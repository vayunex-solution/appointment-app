const express = require('express');
const router = express.Router();
const { authenticate, requireVerified, requireRole } = require('../middleware/auth');
const db = require('../config/db');
const Provider = require('../models/Provider');
const User = require('../models/User');

// All admin routes require authentication + verified + admin role
router.use(authenticate, requireVerified, requireRole('admin'));

// Get pending providers
router.get('/providers/pending', async (req, res) => {
    try {
        const providers = await Provider.getPending();
        res.json({ providers });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch pending providers' });
    }
});

// Approve provider
router.put('/providers/:id/approve', async (req, res) => {
    try {
        await Provider.setApproval(req.params.id, true);
        res.json({ message: 'Provider approved' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to approve provider' });
    }
});

// Reject provider
router.put('/providers/:id/reject', async (req, res) => {
    try {
        await Provider.setApproval(req.params.id, false);
        res.json({ message: 'Provider rejected' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to reject provider' });
    }
});

// Get all users
router.get('/users', async (req, res) => {
    try {
        const [users] = await db.execute(
            'SELECT id, name, email, mobile, role, is_verified, is_blocked, created_at FROM users'
        );
        res.json({ users });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch users' });
    }
});

// Block user
router.put('/users/:id/block', async (req, res) => {
    try {
        await User.setBlocked(req.params.id, true);
        res.json({ message: 'User blocked' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to block user' });
    }
});

// Unblock user
router.put('/users/:id/unblock', async (req, res) => {
    try {
        await User.setBlocked(req.params.id, false);
        res.json({ message: 'User unblocked' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to unblock user' });
    }
});

// Get reports
router.get('/reports', async (req, res) => {
    try {
        const [userStats] = await db.execute(
            `SELECT role, COUNT(*) as count FROM users GROUP BY role`
        );
        const [bookingStats] = await db.execute(
            `SELECT status, COUNT(*) as count FROM appointments GROUP BY status`
        );
        const [revenue] = await db.execute(
            `SELECT SUM(locked_price) as total FROM appointments WHERE status = 'completed'`
        );

        res.json({
            users: userStats,
            bookings: bookingStats,
            totalRevenue: revenue[0]?.total || 0
        });
    } catch (error) {
        res.status(500).json({ error: 'Failed to generate reports' });
    }
});

// Get login logs
router.get('/logs', async (req, res) => {
    try {
        const [logs] = await db.execute(
            `SELECT l.*, u.name, u.email 
       FROM login_logs l 
       LEFT JOIN users u ON l.user_id = u.id 
       ORDER BY l.created_at DESC 
       LIMIT 100`
        );
        res.json({ logs });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch logs' });
    }
});

module.exports = router;
