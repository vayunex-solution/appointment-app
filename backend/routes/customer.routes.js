const express = require('express');
const router = express.Router();
const { authenticate, requireVerified, requireRole } = require('../middleware/auth');
const Provider = require('../models/Provider');
const Service = require('../models/Service');
const Booking = require('../models/Booking');
const db = require('../config/db');

// Browse providers (public) with search
router.get('/providers', async (req, res) => {
    try {
        const { category, location, search } = req.query;
        let providers = await Provider.getAllApproved(category, location);
        
        // Apply search filter
        if (search) {
            const searchLower = search.toLowerCase();
            providers = providers.filter(p => 
                p.shop_name.toLowerCase().includes(searchLower) ||
                p.category.toLowerCase().includes(searchLower) ||
                p.name.toLowerCase().includes(searchLower)
            );
        }
        
        res.json({ providers });
    } catch (error) {
        console.error('Get providers error:', error);
        res.status(500).json({ error: 'Failed to fetch providers' });
    }
});

// Get provider details with availability
router.get('/providers/:id', async (req, res) => {
    try {
        const provider = await Provider.findById(req.params.id);
        if (!provider || !provider.is_approved) {
            return res.status(404).json({ error: 'Provider not found' });
        }
        
        const availability = await Provider.getAvailability(provider.id);
        res.json({ provider, availability });
    } catch (error) {
        console.error('Get provider error:', error);
        res.status(500).json({ error: 'Failed to fetch provider' });
    }
});

// Get provider's services
router.get('/providers/:id/services', async (req, res) => {
    try {
        const services = await Service.getByProvider(req.params.id, true);
        res.json({ services });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch services' });
    }
});

// Get available slots for a provider on a date
router.get('/providers/:id/slots', async (req, res) => {
    try {
        const { date } = req.query;
        if (!date) {
            return res.status(400).json({ error: 'Date is required' });
        }

        const providerId = req.params.id;
        const bookingDate = new Date(date);
        const dayOfWeek = bookingDate.getDay();

        // Get provider's availability for this day
        const availability = await Provider.getAvailability(providerId);
        const daySchedule = availability.find(a => a.day_of_week === dayOfWeek);

        if (!daySchedule || !daySchedule.is_active) {
            return res.json({ slots: [], message: 'Provider is not available on this day' });
        }

        // Generate time slots
        const slots = [];
        const startTime = daySchedule.start_time.toString().substring(0, 5);
        const endTime = daySchedule.end_time.toString().substring(0, 5);
        const startParts = startTime.split(':');
        const endParts = endTime.split(':');
        const slotDuration = daySchedule.slot_duration || 30;

        let currentTime = new Date();
        currentTime.setHours(parseInt(startParts[0]), parseInt(startParts[1]), 0, 0);
        
        const endDateTime = new Date();
        endDateTime.setHours(parseInt(endParts[0]), parseInt(endParts[1]), 0, 0);

        // Get existing bookings for this date
        const [existingBookings] = await db.execute(
            `SELECT slot_time FROM appointments 
             WHERE provider_id = ? AND booking_date = ? AND status != 'cancelled'`,
            [providerId, date]
        );
        const bookedSlots = existingBookings.map(b => b.slot_time.substring(0, 5));

        while (currentTime < endDateTime) {
            const timeStr = currentTime.toTimeString().substring(0, 5);
            slots.push({
                time: timeStr,
                available: !bookedSlots.includes(timeStr),
            });
            currentTime.setMinutes(currentTime.getMinutes() + slotDuration);
        }

        res.json({ slots, date, dayOfWeek });
    } catch (error) {
        console.error('Get slots error:', error);
        res.status(500).json({ error: 'Failed to fetch slots' });
    }
});

// Get categories list
router.get('/categories', async (req, res) => {
    try {
        const [rows] = await db.execute(
            `SELECT DISTINCT category FROM providers WHERE is_approved = 1 ORDER BY category`
        );
        const categories = rows.map(r => r.category);
        res.json({ categories });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch categories' });
    }
});

module.exports = router;
