require('dotenv').config();
const fetch = require('node-fetch');
(async () => {
  const l = await fetch('http://localhost:5000/api/auth/login', {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ identifier: 'yashkr4748@gmail.com', password: 'yash2002' })
  });
  const d = await l.json();
  const b = await fetch('http://localhost:5000/api/provider/bookings', {
    headers: { 'Authorization': 'Bearer ' + d.token }
  });
  const bd = await b.json();
  console.log('ORDER:');
  bd.bookings?.forEach((bk, i) => console.log(
    (i + 1) + '. ' + bk.token_number + ' | ' + bk.status + ' | pos:' + bk.queue_position + ' | ' + bk.booking_date
  ));
  process.exit();
})();
