// ============================================================
// PostgreSQL connection (Render.com) + mysql2-compatible shim
// ------------------------------------------------------------
// The rest of the codebase was originally written against
// mysql2/promise, which returns results like:
//   SELECT ...   -> [rows, fields]
//   INSERT ...   -> [{ insertId, affectedRows }, fields]
//   UPDATE/DELETE-> [{ affectedRows }, fields]
// and uses "?" as the placeholder character.
//
// Rather than rewriting every query in every controller, this
// module exposes the same `execute(sql, params)` shape on top
// of the `pg` driver, so existing code like:
//   const [rows] = await db.execute('SELECT * FROM x WHERE id=?', [id]);
//   const [result] = await db.execute('INSERT INTO x (...) VALUES (?)', [v]);
//   const userId = result.insertId;
// keeps working unmodified.
// ============================================================

const { Pool, types } = require('pg');
require('dotenv').config();

// mysql2 returns COUNT(*)/SUM(...)/NUMERIC columns as JS numbers.
// node-postgres returns BIGINT (OID 20) and NUMERIC (OID 1700) as
// strings by default (to avoid precision loss on huge values). This
// app doesn't need that precision, and the frontend expects numbers
// (e.g. for charts/analytics), so parse them back to floats/ints here
// instead of touching every controller.
types.setTypeParser(20, (val) => (val === null ? null : parseInt(val, 10)));   // int8/bigint
types.setTypeParser(1700, (val) => (val === null ? null : parseFloat(val)));   // numeric/decimal

const connectionString =
  process.env.DATABASE_URL ||
  `postgres://${process.env.DB_USER || 'postgres'}:${process.env.DB_PASSWORD || ''}@${process.env.DB_HOST || 'localhost'}:${process.env.DB_PORT || 5432}/${process.env.DB_NAME || 'people_esheba'}`;

// Render's managed Postgres requires SSL for external connections.
// Internal connections (same-region private URL) don't need it, but
// enabling it with rejectUnauthorized:false is safe either way.
const useSSL =
  process.env.DB_SSL === 'true' ||
  process.env.NODE_ENV === 'production' ||
  /render\.com/.test(connectionString);

const pool = new Pool({
  connectionString,
  ssl: useSSL ? { rejectUnauthorized: false } : false,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
});

pool
  .connect()
  .then((client) => {
    console.log('✅ PostgreSQL connected successfully');
    client.release();
  })
  .catch((err) => {
    console.error('❌ PostgreSQL connection failed:', err.message);
    process.exit(1);
  });

/** Convert `?` placeholders (in source order) to Postgres `$1, $2, ...` */
function toPgPlaceholders(sql) {
  let i = 0;
  return sql.replace(/\?/g, () => `$${++i}`);
}

const isInsert = (sql) => /^\s*insert/i.test(sql);
const isMutation = (sql) => /^\s*(update|delete)/i.test(sql);

/**
 * mysql2-compatible execute(). Returns [rowsOrResultHeader, fields]
 * just like mysql2/promise does, so existing destructuring code
 * (`const [rows] = ...` / `const [result] = ...`) keeps working.
 */
async function execute(sql, params = []) {
  let text = toPgPlaceholders(sql);

  // mysql2 lets INSERTs work without RETURNING and still exposes
  // insertId. Postgres needs an explicit RETURNING clause for that.
  if (isInsert(text) && !/returning/i.test(text)) {
    text += ' RETURNING id';
  }

  const result = await pool.query(text, params);

  if (isInsert(sql)) {
    const insertId = result.rows?.[0]?.id;
    return [{ insertId, affectedRows: result.rowCount }, result.fields];
  }
  if (isMutation(sql)) {
    return [{ affectedRows: result.rowCount }, result.fields];
  }
  // SELECT and everything else: behave like mysql2 and return the row array
  return [result.rows, result.fields];
}

module.exports = { execute, query: execute, pool };
