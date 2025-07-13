-- =============================================
-- TRAVELER'S BEACON SYSTEM v1 - CHARACTER DATABASE
-- =============================================
-- Foundation build using working simple system
-- Database structure ready for tier and functionality expansions

-- =============================================
-- BEACON LOCATIONS TABLE
-- =============================================

-- Main table for storing player beacon locations
DROP TABLE IF EXISTS `player_beacon_locations`;
CREATE TABLE `player_beacon_locations` (
  `guid` int(10) unsigned NOT NULL COMMENT 'Player GUID',
  `beacon_item_id` int(10) unsigned NOT NULL COMMENT 'Beacon item ID',
  `location_slot` tinyint(3) unsigned NOT NULL COMMENT 'Location slot (0-based)',
  `location_name` varchar(100) NOT NULL COMMENT 'Player-defined location name',
  `map_id` int(10) unsigned NOT NULL COMMENT 'Map ID',
  `position_x` float NOT NULL COMMENT 'X coordinate',
  `position_y` float NOT NULL COMMENT 'Y coordinate',
  `position_z` float NOT NULL COMMENT 'Z coordinate',
  `orientation` float NOT NULL COMMENT 'Orientation',
  `location_type` enum('manual', 'dungeon', 'raid', 'capital', 'event') DEFAULT 'manual' COMMENT 'Location type for future functionality',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Creation timestamp',
  PRIMARY KEY (`guid`,`beacon_item_id`,`location_slot`),
  KEY `idx_location_type` (`location_type`),
  KEY `idx_player_beacon` (`guid`, `beacon_item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Stores player beacon teleport locations';

-- =============================================
-- PLAYER PROGRESSION TABLE (FUTURE)
-- =============================================

-- Table for tracking beacon tier and functionality upgrades
-- Currently unused in v1 but ready for expansion
DROP TABLE IF EXISTS `player_beacon_progress`;
CREATE TABLE `player_beacon_progress` (
  `guid` int(10) unsigned NOT NULL PRIMARY KEY COMMENT 'Player GUID',
  `beacon_tier` tinyint(3) unsigned NOT NULL DEFAULT 1 COMMENT 'Current beacon tier (1-4)',
  `has_portal_upgrade` boolean NOT NULL DEFAULT FALSE COMMENT 'Portal casting upgrade',
  `has_dungeon_upgrade` boolean NOT NULL DEFAULT FALSE COMMENT 'Dungeon access upgrade',
  `has_raid_upgrade` boolean NOT NULL DEFAULT FALSE COMMENT 'Raid access upgrade',
  `has_capital_upgrade` boolean NOT NULL DEFAULT FALSE COMMENT 'Capital networks upgrade',
  `has_events_upgrade` boolean NOT NULL DEFAULT FALSE COMMENT 'World events upgrade',
  `last_updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last update timestamp',
  KEY `idx_beacon_tier` (`beacon_tier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Tracks player beacon progression and functionality upgrades';


-- =============================================
-- INSTANCE DISCOVERY TABLE (FUTURE)
-- =============================================

-- Table for tracking which dungeons/raids players have discovered
-- Will be used for dungeon/raid access functionality upgrades
DROP TABLE IF EXISTS `player_instance_discovery`;
CREATE TABLE `player_instance_discovery` (
  `guid` int(10) unsigned NOT NULL COMMENT 'Player GUID',
  `map_id` int(10) unsigned NOT NULL COMMENT 'Instance map ID',
  `instance_name` varchar(100) NOT NULL COMMENT 'Instance name',
  `instance_type` enum('dungeon', 'raid') NOT NULL COMMENT 'Instance type',
  `recommended_level` tinyint(3) unsigned DEFAULT NULL COMMENT 'Recommended level',
  `expansion` enum('classic', 'tbc', 'wotlk') DEFAULT 'classic' COMMENT 'Content expansion',
  `first_entered` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'First discovery timestamp',
  PRIMARY KEY (`guid`, `map_id`),
  KEY `idx_instance_type` (`instance_type`),
  KEY `idx_expansion` (`expansion`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Tracks discovered instances for beacon access';

-- =============================================
-- INSTALLATION NOTES
-- =============================================
-- Character database v1 setup complete!
-- 
-- Current Usage:
-- ✓ player_beacon_locations - Active for Tier 1 beacon storage
-- ✓ player_beacon_progress - Ready for tier/functionality expansion
-- ✓ player_instance_discovery - Ready for dungeon/raid access features
--
-- Database Design Notes:
-- - All tables use proper indexes for performance
-- - UTF8MB4 charset for full Unicode support
-- - Enum values prepared for future content types
-- - Timestamp tracking for debugging and analytics
-- - Composite primary keys for efficient storage
--
-- Next Steps:
-- 1. Test basic functionality with Tier 1 beacon
-- 2. Add tier 2-4 beacon items when ready
-- 3. Implement functionality upgrades using progression table
-- 4. Add instance discovery tracking for dungeon/raid access
-- ============================================= 