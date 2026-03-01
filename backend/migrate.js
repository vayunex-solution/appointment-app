require('dotenv').config();
const db = require('./config/db');

async function migrate() {
    try {
        console.log('Running migration...');
        await db.execute(`
            CREATE TABLE IF NOT EXISTS categories (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(100) NOT NULL UNIQUE,
                icon VARCHAR(100) NULL,
                is_active BOOLEAN DEFAULT TRUE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        `);
        console.log('Created categories table');

        await db.execute(`
            INSERT IGNORE INTO categories (name, icon) VALUES 
            ('Salon', 'spa'), 
            ('Healthcare', 'medical_services'), 
            ('Fitness', 'fitness_center'), 
            ('Education', 'school'), 
            ('Legal', 'gavel'), 
            ('More', 'more_horiz');
        `);
        console.log('Inserted default categories');

        process.exit(0);
    } catch (e) {
        console.error('Migration failed:', e);
        process.exit(1);
    }
}

migrate();
