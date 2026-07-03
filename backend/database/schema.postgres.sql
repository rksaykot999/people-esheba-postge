-- ============================================================
-- People E-Sheba — PostgreSQL Schema (for Render.com)
-- Converted from the original MySQL schema.sql
-- ============================================================
-- Notes on the conversion:
--  * AUTO_INCREMENT           -> SERIAL
--  * ENUM(...)                -> TEXT + CHECK constraint
--  * TINYINT(1) (booleans)    -> SMALLINT (kept as 0/1 so all existing
--                                 backend code that compares to 0/1 keeps working)
--  * INDEX (...) inside table -> separate CREATE INDEX statements
--  * ON UPDATE CURRENT_TIMESTAMP -> trigger (see bottom of file)
--  * INSERT IGNORE            -> INSERT ... ON CONFLICT (...) DO NOTHING
-- ============================================================

-- ── Users ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id            SERIAL PRIMARY KEY,
  name          VARCHAR(100)  NOT NULL,
  email         VARCHAR(150)  NOT NULL UNIQUE,
  phone         VARCHAR(20),
  password_hash VARCHAR(255)  NOT NULL,
  role          TEXT          NOT NULL DEFAULT 'user' CHECK (role IN ('user','admin')),
  avatar        VARCHAR(255),
  division      VARCHAR(60),
  district      VARCHAR(60),
  upazila       VARCHAR(60),
  is_active     SMALLINT      NOT NULL DEFAULT 1,
  is_verified   SMALLINT      NOT NULL DEFAULT 0,
  created_at    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_users_email  ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role   ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_active ON users(is_active);

-- ── SOS / Emergency Contacts ──────────────────────────────────
CREATE TABLE IF NOT EXISTS sos_contacts (
  id         SERIAL PRIMARY KEY,
  name       VARCHAR(100) NOT NULL,
  number     VARCHAR(30)  NOT NULL,
  type       VARCHAR(40)  NOT NULL DEFAULT 'general',
  icon       VARCHAR(10)  DEFAULT '📞',
  is_active  SMALLINT     NOT NULL DEFAULT 1,
  created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (name, number)
);

