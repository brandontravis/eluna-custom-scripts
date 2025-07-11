-- =============================================
-- TRAVELER'S BEACON UPGRADE SYSTEM - WORLD DATABASE
-- =============================================
-- Import this file into your WORLD database (acore_world)
-- Contains: Items, NPCs, Vendors

-- =============================================
-- BEACON PROGRESSION ITEMS (4 Tiers)
-- =============================================

-- Item 800,000: Traveler's Mark (Basic teleport reagent)
DELETE FROM `item_template` WHERE `entry` = 800000;
INSERT INTO `item_template` (`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`, `BuyCount`, `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`, `maxcount`, `stackable`, `bonding`, `description`, `spellid_1`, `spelltrigger_1`, `material`) VALUES
(800000, 0, 8, 'Traveler\'s Mark', 48010, 1, 0, 1, 2500, 625, 0, -1, -1, 10, 1, 0, 200, 0, 'A mystical rune imbued with teleportation magic. Used to power Traveler\'s Beacons.', 0, 0, -1);

-- Item 800,001: Starter Traveler's Beacon (Tier 1 - White, 1 location)
DELETE FROM `item_template` WHERE `entry` = 800001;
INSERT INTO `item_template` (`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`, `BuyCount`, `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`, `maxcount`, `stackable`, `bonding`, `description`, `spellid_1`, `spelltrigger_1`, `material`) VALUES
(800001, 15, 0, 'Starter Traveler\'s Beacon', 50456, 1, 0, 1, 50000, 12500, 0, -1, -1, 10, 1, 1, 1, 1, 'A mystical beacon that can store one location and teleport you back to it. Requires Traveler\'s Marks to use.', 1, 0, 4);

-- Item 800,002: Traveler's Beacon (Tier 2 - Green, 2 locations)
DELETE FROM `item_template` WHERE `entry` = 800002;
INSERT INTO `item_template` (`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`, `BuyCount`, `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`, `maxcount`, `stackable`, `bonding`, `description`, `spellid_1`, `spelltrigger_1`, `material`) VALUES
(800002, 15, 0, 'Traveler\'s Beacon', 50456, 2, 0, 1, 100000, 25000, 0, -1, -1, 20, 10, 1, 1, 1, 'An enhanced mystical beacon that can store two locations and teleport you back to them. Requires Traveler\'s Marks to use.', 0, 0, 4);

-- Item 800,003: Advanced Traveler's Beacon (Tier 3 - Blue, 5 locations)
DELETE FROM `item_template` WHERE `entry` = 800003;
INSERT INTO `item_template` (`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`, `BuyCount`, `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`, `maxcount`, `stackable`, `bonding`, `description`, `spellid_1`, `spelltrigger_1`, `material`) VALUES
(800003, 15, 0, 'Advanced Traveler\'s Beacon', 50456, 3, 0, 1, 250000, 62500, 0, -1, -1, 40, 25, 1, 1, 1, 'A powerful mystical beacon that can store five locations and teleport you back to them. Supports content pack expansions.', 0, 0, 4);

-- Item 800,004: Master's Portal Beacon (Tier 4 - Purple, 5 locations + portals)
DELETE FROM `item_template` WHERE `entry` = 800004;
INSERT INTO `item_template` (`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`, `BuyCount`, `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`, `maxcount`, `stackable`, `bonding`, `description`, `spellid_1`, `spelltrigger_1`, `material`) VALUES
(800004, 15, 0, 'Master\'s Portal Beacon', 50456, 4, 0, 1, 500000, 125000, 0, -1, -1, 60, 40, 1, 1, 1, 'A masterwork beacon with portal-casting abilities. Can store five locations and create portals for others to use.', 0, 0, 4);

-- =============================================
-- REAGENT ITEMS
-- =============================================

-- Item 800,010: Arcane Crystal (Portal casting reagent - 1g each)
DELETE FROM `item_template` WHERE `entry` = 800010;
INSERT INTO `item_template` (`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`, `BuyCount`, `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`, `maxcount`, `stackable`, `bonding`, `description`, `spellid_1`, `spelltrigger_1`, `material`) VALUES
(800010, 0, 8, 'Arcane Crystal', 134332, 2, 0, 1, 10000, 2500, 0, -1, -1, 30, 40, 0, 50, 0, 'A crystal charged with pure arcane energy. Used to power portal magic in Master\'s Portal Beacons.', 0, 0, -1);

-- Item 800,020: Dungeon Stone (Dungeon teleport reagent - 1g each)
DELETE FROM `item_template` WHERE `entry` = 800020;
INSERT INTO `item_template` (`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`, `BuyCount`, `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`, `maxcount`, `stackable`, `bonding`, `description`, `spellid_1`, `spelltrigger_1`, `material`) VALUES
(800020, 0, 8, 'Dungeon Stone', 134298, 1, 0, 1, 10000, 2500, 0, -1, -1, 15, 15, 0, 100, 0, 'A carved stone attuned to dungeon entrances. Used for dungeon teleportation with Traveler\'s Beacons.', 0, 0, -1);

-- Item 800,030: Raid Seal (Raid teleport reagent - 2g each)
DELETE FROM `item_template` WHERE `entry` = 800030;
INSERT INTO `item_template` (`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`, `BuyCount`, `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`, `maxcount`, `stackable`, `bonding`, `description`, `spellid_1`, `spelltrigger_1`, `material`) VALUES
(800030, 0, 8, 'Raid Seal', 134415, 2, 0, 1, 20000, 5000, 0, -1, -1, 25, 25, 0, 50, 0, 'An ancient seal imbued with powerful magic. Used for raid teleportation with advanced Traveler\'s Beacons.', 0, 0, -1);

-- =============================================
-- NPC VENDORS AND UPGRADE SPECIALISTS
-- =============================================

-- Update Engineer Gizmo Wayfinder (existing vendor) to sell new beacon items
DELETE FROM `npc_vendor` WHERE `entry` = 800000;
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`) VALUES
-- Starter beacon (Tier 1)
(800000, 0, 800001, 0, 0, 0, 0),
-- Basic reagents  
(800000, 1, 800000, 0, 0, 0, 0),  -- Traveler's Mark
(800000, 2, 800020, 0, 0, 0, 0),  -- Dungeon Stone
(800000, 3, 800030, 0, 0, 0, 0),  -- Raid Seal
-- Advanced reagents (higher level requirement)
(800000, 4, 800010, 0, 0, 0, 0);  -- Arcane Crystal

-- Create Beacon Upgrade NPC (Arcane Engineer Voltis)
DELETE FROM `creature_template` WHERE `entry` = 800001;
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `scale`, `rank`, `unit_class`, `unit_flags`, `type`, `type_flags`, `RegenHealth`, `flags_extra`, `AIName`) VALUES
(800001, 'Arcane Engineer Voltis', 'Beacon Upgrade Specialist', 'Trainer', 80, 80, 35, 1, 1, 1.14286, 1, 0, 1, 0, 7, 0, 1, 0, '');

-- Display model for upgrade NPC (Gnome Male Mage)
DELETE FROM `creature_template_model` WHERE `CreatureID` = 800001;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(800001, 0, 26748, 1, 1);

-- =============================================
-- INSTALLATION COMPLETE
-- =============================================
-- World database setup complete!
-- Next: Import TravelersBeacon_Characters.sql into your CHARACTER database
-- Then: Load TravelersBeacon_Upgraded.lua on your server 