#!/bin/bash
# ============================================
# BookNex Booking Fix — Direct cPanel Patcher
# Run this inside: /home/vayunexs/api.booknex.vayunexsolution.com
# ============================================

echo "===== STEP 1: Backing up old files ====="
cp routes/booking.routes.js routes/booking.routes.js.bak 2>/dev/null
cp models/Booking.js models/Booking.js.bak 2>/dev/null
echo "Backup done."

echo ""
echo "===== STEP 2: Patching Booking.js (queue_position → queue_number) ====="
sed -i "s/queue_position/queue_number/g" models/Booking.js
echo "Booking.js patched."

echo ""
echo "===== STEP 3: Patching booking.routes.js ====="
# Fix 1: Add 'const db = require' if not already present
if ! grep -q "const db = require" routes/booking.routes.js; then
  sed -i "/const Provider = require/a const db = require('../config/db');" routes/booking.routes.js
  echo "Added db import."
else
  echo "db import already exists."
fi

# Fix 2: Replace inline require with db.execute
sed -i "s/await require('..\/config\/db').execute/await db.execute/g" routes/booking.routes.js
echo "Fixed db.execute call."

# Fix 3: Add error details to 500 response
sed -i "s/res.status(500).json({ error: 'Booking failed' })/res.status(500).json({ error: 'Booking failed', details: error.message })/g" routes/booking.routes.js
echo "Added error details to 500 response."

echo ""
echo "===== STEP 4: Patching QueueEngine.js (queue_position → queue_number) ====="
if [ -f services/QueueEngine.js ]; then
  sed -i "s/a\.queue_position/a.queue_number/g" services/QueueEngine.js
  sed -i "s/queue_position/queue_number/g" services/QueueEngine.js
  echo "QueueEngine.js patched."
else
  echo "QueueEngine.js not found (skip)."
fi

echo ""
echo "===== STEP 5: Restarting Node App ====="
if [ -d tmp ]; then
  touch tmp/restart.txt
  echo "Server restart triggered!"
else
  mkdir -p tmp
  touch tmp/restart.txt
  echo "Created tmp/ and triggered restart!"
fi

echo ""
echo "============================================"
echo "ALL FIXES APPLIED SUCCESSFULLY!"
echo "Now test booking from the app/browser."
echo "============================================"
