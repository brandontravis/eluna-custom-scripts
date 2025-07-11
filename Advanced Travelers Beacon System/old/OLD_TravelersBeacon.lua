-- Traveler's Beacon Upgrade System for AzerothCore
-- Supports tiered beacon progression with different reagent costs

print("=== LOADING TRAVELER'S BEACON SYSTEM ===")

-- =============================================
-- CONFIGURATION
-- =============================================

-- Beacon Item IDs (Progression Tiers)
local BEACON_ITEMS = {
    [800001] = {level = 1, name = "Starter Traveler's Beacon", max_locations = 1},
    [800002] = {level = 2, name = "Traveler's Beacon", max_locations = 2},
    [800003] = {level = 3, name = "Advanced Traveler's Beacon", max_locations = 5},
    [800004] = {level = 4, name = "Master's Portal Beacon", max_locations = 5, has_portals = true}
}

print("BEACON ITEMS CONFIGURED:")
for itemId, data in pairs(BEACON_ITEMS) do
    print(string.format("  %d = %s (Level %d)", itemId, data.name, data.level))
end

-- Reagent Items and Costs
local REAGENTS = {
    TRAVELERS_MARK = 800000,   -- Basic teleports (25s each)
    ARCANE_CRYSTAL = 800010,   -- Portal casting (1g each)
    DUNGEON_STONE = 800020,    -- Dungeon teleports (1g each)
    RAID_SEAL = 800030         -- Raid teleports (2g each)
}

-- Content Pack Bitfield
local CONTENT_PACKS = {
    EK_DUNGEONS = 1,        -- 0x001
    KAL_DUNGEONS = 2,       -- 0x002  
    OUTLAND_DUNGEONS = 4,   -- 0x004
    NORTHREND_DUNGEONS = 8, -- 0x008
    EK_RAIDS = 16,          -- 0x010
    KAL_RAIDS = 32,         -- 0x020
    OUTLAND_RAIDS = 64,     -- 0x040
    NORTHREND_RAIDS = 128   -- 0x080
}

-- Upgrade Costs (item + gold cost in copper)
local UPGRADE_COSTS = {
    [1] = {gold = 100000, items = {{id = REAGENTS.TRAVELERS_MARK, count = 10}}}, -- 1->2: 10g + 10 marks
    [2] = {gold = 500000, items = {{id = REAGENTS.TRAVELERS_MARK, count = 25}}}, -- 2->3: 50g + 25 marks  
    [3] = {gold = 1000000, items = {{id = REAGENTS.ARCANE_CRYSTAL, count = 5}}} -- 3->4: 100g + 5 crystals
}

-- System Settings
local CAST_TIME = 5000 -- 5 seconds cast time
local COOLDOWN_TIME = 0 -- No cooldown currently
local CHANNEL_SPELL = 12051 -- Evocation spell for casting animation

-- =============================================
-- CACHE AND STATE
-- =============================================

local playerLocationCache = {}
local playerCooldowns = {}

-- =============================================
-- UTILITY FUNCTIONS
-- =============================================

-- Get player's current beacon level and item
local function GetPlayerBeacon(player)
    for itemId, data in pairs(BEACON_ITEMS) do
        if player:HasItem(itemId) then
            return itemId, data
        end
    end
    return nil, nil
end

-- Get player's beacon progress from database
local function GetPlayerProgress(playerGuid)
    local query = string.format("SELECT beacon_level, content_packs FROM player_beacon_progress WHERE guid = %d", playerGuid)
    local result = CharDBQuery(query)
    
    if result then
        return result:GetUInt32(0), result:GetUInt32(1)
    end
    
    -- Initialize new player
    CharDBExecute(string.format("INSERT INTO player_beacon_progress (guid, beacon_level, content_packs) VALUES (%d, 1, 0)", playerGuid))
    return 1, 0
end

-- Update player's beacon progress
local function UpdatePlayerProgress(playerGuid, beaconLevel, contentPacks)
    local query = string.format(
        "INSERT INTO player_beacon_progress (guid, beacon_level, content_packs) VALUES (%d, %d, %d) ON DUPLICATE KEY UPDATE beacon_level = %d, content_packs = %d",
        playerGuid, beaconLevel, contentPacks, beaconLevel, contentPacks
    )
    CharDBExecute(query)
