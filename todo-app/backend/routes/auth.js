const express = require('express');
const router = express.Router();
const pool = require('../db');

// POST /api/login
// Deliberately simple: just checks username + password against the
// users table and returns success/failure. No JWT, no sessions, no
// hashing yet. That's a later phase (Cognito / API Gateway authorizer
// is a natural place to add real auth once you get to AWS).
router.post('/login', async (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({ success: false, message: 'Username and password are required' });
  }

  try {
    const result = await pool.query(
      'SELECT id, username FROM users WHERE username = $1 AND password = $2',
      [username, password]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ success: false, message: 'Invalid username or password' });
    }

    return res.status(200).json({ success: true, user: result.rows[0] });
  } catch (err) {
    console.error('Login error:', err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;
