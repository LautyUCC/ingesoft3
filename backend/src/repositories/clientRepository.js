const pool = require('../config/database');
async function findAll() { return (await pool.query('SELECT * FROM clients ORDER BY name')).rows; }
async function findById(id) { return (await pool.query('SELECT * FROM clients WHERE id=$1', [id])).rows[0]; }
async function create(c) { return (await pool.query(`INSERT INTO clients(name,type,phone,email,notes) VALUES($1,$2,$3,$4,$5) RETURNING *`, [c.name,c.type,c.phone,c.email,c.notes])).rows[0]; }
async function update(id,c) { return (await pool.query(`UPDATE clients SET name=$1,type=$2,phone=$3,email=$4,notes=$5,updated_at=NOW() WHERE id=$6 RETURNING *`, [c.name,c.type,c.phone,c.email,c.notes,id])).rows[0]; }
async function remove(id) { return (await pool.query('DELETE FROM clients WHERE id=$1 RETURNING id',[id])).rowCount > 0; }
module.exports = { findAll, findById, create, update, remove };
