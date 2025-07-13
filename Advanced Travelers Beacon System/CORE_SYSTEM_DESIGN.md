# Traveler's Beacon System - Core Design Document

## 🎯 **Core Vision**

Create a **teleportation and portal system** that makes travel across Azeroth much more friendly for players. The system starts simple and grows with player progression, eventually expanding into portal creation and dungeon/raid access.

---

## 🏗️ **Core System Requirements**

### **Base Functionality**
- **One beacon item** that stores recall locations
- **Open world teleportation** to almost any location in Azeroth
- **Restricted areas:** Cannot teleport to PvP battlegrounds, inside dungeons, arenas, raids
- **Progressive upgrades** that add more location slots as players level

### **Upgrade Progression**
- **Level-based upgrades** at key progression points (20, 40, etc.)
- **Capacity expansion** through upgrade mechanic or direct item replacement
- **Advanced features** unlocked at higher levels (portals, dungeon access)

---

## 🎮 **Recommended Implementation**

### **Beacon Capacity Tiers**

| Tier | Name | Level Req | Max Locations | Upgrade Cost |
|------|------|-----------|---------------|--------------|
| 1 | **Traveler's Beacon** | 1 | 1 | Starting item |
| 2 | **Dual Anchor Beacon** | 20 | 2 | Expensive |
| 3 | **Travel Network Beacon** | 40 | 5 | Very Expensive |
| 4 | **Master's Travel Beacon** | 60 | 10 | Extremely Expensive |

### **Functionality Upgrades** *(Independent of Capacity)*

| Upgrade | Availability | Requirements | Features |
|---------|-------------|--------------|----------|
| **Portal Casting** | Level 30 | Mage Portal Level + 10 | Create portals for others |
| **Dungeon Access** | Level 15 | Entry-level dungeons | Teleport to visited dungeons |
| **Raid Access** | Level 60 | End-game content | Teleport to visited raids |
| **Capital Networks** | Level 25 | Cross-faction access | Instant teleports to all major cities |
| **World Events** | Level 35 | Seasonal content | Access to event-specific locations |

### **Two-Path Upgrade System**

#### **Path 1: Capacity Upgrades** *(Expensive, Level-Gated)*
- **Item replacement system:** Buy new beacon, locations transfer automatically
- **High cost barriers:** Significant gold investment required
- **Level gates:** Must reach minimum level to purchase
- **Name changes:** Beacon name reflects current capacity tier

#### **Path 2: Functionality Upgrades** *(Moderate Cost, Early Access)*
- **Add-on system:** Upgrades apply to any capacity beacon
- **Lower level requirements:** Available much earlier than capacity upgrades
- **Beacon name unchanged:** Functionality doesn't affect beacon naming
- **Stackable:** Can have multiple functionality upgrades on one beacon

### **Feature Progression Examples**

#### **Level 15 Player with Traveler's Beacon (1 location)**
- Can purchase **Dungeon Access** upgrade
- Beacon name remains "Traveler's Beacon"
- Now has: 1 manual location + dungeon teleports

#### **Level 30 Player with Dual Anchor Beacon (2 locations)**
- Can purchase **Portal Casting** upgrade
- Beacon name remains "Dual Anchor Beacon"  
- Now has: 2 manual locations + portal creation

#### **Level 60 Player with Travel Network Beacon (5 locations)**
- Can have **multiple functionality upgrades**: Portal + Dungeon + Raid + Capital Networks + World Events
- Beacon name remains "Travel Network Beacon"
- Feature set: 5 manual locations + portals + instance access + capitals + events

#### **Level 70 Player with Master's Travel Beacon (10 locations)**
- Can have **all functionality upgrades**: Portal + Dungeon + Raid + Capital + Events
- Beacon name: "Master's Travel Beacon"
- Full feature set: 10 manual locations + all advanced functionality

---

## 💰 **Resource Management**

