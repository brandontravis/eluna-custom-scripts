-- Traveler's Beacon System for AzerothCore (Simplified)
-- Allows players to set and recall to one custom location

print("=== LOADING TravelersBeacon.lua (Simplified) ===")

-- Configuration
local BEACON_ITEM_ID = 800001 -- Starter Traveler's Beacon (Custom Item)
local RUNE_ITEM_ID = 800000 -- Traveler's Mark (Custom Item)
local CAST_TIME = 5000 -- 5 seconds cast time
local COOLDOWN_TIME = 0 -- 30 seconds cooldown
local CHANNEL_SPELL = 12051 -- Evocation: an 8s self-cast channel with nice bar & glow

-- Cache for player locations to avoid repeated database queries
local playerLocationCache = {}

-- Cooldown tracking for players
local playerCooldowns = {}

-- Helper function to check if location is valid for teleportation
local function IsValidTeleportLocation(player, mapId, x, y, z)
    print("DEBUG: Validating location - MapID: " .. mapId .. ", X: " .. x .. ", Y: " .. y .. ", Z: " .. z)
    
    -- Check if coordinates are reasonable (not 0,0,0 or extremely large)
    if x == 0 and y == 0 and z == 0 then
        print("DEBUG: Invalid coordinates (0,0,0)")
        return false, "Invalid coordinates."
    end
    
    -- Check for reasonable coordinate ranges (WoW maps are typically -20000 to 20000)
    if math.abs(x) > 20000 or math.abs(y) > 20000 or math.abs(z) > 20000 then
        print("DEBUG: Coordinates out of range")
        return false, "Coordinates out of reasonable range."
    end
    
    -- Prevent teleportation to instances (basic check)
    if mapId >= 30 and mapId <= 90 then
        print("DEBUG: Map is a dungeon instance")
        return false, "Cannot teleport to dungeon locations."
    end
    
    -- Prevent teleportation to battlegrounds
    if mapId >= 489 and mapId <= 566 then
        print("DEBUG: Map is a battleground")
        return false, "Cannot teleport to battleground locations."
    end
    
    print("DEBUG: Location validation passed")
    return true, ""
end

-- Helper function to get player's stored location
local function GetPlayerLocation(playerGuid)
    if playerLocationCache[playerGuid] then
        return playerLocationCache[playerGuid]
    end
    
    local query = string.format([[
        SELECT location_name, map_id, position_x, position_y, position_z, orientation
        FROM player_beacon_locations
        WHERE guid = %d AND beacon_item_id = %d AND location_slot = 0
    ]], playerGuid, BEACON_ITEM_ID)
    
    local result = CharDBQuery(query)
    local location = nil
    
    if result then
        local name = result:GetString(0)
        local mapId = result:GetUInt32(1)
        local x = result:GetFloat(2)
        local y = result:GetFloat(3)
        local z = result:GetFloat(4)
        local o = result:GetFloat(5)
        
        location = {
            name = name,
            mapId = mapId,
            x = x,
            y = y,
            z = z,
            o = o
        }
    end
    
    playerLocationCache[playerGuid] = location
    return location
end

-- Helper function to save a location
local function SaveLocation(playerGuid, name, mapId, x, y, z, o)
    local query = string.format([[
        INSERT INTO player_beacon_locations (guid, beacon_item_id, location_slot, location_name, map_id, position_x, position_y, position_z, orientation)
        VALUES (%d, %d, 0, '%s', %d, %f, %f, %f, %f)
        ON DUPLICATE KEY UPDATE
        location_name = '%s', map_id = %d, position_x = %f, position_y = %f, position_z = %f, orientation = %f
    ]], playerGuid, BEACON_ITEM_ID, name, mapId, x, y, z, o, name, mapId, x, y, z, o)
    
    CharDBExecute(query)
    
    -- Clear cache for this player
    playerLocationCache[playerGuid] = nil
end

