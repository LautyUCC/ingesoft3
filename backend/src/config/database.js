const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgres://photomatch:photomatch@localhost:5432/photomatch'
});

module.exports = pool;
