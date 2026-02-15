require('dotenv').config();
const db = require('./config/db');
(async () => {
  // Find the customer with running/pending bookings
  const [custs] = await db.execute(
    `SELECT DISTINCT a.customer_id, u.name, u.mobile
     FROM appointments a
     JOIN users u ON a.customer_id = u.id
     WHERE a.status IN ('pending','running') AND a.booking_date >= CURDATE()
     LIMIT 5`
  );
  console.log('ACTIVE CUSTOMERS:');
  custs.forEach(c => console.log('  ID:' + c.customer_id + ' ' + c.name + ' ' + c.mobile));
  
  if (custs.length > 0) {
    const custId = custs[0].customer_id;
    console.log('\nTESTING getCustomerQueueStatus for customer ID:', custId);
    
    const QueueEngine = require('./services/QueueEngine');
    const result = await QueueEngine.getCustomerQueueStatus(custId);
    console.log('RESULT COUNT:', result.length);
    result.forEach(t => {
      console.log('  TOKEN:', t.token_number);
      console.log('  STATUS:', t.status);
      console.log('  SHOP:', t.shop_name);
      console.log('  AHEAD:', t.tokens_ahead);
      console.log('  WAIT:', t.estimated_wait_minutes + 'min');
      console.log('  MY_TURN:', t.is_my_turn);
      console.log('  SERVING:', t.current_serving?.token_number || 'none');
      console.log('  ---');
    });
  }
  process.exit();
})();
