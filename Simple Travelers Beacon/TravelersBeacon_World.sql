-- New Custom Items for Traveler's Beacon System
-- Item 800,000: Traveler's Mark (replaces rune item, based on Abyssal Rune 47213)
-- Item 800,001: Starter Traveler's Beacon (copy of existing 23443 with new ID)

-- Item 800,000: Traveler's Mark
-- Based on Abyssal Rune (47213) but with modifications: white quality, 25s buy price, stack 200
DELETE FROM `item_template` WHERE `entry` = 800000;
INSERT INTO `item_template` (`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`, `BuyCount`, `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`, `maxcount`, `stackable`, `bonding`, `description`, `spellid_1`, `spelltrigger_1`, `material`) VALUES
(800000, 0, 8, 'Traveler\'s Mark', 48010, 1, 0, 1, 2500, 625, 0, -1, -1, 10, 1, 0, 200, 0, 'A mystical rune imbued with teleportation magic. Used to power Traveler\'s Beacons.', 0, 0, -1);

-- Item 800,001: Starter Traveler's Beacon (new custom ID version of 23443, which used to use 35948 display id)
DELETE FROM `item_template` WHERE `entry` = 800001;
INSERT INTO `item_template` (`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`, `BuyCount`, `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`, `maxcount`, `stackable`, `bonding`, `description`, `spellid_1`, `spelltrigger_1`, `material`) VALUES
(800001, 15, 0, 'Starter Traveler\'s Beacon', 50456, 1, 0, 1, 50000, 12500, 0, -1, -1, 10, 1, 1, 1, 1, 'A mystical beacon that can store one location and teleport you back to it. Requires Traveler\'s Marks to use.', 1, 0, 4);

-- Engineer Gizmo Wayfinder - Traveler's Beacon Engineer
DELETE FROM `creature_template` WHERE `entry` = 800000;
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `scale`, `rank`, `unit_class`, `unit_flags`, `type`, `type_flags`, `RegenHealth`, `flags_extra`, `AIName`) VALUES
(800000, 'Engineer Gizmo Wayfinder', 'Waypoint Technology Specialist', 'Buy', 80, 80, 35, 129, 1, 1.14286, 1, 0, 1, 0, 7, 0, 1, 0, '');

-- Create the display model for the NPC (Gnome Male Engineer)
DELETE FROM `creature_template_model` WHERE `CreatureID` = 800000;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(800000, 0, 26374, 1, 1);

-- Update NPC vendor to sell the new items instead of old ones
DELETE FROM `npc_vendor` WHERE `entry` = 800000;
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`) VALUES
(800000, 0, 800001, 0, 0, 0, 0),  -- New Starter Traveler's Beacon
(800000, 1, 800000, 0, 0, 0, 0);  -- New Traveler's Mark (replaces rune) 