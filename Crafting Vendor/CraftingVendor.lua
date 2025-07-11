-- Crafting Materials Vendor for AzerothCore
-- Shows profession-specific materials based on player's known professions
-- Uses Eluna vendor management functions for proper cache handling

local VENDOR_NPC = 700000

-- Rotation system configuration
local ROTATION_INTERVAL = 900 -- 15 minutes in seconds
local ITEMS_PER_TIER = 8 -- How many items to show per unlocked tier

-- Profession skill IDs and their skill-based item tiers
local PROFESSIONS = {
    {
        skillId = 171, 
        name = "Alchemy", 
        tiers = {
            {
                name = "Apprentice",
                minSkill = 1,
                maxSkill = 75,
                items = {
                    765,   -- Silverleaf
                    2447,  -- Peacebloom
                    2449,  -- Earthroot
                    2450,  -- Briarthorn
                    3371,  -- Crystal Vial
                    10648, -- Blank Vial
                    3372,  -- Leaded Vial
                    159,   -- Refreshing Spring Water
                    1179,  -- Ice Cold Milk
                    2880,  -- Weak Flux
                    4289,  -- Salt
                    2320,  -- Coarse Thread
                    4340   -- Gray Dye
                }
            },
            {
                name = "Journeyman",
                minSkill = 75,
                maxSkill = 150,
                items = {
                    785,   -- Mageroyal
                    2453,  -- Bruiseweed
                    3820,  -- Stranglekelp
                    3355,  -- Wild Steelbloom
                    3821,  -- Goldthorn
                    3466,  -- Strong Flux
                    2321,  -- Fine Thread
                    4342,  -- Purple Dye
                    2604,  -- Red Dye
                    6260,  -- Blue Dye
                    2605   -- Green Dye
                }
            },
            {
                name = "Expert",
                minSkill = 150,
                maxSkill = 225,
                items = {
                    3356,  -- Kingsblood
                    3357,  -- Liferoot
                    8838,  -- Sungrass
                    8839,  -- Blindweed
                    8845,  -- Ghost Mushroom
                    8846,  -- Gromsblood
                    3358,  -- Khadgar's Whisker
                    8836,  -- Arthas' Tears
                    8153,  -- Wildvine
                    8343,  -- Heavy Silken Thread
                    4291   -- Silken Thread
                }
            },
            {
                name = "Artisan",
                minSkill = 225,
                maxSkill = 300,
                items = {
                    13463, -- Dreamfoil
                    13464, -- Golden Sansam
                    13465, -- Mountain Silversage
                    13466, -- Sorrowmoss
                    13467, -- Icecap
                    13468, -- Black Lotus
                    7068,  -- Elemental Fire
                    7080,  -- Essence of Water
                    7081,  -- Breath of Wind
                    12808, -- Essence of Undeath
                    14341, -- Rune Thread
                    18567  -- Elemental Flux
                }
            },
            {
                name = "Master",
                minSkill = 300,
                maxSkill = 375,
                items = {
                    22785, -- Felweed
                    22786, -- Dreaming Glory
                    22787, -- Ragveil
                    22789, -- Terocone
                    22790, -- Ancient Lichen
                    22791, -- Netherbloom
                    22792  -- Nightmare Vine
                }
            },
            {
                name = "Grand Master",
                minSkill = 375,
                maxSkill = 450,
                items = {
                    36901, -- Goldclover
                    36903, -- Adder's Tongue
                    36904, -- Tiger Lily
                    36905, -- Lichbloom
                    36906, -- Icethorn
                    39970, -- Fire Leaf
                    37921  -- Deadnettle
                }
            }
        }
    },
    {
        skillId = 164, 
        name = "Blacksmithing", 
        tiers = {
            {
                name = "Apprentice",
                minSkill = 1,
                maxSkill = 75,
                items = {
                    2840,  -- Copper Bar
                    3576,  -- Tin Bar
                    2841,  -- Bronze Bar
                    2842,  -- Silver Bar
                    2835,  -- Rough Stone
                    2836,  -- Coarse Stone
                    2880,  -- Weak Flux
                    2320,  -- Coarse Thread
                    2321,  -- Fine Thread
                    2901,  -- Mining Pick
                    6217,  -- Copper Rod
                    2318   -- Light Leather
                }
            },
            {
                name = "Journeyman",
                minSkill = 75,
                maxSkill = 150,
                items = {
                    3575,  -- Iron Bar
                    3859,  -- Steel Bar
                    3577,  -- Gold Bar
                    2838,  -- Heavy Stone
                    7912,  -- Solid Stone
                    2836,  -- Coarse Stone
                    3466,  -- Strong Flux
                    4234,  -- Heavy Leather
                    2319,  -- Medium Leather
                    6339,  -- Runed Silver Rod
                    11128, -- Golden Rod
                    3914   -- Journeyman's Backpack
                }
            },
            {
                name = "Expert",
                minSkill = 150,
                maxSkill = 225,
                items = {
                    3860,  -- Mithril Bar
                    6037,  -- Truesilver Bar
                    7966,  -- Solid Grinding Stone
                    4304,  -- Thick Leather
                    8170,  -- Rugged Leather
                    1705,  -- Lesser Moonstone
                    1206,  -- Moss Agate
                    3864,  -- Citrine
                    7909,  -- Aquamarine
                    7910,  -- Star Ruby
                    12800, -- Azerothian Diamond
                    11145  -- Runed Golden Rod
                }
            },
            {
                name = "Artisan",
                minSkill = 225,
                maxSkill = 300,
                items = {
                    12359, -- Thorium Bar
                    12655, -- Enchanted Thorium Bar
                    12360, -- Arcanite Bar
                    12365, -- Dense Stone
                    18567, -- Elemental Flux
                    12808, -- Essence of Undeath
                    12803, -- Living Essence
                    7076,  -- Essence of Earth
                    7077,  -- Heart of Fire
                    16206, -- Arcanite Rod
                    12361, -- Blue Sapphire
                    12799  -- Large Opal
                }
            },
            {
                name = "Master",
                minSkill = 300,
                maxSkill = 375,
                items = {
                    23424, -- Fel Iron Bar
                    23425, -- Adamantite Bar
                    23426, -- Khorium Bar
                    23449, -- Khorium Ore
                    21884, -- Primal Fire
                    21885, -- Primal Water
                    21886, -- Primal Life
                    32227  -- Primal Nether
                }
            },
            {
                name = "Grand Master",
                minSkill = 375,
                maxSkill = 450,
                items = {
                    36916, -- Cobalt Bar
                    36913, -- Saronite Bar
                    36910, -- Titanium Bar
                    41163, -- Titanium Powder
                    36926, -- Eternal Fire
                    36860, -- Eternal Water
                    35624, -- Eternal Earth
                    35627  -- Eternal Shadow
                }
            }
        }
    },
    {
        skillId = 333, 
        name = "Enchanting", 
        tiers = {
            {
                name = "Apprentice",
                minSkill = 1,
                maxSkill = 75,
                items = {
                    10940, -- Strange Dust
                    10938, -- Lesser Magic Essence
                    10939, -- Greater Magic Essence
                    10978, -- Small Glimmering Shard
                    6217,  -- Copper Rod
                    6218,  -- Runed Copper Rod
                    2589,  -- Linen Cloth
                    2320   -- Coarse Thread
                }
            },
            {
                name = "Journeyman",
                minSkill = 75,
                maxSkill = 150,
                items = {
                    11137, -- Vision Dust
                    11134, -- Lesser Astral Essence
                    11135, -- Greater Astral Essence
                    11084, -- Large Glimmering Shard
                    6339,  -- Runed Silver Rod
                    2592,  -- Wool Cloth
                    4306,  -- Silk Cloth
                    2321   -- Fine Thread
                }
            },
            {
                name = "Expert",
                minSkill = 150,
                maxSkill = 225,
                items = {
                    16204, -- Illusion Dust
                    16202, -- Lesser Eternal Essence
                    16203, -- Greater Eternal Essence
                    14343, -- Small Brilliant Shard
                    11145, -- Runed Golden Rod
                    4338,  -- Mageweave Cloth
                    8343,  -- Heavy Silken Thread
                    11174  -- Lesser Nether Essence
                }
            },
            {
                name = "Artisan",
                minSkill = 225,
                maxSkill = 300,
                items = {
                    16204, -- Illusion Dust
                    16202, -- Lesser Eternal Essence
                    16203, -- Greater Eternal Essence
                    14343, -- Small Brilliant Shard
                    16206, -- Arcanite Rod
                    14047, -- Runecloth
                    14341, -- Rune Thread
                    20725  -- Nexus Crystal
                }
            },
            {
                name = "Master",
                minSkill = 300,
                maxSkill = 375,
                items = {
                    22445, -- Arcane Dust
                    22447, -- Lesser Planar Essence
                    22446, -- Greater Planar Essence
                    22449, -- Large Prismatic Shard
                    22463, -- Void Crystal
                    22461, -- Runed Fel Iron Rod
                    21877, -- Netherweave Cloth
                    24271  -- Spellcloth
                }
            },
            {
                name = "Grand Master",
                minSkill = 375,
                maxSkill = 450,
                items = {
                    34054, -- Infinite Dust
                    34055, -- Lesser Cosmic Essence
                    34056, -- Greater Cosmic Essence
                    34057, -- Abyss Crystal
                    34052, -- Dream Shard
                    41146, -- Runed Titanium Rod
                    33470, -- Frostweave Cloth
                    38426  -- Eternium Thread
                }
            }
        }
    },
    {
        skillId = 202, 
        name = "Engineering", 
        tiers = {
            {
                name = "Apprentice",
                minSkill = 1,
                maxSkill = 75,
                items = {
                    4359,  -- Handful of Copper Bolts
                    4361,  -- Copper Tube
                    4357,  -- Rough Blasting Powder
                    4364,  -- Coarse Blasting Powder
                    2840,  -- Copper Bar
                    3576,  -- Tin Bar
                    2841,  -- Bronze Bar
                    2880,  -- Weak Flux
                    2589,  -- Linen Cloth
                    2320,  -- Coarse Thread
                    4306,  -- Silk Cloth
                    2592   -- Wool Cloth
                }
            },
            {
                name = "Journeyman",
                minSkill = 75,
                maxSkill = 150,
                items = {
                    4371,  -- Bronze Tube
                    4377,  -- Heavy Blasting Powder
                    4382,  -- Bronze Framework
                    4404,  -- Silver Contact
                    4365,  -- Coarse Dynamite
                    2841,  -- Bronze Bar
                    3575,  -- Iron Bar
                    2842,  -- Silver Bar
                    2592,  -- Wool Cloth
                    4234,  -- Heavy Leather
                    3466,  -- Strong Flux
                    4338   -- Mageweave Cloth
                }
            },
            {
                name = "Expert",
                minSkill = 150,
                maxSkill = 225,
                items = {
                    4389,  -- Gyromatic Micro-Adjustor
                    7191,  -- Fused Wiring
                    4394,  -- Big Iron Bomb
                    9060,  -- Inlaid Mithril Cylinder
                    4390,  -- Iron Grenade
                    4387,  -- Iron Strut
                    3860,  -- Mithril Bar
                    6037,  -- Truesilver Bar
                    4338,  -- Mageweave Cloth
                    4304,  -- Thick Leather
                    7912,  -- Solid Stone
                    18567  -- Elemental Flux
                }
            },
            {
                name = "Artisan",
                minSkill = 225,
                maxSkill = 300,
                items = {
                    15992, -- Dense Blasting Powder
                    16000, -- Thorium Widget
                    15994, -- Thorium Widget
                    16006, -- Delicate Arcanite Converter
                    15417, -- Devilsaur Leather
                    12359, -- Thorium Bar
                    12360, -- Arcanite Bar
                    14047, -- Runecloth
                    8170,  -- Rugged Leather
                    12365, -- Dense Stone
                    7076,  -- Essence of Earth
                    7077   -- Heart of Fire
                }
            },
            {
                name = "Master",
                minSkill = 300,
                maxSkill = 375,
                items = {
                    23781, -- Elemental Blasting Powder
                    23782, -- Fel Iron Casing
                    23783, -- Handful of Fel Iron Bolts
                    23784, -- Adamantite Frame
                    23424, -- Fel Iron Bar
                    23425, -- Adamantite Bar
                    21877, -- Netherweave Cloth
                    25699  -- Crystal Infused Leather
                }
            },
            {
                name = "Grand Master",
                minSkill = 375,
                maxSkill = 450,
                items = {
                    39681, -- Handful of Cobalt Bolts
                    39682, -- Overcharged Capacitor
                    39683, -- Froststeel Tube
                    44499, -- Volatile Blasting Trigger
                    36916, -- Cobalt Bar
                    36913, -- Saronite Bar
                    33470, -- Frostweave Cloth
                    38425  -- Heavy Borean Leather
                }
            }
        }
    },
    {
        skillId = 773, 
        name = "Inscription", 
        tiers = {
            {
                name = "Apprentice",
                minSkill = 1,
                maxSkill = 75,
                items = {
                    39354, -- Light Parchment
                    39469, -- Moonglow Ink
                    39151, -- Alabaster Pigment
                    39334, -- Dusky Pigment
                    2447,  -- Peacebloom
                    765,   -- Silverleaf
                    2449,  -- Earthroot
                    785,   -- Mageroyal
                    3371,  -- Crystal Vial
                    2880,  -- Weak Flux
                    2320,  -- Coarse Thread
                    159    -- Refreshing Spring Water
                }
            },
            {
                name = "Journeyman",
                minSkill = 75,
                maxSkill = 150,
                items = {
                    39354, -- Light Parchment
                    39774, -- Midnight Ink
                    39338, -- Golden Pigment
                    39339, -- Emerald Pigment
                    2453,  -- Bruiseweed
                    3820,  -- Stranglekelp
                    2450,  -- Briarthorn
                    3355,  -- Wild Steelbloom
                    3821,  -- Goldthorn
                    3466,  -- Strong Flux
                    2321,  -- Fine Thread
                    1179   -- Ice Cold Milk
                }
            },
            {
                name = "Expert",
                minSkill = 150,
                maxSkill = 225,
                items = {
                    43230, -- Resilient Parchment
                    37101, -- Ivory Ink
                    43125, -- Verdant Pigment
                    43126, -- Burnt Pigment
                    3356,  -- Kingsblood
                    3357,  -- Liferoot
                    8838,  -- Sungrass
                    8839,  -- Blindweed
                    3358,  -- Khadgar's Whisker
                    8836,  -- Arthas' Tears
                    8343,  -- Heavy Silken Thread
                    4291   -- Silken Thread
                }
            },
            {
                name = "Artisan",
                minSkill = 225,
                maxSkill = 300,
                items = {
                    43230, -- Resilient Parchment
                    43122, -- Shimmering Ink
                    43127, -- Indigo Pigment
                    43128, -- Ruby Pigment
                    13463, -- Dreamfoil
                    13464, -- Golden Sansam
                    13465, -- Mountain Silversage
                    13466, -- Sorrowmoss
                    13467, -- Icecap
                    13468, -- Black Lotus
                    14341, -- Rune Thread
                    18567  -- Elemental Flux
                }
            },
            {
                name = "Master",
                minSkill = 300,
                maxSkill = 375,
                items = {
                    43230, -- Resilient Parchment
                    43124, -- Ethereal Ink
                    39340, -- Violet Pigment
                    39341, -- Silvery Pigment
                    22785, -- Felweed
                    22786, -- Dreaming Glory
                    22787, -- Ragveil
                    22789  -- Terocone
                }
            },
            {
                name = "Grand Master",
                minSkill = 375,
                maxSkill = 450,
                items = {
                    43230, -- Resilient Parchment
                    43126, -- Darkflame Ink
                    43107, -- Sapphire Pigment
                    39342, -- Nether Pigment
                    36901, -- Goldclover
                    36903, -- Adder's Tongue
                    36904, -- Tiger Lily
                    36905  -- Lichbloom
                }
            }
        }
    },
    {
        skillId = 755, 
        name = "Jewelcrafting", 
        tiers = {
            {
                name = "Apprentice",
                minSkill = 1,
                maxSkill = 75,
                items = {
                    2835,  -- Rough Stone
                    2836,  -- Coarse Stone
                    774,   -- Malachite
                    818,   -- Tigerseye
                    1210,  -- Shadowgem
                    1529,  -- Jade
                    1206,  -- Moss Agate
                    20815, -- Jeweler's Kit
                    2840,  -- Copper Bar
                    2842,  -- Silver Bar
                    2880,  -- Weak Flux
                    2320   -- Coarse Thread
                }
            },
            {
                name = "Journeyman",
                minSkill = 75,
                maxSkill = 150,
                items = {
                    2838,  -- Heavy Stone
                    1705,  -- Lesser Moonstone
                    1206,  -- Moss Agate
                    3864,  -- Citrine
                    7909,  -- Aquamarine
                    7910,  -- Star Ruby
                    1645,  -- Moonstone
                    3575,  -- Iron Bar
                    3577,  -- Gold Bar
                    3466,  -- Strong Flux
                    2321,  -- Fine Thread
                    5500   -- Iridescent Pearl
                }
            },
            {
                name = "Expert",
                minSkill = 150,
                maxSkill = 225,
                items = {
                    7912,  -- Solid Stone
                    12800, -- Azerothian Diamond
                    12799, -- Large Opal
                    12361, -- Blue Sapphire
                    1705,  -- Lesser Moonstone
                    7971,  -- Black Pearl
                    12362, -- Windfury Totem
                    3860,  -- Mithril Bar
                    6037,  -- Truesilver Bar
                    18567, -- Elemental Flux
                    8343,  -- Heavy Silken Thread
                    7076   -- Essence of Earth
                }
            },
            {
                name = "Artisan",
                minSkill = 225,
                maxSkill = 300,
                items = {
                    12365, -- Dense Stone
                    12800, -- Azerothian Diamond
                    12364, -- Huge Emerald
                    12363, -- Arcane Crystal
                    21752, -- Thorium Setting
                    12359, -- Thorium Bar
                    12360, -- Arcanite Bar
                    7076,  -- Essence of Earth
                    7077,  -- Heart of Fire
                    7080,  -- Essence of Water
                    14341, -- Rune Thread
                    12803  -- Living Essence
                }
            },
            {
                name = "Master",
                minSkill = 300,
                maxSkill = 375,
                items = {
                    23077, -- Blood Garnet
                    23079, -- Deep Peridot
                    23112, -- Golden Draenite
                    23117, -- Azure Moonstone
                    23436, -- Living Ruby
                    23437, -- Talasite
                    23438, -- Star of Elune
                    23439, -- Noble Topaz
                    23440, -- Dawnstone
                    23441, -- Nightseye
                    23424, -- Fel Iron Bar
                    23425  -- Adamantite Bar
                }
            },
            {
                name = "Grand Master",
                minSkill = 375,
                maxSkill = 450,
                items = {
                    36917, -- Bloodstone
                    36923, -- Chalcedony
                    36924, -- Sky Sapphire
                    36929, -- Huge Citrine
                    36930, -- Dark Jade
                    36932, -- Shadow Crystal
                    41163, -- Titanium Powder
                    36916, -- Cobalt Bar
                    36913, -- Saronite Bar
                    36910  -- Titanium Bar
                }
            }
        }
    },
    {
        skillId = 197, 
        name = "Tailoring", 
        tiers = {
            {
                name = "Apprentice",
                minSkill = 1,
                maxSkill = 75,
                items = {
                    2589,  -- Linen Cloth
                    2320,  -- Coarse Thread
                    2604,  -- Red Dye
                    6260,  -- Blue Dye
                    4340,  -- Gray Dye
                    2605,  -- Green Dye
                    4341,  -- Yellow Dye
                    159    -- Refreshing Spring Water
                }
            },
            {
                name = "Journeyman",
                minSkill = 75,
                maxSkill = 150,
                items = {
                    2592,  -- Wool Cloth
                    2321,  -- Fine Thread
                    4306,  -- Silk Cloth
                    4291,  -- Silken Thread
                    4342,  -- Purple Dye
                    10290, -- Pink Dye
                    6261,  -- Orange Dye
                    6362   -- Raw Rockscale Cod
                }
            },
            {
                name = "Expert",
                minSkill = 150,
                maxSkill = 225,
                items = {
                    4338,  -- Mageweave Cloth
                    8343,  -- Heavy Silken Thread
                    4234,  -- Heavy Leather
                    8170,  -- Rugged Leather
                    8153,  -- Wildvine
                    14256, -- Felcloth
                    7067,  -- Elemental Earth
                    7068   -- Elemental Fire
                }
            },
            {
                name = "Artisan",
                minSkill = 225,
                maxSkill = 300,
                items = {
                    14047, -- Runecloth
                    14341, -- Rune Thread
                    14256, -- Felcloth
                    14227, -- Ironweb Spider Silk
                    7080,  -- Essence of Water
                    7081,  -- Breath of Wind
                    12662, -- Demonic Rune
                    7972   -- Ichor of Undeath
                }
            },
            {
                name = "Master",
                minSkill = 300,
                maxSkill = 375,
                items = {
                    21877, -- Netherweave Cloth
                    21881, -- Netherweb Spider Silk
                    24271, -- Spellcloth
                    21845, -- Primal Water
                    21884, -- Primal Fire
                    21885, -- Primal Life
                    22572, -- Mote of Air
                    22573  -- Mote of Earth
                }
            },
            {
                name = "Grand Master",
                minSkill = 375,
                maxSkill = 450,
                items = {
                    33470, -- Frostweave Cloth
                    38426, -- Eternium Thread
                    33567, -- Borean Leather Scraps
                    41593, -- Ebonweave
                    41594, -- Moonshroud
                    36860, -- Eternal Water
                    36926, -- Eternal Fire
                    35624  -- Eternal Earth
                }
            }
        }
    },
    {
        skillId = 165, 
        name = "Leatherworking", 
        tiers = {
            {
                name = "Apprentice",
                minSkill = 1,
                maxSkill = 75,
                items = {
                    2934,  -- Ruined Leather Scraps
                    2318,  -- Light Leather
                    783,   -- Light Hide
                    2320,  -- Coarse Thread
                    4289,  -- Salt
                    2880,  -- Weak Flux
                    159,   -- Refreshing Spring Water
                    4340   -- Gray Dye
                }
            },
            {
                name = "Journeyman",
                minSkill = 75,
                maxSkill = 150,
                items = {
                    2319,  -- Medium Leather
                    4232,  -- Medium Hide
                    4234,  -- Heavy Leather
                    2321,  -- Fine Thread
                    4291,  -- Silken Thread
                    2604,  -- Red Dye
                    6260,  -- Blue Dye
                    4342   -- Purple Dye
                }
            },
            {
                name = "Expert",
                minSkill = 150,
                maxSkill = 225,
                items = {
                    4304,  -- Thick Leather
                    4235,  -- Heavy Hide
                    8343,  -- Heavy Silken Thread
                    15407, -- Cured Light Hide
                    8153,  -- Wildvine
                    7287,  -- Red Wolf Meat
                    6470,  -- Deviate Scale
                    5637   -- Large Fang
                }
            },
            {
                name = "Artisan",
                minSkill = 225,
                maxSkill = 300,
                items = {
                    8170,  -- Rugged Leather
                    8171,  -- Rugged Hide
                    14341, -- Rune Thread
                    15408, -- Cured Heavy Hide
                    12803, -- Living Essence
                    12808, -- Essence of Undeath
                    7972,  -- Ichor of Undeath
                    7077   -- Heart of Fire
                }
            },
            {
                name = "Master",
                minSkill = 300,
                maxSkill = 375,
                items = {
                    21887, -- Knothide Leather
                    25649, -- Knothide Leather Scraps
                    25700, -- Fel Scales
                    25699, -- Crystal Infused Leather
                    29539, -- Cobra Scales
                    21884, -- Primal Fire
                    21885, -- Primal Water
                    22572  -- Mote of Air
                }
            },
            {
                name = "Grand Master",
                minSkill = 375,
                maxSkill = 450,
                items = {
                    33568, -- Borean Leather
                    38425, -- Heavy Borean Leather
                    44128, -- Arctic Fur
                    33567, -- Borean Leather Scraps
                    38558, -- Nerubian Chitin
                    36860, -- Eternal Water
                    36926, -- Eternal Fire
                    35624  -- Eternal Earth
                }
            }
        }
    },
    {
        skillId = 185, 
        name = "Cooking", 
        tiers = {
            {
                name = "Apprentice",
                minSkill = 1,
                maxSkill = 75,
                items = {
                    2678,  -- Mild Spices
                    159,   -- Refreshing Spring Water
                    1179,  -- Ice Cold Milk
                    4289,  -- Salt
                    414,   -- Dalaran Sharp
                    422,   -- Dwarven Mild
                    1707,  -- Stormwind Brie
                    4399,  -- Wooden Ladle
                    2324,  -- Bleach
                    6308,  -- Raw Fish
                    787,   -- Slitherskin Mackerel
                    769    -- Chunk of Boar Meat
                }
            },
            {
                name = "Journeyman",
                minSkill = 75,
                maxSkill = 150,
                items = {
                    3713,  -- Soothing Spices
                    2593,  -- Flask of Port
                    1708,  -- Sweet Nectar
                    1645,  -- Salty Dog Biscuit
                    6888,  -- Herb Baked Egg
                    787,   -- Slitherskin Mackerel
                    4603,  -- Raw Spotted Yellowtail
                    6289,  -- Raw Longjaw Mud Snapper
                    2251,  -- Gooey Spider Leg
                    1015,  -- Lean Wolf Flank
                    2672,  -- Stringy Wolf Meat
                    2674   -- Crawler Meat
                }
            },
            {
                name = "Expert",
                minSkill = 150,
                maxSkill = 225,
                items = {
                    3714,  -- Hot Spices
                    8150,  -- Deeprock Salt
                    7974,  -- Zesty Clam Meat
                    13759, -- Zesty Clam Meat
                    4603,  -- Raw Spotted Yellowtail
                    8959,  -- Raw Spinefin Halibut
                    21071, -- Raw Sagefish
                    13893, -- Large Raw Mightfish
                    3667,  -- Tender Crab Meat
                    4655,  -- Giant Clam Meat
                    5051,  -- Dig Rat Stew
                    6361   -- Raw Rainbow Fin Albacore
                }
            },
            {
                name = "Artisan",
                minSkill = 225,
                maxSkill = 300,
                items = {
                    2692,  -- Hot Spices
                    21153, -- Raw Greater Sagefish
                    13893, -- Large Raw Mightfish
                    19808, -- Rocknose
                    20709, -- Rumsey Rum Light
                    8932,  -- Alterac Swiss
                    8950,  -- Homemade Cherry Pie
                    19304, -- Spiced Beef Jerky
                    12037, -- Mystery Meat
                    13754, -- Raw Glossy Mightfish
                    21024, -- Chimaerok Tenderloin
                    12207  -- Giant Egg
                }
            },
            {
                name = "Master",
                minSkill = 300,
                maxSkill = 375,
                items = {
                    30817, -- Simple Flour
                    27651, -- Buzzard Meat
                    24477, -- Jaggal Clam Meat
                    27674, -- Ravager Flesh
                    31670, -- Raptor Ribs
                    33452, -- Honey Mead
                    27857, -- Garadar Sharp
                    35794  -- Silvercoat Stag Meat
                }
            },
            {
                name = "Grand Master",
                minSkill = 375,
                maxSkill = 450,
                items = {
                    43007, -- Northern Spices
                    43013, -- Chilled Meat
                    33004, -- Turtle Meat
                    35794, -- Silvercoat Stag Meat
                    43012, -- Rhino Meat
                    43013, -- Chilled Meat
                    44071, -- Slow-Roasted Turkey
                    44072  -- Great Feast
                }
            }
        }
    },
    {
        skillId = 129, 
        name = "First Aid", 
        tiers = {
            {
                name = "Apprentice",
                minSkill = 1,
                maxSkill = 75,
                items = {
                    2589,  -- Linen Cloth
                    1251,  -- Linen Bandage
                    2581,  -- Heavy Linen Bandage
                    929,   -- Healing Potion
                    118,   -- Minor Healing Potion
                    2320,  -- Coarse Thread
                    159,   -- Refreshing Spring Water
                    4340,  -- Gray Dye
                    2324,  -- Bleach
                    4289,  -- Salt
                    1179,  -- Ice Cold Milk
                    2880   -- Weak Flux
                }
            },
            {
                name = "Journeyman",
                minSkill = 75,
                maxSkill = 150,
                items = {
                    2592,  -- Wool Cloth
                    3530,  -- Wool Bandage
                    3531,  -- Heavy Wool Bandage
                    858,   -- Lesser Healing Potion
                    4596,  -- Discolored Healing Potion
                    2321,  -- Fine Thread
                    4306,  -- Silk Cloth
                    2604,  -- Red Dye
                    3466,  -- Strong Flux
                    4291,  -- Silken Thread
                    6260,  -- Blue Dye
                    2605   -- Green Dye
                }
            },
            {
                name = "Expert",
                minSkill = 150,
                maxSkill = 225,
                items = {
                    6450,  -- Silk Bandage
                    6451,  -- Heavy Silk Bandage
                    4338,  -- Mageweave Cloth
                    1710,  -- Greater Healing Potion
                    3928,  -- Superior Healing Potion
                    4291,  -- Silken Thread
                    8343,  -- Heavy Silken Thread
                    6260,  -- Blue Dye
                    4342,  -- Purple Dye
                    4341,  -- Yellow Dye
                    18567, -- Elemental Flux
                    2325   -- Black Dye
                }
            },
            {
                name = "Artisan",
                minSkill = 225,
                maxSkill = 300,
                items = {
                    8544,  -- Mageweave Bandage
                    8545,  -- Heavy Mageweave Bandage
                    14047, -- Runecloth
                    14529, -- Runecloth Bandage
                    14530, -- Heavy Runecloth Bandage
                    13446, -- Major Healing Potion
                    14341, -- Rune Thread
                    4342,  -- Purple Dye
                    13444, -- Major Mana Potion
                    3928,  -- Superior Healing Potion
                    7076,  -- Essence of Earth
                    12803  -- Living Essence
                }
            },
            {
                name = "Master",
                minSkill = 300,
                maxSkill = 375,
                items = {
                    21877, -- Netherweave Cloth
                    21990, -- Netherweave Bandage
                    21991, -- Heavy Netherweave Bandage
                    22829, -- Super Healing Potion
                    28101, -- Unstable Healing Potion
                    21881, -- Netherweb Spider Silk
                    22572, -- Mote of Air
                    10290  -- Pink Dye
                }
            },
            {
                name = "Grand Master",
                minSkill = 375,
                maxSkill = 450,
                items = {
                    33470, -- Frostweave Cloth
                    34721, -- Frostweave Bandage
                    34722, -- Heavy Frostweave Bandage
                    33447, -- Runic Healing Potion
                    40087, -- Powerful Rejuvenation Potion
                    38426, -- Eternium Thread
                    36860, -- Eternal Water
                    35624  -- Eternal Earth
                }
            }
        }
    }
}

