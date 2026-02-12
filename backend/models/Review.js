const db = require('../config/db');

class Review {
    // Create a review
    static async create(reviewData) {
        const { appointment_id, customer_id, provider_id, rating, comment } = reviewData;

        const [result] = await db.execute(
            `INSERT INTO reviews (appointment_id, customer_id, provider_id, rating, comment)
             VALUES (?, ?, ?, ?, ?)`,
            [appointment_id, customer_id, provider_id, rating, comment || null]
        );

        return result.insertId;
    }

    // Get reviews for a provider
    static async getByProvider(providerId) {
        const [rows] = await db.execute(
            `SELECT r.*, u.name as customer_name
             FROM reviews r
             JOIN users u ON r.customer_id = u.id
             WHERE r.provider_id = ?
             ORDER BY r.created_at DESC`,
            [providerId]
        );
        return rows;
    }

    // Get provider average rating
    static async getProviderRating(providerId) {
        const [rows] = await db.execute(
            `SELECT AVG(rating) as avg_rating, COUNT(*) as total_reviews
             FROM reviews WHERE provider_id = ?`,
            [providerId]
        );
        return {
            avgRating: rows[0].avg_rating ? parseFloat(rows[0].avg_rating).toFixed(1) : '0.0',
            totalReviews: rows[0].total_reviews || 0
        };
    }

    // Check if customer already reviewed an appointment
    static async existsForAppointment(appointmentId) {
        const [rows] = await db.execute(
            'SELECT id FROM reviews WHERE appointment_id = ?',
            [appointmentId]
        );
        return rows.length > 0;
    }

    // Get reviews by customer
    static async getByCustomer(customerId) {
        const [rows] = await db.execute(
            `SELECT r.*, p.shop_name as provider_name
             FROM reviews r
             JOIN providers p ON r.provider_id = p.id
             WHERE r.customer_id = ?
             ORDER BY r.created_at DESC`,
            [customerId]
        );
        return rows;
    }
}

module.exports = Review;
