-- Traveler's Beacon System for AzerothCore (Advanced - v1 Foundation)
-- Starting with working simple system, will add tier progression

print("=== LOADING ADVANCED TRAVELER'S BEACON SYSTEM v1 ===")

-- =============================================
-- CONFIGURATION
-- =============================================

-- Base beacon configuration (Tier 1 to start)
local BEACON_ITEMS = {
    [800001] = {tier = 1, name = "Traveler's Beacon", max_locations = 1}
}

-- Reagent items
local REAGENTS = {
    TRAVELERS_MARK = 800000, -- 25s each, stackable to 200
    PORTAL_MARK = 800010     -- Future portal reagent
}

-- System settings
local CAST_TIME = 5000      -- 5 seconds cast time
local COOLDOWN_TIME = 900   -- 15 minutes cooldown (900 seconds)
local CHANNEL_SPELL = 12051 -- Evocation animation

print("BEACON CONFIGURATION LOADED:")
for itemId, data in pairs(BEACON_ITEMS) do
    print(string.format("  %d = %s (Tier %d, %d locations)", itemId, data.name, data.tier, data.max_locations))
end

-- =============================================
-- CACHE AND STATE
-- =============================================

local playerLocationCache = {}
local playerCooldowns = {}

-- =============================================
-- UTILITY FUNCTIONS
-- =============================================

-- Get player's current beacon
local function GetPlayerBeacon(player)
    for itemId, data in pairs(BEACON_ITEMS) do
        if player:HasItem(itemId) then
            return itemId, data
        end
    end
    return nil, nil
end

-- Check if location is valid for teleportation
local function IsValidTeleportLocation(player, mapId, x, y, z)
    print("DEBUG: Validating location - MapID: " .. mapId .. ", X: " .. x .. ", Y: " .. y .. ", Z: " .. z)
    
    if x == 0 and y == 0 and z == 0 then
        return false, "Invalid coordinates."
    end
    
    if math.abs(x) > 20000 or math.abs(y) > 20000 or math.abs(z) > 20000 then
        return false, "Coordinates out of reasonable range."
    end
    
    -- Prevent teleportation to instances/dungeons/raids/battlegrounds/arenas
    if (mapId >= 30 and mapId <= 90) or          -- Classic dungeons
       (mapId >= 189 and mapId <= 230) or        -- Classic raids
       (mapId >= 249 and mapId <= 429) or        -- More dungeons/raids
       (mapId >= 469 and mapId <= 580) or        -- TBC dungeons/raids
       (mapId >= 595 and mapId <= 650) or        -- WotLK dungeons/raids
       (mapId >= 489 and mapId <= 566) or        -- Battlegrounds
       (mapId >= 617 and mapId <= 628) then      -- Arenas
        return false, "Cannot teleport to instances, dungeons, raids, battlegrounds, or arenas."
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

-- Check if player has enough reagents
local function HasEnoughReagents(player, reagentId, count)
    return player:GetItemCount(reagentId) >= count
end

-- Consume reagents from player
local function ConsumeReagents(player, reagentId, count)
    player:RemoveItem(reagentId, count)
end

-- =============================================
-- COOLDOWN MANAGEMENT
-- =============================================

local function IsOnCooldown(playerGuid)
    if not playerCooldowns[playerGuid] then
        return false, 0
    end
    
    local currentTime = GetCurrTime()
    local lastUseTime = playerCooldowns[playerGuid]
    local elapsed = currentTime - lastUseTime
    
    -- Convert to seconds if needed
    local elapsedSeconds = elapsed
    if elapsed > 1000 then
        elapsedSeconds = elapsed / 1000
    end
    
    if elapsedSeconds < COOLDOWN_TIME then
        local remaining = math.ceil(COOLDOWN_TIME - elapsedSeconds)
        return true, remaining
    end
    
    return false, 0
end

local function SetCooldown(playerGuid)
    playerCooldowns[playerGuid] = GetCurrTime()
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
        SELECT location_slot, location_name, map_id, position_x, position_y, position_z, orientation
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
            
            locations[slot] = {
                name = name,
                mapId = mapId,
                x = x,
                y = y,
                z = z,
                o = o
            }
        until not result:NextRow()
    end
    
    playerLocationCache[playerGuid] = locations
    return locations
end

-- Save a location
local function SaveLocation(playerGuid, beaconItemId, slot, name, mapId, x, y, z, o)
    local query = string.format([[
        INSERT INTO player_beacon_locations (guid, beacon_item_id, location_slot, location_name, map_id, position_x, position_y, position_z, orientation)
        VALUES (%d, %d, %d, '%s', %d, %f, %f, %f, %f)
        ON DUPLICATE KEY UPDATE
        location_name = '%s', map_id = %d, position_x = %f, position_y = %f, position_z = %f, orientation = %f
    ]], playerGuid, beaconItemId, slot, name, mapId, x, y, z, o, name, mapId, x, y, z, o)
    
    CharDBExecute(query)
    playerLocationCache[playerGuid] = nil -- Clear cache
