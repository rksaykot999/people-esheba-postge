const { Client } = require('pg');
const passwords = ['2sylNmJ5GEkwiYiULtCv1GOIgHQTlnsp'];
const hostnames = [
  'dpg-crd6dhoqf0us73db6k40-a.oregon-postgres.render.com',
  'dpg-crd6dhogf0us73db6k40-a.oregon-postgres.render.com',
  'dpg-crd6dhoqfous73db6k40-a.oregon-postgres.render.com',
  'dpg-crd6dhoqf0us73db6k4o-a.oregon-postgres.render.com',
  'dpg-crd6dhogfous73db6k40-a.oregon-postgres.render.com'
];
async function run() {
  for(let h of hostnames) {
    try {
      const client = new Client({
        connectionString: `postgres://people_esheba_db_user:${passwords[0]}@${h}/people_esheba_db`,
        ssl: { rejectUnauthorized: false },
        connectionTimeoutMillis: 5000
      });
      await client.connect();
      console.log('SUCCESS HOST:', h);
      process.exit(0);
    } catch(e) {
      console.log('FAILED HOST:', h, e.message);
    }
  }
}
run();
