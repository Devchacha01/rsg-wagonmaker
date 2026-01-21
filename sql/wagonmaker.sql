-- Add serial column to customer-owned wagons table (wagonmaker_wagons)
-- Required for business stock -> customer transfers with AB1234 serials.
ALTER TABLE `wagonmaker_wagons`
  ADD COLUMN `serial` varchar(6) DEFAULT NULL AFTER `plate`;

-- Ensure serials are unique (optional but strongly recommended)
CREATE UNIQUE INDEX `uq_wagonmaker_wagons_serial` ON `wagonmaker_wagons` (`serial`);

-- Optional backfill: if you previously used `plate` as an identifier, copy it into serial
UPDATE `wagonmaker_wagons`
SET `serial` = `plate`
WHERE `serial` IS NULL AND `plate` IS NOT NULL AND `plate` <> '';
