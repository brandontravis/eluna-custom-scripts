-- Traveler's Beacon System for AzerothCore (Advanced - v1 Foundation)
-- Starting with working simple system, will add tier progression

print("=== LOADING ADVANCED TRAVELER'S BEACON SYSTEM v1 ===")

-- =============================================
-- CONFIGURATION
-- =============================================

-- Beacon configuration (Tiers 1-2)
local BEACON_ITEMS = {
    [800001] = {tier = 1, name = "Traveler's Beacon", max_locations = 1},
    [800002] = {tier = 2, name = "Dual Anchor Beacon", max_locations = 2},
    [800003] = {tier = 3, name = "Travel Network Beacon", max_locations = 5},
    [800004] = {tier = 4, name = "Master's Travel Beacon", max_locations = 10}
}

-- Reagent items
local REAGENTS = {
    TRAVELERS_MARK = 800000, -- 25s each, stackable to 200
    PORTAL_MARK = 800010     -- Future portal reagent
}

-- System settings
local CAST_TIME = 5000      -- 5 seconds cast time
local COOLDOWN_TIME = 0   -- 15 minutes cooldown (900 seconds)
-- local COOLDOWN_TIME = 900   -- 15 minutes cooldown (900 seconds)
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

-- Check if map allows beacon usage
local function IsValidBeaconMap(mapId)
    print("DEBUG: Validating map for beacon usage - MapID: " .. mapId)
    
    -- Prevent beacon usage in instances/dungeons/raids/battlegrounds/arenas
    if (mapId >= 30 and mapId <= 90) or          -- Classic dungeons
       (mapId >= 189 and mapId <= 230) or        -- Classic raids
       (mapId >= 249 and mapId <= 429) or        -- More dungeons/raids
       (mapId >= 469 and mapId <= 580) or        -- TBC dungeons/raids
       (mapId >= 595 and mapId <= 650) or        -- WotLK dungeons/raids
       (mapId >= 489 and mapId <= 566) or        -- Battlegrounds
       (mapId >= 617 and mapId <= 628) then      -- Arenas
        return false, "Cannot use beacon in instances, dungeons, raids, battlegrounds, or arenas."
    end
    
    return true, ""
end

