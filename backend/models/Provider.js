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
}

module.exports = Provider;
