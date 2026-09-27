import React, { useState } from 'react';
import { createTask } from '../api/api';

// Page 1: create a new task. Title, description, status dropdown, Add button.
export default function AddTask() {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [status, setStatus] = useState('pending');
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setMessage('');
    try {
      await createTask({ title, description, status });
      setMessage(`Task "${title}" added.`);
      setTitle('');
      setDescription('');
      setStatus('pending');
    } catch (err) {
      setError(err.message);
    }
  };

  return (
    <div className="container">
      <h2>Add a Task</h2>
      <form onSubmit={handleSubmit}>
        <label>Task Title</label>
        <input
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="e.g. Provision RDS Postgres"
          required
        />

        <label>Task Description</label>
        <textarea
          rows={4}
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          placeholder="Optional details about the task"
        />

        <label>Status</label>
        <select value={status} onChange={(e) => setStatus(e.target.value)}>
          <option value="pending">Pending</option>
          <option value="in_progress">In Progress</option>
          <option value="completed">Completed</option>
        </select>

        {error && <div className="error">{error}</div>}
        {message && <div style={{ color: '#065f46' }}>{message}</div>}

        <button type="submit">Add Task</button>
      </form>
    </div>
  );
}
