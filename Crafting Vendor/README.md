# Crafting Materials Vendor for AzerothCore

A dynamic crafting materials vendor that shows profession-specific supplies based on the player's known professions.

## Features

- **Dynamic Profession Detection**: Only shows professions the player has learned
- **Comprehensive Material Coverage**: Includes materials from Vanilla through WotLK
- **Clean Interface**: Simple gossip menu for profession selection
- **Reliable Technology**: Uses proven static vendor inventory approach

## Supported Professions

- **Alchemy**: Herbs, vials, and reagents (19 different materials)
- **Blacksmithing**: Metal bars and flux (18 different materials) 
- **Enchanting**: Dusts, essences, and shards (18 different materials)
- **Engineering**: Bolts, powders, and components (16 different materials)
- **Tailoring**: Cloth, thread, and dyes (17 different materials)
- **Leatherworking**: Leather, hides, and thread (17 different materials)

## Installation

### 1. Database Setup
Import the SQL file into your world database:
```sql
SOURCE path/to/CraftingVendor.sql;
```

### 2. Script Installation
Copy `CraftingVendor.lua` to your server's `lua_scripts` folder.

### 3. Restart Server
Restart your worldserver to load the new script.

### 4. Spawn the Vendor
Use the following GM command to spawn the vendor:
```
.npc add 700000
```

## Usage

1. **Approach the Vendor**: Right-click the "Crafting Vendor" NPC
2. **Select Profession**: Choose from your known professions in the gossip menu
3. **Browse Materials**: The vendor window opens with profession-specific materials
4. **Purchase Items**: Buy materials as you would from any vendor

## Technical Details

### NPC Information
- **Entry ID**: 700000
- **Name**: Crafting Vendor
- **Subname**: Materials & Supplies
- **Display Model**: 19646 (Gnome merchant)

### Vendor IDs
- **700001**: Alchemy materials
- **700002**: Blacksmithing materials  
- **700003**: Enchanting materials
- **700004**: Engineering materials
- **700005**: Tailoring materials
- **700006**: Leatherworking materials

### How It Works
1. Script detects player's professions using `player:HasSkill(skillId)`
2. Gossip menu dynamically builds based on known professions
3. Player selection triggers `player:SendListInventory(creature, vendorId)`
4. Static vendor inventories provide reliable item display

## Customization

### Adding Materials
To add materials to any profession:
1. Edit the SQL file
2. Add new `npc_vendor` entries with the appropriate vendor ID
3. Reload the database

### Changing Prices
All items are sold at their default vendor prices. To customize:
1. Modify item costs in your `item_template` table, or
2. Add custom pricing via the `ExtendedCost` column in `npc_vendor`

### Adding Professions
To add new professions:
1. Add new vendor ID and materials in SQL
2. Add profession entry to `PROFESSIONS` table in Lua
3. Use correct skill ID from `SkillLine.dbc`

## Requirements

- AzerothCore with Eluna Lua engine
- Database access for SQL import
- GM access for NPC spawning

## Troubleshooting

**Vendor doesn't appear**: Check that NPC entry 700000 is available and not conflicting

**No gossip menu**: Verify Eluna is properly installed and CraftingVendor.lua is in the lua_scripts folder

**Empty vendor window**: Ensure CraftingVendor.sql was imported successfully into the world database

**Missing professions**: Check that profession skill IDs match your server's configuration 