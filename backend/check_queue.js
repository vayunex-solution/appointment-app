require('dotenv').config();
const db = require('./config/db');
(async () => {
  const [rows] = await db.execute(
    `SELECT id, token_number, queue_position FROM appointments WHERE booking_date = '2026-02-17'`
  );
  console.log('FEB 17 BOOKINGS:');
  rows.forEach(r => console.log('ID:' + r.id + ' TK:' + r.token_number + ' POS:' + r.queue_position));
  process.exit();
})();