end

-- Check if player has required reagents
local function HasReagents(player, reagentId, count)
    return player:GetItemCount(reagentId) >= count
end

-- Consume reagents from player
local function ConsumeReagents(player, reagentId, count)
    player:RemoveItem(reagentId, count)
end

-- Check if player has enough gold
local function HasGold(player, copperAmount)
    return player:GetCoinage() >= copperAmount
end

-- Consume gold from player
local function ConsumeGold(player, copperAmount)
    player:ModifyMoney(-copperAmount)
end

-- Check if location is valid for teleportation
local function IsValidTeleportLocation(player, mapId, x, y, z)
    if x == 0 and y == 0 and z == 0 then
        return false, "Invalid coordinates."
    end
    
    if math.abs(x) > 20000 or math.abs(y) > 20000 or math.abs(z) > 20000 then
        return false, "Coordinates out of reasonable range."
    end
    
    -- Prevent teleportation to instances and battlegrounds
    if (mapId >= 30 and mapId <= 90) or (mapId >= 189 and mapId <= 650) or (mapId >= 489 and mapId <= 628) then
        return false, "Cannot teleport to instances, dungeons, raids, or battlegrounds."
    end
    
    return true, ""
end

-- Get zone name for location
local function GetZoneName(player)
    local zoneId = player:GetZoneId()
    local areaId = player:GetAreaId()
    
    local areaName = GetAreaName(areaId)
    if areaName and areaName ~= "" then
        return areaName
    end
    
    local zoneName = GetAreaName(zoneId)
    if zoneName and zoneName ~= "" then
        return zoneName
    end
    
    local x, y, z = player:GetLocation()
    return string.format("Location (%.1f, %.1f)", x, y)
end

-- =============================================
-- LOCATION MANAGEMENT
-- =============================================

-- Get player's stored locations
local function GetPlayerLocations(playerGuid, beaconItemId)
    if playerLocationCache[playerGuid] then
        return playerLocationCache[playerGuid]
    end
    
    local query = string.format([[
        SELECT location_slot, location_name, map_id, position_x, position_y, position_z, orientation, location_type
        FROM player_beacon_locations
        WHERE guid = %d AND beacon_item_id = %d
        ORDER BY location_slot
    ]], playerGuid, beaconItemId)
    
    local result = CharDBQuery(query)
    local locations = {}
    
    if result then
        repeat
            local slot = result:GetUInt32(0)
            local name = result:GetString(1)
            local mapId = result:GetUInt32(2)
            local x = result:GetFloat(3)
            local y = result:GetFloat(4)
            local z = result:GetFloat(5)
            local o = result:GetFloat(6)
            local locType = result:GetString(7)
            
            locations[slot] = {
            name = name,
            mapId = mapId,
            x = x,
            y = y,
            z = z,
                o = o,
                type = locType
            }
        until not result:NextRow()
    end
    
    playerLocationCache[playerGuid] = locations
    return locations
end

-- Save a location to a specific slot
local function SaveLocationToSlot(playerGuid, beaconItemId, slot, name, mapId, x, y, z, o, locationType)
    locationType = locationType or 'manual'
    
    local query = string.format([[
        INSERT INTO player_beacon_locations (guid, beacon_item_id, location_slot, location_name, map_id, position_x, position_y, position_z, orientation, location_type)
        VALUES (%d, %d, %d, '%s', %d, %f, %f, %f, %f, '%s')
        ON DUPLICATE KEY UPDATE
        location_name = '%s', map_id = %d, position_x = %f, position_y = %f, position_z = %f, orientation = %f, location_type = '%s'
    ]], playerGuid, beaconItemId, slot, name, mapId, x, y, z, o, locationType, name, mapId, x, y, z, o, locationType)
    
    CharDBExecute(query)
    playerLocationCache[playerGuid] = nil -- Clear cache
end

-- Delete a location from a specific slot
local function DeleteLocationFromSlot(playerGuid, beaconItemId, slot)
    local query = string.format([[
        DELETE FROM player_beacon_locations
        WHERE guid = %d AND beacon_item_id = %d AND location_slot = %d
    ]], playerGuid, beaconItemId, slot)
    
    CharDBExecute(query)
    playerLocationCache[playerGuid] = nil -- Clear cache
