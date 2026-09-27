import React, { useState } from 'react';
import { BrowserRouter, Routes, Route, Navigate, Link, useNavigate } from 'react-router-dom';
import Login from './pages/Login';
import AddTask from './pages/AddTask';
import TaskList from './pages/TaskList';

function NavBar({ user, onLogout }) {
  const navigate = useNavigate();
  const handleLogout = () => {
    onLogout();
    navigate('/');
  };
  return (
    <nav>
      <div className="links">
        <Link to="/add">Add Task</Link>
        <Link to="/tasks">View Tasks</Link>
      </div>
      <div>
        <span style={{ marginRight: 12 }}>Hi, {user.username}</span>
        <button className="secondary" onClick={handleLogout}>Log Out</button>
      </div>
    </nav>
  );
}

// Guards the two app pages behind a simple "is a user set" check.
// No tokens — just in-memory state, so refreshing the page logs you out.
function PrivateRoute({ user, children }) {
  return user ? children : <Navigate to="/" replace />;
}

export default function App() {
  const [user, setUser] = useState(null);

  return (
    <BrowserRouter>
      {user && <NavBar user={user} onLogout={() => setUser(null)} />}
      <Routes>
        <Route
          path="/"
          element={user ? <Navigate to="/add" replace /> : <Login onLogin={setUser} />}
        />
        <Route
          path="/add"
          element={<PrivateRoute user={user}><AddTask /></PrivateRoute>}
        />
        <Route
          path="/tasks"
          element={<PrivateRoute user={user}><TaskList /></PrivateRoute>}
        />
      </Routes>
    </BrowserRouter>
  );
}
