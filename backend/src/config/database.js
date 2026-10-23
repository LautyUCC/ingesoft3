const { Pool } = require('pg');

const databaseUrl = process.env.DATABASE_URL || 'postgres://photomatch:photomatch@localhost:5432/photomatch';
const requiresSsl = databaseUrl.includes('neon.tech') || databaseUrl.includes('sslmode=require') || process.env.NODE_ENV === 'production';

const pool = new Pool({
  connectionString: databaseUrl,
  ssl: requiresSsl ? { rejectUnauthorized: false } : false
});

module.exports = pool;