end

-- Delete a location
local function DeleteLocation(playerGuid, beaconItemId, slot)
    local query = string.format([[
        DELETE FROM player_beacon_locations
        WHERE guid = %d AND beacon_item_id = %d AND location_slot = %d
    ]], playerGuid, beaconItemId, slot)
    
    CharDBExecute(query)
    playerLocationCache[playerGuid] = nil -- Clear cache
end

-- =============================================
-- TELEPORTATION SYSTEM
-- =============================================

local function StartTeleportChannel(player, location, beaconItemId)
    local playerGuid = player:GetGUIDLow()
    local startX, startY, startZ = player:GetLocation()
    local startMana = player:GetPower(0) -- POWER_MANA
    
    player:SendBroadcastMessage("Teleporting to " .. location.name .. "...")
    
    if player:IsInCombat() then
        player:SendBroadcastMessage("You can't channel while in combat!")
        return false
    end
    
    -- Start evocation channel
    player:CastSpell(player, CHANNEL_SPELL, true)
    
    -- Schedule teleport completion
    player:RegisterEvent(function(eventId, delay, repeats)
        local currentPlayer = GetPlayerByGUID(playerGuid)
        if not currentPlayer or not currentPlayer:IsInWorld() then
            return
        end
        
        -- Check if channel is still active
        if not currentPlayer:IsCasting() then
            currentPlayer:SendBroadcastMessage("Teleport cancelled.")
            currentPlayer:SetPower(startMana, 0)
            return
        end
        
        -- Check if player moved
        local currentX, currentY, currentZ = currentPlayer:GetLocation()
        local distance = math.sqrt((currentX - startX)^2 + (currentY - startY)^2 + (currentZ - startZ)^2)
        
        if distance > 1 then
            currentPlayer:SendBroadcastMessage("Teleport cancelled - you moved!")
            currentPlayer:InterruptSpell(0)
            currentPlayer:SetPower(startMana, 0)
            return
        end
        
        -- Complete teleport
        currentPlayer:InterruptSpell(0)
        currentPlayer:SetPower(startMana, 0)
        currentPlayer:Teleport(location.mapId, location.x, location.y, location.z, location.o)
        currentPlayer:SendBroadcastMessage("Arrived at " .. location.name)
        
        SetCooldown(playerGuid)
    end, CAST_TIME, 1)
    
    return true
end

-- =============================================
-- BEACON INTERFACE
-- =============================================

local function ShowBeaconMenu(player, beaconItemId, beaconData, locations)
    local playerGuid = player:GetGUIDLow()
    
    player:GossipClearMenu()
    
    -- If no locations, show first-time explanation
    if not locations or not next(locations) then
        player:GossipMenuAddItem(0, "◆ Welcome to Traveler's Beacon System", 0, 9998)
        player:GossipMenuAddItem(0, "Set your first location here", 0, 2000 + 0) -- slot 0
        player:GossipMenuAddItem(0, "Cancel", 0, 9999)
    else
        -- Show recall options for existing locations
        for slot = 0, beaconData.max_locations - 1 do
            if locations[slot] then
                player:GossipMenuAddItem(0, "◆ Recall to " .. locations[slot].name, 0, 1000 + slot)
            end
        end
        
        -- Show management options
        player:GossipMenuAddItem(0, "── Location Management ──", 0, 9998)
        
        -- Show available slots for new locations
        for slot = 0, beaconData.max_locations - 1 do
            if not locations[slot] then
                player:GossipMenuAddItem(0, "Set new location (Slot " .. (slot + 1) .. ")", 0, 2000 + slot)
            end
        end
        
        -- Show clear options for existing locations
        for slot = 0, beaconData.max_locations - 1 do
            if locations[slot] then
                player:GossipMenuAddItem(0, "Clear: " .. locations[slot].name, 0, 3000 + slot)
            end
        end
        
        player:GossipMenuAddItem(0, "Cancel", 0, 9999)
    end
end

-- =============================================
-- EVENT HANDLERS
-- =============================================

