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
-- BEACON TIER 2
-- =============================================

-- Item 800,002: Dual Anchor Beacon (Tier 2)
DELETE FROM `item_template` WHERE `entry` = 800002;
INSERT INTO `item_template` (`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`, `BuyCount`, `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`, `maxcount`, `stackable`, `bonding`, `description`, `spellid_1`, `spelltrigger_1`, `material`) VALUES
(800002, 15, 0, 'Dual Anchor Beacon', 50456, 2, 0, 1, 100000, 25000, 0, -1, -1, 20, 20, 1, 1, 1, 'An enhanced beacon that can store two locations and teleport you back to them. Requires Traveler\'s Marks to use. Level 20 required.', 1, 0, 4);

-- =============================================
-- BEACON TIER 3
-- =============================================

-- Item 800,003: Travel Network Beacon (Tier 3)
DELETE FROM `item_template` WHERE `entry` = 800003;
INSERT INTO `item_template` (`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`, `BuyCount`, `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`, `maxcount`, `stackable`, `bonding`, `description`, `spellid_1`, `spelltrigger_1`, `material`) VALUES
(800003, 15, 0, 'Travel Network Beacon', 50456, 2, 0, 1, 250000, 62500, 0, -1, -1, 40, 40, 1, 1, 1, 'A powerful beacon that can store five locations and teleport you back to them. Requires Traveler\'s Marks to use. Level 40 required.', 1, 0, 4);

-- =============================================
-- BEACON TIER 4
-- =============================================

-- Item 800,004: Master's Travel Beacon (Tier 4)
DELETE FROM `item_template` WHERE `entry` = 800004;
INSERT INTO `item_template` (`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`, `BuyCount`, `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`, `maxcount`, `stackable`, `bonding`, `description`, `spellid_1`, `spelltrigger_1`, `material`) VALUES
(800004, 15, 0, 'Master\'s Travel Beacon', 50456, 3, 0, 1, 500000, 125000, 0, -1, -1, 60, 60, 1, 1, 1, 'A masterwork beacon that can store ten locations and teleport you back to them. Requires Traveler\'s Marks to use. Level 60 required.', 1, 0, 4);

-- =============================================
-- NPC VENDOR
-- =============================================

-- Engineer Gizmo Wayfinder - Beacon Specialist
DELETE FROM `creature_template` WHERE `entry` = 800000;
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `scale`, `rank`, `unit_class`, `unit_flags`, `type`, `type_flags`, `RegenHealth`, `flags_extra`, `AIName`) VALUES
(800000, 'Engineer Gizmo Wayfinder', 'Beacon Technology Specialist', 'Buy', 0, 80, 80, 35, 128, 1, 1.14286, 1, 0, 1, 0, 7, 0, 1, 0, '');

-- NPC Display Model (Gnome Male Engineer)
DELETE FROM `creature_template_model` WHERE `CreatureID` = 800000;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(800000, 0, 26374, 1, 1);