-- ── Emergency Services ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS emergency_services (
  id          SERIAL PRIMARY KEY,
  name        VARCHAR(150) NOT NULL,
  type        TEXT         NOT NULL DEFAULT 'other'
              CHECK (type IN ('hospital','police','fire','ambulance','mental','other')),
  address     VARCHAR(255),
  division    VARCHAR(60),
  district    VARCHAR(60),
  upazila     VARCHAR(60),
  phone       VARCHAR(50),
  latitude    DECIMAL(10,7),
  longitude   DECIMAL(10,7),
  is_24h      SMALLINT     NOT NULL DEFAULT 0,
  is_verified SMALLINT     NOT NULL DEFAULT 0,
  created_by  INT REFERENCES users(id) ON DELETE SET NULL,
  created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_emerg_type     ON emergency_services(type);
CREATE INDEX IF NOT EXISTS idx_emerg_district ON emergency_services(district);

-- ── Blood Donors ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS blood_donors (
  id                SERIAL PRIMARY KEY,
  user_id           INT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  blood_group       TEXT NOT NULL
                    CHECK (blood_group IN ('A+','A-','B+','B-','AB+','AB-','O+','O-')),
  last_donation     DATE,
  is_available      SMALLINT NOT NULL DEFAULT 1,
  division          VARCHAR(60),
  district          VARCHAR(60),
  upazila           VARCHAR(60),
  address           VARCHAR(255),
  emergency_contact VARCHAR(20),
  total_donations   INT NOT NULL DEFAULT 0,
  created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_blood_group     ON blood_donors(blood_group);
CREATE INDEX IF NOT EXISTS idx_blood_available ON blood_donors(is_available);
CREATE INDEX IF NOT EXISTS idx_blood_district  ON blood_donors(district);

-- ── Donations / Help Requests ─────────────────────────────────
CREATE TABLE IF NOT EXISTS donations (
  id             SERIAL PRIMARY KEY,
  user_id        INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title          VARCHAR(200)  NOT NULL,
  description    TEXT          NOT NULL,
  category       TEXT NOT NULL DEFAULT 'other'
                 CHECK (category IN ('medical','education','disaster','food','other')),
  amount_needed  DECIMAL(12,2) NOT NULL DEFAULT 0,
  amount_raised  DECIMAL(12,2) NOT NULL DEFAULT 0,
  image          VARCHAR(255),
  division       VARCHAR(60),
  district       VARCHAR(60),
  status         TEXT NOT NULL DEFAULT 'pending'
                 CHECK (status IN ('pending','approved','rejected','completed')),
  is_urgent      SMALLINT      NOT NULL DEFAULT 0,
  deadline       DATE,
  created_at     TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_donations_status   ON donations(status);
CREATE INDEX IF NOT EXISTS idx_donations_category ON donations(category);
CREATE INDEX IF NOT EXISTS idx_donations_district ON donations(district);

-- ── Donation Transactions ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS donation_transactions (
  id           SERIAL PRIMARY KEY,
  donation_id  INT NOT NULL REFERENCES donations(id) ON DELETE CASCADE,
  donor_id     INT REFERENCES users(id) ON DELETE SET NULL,
  amount       DECIMAL(12,2) NOT NULL,
  message      VARCHAR(255),
  is_anonymous SMALLINT      NOT NULL DEFAULT 0,
  created_at   TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ── Jobs ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS jobs (
  id              SERIAL PRIMARY KEY,
  user_id         INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title           VARCHAR(200)  NOT NULL,
  company         VARCHAR(150)  NOT NULL,
  description     TEXT          NOT NULL,
  requirements    TEXT,
  category        VARCHAR(60)   NOT NULL DEFAULT 'general',
  type            TEXT NOT NULL DEFAULT 'full-time'
                  CHECK (type IN ('full-time','part-time','freelance','internship','govt')),
  salary_min      DECIMAL(10,2),
  salary_max      DECIMAL(10,2),
  salary_currency VARCHAR(10)   NOT NULL DEFAULT 'BDT',
  division        VARCHAR(60),
  district        VARCHAR(60),
  is_remote       SMALLINT      NOT NULL DEFAULT 0,
  deadline        DATE,
  status          TEXT NOT NULL DEFAULT 'active'
                  CHECK (status IN ('active','closed','draft')),
  views           INT           NOT NULL DEFAULT 0,
  created_at      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_jobs_status   ON jobs(status);
CREATE INDEX IF NOT EXISTS idx_jobs_type     ON jobs(type);
CREATE INDEX IF NOT EXISTS idx_jobs_district ON jobs(district);
CREATE INDEX IF NOT EXISTS idx_jobs_category ON jobs(category);

-- ── Job Applications ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS job_applications (
  id           SERIAL PRIMARY KEY,
  job_id       INT NOT NULL REFERENCES jobs(id)  ON DELETE CASCADE,
  user_id      INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  cover_letter TEXT,
  resume       VARCHAR(255),
  status       TEXT NOT NULL DEFAULT 'pending'
               CHECK (status IN ('pending','shortlisted','rejected','hired')),
  created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (job_id, user_id)
);

-- ── Volunteers ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS volunteers (
  id           SERIAL PRIMARY KEY,
  user_id      INT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  skills       TEXT,
  availability VARCHAR(100),
  category     VARCHAR(80)  NOT NULL DEFAULT 'general',
  division     VARCHAR(60),
  district     VARCHAR(60),
  bio          TEXT,
  is_active    SMALLINT     NOT NULL DEFAULT 1,
  created_at   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_volunteers_active   ON volunteers(is_active);
CREATE INDEX IF NOT EXISTS idx_volunteers_district ON volunteers(district);
CREATE INDEX IF NOT EXISTS idx_volunteers_category ON volunteers(category);

-- ── Notifications ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
  id         SERIAL PRIMARY KEY,
  user_id    INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title      VARCHAR(200) NOT NULL,
  body       TEXT         NOT NULL,
  type       VARCHAR(40)  NOT NULL DEFAULT 'info',
  link       VARCHAR(255),
  is_read    SMALLINT     NOT NULL DEFAULT 0,
  created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_notif_user_read ON notifications(user_id, is_read);

-- ── Bookmarks ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS bookmarks (
  id          SERIAL PRIMARY KEY,
  user_id     INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  entity_type TEXT NOT NULL CHECK (entity_type IN ('job','donation','volunteer','emergency')),
  entity_id   INT NOT NULL,
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (user_id, entity_type, entity_id)
);

-- ── Reports ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS reports (
  id          SERIAL PRIMARY KEY,
  reporter_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  entity_type VARCHAR(40) NOT NULL,
  entity_id   INT         NOT NULL,
  reason      TEXT        NOT NULL,
  status      TEXT NOT NULL DEFAULT 'pending'
              CHECK (status IN ('pending','reviewed','resolved')),
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ── Ratings ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS ratings (
  id          SERIAL PRIMARY KEY,
  user_id     INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  entity_type VARCHAR(40) NOT NULL,
  entity_id   INT         NOT NULL,
  score       SMALLINT    NOT NULL CHECK (score BETWEEN 1 AND 5),
  review      TEXT,
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (user_id, entity_type, entity_id)
);

-- ── Announcements (Admin broadcast) ──────────────────────────
CREATE TABLE IF NOT EXISTS announcements (
  id         SERIAL PRIMARY KEY,
  admin_id   INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title      VARCHAR(200) NOT NULL,
  body       TEXT         NOT NULL,
  is_active  SMALLINT     NOT NULL DEFAULT 1,
  created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- Auto-update "updated_at" columns (replaces MySQL's
-- "ON UPDATE CURRENT_TIMESTAMP")
-- ============================================================
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY['users','emergency_services','blood_donors','donations','jobs','volunteers']
  LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS trg_set_updated_at ON %I;', t);
    EXECUTE format(
      'CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON %I
       FOR EACH ROW EXECUTE FUNCTION set_updated_at();', t
    );
  END LOOP;
END $$;

-- ============================================================
-- Seed data
-- ============================================================

-- ── Seed default SOS contacts ─────────────────────────────────
INSERT INTO sos_contacts (name, number, type, icon) VALUES
  ('National Emergency', '999',  'emergency', '🆘'),
  ('Fire Service',       '199',  'fire',      '🚒'),
  ('Ambulance',          '199',  'ambulance', '🚑'),
  ('Police',             '999',  'police',    '👮'),
  ('Anti-Terrorism',     '01769-691613', 'security', '🛡️'),
  ('Child Helpline',     '1098', 'child',     '👶'),
  ('Women Helpline',     '10921','women',     '👩'),
  ('Suicide Prevention', '16789','mental',    '🧠')
ON CONFLICT (name, number) DO NOTHING;

-- ── Default Admin User (password: Admin@1234) ─────────────────
INSERT INTO users (name, email, phone, password_hash, role, is_verified) VALUES
  ('Super Admin', 'admin@esheba.bd', '01700000000',
   '$2a$12$4XKmQO7wO7exnUrnOAgbe.1NN2W490smMmbUq4ODJZU73jnSyJeQ6', -- Admin@1234
   'admin', 1)
ON CONFLICT (email) DO NOTHING;