-- Check if location is valid for teleportation (for setting/teleporting to locations)
local function IsValidTeleportLocation(player, mapId, x, y, z)
    print("DEBUG: Validating teleport location - MapID: " .. mapId .. ", X: " .. x .. ", Y: " .. y .. ", Z: " .. z)
    
    if x == 0 and y == 0 and z == 0 then
        return false, "Invalid coordinates."
    end
    
    if math.abs(x) > 20000 or math.abs(y) > 20000 or math.abs(z) > 20000 then
        return false, "Coordinates out of reasonable range."
    end
    
    -- Use the map validation function
    return IsValidBeaconMap(mapId)
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
    
    print("DEBUG CLEAR: Executing DELETE query: " .. query)
    CharDBExecute(query)
    print("DEBUG CLEAR: DeleteLocation clearing cache for player " .. playerGuid)
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
        print("DEBUG: Teleport completion callback triggered for player " .. playerGuid)
        
        local currentPlayer = GetPlayerByGUID(playerGuid)
        if not currentPlayer then
            print("DEBUG: GetPlayerByGUID returned nil for " .. playerGuid)
            return
        end
        
        if not currentPlayer:IsInWorld() then
            print("DEBUG: Player " .. playerGuid .. " is not in world")
            return
        end
        
        print("DEBUG: Player found and in world, checking casting status")
        
        -- Check if channel is still active
        if not currentPlayer:IsCasting() then
            print("DEBUG: Player is not casting, teleport was cancelled")
            currentPlayer:SendBroadcastMessage("Teleport cancelled.")
            currentPlayer:SetPower(startMana, 0)
            return
        end
        
        -- Check if player moved
        local currentX, currentY, currentZ = currentPlayer:GetLocation()
        local distance = math.sqrt((currentX - startX)^2 + (currentY - startY)^2 + (currentZ - startZ)^2)
        
        print("DEBUG: Movement check - Distance: " .. distance)
        
        if distance > 1 then
            print("DEBUG: Player moved too far, cancelling teleport")
            currentPlayer:SendBroadcastMessage("Teleport cancelled - you moved!")
            currentPlayer:InterruptSpell(0)
            currentPlayer:SetPower(startMana, 0)
            return
        end
        
        -- Complete teleport
        print("DEBUG: Attempting teleport to " .. location.mapId .. ", " .. location.x .. ", " .. location.y .. ", " .. location.z)
        currentPlayer:InterruptSpell(0)
        currentPlayer:SetPower(startMana, 0)
        
        local teleportSuccess = currentPlayer:Teleport(location.mapId, location.x, location.y, location.z, location.o)
        print("DEBUG: Teleport call returned: " .. tostring(teleportSuccess))
        
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
    
    -- If no locations, show simple setup
    if not locations or not next(locations) then
        player:GossipMenuAddItem(0, "Set your first location here", 0, 2000 + 0) -- slot 0
        player:GossipMenuAddItem(0, "Cancel", 0, 9999)
    else
        -- Show recall options for existing locations
        for slot = 0, beaconData.max_locations - 1 do
            if locations[slot] then
                player:GossipMenuAddItem(0, "Recall to " .. locations[slot].name, 0, 1000 + slot)
            end
        end
        
        -- Show available slots for new locations
        for slot = 0, beaconData.max_locations - 1 do
            if not locations[slot] then
                player:GossipMenuAddItem(0, "Set new location (Slot " .. (slot + 1) .. ")", 0, 2000 + slot)
            end
        end
        
        -- Show management menu option only if we have existing locations
        if next(locations) then
            player:GossipMenuAddItem(0, "Location Management", 0, 4000)
        end
        
        player:GossipMenuAddItem(0, "Cancel", 0, 9999)
    end
end

local function ShowManagementMenu(player, beaconItemId, beaconData, locations)
    player:GossipClearMenu()
    
    -- Check if there are any locations to manage
    local hasLocations = false
    for slot = 0, beaconData.max_locations - 1 do
        if locations[slot] then
            hasLocations = true
            break
        end
    end
    
    if hasLocations then
        -- Show clear options for existing locations
        for slot = 0, beaconData.max_locations - 1 do
            if locations[slot] then
                player:GossipMenuAddItem(0, "Clear: " .. locations[slot].name, 0, 3000 + slot)
            end
        end
        
        player:GossipMenuAddItem(0, "Back to main menu", 0, 5000)
        player:GossipMenuAddItem(0, "Cancel", 0, 9999)
    else
        -- No locations to manage, return to main menu
        player:SendBroadcastMessage("No locations to manage.")
        ShowBeaconMenu(player, beaconItemId, beaconData, locations)
    end
end

-- =============================================
-- BEACON UPGRADE SYSTEM
-- =============================================

local UPGRADE_NPC_ID = 800001

-- Capacity upgrade costs (beacon tier upgrades)
local UPGRADE_COSTS = {
    [800002] = {gold = 1000, level = 20, name = "Dual Anchor Beacon"},    -- Tier 1 -> Tier 2
    [800003] = {gold = 2500, level = 40, name = "Travel Network Beacon"}, -- Tier 2 -> Tier 3
    [800004] = {gold = 5000, level = 60, name = "Master's Travel Beacon"} -- Tier 3 -> Tier 4
}

-- Functionality upgrade costs (independent of beacon tier)
local FUNCTIONALITY_COSTS = {
    capital_networks = {gold = 500, level = 25, name = "Capital Networks", description = "Instant access to all major cities"},
    portal_casting = {gold = 750, level = 30, name = "Portal Casting", description = "Create portals for other players"},
    dungeon_access = {gold = 300, level = 15, name = "Dungeon Access", description = "Teleport to discovered dungeon entrances"},
    raid_access = {gold = 1000, level = 60, name = "Raid Access", description = "Teleport to discovered raid entrances"},
    world_events = {gold = 400, level = 35, name = "World Events", description = "Access to seasonal event locations"}
}

