-- =============================================
-- PRODUCTION QUEUE ENGINE — DATABASE MIGRATION
-- Run this on production database (phpMyAdmin)
-- =============================================

-- Step 1: Modify appointments status ENUM to support queue statuses
ALTER TABLE appointments 
MODIFY COLUMN status ENUM('pending', 'running', 'completed', 'skipped', 'cancelled') DEFAULT 'pending';

-- Step 2: Rename queue_number → queue_position (if exists)
-- First check if queue_number exists, rename it
ALTER TABLE appointments CHANGE COLUMN queue_number queue_position INT NULL;

-- Step 3: Add priority_flag
ALTER TABLE appointments ADD COLUMN priority_flag BOOLEAN DEFAULT FALSE;

-- Step 4: Rename served_at → started_at (if exists)
ALTER TABLE appointments CHANGE COLUMN served_at started_at DATETIME NULL;

-- Step 5: Add proper indexes for queue performance
ALTER TABLE appointments ADD INDEX idx_queue_lookup (provider_id, booking_date, status, queue_position);

-- Step 6: Convert old 'confirmed' status to 'running' 
UPDATE appointments SET status = 'running' WHERE status = 'confirmed';

-- =============================================
-- QUEUE STATS TABLE
-- Tracks current state per provider per day
-- =============================================
CREATE TABLE IF NOT EXISTS queue_stats (
    id INT AUTO_INCREMENT PRIMARY KEY,
    provider_id INT NOT NULL,
    queue_date DATE NOT NULL,
    current_running_token_id INT NULL,
    average_service_time INT DEFAULT 900 COMMENT 'Avg service time in seconds',
    total_served INT DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (provider_id) REFERENCES providers(id) ON DELETE CASCADE,
    UNIQUE KEY uk_provider_date (provider_id, queue_date),
    INDEX idx_provider (provider_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- PUSH SUBSCRIPTIONS TABLE
-- For open-source push notifications (ntfy.sh)
-- =============================================
CREATE TABLE IF NOT EXISTS push_subscriptions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    subscription_type ENUM('ntfy', 'webpush') DEFAULT 'ntfy',
    topic_id VARCHAR(255) NOT NULL COMMENT 'ntfy topic or webpush endpoint',
    subscription_json TEXT NULL COMMENT 'For webpush: full subscription object',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user (user_id),
    INDEX idx_active (user_id, is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
