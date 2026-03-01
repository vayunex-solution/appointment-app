const mysql = require('mysql2/promise');

async function checkAppointmentsSchema() {
    let connection;
    try {
        connection = await mysql.createConnection({
            host: 'localhost',
            user: 'root',
            password: '',
            database: 'vayunexs_db_appointment_booking'
        });

        const [rows] = await connection.execute('DESCRIBE appointments');
        console.table(rows);
    } catch (e) {
        console.error(e);
    } finally {
        if (connection) await connection.end();
    }
}

checkAppointmentsSchema();