-- Get next tier beacon for current beacon
local function GetNextTierBeacon(currentBeaconId)
    local currentTier = BEACON_ITEMS[currentBeaconId] and BEACON_ITEMS[currentBeaconId].tier or 0
    
    for itemId, beaconData in pairs(BEACON_ITEMS) do
        if beaconData.tier == currentTier + 1 then
            return itemId, beaconData
        end
    end
    return nil, nil
end

-- Transfer all locations from old beacon to new beacon
local function TransferBeaconLocations(playerGuid, oldBeaconId, newBeaconId)
    local query = string.format([[
        UPDATE player_beacon_locations 
        SET beacon_item_id = %d 
        WHERE guid = %d AND beacon_item_id = %d
    ]], newBeaconId, playerGuid, oldBeaconId)
    
    CharDBExecute(query)
    print("DEBUG UPGRADE: Transferred locations from beacon " .. oldBeaconId .. " to " .. newBeaconId .. " for player " .. playerGuid)
end

-- Perform the beacon upgrade
local function UpgradeBeacon(player, oldBeaconId, newBeaconId, cost)
    local playerGuid = player:GetGUIDLow()
    
    -- Remove old beacon
    player:RemoveItem(oldBeaconId, 1)
    
    -- Add new beacon
    player:AddItem(newBeaconId, 1)
    
    -- Transfer locations
    TransferBeaconLocations(playerGuid, oldBeaconId, newBeaconId)
    
    -- Clear cache to ensure fresh data
    playerLocationCache[playerGuid] = nil
    
    -- Charge gold
    player:ModifyMoney(-cost.gold * 10000) -- Convert gold to copper
    
    print("DEBUG UPGRADE: Upgraded beacon " .. oldBeaconId .. " to " .. newBeaconId .. " for player " .. playerGuid)
end

-- Upgrade NPC gossip handler
local function OnUpgradeNPCGossip(event, player, object)
    print("DEBUG UPGRADE GOSSIP: OnUpgradeNPCGossip called")
    if object:GetEntry() ~= UPGRADE_NPC_ID then
        return false
    end

    print("DEBUG UPGRADE GOSSIP: Showing main upgrade menu")
    player:GossipClearMenu()
    
    -- Just show the main menu - let submenus handle the specific logic
    player:GossipMenuAddItem(0, "Upgrade Beacon Capacity", 0, 2000)
    player:GossipMenuAddItem(0, "Add Functionality Upgrades", 0, 3000)
    player:GossipMenuAddItem(0, "Close", 0, 9999)
    player:GossipSendMenu(800010, object)
    return
end

