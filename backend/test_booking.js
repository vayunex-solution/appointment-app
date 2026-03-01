const axios = require('axios');
const API_URL = 'https://api.booknex.vayunexsolution.com/api';

async function testBooking() {
    try {
        console.log('--- Registering temporary test customer ---');
        const email = `test_c_${Math.random().toString(36).substring(7)}@test.com`;
        const mobile = '9' + Math.floor(100000000 + Math.random() * 900000000).toString();

        await axios.post(`${API_URL}/auth/register/customer`, {
            name: 'Test Customer', email, mobile, password: 'password123'
        });

        // The user's screenshot uses ID=6 for clinic "software company" 
        // Let's hardcode provider ID 6 to replicate the EXACT user error.
        const providerId = 6;
        console.log('Using test provider ID:', providerId);

        // Fetch Services
        const servicesRes = await axios.get(`${API_URL}/customer/providers/${providerId}/services`);
        
        const serviceId = servicesRes.data.services[0].id;
        console.log('Using Service ID:', serviceId);

        // Try booking directly! But first let me login. The user who is testing is NOT VERIFIED.
        // Wait, the new customer I just registered is NOT VERIFIED, so I cannot login normally due to requireVerified.
        console.log('Script aborted: I cannot test this without direct DB access to verify my test user or by guessing the user admin credentials.');

    } catch (e) {
        if (e.response) {
            console.error('\n--- API RETURNED AN ERROR ---');
            console.error('Status:', e.response.status);
            console.error('Data Payload:', JSON.stringify(e.response.data, null, 2));
            if (typeof e.response.data === 'string') {
                console.error('Raw HTML summary:', e.response.data.substring(0, 500));
            }
        } else {
            console.error('Request failed without a response:', e.message);
        }
    }
}

testBooking();
