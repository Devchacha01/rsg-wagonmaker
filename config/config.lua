Config = {}

-------------------------------------------------
-- General Settings
-------------------------------------------------
Config.Debug = false
-- Enables verbose server/client logs for progressive crafting contributions, stash usage, refunds, etc.
-- Safe to leave in production (disabled by default).

-------------------------------------------------
-- Job Settings
-------------------------------------------------
Config.JobRequired = true                   -- Set to true to restrict crafting to job holders
Config.JobMode = 'location'                 -- 'location' = check per zone, 'single' = check global
Config.GlobalJobName = "wagonmaker"         -- Fallback job name
Config.WagonMakerJob = "wagonmaker"         -- Legacy support
Config.WagonMakerGrade = 0                  -- Minimum grade required

-------------------------------------------------
-- Admin Settings
-------------------------------------------------
Config.AdminGroups = { "admin", "superadmin", "god" }

-------------------------------------------------
-- Zone Marker Settings
-------------------------------------------------
Config.CraftingMarker = {
    type = 0x94FDAE17,                      -- Ring marker
    color = { r = 50, g = 205, b = 50, a = 150 },  -- Green
    radius = 2.0,
    height = 0.5
}

Config.PreviewMarker = {
    type = 0x94FDAE17,                      -- Ring marker
    color = { r = 100, g = 149, b = 237, a = 150 }, -- Cornflower blue
    radius = 3.0,
    height = 0.5
}

-------------------------------------------------
-- Limits
-------------------------------------------------
Config.MaxWagonsPerPlayer = 5               -- Max wagons a player can own
Config.MaxPreviewTime = 300                 -- Seconds before preview auto-deletes (5 minutes)
Config.CraftingAnimTime = 30000             -- Default crafting time in ms

-------------------------------------------------
-- Progressive Crafting
-- If true: players can deliver materials over time (no need to hold all parts at once).
-- The build completes when all required materials have been delivered.
-------------------------------------------------
Config.ProgressiveCrafting = true
-- ========================================
-- Business Ownership Mode
-- ========================================
-- When true, wagon builds and finished wagons belong to the business (job),
-- not the individual who started the project. Any authorized employee can contribute.
Config.BusinessOwnership = true

-- Who can contribute materials / progress builds
Config.BuildPermissions = {
    minGrade = 0, -- 0 = any employee in the job
}

-- Who can cancel projects (recommended to restrict; cancellation refunds to shop storage)
Config.CancelPermissions = {
    minGrade = 2, -- default: manager+
}

-- Who can transfer business-owned stock wagons to customers
Config.TransferPermissions = {
    minGrade = 2, -- default: manager+
}

-- Transfer rules
Config.TransferRules = {
    depositToCompanyFunds = true,
    requireCustomerNearby = true,
    maxDistance = 3.0,
    requirePayment = false,
    moneyType = "cash",
}


-------------------------------------------------
-- ox_target Settings
-------------------------------------------------
Config.UseOxTarget = true                   -- Use ox_target for wagon interactions (requires ox_target)

-------------------------------------------------
-- Wagon Inventory Settings
-------------------------------------------------
-- This resource's storage features are implemented via rsg-inventory job stashes.
-- Leave this disabled unless you have explicitly integrated ox_inventory.
Config.UseWagonInventory = false


-------------------------------------------------
-- Currency Settings
-------------------------------------------------
Config.MoneyType = "cash"                   -- "cash" or "bank"

-------------------------------------------------
Config.JobGrades = {
    boss = 3,
    manager = 2,
    employee = 1,
    recruit = 0
}

-------------------------------------------------
-- Key Bindings
-------------------------------------------------
Config.Keys = {
    Interact = "INPUT_FRONTEND_ACCEPT",     -- Enter/E key
    RotateLeft = "INPUT_FRONTEND_LB",       -- Q key
    RotateRight = "INPUT_FRONTEND_RB",      -- E key
    Cancel = "INPUT_FRONTEND_CANCEL"        -- Backspace
}

-------------------------------------------------
-- Crafting NPC Settings
-- Use these to define static NPCs instead of using DB zones
-------------------------------------------------
Config.DefaultWorkerModel = "s_m_m_valdealer_01"

Config.CraftingNPCs = {
    {
        id = "static_valentine",
        name = "Valentine Wagon Maker",
        coords = vector4(-242.42, 696.51, 113.46, 340.26),
        model = "s_m_m_valdealer_01",
        job = "wagon_valentine",
        previewPoint = vector3(-238.74, 702.13, 113.52),
        previewHeading = 281.85
    },
    {
        id = "static_rhodes",
        name = "Rhodes Wagon Maker",
        coords = vector4(1467.68, -1373.22, 78.79, 249.50),
        model = "s_m_m_valdealer_01",
        job = "wagon_rhodes",
        previewPoint = vector3(1472.25, -1378.08, 78.40),
        previewHeading = 224.98
    },
    {
        id = "static_saint_denis",
        name = "Saint Denis Wagon Maker",
        coords = vector4(2695.47, -870.45, 42.47, 22.0),
        model = "s_m_m_valdealer_01",
        job = "wagon_saint",
        previewPoint = vector3(2702.58, -875.31, 42.38),
        previewHeading = 167.47
    },
    {
        id = "static_blackwater",
        name = "Blackwater Wagon Maker",
        coords = vector4(-868.94, -1380.57, 43.65, 180.44),
        model = "s_m_m_valdealer_01",
        job = "wagon_blackwater",
        previewPoint = vector3(-877.50, -1383.58, 43.61),
        previewHeading = 276.05
    },
    {
        id = "static_strawberry",
        name = "Strawberry Wagon Maker",
        coords = vector4(-1826.29, -570.82, 156.05, 161.84),
        model = "s_m_m_valdealer_01",
        job = "wagon_strawberry",
        previewPoint = vector3(-1827.84, -577.88, 156.00),
        previewHeading = 158.78
    },
    {
        id = "static_armadillo",
        name = "Armadillo Wagon Maker",
        coords = vector4(-3681.45, -2565.50, -13.51, 167.90),
        model = "s_m_m_valdealer_01",
        job = "wagon_armadillo",
        previewPoint = vector3(-3686.87, -2575.38, -13.68),
        previewHeading = 206.74
    },
    {
        id = "static_tumbleweed",
        name = "Tumbleweed Wagon Maker",
        coords = vector4(-5524.76, -3055.89, -2.22, 144.41),
        model = "s_m_m_valdealer_01",
        job = "wagon_tumbleweed",
        previewPoint = vector3(-5533.76, -3060.18, -1.26),
        previewHeading = 274.13
    }
}

