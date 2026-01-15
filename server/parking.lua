-- ========================================
-- RSG Wagon Maker - Server Parking
-- Wagon storage and retrieval management
-- ========================================

local RSGCore = exports['rsg-core']:GetCoreObject()

-- Active Wagon Tracker (OneSync Reliability)
-- [wagonId] = networkId
local ActiveWagons = {}

-- ========================================
-- Helper Functions
-- ========================================

local function GetPlayerIdentifier(source)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return nil end
    return Player.PlayerData.citizenid
end

local function Log(citizenid, action, model, wagonId, details)
    MySQL.insert.await(
        'INSERT INTO wagonmaker_logs (citizenid, action, wagon_model, wagon_id, details) VALUES (?, ?, ?, ?, ?)',
        { citizenid, action, model, wagonId, details }
    )
end

-- ========================================
-- Get Player Wagons
-- ========================================

lib.callback.register('rsg-wagonmaker:server:getPlayerWagons', function(source)
    local citizenid = GetPlayerIdentifier(source)
    if not citizenid then return {} end
    
    local wagons = MySQL.query.await(
        'SELECT * FROM wagonmaker_wagons WHERE citizenid = ? ORDER BY created_at DESC',
        { citizenid }
    )
    
    -- Auto-Fix Ghost Wagons
    if wagons then
        for _, wagon in ipairs(wagons) do
            if wagon.spawned == 1 then
                local activeNetId = ActiveWagons[wagon.id]
                local entityExists = false
                
                if activeNetId then
                    local entity = NetworkGetEntityFromNetworkId(activeNetId)
                    if DoesEntityExist(entity) then
                        entityExists = true
                    end
                end
                
                if not entityExists then
                    -- Auto-Correct Database
                    MySQL.update('UPDATE wagonmaker_wagons SET spawned = 0 WHERE id = ?', { wagon.id })
                    wagon.spawned = 0 -- Update local result for UI
                    ActiveWagons[wagon.id] = nil
                    if Config and Config.Debug then
                        print('^3[RSG-WagonMaker] Auto-fixed ghost wagon: ' .. wagon.id .. '^7')
                    end
                end
            end
        end
    end
    
    return wagons or {}
end)

lib.callback.register('rsg-wagonmaker:server:getWagonById', function(source, wagonId)
    local citizenid = GetPlayerIdentifier(source)
    if not citizenid then return nil end
    
    local wagon = MySQL.single.await(
        'SELECT * FROM wagonmaker_wagons WHERE id = ? AND citizenid = ?',
        { wagonId, citizenid }
    )
    
    return wagon
end)

-- ========================================
-- Wagon Spawn/Store Events
-- ========================================

RegisterNetEvent('rsg-wagonmaker:server:wagonSpawned', function(wagonId, networkId, model)
    local src = source
    local citizenid = GetPlayerIdentifier(src)
    
    if not citizenid then return end
    
    -- Verify ownership
    local wagon = MySQL.single.await(
        'SELECT * FROM wagonmaker_wagons WHERE id = ? AND citizenid = ?',
        { wagonId, citizenid }
    )
    
    if not wagon then
        if Config and Config.Debug then
            print('^1[RSG-WagonMaker]^7 Unauthorized spawn attempt for wagon ' .. wagonId)
        end
        return
    end
    
    -- Mark as spawned
    MySQL.update.await(
        'UPDATE wagonmaker_wagons SET spawned = 1 WHERE id = ?',
        { wagonId }
    )
    
    -- Track Active Entity
    ActiveWagons[wagonId] = networkId
    
    -- Register wagon inventory stash if enabled
    if Config and Config.UseWagonInventory then
        local wagonConfig = Config.Wagons[model or wagon.model]
        if wagonConfig then
            local stashId = 'wagon_' .. wagonId
            
            -- Check for ox_inventory
            if GetResourceState('ox_inventory') == 'started' and exports.ox_inventory and exports.ox_inventory.RegisterStash then
                local success, result = pcall(function() 
                    exports.ox_inventory:RegisterStash(stashId, wagon.name or 'Wagon Stash', wagonConfig.slots or 50, wagonConfig.maxWeight or 500000)
                end)
                if not success then
                    print('^3[RSG-WagonMaker] Warning: Failed to register stash with ox_inventory: ' .. tostring(result) .. '^7')
                end
            end
            -- RSG Inventory implies dynamic creation, no server-side registration needed usually
        end
    end
    
    Log(citizenid, 'spawn', wagon.model, wagonId, nil)
    
    if Config and Config.Debug then
        print('^2[RSG-WagonMaker]^7 Wagon ' .. wagonId .. ' spawned for ' .. citizenid)
    end
end)

-- ========================================
-- Wagon Stash Handler
-- ========================================

RegisterNetEvent('rsg-wagonmaker:server:openWagonStash', function(stashId, stashData)
    local src = source
    
    if not stashId or not stashData then
        print('^1[RSG-WagonMaker]^7 Invalid stash data received')
        return
    end
    
    -- Use rsg-inventory export
    if GetResourceState('rsg-inventory') == 'started' then
        exports['rsg-inventory']:OpenInventory(src, stashId, {
            maxweight = stashData.maxweight or 500000,
            slots = stashData.slots or 50,
            label = stashData.label or 'Wagon Stash'
        })
    elseif GetResourceState('ox_inventory') == 'started' then
        -- ox_inventory fallback
        exports.ox_inventory:forceOpenInventory(src, 'stash', stashId)
    else
        print('^1[RSG-WagonMaker]^7 No compatible inventory system found')
    end
end)