-- Show capacity upgrade submenu
local function ShowCapacityUpgradeMenu(player, object)
    print("DEBUG CAPACITY MENU: ShowCapacityUpgradeMenu called")
    print("DEBUG CAPACITY MENU: Call stack trace:")
    print(debug.traceback())
    local currentBeaconId, currentBeaconData = GetPlayerBeacon(player)
    print("DEBUG CAPACITY MENU: Current beacon ID: " .. tostring(currentBeaconId))
    player:GossipClearMenu()
    
    if not currentBeaconId then
        player:GossipMenuAddItem(0, "You don't have a beacon", 0, 9999)
        player:GossipMenuAddItem(0, "Back to main menu", 0, 4000)
        player:GossipSendMenu(800001, object)
        return
    end
    
    local nextBeaconId, nextBeaconData = GetNextTierBeacon(currentBeaconId)
    
    if not nextBeaconId then
        player:GossipMenuAddItem(0, "Back to main menu", 0, 4000)
        player:GossipSendMenu(800002, object)
        return
    end
    
    local upgradeCost = UPGRADE_COSTS[nextBeaconId]
    if not upgradeCost then
        player:GossipMenuAddItem(0, "Back to main menu", 0, 4000)
        player:GossipSendMenu(800003, object)
        return
    end
    
    -- Check requirements
    local playerLevel = player:GetLevel()
    local playerGold = player:GetCoinage()
    local requiredGold = upgradeCost.gold * 10000
    
    local canUpgrade = true
    local reasons = {}
    
    if playerLevel < upgradeCost.level then
        canUpgrade = false
        table.insert(reasons, "Requires level " .. upgradeCost.level)
    end
    
    if playerGold < requiredGold then
        canUpgrade = false
        table.insert(reasons, "Requires " .. upgradeCost.gold .. " gold")
    end
    
    -- Determine appropriate text ID and menu
    local textId
    if canUpgrade then
        if currentBeaconData.tier == 1 then
            textId = 800004  -- Tier 1 to 2
        elseif currentBeaconData.tier == 2 then
            textId = 800005  -- Tier 2 to 3
        elseif currentBeaconData.tier == 3 then
            textId = 800006  -- Tier 3 to 4
        else
            textId = 800010  -- Fallback
        end
        
        local menuText = string.format("Yes, upgrade to %s (%d gold)", upgradeCost.name, upgradeCost.gold)
        local upgradeIntId = 6000 + currentBeaconData.tier  -- Use 6001, 6002, 6003 for upgrades
        print("DEBUG CAPACITY MENU: About to add menu item:")
        print("  Text: " .. menuText)
        print("  IntId: " .. upgradeIntId) 
        print("  Tier: " .. currentBeaconData.tier)
        player:GossipMenuAddItem(0, menuText, 0, upgradeIntId)
        print("DEBUG CAPACITY MENU: Menu item added successfully")
    else
        local needsLevel = playerLevel < upgradeCost.level
        local needsGold = playerGold < requiredGold
        
        if needsLevel and needsGold then
            textId = 800009
        elseif needsLevel then
            textId = 800007
        elseif needsGold then
            textId = 800008
        else
            textId = 800010
        end
    end
    
    print("DEBUG CAPACITY MENU: Adding 'Back to main menu' with intid 4000")
    player:GossipMenuAddItem(0, "Back to main menu", 0, 4000)
    print("DEBUG CAPACITY MENU: Sending menu with textId " .. textId)
    player:GossipSendMenu(textId, object)
end

-- Show functionality upgrade submenu
local function ShowFunctionalityUpgradeMenu(player, object)
    print("DEBUG FUNCTIONALITY MENU: ShowFunctionalityUpgradeMenu called")
    player:GossipClearMenu()
    
    -- For now, just show placeholder options
    player:GossipMenuAddItem(0, "Capital Networks (25g, Level 25)", 0, 5001)
    player:GossipMenuAddItem(0, "Portal Casting (75g, Level 30)", 0, 5002)
    player:GossipMenuAddItem(0, "Dungeon Access (30g, Level 15)", 0, 5003)
    player:GossipMenuAddItem(0, "Raid Access (100g, Level 60)", 0, 5004)
    player:GossipMenuAddItem(0, "World Events (40g, Level 35)", 0, 5005)
    
    print("DEBUG FUNCTIONALITY MENU: Adding 'Back to main menu' with intid 4000")
    player:GossipMenuAddItem(0, "Back to main menu", 0, 4000)
    print("DEBUG FUNCTIONALITY MENU: Sending menu with textId 800011")
    player:GossipSendMenu(800011, object)
end