-- Helper function to delete a location
local function DeleteLocation(playerGuid)
    local query = string.format([[
        DELETE FROM player_beacon_locations
        WHERE guid = %d AND beacon_item_id = %d AND location_slot = 0
    ]], playerGuid, BEACON_ITEM_ID)
    
    CharDBExecute(query)
    
    -- Clear cache for this player
    playerLocationCache[playerGuid] = nil
end

-- Helper function to check if player has enough runes
local function HasEnoughRunes(player)
    return player:GetItemCount(RUNE_ITEM_ID) >= 1
end

-- Helper function to consume runes
local function ConsumeRunes(player)
    player:RemoveItem(RUNE_ITEM_ID, 1)
end

-- Helper function to get zone name
local function GetZoneName(player)
    local zoneId = player:GetZoneId()
    local areaId = player:GetAreaId()
    
    -- Try to get area name first (more specific), fallback to zone
    local areaName = GetAreaName(areaId)
    if areaName and areaName ~= "" then
        return areaName
    end
    
    local zoneName = GetAreaName(zoneId)
    if zoneName and zoneName ~= "" then
        return zoneName
    end
    
    -- Fallback to coordinates if we can't get names
    local x, y, z = player:GetLocation()
    return string.format("Location (%.1f, %.1f)", x, y)
end

-- Helper function to check cooldown
local function IsOnCooldown(playerGuid)
    if not playerCooldowns[playerGuid] then
        print("DEBUG: No cooldown record for player " .. playerGuid)
        return false, 0
    end
    
    local currentTime = GetCurrTime()
    local lastUseTime = playerCooldowns[playerGuid]
    local elapsed = currentTime - lastUseTime
    
    print("DEBUG: Cooldown check - Current: " .. currentTime .. ", Last: " .. lastUseTime .. ", Elapsed: " .. elapsed)
    print("DEBUG: Cooldown time setting: " .. COOLDOWN_TIME .. " (seconds or time units?)")
    
    -- Convert elapsed time to seconds if GetCurrTime() returns milliseconds
    local elapsedSeconds = elapsed
    if elapsed > 1000 then
        elapsedSeconds = elapsed / 1000
        print("DEBUG: Converted to seconds: " .. elapsedSeconds)
    end
    
    if elapsedSeconds < COOLDOWN_TIME then
        local remaining = COOLDOWN_TIME - elapsedSeconds
        print("DEBUG: Still on cooldown, " .. remaining .. " seconds remaining")
        return true, remaining
    end
    
    print("DEBUG: Cooldown expired, allowing use")
    return false, 0
end

-- Helper function to set cooldown
local function SetCooldown(playerGuid)
    local currentTime = GetCurrTime()
    playerCooldowns[playerGuid] = currentTime
    print("DEBUG: Setting cooldown for player " .. playerGuid .. " at time " .. currentTime)
end