RegisterNetEvent('rsg-wagonmaker:server:wagonStored', function(wagonId)
    local src = source
    local citizenid = GetPlayerIdentifier(src)
    
    if not citizenid then return end
    
    -- Verify ownership
    local wagon = MySQL.single.await(
        'SELECT * FROM wagonmaker_wagons WHERE id = ? AND citizenid = ?',
        { wagonId, citizenid }
    )
    
    if not wagon then
        if Config and Config.Debug then
            print('^1[RSG-WagonMaker]^7 Unauthorized store attempt for wagon ' .. wagonId)
        end
        return
    end
    
    -- Mark as stored
    MySQL.update.await(
        'UPDATE wagonmaker_wagons SET spawned = 0 WHERE id = ?',
        { wagonId }
    )
    
    -- Clear Active Tracker
    ActiveWagons[wagonId] = nil
    
    Log(citizenid, 'store', wagon.model, wagonId, nil)
    
    if Config and Config.Debug then
        print('^2[RSG-WagonMaker]^7 Wagon ' .. wagonId .. ' stored for ' .. citizenid)
    end
end)

-- ========================================
-- Rename Wagon
-- ========================================

RegisterNetEvent('rsg-wagonmaker:server:renameWagon', function(wagonId, newName)
    local src = source
    local citizenid = GetPlayerIdentifier(src)
    
    if not citizenid then return end
    
    -- Verify ownership
    local wagon = MySQL.single.await(
        'SELECT * FROM wagonmaker_wagons WHERE id = ? AND citizenid = ?',
        { wagonId, citizenid }
    )
    
    if not wagon then return end
    
    -- Sanitize name
    newName = string.sub(newName, 1, 50)
    
    MySQL.update.await(
        'UPDATE wagonmaker_wagons SET name = ? WHERE id = ?',
        { newName, wagonId }
    )
    
    Log(citizenid, 'rename', wagon.model, wagonId, 'New name: ' .. newName)
    
    TriggerClientEvent('rsg-wagonmaker:client:wagonRenamed', src, newName)
end)

-- ========================================
-- Delete Wagon
-- ========================================

RegisterNetEvent('rsg-wagonmaker:server:deleteWagon', function(wagonId)
    local src = source
    local citizenid = GetPlayerIdentifier(src)
    
    if not citizenid then return end
    
    -- Verify ownership
    local wagon = MySQL.single.await(
        'SELECT * FROM wagonmaker_wagons WHERE id = ? AND citizenid = ?',
        { wagonId, citizenid }
    )
    
    if not wagon then return end
    
    -- Delete any pending transfers
    MySQL.update.await(
        'DELETE FROM wagonmaker_transfers WHERE wagon_id = ?',
        { wagonId }
    )
    
    -- Delete wagon
    MySQL.update.await(
        'DELETE FROM wagonmaker_wagons WHERE id = ?',
        { wagonId }
    )
    
    Log(citizenid, 'delete', wagon.model, wagonId, nil)
    
    TriggerClientEvent('rsg-wagonmaker:client:wagonDeleted', src)
    
    if Config and Config.Debug then
        print('^2[RSG-WagonMaker]^7 Wagon ' .. wagonId .. ' deleted by ' .. citizenid)
    end
end)

-- ========================================
-- Change Parking Location
-- ========================================

RegisterNetEvent('rsg-wagonmaker:server:changeParkingLocation', function(wagonId, locationId)
    local src = source
    local citizenid = GetPlayerIdentifier(src)
    
    if not citizenid then return end
    
    -- Verify ownership
    local wagon = MySQL.single.await(
        'SELECT * FROM wagonmaker_wagons WHERE id = ? AND citizenid = ?',
        { wagonId, citizenid }
    )
    
    if not wagon then return end
    
    -- Validate location
    local validLocation = false
    for _, npc in ipairs(Config.ParkingNPCs) do
        if npc.id == locationId then
            validLocation = true
            break
        end
    end
    
    if not validLocation then return end
    
    MySQL.update.await(
        'UPDATE wagonmaker_wagons SET parking_location = ? WHERE id = ?',
        { locationId, wagonId }
    )
    
    Log(citizenid, 'move', wagon.model, wagonId, 'New location: ' .. locationId)
end)

-- ========================================
-- Get Wagon by ID (for other resources)
-- ========================================

exports('GetWagonById', function(wagonId)
    local wagon = MySQL.single.await(
        'SELECT * FROM wagonmaker_wagons WHERE id = ?',
        { wagonId }
    )
    return wagon
end)

exports('GetWagonOwner', function(wagonId)
    local wagon = MySQL.single.await(
        'SELECT citizenid FROM wagonmaker_wagons WHERE id = ?',
        { wagonId }
    )
    return wagon and wagon.citizenid or nil
end)

exports('IsWagonSpawned', function(wagonId)
    local wagon = MySQL.single.await(
        'SELECT spawned FROM wagonmaker_wagons WHERE id = ?',
        { wagonId }
    )
    return wagon and wagon.spawned == 1 or false
end)

-- Force delete wagon entity (networked fix)
RegisterNetEvent('rsg-wagonmaker:server:forceDeleteWagon', function(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(entity) then
        DeleteEntity(entity)
        -- print('^2[RSG-WagonMaker] Server deleted wagon entity: ' .. netId .. '^7')
    end
end)
