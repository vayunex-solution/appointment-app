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

module.exports = router;