end

-- =============================================
-- UPGRADE SYSTEM
-- =============================================

-- Check if player can upgrade their beacon
local function CanUpgradeBeacon(player, currentLevel)
    if currentLevel >= 4 then
        return false, "Your beacon is already at maximum level."
    end
    
    local upgradeCost = UPGRADE_COSTS[currentLevel]
    if not upgradeCost then
        return false, "No upgrade path available."
    end
    
    -- Check gold
    if not HasGold(player, upgradeCost.gold) then
        local goldNeeded = upgradeCost.gold / 10000 -- Convert copper to gold
        return false, string.format("You need %d gold to upgrade.", goldNeeded)
    end
    
    -- Check reagents
    for _, item in ipairs(upgradeCost.items) do
        if not HasReagents(player, item.id, item.count) then
            return false, string.format("You need %d more reagents to upgrade.", item.count - player:GetItemCount(item.id))
        end
    end
    
    return true, ""
end

-- Perform beacon upgrade
local function UpgradeBeacon(player, currentLevel, currentBeaconId)
    local playerGuid = player:GetGUIDLow()
    local upgradeCost = UPGRADE_COSTS[currentLevel]
    local newLevel = currentLevel + 1
    local newBeaconId = nil
    
    -- Find new beacon item ID
    for itemId, data in pairs(BEACON_ITEMS) do
        if data.level == newLevel then
            newBeaconId = itemId
            break
        end
    end
    
    if not newBeaconId then
        player:SendBroadcastMessage("Error: Cannot find upgrade beacon.")
        return false
    end
    
    -- Consume costs
    ConsumeGold(player, upgradeCost.gold)
    for _, item in ipairs(upgradeCost.items) do
        ConsumeReagents(player, item.id, item.count)
    end
    
    -- Remove old beacon and give new one
    player:RemoveItem(currentBeaconId, 1)
    player:AddItem(newBeaconId, 1)
    
    -- Update database progress
    local _, contentPacks = GetPlayerProgress(playerGuid)
    UpdatePlayerProgress(playerGuid, newLevel, contentPacks)
    
    -- Update all existing locations to use new beacon ID
    local query = string.format([[
        UPDATE player_beacon_locations 
        SET beacon_item_id = %d 
        WHERE guid = %d AND beacon_item_id = %d
    ]], newBeaconId, playerGuid, currentBeaconId)
    CharDBExecute(query)
    
    playerLocationCache[playerGuid] = nil -- Clear cache
    
    local beaconName = BEACON_ITEMS[newBeaconId].name
    player:SendBroadcastMessage(string.format("Beacon upgraded to: %s", beaconName))
    
    return true
end

print("Beacon upgrade system core functions loaded...")

-- =============================================
-- TELEPORTATION SYSTEM  
-- =============================================

-- Perform actual teleportation after casting
local function PerformTeleport(playerGuid, location)
    local player = GetPlayerByGUID(playerGuid)
    if not player then return end
    
    local isValid, errorMsg = IsValidTeleportLocation(player, location.mapId, location.x, location.y, location.z)
    if not isValid then
        player:SendBroadcastMessage("Teleportation failed: " .. errorMsg)
        return
    end
    
    -- Special effects before teleport
    player:CastSpell(player, 64446, true) -- Blue teleport visual
    
    -- Perform teleport
    player:Teleport(location.mapId, location.x, location.y, location.z, location.o)
    
    -- Clear cooldown after successful teleport
    playerCooldowns[playerGuid] = nil
    
    player:SendBroadcastMessage("Teleported to: " .. location.name)
end

