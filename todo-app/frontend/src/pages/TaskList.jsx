import React, { useEffect, useState } from 'react';
import { getTasks, updateTaskStatus, deleteTask } from '../api/api';

const LIMIT = 10;

// Page 2: shows created tasks, paginated. No editing — only "mark completed"
// and "delete" for now, as requested.
export default function TaskList() {
  const [tasks, setTasks] = useState([]);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [error, setError] = useState('');

  const loadTasks = async (targetPage) => {
    try {
      const data = await getTasks(targetPage, LIMIT);
      setTasks(data.tasks);
      setTotalPages(data.pagination.totalPages);
      // If we deleted the last item on a page, snap back to a valid page.
      if (targetPage > data.pagination.totalPages) {
        setPage(data.pagination.totalPages);
      }
    } catch (err) {
      setError(err.message);
    }
  };

  useEffect(() => {
    loadTasks(page);
  }, [page]);

  const handleComplete = async (id) => {
    try {
      await updateTaskStatus(id, 'completed');
      loadTasks(page);
    } catch (err) {
      setError(err.message);
    }
  };

  const handleDelete = async (id) => {
    try {
      await deleteTask(id);
      loadTasks(page);
    } catch (err) {
      setError(err.message);
    }
  };

  return (
    <div className="container">
      <h2>Your Tasks</h2>
      {error && <div className="error">{error}</div>}

      {tasks.length === 0 && <p>No tasks yet — add one from the Add Task page.</p>}

      {tasks.map((task) => (
        <div className="task-card" key={task.id}>
          <div>
            <div className="title">#{task.id} {task.title}</div>
            {task.description && <div className="desc">{task.description}</div>}
            <div className={`status-badge status-${task.status}`}>{task.status}</div>
          </div>
          <div>
            {task.status !== 'completed' && (
              <button onClick={() => handleComplete(task.id)}>Complete</button>
            )}
            <button className="danger" onClick={() => handleDelete(task.id)} style={{ marginLeft: 8 }}>
              Delete
            </button>
          </div>
        </div>
      ))}

      {totalPages > 1 && (
        <div className="pagination" style={{ marginTop: 16, display: 'flex', gap: 8, alignItems: 'center' }}>
          <button disabled={page <= 1} onClick={() => setPage((p) => p - 1)}>
            Prev
          </button>
          <span>Page {page} of {totalPages}</span>
          <button disabled={page >= totalPages} onClick={() => setPage((p) => p + 1)}>
            Next
          </button>
        </div>
      )}
    </div>
  );
}
