-- ========================================
-- RSG Wagon Maker - Admin Zone Management
-- Commands for placing and removing zones
-- ========================================

local RSGCore = exports['rsg-core']:GetCoreObject()

-- ========================================
-- Admin Commands
-- ========================================

-- Add a zone at current position
RegisterCommand('wm_addzone', function(source, args)
    if not IsAdmin() then
        Notify(GetLocale('no_permission'), 'error')
        return
    end
    
    local zoneType = args[1]
    if not zoneType or (zoneType ~= 'crafting' and zoneType ~= 'preview') then
        Notify('Usage: /wm_addzone [crafting|preview]', 'error')
        return
    end
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    local heading = GetEntityHeading(PlayerPedId())
    local radius = tonumber(args[2]) or (zoneType == 'crafting' and Config.CraftingMarker.radius or Config.PreviewMarker.radius)
    
    TriggerServerEvent('rsg-wagonmaker:server:addZone', {
        type = zoneType,
        x = playerCoords.x,
        y = playerCoords.y,
        z = playerCoords.z,
        heading = heading,
        model = Config.DefaultWorkerModel,
        radius = radius
    })
end, false)

-- Get current coordinates (Anyone can use)
RegisterCommand('coords', function(source, args)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    
    -- Print to console (F8)
    print('^3[Coords]^7')
    print(string.format('  vector3(%.2f, %.2f, %.2f)', playerCoords.x, playerCoords.y, playerCoords.z))
    print(string.format('  Heading: %.2f', heading))
    
    Notify('Coords printed to F8 console!', 'success')
end, false)

-- Remove nearest zone
RegisterCommand('wm_removezone', function(source, args)
    if not IsAdmin() then
        Notify(GetLocale('no_permission'), 'error')
        return
    end
    
    local zone, dist = GetClosestZone()
    if not zone or dist > 10.0 then
        Notify(GetLocale('zone_not_found'), 'error')
        return
    end
    
    TriggerServerEvent('rsg-wagonmaker:server:removeZone', zone.id)
end, false)

-- List all zones
RegisterCommand('wm_listzones', function(source, args)
    if not IsAdmin() then
        Notify(GetLocale('no_permission'), 'error')
        return
    end
    
    if #Zones == 0 then
        Notify('No zones configured', 'inform')
        return
    end
    
    print('^3[RSG-WagonMaker] Zone List:^7')
    for _, zone in ipairs(Zones) do
        print(string.format('  ID: %d | Type: %s | Coords: %.2f, %.2f, %.2f | Radius: %.1f',
            zone.id, zone.type, zone.x, zone.y, zone.z, zone.radius))
    end
    
    Notify('Zone list printed to console (F8)', 'success')
end, false)

-- Teleport to zone
RegisterCommand('wm_goto', function(source, args)
    if not IsAdmin() then
        Notify(GetLocale('no_permission'), 'error')
        return
    end
    
    local zoneId = tonumber(args[1])
    if not zoneId then
        Notify('Usage: /wm_goto [zone_id]', 'error')
        return
    end
    
    for _, zone in ipairs(Zones) do
        if zone.id == zoneId then
            SetEntityCoords(PlayerPedId(), zone.x, zone.y, zone.z, false, false, false, false)
            Notify('Teleported to zone ' .. zoneId, 'success')
            return
        end
    end
    
    Notify('Zone not found', 'error')
end, false)

-- Add parking NPC at current position
RegisterCommand('wm_addparking', function(source, args)
    if not IsAdmin() then
        Notify(GetLocale('no_permission'), 'error')
        return
    end
    
    local name = table.concat(args, ' ')
    if not name or name == '' then
        Notify('Usage: /wm_addparking [name]', 'error')
        return
    end
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    local heading = GetEntityHeading(PlayerPedId())
    
    -- Calculate spawn point offset
    local forwardVector = GetEntityForwardVector(PlayerPedId())
    local spawnOffset = playerCoords + (forwardVector * 5.0)
    
    local parkingData = {
        name = name,
        coords = playerCoords,
        heading = heading,
        spawnPoint = spawnOffset,
        spawnHeading = heading
    }
    
    -- Print config entry for manual addition
    print('^3[RSG-WagonMaker] Add this to Config.ParkingNPCs:^7')
    print(string.format([[
{
    id = X, -- Replace with next ID
    name = "%s",
    coords = vector3(%.2f, %.2f, %.2f),
    heading = %.2f,
    model = "s_m_m_cghworker_01",
    spawnPoint = vector3(%.2f, %.2f, %.2f),
    spawnHeading = %.2f,
    blip = {
        enabled = true,
        sprite = 1012165077,
        name = "Wagon Yard",
        scale = 0.8
    }
},]], 
        name, 
        playerCoords.x, playerCoords.y, playerCoords.z,
        heading,
        spawnOffset.x, spawnOffset.y, spawnOffset.z,
        heading
    ))
    
    Notify('Parking NPC config printed to console', 'success')
end, false)

-- ========================================
-- Server Callbacks
-- ========================================

RegisterNetEvent('rsg-wagonmaker:client:zoneAddedConfirm', function(success, zoneType)
    if success then
        Notify(GetLocale('zone_placed', zoneType), 'success')
    else
        Notify('Failed to add zone', 'error')
    end
end)

RegisterNetEvent('rsg-wagonmaker:client:zoneRemovedConfirm', function(success)
    if success then
        Notify(GetLocale('zone_removed'), 'success')
    else
        Notify('Failed to remove zone', 'error')
    end
end)

-- ========================================
-- Debug Commands
-- ========================================

if Config.Debug then
    RegisterCommand('wm_debug', function()
        if not IsAdmin() then return end
        
        print('^3[RSG-WagonMaker] Debug Info:^7')
        print('  Player Data:', json.encode(PlayerData))
        print('  Is WagonMaker:', IsWagonMaker())
        print('  Is Admin:', IsAdmin())
        print('  Zones:', #Zones)
        print('  Parking NPCs:', #Config.ParkingNPCs)
    end, false)
    
    RegisterCommand('wm_reloadnpcs', function()
        if not IsAdmin() then return end
        
        -- Clear existing NPCs
        for _, ped in pairs(ParkingNPCs) do
            if DoesEntityExist(ped) then
                DeleteEntity(ped)
            end
        end
        ParkingNPCs = {}
        
        -- Clear blips
        for _, blip in pairs(ParkingBlips) do
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end
        ParkingBlips = {}
        
        -- Respawn
        SpawnParkingNPCs()
        Notify('Parking NPCs reloaded', 'success')
    end, false)
end