-- Start casting for teleportation
local function StartTeleportCast(player, location, reagentId, reagentCount)
    local playerGuid = player:GetGUIDLow()
    
    -- Check cooldown
    if playerCooldowns[playerGuid] and playerCooldowns[playerGuid] > GetCurrTime() then
        local remaining = playerCooldowns[playerGuid] - GetCurrTime()
        player:SendBroadcastMessage(string.format("Beacon is on cooldown for %d more seconds.", remaining))
        return false
    end
    
    -- Consume reagents
    ConsumeReagents(player, reagentId, reagentCount)
    
    -- Set cooldown
    playerCooldowns[playerGuid] = GetCurrTime() + COOLDOWN_TIME
    
    -- Start casting animation
    player:CastSpell(player, CHANNEL_SPELL, false)
    
    -- Send status message
    player:SendBroadcastMessage("Channeling teleportation magic...")
    
    -- Schedule teleportation after cast time
    player:RegisterEvent(function(eventId, delay, repeats, pPlayer)
        if pPlayer:IsChannelingSpell() then
            pPlayer:InterruptSpell(0, false)
        end
        PerformTeleport(playerGuid, location)
    end, CAST_TIME, 1)
    
    return true
end

-- =============================================
-- PORTAL CASTING SYSTEM
-- =============================================

-- Create a portal to a location
local function CreatePortal(player, location)
    local playerGuid = player:GetGUIDLow()
    
    -- Check reagents (1 Arcane Crystal per portal)
    if not HasReagents(player, REAGENTS.ARCANE_CRYSTAL, 1) then
        player:SendBroadcastMessage("You need an Arcane Crystal to create a portal.")
        return false
    end
    
    -- Consume reagent
    ConsumeReagents(player, REAGENTS.ARCANE_CRYSTAL, 1)
    
    -- Start portal casting animation
    player:CastSpell(player, CHANNEL_SPELL, false)
    player:SendBroadcastMessage("Creating portal...")
    
    -- Schedule portal creation
    player:RegisterEvent(function(eventId, delay, repeats, pPlayer)
        if pPlayer:IsChannelingSpell() then
            pPlayer:InterruptSpell(0, false)
        end
        
        -- Create portal visual effects
        pPlayer:CastSpell(pPlayer, 32571, true) -- Portal visual
        
        -- Store portal data for other players to use
        -- Note: This would need additional implementation for persistent portals
        pPlayer:SendAreaTriggerMessage(string.format("Portal to %s created by %s", location.name, pPlayer:GetName()))
        
    end, CAST_TIME, 1)
    
    return true
end

-- =============================================
-- GOSSIP HANDLERS
-- =============================================

