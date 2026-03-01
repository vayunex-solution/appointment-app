const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const NotificationService = require('../services/NotificationService');

// All routes require authentication
router.use(authenticate);

// Register FCM device token
router.post('/register-device', async (req, res) => {
    try {
        const { fcm_token, device_info } = req.body;

        if (!fcm_token) {
            return res.status(400).json({ error: 'FCM token is required' });
        }

        await NotificationService.registerToken(req.user.id, fcm_token, device_info);
        res.json({ message: 'Device registered successfully' });
    } catch (error) {
        console.error('Register device error:', error);
        res.status(500).json({ error: 'Failed to register device' });
    }
});

// Get notification history (for dashboard)
router.get('/', async (req, res) => {
    try {
        const limit = parseInt(req.query.limit) || 50;
        const offset = parseInt(req.query.offset) || 0;

        const notifications = await NotificationService.getNotifications(req.user.id, limit, offset);
        const unreadCount = await NotificationService.getUnreadCount(req.user.id);

        res.json({ notifications, unread_count: unreadCount });
    } catch (error) {
        console.error('Get notifications error:', error);
        res.status(500).json({ error: 'Failed to fetch notifications' });
    }
});

// Get unread count only (for badge)
router.get('/unread-count', async (req, res) => {
    try {
        const count = await NotificationService.getUnreadCount(req.user.id);
        res.json({ unread_count: count });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch unread count' });
    }
});

// Mark single notification as read
router.patch('/:id/read', async (req, res) => {
    try {
        await NotificationService.markAsRead(parseInt(req.params.id), req.user.id);
        res.json({ message: 'Marked as read' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to mark as read' });
    }
});

// Mark all notifications as read
router.patch('/read-all', async (req, res) => {
    try {
        await NotificationService.markAllRead(req.user.id);
        res.json({ message: 'All notifications marked as read' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to mark all as read' });
    }
});

module.exports = router;
