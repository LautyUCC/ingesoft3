const pool=require('../config/database');
async function findAll(){return (await pool.query('SELECT * FROM teams ORDER BY name')).rows;}
async function findOrCreate(name){return (await pool.query(`INSERT INTO teams(name) VALUES($1) ON CONFLICT(name) DO UPDATE SET name=EXCLUDED.name RETURNING *`,[name.trim()])).rows[0];}
module.exports={findAll,findOrCreate};