local function OnGossipSelect(event, player, item, sender, intid, code)
    local itemId = item:GetEntry()
    local playerGuid = player:GetGUIDLow()
    local beaconData = BEACON_ITEMS[itemId]
    
    print(string.format("DEBUG: Gossip selection - Player: %s, Item: %d, IntID: %d", player:GetName(), itemId, intid))
    
    if not beaconData then
        print("DEBUG: Invalid beacon in gossip selection")
        return false
    end
    
    player:GossipClearMenu()
    
    if intid >= 1000 and intid < 2000 then
        -- Teleport to location (1000-1999)
        local slot = intid - 1000
        local locations = GetPlayerLocations(playerGuid, itemId)
        
        if locations[slot] then
            if HasReagents(player, REAGENTS.TRAVELERS_MARK, 1) then
                player:GossipComplete()
                StartTeleportCast(player, locations[slot], REAGENTS.TRAVELERS_MARK, 1)
            else
                player:SendBroadcastMessage("You need a Traveler's Mark to teleport.")
                player:GossipComplete()
            end
        end
        
    elseif intid == 2000 then
        -- Portal Options Menu
        if beaconData.has_portals then
            local locations = GetPlayerLocations(playerGuid, itemId)
            
            for slot = 0, beaconData.max_locations - 1 do
                if locations[slot] then
                    local location = locations[slot]
                    if HasReagents(player, REAGENTS.ARCANE_CRYSTAL, 1) then
                        player:GossipMenuAddItem(0, string.format("Create portal to %s (1 Arcane Crystal)", location.name), 0, 2100 + slot)
                    else
                        player:GossipMenuAddItem(0, string.format("|cff999999Portal to %s (Need Arcane Crystal)|r", location.name), 0, 9998)
                    end
                end
            end
            
            player:GossipMenuAddItem(0, "Back to Main Menu", 0, 8000)
            player:GossipSendMenu(1, item)
        end
        
    elseif intid >= 2100 and intid < 2200 then
        -- Create Portal (2100-2199)
        local slot = intid - 2100
        local locations = GetPlayerLocations(playerGuid, itemId)
        
        if locations[slot] and beaconData.has_portals then
            player:GossipComplete()
            CreatePortal(player, locations[slot])
        end
        
    elseif intid == 3000 then
        -- Manage Locations Menu
        local locations = GetPlayerLocations(playerGuid, itemId)
        
        -- Show save options for empty slots
        for slot = 0, beaconData.max_locations - 1 do
            if not locations[slot] then
                player:GossipMenuAddItem(0, string.format("Save current location to slot %d", slot + 1), 0, 3100 + slot)
            else
                player:GossipMenuAddItem(0, string.format("Overwrite slot %d: %s", slot + 1, locations[slot].name), 0, 3100 + slot)
            end
        end
        
        -- Show delete options for occupied slots
        for slot = 0, beaconData.max_locations - 1 do
            if locations[slot] then
                player:GossipMenuAddItem(0, string.format("Delete slot %d: %s", slot + 1, locations[slot].name), 0, 3200 + slot)
            end
        end
        
        player:GossipMenuAddItem(0, "Back to Main Menu", 0, 8000)
        player:GossipSendMenu(1, item)
        
    elseif intid >= 3100 and intid < 3200 then
        -- Save Location (3100-3199)
        local slot = intid - 3100
        
        local currentMapId = player:GetMapId()
        local x, y, z = player:GetLocation()
        local o = player:GetO()
        
        local isValid, errorMsg = IsValidTeleportLocation(player, currentMapId, x, y, z)
        if not isValid then
            player:SendBroadcastMessage("Error: " .. errorMsg)
            player:GossipComplete()
            return false
        end
        
        local zoneName = GetZoneName(player)
        SaveLocationToSlot(playerGuid, itemId, slot, zoneName, currentMapId, x, y, z, o, 'manual')
        
        player:SendBroadcastMessage(string.format("Location saved to slot %d: %s", slot + 1, zoneName))
        player:GossipComplete()
        
    elseif intid >= 3200 and intid < 3300 then
        -- Delete Location (3200-3299)
        local slot = intid - 3200
        local locations = GetPlayerLocations(playerGuid, itemId)
        
        if locations[slot] then
            local locationName = locations[slot].name
            DeleteLocationFromSlot(playerGuid, itemId, slot)
            player:SendBroadcastMessage(string.format("Deleted location from slot %d: %s", slot + 1, locationName))
        end
        
        player:GossipComplete()
        
    elseif intid == 4000 then
        -- Upgrade Beacon Menu
        local currentLevel = beaconData.level
        local canUpgrade, errorMsg = CanUpgradeBeacon(player, currentLevel)
        
        if canUpgrade then
            local upgradeCost = UPGRADE_COSTS[currentLevel]
            local goldCost = upgradeCost.gold / 10000 -- Convert to gold
            
            local costText = string.format("Upgrade to Level %d (%dg", currentLevel + 1, goldCost)
            for _, item in ipairs(upgradeCost.items) do
                costText = costText .. string.format(" + %d reagents", item.count)
            end
            costText = costText .. ")"
            
            player:GossipMenuAddItem(0, costText, 0, 4100)
            player:GossipMenuAddItem(0, "View Upgrade Benefits", 0, 4200)
        else
            player:GossipMenuAddItem(0, "|cff999999Cannot Upgrade|r", 0, 9998)
            player:GossipMenuAddItem(0, string.format("|cffff0000%s|r", errorMsg), 0, 9998)
        end
        
        player:GossipMenuAddItem(0, "Content Pack Options", 0, 5000)
        player:GossipMenuAddItem(0, "Back to Main Menu", 0, 8000)
        player:GossipSendMenu(1, item)
        
    elseif intid == 4100 then
        -- Confirm Upgrade
        local currentLevel = beaconData.level
        local canUpgrade, errorMsg = CanUpgradeBeacon(player, currentLevel)
        
        if canUpgrade then
            player:GossipComplete()
            if UpgradeBeacon(player, currentLevel, itemId) then
                player:SendBroadcastMessage("Beacon upgrade successful!")
            else
                player:SendBroadcastMessage("Beacon upgrade failed.")
            end
        else
            player:SendBroadcastMessage("Cannot upgrade: " .. errorMsg)
            player:GossipComplete()
        end
        
    elseif intid == 4200 then
        -- View Upgrade Benefits
        local currentLevel = beaconData.level
        local nextLevel = currentLevel + 1
        
        if nextLevel <= 4 then
            local nextBeaconId = nil
            for id, data in pairs(BEACON_ITEMS) do
                if data.level == nextLevel then
                    nextBeaconId = id
                    break
                end
            end
            
            if nextBeaconId then
                local nextData = BEACON_ITEMS[nextBeaconId]
                player:SendBroadcastMessage(string.format("Upgrade Benefits for Level %d:", nextLevel))
                player:SendBroadcastMessage(string.format("- Name: %s", nextData.name))
                player:SendBroadcastMessage(string.format("- Max Locations: %d", nextData.max_locations))
                if nextData.has_portals then
                    player:SendBroadcastMessage("- Portal Casting: Yes")
                end
            end
        end
        
        player:GossipComplete()
        
    elseif intid == 5000 then
        -- Content Pack Options (placeholder for future implementation)
        player:SendBroadcastMessage("Content pack system coming soon!")
        player:GossipComplete()
        
    elseif intid == 8000 then
        -- Back to Main Menu - reshow main menu
        local locations = GetPlayerLocations(playerGuid, itemId)
        
        -- Add location recall options
        for slot = 0, beaconData.max_locations - 1 do
            if locations[slot] then
                local location = locations[slot]
                if HasReagents(player, REAGENTS.TRAVELERS_MARK, 1) then
                    player:GossipMenuAddItem(0, string.format("Recall to %s (1 Traveler's Mark)", location.name), 0, 1000 + slot)
                else
                    player:GossipMenuAddItem(0, string.format("|cff999999Recall to %s (Need Traveler's Mark)|r", location.name), 0, 9998)
                end
            end
        end
        
        -- Add portal option for Master's Portal Beacon
        if beaconData.has_portals then
            player:GossipMenuAddItem(0, "Portal Options", 0, 2000)
        end
        
        -- Add management options
        player:GossipMenuAddItem(0, "Manage Locations", 0, 3000)
        player:GossipMenuAddItem(0, "Upgrade Beacon", 0, 4000)
        player:GossipMenuAddItem(0, "Cancel", 0, 9999)
        
        player:GossipSendMenu(1, item)
        
    elseif intid == 9999 then
        -- Cancel
        player:GossipComplete()
        
    elseif intid == 9998 then
        -- Invalid option (grayed out)
        player:GossipComplete()
    end
    
    return false
