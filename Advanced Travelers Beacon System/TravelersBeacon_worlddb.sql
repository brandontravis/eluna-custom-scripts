-- =============================================
-- TRAVELER'S BEACON SYSTEM v1 - WORLD DATABASE
-- =============================================
-- Foundation build using working simple system
-- Ports existing items and NPCs for tier system expansion

-- =============================================
-- REAGENT ITEMS
-- =============================================

-- Item 800,000: Traveler's Mark (Primary reagent)
DELETE FROM `item_template` WHERE `entry` = 800000;
INSERT INTO `item_template` (`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`, `BuyCount`, `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`, `maxcount`, `stackable`, `bonding`, `description`, `spellid_1`, `spelltrigger_1`, `material`) VALUES
(800000, 0, 8, 'Traveler\'s Mark', 48010, 1, 0, 1, 2500, 625, 0, -1, -1, 10, 1, 0, 200, 0, 'A mystical rune imbued with teleportation magic. Used to power Traveler\'s Beacons.', 0, 0, -1);

-- Item 800,010: Portal Mark (Future portal reagent)
DELETE FROM `item_template` WHERE `entry` = 800010;
INSERT INTO `item_template` (`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`, `BuyCount`, `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`, `maxcount`, `stackable`, `bonding`, `description`, `spellid_1`, `spelltrigger_1`, `material`) VALUES
(800010, 0, 8, 'Portal Mark', 134332, 2, 0, 1, 5000, 1250, 0, -1, -1, 20, 30, 0, 100, 0, 'A crystal charged with portal magic. Used for creating portals with advanced Traveler\'s Beacons.', 0, 0, -1);

-- =============================================
-- BEACON TIER 1 (FOUNDATION)
-- =============================================

-- Item 800,001: Traveler's Beacon (Tier 1)
DELETE FROM `item_template` WHERE `entry` = 800001;
INSERT INTO `item_template` (`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`, `BuyCount`, `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`, `maxcount`, `stackable`, `bonding`, `description`, `spellid_1`, `spelltrigger_1`, `material`) VALUES
(800001, 15, 0, 'Traveler\'s Beacon', 50456, 1, 0, 1, 50000, 12500, 0, -1, -1, 10, 1, 1, 1, 1, 'A mystical beacon that can store one location and teleport you back to it. Requires Traveler\'s Marks to use. Can be upgraded for more capacity.', 1, 0, 4);

-- =============================================
-- FUTURE BEACON TIERS (PLACEHOLDERS)
-- =============================================

-- Item 800,002: Dual Anchor Beacon (Tier 2) - Will be added in next version
-- Item 800,003: Travel Network Beacon (Tier 3) - Will be added in next version
-- Item 800,004: Master's Travel Beacon (Tier 4) - Will be added in next version

-- =============================================
-- NPC VENDOR
-- =============================================

-- Engineer Gizmo Wayfinder - Beacon Specialist
DELETE FROM `creature_template` WHERE `entry` = 800000;
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `scale`, `rank`, `unit_class`, `unit_flags`, `type`, `type_flags`, `RegenHealth`, `flags_extra`, `AIName`) VALUES
(800000, 'Engineer Gizmo Wayfinder', 'Waypoint Technology Specialist', 'Buy', 80, 80, 35, 129, 1, 1.14286, 1, 0, 1, 0, 7, 0, 1, 0, '');

-- NPC Display Model (Gnome Male Engineer)
DELETE FROM `creature_template_model` WHERE `CreatureID` = 800000;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(800000, 0, 26374, 1, 1);

-- NPC Vendor Inventory
DELETE FROM `npc_vendor` WHERE `entry` = 800000;
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`) VALUES
(800000, 0, 800001, 0, 0, 0, 0),  -- Traveler's Beacon (Tier 1)
(800000, 1, 800000, 0, 0, 0, 0),  -- Traveler's Mark
(800000, 2, 800010, 0, 0, 0, 0);  -- Portal Mark (future use)

-- =============================================
-- INSTALLATION NOTES
-- =============================================
-- World database v1 setup complete!
-- 
-- Current Features:
-- ✓ Tier 1 beacon (Traveler's Beacon - 1 location)
-- ✓ Traveler's Mark reagent
-- ✓ Portal Mark reagent (for future portal system)
-- ✓ Engineer Gizmo Wayfinder vendor
--
-- Next Steps:
-- 1. Import TravelersBeacon_Characters_v1.sql
-- 2. Load TravelersBeacon_v1.lua on server
-- 3. Spawn NPC: .npc add 800000
-- 4. Test basic functionality
-- 5. Add higher tier beacons when ready
-- ============================================= 