const { Pool } = require('pg');
require('dotenv').config();

// A single shared connection pool. When you move this to RDS, only
// the env vars change — this file stays exactly the same. Later, if
// you put this behind Lambda, you'll swap this for a connection
// pooler (RDS Proxy) instead of a raw pg.Pool — see AWS-Practice-Guide.md.
const pool = new Pool({
  host: process.env.PGHOST,
  port: process.env.PGPORT,
  user: process.env.PGUSER,
  password: process.env.PGPASSWORD,
  database: process.env.PGDATABASE,
  ssl:{
    rejectUnauthorized: false
  }
});

pool.on('error', (err) => {
  console.error('Unexpected error on idle Postgres client', err);
});

module.exports = pool;