end

-- =============================================
-- MAIN BEACON USAGE HANDLER
-- =============================================

local function OnBeaconUse(event, player, item, target)
    local itemId = item:GetEntry()
    local playerGuid = player:GetGUIDLow()
    
    print("=== BEACON USE EVENT TRIGGERED ===")
    print(string.format("Player: %s (GUID: %d)", player:GetName(), playerGuid))
    print(string.format("Item: %d", itemId))
    player:SendBroadcastMessage("BEACON CLICKED - Check console for debug info")
    
    -- Check if this is a valid beacon
    local beaconData = BEACON_ITEMS[itemId]
    if not beaconData then
        print("ERROR: Item " .. itemId .. " is not a valid beacon")
        player:SendBroadcastMessage("ERROR: Invalid beacon item")
        return false
    end
    
    print(string.format("Valid beacon - Level %d: %s", beaconData.level, beaconData.name))
    
    -- Check combat
    if player:IsInCombat() then
        player:SendBroadcastMessage("You cannot use a beacon while in combat.")
        return false
    end
    
    -- Check location restrictions
    local mapId = player:GetMapId()
    if (mapId >= 30 and mapId <= 650) or (mapId >= 489 and mapId <= 628) then
        player:SendBroadcastMessage("You cannot use a beacon in dungeons, raids, battlegrounds, or arenas.")
        return false
    end
    
    -- Get player locations
    local locations = GetPlayerLocations(playerGuid, itemId)
    local hasLocations = false
    for slot = 0, beaconData.max_locations - 1 do
        if locations[slot] then
            hasLocations = true
            break
        end
    end
    
    if not hasLocations then
        -- No saved locations, save current location to slot 0
        local currentMapId = player:GetMapId()
        local x, y, z = player:GetLocation()
        local o = player:GetO()
        
        local isValid, errorMsg = IsValidTeleportLocation(player, currentMapId, x, y, z)
        if not isValid then
            player:SendBroadcastMessage("Error: " .. errorMsg)
            return false
        end
        
        local zoneName = GetZoneName(player)
        SaveLocationToSlot(playerGuid, itemId, 0, zoneName, currentMapId, x, y, z, o, 'manual')
        
        player:SendBroadcastMessage("Location saved: " .. zoneName)
        player:SendBroadcastMessage("Use the beacon again to access teleportation options.")
    else
        -- Show main menu
        player:GossipClearMenu()
        
        -- Add location recall options
        for slot = 0, beaconData.max_locations - 1 do
            if locations[slot] then
                local location = locations[slot]
                if HasReagents(player, REAGENTS.TRAVELERS_MARK, 1) then
                    player:GossipMenuAddItem(0, string.format("Recall to %s (1 Traveler's Mark)", location.name), 0, 1000 + slot)
                else
                    player:GossipMenuAddItem(0, string.format("|cff999999Recall to %s (Need Traveler's Mark)|r", location.name), 0, 9998)
                end
            end
        end
        
        -- Add portal option for Master's Portal Beacon
        if beaconData.has_portals then
            player:GossipMenuAddItem(0, "Portal Options", 0, 2000)
        end
        
        -- Add management options
        player:GossipMenuAddItem(0, "Manage Locations", 0, 3000)
        player:GossipMenuAddItem(0, "Upgrade Beacon", 0, 4000)
        player:GossipMenuAddItem(0, "Cancel", 0, 9999)
        
        player:GossipSendMenu(1, item)
        print("=== GOSSIP MENU SENT TO PLAYER ===")
    end
    
    print("=== BEACON USE EVENT COMPLETED ===")
    return false
