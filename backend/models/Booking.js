const db = require('../config/db');
const { v4: uuidv4 } = require('uuid');

class Booking {
  // Create booking
  static async create(bookingData) {
    const { customer_id, provider_id, service_id, booking_date, slot_time, locked_price } = bookingData;
    const token_number = `TKN-${Date.now().toString(36).toUpperCase()}`;
    
    const [result] = await db.execute(
      `INSERT INTO appointments (customer_id, provider_id, service_id, token_number, booking_date, slot_time, locked_price) 
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [customer_id, provider_id, service_id, token_number, booking_date, slot_time, locked_price]
    );
    
    return { id: result.insertId, token_number };
  }

  // Get booking by ID
  static async findById(id) {
    const [rows] = await db.execute(
      `SELECT a.*, s.service_name, s.rate, u.name as customer_name, 
              p.shop_name as provider_name
       FROM appointments a
       JOIN services s ON a.service_id = s.id
       JOIN users u ON a.customer_id = u.id
       JOIN providers p ON a.provider_id = p.id
       WHERE a.id = ?`,
      [id]
    );
    return rows[0];
  }

  // Get customer bookings
  static async getByCustomer(customerId) {
    const [rows] = await db.execute(
      `SELECT a.*, s.service_name, p.shop_name as provider_name, u.name as provider_contact_name
       FROM appointments a
       JOIN services s ON a.service_id = s.id
       JOIN providers p ON a.provider_id = p.id
       JOIN users u ON p.user_id = u.id
       WHERE a.customer_id = ?
       ORDER BY a.booking_date DESC, a.slot_time DESC`,
      [customerId]
    );
    return rows;
  }

  // Get provider bookings
  static async getByProvider(providerId) {
    const [rows] = await db.execute(
      `SELECT a.*, s.service_name, u.name as customer_name, u.mobile as customer_mobile
       FROM appointments a
       JOIN services s ON a.service_id = s.id
       JOIN users u ON a.customer_id = u.id
       WHERE a.provider_id = ?
       ORDER BY a.booking_date DESC, a.slot_time DESC`,
      [providerId]
    );
    return rows;
  }

  // Update status
  static async updateStatus(id, status) {
    await db.execute(
      'UPDATE appointments SET status = ? WHERE id = ?',
      [status, id]
    );
  }

  // Check for double booking
  static async checkSlotAvailable(providerId, date, time) {
    const [rows] = await db.execute(
      `SELECT id FROM appointments 
       WHERE provider_id = ? AND booking_date = ? AND slot_time = ? 
       AND status NOT IN ('cancelled')`,
      [providerId, date, time]
    );
    return rows.length === 0;
  }

  // Reschedule
  static async reschedule(id, newDate, newTime) {
    await db.execute(
      'UPDATE appointments SET booking_date = ?, slot_time = ? WHERE id = ?',
      [newDate, newTime, id]
    );
  }
}

module.exports = Booking;
