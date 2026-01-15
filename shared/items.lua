-- ========================================
-- RSG Wagon Maker - Item Definitions
-- This file defines crafting materials for NUI display
-- ========================================

-- Material configuration for NUI display (labels and images)
Config = Config or {}
Config.Materials = {
    ['wood_log']     = { label = 'Wood Log',     image = 'wood_log.png' },
    ['iron_parts']   = { label = 'Iron Parts',   image = 'iron_parts.png' },
    ['steel_plate']  = { label = 'Steel Plate',  image = 'steel_plate.png' },
    ['wagon_wheel']  = { label = 'Wagon Wheel',  image = 'wagon_wheel.png' },
    ['leather']      = { label = 'Leather',      image = 'leather.png' },
    ['rope']         = { label = 'Rope',         image = 'rope.png' },
    ['nails']        = { label = 'Nails',        image = 'nails.png' },
    ['paint']        = { label = 'Paint',        image = 'paint.png' },
}

--[[
    =====================================================
    INSTALLATION: Add these to rsg-core/shared/items.lua
    =====================================================
    Copy the lines below into your RSGShared.Items table:
    
    -- RSG WAGONMAKER MATERIALS
    ['wood_log']     = { name = 'wood_log',     label = 'Wood Log',     weight = 5000, type = 'item', image = 'wood_log.png',     unique = false, useable = false, shouldClose = false, combinable = nil, description = 'Sturdy timber for wagon frame construction' },
    ['iron_parts']   = { name = 'iron_parts',   label = 'Iron Parts',   weight = 3000, type = 'item', image = 'iron_parts.png',   unique = false, useable = false, shouldClose = false, combinable = nil, description = 'Metal fittings and hardware for wagon assembly' },
    ['steel_plate']  = { name = 'steel_plate',  label = 'Steel Plate',  weight = 4000, type = 'item', image = 'steel_plate.png',  unique = false, useable = false, shouldClose = false, combinable = nil, description = 'Reinforced steel sheets for heavy-duty wagons' },
    ['wagon_wheel']  = { name = 'wagon_wheel',  label = 'Wagon Wheel',  weight = 8000, type = 'item', image = 'wagon_wheel.png',  unique = false, useable = false, shouldClose = false, combinable = nil, description = 'Pre-crafted wooden wheel with iron rim' },
    ['leather']      = { name = 'leather',      label = 'Leather',      weight = 500,  type = 'item', image = 'leather.png',      unique = false, useable = false, shouldClose = false, combinable = nil, description = 'Tanned hide for seats and wagon covers' },
    ['rope']         = { name = 'rope',         label = 'Rope',         weight = 1000, type = 'item', image = 'rope.png',         unique = false, useable = false, shouldClose = false, combinable = nil, description = 'Hemp rope for securing cargo and rigging' },
    ['nails']        = { name = 'nails',        label = 'Nails',        weight = 100,  type = 'item', image = 'nails.png',        unique = false, useable = false, shouldClose = false, combinable = nil, description = 'Iron nails for wagon construction' },
    ['paint']        = { name = 'paint',        label = 'Paint',        weight = 2000, type = 'item', image = 'paint.png',        unique = false, useable = false, shouldClose = false, combinable = nil, description = 'Wood stain and paint for finishing wagons' },
]]
