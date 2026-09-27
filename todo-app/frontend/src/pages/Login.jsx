import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { login } from '../api/api';

// Simple login: no tokens, no sessions. On success we just stash the
// username in memory (App state) so the rest of the app knows someone
// is "logged in". Good enough for practicing the app itself; real
// auth (Cognito, API Gateway authorizer) comes later.
export default function Login({ onLogin }) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    try {
      const result = await login(username, password);
      onLogin(result.user);
      navigate('/add');
    } catch (err) {
      setError(err.message);
    }
  };

  return (
    <div className="container">
      <h1>Todo App Login</h1>
      <form onSubmit={handleSubmit}>
        <label>Username</label>
        <input
          value={username}
          onChange={(e) => setUsername(e.target.value)}
          placeholder="admin"
          required
        />
        <label>Password</label>
        <input
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          placeholder="admin123"
          required
        />
        {error && <div className="error">{error}</div>}
        <button type="submit">Log In</button>
      </form>
      <p style={{ fontSize: 13, color: '#777' }}>
        Default seeded user: <code>admin / admin123</code>
      </p>
    </div>
  );
}
