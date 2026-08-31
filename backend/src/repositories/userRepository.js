const pool = require('../config/database');
async function findByEmail(email) { const r = await pool.query('SELECT * FROM users WHERE email = $1', [email]); return r.rows[0]; }
module.exports = { findByEmail };
