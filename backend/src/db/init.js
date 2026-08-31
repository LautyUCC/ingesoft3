const fs = require('fs/promises');
const path = require('path');
const bcrypt = require('bcryptjs');
const pool = require('../config/database');
const {pricing}=require('../services/pricingService');

async function initializeDatabase() {
  const schema = await fs.readFile(path.join(__dirname, 'schema.sql'), 'utf8');
  await pool.query(schema);
  await pool.query(`UPDATE coverage_players SET agreed_price=CASE purchase_type WHEN 'single' THEN $1 WHEN 'pack6' THEN $2 WHEN 'all' THEN $3 ELSE 0 END,photos_purchased=CASE purchase_type WHEN 'single' THEN 1 WHEN 'pack6' THEN 6 WHEN 'all' THEN photos_taken ELSE 0 END,purchased_photos=(purchase_type!='none')`,[pricing.products.single.price,pricing.products.pack6.price,pricing.products.all.price]);
  const email = process.env.ADMIN_EMAIL || 'admin@photomatch.local';
  const passwordHash = await bcrypt.hash(process.env.ADMIN_PASSWORD || 'admin123', 12);
  await pool.query(
    `INSERT INTO users (name, email, password_hash) VALUES ($1, $2, $3)
     ON CONFLICT (email) DO NOTHING`, ['Administrador', email.toLowerCase(), passwordHash]
  );
  const homeTeam = await pool.query(`INSERT INTO teams(name) VALUES('Talleres') ON CONFLICT(name) DO UPDATE SET name=EXCLUDED.name RETURNING id`);
  const awayTeam = await pool.query(`INSERT INTO teams(name) VALUES('River Plate') ON CONFLICT(name) DO UPDATE SET name=EXCLUDED.name RETURNING id`);
  const firstDivision=await pool.query(`INSERT INTO divisions(name) VALUES('Primera') ON CONFLICT(name) DO UPDATE SET name=EXCLUDED.name RETURNING id`);
  for(const name of ['Reserva','4ª','5ª','6ª','7ª','8ª','9ª'])await pool.query('INSERT INTO divisions(name) VALUES($1) ON CONFLICT(name) DO NOTHING',[name]);
  const count = await pool.query('SELECT COUNT(*)::int AS total FROM clients');
  if (count.rows[0].total === 0) {
    const client = await pool.query(
      `INSERT INTO clients (name, type, phone, email, notes) VALUES
       ('Club Atlético Talleres', 'club', '+54 351 555-0101', 'prensa@talleres.com.ar', 'Cliente de ejemplo') RETURNING id`
    );
    await pool.query(
      `INSERT INTO coverages (event_name,event_date,venue,client_id,price,status,payment_status,photo_count,delivery_date,notes,home_team_id,away_team_id)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)`,
      ['Talleres vs River', '2026-08-23', 'Mario Alberto Kempes', client.rows[0].id, 120000, 'Editando', 'Pendiente', 487, '2026-08-25', 'Cobertura de ejemplo',homeTeam.rows[0].id,awayTeam.rows[0].id]
    );
  }
  await pool.query(`UPDATE coverages SET home_team_id=COALESCE(home_team_id,$1), away_team_id=COALESCE(away_team_id,$2) WHERE event_name='Talleres vs River'`,[homeTeam.rows[0].id,awayTeam.rows[0].id]);
  await pool.query(`UPDATE coverages SET home_division_id=COALESCE(home_division_id,$1),away_division_id=COALESCE(away_division_id,$1) WHERE event_name='Talleres vs River'`,[firstDivision.rows[0].id]);
  const sampleCoverage=await pool.query(`SELECT id FROM coverages WHERE event_name='Talleres vs River' ORDER BY id LIMIT 1`);
  if(sampleCoverage.rows[0]){
    const sampleCount=await pool.query('SELECT COUNT(*)::int total FROM coverage_players WHERE coverage_id=$1',[sampleCoverage.rows[0].id]);
    if(sampleCount.rows[0].total===0){
      const samplePlayers=[['Juan','Pérez',homeTeam.rows[0].id,10,34,true,true,12,18000,'Entregado'],['Pedro','Gómez',homeTeam.rows[0].id,7,18,true,false,0,null,'Consultó'],['Lucas','Díaz',awayTeam.rows[0].id,4,9,false,false,0,null,'Sin contacto']];
      for(const p of samplePlayers){const saved=await pool.query(`INSERT INTO players(first_name,last_name) VALUES($1,$2) ON CONFLICT(first_name,last_name) DO UPDATE SET first_name=EXCLUDED.first_name RETURNING id`,[p[0],p[1]]);await pool.query(`INSERT INTO coverage_players(coverage_id,player_id,team_id,jersey_number,photos_taken,requested_photos,purchased_photos,photos_purchased,agreed_price,status) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) ON CONFLICT(coverage_id,player_id) DO NOTHING`,[sampleCoverage.rows[0].id,saved.rows[0].id,...p.slice(2)]);}
    }
    await pool.query(`INSERT INTO roster_memberships(player_id,team_id,division_id,season,active) SELECT cp.player_id,cp.team_id,$2,2026,true FROM coverage_players cp WHERE cp.coverage_id=$1 ON CONFLICT(player_id,team_id,division_id,season) DO NOTHING`,[sampleCoverage.rows[0].id,firstDivision.rows[0].id]);
  }
}

module.exports = initializeDatabase;
