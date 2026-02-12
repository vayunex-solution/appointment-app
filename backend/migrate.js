const db = require('./config/db');

async function migrate() {
    console.log('Running migrations...');
    
    // Add queue columns to appointments
    try {
        await db.execute('ALTER TABLE appointments ADD COLUMN queue_number INT NULL');
        console.log('✅ queue_number column added');
    } catch(e) {
        console.log('⚠️ queue_number:', e.message.substring(0, 50));
    }
    
    try {
        await db.execute('ALTER TABLE appointments ADD COLUMN served_at DATETIME NULL');
        console.log('✅ served_at column added');
    } catch(e) {
        console.log('⚠️ served_at:', e.message.substring(0, 50));
    }
    
    try {
        await db.execute('ALTER TABLE appointments ADD COLUMN completed_at DATETIME NULL');
        console.log('✅ completed_at column added');
    } catch(e) {
        console.log('⚠️ completed_at:', e.message.substring(0, 50));
    }
    
    // Create reviews table
    try {
        await db.execute(`
            CREATE TABLE IF NOT EXISTS reviews (
                id INT AUTO_INCREMENT PRIMARY KEY,
                appointment_id INT NOT NULL UNIQUE,
                customer_id INT NOT NULL,
                provider_id INT NOT NULL,
                rating TINYINT NOT NULL,
                comment TEXT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (appointment_id) REFERENCES appointments(id) ON DELETE CASCADE,
                FOREIGN KEY (customer_id) REFERENCES users(id) ON DELETE CASCADE,
                FOREIGN KEY (provider_id) REFERENCES providers(id) ON DELETE CASCADE,
                INDEX idx_provider (provider_id),
                INDEX idx_customer (customer_id)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        `);
        console.log('✅ reviews table created');
    } catch(e) {
        console.log('⚠️ reviews:', e.message.substring(0, 50));
    }
    
    console.log('Migration complete!');
    process.exit(0);
}

migrate();
