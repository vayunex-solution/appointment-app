/**
 * TurnAlertService.js — Automatic Turn-Based Alert Triggers
 * 
 * Called after every queue mutation (call-next, complete, skip).
 * Calculates who is 1/2/3 positions ahead and sends FCM push alerts.
 */
const db = require('../config/db');
const NotificationService = require('./NotificationService');

class TurnAlertService {

  /**
   * Send alerts to upcoming customers after a queue mutation.
   * Call this after: callNextToken, completeToken, skipToken
   * 
   * @param {number} providerId — The provider whose queue changed
   */
  static async sendUpcomingAlerts(providerId) {
    try {
      // Get provider shop name
      const [providerRows] = await db.execute(
        'SELECT shop_name FROM providers WHERE id = ?',
        [providerId]
      );
      if (providerRows.length === 0) return;
      const shopName = providerRows[0].shop_name;

      // Get currently running token (if any)
      const [running] = await db.execute(
        `SELECT id, customer_id, token_number FROM appointments 
         WHERE provider_id = ? AND booking_date = CURDATE() AND status = 'running'
         LIMIT 1`,
        [providerId]
      );

      // Send "YOUR TURN" to the running customer
      if (running.length > 0) {
        await NotificationService.sendYourTurn(running[0].customer_id, {
          shopName,
          tokenNumber: running[0].token_number
        });
      }

      // Get next pending tokens in queue order (top 3)
      const [upcoming] = await db.execute(
        `SELECT a.id, a.customer_id, a.token_number, a.queue_number
         FROM appointments a
         WHERE a.provider_id = ? AND a.booking_date = CURDATE() AND a.status = 'pending'
         ORDER BY a.queue_number ASC
         LIMIT 3`,
        [providerId]
      );

      // Send "turn approaching" alerts
      for (let i = 0; i < upcoming.length; i++) {
        const tokensAhead = i + 1; // 1st pending = 1 ahead, 2nd = 2 ahead, etc.
        
        // Only send alerts for positions 1-3
        if (tokensAhead <= 3) {
          await NotificationService.sendTurnApproaching(upcoming[i].customer_id, {
            tokensAhead,
            shopName,
            tokenNumber: upcoming[i].token_number
          });
        }
      }

    } catch (error) {
      console.error('TurnAlertService error:', error.message);
      // Non-blocking: don't let notification errors break queue operations
    }
  }

  /**
   * Send completion notification to a customer
   */
  static async sendCompletionAlert(customerId, providerId) {
    try {
      const [provider] = await db.execute(
        `SELECT p.shop_name, s.service_name 
         FROM providers p
         JOIN appointments a ON a.provider_id = p.id
         JOIN services s ON a.service_id = s.id
         WHERE p.id = ? AND a.customer_id = ? AND a.status = 'completed'
         ORDER BY a.completed_at DESC LIMIT 1`,
        [providerId, customerId]
      );

      if (provider.length > 0) {
        await NotificationService.sendBookingCompleted(customerId, {
          shopName: provider[0].shop_name,
          serviceName: provider[0].service_name
        });
      }
    } catch (error) {
      console.error('Completion alert error:', error.message);
    }
  }

  /**
   * Send skip/cancel notification to a customer
   */
  static async sendSkipAlert(customerId, providerId, tokenNumber, reason) {
    try {
      const [provider] = await db.execute(
        'SELECT shop_name FROM providers WHERE id = ?',
        [providerId]
      );

      if (provider.length > 0) {
        await NotificationService.sendBookingCancelled(customerId, {
          shopName: provider[0].shop_name,
          tokenNumber,
          reason
        });
      }
    } catch (error) {
      console.error('Skip alert error:', error.message);
    }
  }
}

module.exports = TurnAlertService;
