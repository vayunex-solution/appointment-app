require('dotenv').config();
const fetch = require('node-fetch');

// Adjust if port differs
const BASE_URL = 'http://localhost:5000/api';

// Generates random test user
const RANDOM_ID = Math.floor(Math.random() * 10000);
const CUSTOMER_EMAIL = `test_customer_${RANDOM_ID}@example.com`;
const CUSTOMER_PASS = '123456';
const CUSTOMER_Mobile = `98${Math.floor(10000000 + Math.random() * 90000000)}`;

async function runTest() {
    console.log('🚀 Starting Backend Queue Flow Verification...');
    console.log(`Target: ${BASE_URL}`);

    try {
        // ------------------------------------------------
        // 1. REGISTER CUSTOMER
        // ------------------------------------------------
        console.log(`\n1. Registering Customer: ${CUSTOMER_EMAIL}`);
        
        const regRes = await fetch(`${BASE_URL}/auth/register/customer`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                name: `Test User ${RANDOM_ID}`,
                email: CUSTOMER_EMAIL,
                password: CUSTOMER_PASS,
                mobile: CUSTOMER_Mobile
            })
        });
        
        const regData = await regRes.json();
        
        if (regRes.ok) {
            console.log('✅ Registration Successful');
            
            // MANUALLY VERIFY USER IN DB
            const db = require('./config/db');
            console.log('   Manually verifying user in DB...');
            await db.execute('UPDATE users SET is_verified = 1 WHERE email = ?', [CUSTOMER_EMAIL]);
            console.log('✅ User verified manually.');
            
        } else {
            console.log(`⚠️ Registration note: ${regData.error || JSON.stringify(regData)}`);
        }

        // ------------------------------------------------
        // 2. LOGIN
        // ------------------------------------------------
        console.log('\n2. Logging in...');
        const loginRes = await fetch(`${BASE_URL}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ identifier: CUSTOMER_EMAIL, password: CUSTOMER_PASS })
        });
        
        const loginData = await loginRes.json();
        if (!loginRes.ok) throw new Error(`Login failed: ${JSON.stringify(loginData)}`);
        
        const token = loginData.token;
        console.log(`✅ Login OK. Token: ${token.substring(0, 15)}...`);

        // ------------------------------------------------
        // 3. GET PROVIDERS & SERVICES
        // ------------------------------------------------
        console.log('\n3. Fetching Providers & Services...');
        const provRes = await fetch(`${BASE_URL}/customer/providers`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        const provData = await provRes.json();
        
        if (!provData.providers || provData.providers.length === 0) {
            throw new Error('❌ No providers found in DB! Cannot test booking.');
        }
        
        let provider = null;
        let service = null;

        // Loop to find provider with services
        for (const p of provData.providers) {
            console.log(`   Checking services for Provider: ${p.shop_name} (ID: ${p.id})...`);
            try {
                const servRes = await fetch(`${BASE_URL}/customer/providers/${p.id}/services`, {
                    headers: { 'Authorization': `Bearer ${token}` }
                });
                const servData = await servRes.json();
                
                if (servData.services && servData.services.length > 0) {
                    provider = p;
                    service = servData.services[0];
                    console.log(`✅ Found Valid Service: ${service.service_name} (ID: ${service.id})`);
                    break;
                }
            } catch (err) {
                console.log(`   ⚠️ Failed to check provider ${p.id}: ${err.message}`);
            }
        }

        if (!provider || !service) {
             throw new Error('❌ None of the providers have any services! Cannot test booking.');
        }

        // ------------------------------------------------
        // 5. CREATE BOOKING
        // ------------------------------------------------
        console.log('\n5. Creating Booking...');
        const now = new Date();
        // Add 1 hour to current time for slot
        now.setHours(now.getHours() + 1);
        const hour = now.getHours().toString().padStart(2, '0');
        // Round to next 30 mins just in case, or use 00
        const minute = '00'; 
        const bookingDate = new Date().toISOString().split('T')[0];
        const slotTime = `${hour}:${minute}`;

        console.log(`   Trying to book: ${bookingDate} at ${slotTime}`);
        
        const bookPayload = {
            provider_id: provider.id,
            service_id: service.id,
            booking_date: bookingDate,
            slot_time: slotTime
        };

        const bookRes = await fetch(`${BASE_URL}/bookings`, {
            method: 'POST',
            headers: { 
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify(bookPayload)
        });
        
        const bookData = await bookRes.json();
        if (!bookRes.ok) {
             throw new Error(`Booking failed: ${JSON.stringify(bookData)}`);
        }
        
        const bookingId = bookData.booking.id;
        console.log(`✅ Booking Confirmed! ID: ${bookingId}`);
        console.log(`   Token: ${bookData.booking.token_number}`);
        console.log(`   Queue Position: ${bookData.booking.queue_position}`);

        // ------------------------------------------------
        // 6. CHECK QUEUE STATUS
        // ------------------------------------------------
        console.log('\n6. Checking Queue Status (Customer API)...');
        const queueRes = await fetch(`${BASE_URL}/customer/queue/status`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        const queueData = await queueRes.json();
        
        if (!queueRes.ok) throw new Error(`Queue fetch failed: ${JSON.stringify(queueData)}`);
        
        // Find our booking within the bookings array
        const myToken = queueData.bookings ? queueData.bookings.find(t => t.id === bookingId) : null;
        
        if (myToken) {
            console.log('\n🎉 SUCCESS: Booking found in queue status!');
            console.log(`   Token Number: ${myToken.token_number}`);
            console.log(`   Tokens Ahead: ${myToken.tokens_ahead}`);
            console.log(`   Estimated Wait: ${myToken.estimated_wait_minutes} mins`);
            console.log(`   Status: ${myToken.status}`);
        } else {
            console.error('\n❌ FAILURE: Newly created booking NOT found in queue status response.');
            console.log('Response was:', JSON.stringify(queueData, null, 2));
        }

    } catch (error) {
        console.error('\n❌ TEST FAILED:', error.message);
        if (error.stack) console.error(error.stack);
        process.exit(1);
    }
}

runTest();
