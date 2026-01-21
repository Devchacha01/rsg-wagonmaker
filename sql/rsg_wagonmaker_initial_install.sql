/*
  rsg-wagonmaker — Initial Install SQL
  Compatible with MySQL / MariaDB (InnoDB, utf8mb4)

  What this creates:
    - wagonmaker_wagons        (player-owned wagons)
    - wagonmaker_stock         (shop/job crafted stock awaiting sale/transfer)
    - wagonmaker_projects      (progressive crafting projects)
    - wagonmaker_transfers     (player-to-player transfers / offers)
    - wagonmaker_logs          (audit/log trail)
    - wagonmaker_zones         (optional; used by admin/management events if enabled)

  Notes / Dependencies:
    - This resource may reference `management_funds` in some configurations. That table is typically provided by a separate
      management/bossmenu resource and is intentionally NOT created here to avoid conflicts.

  Safe to run multiple times: uses CREATE TABLE IF NOT EXISTS.
*/

SET FOREIGN_KEY_CHECKS=0;

-- ============================================================
-- Player-owned wagons
-- ============================================================
CREATE TABLE IF NOT EXISTS `wagonmaker_wagons` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(64) NOT NULL,

  `model` VARCHAR(64) NOT NULL,
  `name` VARCHAR(100) NOT NULL,

  -- Legacy identifier some ecosystems use; kept for compatibility.
  `plate` VARCHAR(32) DEFAULT NULL,

  -- Unique shop/yard serial used by this script (e.g., AB1234)
  `serial` VARCHAR(64) DEFAULT NULL,

  `livery` INT DEFAULT 0,
  `tint` INT DEFAULT 0,

  -- Whether the wagon is currently spawned (anti-ghost cleanup)
  `spawned` TINYINT(1) NOT NULL DEFAULT 0,

  -- Whether the wagon is stored (yard/storage state)
  `stored` TINYINT(1) NOT NULL DEFAULT 1,

  -- Optional: where it is parked/stored (yard identifier, stable name, etc.)
  `parking_location` VARCHAR(64) DEFAULT NULL,

  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  PRIMARY KEY (`id`),
  KEY `idx_wagonmaker_wagons_citizenid` (`citizenid`),
  KEY `idx_wagonmaker_wagons_model` (`model`),
  UNIQUE KEY `uq_wagonmaker_wagons_serial` (`serial`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- Business stock (crafted wagons held by a wagonmaker job)
-- ============================================================
CREATE TABLE IF NOT EXISTS `wagonmaker_stock` (
  `id` INT NOT NULL AUTO_INCREMENT,

  `job_name` VARCHAR(50) NOT NULL,

  -- Unique stock serial generated server-side
  `serial` VARCHAR(64) NOT NULL,

  `model` VARCHAR(64) NOT NULL,
  `name` VARCHAR(100) NOT NULL,

  `livery` INT DEFAULT 0,
  `tint` INT DEFAULT 0,

  `status` ENUM('in_stock','sold','reserved') NOT NULL DEFAULT 'in_stock',

  -- Sale price (if used)
  `price` INT NOT NULL DEFAULT 0,

  -- Player identifier that created the stock entry
  `created_by` VARCHAR(64) NOT NULL,

  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_wagonmaker_stock_serial` (`serial`),
  KEY `idx_wagonmaker_stock_job_status` (`job_name`, `status`),
  KEY `idx_wagonmaker_stock_model` (`model`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- Progressive crafting projects
-- ============================================================
CREATE TABLE IF NOT EXISTS `wagonmaker_projects` (
  `id` INT NOT NULL AUTO_INCREMENT,

  `job_name` VARCHAR(50) NOT NULL,
  `created_by` VARCHAR(64) NOT NULL,

  `model` VARCHAR(64) NOT NULL,
  `name` VARCHAR(100) NOT NULL,

  -- JSON text (customization/options)
  `customization` LONGTEXT NULL,

  -- JSON text: { itemName: count, ... }
  `materials_required` LONGTEXT NOT NULL,
  `materials_delivered` LONGTEXT NOT NULL,

  `status` ENUM('active','completed','cancelled') NOT NULL DEFAULT 'active',

  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (`id`),
  KEY `idx_wagonmaker_projects_job_status` (`job_name`, `status`),
  KEY `idx_wagonmaker_projects_model` (`model`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- Wagon transfer offers (player-to-player)
-- ============================================================
CREATE TABLE IF NOT EXISTS `wagonmaker_transfers` (
  `id` INT NOT NULL AUTO_INCREMENT,

  `wagon_id` INT NOT NULL,
  `from_citizenid` VARCHAR(64) NOT NULL,
  `to_citizenid` VARCHAR(64) NOT NULL,

  `price` INT NOT NULL DEFAULT 0,
  `message` VARCHAR(255) DEFAULT NULL,

  `status` ENUM('pending','accepted','declined','cancelled','expired') NOT NULL DEFAULT 'pending',

  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `responded_at` TIMESTAMP NULL DEFAULT NULL,

  PRIMARY KEY (`id`),

  KEY `idx_wagonmaker_transfers_to_status` (`to_citizenid`, `status`),
  KEY `idx_wagonmaker_transfers_from_status` (`from_citizenid`, `status`),
  KEY `idx_wagonmaker_transfers_wagon_id` (`wagon_id`),

  CONSTRAINT `fk_wagonmaker_transfers_wagon`
    FOREIGN KEY (`wagon_id`) REFERENCES `wagonmaker_wagons` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- Logs / audit trail
-- ============================================================
CREATE TABLE IF NOT EXISTS `wagonmaker_logs` (
  `id` INT NOT NULL AUTO_INCREMENT,

  `citizenid` VARCHAR(64) NOT NULL,
  `action` VARCHAR(64) NOT NULL,

  `wagon_model` VARCHAR(64) DEFAULT NULL,
  `wagon_id` INT DEFAULT NULL,

  `details` LONGTEXT NULL,

  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  PRIMARY KEY (`id`),
  KEY `idx_wagonmaker_logs_citizenid` (`citizenid`),
  KEY `idx_wagonmaker_logs_action` (`action`),
  KEY `idx_wagonmaker_logs_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- Optional: Zones table (if your config/admin flow uses it)
-- ============================================================
CREATE TABLE IF NOT EXISTS `wagonmaker_zones` (
  `id` INT NOT NULL AUTO_INCREMENT,

  `job_name` VARCHAR(50) NOT NULL,
  `zone_name` VARCHAR(64) NOT NULL,

  -- JSON text payload for coords/shape/heading/etc.
  `zone_data` LONGTEXT NOT NULL,

  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  PRIMARY KEY (`id`),
  KEY `idx_wagonmaker_zones_job` (`job_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS=1;