end

-- =============================================
-- UPGRADE NPC HANDLERS (Creature 800001)
-- =============================================

local function OnUpgradeNPCHello(event, player, creature)
    player:GossipClearMenu()
    
    -- Get player's current beacon
    local beaconItemId, beaconData = GetPlayerBeacon(player)
    
    if not beaconItemId then
        player:GossipMenuAddItem(0, "You need a Traveler's Beacon to upgrade!", 0, 9998)
        player:GossipMenuAddItem(0, "Visit Engineer Gizmo to purchase a starter beacon.", 0, 9998)
    else
        local currentLevel = beaconData.level
        player:GossipMenuAddItem(0, string.format("Current Beacon: %s (Level %d)", beaconData.name, currentLevel), 0, 9998)
        
        -- Check if can upgrade
        local canUpgrade, errorMsg = CanUpgradeBeacon(player, currentLevel)
        if canUpgrade then
            local upgradeCost = UPGRADE_COSTS[currentLevel]
            local goldCost = upgradeCost.gold / 10000
            
            local costText = string.format("Upgrade to Level %d (%dg", currentLevel + 1, goldCost)
            for _, item in ipairs(upgradeCost.items) do
                costText = costText .. string.format(" + %d reagents", item.count)
            end
            costText = costText .. ")"
            
            player:GossipMenuAddItem(0, costText, 0, 1001)
            player:GossipMenuAddItem(0, "View upgrade benefits", 0, 1002)
        else
            player:GossipMenuAddItem(0, "|cff999999Cannot Upgrade|r", 0, 9998)
            player:GossipMenuAddItem(0, string.format("|cffff0000%s|r", errorMsg), 0, 9998)
        end
        
        player:GossipMenuAddItem(0, "Content Pack Options (Coming Soon)", 0, 9998)
    end
    
    player:GossipMenuAddItem(0, "Goodbye", 0, 9999)
    player:GossipSendMenu(1, creature)
            return false
        end
        