-- Function to get current rotation period
local function GetCurrentRotationPeriod()
    return math.floor(os.time() / ROTATION_INTERVAL)
end

-- Function to create a deterministic random selection of items
local function GetRotatedItemSelection(itemList, maxItems, seed)
    if #itemList <= maxItems then
        return itemList -- Return all items if we have fewer than max
    end
    
    -- Create a deterministic "random" selection based on seed
    math.randomseed(seed)
    local shuffled = {}
    for i, item in ipairs(itemList) do
        table.insert(shuffled, item)
    end
    
    -- Simple shuffle algorithm
    for i = #shuffled, 2, -1 do
        local j = math.random(1, i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end
    
    -- Take only the first maxItems
    local selected = {}
    for i = 1, math.min(maxItems, #shuffled) do
        table.insert(selected, shuffled[i])
    end
    
    return selected
end

-- Function to get available tiers based on skill level
local function GetAvailableTiers(professionData, skillLevel)
    local availableTiers = {}
    
    for i, tier in ipairs(professionData.tiers) do
        if skillLevel >= tier.minSkill then
            table.insert(availableTiers, tier)
        end
    end
    
    return availableTiers
end

-- Function to build item list from multiple tiers
local function BuildItemList(availableTiers)
    local itemList = {}
    
    for i, tier in ipairs(availableTiers) do
        for j, itemId in ipairs(tier.items) do
            table.insert(itemList, itemId)
        end
    end
    
    return itemList
end

-- Function to set vendor items using Eluna functions (skill-based with rotation)
local function SetVendorItems(professionData, playerSkillLevel)
    print("[CraftingVendor] Setting vendor items for " .. professionData.name .. " (skill level: " .. playerSkillLevel .. ")")
    
    -- Clear all current items from vendor
    VendorRemoveAllItems(VENDOR_NPC)
    print("[CraftingVendor] Cleared all vendor items")
    
    -- Get available tiers based on skill level
    local availableTiers = GetAvailableTiers(professionData, playerSkillLevel)
    local fullItemList = BuildItemList(availableTiers)
    
    -- Calculate rotation parameters
    local maxItems = ITEMS_PER_TIER * #availableTiers
    local rotationPeriod = GetCurrentRotationPeriod()
    
    -- Create unique seed for this profession/skill combination
    local seed = rotationPeriod + professionData.skillId + math.floor(playerSkillLevel / 25)
    
    -- Get rotated selection of items
    local itemList = GetRotatedItemSelection(fullItemList, maxItems, seed)
    
    -- Add each item from the rotated item list
    -- maxcount = 0 (unlimited stock), incrtime = 0 (no restock needed)
    for i, itemId in ipairs(itemList) do
        AddVendorItem(VENDOR_NPC, itemId, 0, 0, 0) -- entry, item, maxcount, incrtime, extendedcost
    end
    
    -- Build tier names string for logging
    local tierNames = {}
    for i, tier in ipairs(availableTiers) do
        table.insert(tierNames, tier.name)
    end
    local tierString = table.concat(tierNames, " + ")
    
    -- Calculate time until next rotation
    local secondsUntilNext = ROTATION_INTERVAL - (os.time() % ROTATION_INTERVAL)
    local minutesUntilNext = math.floor(secondsUntilNext / 60)
    
    print("[CraftingVendor] Added " .. #itemList .. "/" .. #fullItemList .. " items for " .. professionData.name .. " (" .. tierString .. " tiers, " .. minutesUntilNext .. " min until rotation)")
end



-- Main gossip menu - show professions the player knows
local function OnGossipHello(event, player, creature)
    if creature:GetEntry() ~= VENDOR_NPC then
        return
    end
    
    print("[CraftingVendor] OnGossipHello called for player: " .. player:GetName())
    
    player:GossipClearMenu()
    
    local hasAnyProfession = false
    
    -- Check each profession and add gossip option if player has it
    for i, profession in ipairs(PROFESSIONS) do
        if player:HasSkill(profession.skillId) then
            print("[CraftingVendor] Player has " .. player:GetSkillValue(profession.skillId) .. " skill in " .. profession.name .. ")")
            player:GossipMenuAddItem(
                0, -- icon
                "Browse " .. profession.name .. " materials",
                0, -- sender
                i -- intid - use the profession index
            )
            hasAnyProfession = true
            print("[CraftingVendor] Added gossip option for " .. profession.name .. " (index: " .. i .. ")")
        end
    end
    
    if not hasAnyProfession then
        player:GossipMenuAddItem(0, "You have no crafting professions.", 0, 999)
    end
    

    
    player:GossipMenuAddItem(0, "Close", 0, 0)
    player:GossipSendMenu(1, creature)
    print("[CraftingVendor] Gossip menu sent")
end

-- Handle gossip selection
local function OnGossipSelect(event, player, creature, sender, intid, code)
    if creature:GetEntry() ~= VENDOR_NPC then
        return
    end
    
    print("[CraftingVendor] OnGossipSelect called with intid: " .. intid)
    
    player:GossipClearMenu()
    
    if intid == 0 or intid == 999 then
        -- Close gossip
        print("[CraftingVendor] Closing gossip")
        player:GossipComplete()
        return
    end
    

    
    -- Get the profession data using the index
    local professionData = PROFESSIONS[intid]
    if professionData then
        -- Get player's skill level for this profession
        local playerSkillLevel = player:GetSkillValue(professionData.skillId)
        
        -- Set the vendor items for the selected profession
        if professionData.tiers then
            -- New tier-based system
            SetVendorItems(professionData, playerSkillLevel)
            
            -- Provide helpful instructions for buying quantities
            player:SendBroadcastMessage("Shopping Tip: Use Shift+click to open quantity dialog, then TYPE the amount you want (e.g. 20) or use Page Up/Down to change by 10, Home/End for min/max")
            
            -- Show skill-based message with tier and rotation info
            local availableTiers = GetAvailableTiers(professionData, playerSkillLevel)
            local tierNames = {}
            for i, tier in ipairs(availableTiers) do
                table.insert(tierNames, tier.name)
            end
            local tierString = table.concat(tierNames, " + ")
            
            -- Calculate rotation info
            local secondsUntilNext = ROTATION_INTERVAL - (os.time() % ROTATION_INTERVAL)
            local minutesUntilNext = math.floor(secondsUntilNext / 60)
            local maxItems = ITEMS_PER_TIER * #availableTiers
            
            player:SendBroadcastMessage("Available items based on your " .. professionData.name .. " skill level: " .. playerSkillLevel .. " (" .. tierString .. " tiers)")
            player:SendBroadcastMessage("Showing " .. maxItems .. " items from current rotation. Next rotation in " .. minutesUntilNext .. " minutes.")
        else
            -- Legacy system for professions not yet converted
            print("[CraftingVendor] Warning: " .. professionData.name .. " still uses legacy item system")
            player:SendBroadcastMessage("Error: This profession needs to be updated to the new skill-based system.")
        end
        
        -- Open the vendor window
        player:SendListInventory(creature)
        print("[CraftingVendor] Opened vendor window for " .. professionData.name)
    else
        print("[CraftingVendor] Invalid profession index: " .. intid)
        player:SendBroadcastMessage("Error: Invalid profession selection.")
    end
    
    player:GossipComplete()
end



-- Register the events
RegisterCreatureGossipEvent(VENDOR_NPC, 1, OnGossipHello)
RegisterCreatureGossipEvent(VENDOR_NPC, 2, OnGossipSelect)

print("Crafting Materials Vendor loaded successfully!")
print("NPC Entry: " .. VENDOR_NPC)
print("Use: .npc add " .. VENDOR_NPC .. " to spawn the vendor")
print("Features:")
print("  - Shows profession-specific materials based on player's known professions")
print("  - Skill-based inventory: Items unlock as your profession skill increases")
print("  - 6 skill tiers per profession: Apprentice → Journeyman → Expert → Artisan → Master → Grand Master")
print("  - Rotating inventory: Shows " .. ITEMS_PER_TIER .. " items per unlocked tier, rotates every " .. (ROTATION_INTERVAL/60) .. " minutes")
print("  - Unlimited stock - buy as much as you need")
print("  - Use Shift+click for quantity dialog with helpful shortcuts")
