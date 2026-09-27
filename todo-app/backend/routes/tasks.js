const express = require('express');
const { SNSClient, PublishCommand } = require('@aws-sdk/client-sns');
const snsClient = new SNSClient({region: process.env.AWS_REGION});
const router = express.Router();
const pool = require('../db');

// GET /api/tasks?page=1&limit=10 - list tasks with pagination
router.get('/', async (req, res) => {
  const page = Math.max(parseInt(req.query.page, 10) || 1, 1);
  const limit = Math.min(Math.max(parseInt(req.query.limit, 10) || 10, 1), 100);
  const offset = (page - 1) * limit;

  try {
    // COUNT(*) OVER() gets the total row count in the same query,
    // so we avoid a second round trip to the DB.
    const [rowsResult, countResult] = await Promise.all([
      pool.query(
        `SELECT * FROM tasks ORDER BY id DESC LIMIT $1 OFFSET $2`,
        [limit, offset]
      ),
      pool.query(
        `SELECT reltuples::bigint AS estimate FROM pg_class WHERE relname = 'tasks'`
      )
    ]);
    
    const tasks = rowsResult.rows;
    const total = parseInt(countResult.rows[0].estimate, 10);

    res.json({
      tasks,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.max(Math.ceil(total / limit), 1),
      },
    });
  } catch (err) {
    console.error('Error fetching tasks:', err);
    res.status(500).json({ message: 'Server error' });
  }
});

// POST /api/tasks - create a task (used by the "add task" page)
router.post('/', async (req, res) => {
  const { title, description, status } = req.body;

  if (!title) {
    return res.status(400).json({ message: 'Task title is required' });
  }

  try {
    const result = await pool.query(
      `INSERT INTO tasks (title, description, status)
       VALUES ($1, $2, COALESCE($3, 'pending'))
       RETURNING *`,
      [title, description || null, status]
    );
    const newTask = result.rows[0];

    try {
      await snsClient.send(new PublishCommand({
        TopicArn: process.env.SNSTOPIC,
        Message: JSON.stringify({ event: 'task_created', task: newTask }),
      }));
    } catch (snsErr) {
      console.error('SNS publish failed (non-fatal):', snsErr);
    }

    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Error creating task:', err);
    res.status(500).json({ message: 'Server error' });
  }
});

// PATCH /api/tasks/:id/status - update just the status
router.patch('/:id/status', async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;

  const allowed = ['pending', 'in_progress', 'completed'];
  if (!allowed.includes(status)) {
    return res.status(400).json({ message: `status must be one of: ${allowed.join(', ')}` });
  }

  try {
    const result = await pool.query(
      `UPDATE tasks SET status = $1, updated_at = NOW() WHERE id = $2 RETURNING *`,
      [status, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Task not found' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error('Error updating task status:', err);
    res.status(500).json({ message: 'Server error' });
  }
});

// DELETE /api/tasks/:id
router.delete('/:id', async (req, res) => {
  const { id } = req.params;

  try {
    const result = await pool.query('DELETE FROM tasks WHERE id = $1 RETURNING *', [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Task not found' });
    }

    res.json({ message: 'Task deleted', task: result.rows[0] });
  } catch (err) {
    console.error('Error deleting task:', err);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
