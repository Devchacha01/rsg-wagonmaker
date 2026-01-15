CREATE TABLE IF NOT EXISTS `wagonmaker_wagons` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) DEFAULT NULL,
  `model` varchar(50) DEFAULT NULL,
  `name` varchar(50) DEFAULT NULL,
  `plate` varchar(50) DEFAULT NULL,
  `spawned` int(1) DEFAULT 0,
  `props` text DEFAULT NULL,
  `livery` int(11) DEFAULT -1,
  `tint` int(11) DEFAULT 0,
  `lantern` varchar(50) DEFAULT NULL,
  `extra` int(11) DEFAULT 0,
  `parking_location` int(11) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  INDEX `idx_citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `wagonmaker_zones` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` varchar(20) DEFAULT 'crafting',
  `created_by` varchar(50) DEFAULT NULL,
  `x` float DEFAULT 0,
  `y` float DEFAULT 0,
  `z` float DEFAULT 0,
  `radius` float DEFAULT 2.0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `wagonmaker_transfers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `wagon_id` int(11) NOT NULL,
  `from_citizenid` varchar(50) NOT NULL,
  `to_citizenid` varchar(50) NOT NULL,
  `price` int(11) DEFAULT 0,
  `status` varchar(20) DEFAULT 'pending', -- pending, accepted, declined
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `wagonmaker_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `action` varchar(50) NOT NULL,
  `wagon_model` varchar(50) NULL,
  `wagon_id` int(11) NULL,
  `details` text NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Management Funds (Required for Boss Menu)
CREATE TABLE IF NOT EXISTS `management_funds` (
  `job_name` varchar(50) NOT NULL,
  `amount` int(11) DEFAULT 0,
  `type` varchar(50) DEFAULT 'boss',
  PRIMARY KEY (`job_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