-- Upgrade NPC gossip select handler
local function OnUpgradeNPCGossipSelect(event, player, object, sender, intid, code)
    print("DEBUG UPGRADE SELECT: Player " .. player:GetGUIDLow() .. " selected option " .. intid)
    print("DEBUG UPGRADE SELECT: intid type: " .. type(intid))
    print("DEBUG UPGRADE SELECT: intid value: " .. tostring(intid))
    
    if intid == 2000 then
        -- Show capacity upgrade submenu
        print("DEBUG UPGRADE SELECT: Showing capacity upgrade menu (intid 2000)")
        ShowCapacityUpgradeMenu(player, object)
        return true
    elseif intid == 3000 then
        -- Show functionality upgrade submenu  
        ShowFunctionalityUpgradeMenu(player, object)
        return true
    elseif intid == 4000 then
        -- Back to main menu - restart the gossip
        OnUpgradeNPCGossip(event, player, object)
        return true
    elseif intid >= 5001 and intid <= 5005 then
        -- Functionality upgrade selections
        local upgradeNames = {
            [5001] = "Capital Networks",
            [5002] = "Portal Casting", 
            [5003] = "Dungeon Access",
            [5004] = "Raid Access",
            [5005] = "World Events"
        }
        
        local upgradeName = upgradeNames[intid]
        print("DEBUG UPGRADE SELECT: Player selected functionality upgrade: " .. upgradeName)
        player:SendBroadcastMessage("You selected " .. upgradeName .. " - functionality not implemented yet!")
        
    elseif intid >= 6001 and intid <= 6003 then
        print("DEBUG UPGRADE SELECT: Matched capacity upgrade range 6001-6003")
        local currentBeaconId, currentBeaconData = GetPlayerBeacon(player)
        print("DEBUG UPGRADE SELECT: Current beacon ID: " .. tostring(currentBeaconId))
        
        if not currentBeaconId then
            print("DEBUG UPGRADE SELECT: Player has no beacon")
            player:SendBroadcastMessage("You need a beacon to upgrade!")
            player:GossipComplete()
            return false
        end
        
        local newBeaconId, newBeaconData = GetNextTierBeacon(currentBeaconId)
        print("DEBUG UPGRADE SELECT: Upgrade to beacon ID " .. tostring(newBeaconId))
        
        if not newBeaconId then
            print("DEBUG UPGRADE SELECT: No next tier beacon found")
            player:SendBroadcastMessage("Upgrade not available.")
            player:GossipComplete()
            return false
        end
        
        local upgradeCost = UPGRADE_COSTS[newBeaconId]
        print("DEBUG UPGRADE SELECT: Upgrade cost data: " .. tostring(upgradeCost))
        if not upgradeCost then
            print("DEBUG UPGRADE SELECT: No upgrade cost found for beacon " .. newBeaconId)
            player:SendBroadcastMessage("Upgrade not available.")
            player:GossipComplete()
            return false
        end
        
        -- Double-check requirements
        local playerLevel = player:GetLevel()
        local playerGold = player:GetCoinage()
        local requiredGold = upgradeCost.gold * 10000
        
        print("DEBUG UPGRADE SELECT: Player level: " .. playerLevel .. ", required: " .. upgradeCost.level)
        print("DEBUG UPGRADE SELECT: Player gold: " .. playerGold .. ", required: " .. requiredGold)
        
        if playerLevel < upgradeCost.level then
            print("DEBUG UPGRADE SELECT: Player level too low")
            player:SendBroadcastMessage("You need to be level " .. upgradeCost.level .. " to upgrade.")
            player:GossipComplete()
            return false
        end
        
        if playerGold < requiredGold then
            print("DEBUG UPGRADE SELECT: Player doesn't have enough gold")
            player:SendBroadcastMessage("You need " .. upgradeCost.gold .. " gold to upgrade.")
            player:GossipComplete()
            return false
        end
        
        -- Perform upgrade
        print("DEBUG UPGRADE SELECT: Performing upgrade from " .. currentBeaconId .. " to " .. newBeaconId)
        UpgradeBeacon(player, currentBeaconId, newBeaconId, upgradeCost)
        player:SendBroadcastMessage("Beacon upgraded to " .. newBeaconData.name .. "!")
        player:SendBroadcastMessage("All your saved locations have been transferred.")

        player:GossipComplete()
        return false
        
    elseif intid == 9999 then
        print("DEBUG UPGRADE SELECT: Player selected Close")
        player:GossipComplete()
        return false
    else
        print("DEBUG UPGRADE SELECT: Unknown option selected: " .. intid)
        print("DEBUG UPGRADE SELECT: No matching condition found - this should not happen")
    end
    
    print("DEBUG UPGRADE SELECT: Completing gossip and returning false")
    
    return false
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
    local isValid, errorMsg = IsValidBeaconMap(mapId)
    if not isValid then
        player:SendBroadcastMessage(errorMsg)
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
        
        -- Add a small delay to ensure database transaction completes
        player:RegisterEvent(function()
            -- Get fresh player object to avoid stale reference
            local currentPlayer = GetPlayerByGUID(playerGuid)
            if not currentPlayer then
                print("DEBUG: Player object became invalid during delay")
                return
            end
            
            -- Close gossip menu since item object becomes stale
            currentPlayer:GossipComplete()
            currentPlayer:SendBroadcastMessage("Location saved successfully. Use beacon again to continue.")
        end, 100, 1) -- 100ms delay
        
        return false
        
    elseif intid >= 3000 and intid < 4000 then
        -- Clear location (from management submenu)
        local slot = intid - 3000
        local location = locations[slot]
        
        if location then
            print("DEBUG CLEAR: Clearing location slot " .. slot .. " (" .. location.name .. ") for player " .. playerGuid)
            DeleteLocation(playerGuid, itemId, slot)
            player:SendBroadcastMessage("Location cleared: " .. location.name)
            
            -- Force clear the cache to ensure fresh data
            print("DEBUG CLEAR: Force clearing cache after DeleteLocation")
            playerLocationCache[playerGuid] = nil
            
            -- Add a small delay to ensure database transaction completes
            player:RegisterEvent(function()
                -- Get fresh player object to avoid stale reference
                local currentPlayer = GetPlayerByGUID(playerGuid)
                if not currentPlayer then
                    print("DEBUG CLEAR: Player object became invalid during delay")
                    return
                end
                
                -- Refresh the management menu to show the change
                print("DEBUG CLEAR: Checking database after 100ms delay...")
                local updatedLocations = GetPlayerLocations(playerGuid, itemId)
                print("DEBUG CLEAR: After clearing, updatedLocations has " .. (next(updatedLocations) and "data" or "no data"))
                
                -- If data still exists, show what's still there
                if next(updatedLocations) then
                    for s, loc in pairs(updatedLocations) do
                        print("DEBUG CLEAR: Still found in slot " .. s .. ": " .. loc.name)
                    end
                end
                
                -- Close gossip menu since item object becomes stale
                currentPlayer:GossipComplete()
                currentPlayer:SendBroadcastMessage("Location cleared successfully. Use beacon again to continue.")
            end, 100, 1) -- 100ms delay
            
            return false
        else
            print("DEBUG CLEAR: No location found in slot " .. slot)
        end
        
    elseif intid == 4000 then
        -- Open location management submenu
        ShowManagementMenu(player, itemId, beaconData, locations)
        player:GossipSendMenu(1, item)
        return false
        
    elseif intid == 5000 then
        -- Back to main menu
        local updatedLocations = GetPlayerLocations(playerGuid, itemId)
        ShowBeaconMenu(player, itemId, beaconData, updatedLocations)
        player:GossipSendMenu(1, item)
        return false
        
    elseif intid == 9998 then
        -- Separator item, do nothing
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

-- Register upgrade NPC events
print("Registering upgrade NPC events for NPC " .. UPGRADE_NPC_ID)
RegisterCreatureGossipEvent(UPGRADE_NPC_ID, 1, OnUpgradeNPCGossip)
RegisterCreatureGossipEvent(UPGRADE_NPC_ID, 2, OnUpgradeNPCGossipSelect)
print("  Registered upgrade gossip events for NPC " .. UPGRADE_NPC_ID)

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

print("=== ADVANCED TRAVELER'S BEACON SYSTEM v2.0 LOADED ===")
print("Features:")
print("  - Tier 1: Traveler's Beacon (1 location)")
print("  - Tier 2: Dual Anchor Beacon (2 locations, Level 20)")
print("  - Tier 3: Travel Network Beacon (5 locations, Level 40)")
print("  - Tier 4: Master's Travel Beacon (10 locations, Level 60)")
print("  - Beacon upgrade system via NPC " .. UPGRADE_NPC_ID .. " (Beacon Artificer)")
print("  - 15-minute cooldown system")
print("  - Traveler's Mark reagents")
print("  - Location transfer between beacon tiers!") 