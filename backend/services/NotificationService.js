/**
 * NotificationService.js — FCM Push Notification Sender
 * 
 * Sends push notifications via Firebase Cloud Messaging and
 * stores notification history in the database for the dashboard.
 */
const { getMessaging } = require('../config/firebase');
const db = require('../config/db');

class NotificationService {

  /**
   * Send push notification to a specific user.
   * Sends to ALL registered devices for that user.
   * Also stores in notification history for dashboard.
   */
  static async sendToUser(userId, { title, body, type = 'general', data = {} }) {
    try {
      // Store notification in DB for dashboard
      await db.execute(
        `INSERT INTO notifications (user_id, title, body, type, data) VALUES (?, ?, ?, ?, ?)`,
        [userId, title, body, type, JSON.stringify(data)]
      );

      // Get all FCM tokens for this user
      const [tokens] = await db.execute(
        'SELECT fcm_token FROM fcm_tokens WHERE user_id = ?',
        [userId]
      );

      if (tokens.length === 0) {
        console.log(`No FCM tokens for user ${userId}, notification stored in DB only.`);
        return { stored: true, pushed: false };
      }

      const messaging = getMessaging();
      if (!messaging) {
        console.log('Firebase not initialized, notification stored in DB only.');
        return { stored: true, pushed: false };
      }

      // Send to all devices
      const fcmTokens = tokens.map(t => t.fcm_token);
      const invalidTokens = [];

      for (const token of fcmTokens) {
        try {
          await messaging.send({
            token,
            notification: {
              title,
              body,
            },
            android: {
              priority: 'high',
              notification: {
                channelId: 'queue_alerts',
                priority: 'max',
                defaultSound: true,
                defaultVibrateTimings: true,
                visibility: 'public', // Show on lock screen
                icon: 'launcher_icon',
              }
            },
            data: {
              type,
              click_action: 'FLUTTER_NOTIFICATION_CLICK',
              ...Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)]))
            }
          });
        } catch (sendErr) {
          if (sendErr.code === 'messaging/registration-token-not-registered' ||
              sendErr.code === 'messaging/invalid-registration-token') {
            invalidTokens.push(token);
          }
          console.error(`FCM send error for token ${token.substring(0, 20)}...:`, sendErr.code);
        }
      }

      // Clean up invalid tokens
      if (invalidTokens.length > 0) {
        for (const t of invalidTokens) {
          await db.execute('DELETE FROM fcm_tokens WHERE fcm_token = ?', [t]);
        }
        console.log(`Cleaned ${invalidTokens.length} invalid FCM tokens`);
      }

      return { stored: true, pushed: true, deviceCount: fcmTokens.length - invalidTokens.length };
    } catch (error) {
      console.error('NotificationService.sendToUser error:', error.message);
      return { stored: false, pushed: false, error: error.message };
    }
  }

  /**
   * Send booking confirmed notification
   */
  static async sendBookingConfirmed(customerId, { tokenNumber, shopName, date, time, serviceName }) {
    return this.sendToUser(customerId, {
      title: '✅ Booking Confirmed!',
      body: `Token ${tokenNumber} at ${shopName} on ${date} at ${time} for ${serviceName}`,
      type: 'booking_confirmed',
      data: { tokenNumber, shopName, date, time }
    });
  }

  /**
   * Send "Your Turn" notification — HIGH PRIORITY
   */
  static async sendYourTurn(customerId, { shopName, tokenNumber }) {
    return this.sendToUser(customerId, {
      title: '🔔 IT\'S YOUR TURN!',
      body: `Token ${tokenNumber} — You are being served now at ${shopName}. Please proceed!`,
      type: 'your_turn',
      data: { shopName, tokenNumber, urgent: 'true' }
    });
  }

  /**
   * Send "Turn Approaching" notification
   */
  static async sendTurnApproaching(customerId, { tokensAhead, shopName, tokenNumber }) {
    const messages = {
      1: '⚡ You\'re NEXT!',
      2: '⏳ 2 people ahead of you',
      3: '📍 3 people ahead of you',
    };
    const title = messages[tokensAhead] || `📍 ${tokensAhead} ahead`;

    return this.sendToUser(customerId, {
      title,
      body: `Get ready! Your token ${tokenNumber} at ${shopName} is approaching.`,
      type: 'turn_approaching',
      data: { tokensAhead: String(tokensAhead), shopName, tokenNumber }
    });
  }

  /**
   * Send booking completed notification
   */
  static async sendBookingCompleted(customerId, { shopName, serviceName }) {
    return this.sendToUser(customerId, {
      title: '✅ Appointment Completed',
      body: `Your ${serviceName} at ${shopName} has been completed. Rate your experience!`,
      type: 'booking_completed',
      data: { shopName, serviceName }
    });
  }

  /**
   * Send booking cancelled / skipped notification
   */
  static async sendBookingCancelled(customerId, { shopName, tokenNumber, reason }) {
    return this.sendToUser(customerId, {
      title: '❌ Booking Cancelled',
      body: `Token ${tokenNumber} at ${shopName} has been ${reason || 'cancelled'}.`,
      type: 'booking_cancelled',
      data: { shopName, tokenNumber }
    });
  }

  /**
   * Register FCM token for a user
   */
  static async registerToken(userId, fcmToken, deviceInfo = null) {
    try {
      // Upsert — avoid duplicate tokens
      await db.execute(
        `INSERT INTO fcm_tokens (user_id, fcm_token, device_info)
         VALUES (?, ?, ?)
         ON DUPLICATE KEY UPDATE user_id = ?, device_info = ?, created_at = NOW()`,
        [userId, fcmToken, deviceInfo, userId, deviceInfo]
      );
      return true;
    } catch (error) {
      console.error('Register FCM token error:', error.message);
      return false;
    }
  }

  /**
   * Get notification history for a user
   */
  static async getNotifications(userId, limit = 50, offset = 0) {
    const [rows] = await db.execute(
      `SELECT id, title, body, type, data, is_read, created_at 
       FROM notifications 
       WHERE user_id = ? 
       ORDER BY created_at DESC 
       LIMIT ? OFFSET ?`,
      [userId, limit, offset]
    );
    return rows;
  }

  /**
   * Get unread count
   */
  static async getUnreadCount(userId) {
    const [rows] = await db.execute(
      'SELECT COUNT(*) as count FROM notifications WHERE user_id = ? AND is_read = 0',
      [userId]
    );
    return rows[0].count;
  }

  /**
   * Mark notification as read
   */
  static async markAsRead(notificationId, userId) {
    await db.execute(
      'UPDATE notifications SET is_read = 1 WHERE id = ? AND user_id = ?',
      [notificationId, userId]
    );
  }

  /**
   * Mark all as read
   */
  static async markAllRead(userId) {
    await db.execute(
      'UPDATE notifications SET is_read = 1 WHERE user_id = ? AND is_read = 0',
      [userId]
    );
  }
}

module.exports = NotificationService;
