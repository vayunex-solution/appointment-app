const express = require('express');
const router = express.Router();
const { authenticate, requireVerified, requireRole } = require('../middleware/auth');
const Provider = require('../models/Provider');
const Service = require('../models/Service');
const Booking = require('../models/Booking');

// Browse providers (public)
router.get('/providers', async (req, res) => {
    try {
        const { category, location } = req.query;
        const providers = await Provider.getAllApproved(category, location);
        res.json({ providers });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch providers' });
    }
});

// Get provider details with services (public)
router.get('/providers/:id', async (req, res) => {
    try {
        const [providers] = await require('../config/db').execute(
            `SELECT p.*, u.name, u.email, u.mobile 
       FROM providers p 
       JOIN users u ON p.user_id = u.id 
       WHERE p.id = ? AND p.is_approved = 1`,
            [req.params.id]
        );

        if (providers.length === 0) {
            return res.status(404).json({ error: 'Provider not found' });
        }

        const services = await Service.getByProvider(req.params.id);
        res.json({ provider: providers[0], services });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch provider' });
    }
});

module.exports = router;
