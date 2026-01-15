CREATE TABLE IF NOT EXISTS `wagon_maker_wagons` (
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
  `damage` text DEFAULT NULL,
  `inventory` longtext DEFAULT NULL,
  `metadata` longtext DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `wagon_maker_zones` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` varchar(20) DEFAULT 'crafting',
  `owner` varchar(50) DEFAULT NULL,
  `x` float DEFAULT 0,
  `y` float DEFAULT 0,
  `z` float DEFAULT 0,
  `radius` float DEFAULT 2.0,
  `allowed_jobs` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `wagon_maker_transfers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `wagon_id` int(11) NOT NULL,
  `from_citizenid` varchar(50) NOT NULL,
  `to_citizenid` varchar(50) NOT NULL,
  `price` int(11) DEFAULT 0,
  `status` varchar(20) DEFAULT 'pending', -- pending, accepted, declined
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- New table for Employee Stats (similar to rsg-saloon)
CREATE TABLE IF NOT EXISTS `wagon_maker_employees` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job_name` varchar(50) NOT NULL,
  `citizenid` varchar(50) NOT NULL,
  `player_name` varchar(100) DEFAULT NULL,
  `items_crafted` int(11) DEFAULT 0,
  `hired_date` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_employee` (`job_name`, `citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