-------------------------------------------------
-- Parking NPC Locations
-- Use /wm_getcoords to get your current position (admin only)
-- Then add an entry below with your coordinates
-------------------------------------------------
Config.ParkingNPCs = {
    {
        id = 1,
        name = "Wagon Yard",
        job = "wagon_valentine",
        coords = vector3(-265.56, 686.32, 113.38),
        heading = 227.37,
        model = "s_m_m_valdealer_01",
        spawnPoint = vector3(-260.56, 686.32, 113.38),
        spawnHeading = 227.37,
        parkingZone = {
            coords = vector3(-260.29, 674.75, 113.33),
            radius = 5.0,
            heading = 39.74
        },
        blip = {
            enabled = true,
            sprite = 1012165077,
            name = "Parking - Valentine",
            scale = 0.8
        }
    },
    {
        id = 2,
        name = "Wagon Yard - Rhodes",
        job = "wagon_rhodes",
        coords = vector3(1459.62, -1374.00, 78.90),
        heading = 162.62,
        model = "s_m_m_valdealer_01",
        spawnPoint = vector3(1461.87, -1386.94, 78.92),
        spawnHeading = 156.77,
        parkingZone = {
            coords = vector3(1461.87, -1386.94, 78.92),
            radius = 5.0,
            heading = 156.77
        },
        blip = {
            enabled = true,
            sprite = 1012165077,
            name = "Parking - Rhodes",
            scale = 0.8
        }
    },
    {
        id = 3,
        name = "Wagon Yard - Saint Denis",
        job = "wagon_saint",
        coords = vector3(2690.47, -875.45, 42.47),
        heading = 22.93,
        model = "s_m_m_valdealer_01",
        spawnPoint = vector3(2688.95, -867.62, 42.36),
        spawnHeading = 295.25,
        parkingZone = {
            coords = vector3(2688.95, -867.62, 42.36),
            radius = 5.0,
            heading = 295.25
        },
        blip = {
            enabled = true,
            sprite = 1012165077,
            name = "Parking - Saint Denis",
            scale = 0.8
        }
    },
    {
        id = 4,
        name = "Wagon Yard - Blackwater",
        job = "wagon_blackwater",
        coords = vector3(-854.54, -1376.22, 43.66),
        heading = 275.28,
        model = "s_m_m_valdealer_01",
        spawnPoint = vector3(-849.09, -1370.74, 43.44),
        spawnHeading = 4.96,
        parkingZone = {
            coords = vector3(-849.09, -1370.74, 43.44),
            radius = 5.0,
            heading = 4.96
        },
        blip = {
            enabled = true,
            sprite = 1012165077,
            name = "Parking - Blackwater",
            scale = 0.8
        }
    },
    {
        id = 5,
        name = "Wagon Yard - Strawberry",
        job = "wagon_strawberry",
        coords = vector3(-1815.75, -576.62, 156.05),
        heading = 255.39,
        model = "s_m_m_valdealer_01",
        spawnPoint = vector3(-1820.25, -591.16, 155.42),
        spawnHeading = 256.09,
        parkingZone = {
            coords = vector3(-1820.25, -591.16, 155.42),
            radius = 5.0,
            heading = 256.09
        },
        blip = {
            enabled = true,
            sprite = 1012165077,
            name = "Parking - Strawberry",
            scale = 0.8
        }
    },
    {
        id = 6,
        name = "Wagon Yard - Armadillo",
        job = "wagon_armadillo",
        coords = vector3(-3700.76, -2570.86, -13.68),
        heading = 274.21,
        model = "s_m_m_valdealer_01",
        spawnPoint = vector3(-3692.22, -2571.55, -13.68),
        spawnHeading = 264.11,
        parkingZone = {
            coords = vector3(-3692.22, -2571.55, -13.68),
            radius = 5.0,
            heading = 264.11
        },
        blip = {
            enabled = true,
            sprite = 1012165077,
            name = "Parking - Armadillo",
            scale = 0.8
        }
    },
    {
        id = 7,
        name = "Wagon Yard - Tumbleweed",
        job = "wagon_tumbleweed",
        coords = vector3(-5549.04, -3046.92, -0.99),
        heading = 83.94,
        model = "s_m_m_valdealer_01",
        spawnPoint = vector3(-5557.10, -3041.48, -1.16),
        spawnHeading = 7.27,
        parkingZone = {
            coords = vector3(-5557.10, -3041.48, -1.16),
            radius = 5.0,
            heading = 7.27
        },
        blip = {
            enabled = true,
            sprite = 1012165077,
            name = "Parking - Tumbleweed",
            scale = 0.8
        }
    }
}

-------------------------------------------------
-- Static Crafting Zones (no database needed)
-- These zones will always appear at these locations
-------------------------------------------------
Config.StaticZones = {} -- Removed old static zones. Using NPC-based zones now.


-------------------------------------------------
-- Materials Definition
-------------------------------------------------
Config.Materials = {
    wood_log = { 
        label = "Wood Log", 
        description = "Sturdy timber for wagon frame",
        image = "wood_log.png" 
    },
    iron_parts = { 
        label = "Iron Parts", 
        description = "Metal fittings and hardware",
        image = "iron_parts.png" 
    },
    steel_plate = { 
        label = "Steel Plate", 
        description = "Reinforced steel sheets",
        image = "steel_plate.png" 
    },
    wagon_wheel = { 
        label = "Wagon Wheel", 
        description = "Pre-crafted wooden wheels",
        image = "wagon_wheel.png" 
    },
    leather = { 
        label = "Leather", 
        description = "Tanned hide for seats and covers",
        image = "leather.png" 
    },
    rope = { 
        label = "Rope", 
        description = "Hemp rope for securing cargo",
        image = "rope.png" 
    },
    nails = { 
        label = "Nails", 
        description = "Iron nails for construction",
        image = "nails.png" 
    },
    paint = { 
        label = "Paint", 
        description = "Wood stain and paint",
        image = "paint.png" 
    }
}

