require('dotenv').config();
const db = require('./config/db');

(async () => {
    try {
        const [tables] = await db.execute('SHOW TABLES');
        const tableNames = tables.map(t => Object.values(t)[0]);
        console.log('ALL TABLES:', tableNames.join(', '));
        console.log('HAS queue_stats:', tableNames.includes('queue_stats'));

        const [cols] = await db.execute('SHOW COLUMNS FROM appointments');
        console.log('APPOINTMENTS COLUMNS:', cols.map(c => c.Field).join(', '));
        console.log('HAS started_at:', cols.some(c => c.Field === 'started_at'));
        console.log('HAS queue_position:', cols.some(c => c.Field === 'queue_position'));

        // Check status enum
        const statusCol = cols.find(c => c.Field === 'status');
        if (statusCol) console.log('STATUS TYPE:', statusCol.Type);
    } catch (e) {
        console.error('ERROR:', e.message);
    }
    process.exit();
})();
