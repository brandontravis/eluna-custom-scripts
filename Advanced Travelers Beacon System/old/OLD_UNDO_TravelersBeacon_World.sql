-- =============================================
-- UNDO SCRIPT FOR TRAVELER'S BEACON WORLD DATABASE
-- =============================================
-- This script removes ALL items, NPCs, and vendors created by TravelersBeacon_World.sql

-- Remove all custom beacon items
DELETE FROM `item_template` WHERE `entry` IN (800000, 800001, 800002, 800003, 800004, 800010, 800020, 800030);

-- Remove all vendor entries for Engineer Gizmo
DELETE FROM `npc_vendor` WHERE `entry` = 800000;

-- Remove Arcane Engineer Voltis NPC
DELETE FROM `creature_template` WHERE `entry` = 800001;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 800001;

-- Remove any spawned creatures (if they exist)
DELETE FROM `creature` WHERE `id1` = 800001;

-- =============================================
-- CLEANUP COMPLETE
-- =============================================
-- All Traveler's Beacon items and NPCs have been removed from the world database. 