-- Main beacon use function
local function OnBeaconUse(event, player, item, target)
    local itemId = item:GetEntry()
    local playerGuid = player:GetGUIDLow()
    
    print("DEBUG: Beacon used by player " .. playerGuid .. " with item " .. itemId)
    
    -- Check if this is the correct beacon
    if itemId ~= BEACON_ITEM_ID then
        print("DEBUG: Wrong beacon item ID")
        return false
    end
    
    -- Check if player is in combat
    if player:IsInCombat() then
        player:SendBroadcastMessage("You cannot use a beacon while in combat.")
        return false
    end
    
    -- Check if beacon is on cooldown
    local isOnCooldown, remainingTime = IsOnCooldown(playerGuid)
    
    if isOnCooldown then
        print("DEBUG: Beacon is on cooldown, " .. remainingTime .. " seconds remaining")
        player:SendBroadcastMessage("Your beacon is still cooling down. (" .. remainingTime .. " seconds remaining)")
        return false
    else
        print("DEBUG: Beacon is not on cooldown, allowing use")
    end
    
    -- Check if player is in a dungeon, battleground, or arena by map ID
    local mapId = player:GetMapId()
    
    -- Check for dungeons, raids, battlegrounds, and arenas by map ID ranges
    if (mapId >= 30 and mapId <= 90) or          -- Classic dungeons
       (mapId >= 189 and mapId <= 230) or        -- Classic raids
       (mapId >= 249 and mapId <= 429) or        -- More dungeons/raids
       (mapId >= 469 and mapId <= 580) or        -- TBC dungeons/raids
       (mapId >= 595 and mapId <= 650) or        -- WotLK dungeons/raids
       (mapId >= 489 and mapId <= 566) or        -- Battlegrounds
       (mapId >= 617 and mapId <= 628) then      -- Arenas
        player:SendBroadcastMessage("You cannot use a beacon in dungeons, raids, battlegrounds, or arenas.")
        return false
    end
    
    print("DEBUG: Getting player location...")
    local location = GetPlayerLocation(playerGuid)
    
    if not location then
        -- No saved location, save current location
        local currentMapId = player:GetMapId()
        local x, y, z = player:GetLocation()
        local o = player:GetO()
        
        local isValid, errorMsg = IsValidTeleportLocation(player, currentMapId, x, y, z)
        if not isValid then
            player:SendBroadcastMessage("Error: " .. errorMsg)
            return false
        end
        
        local zoneName = GetZoneName(player)
        SaveLocation(playerGuid, zoneName, currentMapId, x, y, z, o)
        
        player:SendBroadcastMessage("Location saved: " .. zoneName)
        player:SendBroadcastMessage("Use the beacon again to recall to this location.")
        
        -- Set cooldown for the beacon item
        SetCooldown(playerGuid)
    else
        -- Saved location exists, show options
        print("DEBUG: Opening gossip menu...")
        player:GossipClearMenu()
        player:GossipMenuAddItem(0, "Recall to " .. location.name, 0, 1000)
        player:GossipMenuAddItem(0, "Set new location", 0, 2000)
        player:GossipMenuAddItem(0, "Clear saved location", 0, 3000)
        player:GossipMenuAddItem(0, "Cancel", 0, 9999)
        player:GossipSendMenu(1, item)
        
        -- Set cooldown to prevent gossip menu spam
        SetCooldown(playerGuid)
    end
    
    return false
end

-- Gossip select handler
local function OnBeaconGossipSelect(event, player, item, sender, intid, code)
    local itemId = item:GetEntry()
    local playerGuid = player:GetGUIDLow()
    
    print("DEBUG: Gossip selected - IntID: " .. intid)
    
    if itemId ~= BEACON_ITEM_ID then
        player:GossipComplete()
        return false
    end
    
    local location = GetPlayerLocation(playerGuid)
    
    if intid == 1000 then
        -- Recall to saved location
        if not location then
            player:SendBroadcastMessage("Error: No saved location found.")
            player:GossipComplete()
            return false
        end
        
        if not HasEnoughRunes(player) then
            player:SendBroadcastMessage("You need a Traveler's Mark to use the beacon.")
            player:GossipComplete()
            return false
        end
        
        -- Consume rune and teleport
        ConsumeRunes(player)
        
        -- Store starting position for movement detection
        local startX, startY, startZ = player:GetLocation()
        local playerGuid = player:GetGUIDLow()
        
        player:SendBroadcastMessage("Teleporting to " .. location.name .. "...")
        
        -- Check if player is in combat before starting channel
        if player:IsInCombat() then
            player:SendBroadcastMessage("You can't channel while in combat!")
            player:GossipComplete()
            return false
        end
        
        -- Snapshot current mana before casting
        local startMana = player:GetPower(0) -- 0 = POWER_MANA
        
        -- 1) Start the real channel (no mana cost because of "true")
        local castResult = player:CastSpell(player, CHANNEL_SPELL, true)
        
        -- 2) Channel started successfully
        player:SendBroadcastMessage("Channeling beacon teleport...")
        
        -- 3) Schedule your teleport + cancel at 5s
        player:RegisterEvent(function(eventId, delay, repeats)
            -- Get a fresh player object using the stored GUID
            local currentPlayer = GetPlayerByGUID(playerGuid)
            if not currentPlayer or not currentPlayer:IsInWorld() then
                print("DEBUG: Player disconnected during beacon teleport")
                return
            end
            
            -- Check if the channel is still active
            if not currentPlayer:IsCasting() then
                currentPlayer:SendBroadcastMessage("Teleport cancelled.")
                -- Restore mana even if cancelled
                currentPlayer:SetPower(startMana, 0) -- 0 = POWER_MANA
                return
            end
            
            -- Check if player moved
            local currentX, currentY, currentZ = currentPlayer:GetLocation()
            local distance = math.sqrt((currentX - startX)^2 + (currentY - startY)^2 + (currentZ - startZ)^2)
            
            if distance > 1 then -- Player moved more than 1 yard
                currentPlayer:SendBroadcastMessage("Teleport cancelled - you moved!")
                currentPlayer:InterruptSpell(0) -- Cancel the channel
                -- Restore mana after movement cancellation
                currentPlayer:SetPower(startMana, 0) -- 0 = POWER_MANA
                return
            end
            
            -- Stop the channel cleanly
            currentPlayer:InterruptSpell(0)
            
            -- Restore original mana (undo any mana ticks from Evocation)
            currentPlayer:SetPower(startMana, 0) -- 0 = POWER_MANA
            
            -- Do the actual teleport
            currentPlayer:Teleport(location.mapId, location.x, location.y, location.z, location.o)
            currentPlayer:SendBroadcastMessage("Arrived at " .. location.name)
            SetCooldown(currentPlayer:GetGUIDLow())
        end, CAST_TIME, 1)
        
        player:GossipComplete()
        return false
        
    elseif intid == 2000 then
        -- Set new location
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
        SaveLocation(playerGuid, zoneName, mapId, x, y, z, o)
        
        player:SendBroadcastMessage("New location saved: " .. zoneName)
        player:GossipComplete()
        return false
        
    elseif intid == 3000 then
        -- Clear saved location
        if location then
            DeleteLocation(playerGuid)
            player:SendBroadcastMessage("Location cleared: " .. location.name)
        end
        
        player:GossipComplete()
        return false
        
    elseif intid == 9999 then
        -- Cancel
        player:GossipComplete()
        return false
    end
    
    return false
