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
// BOOKING STATUS UPDATE (used by provider_bookings_screen)
// ========================

router.patch('/bookings/:id/status', async (req, res) => {
    try {
        const provider = await Provider.findByUserId(req.user.id);
        const { status } = req.body;
        const bookingId = parseInt(req.params.id);

        if (!['running', 'completed', 'skipped', 'cancelled'].includes(status)) {
            return res.status(400).json({ error: 'Invalid status' });
        }

        const QueueEngine = require('../services/QueueEngine');
        let result;

        switch (status) {
            case 'running':
                // Set started_at and update queue_stats
                await db.execute(
                    `UPDATE appointments SET status = 'running', started_at = NOW() WHERE id = ? AND provider_id = ?`,
                    [bookingId, provider.id]
                );
                await db.execute(
                    `INSERT INTO queue_stats (provider_id, queue_date, current_running_token_id, last_updated)
                     VALUES (?, CURDATE(), ?, NOW())
                     ON DUPLICATE KEY UPDATE current_running_token_id = ?, last_updated = NOW()`,
                    [provider.id, bookingId, bookingId]
                );
                result = { success: true };
                break;
            case 'completed':
                result = await QueueEngine.completeToken(provider.id, bookingId);
                break;
            case 'skipped':
                result = await QueueEngine.skipToken(provider.id, bookingId);
                break;
            case 'cancelled':
                result = await QueueEngine.cancelToken(provider.id, bookingId);
                break;
        }

        if (result?.error) {
            return res.status(400).json({ error: result.error });
        }

        res.json({ message: `Booking ${status}` });
    } catch (error) {
        console.error('Booking status update error:', error);
        res.status(500).json({ error: 'Failed to update booking status' });
    }
});

// ========================
// QUEUE MANAGEMENT (QueueEngine)
// ========================
const QueueEngine = require('../services/QueueEngine');

// Get today's queue (full data)
router.get('/queue/today', async (req, res) => {
    try {
        const provider = await Provider.findByUserId(req.user.id);
        const data = await QueueEngine.getProviderQueue(provider.id);
        res.json(data);
    } catch (error) {
        console.error('Queue fetch error:', error);
        res.status(500).json({ error: 'Failed to fetch queue' });
    }
});

// Call next token (strict FIFO)
router.patch('/queue/call-next', async (req, res) => {
    try {
        const provider = await Provider.findByUserId(req.user.id);
        const result = await QueueEngine.callNextToken(provider.id);

        if (!result) {
            return res.json({ message: 'Queue is empty', queue_empty: true });
        }
        if (result.error) {
            return res.status(400).json({ error: result.error });
        }

        // Get updated queue
        const queueData = await QueueEngine.getProviderQueue(provider.id);
        res.json({ message: 'Token called', calledToken: result, ...queueData });
    } catch (error) {
        console.error('Call next error:', error);
        res.status(500).json({ error: 'Failed to call next token' });
    }
});

// Serve specific token by ID (force serve)
router.patch('/queue/:id/serve', async (req, res) => {
    try {
        const provider = await Provider.findByUserId(req.user.id);
        const result = await QueueEngine.callNextToken(provider.id);
        
        if (result?.error) {
            return res.status(400).json({ error: result.error });
        }

        const queueData = await QueueEngine.getProviderQueue(provider.id);
        res.json({ message: 'Now serving', ...queueData });
    } catch (error) {
        res.status(500).json({ error: 'Failed to serve token' });
    }
});

// Complete current token
router.patch('/queue/:id/complete', async (req, res) => {
    try {
        const provider = await Provider.findByUserId(req.user.id);
        const result = await QueueEngine.completeToken(provider.id, parseInt(req.params.id));

        if (result.error) {
            return res.status(400).json({ error: result.error });
        }

        const queueData = await QueueEngine.getProviderQueue(provider.id);
        res.json({ message: 'Token completed', result, ...queueData });
    } catch (error) {
        console.error('Complete error:', error);
        res.status(500).json({ error: 'Failed to complete token' });
    }
});

// Skip token (no-show)
router.patch('/queue/:id/skip', async (req, res) => {
    try {
        const provider = await Provider.findByUserId(req.user.id);
        const result = await QueueEngine.skipToken(provider.id, parseInt(req.params.id));

        if (result.error) {
            return res.status(400).json({ error: result.error });
        }

        const queueData = await QueueEngine.getProviderQueue(provider.id);
        res.json({ message: 'Token skipped', result, ...queueData });
    } catch (error) {
        res.status(500).json({ error: 'Failed to skip token' });
    }
});

// Cancel token
router.patch('/queue/:id/cancel', async (req, res) => {
    try {
        const provider = await Provider.findByUserId(req.user.id);
        const result = await QueueEngine.cancelToken(provider.id, parseInt(req.params.id));

        if (result.error) {
            return res.status(400).json({ error: result.error });
        }

        const queueData = await QueueEngine.getProviderQueue(provider.id);
        res.json({ message: 'Token cancelled', result, ...queueData });
    } catch (error) {
        res.status(500).json({ error: 'Failed to cancel token' });
    }
});

// Toggle priority flag
router.patch('/queue/:id/priority', async (req, res) => {
    try {
        const provider = await Provider.findByUserId(req.user.id);
        const result = await QueueEngine.togglePriority(provider.id, parseInt(req.params.id));

        if (result.error) {
            return res.status(400).json({ error: result.error });
        }

        const queueData = await QueueEngine.getProviderQueue(provider.id);
        res.json({ message: 'Priority updated', result, ...queueData });
    } catch (error) {
        res.status(500).json({ error: 'Failed to toggle priority' });
    }
});

module.exports = router;


