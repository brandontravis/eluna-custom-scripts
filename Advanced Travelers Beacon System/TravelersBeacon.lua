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
-- FUNCTIONALITY UPGRADE DATABASE FUNCTIONS
-- =============================================

-- Get player's functionality upgrades from database
local function GetPlayerFunctionalityUpgrades(playerGuid)
    local query = string.format([[
        SELECT has_capital_upgrade, has_portal_upgrade, has_dungeon_upgrade, has_raid_upgrade, has_events_upgrade
        FROM player_beacon_progress
        WHERE guid = %d
    ]], playerGuid)
    
    local result = CharDBQuery(query)
    if result then
        return {
            capital_networks = result:GetBool(0),
            portal_casting = result:GetBool(1),
            dungeon_access = result:GetBool(2),
            raid_access = result:GetBool(3),
            world_events = result:GetBool(4)
        }
    end
    
    -- Initialize new player record
    local initQuery = string.format([[
        INSERT INTO player_beacon_progress (guid, beacon_tier, has_capital_upgrade, has_portal_upgrade, has_dungeon_upgrade, has_raid_upgrade, has_events_upgrade)
        VALUES (%d, 1, FALSE, FALSE, FALSE, FALSE, FALSE)
    ]], playerGuid)
    CharDBExecute(initQuery)
    
    return {
        capital_networks = false,
        portal_casting = false,
        dungeon_access = false,
        raid_access = false,
        world_events = false
    }
end

-- Purchase functionality upgrade for player
local function PurchaseFunctionalityUpgrade(playerGuid, upgradeType)
    local columnName = "has_" .. upgradeType:gsub("_", "_") .. "_upgrade"
    if upgradeType == "capital_networks" then
        columnName = "has_capital_upgrade"
    elseif upgradeType == "portal_casting" then
        columnName = "has_portal_upgrade"
    elseif upgradeType == "dungeon_access" then
        columnName = "has_dungeon_upgrade"
    elseif upgradeType == "raid_access" then
        columnName = "has_raid_upgrade"
    elseif upgradeType == "world_events" then
        columnName = "has_events_upgrade"
    end
    
    local query = string.format([[
        INSERT INTO player_beacon_progress (guid, beacon_tier, %s)
        VALUES (%d, 1, TRUE)
        ON DUPLICATE KEY UPDATE %s = TRUE
    ]], columnName, playerGuid, columnName)
    
    CharDBExecute(query)

end

-- =============================================
-- DUNGEON DISCOVERY SYSTEM
-- =============================================