local function OnBeaconUse(event, player, item, target)
    local itemId = item:GetEntry()
    local playerGuid = player:GetGUIDLow()
    
    -- Get beacon configuration
    local beaconData = BEACON_ITEMS[itemId]
    if not beaconData then
        return false
    end
    
    print("DEBUG: Beacon used - " .. beaconData.name .. " by player " .. playerGuid)
    
    -- Check combat
    if player:IsInCombat() then
        player:SendBroadcastMessage("You cannot use a beacon while in combat.")
        return false
    end
    
    -- Check cooldown
    local isOnCooldown, remainingTime = IsOnCooldown(playerGuid)
    if isOnCooldown then
        local minutes = math.floor(remainingTime / 60)
        local seconds = remainingTime % 60
        player:SendBroadcastMessage(string.format("Your beacon is cooling down. (%d:%02d remaining)", minutes, seconds))
        return false
    end
    
    -- Check location restrictions
    local mapId = player:GetMapId()
    local isValid, errorMsg = IsValidTeleportLocation(player, mapId, 0, 0, 0)
    if not isValid then
        player:SendBroadcastMessage("You cannot use a beacon in this area.")
        return false
    end
    
    -- Get stored locations
    local locations = GetPlayerLocations(playerGuid, itemId)
    
    -- Show beacon interface
    ShowBeaconMenu(player, itemId, beaconData, locations)
    player:GossipSendMenu(1, item)
    
    return false
end

local function OnBeaconGossipSelect(event, player, item, sender, intid, code)
    local itemId = item:GetEntry()
    local playerGuid = player:GetGUIDLow()
    local beaconData = BEACON_ITEMS[itemId]
    
    if not beaconData then
        player:GossipComplete()
        return false
    end
    
    local locations = GetPlayerLocations(playerGuid, itemId)
    
    -- Handle different action types
    if intid >= 1000 and intid < 2000 then
        -- Recall to location
        local slot = intid - 1000
        local location = locations[slot]
        
        if not location then
            player:SendBroadcastMessage("Error: Location not found.")
            player:GossipComplete()
            return false
        end
        
        if not HasEnoughReagents(player, REAGENTS.TRAVELERS_MARK, 1) then
            player:SendBroadcastMessage("You need a Traveler's Mark to use the beacon.")
            player:GossipComplete()
            return false
        end
        
        ConsumeReagents(player, REAGENTS.TRAVELERS_MARK, 1)
        StartTeleportChannel(player, location, itemId)
        
    elseif intid >= 2000 and intid < 3000 then
        -- Set new location
        local slot = intid - 2000
        local mapId = player:GetMapId()
        local x, y, z = player:GetLocation()
        local o = player:GetO()
        
        local isValid, errorMsg = IsValidTeleportLocation(player, mapId, x, y, z)
        if not isValid then
            player:SendBroadcastMessage("Error: " .. errorMsg)
            player:GossipComplete()
            return false
        end
        
        local zoneName = GetZoneName(player)
        SaveLocation(playerGuid, itemId, slot, zoneName, mapId, x, y, z, o)
        
        player:SendBroadcastMessage("Location saved: " .. zoneName)
        
    elseif intid >= 3000 and intid < 4000 then
        -- Clear location
        local slot = intid - 3000
        local location = locations[slot]
        
        if location then
            DeleteLocation(playerGuid, itemId, slot)
            player:SendBroadcastMessage("Location cleared: " .. location.name)
        end
        
    elseif intid == 9998 then
        -- Info item, do nothing
        player:GossipComplete()
        return false
        
    elseif intid == 9999 then
        -- Cancel
        player:GossipComplete()
        return false
    end
    
    player:GossipComplete()
    return false
end

-- =============================================
-- EVENT REGISTRATION
-- =============================================

print("Registering beacon events...")

for itemId, _ in pairs(BEACON_ITEMS) do
    RegisterItemEvent(itemId, 2, OnBeaconUse)
    RegisterItemGossipEvent(itemId, 2, OnBeaconGossipSelect)
    print("  Registered events for item " .. itemId)
end

-- Cleanup on logout
local function OnPlayerLogout(event, player)
    local playerGuid = player:GetGUIDLow()
    playerLocationCache[playerGuid] = nil
    playerCooldowns[playerGuid] = nil
end

RegisterPlayerEvent(4, OnPlayerLogout)

-- Debug command
local function DebugBeacon(event, player, message, type, language)
    if message:lower() == ".testbeacon" then
        player:SendBroadcastMessage("DEBUG: Advanced Traveler's Beacon System v1 is active!")
        
        local beaconItemId, beaconData = GetPlayerBeacon(player)
        if beaconItemId then
            player:SendBroadcastMessage("DEBUG: You have " .. beaconData.name .. " (Tier " .. beaconData.tier .. ")")
        else
            player:SendBroadcastMessage("DEBUG: You don't have any beacon items")
        end
        return false
    end
    return true
end

RegisterPlayerEvent(18, DebugBeacon)

print("=== ADVANCED TRAVELER'S BEACON SYSTEM v1 LOADED ===")
print("Features:")
print("  - Tier 1: Traveler's Beacon (1 location)")
print("  - 15-minute cooldown system")
print("  - Traveler's Mark reagents")
print("  - Ready for tier expansion!") 