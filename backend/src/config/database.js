const { Pool } = require('pg');

const databaseUrl = process.env.DATABASE_URL || 'postgres://photomatch:photomatch@localhost:5432/photomatch';
const url = new URL(databaseUrl);
const sslMode = process.env.DB_SSL_MODE || url.searchParams.get('sslmode') ||
  (url.hostname.endsWith('.neon.tech') ? 'require' : 'disable');
if (!['require', 'disable'].includes(sslMode)) {
  throw new Error('DB_SSL_MODE debe ser require o disable');
}
// pg reinterpreta sslmode de la URL y puede reemplazar nuestra configuración TLS.
url.searchParams.delete('sslmode');

const pool = new Pool({
  connectionString: url.toString(),
  ssl: sslMode === 'require' ? { rejectUnauthorized: true, servername: url.hostname } : false
});

module.exports = pool;