-------------------------------------------------
-- Wagon Recipes (Complete List)
-------------------------------------------------
Config.Wagons = {
    -------------------------------------------------
    -- Basic Carts
    -------------------------------------------------
    cart01 = {
        label = "Light Peasant Cart",
        description = "A simple one-horse cart for light loads",
        category = "carts",
        craftTime = 30000,
        materials = {
            { item = "wood_log", amount = 8 },
            { item = "iron_parts", amount = 4 },
            { item = "wagon_wheel", amount = 2 },
            { item = "nails", amount = 10 }
        },
        price = 0,
        maxWeight = 150000,
        slots = 60,
        customizations = {
            livery = { -1, 0, 1, 2, 3 },
            tint = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
            extras = { 0, 1, 2, 3 }
        }
    },
    cart02 = {
        label = "Peasant Cart with Sides",
        description = "A cart with raised sides for better cargo security",
        category = "carts",
        craftTime = 35000,
        materials = {
            { item = "wood_log", amount = 10 },
            { item = "iron_parts", amount = 5 },
            { item = "wagon_wheel", amount = 2 },
            { item = "nails", amount = 15 }
        },
        price = 0,
        maxWeight = 180000,
        slots = 60,
        customizations = {
            livery = { -1, 0, 1, 2, 3 },
            tint = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
            extras = { 0, 1, 2, 3 }
        }
    },
    cart03 = {
        label = "Small Market Cart",
        description = "Compact cart ideal for market vendors",
        category = "carts",
        craftTime = 25000,
        materials = {
            { item = "wood_log", amount = 6 },
            { item = "iron_parts", amount = 3 },
            { item = "wagon_wheel", amount = 2 },
            { item = "nails", amount = 8 }
        },
        price = 0,
        maxWeight = 150000,
        slots = 60,
        customizations = {
            livery = { -1, 0, 1, 2 },
            tint = { 0, 1, 2, 3, 4, 5, 6, 7, 8 },
            extras = { 0, 1, 2 }
        }
    },
    cart04 = {
        label = "Compact Farm Cart",
        description = "Handy cart for farm work",
        category = "carts",
        craftTime = 28000,
        materials = {
            { item = "wood_log", amount = 7 },
            { item = "iron_parts", amount = 4 },
            { item = "wagon_wheel", amount = 2 },
            { item = "nails", amount = 12 }
        },
        price = 0,
        maxWeight = 170000,
        slots = 60,
        customizations = {
            livery = { -1, 0, 1, 2 },
            tint = { 0, 1, 2, 3, 4, 5, 6, 7, 8 },
            extras = { 0, 1, 2 }
        }
    },
    cart05 = {
        label = "Water/Liquid Tank Wagon",
        description = "Specialized for liquid transport",
        category = "carts",
        craftTime = 45000,
        materials = {
            { item = "wood_log", amount = 12 },
            { item = "iron_parts", amount = 10 },
            { item = "steel_plate", amount = 5 },
            { item = "wagon_wheel", amount = 2 },
            { item = "nails", amount = 20 }
        },
        price = 0,
        maxWeight = 200000,
        slots = 60,
        customizations = {
            livery = { -1, 0, 1 },
            tint = { 0, 1, 2, 3, 4, 5 },
            extras = { 0, 1 }
        }
    },
    cart06 = {
        label = "General Cargo Cart",
        description = "Versatile cart for various cargo",
        category = "carts",
        craftTime = 40000,
        materials = {
            { item = "wood_log", amount = 14 },
            { item = "iron_parts", amount = 8 },
            { item = "wagon_wheel", amount = 2 },
            { item = "nails", amount = 25 }
        },
        price = 0,
        maxWeight = 220000,
        slots = 60,
        customizations = {
            livery = { -1, 0, 1, 2, 3 },
            tint = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 },
            extras = { 0, 1, 2, 3 }
        }
    },
    cart07 = {
        label = "Farmer's Cart",
        description = "Reliable farm cart",
        category = "carts",
        craftTime = 32000,
        materials = {
            { item = "wood_log", amount = 9 },
            { item = "iron_parts", amount = 5 },
            { item = "wagon_wheel", amount = 2 },
            { item = "nails", amount = 14 }
        },
        price = 0,
        maxWeight = 180000,
        slots = 60,
        customizations = {
            livery = { -1, 0, 1, 2 },
            tint = { 0, 1, 2, 3, 4, 5, 6 },
            extras = { 0, 1, 2 }
        }
    },
    cart08 = {
        label = "Rural Utility Cart",
        description = "Multi-purpose utility cart",
        category = "carts",
        craftTime = 38000,
        materials = {
            { item = "wood_log", amount = 11 },
            { item = "iron_parts", amount = 6 },
            { item = "wagon_wheel", amount = 2 },
            { item = "nails", amount = 18 }
        },
        price = 0,
        maxWeight = 200000,
        slots = 60,
        customizations = {
            livery = { -1, 0, 1, 2, 3 },
            tint = { 0, 1, 2, 3, 4, 5, 6, 7, 8 },
            extras = { 0, 1, 2, 3 }
        }
    },
    
    -------------------------------------------------
    -- Work Wagons
    -------------------------------------------------
    wagon02x = {
        label = "Standard Camping Wagon",
        description = "A reliable covered wagon for long journeys",
        category = "work",
        craftTime = 60000,
        materials = {
            { item = "wood_log", amount = 15 },
            { item = "iron_parts", amount = 8 },
            { item = "wagon_wheel", amount = 4 },
            { item = "leather", amount = 5 },
            { item = "nails", amount = 20 },
            { item = "rope", amount = 4 }
        },
        price = 0,
        maxWeight = 400000,
        slots = 80,
        customizations = {
            livery = { -1, 0, 1, 2, 3, 4, 5 },
            tint = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
            extras = { 0, 1, 2, 3, 4 }
        }
    },
    wagon03x = {
        label = "Reinforced Camping Wagon",
        description = "A sturdier wagon with extra storage",
        category = "work",
        craftTime = 75000,
        materials = {
            { item = "wood_log", amount = 18 },
            { item = "iron_parts", amount = 10 },
            { item = "steel_plate", amount = 3 },
            { item = "wagon_wheel", amount = 4 },
            { item = "leather", amount = 6 },
            { item = "nails", amount = 25 },
            { item = "rope", amount = 6 }
        },
        price = 0,
        maxWeight = 450000,
        slots = 80,
        customizations = {
            livery = { -1, 0, 1, 2, 3, 4, 5, 6 },
            tint = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
            extras = { 0, 1, 2, 3, 4, 5 }
        }
    },
    wagon04x = {
        label = "Light Farm Wagon",
        description = "Lightweight wagon for farming",
        category = "work",
        craftTime = 50000,
        materials = {
            { item = "wood_log", amount = 12 },
            { item = "iron_parts", amount = 6 },
            { item = "wagon_wheel", amount = 4 },
            { item = "nails", amount = 18 }
        },
        price = 0,
        maxWeight = 350000,
        slots = 60,
        customizations = {
            livery = { -1, 0, 1, 2, 3 },
            tint = { 0, 1, 2, 3, 4, 5, 6, 7, 8 },
            extras = { 0, 1, 2, 3 }
        }
    },
    wagon05x = {
        label = "Open Utility Wagon",
        description = "Open wagon for versatile use",
        category = "work",
        craftTime = 55000,
        materials = {
            { item = "wood_log", amount = 14 },
            { item = "iron_parts", amount = 7 },
            { item = "wagon_wheel", amount = 4 },
            { item = "nails", amount = 20 }
        },
        price = 0,
        maxWeight = 380000,
        slots = 60,
        customizations = {
            livery = { -1, 0, 1, 2, 3, 4 },
            tint = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 },
            extras = { 0, 1, 2, 3, 4 }
        }
    },
    wagon06x = {
        label = "Covered Supply Wagon",
        description = "Covered wagon for protected cargo",
        category = "work",
        craftTime = 70000,
        materials = {
            { item = "wood_log", amount = 16 },
            { item = "iron_parts", amount = 9 },
            { item = "wagon_wheel", amount = 4 },
            { item = "leather", amount = 8 },
            { item = "nails", amount = 22 }
        },
        price = 0,
        maxWeight = 450000,
        slots = 80,
        customizations = {
            livery = { -1, 0, 1, 2, 3, 4, 5 },
            tint = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
            extras = { 0, 1, 2, 3, 4 }
        }
    },
    chuckwagon000x = {
        label = "Kitchen Wagon (Chuckwagon)",
        description = "A mobile kitchen for feeding workers",
        category = "work",
        craftTime = 90000,
        materials = {
            { item = "wood_log", amount = 20 },
            { item = "iron_parts", amount = 12 },
            { item = "steel_plate", amount = 5 },
            { item = "wagon_wheel", amount = 4 },
            { item = "leather", amount = 4 },
            { item = "nails", amount = 30 }
        },
        price = 0,
        maxWeight = 600000,
        slots = 100,
        customizations = {
            livery = { -1, 0, 1, 2, 3, 4 },
            tint = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
            extras = { 0, 1, 2, 3, 4, 5 }
        }
    },
    chuckwagon002x = {
        label = "Tool Cargo Wagon",
        description = "Wagon designed for tools and equipment",
        category = "work",
        craftTime = 85000,
        materials = {
            { item = "wood_log", amount = 18 },
            { item = "iron_parts", amount = 14 },
            { item = "steel_plate", amount = 4 },
            { item = "wagon_wheel", amount = 4 },
            { item = "nails", amount = 28 }
        },
        price = 0,
        maxWeight = 550000,
        slots = 100,
        customizations = {
            livery = { -1, 0, 1, 2, 3, 4 },
            tint = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
            extras = { 0, 1, 2, 3, 4 }
        }
    },
    supplywagon = {
        label = "Large Supply Wagon",
        description = "Heavy-duty wagon for bulk cargo",
        category = "work",
        craftTime = 120000,
        materials = {
            { item = "wood_log", amount = 30 },
            { item = "iron_parts", amount = 20 },
            { item = "steel_plate", amount = 8 },
            { item = "wagon_wheel", amount = 4 },
            { item = "leather", amount = 6 },
            { item = "nails", amount = 50 },
            { item = "rope", amount = 10 }
        },
        price = 0,
        maxWeight = 800000,
        slots = 120,
        customizations = {
            livery = { -1, 0, 1, 2, 3, 4, 5, 6 },
            tint = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
            extras = { 0, 1, 2, 3, 4, 5, 6 }
        }
    },
    utilliwag = {
        label = "Low Utility Wagon (Buckboard)",
        description = "Light buckboard wagon",
        category = "work",
        craftTime = 35000,
        materials = {
            { item = "wood_log", amount = 10 },
            { item = "iron_parts", amount = 5 },
            { item = "wagon_wheel", amount = 4 },
            { item = "nails", amount = 15 }
        },
        price = 0,
        maxWeight = 300000,
        slots = 60,
        customizations = {
            livery = { -1, 0, 1, 2, 3 },
            tint = { 0, 1, 2, 3, 4, 5, 6, 7, 8 },
            extras = { 0, 1, 2, 3 }
        }
    },
    gatchuck = {
        label = "Articulated Heavy Cargo Wagon",
        description = "Massive freight wagon",
        category = "work",
        craftTime = 150000,
        materials = {
            { item = "wood_log", amount = 35 },
            { item = "iron_parts", amount = 25 },
            { item = "steel_plate", amount = 12 },
            { item = "wagon_wheel", amount = 6 },
            { item = "nails", amount = 60 },
            { item = "rope", amount = 15 }
        },
        price = 0,
        maxWeight = 1000000,
        slots = 150,
        requiredGrade = 2,
        customizations = {
            livery = { -1, 0, 1, 2, 3 },
            tint = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 },
            extras = { 0, 1, 2, 3, 4 }
        }
    },
    oilwagon01x = {
        label = "Small Oil Tanker Wagon",
        description = "Transport oil and fuel",
        category = "work",
        craftTime = 80000,
        materials = {
            { item = "wood_log", amount = 15 },
            { item = "iron_parts", amount = 12 },
            { item = "steel_plate", amount = 8 },
            { item = "wagon_wheel", amount = 4 },
            { item = "nails", amount = 25 }
        },
        price = 0,
        maxWeight = 500000,
        slots = 60,
        customizations = {
            livery = { -1, 0, 1 },
            tint = { 0, 1, 2, 3, 4, 5 },
            extras = { 0, 1 }
        }
    },
    oilwagon02x = {
        label = "Large Oil Tanker Wagon",
        description = "Large capacity fuel transport",
        category = "work",
        craftTime = 100000,
        materials = {
            { item = "wood_log", amount = 20 },
            { item = "iron_parts", amount = 18 },
            { item = "steel_plate", amount = 12 },
            { item = "wagon_wheel", amount = 4 },
            { item = "nails", amount = 35 }
        },
        price = 0,
        maxWeight = 700000,
        slots = 80,
        customizations = {
            livery = { -1, 0, 1 },
            tint = { 0, 1, 2, 3, 4, 5, 6 },
            extras = { 0, 1, 2 }
        }
    },
    coal_wagon = {
        label = "Coal/Ore Wagon",
        description = "Industrial wagon for bulk materials",
        category = "work",
        craftTime = 100000,
        materials = {
            { item = "wood_log", amount = 25 },
            { item = "iron_parts", amount = 25 },
            { item = "steel_plate", amount = 15 },
            { item = "wagon_wheel", amount = 4 },
            { item = "nails", amount = 60 }
        },
        price = 0,
        maxWeight = 900000,
        slots = 100,
        customizations = {
            livery = { -1, 0, 1 },
            tint = { 0, 1, 2, 3, 4, 5 },
            extras = { 0, 1 }
        }
    },
    
    -------------------------------------------------
    -- Coaches & Carriages
    -------------------------------------------------
    coach2 = {
        label = "Light Closed Carriage (Brougham)",
        description = "Elegant carriage for 2-4 passengers",
        category = "coaches",
        craftTime = 100000,
        materials = {
            { item = "wood_log", amount = 25 },
            { item = "iron_parts", amount = 15 },
            { item = "steel_plate", amount = 5 },
            { item = "wagon_wheel", amount = 4 },
            { item = "leather", amount = 15 },
            { item = "nails", amount = 40 },
            { item = "paint", amount = 5 }
        },
        price = 0,
        maxWeight = 350000,
        slots = 60,
        customizations = {
            livery = { -1, 0, 1, 2, 3, 4, 5, 6 },
            tint = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
            extras = { 0, 1, 2, 3, 4 }
        }
    },
    coach3 = {
        label = "Rental Carriage (Fiacre)",
        description = "Urban passenger transport",
        category = "coaches",
        craftTime = 95000,
        materials = {
            { item = "wood_log", amount = 22 },
            { item = "iron_parts", amount = 12 },
            { item = "wagon_wheel", amount = 4 },
            { item = "leather", amount = 12 },
            { item = "nails", amount = 35 },
            { item = "paint", amount = 4 }
        },
        price = 0,
        maxWeight = 380000,
        slots = 60,
        customizations = {
            livery = { -1, 0, 1, 2, 3, 4, 5 },
            tint = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
            extras = { 0, 1, 2, 3, 4 }
        }
    },
    coach4 = {
        label = "Landau Carriage",
        description = "Luxury convertible carriage",
        category = "coaches",
        craftTime = 120000,
        materials = {
            { item = "wood_log", amount = 28 },
            { item = "iron_parts", amount = 16 },
            { item = "wagon_wheel", amount = 4 },
            { item = "leather", amount = 18 },
            { item = "nails", amount = 45 },
            { item = "paint", amount = 6 }
        },
        price = 0,
        maxWeight = 450000,
        slots = 60,
        customizations = {
            livery = { -1, 0, 1, 2, 3, 4, 5, 6 },
            tint = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
            extras = { 0, 1, 2, 3, 4, 5 }
        }
    },
    coach5 = {
        label = "Elegant Victoria",
        description = "Open carriage for outings",
        category = "coaches",
        craftTime = 110000,
        materials = {
            { item = "wood_log", amount = 24 },
            { item = "iron_parts", amount = 14 },
            { item = "wagon_wheel", amount = 4 },
            { item = "leather", amount = 14 },
            { item = "nails", amount = 38 },
            { item = "paint", amount = 5 }
        },
        price = 0,
        maxWeight = 400000,
        slots = 60,
        customizations = {
            livery = { -1, 0, 1, 2, 3, 4, 5, 6 },
            tint = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
            extras = { 0, 1, 2, 3, 4 }
        }
    },
    coach6 = {
        label = "Open Excursion Carriage",
        description = "Group transport for events",
        category = "coaches",
        craftTime = 115000,
        materials = {
            { item = "wood_log", amount = 26 },
            { item = "iron_parts", amount = 15 },
            { item = "wagon_wheel", amount = 4 },
            { item = "leather", amount = 10 },
            { item = "nails", amount = 42 },
            { item = "paint", amount = 4 }
        },
        price = 0,
        maxWeight = 480000,
        slots = 80,
        customizations = {
            livery = { -1, 0, 1, 2, 3, 4, 5 },
            tint = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
            extras = { 0, 1, 2, 3, 4 }
        }
    },
    buggy01 = {
        label = "Luxury Buggy (Leather Top)",
        description = "Elegant buggy for personal use",
        category = "coaches",
        craftTime = 45000,
        materials = {
            { item = "wood_log", amount = 10 },
            { item = "iron_parts", amount = 6 },
            { item = "wagon_wheel", amount = 2 },
            { item = "leather", amount = 10 },
            { item = "nails", amount = 20 },
            { item = "paint", amount = 3 }
        },
        price = 0,
        maxWeight = 250000,
        slots = 60,
        customizations = {
            livery = { -1, 0, 1, 2, 3, 4 },
            tint = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
            extras = { 0, 1, 2, 3 }
        }
    },
    buggy02 = {
        label = "Standard Buggy (Runabout)",
        description = "Common light buggy",
        category = "coaches",
        craftTime = 35000,
        materials = {
            { item = "wood_log", amount = 8 },
            { item = "iron_parts", amount = 4 },
            { item = "wagon_wheel", amount = 2 },
            { item = "leather", amount = 5 },
            { item = "nails", amount = 15 }
        },
        price = 0,
        maxWeight = 200000,
        slots = 60,
        customizations = {
            livery = { -1, 0, 1, 2, 3 },
            tint = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
            extras = { 0, 1, 2 }
        }
    },
    buggy03 = {
        label = "Family Buggy (Light Surrey)",
        description = "Buggy for 4 people",
        category = "coaches",
        craftTime = 50000,
        materials = {
            { item = "wood_log", amount = 12 },
            { item = "iron_parts", amount = 7 },
            { item = "wagon_wheel", amount = 4 },
            { item = "leather", amount = 8 },
            { item = "nails", amount = 22 }
        },
        price = 0,
        maxWeight = 300000,
        slots = 60,
        customizations = {
            livery = { -1, 0, 1, 2, 3, 4 },
            tint = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
            extras = { 0, 1, 2, 3 }
        }
    },
    
    -------------------------------------------------
    -- Stagecoaches
    -------------------------------------------------
    stagecoach001x = {
        label = "Common Stagecoach (Concord)",
        description = "Standard intercity stagecoach",
        category = "stagecoaches",
        craftTime = 150000,
        materials = {
            { item = "wood_log", amount = 35 },
            { item = "iron_parts", amount = 25 },
            { item = "steel_plate", amount = 10 },
            { item = "wagon_wheel", amount = 4 },
            { item = "leather", amount = 20 },
            { item = "nails", amount = 60 },
            { item = "paint", amount = 8 }
        },
        price = 0,
        maxWeight = 600000,
        slots = 100,
        customizations = {
            livery = { -1, 0, 1, 2, 3, 4, 5, 6, 7 },
            tint = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
            extras = { 0, 1, 2, 3, 4, 5 }
        }
    },
    stagecoach002x = {
        label = "Light Rural Stagecoach",
        description = "Smaller stagecoach for rural routes",
        category = "stagecoaches",
        craftTime = 130000,
        materials = {
            { item = "wood_log", amount = 30 },
            { item = "iron_parts", amount = 20 },
            { item = "steel_plate", amount = 6 },
            { item = "wagon_wheel", amount = 4 },
            { item = "leather", amount = 15 },
            { item = "nails", amount = 50 },
            { item = "paint", amount = 6 }
        },
        price = 0,
        maxWeight = 500000,
        slots = 80,
        customizations = {
            livery = { -1, 0, 1, 2, 3, 4, 5, 6 },
            tint = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
            extras = { 0, 1, 2, 3, 4 }
        }
    },
    stagecoach003x = {
        label = "Simple Passenger Carriage",
        description = "Basic closed town coach",
        category = "stagecoaches",
        craftTime = 90000,
        materials = {
            { item = "wood_log", amount = 22 },
            { item = "iron_parts", amount = 14 },
            { item = "wagon_wheel", amount = 4 },
            { item = "leather", amount = 12 },
            { item = "nails", amount = 35 },
            { item = "paint", amount = 4 }
        },
        price = 0,
        maxWeight = 450000,
        slots = 60,
        customizations = {
            livery = { -1, 0, 1, 2, 3, 4, 5 },
            tint = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
            extras = { 0, 1, 2, 3, 4 }
        }
    },
    stagecoach005x = {
        label = "Long-Distance Stagecoach",
        description = "Robust stagecoach for long routes",
        category = "stagecoaches",
        craftTime = 160000,
        materials = {
            { item = "wood_log", amount = 38 },
            { item = "iron_parts", amount = 28 },
            { item = "steel_plate", amount = 12 },
            { item = "wagon_wheel", amount = 4 },
            { item = "leather", amount = 22 },
            { item = "nails", amount = 65 },
            { item = "paint", amount = 10 }
        },
        price = 0,
        maxWeight = 700000,
        slots = 110,
        customizations = {
            livery = { -1, 0, 1, 2, 3, 4, 5, 6, 7 },
            tint = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
            extras = { 0, 1, 2, 3, 4, 5, 6 }
        }
    },
    stagecoach006x = {
        label = "Urban Omnibus Stagecoach",
        description = "Mass transit public coach",
        category = "stagecoaches",
        craftTime = 140000,
        materials = {
            { item = "wood_log", amount = 32 },
            { item = "iron_parts", amount = 22 },
            { item = "steel_plate", amount = 8 },
            { item = "wagon_wheel", amount = 4 },
            { item = "leather", amount = 18 },
            { item = "nails", amount = 55 },
            { item = "paint", amount = 7 }
        },
        price = 0,
        maxWeight = 650000,
        slots = 120,
        customizations = {
            livery = { -1, 0, 1, 2, 3, 4, 5, 6 },
            tint = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
            extras = { 0, 1, 2, 3, 4, 5 }
        }
    },
    
    -------------------------------------------------
    -- Special & Military Wagons
    -------------------------------------------------
    wagonarmoured01x = {
        label = "Armored Valuables Wagon",
        description = "Heavily armored for valuables transport",
        category = "special",
        craftTime = 180000,
        materials = {
            { item = "wood_log", amount = 40 },
            { item = "iron_parts", amount = 30 },
            { item = "steel_plate", amount = 25 },
            { item = "wagon_wheel", amount = 4 },
            { item = "leather", amount = 10 },
            { item = "nails", amount = 80 }
        },
        price = 0,
        maxWeight = 1000000,
        slots = 60,
        requiredGrade = 3,
        customizations = {
            livery = { -1, 0, 1, 2 },
            tint = { 0, 1, 2, 3, 4, 5, 6 },
            extras = { 0, 1, 2 }
        }
    },
    stagecoach004x = {
        label = "Reinforced Stagecoach",
        description = "Extra-sturdy passenger transport",
        category = "special",
        craftTime = 170000,
        materials = {
            { item = "wood_log", amount = 35 },
            { item = "iron_parts", amount = 30 },
            { item = "steel_plate", amount = 15 },
            { item = "wagon_wheel", amount = 4 },
            { item = "leather", amount = 20 },
            { item = "nails", amount = 70 },
            { item = "paint", amount = 8 }
        },
        price = 0,
        maxWeight = 750000,
        slots = 120,
        requiredGrade = 2,
        customizations = {
            livery = { -1, 0, 1, 2, 3, 4, 5 },
            tint = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
            extras = { 0, 1, 2, 3, 4 }
        }
    },
    stagecoach004_2x = {
        label = "Heavy Armored Stagecoach",
        description = "Armored passenger stagecoach",
        category = "special",
        craftTime = 200000,
        materials = {
            { item = "wood_log", amount = 45 },
            { item = "iron_parts", amount = 35 },
            { item = "steel_plate", amount = 25 },
            { item = "wagon_wheel", amount = 4 },
            { item = "leather", amount = 25 },
            { item = "nails", amount = 90 },
            { item = "paint", amount = 10 }
        },
        price = 0,
        maxWeight = 900000,
        slots = 120,
        requiredGrade = 3,
        customizations = {
            livery = { -1, 0, 1, 2, 3 },
            tint = { 0, 1, 2, 3, 4, 5, 6, 7, 8 },
            extras = { 0, 1, 2, 3 }
        }
    },
    policewagon01x = {
        label = "Police Patrol Wagon",
        description = "Law enforcement patrol vehicle",
        category = "special",
        craftTime = 140000,
        materials = {
            { item = "wood_log", amount = 30 },
            { item = "iron_parts", amount = 22 },
            { item = "steel_plate", amount = 12 },
            { item = "wagon_wheel", amount = 4 },
            { item = "leather", amount = 10 },
            { item = "nails", amount = 55 },
            { item = "paint", amount = 5 }
        },
        price = 0,
        maxWeight = 600000,
        slots = 100,
        requiredGrade = 2,
        customizations = {
            livery = { -1, 0, 1, 2 },
            tint = { 0, 1, 2, 3, 4, 5, 6 },
            extras = { 0, 1, 2 }
        }
    },
    wagonprison01x = {
        label = "Prisoner Transport Wagon",
        description = "Secure wagon with cells",
        category = "special",
        craftTime = 150000,
        materials = {
            { item = "wood_log", amount = 32 },
            { item = "iron_parts", amount = 30 },
            { item = "steel_plate", amount = 18 },
            { item = "wagon_wheel", amount = 4 },
            { item = "nails", amount = 70 }
        },
        price = 0,
        maxWeight = 550000,
        slots = 100,
        requiredGrade = 2,
        customizations = {
            livery = { -1, 0, 1 },
            tint = { 0, 1, 2, 3, 4 },
            extras = { 0, 1 }
        }
    },
    gatchuck_2 = {
        label = "Combat Wagon with Machine Gun",
        description = "Military combat vehicle",
        category = "special",
        craftTime = 240000,
        materials = {
            { item = "wood_log", amount = 50 },
            { item = "iron_parts", amount = 50 },
            { item = "steel_plate", amount = 40 },
            { item = "wagon_wheel", amount = 4 },
            { item = "leather", amount = 15 },
            { item = "nails", amount = 100 }
        },
        price = 0,
        maxWeight = 800000,
        slots = 60,
        requiredGrade = 3,
        customizations = {
            livery = { -1, 0, 1 },
            tint = { 0, 1, 2, 3, 4, 5 },
            extras = { 0, 1 }
        }
    },
    warwagon2 = {
        label = "Armored War Wagon with Turret",
        description = "Heavy armored military wagon",
        category = "special",
        craftTime = 300000,
        materials = {
            { item = "wood_log", amount = 60 },
            { item = "iron_parts", amount = 60 },
            { item = "steel_plate", amount = 50 },
            { item = "wagon_wheel", amount = 6 },
            { item = "nails", amount = 120 }
        },
        price = 0,
        maxWeight = 950000,
        slots = 80,
        requiredGrade = 3,
        customizations = {
            livery = { -1, 0, 1 },
            tint = { 0, 1, 2, 3, 4 },
            extras = { 0, 1 }
        }
    },
    
    -------------------------------------------------
    -- Specialty Commercial Wagons
    -------------------------------------------------
    wagoncircus01x = {
        label = "Circus Wagon - Floats",
        description = "Decorated circus parade wagon",
        category = "specialty",
        craftTime = 100000,
        materials = {
            { item = "wood_log", amount = 28 },
            { item = "iron_parts", amount = 15 },
            { item = "wagon_wheel", amount = 4 },
            { item = "leather", amount = 8 },
            { item = "nails", amount = 45 },
            { item = "paint", amount = 15 }
        },
        price = 0,
        maxWeight = 400000,
        slots = 40,
        customizations = {
            livery = { -1, 0, 1, 2, 3, 4, 5, 6, 7, 8 },
            tint = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
            extras = { 0, 1, 2, 3, 4, 5, 6 }
        }
    },
    wagoncircus02x = {
        label = "Circus Wagon - Performers",
        description = "Circus personnel wagon",
        category = "specialty",
        craftTime = 90000,
        materials = {
            { item = "wood_log", amount = 24 },
            { item = "iron_parts", amount = 12 },
            { item = "wagon_wheel", amount = 4 },
            { item = "leather", amount = 10 },
            { item = "nails", amount = 38 },
            { item = "paint", amount = 12 }
        },
        price = 0,
        maxWeight = 350000,
        slots = 30,
        customizations = {
            livery = { -1, 0, 1, 2, 3, 4, 5, 6, 7 },
            tint = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
            extras = { 0, 1, 2, 3, 4, 5 }
        }
    },
    wagondairy01x = {
        label = "Milkman's Wagon",
        description = "Dairy delivery wagon",
        category = "specialty",
        craftTime = 60000,
        materials = {
            { item = "wood_log", amount = 15 },
            { item = "iron_parts", amount = 8 },
            { item = "wagon_wheel", amount = 4 },
            { item = "nails", amount = 25 },
            { item = "paint", amount = 3 }
        },
        price = 0,
        maxWeight = 320000,
        slots = 50,
        customizations = {
            livery = { -1, 0, 1, 2, 3 },
            tint = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 },
            extras = { 0, 1, 2, 3 }
        }
    },
    wagondoc01x = {
        label = "Traveling Apothecary's Wagon",
        description = "Medicine wagon",
        category = "specialty",
        craftTime = 70000,
        materials = {
            { item = "wood_log", amount = 18 },
            { item = "iron_parts", amount = 10 },
            { item = "wagon_wheel", amount = 4 },
            { item = "leather", amount = 6 },
            { item = "nails", amount = 30 },
            { item = "paint", amount = 5 }
        },
        price = 0,
        maxWeight = 380000,
        slots = 45,
        customizations = {
            livery = { -1, 0, 1, 2, 3, 4 },
            tint = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
            extras = { 0, 1, 2, 3, 4 }
        }
    },
    wagontraveller01x = {
        label = "Traveler's Wagon",
        description = "Merchant's traveling wagon",
        category = "specialty",
        craftTime = 80000,
        materials = {
            { item = "wood_log", amount = 20 },
            { item = "iron_parts", amount = 12 },
            { item = "wagon_wheel", amount = 4 },
            { item = "leather", amount = 8 },
            { item = "nails", amount = 35 },
            { item = "paint", amount = 4 }
        },
        price = 0,
        maxWeight = 420000,
        slots = 60,
        customizations = {
            livery = { -1, 0, 1, 2, 3, 4, 5 },
            tint = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
            extras = { 0, 1, 2, 3, 4 }
        }
    },
    wagonwork01x = {
        label = "Delivery Wagon (Baker)",
        description = "Commercial delivery wagon",
        category = "specialty",
        craftTime = 65000,
        materials = {
            { item = "wood_log", amount = 16 },
            { item = "iron_parts", amount = 9 },
            { item = "wagon_wheel", amount = 4 },
            { item = "nails", amount = 28 },
            { item = "paint", amount = 3 }
        },
        price = 0,
        maxWeight = 360000,
        slots = 55,
        customizations = {
            livery = { -1, 0, 1, 2, 3 },
            tint = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 },
            extras = { 0, 1, 2, 3 }
        }
    }
}

