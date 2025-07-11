# Traveler's Beacon System Design

## Overview
The Traveler's Beacon is a custom item system that allows players to set and recall to custom locations, similar to hearthstone but with multiple locations and scaling costs.

## Item Tiers

### Starter Traveler's Beacon (1x)
- **Item ID**: 23443
- **Name**: Starter Traveler's Beacon
- **Description**: "A simple beacon that can store 1 location. A perfect introduction to waypoint technology."
- **Level Requirement**: 1
- **Max Locations**: 1
- **Base Rune Cost**: 1 per stored location
- **Quality**: Common (White)
- **Vendor Cost**: 5 Gold

### Basic Traveler's Beacon (3x)
- **Item ID**: 800001
- **Name**: Basic Traveler's Beacon
- **Description**: "A basic beacon that can store up to 3 locations. Each stored location increases the rune cost when teleporting."
- **Level Requirement**: 15
- **Max Locations**: 3
- **Base Rune Cost**: 1 per stored location
- **Quality**: Uncommon (Green)
- **Vendor Cost**: 25 Gold

### Enhanced Traveler's Beacon (5x)
- **Item ID**: 800002
- **Name**: Enhanced Traveler's Beacon
- **Description**: "An improved beacon that can store up to 5 locations. Each stored location increases the rune cost when teleporting."
- **Level Requirement**: 30
- **Max Locations**: 5
- **Base Rune Cost**: 1 per stored location
- **Quality**: Rare (Blue)
- **Vendor Cost**: 75 Gold

### Superior Traveler's Beacon (7x)
- **Item ID**: 800003
- **Name**: Superior Traveler's Beacon
- **Description**: "A superior beacon that can store up to 7 locations. Each stored location increases the rune cost when teleporting."
- **Level Requirement**: 45
- **Max Locations**: 7
- **Base Rune Cost**: 1 per stored location
- **Quality**: Epic (Purple)
- **Vendor Cost**: 175 Gold

### Master Traveler's Beacon (10x)
- **Item ID**: 800004
- **Name**: Master Traveler's Beacon
- **Description**: "A master-crafted beacon that can store up to 10 locations. Each stored location increases the rune cost when teleporting."
- **Level Requirement**: 60
- **Max Locations**: 10
- **Base Rune Cost**: 1 per stored location
- **Quality**: Epic (Purple)
- **Vendor Cost**: 375 Gold

### Advanced Traveler's Beacon (5x Efficient)
- **Item ID**: 800005
- **Name**: Advanced Traveler's Beacon
- **Description**: "An advanced beacon with superior efficiency. Stores up to 5 locations with a fixed cost of only 1 rune."
- **Level Requirement**: 70
- **Max Locations**: 5
- **Base Rune Cost**: 1 (fixed, regardless of stored locations)
- **Quality**: Epic (Purple)
- **Vendor Cost**: 750 Gold

### Ultimate Traveler's Beacon (10x Mastery)
- **Item ID**: 800006
- **Name**: Ultimate Traveler's Beacon
- **Description**: "The pinnacle of waypoint technology. Stores up to 10 locations with a fixed cost of only 1 rune."
- **Level Requirement**: 80
- **Max Locations**: 10
- **Base Rune Cost**: 1 (fixed, regardless of stored locations)
- **Quality**: Legendary (Orange)
- **Vendor Cost**: 2500 Gold

## Mechanics

### Rune of Teleportation
- **Item ID**: 17031 (existing item)
- **Cost per Use**: 1 rune per stored location
- **Emergency Purchase**: 5x vendor cost if player has no runes

### Teleportation Properties
- **Cast Time**: 10 seconds (interruptible)
- **Cooldown**: 30 seconds
- **Rune Cost**: Equal to number of stored locations
- **Can be interrupted**: Yes (combat, movement, taking damage)

### Location Management
- **First Use**: Sets first location if no locations stored
- **Subsequent Uses**: Opens management menu with options:
  - Recall to [Location Name]
  - Set New Location
  - Clear Location
  - Manage Locations (if multiple stored)

## NPC Vendor

### Traveler's Beacon Engineer
- **NPC ID**: 800000
- **Name**: Engineer Gizmo Wayfinder
- **Subname**: Waypoint Technology Specialist
- **Location**: Manually spawned by administrators
- **Faction**: Neutral
- **Level**: 80
- **Model**: Gnome Male Engineer

### Vendor Inventory
- Starter Traveler's Beacon (1x) - 5 Gold
- Basic Traveler's Beacon (3x) - 25 Gold (requires level 15)
- Enhanced Traveler's Beacon (5x) - 75 Gold (requires level 30)
- Superior Traveler's Beacon (7x) - 175 Gold (requires level 45)
- Master Traveler's Beacon (10x) - 375 Gold (requires level 60)
- Advanced Traveler's Beacon (5x Efficient) - 750 Gold (requires level 70)
- Ultimate Traveler's Beacon (10x Mastery) - 2500 Gold (requires level 80)
- Rune of Teleportation - 50 Silver each

## Database Storage

### Custom Table: player_beacon_locations
```sql
CREATE TABLE `player_beacon_locations` (
  `guid` int(10) unsigned NOT NULL,
  `beacon_item_id` int(10) unsigned NOT NULL,
  `location_slot` tinyint(3) unsigned NOT NULL,
  `location_name` varchar(100) NOT NULL,
  `map_id` int(10) unsigned NOT NULL,
  `position_x` float NOT NULL,
  `position_y` float NOT NULL,
  `position_z` float NOT NULL,
  `orientation` float NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`,`beacon_item_id`,`location_slot`)
);
```

## User Interface Flow

### First Use (No Locations Set)
1. Player uses beacon item
2. Confirmation dialog: "Set current location as recall point?"
3. If yes: Store location, show success message
4. If no: Cancel action

### Subsequent Uses (Locations Set)
1. Player uses beacon item
2. Gossip menu appears with options:
   - "Recall to [Location Name]" (for each stored location)
   - "Set New Location" (if slots available)
   - "Manage Locations" (submenu)
   - "Cancel"

### Location Management Submenu
- "Rename Location"
- "Clear Location"
- "Set Current Location"
- "Back to Main Menu"

## Error Handling

### Insufficient Runes
- Show message: "You need [X] Runes of Teleportation to recall to your stored locations."
- Option: "Manifest Runes (Cost: [X] gold)" - 5x normal rune cost

### Location Conflicts
- If player tries to set location in invalid area (instances, battlegrounds)
- Show message: "You cannot set a beacon location in this area."

### Item Restrictions
- Can only have one beacon type active at a time
- Upgrading to higher tier beacon transfers existing locations
- Maximum of 10 locations across all beacon types

## Implementation Notes

### Cooldown Management
- Use spell cooldown system for consistency
- 30-second cooldown prevents spam
- Cooldown persists through logout/login

### Security Considerations
- Validate all location coordinates
- Check for valid maps/zones
- Prevent exploitation of instance/battleground teleports
- Rate limiting on location changes

### Performance
- Cache beacon locations in memory
- Batch database operations
- Use efficient SQL queries for location retrieval 

## New Ideas
- Dungeon Delver Beacon: Stores the entrance to all dungeons automatically. should separate continents by gossip menu's and should only allow you access to content appropriate for your level (old world, outland, etc)
- Raid Master Beacon: Stores entrance to all raids automatically.

### Upgrades
- Dimensional Rift Beacon: Opens a portal at your anchor for 30 seconds.
- Dual Anchor: Stores two locations instead of one with a shared cooldown.
- Network Beacon: Stores up to five anchors.
- 