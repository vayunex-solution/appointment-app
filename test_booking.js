const mysql = require('mysql2/promise');
const API_URL = 'https://api.booknex.vayunexsolution.com/api';

async function testBooking() {
    let connection;
    try {
        // Connect to local DB to force verify the user
        connection = await mysql.createConnection({
            host: 'localhost',
            user: 'root',
            password: '',
            database: 'vayunexs_db_appointment_booking'
        });

        // 1. Create a dynamic new customer
        const randomString = Math.random().toString(36).substring(7);
        const email = `test_customer_${randomString}@test.com`;
        const mobile = `9${Math.floor(100000000 + Math.random() * 900000000)}`;
        
        console.log('Registering Customer:', email, mobile);
        const registerRes = await fetch(`${API_URL}/auth/register/customer`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                name: 'Test Customer',
                email: email,
                mobile: mobile,
                password: 'password123'
            })
        }).then(res => res.json());
        
        console.log('Registration Result:', registerRes);
        
        // Force Verify via DB
        await connection.execute('UPDATE users SET is_verified = 1 WHERE email = ?', [email]);
        console.log('User forcefully verified in DB.');

        // Login
        const loginRes = await fetch(`${API_URL}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                identifier: email,
                password: 'password123'
            })
        }).then(res => res.json());
        
        const token = loginRes.token;
        console.log('Login Result:', loginRes);
        if (!token) {
           console.log('FAILED TO GET TOKEN. Cannot proceed.');
           return;
        }
        
        // Fetch providers
        const providersRes = await fetch(`${API_URL}/customer/providers`, {
            headers: { Authorization: `Bearer ${token}` }
        }).then(res => res.json());
        
        if (!providersRes.providers || providersRes.providers.length === 0) {
            console.log('No providers found to book.');
            return;
        }
        
        const providerId = providersRes.providers[0].id;
        
        // Fetch services
        const servicesRes = await fetch(`${API_URL}/customer/providers/${providerId}/services`, {
            headers: { Authorization: `Bearer ${token}` }
        }).then(res => res.json());
        
        if (!servicesRes.services || servicesRes.services.length === 0) {
            console.log('No services found for provider:', providerId);
            return;
        }
        
        const serviceId = servicesRes.services[0].id;
        
        // Try booking
        console.log(`Booking payload: { provider_id: ${providerId}, service_id: ${serviceId}, booking_date: '2026-05-15', slot_time: '10:00' }`);
        const bookingRes = await fetch(`${API_URL}/bookings`, {
            method: 'POST',
            headers: { 
                'Content-Type': 'application/json',
                Authorization: `Bearer ${token}` 
            },
            body: JSON.stringify({
                provider_id: providerId,
                service_id: serviceId,
                booking_date: '2026-05-15',
                slot_time: '10:00'
            })
        }).then(res => res.json());
        
        console.log('Booking Result:', bookingRes);

    } catch (error) {
        console.error('Test Failed:', error);
    } finally {
        if (connection) await connection.end();
    }
}

testBooking();
