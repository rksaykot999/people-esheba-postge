// Normalizes any "truthy-ish" input (JS boolean, "true"/"false" string from
// multipart forms, 1/0, "1"/"0") into a plain 0 or 1 integer.
//
// This matters for Postgres: unlike MySQL's TINYINT (which quietly
// coerces booleans/strings), our is_* columns are SMALLINT, and the `pg`
// driver will throw if you try to bind a JS boolean or the string "true"
// directly into an integer column.
function toBit(value) {
  if (value === true || value === 1 || value === '1' || value === 'true') return 1;
  return 0;
}

module.exports = { toBit };
