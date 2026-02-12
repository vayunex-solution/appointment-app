const express = require('express');
const router = express.Router();
const { authenticate, requireVerified, requireRole } = require('../middleware/auth');
const { serviceValidation } = require('../middleware/validator');
const Provider = require('../models/Provider');
const Service = require('../models/Service');
const Booking = require('../models/Booking');

// All routes require authentication + verified + provider role
router.use(authenticate, requireVerified, requireRole('provider'));

// Get provider profile
router.get('/profile', async (req, res) => {
    try {
        const provider = await Provider.findByUserId(req.user.id);
        if (!provider) {
            return res.status(404).json({ error: 'Provider profile not found' });
        }
        res.json({ provider });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch profile' });
    }
});

// Update provider profile
router.put('/profile', async (req, res) => {
    try {
        const provider = await Provider.findByUserId(req.user.id);
        if (!provider) {
            return res.status(404).json({ error: 'Provider profile not found' });
        }
        await Provider.updateProfile(provider.id, req.body);
        res.json({ message: 'Profile updated successfully' });
    } catch (error) {
        console.error('Update profile error:', error);
        res.status(500).json({ error: 'Failed to update profile' });
    }
});

// Get dashboard stats
router.get('/dashboard', async (req, res) => {
    try {
        const provider = await Provider.findByUserId(req.user.id);
        const stats = await Provider.getDashboardStats(provider.id);
        res.json({ stats, provider });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch dashboard' });
    }
});

// Get availability
router.get('/availability', async (req, res) => {
    try {
        const provider = await Provider.findByUserId(req.user.id);
        const availability = await Provider.getAvailability(provider.id);
        res.json({ availability });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch availability' });
    }
});

// Set availability (single day)
router.post('/availability', async (req, res) => {
    try {
        const provider = await Provider.findByUserId(req.user.id);
        const id = await Provider.setAvailability(provider.id, req.body);
        res.json({ message: 'Availability set successfully', id });
    } catch (error) {
        console.error('Set availability error:', error);
        res.status(500).json({ error: 'Failed to set availability' });
    }
});

// Set availability (bulk - all days)
router.post('/availability/bulk', async (req, res) => {
    try {
        const provider = await Provider.findByUserId(req.user.id);
        const { schedules } = req.body; // Array of availability objects

        for (const schedule of schedules) {
            await Provider.setAvailability(provider.id, schedule);
        }
        res.json({ message: 'Availability schedule saved' });
    } catch (error) {
        console.error('Bulk availability error:', error);
        res.status(500).json({ error: 'Failed to save availability schedule' });
    }
});

// Get all services
router.get('/services', async (req, res) => {
    try {
        const provider = await Provider.findByUserId(req.user.id);
        const services = await Service.getByProvider(provider.id, false);
        res.json({ services });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch services' });
    }
});

// Add new service
router.post('/services', serviceValidation, async (req, res) => {
    try {
        const provider = await Provider.findByUserId(req.user.id);
        if (!provider.is_approved) {
            return res.status(403).json({ error: 'Your account is pending approval' });
        }

        const serviceId = await Service.create({
            provider_id: provider.id,
            ...req.body
        });
        res.status(201).json({ message: 'Service added', serviceId });
    } catch (error) {
        res.status(500).json({ error: 'Failed to add service' });
    }
});