local function OnUpgradeNPCSelect(event, player, creature, sender, intid, code)
    local beaconItemId, beaconData = GetPlayerBeacon(player)
    
    if intid == 1001 then
        -- Confirm upgrade
        if beaconItemId and beaconData then
            local currentLevel = beaconData.level
            local canUpgrade, errorMsg = CanUpgradeBeacon(player, currentLevel)
            
            if canUpgrade then
                player:GossipComplete()
                if UpgradeBeacon(player, currentLevel, beaconItemId) then
                    player:SendBroadcastMessage("Beacon upgrade successful!")
                else
                    player:SendBroadcastMessage("Beacon upgrade failed.")
                end
            else
                player:SendBroadcastMessage("Cannot upgrade: " .. errorMsg)
            player:GossipComplete()
            end
        end
        
    elseif intid == 1002 then
        -- View upgrade benefits
        if beaconData then
            local currentLevel = beaconData.level
            local nextLevel = currentLevel + 1
            
            if nextLevel <= 4 then
                local nextBeaconId = nil
                for id, data in pairs(BEACON_ITEMS) do
                    if data.level == nextLevel then
                        nextBeaconId = id
                        break
                    end
                end
                
                if nextBeaconId then
                    local nextData = BEACON_ITEMS[nextBeaconId]
                    player:SendBroadcastMessage(string.format("=== Upgrade Benefits for Level %d ===", nextLevel))
                    player:SendBroadcastMessage(string.format("Name: %s", nextData.name))
                    player:SendBroadcastMessage(string.format("Max Locations: %d", nextData.max_locations))
                    if nextData.has_portals then
                        player:SendBroadcastMessage("NEW: Portal Casting Ability!")
                    end
                end
            end
        end
        player:GossipComplete()
        
    elseif intid == 9999 then
        -- Goodbye
        player:GossipComplete()
        
    elseif intid == 9998 then
        -- Invalid option
        player:GossipComplete()
    end
    
    return false
end

-- Debug: Print beacon items being registered
print("DEBUG: Beacon items to register:")
for itemId, data in pairs(BEACON_ITEMS) do
    print("  Item " .. itemId .. ": " .. data.name .. " (Level " .. data.level .. ")")
end

-- Clean registration - remove all the test bullshit
print("Registering beacon events...")

-- Register events for all beacon items - ONE handler per item
for itemId, _ in pairs(BEACON_ITEMS) do
    RegisterItemEvent(itemId, 2, OnBeaconUse) -- ITEM_EVENT_ON_USE
    RegisterItemGossipEvent(itemId, 2, OnGossipSelect) -- GOSSIP_EVENT_ON_SELECT
    print("Registered events for beacon item: " .. itemId)
end

-- Register events for upgrade NPC (creature 800001)
RegisterCreatureGossipEvent(800001, 1, OnUpgradeNPCHello) -- GOSSIP_EVENT_ON_HELLO
RegisterCreatureGossipEvent(800001, 2, OnUpgradeNPCSelect) -- GOSSIP_EVENT_ON_SELECT
print("Registered events for upgrade NPC: 800001")

-- All event registration complete

print("Main beacon handler and gossip handlers loaded...")

-- =============================================
-- INITIALIZATION MESSAGE
-- =============================================

print("==========================================")
print("TRAVELER'S BEACON UPGRADE SYSTEM LOADED!")
print("==========================================")
print("Features:")
print("  4-Tier Progressive Beacon System")
print("  Dynamic Reagent Requirements")
print("  Portal Casting (Tier 4)")
print("  Location Management")
print("  Upgrade System with Costs")
print("  Professional Casting Animations")
print("  Upgrade NPC Gossip Handlers")
print("  Debug Logging Enabled")
print("==========================================")
print("Beacon Tiers:")
print("  Level 1: Starter (1 location)")
print("  Level 2: Enhanced (2 locations)")  
print("  Level 3: Advanced (5 locations)")
print("  Level 4: Master (5 + portals)")
print("==========================================")
print("NPCs:")
print("  Engineer Gizmo (800000): Vendor")
print("  Arcane Engineer Voltis (800001): Upgrades")
print("==========================================")
print("Reagents:")
print("  Traveler's Mark (800000): Basic teleports")
print("  Arcane Crystal (800010): Portal casting")
print("  Dungeon Stone (800020): Dungeon teleports") 
print("  Raid Seal (800030): Raid teleports")
print("==========================================")
print("System ready for testing with debug logging!") 