// One-time schema loader — run this instead of using the `psql` CLI.
// Usage:
//   DATABASE_URL="postgresql://...external-url-from-render..." node database/migrate-postgres.js
//
// It reads schema.postgres.sql and runs it against whatever DATABASE_URL
// points to. Safe to run more than once (CREATE TABLE IF NOT EXISTS +
// ON CONFLICT DO NOTHING in the seed data).

const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  console.error('❌ Please set DATABASE_URL first. Example:\n');
  console.error('   DATABASE_URL="postgresql://user:pass@host/dbname" node database/migrate-postgres.js\n');
  process.exit(1);
}

const pool = new Pool({
  connectionString,
  ssl: { rejectUnauthorized: false }, // Render's external URL requires SSL
});

async function main() {
  const sqlPath = path.join(__dirname, 'schema.postgres.sql');
  const sql = fs.readFileSync(sqlPath, 'utf8');

  console.log('▶ Connecting to database...');
  const client = await pool.connect();
  try {
    console.log('▶ Running schema.postgres.sql ...');
    await client.query(sql);
    console.log('✅ Schema loaded successfully!');
  } finally {
    client.release();
    await pool.end();
  }
}

main().catch((err) => {
  console.error('❌ Migration failed:', err.message);
  process.exit(1);
});