-- Comprehensive dungeon/raid definitions with entrance coordinates
local DUNGEON_DATA = {
    -- ===== CLASSIC DUNGEONS =====
    -- Eastern Kingdoms
    [36] = {name = "The Deadmines", expansion = "classic", level = 18, entrance = {mapId = 0, x = -11209.6, y = 1666.54, z = 24.6974, o = 1.42}},
    [33] = {name = "Shadowfang Keep", expansion = "classic", level = 25, entrance = {mapId = 0, x = -234.675, y = 1561.63, z = 76.8921, o = 1.24}},
    [34] = {name = "The Stockade", expansion = "classic", level = 24, entrance = {mapId = 0, x = -8769.85, y = 845.499, z = 87.9952, o = 5.00}},
    [90] = {name = "Gnomeregan", expansion = "classic", level = 32, entrance = {mapId = 0, x = -5163.54, y = 925.423, z = 257.181, o = 1.57}},
    [70] = {name = "Uldaman", expansion = "classic", level = 44, entrance = {mapId = 0, x = -6071.37, y = -2955.16, z = 209.782, o = 0.015}},
    [109] = {name = "The Sunken Temple", expansion = "classic", level = 50, entrance = {mapId = 0, x = -10177.9, y = -3994.9, z = -111.239, o = 6.01}},
    [329] = {name = "Stratholme", expansion = "classic", level = 58, entrance = {mapId = 0, x = 3352.92, y = -3379.03, z = 144.782, o = 6.25}},
    [229] = {name = "Blackrock Spire", expansion = "classic", level = 55, entrance = {mapId = 0, x = -7527.05, y = -1226.77, z = 285.732, o = 2.32}},
    [230] = {name = "Blackrock Depths", expansion = "classic", level = 52, entrance = {mapId = 0, x = -7179.34, y = -921.212, z = 165.821, o = 5.09}},
    [189] = {name = "Scarlet Monastery", expansion = "classic", level = 35, entrance = {mapId = 0, x = 2873.15, y = -764.523, z = 160.332, o = 5.10}},
    
    -- Kalimdor
    [43] = {name = "Wailing Caverns", expansion = "classic", level = 20, entrance = {mapId = 1, x = -731.607, y = -2218.39, z = 17.0281, o = 2.78}},
    [47] = {name = "Razorfen Kraul", expansion = "classic", level = 32, entrance = {mapId = 1, x = -4470.28, y = -1677.77, z = 81.3925, o = 1.16}},
    [129] = {name = "Razorfen Downs", expansion = "classic", level = 40, entrance = {mapId = 1, x = -4657.3, y = -2519.35, z = 81.0529, o = 4.54}},
    [349] = {name = "Maraudon", expansion = "classic", level = 48, entrance = {mapId = 1, x = -1421.42, y = 2907.83, z = 137.415, o = 1.70}},
    [209] = {name = "Zul'Farrak", expansion = "classic", level = 46, entrance = {mapId = 1, x = -6801.19, y = -2893.02, z = 9.00388, o = 0.158}},
    [389] = {name = "Ragefire Chasm", expansion = "classic", level = 16, entrance = {mapId = 1, x = 1811.78, y = -4410.5, z = -18.4704, o = 5.20}},
    [48] = {name = "Blackfathom Deeps", expansion = "classic", level = 24, entrance = {mapId = 1, x = 4249.99, y = 740.102, z = -25.671, o = 1.34}},
    [7] = {name = "Dire Maul", expansion = "classic", level = 55, entrance = {mapId = 1, x = -3520.14, y = 1119.38, z = 161.025, o = 4.70}},
    

    
    -- ===== TBC DUNGEONS =====
    -- Hellfire Peninsula
    [543] = {name = "Hellfire Ramparts", expansion = "tbc", level = 60, entrance = {mapId = 530, x = -360.671, y = 3071.9, z = -15.0977, o = 1.31}},
    [542] = {name = "The Blood Furnace", expansion = "tbc", level = 61, entrance = {mapId = 530, x = -303.506, y = 3164.75, z = 31.1923, o = 2.19}},
    [540] = {name = "The Shattered Halls", expansion = "tbc", level = 70, entrance = {mapId = 530, x = -311.083, y = 3083.73, z = -3.73574, o = 4.66}},
    
    -- Zangarmarsh
    [546] = {name = "The Underbog", expansion = "tbc", level = 63, entrance = {mapId = 530, x = 777.89, y = 6763.450, z = -72.1884, o = 5.02}},
    [545] = {name = "The Slave Pens", expansion = "tbc", level = 62, entrance = {mapId = 530, x = 777.89, y = 6763.450, z = -72.1884, o = 5.02}},
    [547] = {name = "The Steamvault", expansion = "tbc", level = 70, entrance = {mapId = 530, x = 777.89, y = 6763.450, z = -72.1884, o = 5.02}},
    
    -- Terokkar Forest
    [556] = {name = "Sethekk Halls", expansion = "tbc", level = 67, entrance = {mapId = 530, x = -3362.219, y = 4826.09, z = -101.047, o = 4.25}},
    [558] = {name = "Auchenai Crypts", expansion = "tbc", level = 65, entrance = {mapId = 530, x = -3362.219, y = 4826.09, z = -101.047, o = 4.25}},
    [557] = {name = "Mana-Tombs", expansion = "tbc", level = 64, entrance = {mapId = 530, x = -3362.219, y = 4826.09, z = -101.047, o = 4.25}},
    [555] = {name = "Shadow Labyrinth", expansion = "tbc", level = 70, entrance = {mapId = 530, x = -3362.219, y = 4826.09, z = -101.047, o = 4.25}},
    
    -- Netherstorm
    [552] = {name = "The Arcatraz", expansion = "tbc", level = 70, entrance = {mapId = 530, x = 3312.19, y = 1334.49, z = 505.559, o = 5.19}},
    [553] = {name = "The Botanica", expansion = "tbc", level = 70, entrance = {mapId = 530, x = 3407.61, y = 1485.44, z = 182.838, o = 5.96}},
    [554] = {name = "The Mechanar", expansion = "tbc", level = 69, entrance = {mapId = 530, x = 2867.19, y = 1546.49, z = 252.159, o = 3.74}},
    
    -- Caverns of Time
    [560] = {name = "Old Hillsbrad Foothills", expansion = "tbc", level = 66, entrance = {mapId = 1, x = -8173.66, y = -4746.36, z = 33.8423, o = 4.93}},
    [269] = {name = "The Black Morass", expansion = "tbc", level = 70, entrance = {mapId = 1, x = -8173.66, y = -4746.36, z = 33.8423, o = 4.93}},
    
    -- Isle of Quel'Danas
    [585] = {name = "Magisters' Terrace", expansion = "tbc", level = 70, entrance = {mapId = 530, x = 12884.6, y = -7317.69, z = 65.5023, o = 4.799}},
    

    
    -- ===== WOTLK DUNGEONS =====
    -- Borean Tundra
    [576] = {name = "The Nexus", expansion = "wotlk", level = 71, entrance = {mapId = 571, x = 3781.81, y = 6965.22, z = 104.72, o = 0.435}},
    [578] = {name = "The Oculus", expansion = "wotlk", level = 80, entrance = {mapId = 571, x = 3781.81, y = 6965.22, z = 104.72, o = 0.435}},
    
    -- Dragonblight
    [574] = {name = "Utgarde Keep", expansion = "wotlk", level = 70, entrance = {mapId = 571, x = 1219.720, y = -4865.28, z = 41.2466, o = 0.31}},
    [575] = {name = "Utgarde Pinnacle", expansion = "wotlk", level = 80, entrance = {mapId = 571, x = 1219.720, y = -4865.28, z = 41.2466, o = 0.31}},
    [599] = {name = "Halls of Stone", expansion = "wotlk", level = 77, entrance = {mapId = 571, x = 8922.12, y = -985.905, z = 1039.56, o = 1.57}},
    [600] = {name = "Halls of Lightning", expansion = "wotlk", level = 80, entrance = {mapId = 571, x = 9136.52, y = -1311.81, z = 1066.29, o = 5.19}},
    
    -- Zul'Drak
    [604] = {name = "Gundrak", expansion = "wotlk", level = 76, entrance = {mapId = 571, x = 6722.44, y = -4640.67, z = 450.632, o = 3.91}},
    [608] = {name = "Drak'Tharon Keep", expansion = "wotlk", level = 74, entrance = {mapId = 571, x = 4765.59, y = -2038.24, z = 229.363, o = 0.887}},
    
    -- Icecrown
    [619] = {name = "Ahn'kahet: The Old Kingdom", expansion = "wotlk", level = 73, entrance = {mapId = 571, x = 3707.86, y = 2150.23, z = 36.76, o = 3.22}},
    [601] = {name = "Azjol-Nerub", expansion = "wotlk", level = 72, entrance = {mapId = 571, x = 3707.86, y = 2150.23, z = 36.76, o = 3.22}},
    [658] = {name = "The Pit of Saron", expansion = "wotlk", level = 80, entrance = {mapId = 571, x = 5643.16, y = 2028.81, z = 798.274, o = 4.60}},
    [632] = {name = "The Forge of Souls", expansion = "wotlk", level = 80, entrance = {mapId = 571, x = 5643.16, y = 2028.81, z = 798.274, o = 4.60}},
    [668] = {name = "Halls of Reflection", expansion = "wotlk", level = 80, entrance = {mapId = 571, x = 5643.16, y = 2028.81, z = 798.274, o = 4.60}},
    
    -- Crystalsong Forest  
    [595] = {name = "The Culling of Stratholme", expansion = "wotlk", level = 80, entrance = {mapId = 1, x = -8173.66, y = -4746.36, z = 33.8423, o = 4.93}},
    
    -- Trial of the Champion
    [650] = {name = "Trial of the Champion", expansion = "wotlk", level = 80, entrance = {mapId = 571, x = 8590.95, y = 791.792, z = 558.235, o = 3.13}},
    

}

-- Comprehensive raid definitions with entrance coordinates
local RAID_DATA = {
    -- ===== CLASSIC RAIDS =====
    [249] = {name = "Onyxia's Lair", expansion = "classic", level = 60, entrance = {mapId = 1, x = -4708.27, y = -3727.64, z = 54.5589, o = 3.72}},
    [309] = {name = "Zul'Gurub", expansion = "classic", level = 60, entrance = {mapId = 0, x = -11916.7, y = -1215.72, z = 92.289, o = 4.72}},
    [409] = {name = "Molten Core", expansion = "classic", level = 60, entrance = {mapId = 0, x = -7527.05, y = -1226.77, z = 285.732, o = 2.32}},
    [469] = {name = "Blackwing Lair", expansion = "classic", level = 60, entrance = {mapId = 0, x = -7527.05, y = -1226.77, z = 285.732, o = 2.32}},
    [533] = {name = "Naxxramas (WotLK)", expansion = "wotlk", level = 80, entrance = {mapId = 571, x = 3668.72, y = -1262.46, z = 243.622, o = 4.785}},
    
    -- ===== TBC RAIDS =====
    [532] = {name = "Karazhan", expansion = "tbc", level = 70, entrance = {mapId = 0, x = -11118.9, y = -2010.33, z = 47.0819, o = 0.649}},
    [565] = {name = "Gruul's Lair", expansion = "tbc", level = 70, entrance = {mapId = 530, x = 3530.06, y = 5104.08, z = 3.50861, o = 5.51}},
    [550] = {name = "Serpentshrine Cavern", expansion = "tbc", level = 70, entrance = {mapId = 530, x = 777.89, y = 6763.450, z = -72.1884, o = 5.02}},
    [548] = {name = "The Eye", expansion = "tbc", level = 70, entrance = {mapId = 530, x = 3087.22, y = 1373.79, z = 184.643, o = 4.79}},
    [534] = {name = "Mount Hyjal", expansion = "tbc", level = 70, entrance = {mapId = 1, x = -8173.66, y = -4746.36, z = 33.8423, o = 4.93}},
    [564] = {name = "Black Temple", expansion = "tbc", level = 70, entrance = {mapId = 530, x = -3649.92, y = 317.469, z = 35.2827, o = 2.94}},
    [580] = {name = "Sunwell Plateau", expansion = "tbc", level = 70, entrance = {mapId = 530, x = 12884.6, y = -7317.69, z = 65.5023, o = 4.799}},
    
    -- ===== WOTLK RAIDS =====
    [615] = {name = "The Obsidian Sanctum", expansion = "wotlk", level = 80, entrance = {mapId = 571, x = 3472.43, y = 264.923, z = -120.146, o = 3.27}},
    [616] = {name = "The Eye of Eternity", expansion = "wotlk", level = 80, entrance = {mapId = 571, x = 3781.81, y = 6965.22, z = 104.72, o = 0.435}},
    [603] = {name = "Ulduar", expansion = "wotlk", level = 80, entrance = {mapId = 571, x = 9222.88, y = -1113.59, z = 1216.12, o = 6.27}},
    [649] = {name = "Trial of the Crusader", expansion = "wotlk", level = 80, entrance = {mapId = 571, x = 8590.95, y = 791.792, z = 558.235, o = 3.13}},
    [631] = {name = "Icecrown Citadel", expansion = "wotlk", level = 80, entrance = {mapId = 571, x = 5855.22, y = 2102.03, z = 635.991, o = 3.57}},
    [724] = {name = "The Ruby Sanctum", expansion = "wotlk", level = 80, entrance = {mapId = 571, x = 3472.43, y = 264.923, z = -120.146, o = 3.27}},
}

