const pool = require('../config/database');
const select = `SELECT c.*, cl.name AS client_name, cl.type AS client_type, ht.name AS home_team_name, at.name AS away_team_name,hd.name AS home_division_name,ad.name AS away_division_name FROM coverages c JOIN clients cl ON cl.id=c.client_id LEFT JOIN teams ht ON ht.id=c.home_team_id LEFT JOIN teams at ON at.id=c.away_team_id LEFT JOIN divisions hd ON hd.id=c.home_division_id LEFT JOIN divisions ad ON ad.id=c.away_division_id`;
async function findAll() { return (await pool.query(`${select} ORDER BY c.event_date DESC, c.id DESC`)).rows; }
async function findById(id) { return (await pool.query(`${select} WHERE c.id=$1`,[id])).rows[0]; }
async function create(c) { return (await pool.query(`INSERT INTO coverages(event_name,event_date,venue,client_id,price,status,payment_status,photo_count,delivery_date,notes,home_team_id,away_team_id,home_division_id,away_division_id) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14) RETURNING *`, values(c))).rows[0]; }
async function update(id,c) { return (await pool.query(`UPDATE coverages SET event_name=$1,event_date=$2,venue=$3,client_id=$4,price=$5,status=$6,payment_status=$7,photo_count=$8,delivery_date=$9,notes=$10,home_team_id=$11,away_team_id=$12,home_division_id=$13,away_division_id=$14,updated_at=NOW() WHERE id=$15 RETURNING *`, [...values(c),id])).rows[0]; }
async function remove(id) { return (await pool.query('DELETE FROM coverages WHERE id=$1 RETURNING id',[id])).rowCount > 0; }
async function dashboard() {
  const summary = await pool.query(`SELECT COUNT(*)::int total, COUNT(*) FILTER(WHERE status='Pendiente')::int pending, COUNT(*) FILTER(WHERE status='Entregada')::int delivered, COUNT(*) FILTER(WHERE payment_status!='Pagado' AND status!='Cancelada')::int unpaid FROM coverages`);
  const upcoming = await pool.query(`${select} WHERE c.event_date >= CURRENT_DATE AND c.status != 'Cancelada' ORDER BY c.event_date LIMIT 5`);
  return { ...summary.rows[0], upcoming: upcoming.rows };
}
function values(c){ return [c.event_name,c.event_date,c.venue,c.client_id,c.price,c.status,c.payment_status,c.photo_count,c.delivery_date,c.notes,c.home_team_id,c.away_team_id,c.home_division_id,c.away_division_id]; }
module.exports = { findAll, findById, create, update, remove, dashboard };
