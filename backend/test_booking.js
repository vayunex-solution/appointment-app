const axios = require('axios');
const fs = require('fs');
const API_URL = 'https://api.booknex.vayunexsolution.com/api';

async function testBooking() {
    try {
        const loginRes = await axios.post(`${API_URL}/auth/login`, {
            identifier: 'erp@agrosaw.com',
            password: 'Test@1234'
        });
        const token = loginRes.data.token;
        
        const providersRes = await axios.get(`${API_URL}/customer/providers`, {
            headers: { Authorization: `Bearer ${token}` }
        });

        const providers = providersRes.data.providers || [];
        let targetProviderId = null;
        let targetServiceId = null;

        for (let p of providers) {
            try {
                const servicesRes = await axios.get(`${API_URL}/customer/providers/${p.id}/services`, {
                    headers: { Authorization: `Bearer ${token}` }
                });
                const services = servicesRes.data.services || [];
                if (services.length > 0) {
                    targetProviderId = p.id;
                    targetServiceId = services[0].id;
                    break;
                }
            } catch (err) { }
        }

        const bookingPayload = {
            provider_id: targetProviderId,
            service_id: targetServiceId,
            booking_date: '2026-06-16',
            slot_time: '12:00'
        };
        
        await axios.post(`${API_URL}/bookings`, bookingPayload, {
            headers: { Authorization: `Bearer ${token}` }
        });

        fs.writeFileSync('test_output2.txt', "SUCCESS");

    } catch (e) {
        if (e.response) {
            const out = {
                status: e.response.status,
                data: e.response.data
            };
            fs.writeFileSync('test_output2.txt', JSON.stringify(out, null, 2));
        } else {
            fs.writeFileSync('test_output2.txt', e.message);
        }
    }
}
testBooking();