-- NPC Vendor Inventory (Only Tier 1 beacon and reagents - higher tiers via upgrades)
DELETE FROM `npc_vendor` WHERE `entry` = 800000;
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`) VALUES
(800000, 0, 800001, 0, 0, 0, 0),  -- Traveler's Beacon (Tier 1) - starter beacon
(800000, 1, 800000, 0, 0, 0, 0),  -- Traveler's Mark - required reagent
(800000, 2, 800010, 0, 0, 0, 0);  -- Portal Mark (future use)

-- =============================================
-- UPGRADE NPC
-- =============================================

-- Beacon Artificer - Upgrade Specialist (Using display model from NPC 33634)
DELETE FROM `creature_template` WHERE `entry` = 800001;
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `scale`, `rank`, `unit_class`, `unit_flags`, `type`, `type_flags`, `RegenHealth`, `flags_extra`, `AIName`) VALUES
(800001, 'Artificer Elara Grayheart', 'Beacon Upgrade Specialist', 'Buy', 0, 80, 80, 35, 1, 1, 1.14286, 1, 0, 1, 0, 7, 0, 1, 2, '');

-- Clear any existing gossip menus for this NPC to let Lua handle it
DELETE FROM `gossip_menu` WHERE `MenuID` IN (SELECT `gossip_menu_id` FROM `creature_template` WHERE `entry` = 800001);
DELETE FROM `gossip_menu_option` WHERE `MenuID` IN (SELECT `gossip_menu_id` FROM `creature_template` WHERE `entry` = 800001);

-- NPC Display Model (Using display ID 28791 from NPC 33634)
DELETE FROM `creature_template_model` WHERE `CreatureID` = 800001;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(800001, 0, 28791, 1, 1);

-- =============================================
-- UPGRADE NPC TEXT ENTRIES
-- =============================================

-- Custom text entries for upgrade NPC scenarios
DELETE FROM `npc_text` WHERE `ID` BETWEEN 800001 AND 800010;

-- Text 800001: Player has no beacon
INSERT INTO `npc_text` (`ID`, `text0_0`) VALUES 
(800001, 'Ah, I see you don\'t have a beacon yet! Visit Engineer Gizmo Wayfinder first to get a Traveler\'s Beacon, then come back to me and I\'ll help you upgrade it!$B$BYou can find him nearby - he\'s the one with all the glowing gadgets.');

-- Text 800002: Player already has highest tier beacon
INSERT INTO `npc_text` (`ID`, `text0_0`) VALUES 
(800002, 'Your beacon is already the highest tier available! You have the best beacon money can buy.$B$BThat\'s a masterwork piece of travel technology you\'ve got there. I couldn\'t improve on it even if I tried!');

-- Text 800003: Upgrade not available yet
INSERT INTO `npc_text` (`ID`, `text0_0`) VALUES 
(800003, 'I\'m sorry, but the upgrade for your beacon isn\'t available yet. Come back later when I\'ve finished my research!$B$BI\'m still working on perfecting the enchantments for the next tier. These things take time to get right!');

-- Text 800004: Can upgrade (Tier 1 to 2)
INSERT INTO `npc_text` (`ID`, `text0_0`) VALUES 
(800004, 'I see you have a Traveler\'s Beacon! For 10 gold, I can upgrade it to a Dual Anchor Beacon which will give you 2 location slots instead of 1.$B$BThe upgrade will preserve all your saved locations. Would you like me to proceed?');

-- Text 800005: Can upgrade (Tier 2 to 3)
INSERT INTO `npc_text` (`ID`, `text0_0`) VALUES 
(800005, 'I see you have a Dual Anchor Beacon! For 25 gold, I can upgrade it to a Travel Network Beacon which will give you 5 location slots instead of 2.$B$BThe upgrade will preserve all your saved locations. Would you like me to proceed?');

-- Text 800006: Can upgrade (Tier 3 to 4)
INSERT INTO `npc_text` (`ID`, `text0_0`) VALUES 
(800006, 'I see you have a Travel Network Beacon! For 50 gold, I can upgrade it to a Master\'s Travel Beacon which will give you 10 location slots instead of 5.$B$BThe upgrade will preserve all your saved locations. Would you like me to proceed?');

-- Text 800007: Cannot upgrade - Level requirement
INSERT INTO `npc_text` (`ID`, `text0_0`) VALUES 
(800007, 'I\'d love to upgrade your beacon, but you need to be a higher level first.$B$BThe magical energies required for the upgrade are quite intense. Come back when you\'re more experienced!');

-- Text 800008: Cannot upgrade - Gold requirement
INSERT INTO `npc_text` (`ID`, `text0_0`) VALUES 
(800008, 'I\'d love to upgrade your beacon, but you don\'t have enough gold.$B$BThe rare materials and enchantments required for the upgrade don\'t come cheap. Come back when you have the funds!');

-- Text 800009: Cannot upgrade - Both level and gold
INSERT INTO `npc_text` (`ID`, `text0_0`) VALUES 
(800009, 'I\'d love to upgrade your beacon, but you need to meet the level and gold requirements first.$B$BThe magical energies and rare materials required for the upgrade are quite demanding. Come back when you\'re ready!');

-- Text 800010: Default/fallback text
INSERT INTO `npc_text` (`ID`, `text0_0`) VALUES 
(800010, 'Welcome to my beacon upgrade service! I can enhance your Traveler\'s Beacon to hold more locations.$B$BShow me your beacon and I\'ll see what I can do for you.');

-- Text 800011: Functionality upgrade menu
INSERT INTO `npc_text` (`ID`, `text0_0`) VALUES 
(800011, 'I can also enhance your beacon with special functionality! These upgrades work with any beacon tier and give you access to new travel options.$B$BWhat kind of enhancement interests you?');

-- =============================================
-- INSTALLATION NOTES
-- =============================================
-- World database v2.0 setup complete!
-- 
-- Current Features:
-- ✓ Tier 1 beacon (Traveler's Beacon - 1 location)
-- ✓ Tier 2 beacon (Dual Anchor Beacon - 2 locations, Level 20)
-- ✓ Tier 3 beacon (Travel Network Beacon - 5 locations, Level 40)
-- ✓ Tier 4 beacon (Master's Travel Beacon - 10 locations, Level 60)
-- ✓ Beacon upgrade system via NPC 800001 (Beacon Artificer)
-- ✓ Location transfer between beacon tiers
-- ✓ Traveler's Mark reagent
-- ✓ Portal Mark reagent (for future portal system)
-- ✓ Engineer Gizmo Wayfinder vendor
--
-- Installation:
-- 1. Import TravelersBeacon_worlddb.sql to WORLD database
-- 2. Import TravelersBeacon_charactersdb.sql to CHARACTER database
-- 3. Load TravelersBeacon.lua on server
-- 4. Spawn NPC: .npc add 800000 (beacon vendor)
-- 5. Spawn NPC: .npc add 800001 (upgrade vendor)
--
-- Upgrade Costs:
-- - Tier 1→2: 10g, Level 20
-- - Tier 2→3: 25g, Level 40  
-- - Tier 3→4: 50g, Level 60
--
-- Testing:
-- - Buy Tier 1 beacon (5g) from vendor NPC 800000
-- - Upgrade beacons via NPC 800001 (Beacon Artificer) when requirements met
-- - All saved locations transfer automatically during upgrades
-- ============================================= 