const db = require('../config/db');
const bcrypt = require('bcryptjs');

class User {
  // Create new user
  static async create(userData) {
    const { name, email, mobile, password, role, device_id } = userData;
    const password_hash = await bcrypt.hash(password, 10);
    
    const [result] = await db.execute(
      `INSERT INTO users (name, email, mobile, password_hash, role, device_id) 
       VALUES (?, ?, ?, ?, ?, ?)`,
      [name, email, mobile, password_hash, role || 'customer', device_id || null]
    );
    
    return result.insertId;
  }

  // Find by email
  static async findByEmail(email) {
    const [rows] = await db.execute(
      'SELECT * FROM users WHERE email = ?',
      [email]
    );
    return rows[0];
  }

  // Find by mobile
  static async findByMobile(mobile) {
    const [rows] = await db.execute(
      'SELECT * FROM users WHERE mobile = ?',
      [mobile]
    );
    return rows[0];
  }

  // Find by ID
  static async findById(id) {
    const [rows] = await db.execute(
      'SELECT id, name, email, mobile, role, is_verified, is_blocked, created_at FROM users WHERE id = ?',
      [id]
    );
    return rows[0];
  }

  // Verify password
  static async verifyPassword(plainPassword, hashedPassword) {
    return bcrypt.compare(plainPassword, hashedPassword);
  }

  // Update verification status
  static async setVerified(userId) {
    await db.execute(
      'UPDATE users SET is_verified = 1 WHERE id = ?',
      [userId]
    );
  }

  // Update password
  static async updatePassword(userId, newPassword) {
    const password_hash = await bcrypt.hash(newPassword, 10);
    await db.execute(
      'UPDATE users SET password_hash = ? WHERE id = ?',
      [password_hash, userId]
    );
  }

  // Block/Unblock user
  static async setBlocked(userId, blocked) {
    await db.execute(
      'UPDATE users SET is_blocked = ? WHERE id = ?',
      [blocked ? 1 : 0, userId]
    );
  }

  // Check if email exists
  static async emailExists(email) {
    const [rows] = await db.execute(
      'SELECT id FROM users WHERE email = ?',
      [email]
    );
    return rows.length > 0;
  }

  // Check if mobile exists
  static async mobileExists(mobile) {
    const [rows] = await db.execute(
      'SELECT id FROM users WHERE mobile = ?',
      [mobile]
    );
    return rows.length > 0;
  }
}

module.exports = User;
