-- =============================================
-- TRAVELER'S BEACON UPGRADE SYSTEM - CHARACTER DATABASE
-- =============================================
-- Import this file into your CHARACTER database (acore_characters)
-- Contains: Player progress tables and beacon location storage

-- =============================================
-- PLAYER PROGRESS TRACKING TABLE
-- =============================================

-- Create table to track each player's beacon level and content pack purchases
DROP TABLE IF EXISTS `player_beacon_progress`;
CREATE TABLE `player_beacon_progress` (
  `guid` int(10) unsigned NOT NULL,
  `beacon_level` tinyint(3) unsigned NOT NULL DEFAULT 1,
  `content_packs` int(10) unsigned NOT NULL DEFAULT 0,
  `last_updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`),
  KEY `idx_beacon_level` (`beacon_level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Tracks player beacon upgrade progress and content pack purchases';

-- =============================================
-- BEACON LOCATIONS TABLE
-- =============================================

-- Drop existing table if it exists and recreate with all needed columns
DROP TABLE IF EXISTS `player_beacon_locations`;
CREATE TABLE `player_beacon_locations` (
  `guid` int(10) unsigned NOT NULL,
  `beacon_item_id` int(10) unsigned NOT NULL,
  `location_slot` tinyint(3) unsigned NOT NULL,
  `location_name` varchar(100) NOT NULL,
  `map_id` int(10) unsigned NOT NULL,
  `position_x` float NOT NULL,
  `position_y` float NOT NULL,
  `position_z` float NOT NULL,
  `orientation` float NOT NULL DEFAULT 0,
  `saved_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `location_type` enum('manual', 'dungeon', 'raid') DEFAULT 'manual',
  `auto_discovered` boolean DEFAULT FALSE,
  `content_pack_id` tinyint DEFAULT NULL,
  PRIMARY KEY (`guid`, `beacon_item_id`, `location_slot`),
  KEY `idx_location_type` (`location_type`),
  KEY `idx_content_pack` (`content_pack_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Stores player beacon teleport locations';

-- =============================================
-- TABLES COMPLETE
-- =============================================

-- All tables created with proper indexes included
-- No additional ALTER statements needed

-- =============================================
-- INITIALIZATION
-- =============================================

-- Tables are now ready for the beacon upgrade system!
-- Players will automatically get initialized when they first use a beacon.

-- =============================================
-- INSTALLATION COMPLETE
-- =============================================
-- Character database setup complete!
-- Installation Summary:
-- 1. ✅ World database: Import TravelersBeacon_World.sql 
-- 2. ✅ Character database: Import TravelersBeacon_Characters.sql (this file)
-- 3. 🔄 Server: Load TravelersBeacon_Upgraded.lua on server restart
--
-- System is ready for testing! 