-- ====================
-- DATABASE STORAGE
-- ====================

-- Create custom table for storing player beacon locations
DROP TABLE IF EXISTS `player_beacon_progress`;
CREATE TABLE IF NOT EXISTS `player_beacon_locations` (
  `guid` int(10) unsigned NOT NULL COMMENT 'Player GUID',
  `beacon_item_id` int(10) unsigned NOT NULL COMMENT 'Beacon item ID',
  `location_slot` tinyint(3) unsigned NOT NULL COMMENT 'Location slot (0-based)',
  `location_name` varchar(100) NOT NULL COMMENT 'Player-defined location name',
  `map_id` int(10) unsigned NOT NULL COMMENT 'Map ID',
  `position_x` float NOT NULL COMMENT 'X coordinate',
  `position_y` float NOT NULL COMMENT 'Y coordinate',
  `position_z` float NOT NULL COMMENT 'Z coordinate',
  `orientation` float NOT NULL COMMENT 'Orientation',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Creation timestamp',
  PRIMARY KEY (`guid`,`beacon_item_id`,`location_slot`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Stores player beacon locations';