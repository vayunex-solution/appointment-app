/**
 * QueueEngine.js — Atomic FIFO Queue Engine
 * 
 * All queue operations use MySQL transactions with SELECT ... FOR UPDATE
 * to prevent race conditions and ensure strict FIFO ordering.
 */

const db = require('../config/db');

class QueueEngine {

  // ========================================
  // ATOMIC QUEUE POSITION ASSIGNMENT
  // ========================================

  /**
   * Assign next queue position for a provider on a given date.
   * Uses transaction + FOR UPDATE lock to prevent race conditions.
   * @returns {number} The assigned queue_position
   */
  static async assignQueuePosition(providerId, bookingDate) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();

      // Lock the row to prevent concurrent reads
      const [rows] = await connection.execute(
        `SELECT COALESCE(MAX(queue_position), 0) as max_pos 
         FROM appointments 
         WHERE provider_id = ? AND booking_date = ?
         FOR UPDATE`,
        [providerId, bookingDate]
      );

      const nextPosition = rows[0].max_pos + 1;

      await connection.commit();
      return nextPosition;
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }

  // ========================================
  // CALL NEXT TOKEN (FIFO)
  // ========================================

  /**
   * Call the next token in queue. Strict FIFO with priority override.
   * - First checks for priority_flag = true tokens
   * - Then picks lowest queue_position with status = 'pending'
   * - Marks it as 'running' atomically
   * @returns {object|null} The called token or null if queue empty
   */
  static async callNextToken(providerId) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();

      // Check if there's already a running token
      const [running] = await connection.execute(
        `SELECT id FROM appointments 
         WHERE provider_id = ? AND booking_date = CURDATE() AND status = 'running'
         FOR UPDATE`,
        [providerId]
      );

      if (running.length > 0) {
        await connection.rollback();
        return { error: 'Complete the current token first', currentRunning: running[0].id };
      }

      // Pick next: priority first, then FIFO
      const [next] = await connection.execute(
        `SELECT a.id, a.token_number, a.queue_position, a.customer_id,
                a.service_id, a.priority_flag,
                u.name as customer_name, u.mobile as customer_mobile,
                s.service_name
         FROM appointments a
         JOIN users u ON a.customer_id = u.id
         JOIN services s ON a.service_id = s.id
         WHERE a.provider_id = ? AND a.booking_date = CURDATE() AND a.status = 'pending'
         ORDER BY a.priority_flag DESC, a.queue_position ASC
         LIMIT 1
         FOR UPDATE`,
        [providerId]
      );

      if (next.length === 0) {
        await connection.commit();
        return null; // Queue empty
      }

      const token = next[0];

      // Mark as running
      await connection.execute(
        `UPDATE appointments SET status = 'running', started_at = NOW() WHERE id = ?`,
        [token.id]
      );

      // Update queue_stats
      await connection.execute(
        `INSERT INTO queue_stats (provider_id, queue_date, current_running_token_id, last_updated)
         VALUES (?, CURDATE(), ?, NOW())
         ON DUPLICATE KEY UPDATE current_running_token_id = ?, last_updated = NOW()`,
        [providerId, token.id, token.id]
      );

      await connection.commit();
      return token;
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }

  // ========================================
  // COMPLETE CURRENT TOKEN
  // ========================================

  /**
   * Complete the currently running token.
   * Updates average_service_time using rolling avg of last 20.
   * @returns {object} Result with completed token info
   */
  static async completeToken(providerId, tokenId) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();

      // Verify this token is actually running for this provider
      const [token] = await connection.execute(
        `SELECT id, started_at, customer_id FROM appointments 
         WHERE id = ? AND provider_id = ? AND status = 'running'
         FOR UPDATE`,
        [tokenId, providerId]
      );

      if (token.length === 0) {
        await connection.rollback();
        return { error: 'Token not found or not currently running' };
      }

      // Mark completed
      await connection.execute(
        `UPDATE appointments SET status = 'completed', completed_at = NOW() WHERE id = ?`,
        [tokenId]
      );

      // Calculate service duration
      const startedAt = token[0].started_at;
      const serviceDuration = Math.floor((Date.now() - new Date(startedAt).getTime()) / 1000);

      // Update rolling average (last 20 completed tokens)
      const [avgRows] = await connection.execute(
        `SELECT AVG(TIMESTAMPDIFF(SECOND, started_at, completed_at)) as avg_time
         FROM (
           SELECT started_at, completed_at FROM appointments
           WHERE provider_id = ? AND status = 'completed' 
           AND started_at IS NOT NULL AND completed_at IS NOT NULL
           ORDER BY completed_at DESC LIMIT 20
         ) as recent`,
        [providerId]
      );

      const avgServiceTime = Math.round(avgRows[0].avg_time || 900);

      // Update queue_stats
      await connection.execute(
        `INSERT INTO queue_stats (provider_id, queue_date, current_running_token_id, average_service_time, total_served, last_updated)
         VALUES (?, CURDATE(), NULL, ?, 1, NOW())
         ON DUPLICATE KEY UPDATE 
           current_running_token_id = NULL,
           average_service_time = ?,
           total_served = total_served + 1,
           last_updated = NOW()`,
        [providerId, avgServiceTime, avgServiceTime]
      );

      await connection.commit();
      return {
        completed: true,
        tokenId,
        serviceDuration,
        avgServiceTime,
        customerId: token[0].customer_id
      };
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }

  // ========================================
  // SKIP TOKEN (NO-SHOW)
  // ========================================

  /**
   * Skip a token (no-show or provider skip).
   * Can skip the running token or any pending token.
   */
  static async skipToken(providerId, tokenId) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();

      const [token] = await connection.execute(
        `SELECT id, status, customer_id FROM appointments 
         WHERE id = ? AND provider_id = ? AND status IN ('pending', 'running')
         FOR UPDATE`,
        [tokenId, providerId]
      );

      if (token.length === 0) {
        await connection.rollback();
        return { error: 'Token not found or already processed' };
      }

      await connection.execute(
        `UPDATE appointments SET status = 'skipped' WHERE id = ?`,
        [tokenId]
      );

      // If we skipped the running token, clear queue_stats
      if (token[0].status === 'running') {
        await connection.execute(
          `UPDATE queue_stats SET current_running_token_id = NULL, last_updated = NOW()
           WHERE provider_id = ? AND queue_date = CURDATE()`,
          [providerId]
        );
      }

      await connection.commit();
      return { skipped: true, tokenId, customerId: token[0].customer_id };
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }

  // ========================================
  // CANCEL TOKEN
  // ========================================

  static async cancelToken(providerId, tokenId) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();

      const [token] = await connection.execute(
        `SELECT id, status, customer_id FROM appointments 
         WHERE id = ? AND provider_id = ? AND status IN ('pending', 'running')
         FOR UPDATE`,
        [tokenId, providerId]
      );

      if (token.length === 0) {
        await connection.rollback();
        return { error: 'Token not found or already processed' };
      }

      await connection.execute(
        `UPDATE appointments SET status = 'cancelled' WHERE id = ?`,
        [tokenId]
      );

      if (token[0].status === 'running') {
        await connection.execute(
          `UPDATE queue_stats SET current_running_token_id = NULL, last_updated = NOW()
           WHERE provider_id = ? AND queue_date = CURDATE()`,
          [providerId]
        );
      }

      await connection.commit();
      return { cancelled: true, tokenId, customerId: token[0].customer_id };
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }

  // ========================================
  // GET FULL QUEUE (for provider)
  // ========================================

  /**
   * Get today's full queue for a provider with all stats.
   */
  static async getProviderQueue(providerId) {
    const [queue] = await db.execute(
      `SELECT a.id, a.token_number, a.queue_position, a.status, 
              a.priority_flag, a.started_at, a.completed_at,
              a.slot_time, a.locked_price,
              u.name as customer_name, u.mobile as customer_mobile,
              s.service_name
       FROM appointments a
       JOIN users u ON a.customer_id = u.id
       JOIN services s ON a.service_id = s.id
       WHERE a.provider_id = ? AND a.booking_date >= CURDATE()
       ORDER BY 
         CASE a.status 
           WHEN 'running' THEN 0
           WHEN 'pending' THEN 1 
           WHEN 'completed' THEN 2 
           WHEN 'skipped' THEN 3 
           WHEN 'cancelled' THEN 4 
         END,
         a.priority_flag DESC,
         a.queue_position ASC`,
      [providerId]
    );

    // Get stats
    const [stats] = await db.execute(
      `SELECT 
         COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_count,
         COUNT(CASE WHEN status = 'running' THEN 1 END) as running_count,
         COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_count,
         COUNT(CASE WHEN status = 'skipped' THEN 1 END) as skipped_count,
         COUNT(*) as total_count
       FROM appointments 
       WHERE provider_id = ? AND booking_date >= CURDATE()`,
      [providerId]
    );

    // Get average service time
    const [avgRow] = await db.execute(
      `SELECT average_service_time FROM queue_stats 
       WHERE provider_id = ? AND queue_date = CURDATE()`,
      [providerId]
    );

    const currentRunning = queue.find(t => t.status === 'running') || null;

    return {
      queue,
      stats: stats[0],
      currentRunning,
      avgServiceTime: avgRow[0]?.average_service_time || 900
    };
  }

  // ========================================
  // GET CUSTOMER QUEUE STATUS
  // ========================================

  /**
   * Get queue position info for a specific customer's token.
   * Returns: tokens ahead, estimated wait, current serving token.
   */
  static async getCustomerQueueStatus(customerId) {
    // Get customer's active bookings for today
    const [myTokens] = await db.execute(
      `SELECT a.id, a.token_number, a.queue_position, a.status,
              a.priority_flag, a.booking_date, a.slot_time,
              a.provider_id, a.service_id,
              s.service_name, p.shop_name,
              u_provider.name as provider_contact_name
       FROM appointments a
       JOIN services s ON a.service_id = s.id
       JOIN providers p ON a.provider_id = p.id
       JOIN users u_provider ON p.user_id = u_provider.id
       WHERE a.customer_id = ? AND a.booking_date = CURDATE()
       AND a.status IN ('pending', 'running')
       ORDER BY a.queue_position ASC`,
      [customerId]
    );

    // For each token, calculate position data
    const enriched = [];
    for (const token of myTokens) {
      // Count tokens ahead (pending with lower queue_position)
      const [ahead] = await db.execute(
        `SELECT COUNT(*) as tokens_ahead FROM appointments
         WHERE provider_id = ? AND booking_date = CURDATE()
         AND status = 'pending' AND queue_position < ?`,
        [token.provider_id, token.queue_position]
      );

      // Current running token for this provider
      const [running] = await db.execute(
        `SELECT token_number, queue_position FROM appointments
         WHERE provider_id = ? AND booking_date = CURDATE() AND status = 'running'
         LIMIT 1`,
        [token.provider_id]
      );

      // Get avg service time
      const [avgRow] = await db.execute(
        `SELECT average_service_time FROM queue_stats
         WHERE provider_id = ? AND queue_date = CURDATE()`,
        [token.provider_id]
      );

      const tokensAhead = token.status === 'running' ? 0 : ahead[0].tokens_ahead;
      const avgTime = avgRow[0]?.average_service_time || 900;
      // Add 1 for currently running token if exists
      const totalAhead = running.length > 0 && token.status !== 'running'
        ? tokensAhead + 1
        : tokensAhead;

      enriched.push({
        ...token,
        tokens_ahead: totalAhead,
        estimated_wait_seconds: totalAhead * avgTime,
        estimated_wait_minutes: Math.ceil((totalAhead * avgTime) / 60),
        current_serving: running[0] || null,
        is_my_turn: token.status === 'running'
      });
    }

    return enriched;
  }

  // ========================================
  // TOGGLE PRIORITY FLAG
  // ========================================

  static async togglePriority(providerId, tokenId) {
    const [token] = await db.execute(
      `SELECT id, priority_flag FROM appointments 
       WHERE id = ? AND provider_id = ? AND status = 'pending'`,
      [tokenId, providerId]
    );

    if (token.length === 0) {
      return { error: 'Token not found or not pending' };
    }

    const newFlag = !token[0].priority_flag;
    await db.execute(
      `UPDATE appointments SET priority_flag = ? WHERE id = ?`,
      [newFlag, tokenId]
    );

    return { tokenId, priority_flag: newFlag };
  }
}

module.exports = QueueEngine;
