CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(160) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(30) NOT NULL DEFAULT 'admin',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS clients (
  id SERIAL PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  type VARCHAR(20) NOT NULL CHECK (type IN ('jugador','club','medio','otro')),
  phone VARCHAR(40),
  email VARCHAR(160),
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS teams (
  id SERIAL PRIMARY KEY,
  name VARCHAR(120) NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS players (
  id SERIAL PRIMARY KEY,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (first_name, last_name)
);
ALTER TABLE players ADD COLUMN IF NOT EXISTS nickname VARCHAR(100);
ALTER TABLE players ADD COLUMN IF NOT EXISTS birth_date DATE;
ALTER TABLE players ADD COLUMN IF NOT EXISTS phone VARCHAR(40);
ALTER TABLE players ADD COLUMN IF NOT EXISTS email VARCHAR(160);
ALTER TABLE players ADD COLUMN IF NOT EXISTS notes TEXT;

CREATE TABLE IF NOT EXISTS divisions (
  id SERIAL PRIMARY KEY, name VARCHAR(80) NOT NULL UNIQUE, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS roster_memberships (
  id SERIAL PRIMARY KEY, player_id INTEGER NOT NULL REFERENCES players(id) ON DELETE RESTRICT,
  team_id INTEGER NOT NULL REFERENCES teams(id) ON DELETE RESTRICT,
  division_id INTEGER NOT NULL REFERENCES divisions(id) ON DELETE RESTRICT,
  season INTEGER NOT NULL, active BOOLEAN NOT NULL DEFAULT TRUE, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(player_id,team_id,division_id,season)
);

CREATE TABLE IF NOT EXISTS coverages (
  id SERIAL PRIMARY KEY,
  event_name VARCHAR(180) NOT NULL,
  event_date DATE NOT NULL,
  venue VARCHAR(180) NOT NULL,
  client_id INTEGER NOT NULL REFERENCES clients(id) ON DELETE RESTRICT,
  price NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (price >= 0),
  status VARCHAR(20) NOT NULL CHECK (status IN ('Pendiente','Realizada','Editando','Entregada','Cancelada')),
  payment_status VARCHAR(20) NOT NULL CHECK (payment_status IN ('Pendiente','Parcial','Pagado')),
  photo_count INTEGER NOT NULL DEFAULT 0 CHECK (photo_count >= 0),
  delivery_date DATE,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE coverages ADD COLUMN IF NOT EXISTS home_team_id INTEGER REFERENCES teams(id) ON DELETE RESTRICT;
ALTER TABLE coverages ADD COLUMN IF NOT EXISTS away_team_id INTEGER REFERENCES teams(id) ON DELETE RESTRICT;
ALTER TABLE coverages ADD COLUMN IF NOT EXISTS home_division_id INTEGER REFERENCES divisions(id) ON DELETE RESTRICT;
ALTER TABLE coverages ADD COLUMN IF NOT EXISTS away_division_id INTEGER REFERENCES divisions(id) ON DELETE RESTRICT;

CREATE TABLE IF NOT EXISTS coverage_players (
  id SERIAL PRIMARY KEY,
  coverage_id INTEGER NOT NULL REFERENCES coverages(id) ON DELETE CASCADE,
  player_id INTEGER NOT NULL REFERENCES players(id) ON DELETE RESTRICT,
  team_id INTEGER NOT NULL REFERENCES teams(id) ON DELETE RESTRICT,
  jersey_number INTEGER CHECK (jersey_number BETWEEN 0 AND 999),
  photos_taken INTEGER NOT NULL DEFAULT 0 CHECK (photos_taken >= 0),
  requested_photos BOOLEAN NOT NULL DEFAULT FALSE,
  purchased_photos BOOLEAN NOT NULL DEFAULT FALSE,
  photos_purchased INTEGER NOT NULL DEFAULT 0 CHECK (photos_purchased >= 0),
  agreed_price NUMERIC(12,2) CHECK (agreed_price IS NULL OR agreed_price >= 0),
  status VARCHAR(30) NOT NULL DEFAULT 'Sin contacto' CHECK (status IN ('Sin contacto','Contactado','Consultó','Interesado','Pendiente de pago','Pagado','Seleccionando fotos','Pendiente de entrega','Entregado','No interesado')),
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (coverage_id, player_id)
);

ALTER TABLE coverage_players ADD COLUMN IF NOT EXISTS purchase_type VARCHAR(20) NOT NULL DEFAULT 'none';
ALTER TABLE coverage_players ADD COLUMN IF NOT EXISTS player_payment_status VARCHAR(20) NOT NULL DEFAULT 'Pendiente';
ALTER TABLE coverage_players ADD COLUMN IF NOT EXISTS is_additional_sale BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE coverage_players DROP CONSTRAINT IF EXISTS coverage_players_status_check;
ALTER TABLE coverage_players ADD CONSTRAINT coverage_players_status_check CHECK (status IN ('Sin actividad','Sin contacto','Contactado','Consultó','Interesado','Pendiente de pago','Pagado','Seleccionando fotos','Pendiente de entrega','Entregado','No interesado'));
UPDATE coverage_players SET purchase_type=CASE WHEN photos_purchased=1 THEN 'single' WHEN photos_purchased=6 THEN 'pack6' WHEN purchased_photos THEN 'all' ELSE 'none' END WHERE purchase_type='none' AND purchased_photos=TRUE;

CREATE TABLE IF NOT EXISTS coverage_team_sales (
  id SERIAL PRIMARY KEY,
  coverage_id INTEGER NOT NULL REFERENCES coverages(id) ON DELETE CASCADE,
  team_id INTEGER NOT NULL REFERENCES teams(id) ON DELETE RESTRICT,
  amount NUMERIC(12,2) NOT NULL CHECK(amount >= 0),
  payment_status VARCHAR(20) NOT NULL CHECK(payment_status IN ('Pendiente','Parcial','Pagado')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(coverage_id,team_id)
);

CREATE INDEX IF NOT EXISTS idx_coverages_client ON coverages(client_id);
CREATE INDEX IF NOT EXISTS idx_coverages_event_date ON coverages(event_date);
CREATE INDEX IF NOT EXISTS idx_coverage_players_coverage ON coverage_players(coverage_id);
CREATE INDEX IF NOT EXISTS idx_rosters_lookup ON roster_memberships(team_id,division_id,season,active);
