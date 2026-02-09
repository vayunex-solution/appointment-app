const db = require('../config/db');

class Provider {
  // Create provider profile
  static async create(providerData) {
    const { user_id, shop_name, category, location } = providerData;

    const [result] = await db.execute(
      `INSERT INTO providers (user_id, shop_name, category, location) 
       VALUES (?, ?, ?, ?)`,
      [user_id, shop_name, category, location]
    );

    return result.insertId;
  }

  // Find by user ID
  static async findByUserId(userId) {
    const [rows] = await db.execute(
      `SELECT p.*, u.name, u.email, u.mobile, u.is_verified 
       FROM providers p 
       JOIN users u ON p.user_id = u.id 
       WHERE p.user_id = ?`,
      [userId]
    );
    return rows[0];
  }

  // Get all approved providers
  static async getAllApproved(category = null, location = null) {
    let query = `
      SELECT p.*, u.name, u.email, u.mobile 
      FROM providers p 
      JOIN users u ON p.user_id = u.id 
      WHERE p.is_approved = 1 AND u.is_blocked = 0
    `;
    const params = [];

    if (category) {
      query += ' AND p.category = ?';
      params.push(category);
    }
    if (location) {
      query += ' AND p.location LIKE ?';
      params.push(`%${location}%`);
    }

    const [rows] = await db.execute(query, params);
    return rows;
  }

  // Get pending approval providers (for admin)
  static async getPending() {
    const [rows] = await db.execute(
      `SELECT p.*, u.name, u.email, u.mobile, u.created_at 
       FROM providers p 
       JOIN users u ON p.user_id = u.id 
       WHERE p.is_approved = 0`
    );
    return rows;
  }

  // Approve/Reject provider
  static async setApproval(providerId, approved) {
    await db.execute(
      'UPDATE providers SET is_approved = ? WHERE id = ?',
      [approved ? 1 : 0, providerId]
    );
  }

  // Update wallet balance
  static async updateWallet(providerId, amount) {
    await db.execute(
      'UPDATE providers SET wallet_balance = wallet_balance + ? WHERE id = ?',
      [amount, providerId]
    );
  }

  // Get wallet balance
  static async getWalletBalance(providerId) {
    const [rows] = await db.execute(
      'SELECT wallet_balance FROM providers WHERE id = ?',
      [providerId]
    );
    return rows[0]?.wallet_balance || 0;
  }

  // Update provider profile
  static async updateProfile(providerId, data) {
    const { shop_name, category, location, description } = data;
    await db.execute(
      `UPDATE providers 
       SET shop_name = ?, category = ?, location = ?, description = ?, updated_at = NOW() 
       WHERE id = ?`,
      [shop_name, category, location, description || null, providerId]
    );
  }

  // Set availability
  static async setAvailability(providerId, availabilityData) {
    const { day_of_week, start_time, end_time, slot_duration, is_active } = availabilityData;

    // Check if exists for this day
    const [existing] = await db.execute(
      'SELECT id FROM provider_availability WHERE provider_id = ? AND day_of_week = ?',
      [providerId, day_of_week]
    );

    if (existing.length > 0) {
      await db.execute(
        `UPDATE provider_availability 
         SET start_time = ?, end_time = ?, slot_duration = ?, is_active = ?
         WHERE provider_id = ? AND day_of_week = ?`,
        [start_time, end_time, slot_duration, is_active ? 1 : 0, providerId, day_of_week]
      );
      return existing[0].id;
    } else {
      const [result] = await db.execute(
        `INSERT INTO provider_availability (provider_id, day_of_week, start_time, end_time, slot_duration, is_active)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [providerId, day_of_week, start_time, end_time, slot_duration, is_active ? 1 : 0]
      );
      return result.insertId;
    }
  }

  // Get availability for provider
  static async getAvailability(providerId) {
    const [rows] = await db.execute(
      `SELECT * FROM provider_availability WHERE provider_id = ? ORDER BY day_of_week`,
      [providerId]
    );
    return rows;
  }

  // Get dashboard stats
  static async getDashboardStats(providerId) {
    const [todayBookings] = await db.execute(
      `SELECT COUNT(*) as count FROM appointments 
       WHERE provider_id = ? AND DATE(booking_date) = CURDATE()`,
      [providerId]
    );

    const [totalBookings] = await db.execute(
      `SELECT COUNT(*) as count FROM appointments WHERE provider_id = ?`,
      [providerId]
    );

    const [pendingBookings] = await db.execute(
      `SELECT COUNT(*) as count FROM appointments 
       WHERE provider_id = ? AND status = 'pending'`,
      [providerId]
    );

    const [totalServices] = await db.execute(
      `SELECT COUNT(*) as count FROM services WHERE provider_id = ? AND is_active = 1`,
      [providerId]
    );

    return {
      todayBookings: todayBookings[0].count,
      totalBookings: totalBookings[0].count,
      pendingBookings: pendingBookings[0].count,
      totalServices: totalServices[0].count
    };
  }

  // Find by ID
  static async findById(providerId) {
    const [rows] = await db.execute(
      `SELECT p.*, u.name, u.email, u.mobile, u.is_verified 
       FROM providers p 
       JOIN users u ON p.user_id = u.id 
       WHERE p.id = ?`,
      [providerId]
    );
    return rows[0];
  }
}

module.exports = Provider;