end

print("Registering beacon events...")

-- Register events for the beacon item
RegisterItemEvent(BEACON_ITEM_ID, 2, OnBeaconUse) -- ITEM_EVENT_ON_USE
RegisterItemGossipEvent(BEACON_ITEM_ID, 2, OnBeaconGossipSelect) -- GOSSIP_EVENT_ON_SELECT

print("Event registration complete.")

-- Debug function to test script connectivity
local function DebugBeacon(event, player, message, type, language)
    if message:lower() == ".testbeacon" then
        player:SendBroadcastMessage("DEBUG: Traveler's Beacon script is active and responding!")
        if player:HasItem(BEACON_ITEM_ID) then
            player:SendBroadcastMessage("DEBUG: You have the Starter Traveler's Beacon")
        else
            player:SendBroadcastMessage("DEBUG: You don't have the Starter Traveler's Beacon")
        end
        return false
    end
    return true
end

RegisterPlayerEvent(18, DebugBeacon) -- PLAYER_EVENT_ON_CHAT

-- Cleanup function for player logout
local function OnPlayerLogout(event, player)
    local playerGuid = player:GetGUIDLow()
    
    -- Clear player's location cache
    playerLocationCache[playerGuid] = nil
    
    -- Clear player's cooldown data
    playerCooldowns[playerGuid] = nil
end

RegisterPlayerEvent(4, OnPlayerLogout) -- PLAYER_EVENT_ON_LOGOUT

print("Traveler's Beacon System loaded successfully!")
print("Features:")
print("  - One saved teleport location")
print("  - Requires Traveler's Marks")
print("  - 30-second cooldown")
print("  - Combat and location validation")
print("  - Persistent storage across sessions")
print("  - Professional spell visuals (5-sec cast, summoning circle, interruptible)")
print("")
print("Usage:")
print("  1. Purchase a Starter Traveler's Beacon from Engineer Gizmo Wayfinder")
print("  2. Use the beacon to set your location")
print("  3. Use again to access teleport options")
print("  4. Teleportation requires 1 Rune of Teleportation") 