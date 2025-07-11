# 55 Solo Systems for AzerothCore

## Table of Contents

### Combat & Arena Systems (1-10)
1. [Champion Challenge Arena](#1-champion-challenge-arena)
2. [NPC Duel League / Sparring Grounds](#2-npc-duel-league--sparring-grounds)
3. [1v1 Tournament Mode](#3-1v1-tournament-mode)
4. [Brawler's Guild-Style Arena](#4-brawlers-guild-style-arena)
5. [Faction Champions (PvP-style PvE)](#5-faction-champions-pvp-style-pve)
6. [Solo Raid Progression Ladder](#6-solo-raid-progression-ladder)
7. [Class Mastery Trials](#7-class-mastery-trials)
8. [Weapon Mastery System](#8-weapon-mastery-system)
9. [Combat Style Evolution](#9-combat-style-evolution)
10. [Solo Challenge Modes](#10-solo-challenge-modes)

### Dungeon & Instance Systems (11-18)
11. [Solo Dungeons with Scaled Rewards](#11-solo-dungeons-with-scaled-rewards)
12. [Mutation Dungeon Key System](#12-mutation-dungeon-key-system)
13. [Dungeon Infusion Modifier System](#13-dungeon-infusion-modifier-system)
14. [Wizard's Trials (Puzzle Dungeon)](#14-wizards-trials-puzzle-dungeon)
15. [Dungeon Speed Run Challenges](#15-dungeon-speed-run-challenges)
16. [Procedural Dungeon Generation](#16-procedural-dungeon-generation)
17. [Dungeon Conquest Achievements](#17-dungeon-conquest-achievements)
18. [Solo Mythic+ System](#18-solo-mythic-system)

### World Events & Dynamic Content (19-26)
19. [Phantom Invasions (Dynamic World Events)](#19-phantom-invasions-dynamic-world-events)
20. [Zone Event Triggers](#20-zone-event-triggers)
21. [Elite World Boss Rotations](#21-elite-world-boss-rotations)
22. [Dynamic Weather Events](#22-dynamic-weather-events)
23. [Seasonal World Events](#23-seasonal-world-events)
24. [Dynamic Faction Wars](#24-dynamic-faction-wars)
25. [World PvE Invasion Cycles](#25-world-pve-invasion-cycles)
26. [Environmental Hazard Zones](#26-environmental-hazard-zones)

### Progression & Character Systems (27-34)
27. [Class Trials or Initiation Rituals](#27-class-trials-or-initiation-rituals)
28. [Magic Spell Tutor](#28-magic-spell-tutor)
29. [City Reputation System](#29-city-reputation-system)
30. [Faction Warboard](#30-faction-warboard)
31. [Solo Progression Milestones](#31-solo-progression-milestones)
32. [Character Prestige System](#32-character-prestige-system)
33. [Solo Achievement Paths](#33-solo-achievement-paths)
34. [Personal Legendary Questlines](#34-personal-legendary-questlines)

### Economy & Trading Systems (35-39)
35. [Dynamic Vendor / Rotating Stock](#35-dynamic-vendor--rotating-stock)
36. [Bounty Board / Hunting Lodge](#36-bounty-board--hunting-lodge)
37. [Solo Economy Empire](#37-solo-economy-empire)
38. [Crafting Mastery System](#38-crafting-mastery-system)
39. [Personal Auction House](#39-personal-auction-house)

### Exploration & Discovery Systems (40-50)
40. [Lost Cargo / World Chests](#40-lost-cargo--world-chests)
41. [Dynamic Lore Library & Collectibles](#41-dynamic-lore-library--collectibles)
42. [Treasure Map Deciphering](#42-treasure-map-deciphering)
43. [Timewalking Zones (Phased)](#43-timewalking-zones-phased)
44. [Hidden Shrines with Buffs](#44-hidden-shrines-with-buffs)
45. [Rare Mount Hunt Across Continents](#45-rare-mount-hunt-across-continents)
46. [Solo Archaeology System](#46-solo-archaeology-system)
47. [Personal Garrison/Base Building](#47-personal-garrisonbase-building)
48. [Solo Fishing Tournaments](#48-solo-fishing-tournaments)
49. [Personal Pet Battle League](#49-personal-pet-battle-league)
50. [Solo Exploration Achievements](#50-solo-exploration-achievements)

### Additional Solo Systems (51-55)
51. [NPC Quest Companions & Story Arcs](#51-npc-quest-companions--story-arcs)
52. [Daily & Weekly Quest Generators](#52-daily--weekly-quest-generators)
53. [Loot Converter / Salvage System](#53-loot-converter--salvage-system)
54. [Death Whisper / Memory System](#54-death-whisper--memory-system)
55. [Player Title Tracker / Vanity Hall](#55-player-title-tracker--vanity-hall)
56. [Traveler's Beacon](#56-travelers-beacon)

---

## Combat & Arena Systems

### 1. Champion Challenge Arena

**Tagline:** "Face your strongest foes... alone."

**Gameplay:**
Enter a solo arena where increasingly difficult champions await.
- Each fight escalates in mechanics and power
- Victory grants titles, vanity gear, or transmog tokens

**Mechanics:**
- Player is teleported into an arena instance or phased zone
- Boss NPCs are spawned using `PerformIngameSpawn()`
- Bosses can use scripted spell timers and phases
- Completion tracked using player data or custom tokens

```lua
player:Teleport(1, 16222.1, 16265.1, 14.2)
```

### 2. NPC Duel League / Sparring Grounds

**Tagline:** "Your next challenger awaits."

**Gameplay:**
Solo PvE duels against increasingly hard NPCs.
- Combat simulates PvP classes
- Win streaks earn titles or transmogs

**Mechanics:**
- Trigger duels in 1v1 arena
- NPCs cast class spells, use cooldowns
- Win triggers next phase or reward

```lua
PerformIngameSpawn(2, 99999, 0, 0, x, y, z, o, true, 1800)
```

### 3. 1v1 Tournament Mode

**Tagline:** "Victory... or defeat. Enter the arena."

**Gameplay:**
Repeatable 1v1 tournament where each round gets harder.
- Weekly reset
- Cosmetic reward ladder

**Mechanics:**
- Track rounds completed
- Spawn harder NPCs by stage
- Reward tokens per win

```lua
player:SetData("arena_round", 4)
```

### 4. Brawler's Guild-Style Arena

**Tagline:** "Face the challenger alone... if you dare."

**Gameplay:**
Solo fight club with bizarre scripted fights.
- Gimmick enemies (e.g., avoid zones, switch buffs)
- Weekly new bosses

**Mechanics:**
- Use boss scripts with timers and phase swaps
- Reward based on survival duration or style
- Add leaderboard or ranking display

```lua
SendWorldMessage("Player X has defeated The Slaughterbot!")
```

### 5. Faction Champions (PvP-style PvE)

**Tagline:** "These foes fight like players..."

**Gameplay:**
Script NPCs to mimic PvP playstyles.
- Rogue NPC uses vanish and kidney shot
- Mage NPC kites and roots

**Mechanics:**
- Use Eluna AI scripting
- Combine multiple NPCs for a group encounter
- Reward on success with PvP vanity gear

```lua
npc:CastSpell(player, 2094) -- Blind
```

### 6. Solo Raid Progression Ladder

**Tagline:** "Conquer the impossible... one boss at a time."

**Gameplay:**
Progressive solo raid encounters that scale with your gear and level.
- Start with simple mechanics, progress to complex multi-phase fights
- Each boss teaches specific mechanics for the next
- Rewards include raid-quality gear scaled for solo play

**Mechanics:**
- Use mod-autobalance to scale raid encounters
- Script boss phases that can be handled solo
- Track progression with `player:SetData("raid_tier", 1)`
- Reward with custom raid tokens or scaled gear

```lua
-- Scale Molten Core for solo play
player:SetData("solo_raid", "molten_core")
player:AddAura(23735, player) -- Solo raid buff
```

### 7. Class Mastery Trials

**Tagline:** "Master your class... or perish trying."

**Gameplay:**
Advanced class-specific challenges that test your understanding of your class.
- Each class has unique trials (Mage: mana management, Rogue: stealth mechanics)
- Complete trials to unlock class-specific abilities or transmogs
- Trials become harder as you progress

**Mechanics:**
- Class-specific event hooks and challenges
- Track mastery levels with `player:SetData("class_mastery", level)`
- Reward with class-exclusive spells or abilities
- Use `player:GetClass()` to determine trial type

```lua
if player:GetClass() == 4 then -- Rogue
    player:SetData("stealth_trial", true)
    player:AddAura(1784, player) -- Stealth buff for trial
end
```

### 8. Weapon Mastery System

**Tagline:** "Your weapon becomes an extension of your soul."

**Gameplay:**
Master different weapon types to unlock special abilities and bonuses.
- Use specific weapons to gain mastery points
- Unlock weapon-specific abilities (sword parry, axe cleave, etc.)
- Mastery affects damage, crit chance, and special effects

**Mechanics:**
- Track weapon usage with `PLAYER_EVENT_ON_KILL_CREATURE`
- Award mastery points based on kills with specific weapon types
- Unlock abilities at mastery thresholds
- Store mastery data with `player:SetData("weapon_mastery_sword", points)`

```lua
local weaponType = player:GetEquippedItemBySlot(16):GetSubClass()
player:SetData("weapon_mastery_" .. weaponType, 
    player:GetData("weapon_mastery_" .. weaponType) + 1)
```

### 9. Combat Style Evolution

**Tagline:** "Your fighting style adapts to your victories."

**Gameplay:**
Your combat approach evolves based on how you defeat enemies.
- Aggressive kills unlock offensive bonuses
- Defensive victories grant protective abilities
- Mixed approaches create hybrid styles

**Mechanics:**
- Track combat metrics (damage taken, time to kill, healing done)
- Award style points based on combat performance
- Unlock passive abilities based on dominant style
- Use `player:AddAura()` for style-based buffs

```lua
if damageDealt > damageTaken * 3 then
    player:SetData("combat_style", "aggressive")
    player:AddAura(12345, player) -- Aggressive style buff
end
```

### 10. Solo Challenge Modes

**Tagline:** "Push your limits... break your records."

**Gameplay:**
Time-based challenges with specific restrictions and goals.
- Speed challenges, no-healing runs, specific gear restrictions
- Leaderboard system for personal bests
- Rewards scale with challenge difficulty

**Mechanics:**
- Timer tracking with `CreateLuaEvent`
- Restriction enforcement (gear, abilities, healing)
- Score calculation based on time and performance
- Store personal records with `player:SetData()`

```lua
player:SetData("challenge_mode", "speed_run")
player:SetData("challenge_start_time", os.time())
```

---

## Dungeon & Instance Systems

### 11. Solo Dungeons with Scaled Rewards

**Tagline:** "Face Azeroth's deadliest dungeons... alone."

**Gameplay:**
Allows players to solo dungeon content using auto-balance and receive custom-scaled rewards.
- Enables full dungeon exploration without bots
- Drops vanity gear, crafting materials, or tokens instead of normal group loot

**Mechanics:**
- Enable mod-autobalance and mod-solocraft
- Use Eluna to adjust loot via hooks
- Optional: track dungeon clears and scale reward tiers

```lua
player:AddItem(29434, 3) -- Award 3 Heroic Badges for a solo dungeon clear
```

### 12. Mutation Dungeon Key System

**Tagline:** "Infuse your dungeon run with risk... for greater rewards."

**Gameplay:**
Use consumable keys to modify dungeon conditions:
- Fire Key: fire damage increased, loot chance doubled
- Shadow Key: mobs have more HP but grant bonus XP

**Mechanics:**
- Keys are items or tokens that set a player data flag
- Boss scripts check modifier value and change behavior
- Adjust loot tables or drop bonus items for enhanced runs

```lua
player:SetData("dungeon_modifier", "fire")
```

### 13. Dungeon Infusion Modifier System

**Tagline:** "Corrupt the halls of Shadowfang with Fel energy..."

**Gameplay:**
Infuse dungeons with modifiers that affect enemy behavior or drop rates.
- Choose modifiers before entering
- High risk, high reward content

**Mechanics:**
- Player chooses a modifier via gossip menu
- Modifier stored with `player:SetData()`
- Scripts read modifier value and alter encounters

```lua
player:SetData("modifier_shadowfang", "fel-infused")
```

### 14. Wizard's Trials (Puzzle Dungeon)

**Tagline:** "Strength will not help you here..."

**Gameplay:**
A dungeon filled with riddles, pressure plates, memory puzzles, and non-combat challenges.
- Solve sequences to progress
- Receive magical vanity items for success

**Mechanics:**
- Phased or private map area with puzzle objects
- Interact with GameObjects to track sequences
- Failures reset puzzle or trigger humorous outcomes

```lua
player:SendBroadcastMessage("You hear a faint hum as the crystal responds...")
```

### 15. Dungeon Speed Run Challenges

**Tagline:** "How fast can you conquer the depths?"

**Gameplay:**
Time-based dungeon challenges with leaderboards and rewards.
- Bronze, Silver, Gold time thresholds for each dungeon
- Special rewards for achieving record times
- Weekly rotating dungeon challenges

**Mechanics:**
- Track dungeon entry/exit times
- Compare against preset time thresholds
- Award tokens or gear based on performance
- Store personal bests with `player:SetData()`

```lua
local startTime = player:GetData("dungeon_start_time")
local endTime = os.time()
local duration = endTime - startTime
if duration < 1800 then -- Under 30 minutes
    player:AddItem(29434, 5) -- Bonus badges
end
```

### 16. Procedural Dungeon Generation

**Tagline:** "No two runs are ever the same."

**Gameplay:**
Dungeons that change layout, enemies, and objectives each run.
- Random enemy placement and boss encounters
- Dynamic loot tables based on difficulty
- Unique challenges for each generated instance

**Mechanics:**
- Use random number generation for layout variations
- Spawn different enemies based on seed
- Adjust difficulty based on player level and gear
- Store generation seed with `player:SetData()`

```lua
local seed = math.random(1, 1000)
player:SetData("dungeon_seed", seed)
-- Generate dungeon based on seed
```

### 17. Dungeon Conquest Achievements

**Tagline:** "Every dungeon conquered... every challenge met."

**Gameplay:**
Comprehensive achievement system for dungeon completion.
- Complete all dungeons, complete with specific restrictions
- Unlock titles, mounts, and special gear
- Progressive rewards for increasing difficulty

**Mechanics:**
- Track dungeon completions with `player:SetData()`
- Award achievement points for milestones
- Unlock rewards at achievement thresholds
- Display progress with custom UI elements

```lua
player:SetData("dungeons_completed", player:GetData("dungeons_completed") + 1)
if player:GetData("dungeons_completed") >= 50 then
    player:AddTitle(123) -- Dungeon Master title
end
```

### 18. Solo Mythic+ System

**Tagline:** "Push beyond the limits of normal dungeons."

**Gameplay:**
Scaling difficulty system for dungeons with increasing rewards.
- Start at +1 difficulty, progress to +20+
- Each level increases enemy health, damage, and adds mechanics
- Weekly affixes that change dungeon behavior

**Mechanics:**
- Scale enemy stats based on mythic level
- Apply weekly affixes (explosive, tyrannical, etc.)
- Track highest completed level
- Award gear with higher item levels for higher difficulties

```lua
local mythicLevel = player:GetData("mythic_level") or 1
-- Scale enemy health and damage by mythic level
enemy:SetMaxHealth(enemy:GetMaxHealth() * (1 + mythicLevel * 0.1))
```

---

## World Events & Dynamic Content

### 19. Phantom Invasions (Dynamic World Events)

**Tagline:** "A portal has opened in Hillsbrad... phantoms pour through!"

**Gameplay:**
Random zones are invaded by hostile NPCs.
- Players must defend towns or eliminate lieutenants
- Successful defense unlocks buffs or temporary vendors

**Mechanics:**
- Timer triggers invasion events with `PerformIngameSpawn`
- World broadcasts notify the player
- Event clears on boss kill or after a timer expires

```lua
SendWorldMessage("Zone Alert: Phantom Invasion detected in Ashenvale!")
```

### 20. Zone Event Triggers

**Tagline:** "Emergency! A wildfire spreads through the forest..."

**Gameplay:**
Triggers random events in zones, like wildfires, bandit ambushes, or corrupted wildlife.
- Players can intervene to help NPCs
- Successful defense unlocks buffs or story progression

**Mechanics:**
- Use timed events with `CreateLuaEvent`
- Spawn mobs, objects, or game effects dynamically
- Set local weather or debuffs for flavor

```lua
World:SendWeather(0, 1, 0.8) -- Example: Rainstorm in Elwynn
```

### 21. Elite World Boss Rotations

**Tagline:** "The Black Serpent rises again in Desolace..."

**Gameplay:**
Rotating elite bosses spawn weekly in different zones.
- Difficult solo fights with mechanics
- Drop crafting reagents or cosmetic rewards

**Mechanics:**
- Timer-based spawns
- Bosses use unique spells and scaling HP
- Optional: broadcast spawn events server-wide

```lua
PerformIngameSpawn(2, 60001, 0, 0, 0, 1, true, 120000)
```

### 22. Dynamic Weather Events

**Tagline:** "The sky darkens... something is coming."

**Gameplay:**
Simulate immersive environmental changes in zones.
- Storms reduce visibility
- Cold zones reduce stamina
- Heat increases chance of crits

**Mechanics:**
- Use `World:SendWeather()`
- Add auras to simulate environmental effects
- Trigger events by timers or player entry

```lua
World:SendWeather(0, 2, 1.0) -- Heavy storm
```

### 23. Seasonal World Events

**Tagline:** "The world changes with the seasons."

**Gameplay:**
Rotating seasonal events that change the world and offer unique rewards.
- Spring: Blooming events with nature-themed rewards
- Summer: Fire festivals with elemental challenges
- Autumn: Harvest events with crafting bonuses
- Winter: Frost events with ice-themed content

**Mechanics:**
- Timer-based seasonal changes
- Spawn seasonal NPCs and events
- Offer seasonal crafting materials and recipes
- Change world aesthetics and weather

```lua
local currentSeason = os.date("*t").month
if currentSeason >= 3 and currentSeason <= 5 then
    -- Spring events
    World:SendWeather(0, 1, 0.3) -- Light rain
    PerformIngameSpawn(2, 60002, 0, 0, x, y, z, o, true, 7200) -- Spring NPC
end
```

### 24. Dynamic Faction Wars

**Tagline:** "Choose your side in the eternal conflict."

**Gameplay:**
Dynamic faction conflicts that players can influence.
- Join temporary factions for special events
- Participate in faction-specific quests and rewards
- Faction standing affects vendor access and story options

**Mechanics:**
- Track faction participation with `player:SetData()`
- Spawn faction-specific NPCs and events
- Offer faction-exclusive rewards and gear
- Change world events based on faction dominance

```lua
player:SetData("current_faction", "dawn_guard")
if player:GetData("current_faction") == "dawn_guard" then
    player:AddItem(12345, 1) -- Dawn Guard exclusive item
end
```

### 25. World PvE Invasion Cycles

**Tagline:** "The world is under siege... will you defend it?"

**Gameplay:**
Cyclical invasions where different enemy types attack various zones.
- Undead invasions, demon incursions, elemental storms
- Defend zones to earn reputation and rewards
- Failed defenses have consequences for the world

**Mechanics:**
- Timer-based invasion cycles
- Spawn waves of enemies in specific zones
- Track defense success/failure
- Award defenders with special currency or gear

```lua
SendWorldMessage("Undead invasion detected in Tirisfal Glades!")
PerformIngameSpawn(2, 60003, 0, 0, x, y, z, o, true, 3600) -- Invasion boss
```

### 26. Environmental Hazard Zones

**Tagline:** "The environment itself becomes your enemy."

**Gameplay:**
Zones with environmental hazards that require special preparation.
- Toxic zones requiring antidotes
- Extreme weather requiring protective gear
- Magical corruption requiring cleansing items

**Mechanics:**
- Apply environmental debuffs to players in zones
- Require specific items or buffs to survive
- Offer unique rewards for braving hazards
- Track hazard exploration with achievements

```lua
if player:GetZoneId() == 139 then -- Eastern Plaguelands
    player:AddAura(12346, player) -- Plague debuff
    if player:HasItem(12347) then -- Antidote
        player:RemoveAura(12346)
    end
end
```

---

## Progression & Character Systems

### 27. Class Trials or Initiation Rituals

**Tagline:** "Only the worthy may wear the mark of their class."

**Gameplay:**
At key levels (e.g. 30, 60), players face class-themed solo challenges.
- Defeat an enemy solo, solve a class puzzle, or survive a test
- Earn a class-specific title or ability

**Mechanics:**
- Class check with `player:GetClass()`
- Use teleport or phased area for solo challenge
- Reward via `player:LearnSpell()`, `AddItem`, or `AddTitle`

```lua
if player:GetClass() == 8 then player:LearnSpell(28271) end -- Mage: Polymorph Turtle
```

### 28. Magic Spell Tutor

**Tagline:** "Magic flows through time... would you learn something lost?"

**Gameplay:**
A mystical NPC offers rare spells appropriate to your class and level.
- Can offer Polymorph variants, teleport spells, or fun transformations
- Gated by gold, item cost, or cooldown

**Mechanics:**
- Gossip menu with class and level checks
- Offer a random spell from a curated list
- Use `player:LearnSpell()` to teach

```lua
player:LearnSpell(28272) -- Teach Polymorph: Pig
```

### 29. City Reputation System

**Tagline:** "The people of Stormwind recognize your service."

**Gameplay:**
Perform tasks that benefit major cities to gain hidden reputation levels.
- Quests, donations, or protection increase favor
- Unlock discounts, cosmetics, or teleport scrolls

**Mechanics:**
- Track rep with custom variables
- Offer different gossip options at rep tiers
- Optional: add city reputation to UI via custom currency or script

```lua
player:SetData("stormwind_rep", player:GetData("stormwind_rep") + 250)
```

### 30. Faction Warboard

**Tagline:** "Choose your allegiance: Dawn or Dusk. You may only choose once."

**Gameplay:**
Players select one of two rival factions to align with.
- Faction choice affects vendor access, quests, and cosmetics
- Creates replayability and identity

**Mechanics:**
- Use gossip NPC with permanent player choice
- Store faction choice with `player:SetData()`
- Adjust future NPC dialogs or vendor options

```lua
player:SetData("faction_choice", "dawn")
```

### 31. Solo Progression Milestones

**Tagline:** "Every step forward is a victory worth celebrating."

**Gameplay:**
Milestone-based progression system with meaningful rewards.
- Level milestones, gear score thresholds, achievement counts
- Each milestone unlocks new content or abilities
- Progressive rewards that scale with difficulty

**Mechanics:**
- Track various progression metrics
- Award milestone rewards automatically
- Unlock new content based on milestones
- Display progress with custom UI

```lua
local gearScore = CalculateGearScore(player)
if gearScore >= 200 and not player:GetData("milestone_200") then
    player:SetData("milestone_200", true)
    player:AddItem(12348, 1) -- Milestone reward
    player:SendBroadcastMessage("Gear Score Milestone: 200!")
end
```

### 32. Character Prestige System

**Tagline:** "Start over... but stronger than ever."

**Gameplay:**
Prestige system allowing players to reset progress for permanent bonuses.
- Reset level, gear, and progress for prestige points
- Prestige points unlock permanent account-wide bonuses
- Multiple prestige levels with increasing rewards

**Mechanics:**
- Track prestige level with `player:SetData()`
- Award prestige points for completing prestige
- Apply permanent bonuses based on prestige level
- Reset character data while preserving prestige benefits

```lua
if player:GetLevel() == 80 and player:GetData("prestige_ready") then
    player:SetData("prestige_level", player:GetData("prestige_level") + 1)
    player:SetLevel(1)
    player:AddItem(12349, 1) -- Prestige token
end
```

### 33. Solo Achievement Paths

**Tagline:** "Choose your path to greatness."

**Gameplay:**
Branching achievement paths that offer different rewards and content.
- Combat path: Focus on killing and damage
- Exploration path: Focus on discovery and collection
- Social path: Focus on reputation and diplomacy
- Each path unlocks unique rewards and content

**Mechanics:**
- Track achievement points in different categories
- Unlock path-specific content based on progress
- Offer path-exclusive rewards and abilities
- Allow path switching with penalties

```lua
local combatPoints = player:GetData("achievement_combat") or 0
if combatPoints >= 1000 then
    player:AddTitle(124) -- Combat Master title
    player:LearnSpell(12350) -- Combat path ability
end
```

### 34. Personal Legendary Questlines

**Tagline:** "Forge your own legend... one quest at a time."

**Gameplay:**
Personal legendary questlines that create unique items and abilities.
- Multi-stage quests requiring various activities
- Quest outcomes depend on player choices
- Results in personalized legendary items or abilities

**Mechanics:**
- Track quest progress with `player:SetData()`
- Offer choice-based quest outcomes
- Create custom items based on player decisions
- Award unique abilities or spells

```lua
if player:GetData("legendary_quest_stage") == 5 then
    local choice = player:GetData("legendary_choice")
    if choice == "fire" then
        player:LearnSpell(12351) -- Fire legendary ability
    elseif choice == "ice" then
        player:LearnSpell(12352) -- Ice legendary ability
    end
end
```

---

## Economy & Trading Systems

### 35. Dynamic Vendor / Rotating Stock

**Tagline:** "Each time you visit, something new awaits..."

**Gameplay:**
A vendor whose inventory changes every 30-60 minutes.
- Pulls randomly from a pool of profession materials, recipes, or utility items
- Guarantees at least 1 relevant item for each of player's professions

**Mechanics:**
- Use Eluna timers and table randomization
- `ClearVendorItems()` then `AddVendorItem()`
- Optionally adjust prices based on rarity or demand

```lua
vendor:AddVendorItem(2592, 10) -- Add Wool Cloth to stock
```

### 36. Bounty Board / Hunting Lodge

**Tagline:** "Wanted: King Bangalash. Reward: Rare cloak."

**Gameplay:**
Visit a bounty board each week to receive new targets.
- Hunt rare or elite mobs
- Turn in trophies for gold, tokens, or vanity gear

**Mechanics:**
- NPC displays rotating kill quests
- Hook `PLAYER_EVENT_ON_KILL_CREATURE`
- Grant item drops that turn in for rewards

```lua
player:AddItem(12219, 1) -- Example: trophy drop from rare kill
```

### 37. Solo Economy Empire

**Tagline:** "Build your wealth from the ground up."

**Gameplay:**
Comprehensive economy system where players build their own economic empire.
- Invest in different economic sectors
- Manage resources and production chains
- Compete for market dominance

**Mechanics:**
- Track economic investments with `player:SetData()`
- Create production chains and resource management
- Award passive income based on investments
- Offer economic achievements and rewards

```lua
local investments = player:GetData("economic_investments") or {}
local passiveIncome = CalculatePassiveIncome(investments)
player:AddItem(12353, passiveIncome) -- Daily income
```

### 38. Crafting Mastery System

**Tagline:** "Master every craft... become the ultimate artisan."

**Gameplay:**
Advanced crafting system with mastery levels and specializations.
- Master all professions to unlock special recipes
- Specialize in specific crafting types for bonuses
- Unlock rare materials and unique items

**Mechanics:**
- Track crafting skill levels and specializations
- Award mastery points for successful crafts
- Unlock special recipes at mastery thresholds
- Offer crafting-specific rewards and abilities

```lua
local blacksmithLevel = player:GetData("crafting_blacksmith") or 0
if blacksmithLevel >= 100 then
    player:LearnSpell(12354) -- Master blacksmith ability
    player:AddItem(12355, 1) -- Master crafting recipe
end
```

### 39. Personal Auction House

**Tagline:** "Your market, your rules."

**Gameplay:**
Personal auction house system for solo players.
- List items for sale with custom pricing
- Buy from other players' listings
- Earn commission from successful sales

**Mechanics:**
- Create personal auction listings
- Track sales and earnings
- Offer market analysis and trends
- Award trading achievements

```lua
local listing = {
    itemId = 12356,
    price = 1000,
    seller = player:GetGUID(),
    duration = 7200 -- 2 hours
}
CreateAuctionListing(listing)
```

---

## Exploration & Discovery Systems

### 40. Lost Cargo / World Chests

**Tagline:** "Someone's lost shipment has washed ashore..."

**Gameplay:**
Rare containers appear randomly in the world.
- Can contain profession materials, scrolls, or lore
- Optional clues lead players to next chest

**Mechanics:**
- Randomize spawn location
- GameObject or spawned creature drop
- Despawn after use

```lua
PerformIngameSpawn(5, 181366, 0, 0, x, y, z, o, true, 3600)
```

### 41. Dynamic Lore Library & Collectibles

**Tagline:** "Page 6 of Arugal's journal recovered..."

**Gameplay:**
Scattered lore pages and collectibles add depth to worldbuilding.
- Reward players with titles or cosmetic items
- Completing sets unlocks bonus events

**Mechanics:**
- Item collection tracked via item IDs
- Turn in completed sets to NPC
- Reward cosmetic gear or companion pets

```lua
player:AddItem(21100, 1) -- Lore page
```

### 42. Treasure Map Deciphering

**Tagline:** "The ink is faded... but a shape appears."

**Gameplay:**
Collect map fragments and piece together hidden treasure locations.
- Combine items to create usable treasure maps
- Marked on map or hint via gossip

**Mechanics:**
- Combine items via Eluna or crafting logic
- Show clues with `player:SendBroadcastMessage`
- Reward via script-triggered chest or token

```lua
player:SendBroadcastMessage("Clue: Where the river meets the mountain...")
```

### 43. Timewalking Zones (Phased)

**Tagline:** "You feel... displaced in time."

**Gameplay:**
Let players re-enter zones in earlier states.
- See old quest chains or events
- Used for story-driven time travel

**Mechanics:**
- Use `player:SetPhaseMask()` for old versions
- Spawn alternative quest NPCs or objects
- Time-travel logic can be tied to major quests

```lua
player:SetPhaseMask(2, true)
```

### 44. Hidden Shrines with Buffs

**Tagline:** "The statue pulses with ancient power..."

**Gameplay:**
Find hidden shrines across the world that grant unique, long-duration buffs.
- Some stack, others overwrite
- Encourages exploration

**Mechanics:**
- GameObject interaction applies unique aura
- Optional: track shrine usage
- Respawn timers or limited use

```lua
player:AddAura(23735, player) -- Ancient shrine buff
```

### 45. Rare Mount Hunt Across Continents

**Tagline:** "The Windsteed leaves no tracks... only clues."

**Gameplay:**
A multi-continent mount quest involving rare spawn clues, item turn-ins, and secret NPCs.
- Long-form solo questline
- One-time reward: epic mount

**Mechanics:**
- Chain of quest flags and creature kills
- Gossip dialog clues for direction
- Final turn-in with title or mount reward

```lua
player:AddItem(43962, 1) -- Reins of the Windsteed
```

### 46. Solo Archaeology System

**Tagline:** "Unearth the secrets of the past."

**Gameplay:**
Personal archaeology system for discovering ancient artifacts.
- Survey sites across the world
- Excavate artifacts and relics
- Complete collections for rewards

**Mechanics:**
- Create dig sites with random locations
- Track artifact collections with `player:SetData()`
- Award archaeology skill points and rewards
- Offer rare artifact discoveries

```lua
local digSite = GenerateDigSite(player:GetZoneId())
player:SetData("current_dig_site", digSite)
player:SendBroadcastMessage("New dig site discovered!")
```

### 47. Personal Garrison/Base Building

**Tagline:** "Build your own fortress in the wilderness."

**Gameplay:**
Personal base building system with customizable structures.
- Build and upgrade various buildings
- Recruit NPC workers and guards
- Generate resources and provide services

**Mechanics:**
- Track building levels and upgrades
- Manage resource production and storage
- Offer building-specific bonuses and abilities
- Create personal teleportation networks

```lua
local garrisonLevel = player:GetData("garrison_level") or 1
if garrisonLevel >= 3 then
    player:LearnSpell(12357) -- Garrison teleport
    player:AddItem(12358, 1) -- Daily garrison resources
end
```

### 48. Solo Fishing Tournaments

**Tagline:** "The biggest catch awaits."

**Gameplay:**
Personal fishing tournaments with unique challenges and rewards.
- Time-based fishing competitions
- Special fishing zones with rare fish
- Tournament rankings and rewards

**Mechanics:**
- Track fishing catches and tournament scores
- Create special fishing zones with rare fish
- Award tournament prizes and achievements
- Offer fishing-specific abilities and gear

```lua
local tournamentScore = player:GetData("fishing_tournament_score") or 0
if tournamentScore >= 1000 then
    player:AddTitle(125) -- Master Angler
    player:AddItem(12359, 1) -- Tournament fishing rod
end
```

### 49. Personal Pet Battle League

**Tagline:** "Train your companions for epic battles."

**Gameplay:**
Personal pet battle system with progression and rewards.
- Capture and train battle pets
- Participate in pet battle tournaments
- Unlock rare pets and abilities

**Mechanics:**
- Track pet collection and battle records
- Create pet battle challenges and tournaments
- Award pet-specific abilities and items
- Offer pet breeding and evolution systems

```lua
local petBattlesWon = player:GetData("pet_battles_won") or 0
if petBattlesWon >= 100 then
    player:AddItem(12360, 1) -- Rare battle pet
    player:LearnSpell(12361) -- Pet battle ability
end
```

### 50. Solo Exploration Achievements

**Tagline:** "Every corner of the world holds a secret."

**Gameplay:**
Comprehensive exploration system with achievements and rewards.
- Discover hidden locations and secrets
- Complete exploration challenges
- Unlock exploration-specific rewards

**Mechanics:**
- Track exploration progress with `player:SetData()`
- Create hidden locations and secrets
- Award exploration achievements and rewards
- Offer exploration-specific abilities and items

```lua
local zonesExplored = player:GetData("zones_explored") or 0
if zonesExplored >= 50 then
    player:AddTitle(126) -- World Explorer
    player:LearnSpell(12362) -- Exploration teleport
end
```

---

## Additional Solo Systems

### 51. NPC Quest Companions & Story Arcs

**Tagline:** "Journey with allies who have their own stories."

**Gameplay:**
Scripted NPCs can join you for certain quests or storylines, offering dialogue, buffs, and unique interactions.
- Companions follow you, help in combat, and react to your actions
- Completing their story arcs unlocks achievements, vanity items, or buffs
- Reputation system tracks your bond with each companion

**Mechanics:**
- Use Eluna to script follow mechanics and dialogue trees
- Track companion reputation with `player:SetData("companion_rep", value)`
- Trigger special events or rewards at reputation milestones

```lua
npc:MoveFollow(player, 2, 2)
player:SetData("companion_rep", (player:GetData("companion_rep") or 0) + 10)
```

### 52. Daily & Weekly Quest Generators

**Tagline:** "New adventures every day!"

**Gameplay:**
A custom NPC offers dynamically generated quests each day/week.
- Randomly selects objectives: kill, collect, explore, craft
- Rewards scale with level and quest difficulty
- Resets automatically on a timer

**Mechanics:**
- Use Eluna to randomize quest objectives
- Store quest state with `player:SetData("daily_quest", questId)`
- Reset quests with `CreateLuaEvent`

```lua
local questPool = {1001, 1002, 1003}
local questId = questPool[math.random(#questPool)]
player:SetData("daily_quest", questId)
```

### 53. Loot Converter / Salvage System

**Tagline:** "Turn junk into treasure."

**Gameplay:**
A vendor or altar lets you trade unwanted gear or mats for useful tokens or crafting reagents.
- Hand in green/blue items for crafting tokens
- Convert old mats into new ones
- Special rewards for bulk turn-ins

**Mechanics:**
- Use gossip menu to select items to convert
- Remove items with `player:RemoveItem()`
- Add rewards with `player:AddItem()`

```lua
if player:HasItemCount(12345, 5) then
  player:RemoveItem(12345, 5)
  player:AddItem(67890, 1) -- Crafting Voucher
end
```

### 54. Death Whisper / Memory System

**Tagline:** "Visions from beyond the grave."

**Gameplay:**
On death, players may be teleported to a dream or memory zone, where they receive cryptic hints, riddles, or story fragments.
- Complete a mini-challenge or puzzle before returning
- Rewards for solving mysteries or finding hidden lore

**Mechanics:**
- Hook into `PLAYER_EVENT_ON_DIED`
- Teleport to a phased area or alternate map
- Return after timer or upon completion

```lua
function OnPlayerDied(event, player)
  player:Teleport(1, 15000, 15000, 50) -- Dream zone
  CreateLuaEvent(function() player:Teleport(0, x, y, z) end, 10000, 1)
end
```

### 55. Player Title Tracker / Vanity Hall

**Tagline:** "Showcase your solo legacy."

**Gameplay:**
A vanity NPC displays your earned titles, rare items, and achievements.
- View progress toward milestones
- Unlock visual badges, tabards, or display trophies
- Optionally, allow other players to visit your vanity hall

**Mechanics:**
- Use gossip menus to display titles and achievements
- Track progress with `player:HasTitle()` and `player:GetAchievementPoints()`
- Offer rewards for reaching milestones

```lua
if player:HasTitle(123) then
  player:SendBroadcastMessage("You have earned the title: Champion of the Arena!")
end
```

---

## Implementation Notes

Each system can be implemented using Eluna scripting for AzerothCore. The systems are designed to be:
- **Solo-focused**: No group requirements
- **Scalable**: Can be adjusted for different player levels
- **Modular**: Can be implemented individually or combined
- **Customizable**: Easy to modify for server-specific needs

For implementation, you'll need:
- Eluna scripting engine
- Basic Lua knowledge
- AzerothCore server setup
- Optional: mod-autobalance and mod-solocraft for dungeon systems


