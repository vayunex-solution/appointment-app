const express = require('express');
const router = express.Router();
const { authenticate, requireVerified } = require('../middleware/auth');
const { bookingValidation } = require('../middleware/validator');
const Booking = require('../models/Booking');
const Service = require('../models/Service');
const { sendEmail, emailTemplates } = require('../config/smtp');
const User = require('../models/User');
const Provider = require('../models/Provider');

// All booking routes require authentication + verified
router.use(authenticate, requireVerified);

// Create booking
router.post('/', bookingValidation, async (req, res) => {
    try {
        const { provider_id, service_id, booking_date, slot_time } = req.body;

        // Check slot availability
        const available = await Booking.checkSlotAvailable(provider_id, booking_date, slot_time);
        if (!available) {
            return res.status(400).json({ error: 'Slot not available' });
        }

        // Get service for locked price
        const service = await Service.findById(service_id);
        if (!service) {
            return res.status(404).json({ error: 'Service not found' });
        }

        // Create booking
        const bookingResult = await Booking.create({
            customer_id: req.user.id,
            provider_id,
            service_id,
            booking_date,
            slot_time,
            locked_price: service.rate
        });

        // Handle duplicate slot error from atomic create
        if (bookingResult.error) {
            return res.status(400).json({ error: bookingResult.error });
        }

        const { id, token_number, queue_position } = bookingResult;

        // Send confirmation email
        const user = await User.findById(req.user.id);
        const providerData = await require('../config/db').execute(
            'SELECT shop_name FROM providers WHERE id = ?',
            [provider_id]
        );

        try {
            await sendEmail(
                user.email,
                'Booking Confirmed',
                emailTemplates.bookingConfirmation(user.name, {
                    token: token_number,
                    serviceName: service.service_name,
                    providerName: providerData[0][0]?.shop_name,
                    date: booking_date,
                    time: slot_time,
                    amount: service.rate
                })
            );
        } catch (emailErr) {
            console.error('Email send failed (non-blocking):', emailErr.message);
        }

        res.status(201).json({
            message: 'Booking confirmed',
            booking: { id, token_number, queue_position, date: booking_date, time: slot_time }
        });
    } catch (error) {
        console.error('Booking error:', error);
        res.status(500).json({ error: 'Booking failed' });
    }
});

// Get my bookings
router.get('/my', async (req, res) => {
    try {
        const bookings = await Booking.getByCustomer(req.user.id);
        res.json({ bookings });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch bookings' });
    }
});

// Get booking details
router.get('/:id', async (req, res) => {
    try {
        const booking = await Booking.findById(req.params.id);
        if (!booking || booking.customer_id !== req.user.id) {
            return res.status(404).json({ error: 'Booking not found' });
        }
        res.json({ booking });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch booking' });
    }
});

// Reschedule booking
router.put('/:id/reschedule', async (req, res) => {
    try {
        const { new_date, new_time } = req.body;
        const booking = await Booking.findById(req.params.id);

        if (!booking || booking.customer_id !== req.user.id) {
            return res.status(404).json({ error: 'Booking not found' });
        }

        if (booking.status !== 'pending' && booking.status !== 'confirmed') {
            return res.status(400).json({ error: 'Cannot reschedule this booking' });
        }

        // Check new slot availability
        const available = await Booking.checkSlotAvailable(booking.provider_id, new_date, new_time);
        if (!available) {
            return res.status(400).json({ error: 'New slot not available' });
        }

        await Booking.reschedule(req.params.id, new_date, new_time);
        res.json({ message: 'Booking rescheduled' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to reschedule' });
    }
});

// Cancel booking
router.put('/:id/cancel', async (req, res) => {
    try {
        const booking = await Booking.findById(req.params.id);

        if (!booking || booking.customer_id !== req.user.id) {
            return res.status(404).json({ error: 'Booking not found' });
        }

        if (booking.status === 'completed' || booking.status === 'cancelled') {
            return res.status(400).json({ error: 'Cannot cancel this booking' });
        }

        await Booking.updateStatus(req.params.id, 'cancelled');
        res.json({ message: 'Booking cancelled' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to cancel' });
    }
});

module.exports = router;
