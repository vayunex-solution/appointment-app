require('dotenv').config();
const fetch = require('node-fetch');
(async () => {
  const l = await fetch('http://localhost:5000/api/auth/login', {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ identifier: 'yashkr4748@gmail.com', password: 'yash2002' })
  });
  const d = await l.json();
  const q = await fetch('http://localhost:5000/api/provider/queue/today', {
    headers: { 'Authorization': 'Bearer ' + d.token }
  });
  const qd = await q.json();
  console.log('STATUS:', q.status);
  console.log('QUEUE COUNT:', qd.queue?.length);
  console.log('STATS:', JSON.stringify(qd.stats));
  if (qd.queue) qd.queue.forEach(t => console.log(t.id + '|' + t.token_number + '|' + t.status + '|' + t.customer_name));
  process.exit();
})();
