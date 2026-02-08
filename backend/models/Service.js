const db = require('../config/db');

class Service {
  // Create service
  static async create(serviceData) {
    const { provider_id, service_name, category, rate, duration_minutes, description } = serviceData;
    
    const [result] = await db.execute(
      `INSERT INTO services (provider_id, service_name, category, rate, duration_minutes, description) 
       VALUES (?, ?, ?, ?, ?, ?)`,
      [provider_id, service_name, category, rate, duration_minutes || null, description || null]
    );
    
    return result.insertId;
  }

  // Get services by provider
  static async getByProvider(providerId, activeOnly = true) {
    let query = 'SELECT * FROM services WHERE provider_id = ?';
    if (activeOnly) query += ' AND is_active = 1';
    
    const [rows] = await db.execute(query, [providerId]);
    return rows;
  }

  // Get service by ID
  static async findById(id) {
    const [rows] = await db.execute(
      'SELECT * FROM services WHERE id = ?',
      [id]
    );
    return rows[0];
  }

  // Update service
  static async update(id, updateData) {
    const { service_name, category, rate, duration_minutes, description } = updateData;
    
    await db.execute(
      `UPDATE services 
       SET service_name = ?, category = ?, rate = ?, duration_minutes = ?, description = ?
       WHERE id = ?`,
      [service_name, category, rate, duration_minutes, description, id]
    );
  }

  // Enable/Disable service
  static async setActive(id, active) {
    await db.execute(
      'UPDATE services SET is_active = ? WHERE id = ?',
      [active ? 1 : 0, id]
    );
  }

  // Delete service
  static async delete(id) {
    await db.execute(
      'DELETE FROM services WHERE id = ?',
      [id]
    );
  }
}

module.exports = Service;