-- Generate suggested level range for a dungeon
local function GetDungeonLevelRange(recommendedLevel)
    local rangeSize
    
    -- Different range sizes based on level brackets
    if recommendedLevel <= 20 then
        rangeSize = 5
    elseif recommendedLevel <= 40 then
        rangeSize = 7
    elseif recommendedLevel <= 60 then
        rangeSize = 8
    else
        rangeSize = 5  -- TBC/WotLK dungeons
    end
    
    local minLevel = math.max(1, recommendedLevel - rangeSize)  -- Never go below level 1
    local maxLevel = recommendedLevel + rangeSize
    
    print("DEBUG DUNGEON LEVEL: Recommended " .. recommendedLevel .. " -> Range [" .. minLevel .. "-" .. maxLevel .. "]")
    return minLevel, maxLevel
end

-- Check if a map ID is a dungeon
local function IsDungeonMap(mapId)
    local isDungeon = DUNGEON_DATA[mapId] ~= nil
    print("DEBUG DUNGEON: IsDungeonMap(" .. mapId .. ") = " .. tostring(isDungeon))
    if isDungeon then
        print("DEBUG DUNGEON: Found dungeon data: " .. DUNGEON_DATA[mapId].name)
    end
    return isDungeon
end

-- Check if a map ID is a raid
local function IsRaidMap(mapId)
    local isRaid = RAID_DATA[mapId] ~= nil
    print("DEBUG RAID: IsRaidMap(" .. mapId .. ") = " .. tostring(isRaid))
    if isRaid then
        print("DEBUG RAID: Found raid data: " .. RAID_DATA[mapId].name)
    end
    return isRaid
end

-- Save discovered dungeon to database
local function SaveDiscoveredDungeon(playerGuid, mapId)
    print("DEBUG DUNGEON: SaveDiscoveredDungeon called - Player: " .. playerGuid .. ", Map: " .. mapId)
    
    local dungeonInfo = DUNGEON_DATA[mapId]
    if not dungeonInfo then
        print("DEBUG DUNGEON: No dungeon data found for map " .. mapId)
        return false
    end
    
    print("DEBUG DUNGEON: Dungeon info found: " .. dungeonInfo.name .. " (" .. dungeonInfo.expansion .. ")")
    
    -- Check if already discovered
    local checkQuery = string.format([[
        SELECT guid FROM player_instance_discovery 
        WHERE guid = %d AND map_id = %d
    ]], playerGuid, mapId)
    
    print("DEBUG DUNGEON: Checking if already discovered with query: " .. checkQuery)
    
    local result = CharDBQuery(checkQuery)
    if result then
        print("DEBUG DUNGEON: Already discovered - not saving again")
        return false
    end
    
    -- Save new discovery
    local insertQuery = string.format([[
        INSERT INTO player_instance_discovery (guid, map_id, instance_name, instance_type, recommended_level, expansion, first_entered)
        VALUES (%d, %d, '%s', 'dungeon', %d, '%s', NOW())
    ]], playerGuid, mapId, dungeonInfo.name, dungeonInfo.level, dungeonInfo.expansion)
    
    print("DEBUG DUNGEON: Saving new discovery with query: " .. insertQuery)
    CharDBExecute(insertQuery)
    print("DEBUG DUNGEON: Successfully saved " .. dungeonInfo.name .. " for player " .. playerGuid)
    
    return true
end