// Update service
router.put('/services/:id', serviceValidation, async (req, res) => {
    try {
        const service = await Service.findById(req.params.id);
        const provider = await Provider.findByUserId(req.user.id);

        if (!service || service.provider_id !== provider.id) {
            return res.status(404).json({ error: 'Service not found' });
        }

        await Service.update(req.params.id, req.body);
        res.json({ message: 'Service updated' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to update service' });
    }
});

// Toggle service active status
router.patch('/services/:id/toggle', async (req, res) => {
    try {
        const service = await Service.findById(req.params.id);
        const provider = await Provider.findByUserId(req.user.id);

        if (!service || service.provider_id !== provider.id) {
            return res.status(404).json({ error: 'Service not found' });
        }

        await Service.setActive(req.params.id, !service.is_active);
        res.json({ message: `Service ${service.is_active ? 'disabled' : 'enabled'}` });
    } catch (error) {
        res.status(500).json({ error: 'Failed to toggle service' });
    }
});

// Delete service
router.delete('/services/:id', async (req, res) => {
    try {
        const service = await Service.findById(req.params.id);
        const provider = await Provider.findByUserId(req.user.id);

        if (!service || service.provider_id !== provider.id) {
            return res.status(404).json({ error: 'Service not found' });
        }

        await Service.delete(req.params.id);
        res.json({ message: 'Service deleted' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to delete service' });
    }
});

// Get provider's bookings
router.get('/bookings', async (req, res) => {
    try {
        const provider = await Provider.findByUserId(req.user.id);
        const bookings = await Booking.getByProvider(provider.id);
        res.json({ bookings });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch bookings' });
    }
});

// Update booking status
router.patch('/bookings/:id/status', async (req, res) => {
    try {
        const { status } = req.body;
        const validStatuses = ['confirmed', 'completed', 'cancelled'];

        if (!validStatuses.includes(status)) {
            return res.status(400).json({ error: 'Invalid status' });
        }

        await Booking.updateStatus(req.params.id, status);
        res.json({ message: 'Booking status updated' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to update booking' });
    }
});

// Get wallet balance
router.get('/wallet', async (req, res) => {
    try {
        const provider = await Provider.findByUserId(req.user.id);
        const balance = await Provider.getWalletBalance(provider.id);
        res.json({ balance });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch wallet' });
    }
});

// ========================
// QUEUE MANAGEMENT
// ========================

// Get today's queue
router.get('/queue/today', async (req, res) => {
    try {
        const provider = await Provider.findByUserId(req.user.id);
        const [rows] = await require('../config/db').execute(
            `SELECT a.*, s.service_name, u.name as customer_name, u.mobile as customer_mobile
             FROM appointments a
             JOIN services s ON a.service_id = s.id
             JOIN users u ON a.customer_id = u.id
             WHERE a.provider_id = ? AND DATE(a.booking_date) = CURDATE()
             AND a.status != 'cancelled'
             ORDER BY a.queue_number ASC, a.slot_time ASC`,
            [provider.id]
        );

        // Find currently serving
        const serving = rows.find(r => r.status === 'confirmed');
        
        res.json({ 
            queue: rows, 
            currentServing: serving || null,
            totalInQueue: rows.filter(r => r.status === 'pending').length,
            completed: rows.filter(r => r.status === 'completed').length
        });
    } catch (error) {
        console.error('Queue error:', error);
        res.status(500).json({ error: 'Failed to fetch queue' });
    }
});

// Serve next token (mark as confirmed/serving)
router.patch('/queue/:id/serve', async (req, res) => {
    try {
        const provider = await Provider.findByUserId(req.user.id);
        const booking = await Booking.findById(req.params.id);

        if (!booking || booking.provider_id !== provider.id) {
            return res.status(404).json({ error: 'Booking not found' });
        }

        await require('../config/db').execute(
            `UPDATE appointments SET status = 'confirmed', served_at = NOW() WHERE id = ?`,
            [req.params.id]
        );
        
        res.json({ message: 'Now serving this customer' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to update queue' });
    }
});

// Complete current token
router.patch('/queue/:id/complete', async (req, res) => {
    try {
        const provider = await Provider.findByUserId(req.user.id);
        const booking = await Booking.findById(req.params.id);

        if (!booking || booking.provider_id !== provider.id) {
            return res.status(404).json({ error: 'Booking not found' });
        }

        await require('../config/db').execute(
            `UPDATE appointments SET status = 'completed', completed_at = NOW() WHERE id = ?`,
            [req.params.id]
        );
        
        res.json({ message: 'Service completed' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to complete' });
    }
});

// Skip / No-show
router.patch('/queue/:id/skip', async (req, res) => {
    try {
        const provider = await Provider.findByUserId(req.user.id);
        const booking = await Booking.findById(req.params.id);

        if (!booking || booking.provider_id !== provider.id) {
            return res.status(404).json({ error: 'Booking not found' });
        }

        await require('../config/db').execute(
            `UPDATE appointments SET status = 'cancelled' WHERE id = ?`,
            [req.params.id]
        );
        
        res.json({ message: 'Customer skipped' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to skip' });
    }
});

module.exports = router;