### **Simple Reagent + Cooldown System**
- **Dual reagent type:** "Traveler's Mark" or similar for Teleports, "Portal Mark" or simsilar for portal creation
- **Cost scaling:** 1 rune per use
- **Vendor availability:** Purchasable from beacon vendor
- **Reasonable pricing:** ~50 silver per Mark, stackable to 200
- **Cooldown-based:** 15 minute cooldown per use

---

## 🗂️ **Database Design**

### **Core Tables**

#### **Player Beacon Progress**
```sql
CREATE TABLE player_beacon_progress (
  guid INT UNSIGNED PRIMARY KEY,
  beacon_tier TINYINT UNSIGNED DEFAULT 1,
  has_portal_upgrade BOOLEAN DEFAULT FALSE,
  has_dungeon_upgrade BOOLEAN DEFAULT FALSE,
  has_raid_upgrade BOOLEAN DEFAULT FALSE,
  has_capital_upgrade BOOLEAN DEFAULT FALSE,
  has_events_upgrade BOOLEAN DEFAULT FALSE,
  last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### **Beacon Locations**
```sql
CREATE TABLE player_beacon_locations (
  guid INT UNSIGNED,
  location_slot TINYINT UNSIGNED,
  location_name VARCHAR(100),
  map_id INT UNSIGNED,
  position_x FLOAT,
  position_y FLOAT,
  position_z FLOAT,
  orientation FLOAT,
  location_type ENUM('manual', 'dungeon', 'raid') DEFAULT 'manual',
  PRIMARY KEY (guid, location_slot)
);
```

#### **Instance Discovery** *(For Tier 5)*
```sql
CREATE TABLE player_instance_discovery (
  guid INT UNSIGNED,
  map_id INT UNSIGNED,
  instance_type ENUM('dungeon', 'raid'),
  first_entered TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (guid, map_id)
);
```

---

## ✨ **Functionality Upgrade Details**

### **Capital Networks** *(Level 25)*
- **Instant access** to all major capital cities (Stormwind, Orgrimmar, Ironforge, etc.)
- **Cross-faction availability** for neutral characters
- **Separate menu section** with organized city listings
- **No discovery requirement** - all capitals available immediately

### **World Events** *(Level 35)*
- **Seasonal locations** during active world events (Darkmoon Faire, seasonal events)
- **Event-specific teleports** to holiday locations (Hallow's End, Winter Veil areas)
- **Dynamic availability** - only shows active event locations
- **Auto-updates** when events start/end

---

## 🎮 **User Experience Flow**

### **Setting Locations**
1. **First use:** Open menu that explains the portals, available upgrades at what levels, etc. Prompt to store first location
2. **Additional locations:** Menu option "Set New Location" 
3. **Location naming:** Auto-generate from zone/area name
4. **Slot management:** Simple list with clear/rename options

### **Teleportation Process**
1. **Use beacon item** → Gossip menu opens
2. **Select destination** from saved locations
3. **Cast time:** 3-5 seconds (interruptible) using evocation animation and timing bar
4. **Teleport** to saved coordinates

### **Portal Creation**
1. **Menu option:** "Create Portal to [Location]"
2. **Reagent check:** Confirm portal stone availability
3. **Casting time:** 8-10 seconds
4. **Portal spawn:** 60-second duration, usable by party/raid

### **Instance Access**
1. **Separate menu section:** "Dungeon Entrances" / "Raid Entrances"
2. **Discovery display:** Show only visited instances that have been entered at least once. 
3. **Expansion filtering:** Group by content (Classic, BC, WotLK)
4. **Location Name:** should include instance name, zone, and recommended level

---

## 🛡️ **Safety & Restrictions**

### **Location Restrictions**
- **Blocked areas:** Battlegrounds, arenas, instance interiors
- **Coordinate validation:** Prevent exploitation or invalid locations
- **Combat protection:** Cannot use while in combat

### **Balance Considerations**
- **Cooldowns:** Prevent rapid teleportation spam
- **Level restrictions:** Higher tiers locked behind progression
- **Resource costs:** Reagents or cooldowns provide limitation

---

## 🔧 **Implementation Phases**

### **Phase 1: Core System** *(MVP)*
- All 4 beacon capacity tiers (Traveler's → Master's Travel)
- Basic teleportation and location storage
- Capacity upgrade system (expensive, level-gated)

### **Phase 2: Basic Functionality Upgrades** *(Enhancement)*
- Portal casting upgrade (Level 30+)
- Dungeon access upgrade (Level 15+)
- Capital Networks upgrade (Level 25+)
- Independent upgrade system from capacity

### **Phase 3: Advanced Functionality** *(Advanced)*
- Raid access upgrade (Level 60+)
- World Events upgrade (Level 35+)
- Instance discovery tracking
- Complete two-path upgrade system

---

## 📊 **Technical Recommendations**

### **Performance**
- **Cache player locations** in memory during session
- **Efficient database queries** with proper indexing
- **Batch operations** for location management

### **Security**
- **Validate all coordinates** before teleportation
- **Check map permissions** to prevent invalid teleports
- **Rate limiting** to prevent exploitation

### **Maintainability**
- **Modular design:** Each tier builds on previous functionality
- **Clear separation:** Core teleportation vs. advanced features
- **Configuration-driven:** Easy to adjust costs, restrictions, etc.

---

## 🎯 **Success Metrics**

### **Player Experience**
- **Reduced travel time** for daily activities
- **Increased exploration** with safe return points
- **Progression satisfaction** through beacon upgrades

### **System Health**
- **Balanced usage:** Not replacing all travel methods
- **Economic impact:** Reasonable reagent economy
- **Technical stability:** No performance issues or exploits

---

## 📋 **Current Implementation Status**

### **Phase 1: Core System** - ✅ **COMPLETE (100%)**
- ✅ All 4 beacon capacity tiers implemented (Traveler's → Master's Travel)
- ✅ Basic teleportation and location storage working
- ✅ Capacity upgrade system functional (expensive, level-gated)
- ✅ Location transfer between beacon tiers working
- ✅ Upgrade NPC with capacity upgrade menus
- ✅ Database integration for beacon locations
- ✅ Cooldown and reagent system operational

### **Phase 2: Basic Functionality Upgrades** - 🔄 **IN PROGRESS (10%)**
- ✅ Functionality upgrade menu framework created
- ✅ Capital Networks upgrade planned (Level 25+)
- ⏳ Portal casting upgrade (Level 30+) - **NEXT PRIORITY**
- ⏳ Dungeon access upgrade (Level 15+) - **NEXT PRIORITY**
- ⏳ Database table for player_beacon_functionality
- ⏳ Independent upgrade system implementation

### **Phase 3: Advanced Functionality** - ⏳ **NOT STARTED (0%)**
- ⏳ Raid access upgrade (Level 60+)
- ⏳ World Events upgrade (Level 35+)
- ⏳ Instance discovery tracking
- ⏳ Complete two-path upgrade system integration

### **Overall Progress: ~35% Complete**

---

## 🎯 **Remaining Tasks**

### **Immediate Priority (Next Session)**
1. **Implement player_beacon_functionality database table** COMPLETE
   - Track which functionality upgrades each player has purchased
   - Add upgrade purchase/validation logic

2. **Capital Networks Functionality** COMPLETE
   - Create instant teleport menu for all major cities
   - Add separate menu section for capital city access
   - Implement cross-faction availability

3. **Portal Casting Upgrade**
   - Add portal creation menu options
   - Implement portal stone reagent consumption
   - Create portal objects with proper duration/mechanics

4. **Dungeon Access Upgrade**
   - Add instance discovery tracking
   - Create dungeon entrance teleportation menu
   - Implement discovery-based availability

### **Medium Priority**
1. **Raid Access System**
   - Extend dungeon system to raid entrances
   - Add raid-specific discovery mechanics

2. **World Events Integration**
   - Add seasonal location tracking
   - Implement dynamic event-based availability

3. **Polish and Optimization**
   - Remove debug output
   - Performance optimization
   - Error handling improvements
   - npc_text and menu description optimization
   - polish animations, add animations to upgrades being performed, etc.
   - cleanup flavortext (remove mystical etc)
   - add cooldown animation if possible
   - text limitations and usage (can't use in dalaran right now ... need to test combat, etc)

---

## 🛠️ **Technical Implementation Details: Gossip System**

### **Event Registration (Lines 868-869)**
```lua
RegisterCreatureGossipEvent(UPGRADE_NPC_ID, 1, OnUpgradeNPCGossip)      -- Event 1: Menu Open
RegisterCreatureGossipEvent(UPGRADE_NPC_ID, 2, OnUpgradeNPCGossipSelect) -- Event 2: Option Select
```

### **Gossip Handler Functions (Lines 429-662)**

#### **OnUpgradeNPCGossip (Event 1 - Menu Open)**
- **Purpose:** Called when player first clicks the NPC
- **Function:** Sets up the initial menu with main options
- **Return Value:** No explicit return (implicit `return nil`)
- **Key Actions:**
  - `player:GossipClearMenu()` - Clears any existing menu
  - `player:GossipMenuAddItem()` - Adds menu options with intids
  - `player:GossipSendMenu()` - Displays the menu to player

#### **OnUpgradeNPCGossipSelect (Event 2 - Option Select)**
- **Purpose:** Called when player selects a menu option
- **Function:** Routes player selection to appropriate submenu or action
- **Return Value:** **CRITICAL** - Controls gossip menu behavior

### **CRITICAL: Return Value Behavior**

#### **`return true`** - Keep Gossip Menu System Active
- **Use Case:** When showing submenus or navigating between menus
- **Effect:** Gossip system remains active, allowing further menu interactions
- **Examples:**
  - `intid == 2000` (Show capacity upgrade menu) → `return true`
  - `intid == 3000` (Show functionality menu) → `return true`
  - `intid == 4000` (Back to main menu) → `return true`

#### **`return false`** - Close Gossip Menu System
- **Use Case:** When completing transactions or final actions
- **Effect:** Gossip system closes, player returns to normal gameplay
- **Examples:**
  - `intid >= 6001 and intid <= 6003` (Perform upgrade) → `return false`
  - `intid == 9999` (Close/Cancel) → `return false`

#### **`player:GossipComplete()`** - Force Close Current Menu
- **Purpose:** Immediately terminates the gossip interaction
- **Usage:** Called before `return false` when transaction is complete. Do NOT call with return true in the menu system
- **Effect:** Ensures clean menu closure and prevents ghost menus

### **Common Debugging Issues**
1. **Wrong Return Values:** Using `return false` when showing submenus causes menu to close unexpectedly
2. **Missing GossipComplete():** Forgetting to call before final `return false` can leave menu in inconsistent state
3. **Inconsistent Return Patterns:** Mixing return types within same function flow causes unpredictable behavior

**The debugging session revealed that incorrect return values were causing the upgrade menu to close prematurely instead of processing the upgrade selection, which took extensive debugging to identify.**

---

## 🔄 **Future Expansion Ideas**

### **Guild Features**
- **Shared beacon networks** for guild members
- **Guild hall integration** with dedicated beacon access
- **Guild-only locations** for officers and leaders

### **PvP Integration**
- **Battleground preparation areas** (outside instance boundaries)
- **Arena tournament locations** for organized events
- **PvP-specific reagent costs** for balance

---

## 📋 **Implementation Checklist**

- [ ] Create 4 beacon capacity items (Traveler's/Dual Anchor/Travel Network/Master's Travel)
- [ ] Design vendor NPC and upgrade system
- [ ] Implement core database tables with all functionality tracking
- [ ] Code basic teleportation system with dual reagent support
- [ ] Add location management interface with evocation animation
- [ ] Implement capacity upgrade mechanics (expensive, level-gated)
- [ ] Create basic functionality upgrades (Portal/Dungeon/Capital Networks)
- [ ] Add advanced functionality upgrades (Raid/World Events)
- [ ] Add instance discovery tracking with detailed location names
- [ ] Testing and balance refinement for complete two-path system

---

This design focuses on **simplicity and progression** while maintaining the flexibility to grow into more advanced features. The system starts friendly for new players and rewards progression with meaningful upgrades. 