-- Get player's discovered dungeons
local function GetDiscoveredDungeons(playerGuid)
    print("DEBUG DUNGEON: GetDiscoveredDungeons called for player " .. playerGuid)
    
    local query = string.format([[
        SELECT map_id, instance_name, recommended_level, expansion
        FROM player_instance_discovery
        WHERE guid = %d AND instance_type = 'dungeon'
        ORDER BY expansion, recommended_level
    ]], playerGuid)
    
    print("DEBUG DUNGEON: Query: " .. query)
    
    local result = CharDBQuery(query)
    local discoveries = {}
    
    if result then
        print("DEBUG DUNGEON: Database query returned results")
        repeat
            local mapId = result:GetUInt32(0)
            local name = result:GetString(1)
            local level = result:GetUInt32(2)
            local expansion = result:GetString(3)
            
            print("DEBUG DUNGEON: Found discovery - Map: " .. mapId .. ", Name: " .. name .. ", Level: " .. level .. ", Expansion: " .. expansion)
            
            table.insert(discoveries, {
                mapId = mapId,
                name = name,
                level = level,
                expansion = expansion,
                entrance = DUNGEON_DATA[mapId] and DUNGEON_DATA[mapId].entrance or nil
            })
        until not result:NextRow()
    else
        print("DEBUG DUNGEON: Database query returned no results")
    end
    
    print("DEBUG DUNGEON: Returning " .. #discoveries .. " discovered dungeons")
    return discoveries
end

-- Save discovered raid to database
local function SaveDiscoveredRaid(playerGuid, mapId)
    print("DEBUG RAID: SaveDiscoveredRaid called - Player: " .. playerGuid .. ", Map: " .. mapId)
    
    local raidInfo = RAID_DATA[mapId]
    if not raidInfo then
        print("DEBUG RAID: No raid data found for map " .. mapId)
        return false
    end
    
    print("DEBUG RAID: Raid info found: " .. raidInfo.name .. " (" .. raidInfo.expansion .. ")")
    
    -- Check if already discovered
    local checkQuery = string.format([[
        SELECT guid FROM player_instance_discovery 
        WHERE guid = %d AND map_id = %d
    ]], playerGuid, mapId)
    
    print("DEBUG RAID: Checking if already discovered with query: " .. checkQuery)
    
    local result = CharDBQuery(checkQuery)
    if result then
        print("DEBUG RAID: Already discovered - not saving again")
        return false
    end
    
    -- Save new discovery
    local insertQuery = string.format([[
        INSERT INTO player_instance_discovery (guid, map_id, instance_name, instance_type, recommended_level, expansion, first_entered)
        VALUES (%d, %d, '%s', 'raid', %d, '%s', NOW())
    ]], playerGuid, mapId, raidInfo.name, raidInfo.level, raidInfo.expansion)
    
    print("DEBUG RAID: Saving new discovery with query: " .. insertQuery)
    CharDBExecute(insertQuery)
    print("DEBUG RAID: Successfully saved " .. raidInfo.name .. " for player " .. playerGuid)
    
    return true
end

-- Get player's discovered raids
local function GetDiscoveredRaids(playerGuid)
    print("DEBUG RAID: GetDiscoveredRaids called for player " .. playerGuid)
    
    local query = string.format([[
        SELECT map_id, instance_name, recommended_level, expansion
        FROM player_instance_discovery
        WHERE guid = %d AND instance_type = 'raid'
        ORDER BY expansion, recommended_level
    ]], playerGuid)
    
    print("DEBUG RAID: Query: " .. query)
    
    local result = CharDBQuery(query)
    local discoveries = {}
    
    if result then
        print("DEBUG RAID: Database query returned results")
        repeat
            local mapId = result:GetUInt32(0)
            local name = result:GetString(1)
            local level = result:GetUInt32(2)
            local expansion = result:GetString(3)
            
            print("DEBUG RAID: Found discovery - Map: " .. mapId .. ", Name: " .. name .. ", Level: " .. level .. ", Expansion: " .. expansion)
            
            table.insert(discoveries, {
                mapId = mapId,
                name = name,
                level = level,
                expansion = expansion,
                entrance = RAID_DATA[mapId] and RAID_DATA[mapId].entrance or nil
            })
        until not result:NextRow()
    else
        print("DEBUG RAID: Database query returned no results")
    end
    
    print("DEBUG RAID: Returning " .. #discoveries .. " discovered raids")
    return discoveries
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
        if not currentPlayer then
            return
        end
        
        if not currentPlayer:IsInWorld() then
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
        
        local teleportSuccess = currentPlayer:Teleport(location.mapId, location.x, location.y, location.z, location.o)
        
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
    
    -- Check if player has functionality upgrades
    local playerUpgrades = GetPlayerFunctionalityUpgrades(playerGuid)
    local hasCapitalNetworks = playerUpgrades.capital_networks
    local hasDungeonAccess = playerUpgrades.dungeon_access
    local hasRaidAccess = playerUpgrades.raid_access
    
    print("DEBUG BEACON MENU: Player " .. playerGuid .. " upgrade check - Capital: " .. tostring(hasCapitalNetworks) .. ", Dungeon: " .. tostring(hasDungeonAccess) .. ", Raid: " .. tostring(hasRaidAccess))
    
    -- If no locations, show simple setup
    if not locations or not next(locations) then
        player:GossipMenuAddItem(0, "Set your first location here", 0, 2000 + 0) -- slot 0
        
        -- Add capital networks option if player has it
        if hasCapitalNetworks then
            player:GossipMenuAddItem(0, "Capital Cities", 0, 8000)
        end
        
        -- Add dungeon access option if player has it
        if hasDungeonAccess then
            print("DEBUG BEACON MENU: Adding Dungeon Access option (empty beacon)")
            player:GossipMenuAddItem(0, "Dungeon Access", 0, 8200)
        else
            print("DEBUG BEACON MENU: Not adding Dungeon Access option - player doesn't have upgrade")
        end
        
        -- Add raid access option if player has it
        if hasRaidAccess then
            print("DEBUG BEACON MENU: Adding Raid Access option (empty beacon)")
            player:GossipMenuAddItem(0, "Raid Access", 0, 8300)
        else
            print("DEBUG BEACON MENU: Not adding Raid Access option - player doesn't have upgrade")
        end
        
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
        
        -- Add capital networks option if player has it
        if hasCapitalNetworks then
            player:GossipMenuAddItem(0, "Capital Cities", 0, 8000)
        end
        
        -- Add dungeon access option if player has it
        if hasDungeonAccess then
            print("DEBUG BEACON MENU: Adding Dungeon Access option (populated beacon)")
            player:GossipMenuAddItem(0, "Dungeon Access", 0, 8200)
        else
            print("DEBUG BEACON MENU: Not adding Dungeon Access option - player doesn't have upgrade")
        end
        
        -- Add raid access option if player has it
        if hasRaidAccess then
            print("DEBUG BEACON MENU: Adding Raid Access option (populated beacon)")
            player:GossipMenuAddItem(0, "Raid Access", 0, 8300)
        else
            print("DEBUG BEACON MENU: Not adding Raid Access option - player doesn't have upgrade")
        end
        
        -- Show management menu option only if we have existing locations
        if next(locations) then
            player:GossipMenuAddItem(0, "Location Management", 0, 4000)
        end
        
        player:GossipMenuAddItem(0, "Cancel", 0, 9999)
    end
end

-- Capital city definitions for Capital Networks upgrade
local CAPITAL_CITIES = {
    -- Alliance Cities
    {name = "Stormwind City", faction = "Alliance", mapId = 0, x = -8842.09, y = 626.358, z = 94.0066, o = 3.61},
    {name = "Ironforge", faction = "Alliance", mapId = 0, x = -4981.25, y = -881.542, z = 502.66, o = 5.40},
    {name = "Darnassus", faction = "Alliance", mapId = 1, x = 9947.52, y = 2482.73, z = 1316.21, o = 1.54},
    {name = "The Exodar", faction = "Alliance", mapId = 530, x = -3864.92, y = -11643.7, z = -137.644, o = 5.50},
    
    -- Horde Cities  
    {name = "Orgrimmar", faction = "Horde", mapId = 1, x = 1676.21, y = -4315.29, z = 61.5164, o = 1.35},
    {name = "Thunder Bluff", faction = "Horde", mapId = 1, x = -1274.45, y = 71.8601, z = 128.159, o = 2.80},
    {name = "Undercity", faction = "Horde", mapId = 0, x = 1633.75, y = 240.167, z = -43.1034, o = 6.26},
    {name = "Silvermoon City", faction = "Horde", mapId = 530, x = 9738.28, y = -7454.19, z = 13.5605, o = 0.043},
    
    -- Neutral Cities
    {name = "Shattrath City", faction = "Neutral", mapId = 530, x = -1887.62, y = 5359.09, z = -12.4279, o = 4.40},
    {name = "Dalaran", faction = "Neutral", mapId = 571, x = 5809.55, y = 503.975, z = 657.526, o = 2.05}
}

-- Show capital cities menu for Capital Networks upgrade
local function ShowCapitalCitiesMenu(player, beaconItemId, beaconData)
    local playerGuid = player:GetGUIDLow()
    
    player:GossipClearMenu()
    
    -- Check if player has capital networks upgrade
    local playerUpgrades = GetPlayerFunctionalityUpgrades(playerGuid)
    if not playerUpgrades.capital_networks then
        player:SendBroadcastMessage("You need the Capital Networks upgrade to use this feature.")
        player:GossipComplete()
        return
    end
    
    -- Get player's faction for filtering
    local playerFaction = player:GetTeam() -- 0 = Alliance, 1 = Horde
    
    -- Add capital city options
    for i, city in ipairs(CAPITAL_CITIES) do
        -- Show all cities for now - cross-faction access as designed
        local menuText = city.name
        if city.faction == "Neutral" then
            menuText = city.name .. " (Neutral)"
        elseif city.faction == "Alliance" then
            menuText = city.name .. " (Alliance)"
        elseif city.faction == "Horde" then
            menuText = city.name .. " (Horde)"
        end
        
        player:GossipMenuAddItem(0, menuText, 0, 8100 + i) -- 8101-8110 for capital cities
    end
    
    player:GossipMenuAddItem(0, "Back to main menu", 0, 8999)
    player:GossipMenuAddItem(0, "Cancel", 0, 9999)
end

-- Show dungeon access menu with discovered dungeons
local function ShowDungeonAccessMenu(player, beaconItemId, beaconData)
    print("DEBUG DUNGEON MENU: ShowDungeonAccessMenu called")
    player:GossipClearMenu()
    
    local playerGuid = player:GetGUIDLow()
    print("DEBUG DUNGEON MENU: Getting discovered dungeons for player " .. playerGuid)
    local discoveredDungeons = GetDiscoveredDungeons(playerGuid)
    
    if not discoveredDungeons or #discoveredDungeons == 0 then
        print("DEBUG DUNGEON MENU: No dungeons discovered - showing empty menu")
        player:GossipMenuAddItem(0, "No dungeons discovered yet", 0, 9998)
        player:GossipMenuAddItem(0, "Back to main menu", 0, 8999)
        player:GossipMenuAddItem(0, "Cancel", 0, 9999)
        return
    end
    
    print("DEBUG DUNGEON MENU: Found " .. #discoveredDungeons .. " discovered dungeons")
    
    -- Sort dungeons by expansion and level
    table.sort(discoveredDungeons, function(a, b)
        local dungeonA = DUNGEON_DATA[a.mapId]
        local dungeonB = DUNGEON_DATA[b.mapId]
        
        if dungeonA.expansion ~= dungeonB.expansion then
            local expansionOrder = {classic = 1, tbc = 2, wotlk = 3}
            return expansionOrder[dungeonA.expansion] < expansionOrder[dungeonB.expansion]
        end
        
        return dungeonA.level < dungeonB.level
    end)
    
    print("DEBUG DUNGEON MENU: Dungeons sorted, building menu items")
    
    -- Add discovered dungeons to menu
    for i, discoveredDungeon in ipairs(discoveredDungeons) do
        local dungeonInfo = DUNGEON_DATA[discoveredDungeon.mapId]
        if dungeonInfo then
            local minLevel, maxLevel = GetDungeonLevelRange(dungeonInfo.level)
            local menuText = string.format("%s (%s) [%d-%d]", dungeonInfo.name, dungeonInfo.expansion:upper(), minLevel, maxLevel)
            local intentId = 8200 + i
            print("DEBUG DUNGEON MENU: Adding menu item #" .. i .. " - " .. menuText .. " (intent " .. intentId .. ")")
            player:GossipMenuAddItem(0, menuText, 0, intentId) -- 8201-8250 for dungeons
        else
            print("DEBUG DUNGEON MENU: ERROR - No dungeon info found for map " .. discoveredDungeon.mapId)
        end
    end
    
    player:GossipMenuAddItem(0, "Back to main menu", 0, 8999)
    player:GossipMenuAddItem(0, "Cancel", 0, 9999)
    print("DEBUG DUNGEON MENU: Menu built successfully")
end

-- Show raid access menu with discovered raids
local function ShowRaidAccessMenu(player, beaconItemId, beaconData)
    print("DEBUG RAID MENU: ShowRaidAccessMenu called")
    player:GossipClearMenu()
    
    local playerGuid = player:GetGUIDLow()
    print("DEBUG RAID MENU: Getting discovered raids for player " .. playerGuid)
    local discoveredRaids = GetDiscoveredRaids(playerGuid)
    
    if not discoveredRaids or #discoveredRaids == 0 then
        print("DEBUG RAID MENU: No raids discovered - showing empty menu")
        player:GossipMenuAddItem(0, "No raids discovered yet", 0, 9998)
        player:GossipMenuAddItem(0, "Back to main menu", 0, 8999)
        player:GossipMenuAddItem(0, "Cancel", 0, 9999)
        return
    end
    
    print("DEBUG RAID MENU: Found " .. #discoveredRaids .. " discovered raids")
    
    -- Sort raids by expansion and level
    table.sort(discoveredRaids, function(a, b)
        local raidA = RAID_DATA[a.mapId]
        local raidB = RAID_DATA[b.mapId]
        
        if raidA.expansion ~= raidB.expansion then
            local expansionOrder = {classic = 1, tbc = 2, wotlk = 3}
            return expansionOrder[raidA.expansion] < expansionOrder[raidB.expansion]
        end
        
        return raidA.level < raidB.level
    end)
    
    print("DEBUG RAID MENU: Raids sorted, building menu items")
    
    -- Add discovered raids to menu
    for i, discoveredRaid in ipairs(discoveredRaids) do
        local raidInfo = RAID_DATA[discoveredRaid.mapId]
        if raidInfo then
            local minLevel, maxLevel = GetDungeonLevelRange(raidInfo.level)
            local menuText = string.format("%s (%s) [%d-%d]", raidInfo.name, raidInfo.expansion:upper(), minLevel, maxLevel)
            local intentId = 8300 + i
            print("DEBUG RAID MENU: Adding menu item #" .. i .. " - " .. menuText .. " (intent " .. intentId .. ")")
            player:GossipMenuAddItem(0, menuText, 0, intentId) -- 8301-8350 for raids
        else
            print("DEBUG RAID MENU: ERROR - No raid info found for map " .. discoveredRaid.mapId)
        end
    end
    
    player:GossipMenuAddItem(0, "Back to main menu", 0, 8999)
    player:GossipMenuAddItem(0, "Cancel", 0, 9999)
    print("DEBUG RAID MENU: Menu built successfully")
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
    

end

-- Upgrade NPC gossip handler
local function OnUpgradeNPCGossip(event, player, object)
    if object:GetEntry() ~= UPGRADE_NPC_ID then
        return false
    end

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
    local currentBeaconId, currentBeaconData = GetPlayerBeacon(player)
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

        -- print("  Text: " .. menuText)
        -- print("  IntId: " .. upgradeIntId) 
        -- print("  Tier: " .. currentBeaconData.tier)
        player:GossipMenuAddItem(0, menuText, 0, upgradeIntId)
        -- print("DEBUG CAPACITY MENU: Menu item added successfully")
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
    
    -- print("DEBUG CAPACITY MENU: Adding 'Back to main menu' with intid 4000")
    player:GossipMenuAddItem(0, "Back to main menu", 0, 4000)
    -- print("DEBUG CAPACITY MENU: Sending menu with textId " .. textId)
    player:GossipSendMenu(textId, object)
end

-- Show functionality upgrade submenu
local function ShowFunctionalityUpgradeMenu(player, object)
    -- print("DEBUG FUNCTIONALITY MENU: ShowFunctionalityUpgradeMenu called")
    player:GossipClearMenu()
    
    local playerGuid = player:GetGUIDLow()
    local playerLevel = player:GetLevel()
    local playerGold = player:GetCoinage()
    
    -- Get player's current functionality upgrades
    local upgrades = GetPlayerFunctionalityUpgrades(playerGuid)
    
    -- Create menu items for each upgrade type
    local upgradeOrder = {"capital_networks", "portal_casting", "dungeon_access", "raid_access", "world_events"}
    local intIdStart = 5001
    
    for i, upgradeType in ipairs(upgradeOrder) do
        local cost = FUNCTIONALITY_COSTS[upgradeType]
        local intId = intIdStart + i - 1
        
        if upgrades[upgradeType] then
            -- Player already has this upgrade
            player:GossipMenuAddItem(0, cost.name .. " - [OWNED]", 0, 9999)
        else
            -- Check if player meets requirements
            local canPurchase = true
            local reasons = {}
            
            if playerLevel < cost.level then
                canPurchase = false
                table.insert(reasons, "Level " .. cost.level .. " required")
            end
            
            if playerGold < cost.gold * 10000 then
                canPurchase = false
                table.insert(reasons, cost.gold .. "g required")
            end
            
            if canPurchase then
                local menuText = string.format("%s (%dg, Level %d)", cost.name, cost.gold, cost.level)
                player:GossipMenuAddItem(0, menuText, 0, intId)
            else
                local reasonText = table.concat(reasons, ", ")
                local menuText = string.format("%s - [%s]", cost.name, reasonText)
                player:GossipMenuAddItem(0, menuText, 0, 9999)
            end
        end
    end
    
    -- print("DEBUG FUNCTIONALITY MENU: Adding 'Back to main menu' with intid 4000")
    player:GossipMenuAddItem(0, "Back to main menu", 0, 4000)
    -- print("DEBUG FUNCTIONALITY MENU: Sending menu with textId 800011")
    player:GossipSendMenu(800011, object)
end

-- Upgrade NPC gossip select handler
local function OnUpgradeNPCGossipSelect(event, player, object, sender, intid, code)
    -- print("DEBUG UPGRADE SELECT: Player " .. player:GetGUIDLow() .. " selected option " .. intid)
    -- print("DEBUG UPGRADE SELECT: intid type: " .. type(intid))
    -- print("DEBUG UPGRADE SELECT: intid value: " .. tostring(intid))
    
    if intid == 2000 then
        -- Show capacity upgrade submenu
        -- print("DEBUG UPGRADE SELECT: Showing capacity upgrade menu (intid 2000)")
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
        local upgradeMap = {
            [5001] = "capital_networks",
            [5002] = "portal_casting", 
            [5003] = "dungeon_access",
            [5004] = "raid_access",
            [5005] = "world_events"
        }
        
        local upgradeType = upgradeMap[intid]
        local upgradeCost = FUNCTIONALITY_COSTS[upgradeType]
        local playerGuid = player:GetGUIDLow()
        
        -- print("DEBUG FUNCTIONALITY PURCHASE: Player selected: " .. upgradeType)
        
        -- Check if player already has this upgrade
        local currentUpgrades = GetPlayerFunctionalityUpgrades(playerGuid)
        if currentUpgrades[upgradeType] then
            player:SendBroadcastMessage("You already have this upgrade!")
            player:GossipComplete()
            return false
        end
        
        -- Double-check requirements
        local playerLevel = player:GetLevel()
        local playerGold = player:GetCoinage()
        local requiredGold = upgradeCost.gold * 10000
        
        if playerLevel < upgradeCost.level then
            player:SendBroadcastMessage("You need to be level " .. upgradeCost.level .. " for this upgrade.")
            player:GossipComplete()
            return false
        end
        
        if playerGold < requiredGold then
            player:SendBroadcastMessage("You need " .. upgradeCost.gold .. " gold for this upgrade.")
            player:GossipComplete()
            return false
        end
        
        -- Perform purchase
        player:ModifyMoney(-requiredGold)
        PurchaseFunctionalityUpgrade(playerGuid, upgradeType)
        player:SendBroadcastMessage("Successfully purchased " .. upgradeCost.name .. "!")
        player:SendBroadcastMessage("This upgrade is now available on all your beacons.")
        
        player:GossipComplete()
        return false
        
    elseif intid >= 6001 and intid <= 6003 then
        -- print("DEBUG UPGRADE SELECT: Matched capacity upgrade range 6001-6003")
        local currentBeaconId, currentBeaconData = GetPlayerBeacon(player)
        -- print("DEBUG UPGRADE SELECT: Current beacon ID: " .. tostring(currentBeaconId))
        
        if not currentBeaconId then
            -- print("DEBUG UPGRADE SELECT: Player has no beacon")
            player:SendBroadcastMessage("You need a beacon to upgrade!")
            player:GossipComplete()
            return false
        end
        
        local newBeaconId, newBeaconData = GetNextTierBeacon(currentBeaconId)
        -- print("DEBUG UPGRADE SELECT: Upgrade to beacon ID " .. tostring(newBeaconId))
        
        if not newBeaconId then
            -- print("DEBUG UPGRADE SELECT: No next tier beacon found")
            player:SendBroadcastMessage("Upgrade not available.")
            player:GossipComplete()
            return false
        end
        
        local upgradeCost = UPGRADE_COSTS[newBeaconId]
        -- print("DEBUG UPGRADE SELECT: Upgrade cost data: " .. tostring(upgradeCost))
        if not upgradeCost then
            -- print("DEBUG UPGRADE SELECT: No upgrade cost found for beacon " .. newBeaconId)
            player:SendBroadcastMessage("Upgrade not available.")
            player:GossipComplete()
            return false
        end
        
        -- Double-check requirements
        local playerLevel = player:GetLevel()
        local playerGold = player:GetCoinage()
        local requiredGold = upgradeCost.gold * 10000
        
        -- print("DEBUG UPGRADE SELECT: Player level: " .. playerLevel .. ", required: " .. upgradeCost.level)
        -- print("DEBUG UPGRADE SELECT: Player gold: " .. playerGold .. ", required: " .. requiredGold)
        
        if playerLevel < upgradeCost.level then
            -- print("DEBUG UPGRADE SELECT: Player level too low")
            player:SendBroadcastMessage("You need to be level " .. upgradeCost.level .. " to upgrade.")
            player:GossipComplete()
            return false
        end
        
        if playerGold < requiredGold then
            -- print("DEBUG UPGRADE SELECT: Player doesn't have enough gold")
            player:SendBroadcastMessage("You need " .. upgradeCost.gold .. " gold to upgrade.")
            player:GossipComplete()
            return false
        end
        
        -- Perform upgrade
        -- print("DEBUG UPGRADE SELECT: Performing upgrade from " .. currentBeaconId .. " to " .. newBeaconId)
        UpgradeBeacon(player, currentBeaconId, newBeaconId, upgradeCost)
        player:SendBroadcastMessage("Beacon upgraded to " .. newBeaconData.name .. "!")
        player:SendBroadcastMessage("All your saved locations have been transferred.")

        player:GossipComplete()
        return false
        
    elseif intid == 9999 then
        -- print("DEBUG UPGRADE SELECT: Player selected Close")
        player:GossipComplete()
        return false
    else
        -- print("DEBUG UPGRADE SELECT: Unknown option selected: " .. intid)
        -- print("DEBUG UPGRADE SELECT: No matching condition found - this should not happen")
    end
    
    -- print("DEBUG UPGRADE SELECT: Completing gossip and returning false")
    
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
                -- print("DEBUG: Player object became invalid during delay")
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
            -- print("DEBUG CLEAR: Clearing location slot " .. slot .. " (" .. location.name .. ") for player " .. playerGuid)
            DeleteLocation(playerGuid, itemId, slot)
            player:SendBroadcastMessage("Location cleared: " .. location.name)
            
            -- Force clear the cache to ensure fresh data
            -- print("DEBUG CLEAR: Force clearing cache after DeleteLocation")
            playerLocationCache[playerGuid] = nil
            
            -- Add a small delay to ensure database transaction completes
            player:RegisterEvent(function()
                -- Get fresh player object to avoid stale reference
                local currentPlayer = GetPlayerByGUID(playerGuid)
                if not currentPlayer then
                    -- print("DEBUG CLEAR: Player object became invalid during delay")
                    return
                end
                
                -- Refresh the management menu to show the change
                -- print("DEBUG CLEAR: Checking database after 100ms delay...")
                local updatedLocations = GetPlayerLocations(playerGuid, itemId)
                -- print("DEBUG CLEAR: After clearing, updatedLocations has " .. (next(updatedLocations) and "data" or "no data"))
                
                -- If data still exists, show what's still there
                if next(updatedLocations) then
                    for s, loc in pairs(updatedLocations) do
                        -- print("DEBUG CLEAR: Still found in slot " .. s .. ": " .. loc.name)
                    end
                end
                
                -- Close gossip menu since item object becomes stale
                currentPlayer:GossipComplete()
                currentPlayer:SendBroadcastMessage("Location cleared successfully. Use beacon again to continue.")
            end, 100, 1) -- 100ms delay
            
            return false
        else
            -- print("DEBUG CLEAR: No location found in slot " .. slot)
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
        
    elseif intid == 8000 then
        -- Show capital cities menu
        ShowCapitalCitiesMenu(player, itemId, beaconData)
        player:GossipSendMenu(1, item)
        return false
        
    elseif intid >= 8101 and intid <= 8110 then
        -- Capital city teleportation
        local cityIndex = intid - 8100
        local selectedCity = CAPITAL_CITIES[cityIndex]
        
        if not selectedCity then
            player:SendBroadcastMessage("Error: Invalid city selection.")
            player:GossipComplete()
            return false
        end
        
        -- Check if player has capital networks upgrade
        local playerUpgrades = GetPlayerFunctionalityUpgrades(playerGuid)
        if not playerUpgrades.capital_networks then
            player:SendBroadcastMessage("You need the Capital Networks upgrade to use this feature.")
            player:GossipComplete()
            return false
        end
        
        if not HasEnoughReagents(player, REAGENTS.TRAVELERS_MARK, 1) then
            player:SendBroadcastMessage("You need a Traveler's Mark to teleport to capital cities.")
            player:GossipComplete()
            return false
        end
        
        ConsumeReagents(player, REAGENTS.TRAVELERS_MARK, 1)
        
        -- Create location object for capital city
        local capitalLocation = {
            name = selectedCity.name,
            mapId = selectedCity.mapId,
            x = selectedCity.x,
            y = selectedCity.y,
            z = selectedCity.z,
            o = selectedCity.o
        }
        
        StartTeleportChannel(player, capitalLocation, itemId)
        
    elseif intid == 8200 then
        -- Show dungeon access menu
        print("DEBUG BEACON GOSSIP: Player selected Dungeon Access menu (intent 8200)")
        ShowDungeonAccessMenu(player, itemId, beaconData)
        player:GossipSendMenu(1, item)
        return false
        
    elseif intid == 8300 then
        -- Show raid access menu
        print("DEBUG BEACON GOSSIP: Player selected Raid Access menu (intent 8300)")
        ShowRaidAccessMenu(player, itemId, beaconData)
        player:GossipSendMenu(1, item)
        return false
        
    elseif intid >= 8201 and intid <= 8250 then
        -- Dungeon teleportation
        print("DEBUG DUNGEON TELEPORT: Player selected dungeon teleportation with intent " .. intid)
        
        local playerUpgrades = GetPlayerFunctionalityUpgrades(playerGuid)
        if not playerUpgrades.dungeon_access then
            print("DEBUG DUNGEON TELEPORT: Player doesn't have dungeon access upgrade")
            player:SendBroadcastMessage("You need the Dungeon Access upgrade to use this feature.")
            player:GossipComplete()
            return false
        end
        
        local dungeonIndex = intid - 8200
        print("DEBUG DUNGEON TELEPORT: Dungeon index: " .. dungeonIndex)
        
        local discoveredDungeons = GetDiscoveredDungeons(playerGuid)
        print("DEBUG DUNGEON TELEPORT: Retrieved " .. #discoveredDungeons .. " discovered dungeons")
        
        if not discoveredDungeons or not discoveredDungeons[dungeonIndex] then
            print("DEBUG DUNGEON TELEPORT: Invalid dungeon selection - index " .. dungeonIndex .. " not found")
            player:SendBroadcastMessage("Error: Invalid dungeon selection.")
            player:GossipComplete()
            return false
        end
        
        local selectedDungeon = discoveredDungeons[dungeonIndex]
        print("DEBUG DUNGEON TELEPORT: Selected dungeon map ID: " .. selectedDungeon.mapId)
        
        local dungeonInfo = DUNGEON_DATA[selectedDungeon.mapId]
        
        if not dungeonInfo then
            print("DEBUG DUNGEON TELEPORT: No dungeon data found for map " .. selectedDungeon.mapId)
            player:SendBroadcastMessage("Error: Dungeon data not found.")
            player:GossipComplete()
            return false
        end
        
        print("DEBUG DUNGEON TELEPORT: Found dungeon info for: " .. dungeonInfo.name)
        
        if not HasEnoughReagents(player, REAGENTS.TRAVELERS_MARK, 1) then
            print("DEBUG DUNGEON TELEPORT: Player doesn't have enough reagents")
            player:SendBroadcastMessage("You need a Traveler's Mark to teleport to dungeons.")
            player:GossipComplete()
            return false
        end
        
        ConsumeReagents(player, REAGENTS.TRAVELERS_MARK, 1)
        print("DEBUG DUNGEON TELEPORT: Consumed reagents, starting teleport")
        
        -- Create location object for dungeon entrance
        local dungeonLocation = {
            name = dungeonInfo.name,
            mapId = dungeonInfo.entrance.mapId,
            x = dungeonInfo.entrance.x,
            y = dungeonInfo.entrance.y,
            z = dungeonInfo.entrance.z,
            o = dungeonInfo.entrance.o
        }
        
        print("DEBUG DUNGEON TELEPORT: Starting teleport to " .. dungeonLocation.name .. " at map " .. dungeonLocation.mapId)
        StartTeleportChannel(player, dungeonLocation, itemId)
        
    elseif intid >= 8301 and intid <= 8350 then
        -- Raid teleportation
        print("DEBUG RAID TELEPORT: Player selected raid teleportation with intent " .. intid)
        
        local playerUpgrades = GetPlayerFunctionalityUpgrades(playerGuid)
        if not playerUpgrades.raid_access then
            print("DEBUG RAID TELEPORT: Player doesn't have raid access upgrade")
            player:SendBroadcastMessage("You need the Raid Access upgrade to use this feature.")
            player:GossipComplete()
            return false
        end
        
        local raidIndex = intid - 8300
        print("DEBUG RAID TELEPORT: Raid index: " .. raidIndex)
        
        local discoveredRaids = GetDiscoveredRaids(playerGuid)
        print("DEBUG RAID TELEPORT: Retrieved " .. #discoveredRaids .. " discovered raids")
        
        if not discoveredRaids or not discoveredRaids[raidIndex] then
            print("DEBUG RAID TELEPORT: Invalid raid selection - index " .. raidIndex .. " not found")
            player:SendBroadcastMessage("Error: Invalid raid selection.")
            player:GossipComplete()
            return false
        end
        
        local selectedRaid = discoveredRaids[raidIndex]
        print("DEBUG RAID TELEPORT: Selected raid map ID: " .. selectedRaid.mapId)
        
        local raidInfo = RAID_DATA[selectedRaid.mapId]
        
        if not raidInfo then
            print("DEBUG RAID TELEPORT: No raid data found for map " .. selectedRaid.mapId)
            player:SendBroadcastMessage("Error: Raid data not found.")
            player:GossipComplete()
            return false
        end
        
        print("DEBUG RAID TELEPORT: Found raid info for: " .. raidInfo.name)
        
        if not HasEnoughReagents(player, REAGENTS.TRAVELERS_MARK, 1) then
            print("DEBUG RAID TELEPORT: Player doesn't have enough reagents")
            player:SendBroadcastMessage("You need a Traveler's Mark to teleport to raids.")
            player:GossipComplete()
            return false
        end
        
        ConsumeReagents(player, REAGENTS.TRAVELERS_MARK, 1)
        print("DEBUG RAID TELEPORT: Consumed reagents, starting teleport")
        
        -- Create location object for raid entrance
        local raidLocation = {
            name = raidInfo.name,
            mapId = raidInfo.entrance.mapId,
            x = raidInfo.entrance.x,
            y = raidInfo.entrance.y,
            z = raidInfo.entrance.z,
            o = raidInfo.entrance.o
        }
        
        print("DEBUG RAID TELEPORT: Starting teleport to " .. raidLocation.name .. " at map " .. raidLocation.mapId)
        StartTeleportChannel(player, raidLocation, itemId)
        
    elseif intid == 8999 then
        -- Back to main menu from capital cities, dungeons, or raids
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
-- print("Registering upgrade NPC events for NPC " .. UPGRADE_NPC_ID)
RegisterCreatureGossipEvent(UPGRADE_NPC_ID, 1, OnUpgradeNPCGossip)
RegisterCreatureGossipEvent(UPGRADE_NPC_ID, 2, OnUpgradeNPCGossipSelect)
-- print("  Registered upgrade gossip events for NPC " .. UPGRADE_NPC_ID)

-- Cleanup on logout
local function OnPlayerLogout(event, player)
    local playerGuid = player:GetGUIDLow()
    playerLocationCache[playerGuid] = nil
    playerCooldowns[playerGuid] = nil
end

RegisterPlayerEvent(4, OnPlayerLogout)

-- Dungeon discovery tracking
local function OnMapChange(event, player, newMapId, newX, newY, newZ, newO)
    local playerGuid = player:GetGUIDLow()
    local playerName = player:GetName()
    
    -- Debug all parameters to see what we're getting
    print("DEBUG DUNGEON: OnMapChange triggered - Event: " .. tostring(event))
    print("DEBUG DUNGEON: Player: " .. playerName .. " (" .. playerGuid .. ")")
    print("DEBUG DUNGEON: newMapId: " .. tostring(newMapId))
    print("DEBUG DUNGEON: newX: " .. tostring(newX))
    print("DEBUG DUNGEON: newY: " .. tostring(newY))
    print("DEBUG DUNGEON: newZ: " .. tostring(newZ))
    print("DEBUG DUNGEON: newO: " .. tostring(newO))
    
    -- Check if newMapId is nil
    if not newMapId then
        print("DEBUG DUNGEON: newMapId is nil - trying to get current map from player")
        newMapId = player:GetMapId()
        print("DEBUG DUNGEON: Got map ID from player: " .. tostring(newMapId))
    end
    
    -- Still nil? Skip processing
    if not newMapId then
        print("DEBUG DUNGEON: Cannot determine map ID - skipping discovery")
        return
    end
    
    -- Check if player entered a dungeon
    if IsDungeonMap(newMapId) then
        print("DEBUG DUNGEON: Player entered a dungeon!")
        local dungeonInfo = DUNGEON_DATA[newMapId]
        if dungeonInfo then
            print("DEBUG DUNGEON: Attempting to save discovery for: " .. dungeonInfo.name)
            local wasNew = SaveDiscoveredDungeon(playerGuid, newMapId)
            if wasNew then
                print("DEBUG DUNGEON: New discovery! Notifying player.")
                player:SendBroadcastMessage("Dungeon discovered: " .. dungeonInfo.name)
                player:SendBroadcastMessage("This dungeon is now available in your Beacon's Dungeon Access menu!")
            else
                print("DEBUG DUNGEON: Already discovered - no notification sent")
            end
        else
            print("DEBUG DUNGEON: ERROR - IsDungeonMap returned true but no dungeon info found!")
        end
    -- Check if player entered a raid
    elseif IsRaidMap(newMapId) then
        print("DEBUG RAID: Player entered a raid!")
        local raidInfo = RAID_DATA[newMapId]
        if raidInfo then
            print("DEBUG RAID: Attempting to save discovery for: " .. raidInfo.name)
            local wasNew = SaveDiscoveredRaid(playerGuid, newMapId)
            if wasNew then
                print("DEBUG RAID: New discovery! Notifying player.")
                player:SendBroadcastMessage("Raid discovered: " .. raidInfo.name)
                player:SendBroadcastMessage("This raid is now available in your Beacon's Raid Access menu!")
            else
                print("DEBUG RAID: Already discovered - no notification sent")
            end
        else
            print("DEBUG RAID: ERROR - IsRaidMap returned true but no raid info found!")
        end
    else
        print("DEBUG INSTANCE: Not a dungeon or raid map - skipping discovery")
    end
end

RegisterPlayerEvent(28, OnMapChange) -- Event 28 = PLAYER_EVENT_ON_MAP_CHANGE
print("DEBUG DUNGEON: Registered OnMapChange event handler")

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