-------------------------------------------------
-- Customization Prices
-------------------------------------------------
Config.CustomizationPrices = {
    livery = 15,    -- Price per livery option
    tint = 25,      -- Price per tint option
    props = 20,     -- Price per prop attachment
    lantern = 10    -- Price for lantern
}

-------------------------------------------------
-- Localization
-------------------------------------------------
Config.Locale = {
    -- General
    ["wagonmaker"] = "Wagon Maker",
    ["crafting_zone"] = "Wagon Crafting Area",
    ["preview_zone"] = "Wagon Preview Area",
    ["parking_npc"] = "Wagon Yard Attendant",
    
    -- Menu
    ["menu_title"] = "Wagon Maker Workshop",
    ["menu_craft"] = "Craft Wagon",
    ["menu_preview"] = "Preview Wagon",
    ["menu_customize"] = "Customize",
    ["menu_confirm"] = "Confirm & Craft",
    ["menu_cancel"] = "Cancel",
    
    -- Crafting
    ["crafting_started"] = "Crafting %s...",
    ["crafting_complete"] = "You have crafted a %s!",
    ["crafting_failed"] = "Crafting failed!",
    ["missing_materials"] = "Missing materials: %s",
    ["insufficient_funds"] = "Insufficient funds! Need $%s",
    ["max_wagons_reached"] = "You already own the maximum number of wagons!",
    ["job_required"] = "You need to be a Wagon Maker to craft wagons!",
    ["grade_required"] = "Your skill level is too low to craft this wagon!",
    
    -- Parking
    ["parking_title"] = "Wagon Yard",
    ["parking_spawn"] = "Spawn Wagon",
    ["parking_store"] = "Store Wagon",
    ["parking_transfer"] = "Transfer Wagon",
    ["parking_sell"] = "Sell Wagon",
    ["parking_rename"] = "Rename Wagon",
    ["parking_delete"] = "Delete Wagon",
    ["no_wagons"] = "You don't own any wagons.",
    ["wagon_spawned"] = "Your wagon has been brought out.",
    ["wagon_stored"] = "Your wagon has been stored.",
    ["already_spawned"] = "You already have a wagon out!",
    ["wagon_not_found"] = "Wagon not found!",
    
    -- Transfer
    ["transfer_title"] = "Transfer Wagon",
    ["transfer_player_id"] = "Enter Player Server ID",
    ["transfer_price"] = "Asking Price (0 for free)",
    ["transfer_sent"] = "Transfer offer sent!",
    ["transfer_received"] = "%s wants to transfer you a %s for $%s",
    ["transfer_accepted"] = "Transfer accepted!",
    ["transfer_declined"] = "Transfer declined.",
    ["transfer_cancelled"] = "Transfer cancelled by owner.",
    
    -- Preview
    ["preview_started"] = "Previewing %s - Use Left/Right Arrow to rotate",
    ["preview_timeout"] = "Preview time expired.",
    
    -- Admin
    ["zone_placed"] = "%s zone placed successfully!",
    ["zone_removed"] = "Zone removed!",
    ["zone_not_found"] = "No zone found nearby.",
    ["no_permission"] = "You don't have permission to do this!"
}

