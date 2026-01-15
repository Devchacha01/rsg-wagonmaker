-- ========================================
-- RSG Wagon Maker - Server Main
-- Core server initialization and zone management
-- ========================================

local RSGCore = exports['rsg-core']:GetCoreObject()

-- ========================================
-- Initialization
-- ========================================

local ZoneCache = {}

CreateThread(function()
    -- Ensure tables exist
    -- Tables are handled by sql/wagonmaker.sql
    -- Ensuring management_funds exists if not created by SQL
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `management_funds` (
            `job_name` VARCHAR(50) NOT NULL,
            `amount` INT DEFAULT 0,
            `type` VARCHAR(50) DEFAULT 'boss',
            PRIMARY KEY (`job_name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    
    
    -- Populate Zone Cache
    local zones = MySQL.query.await('SELECT * FROM wagonmaker_zones')
    if zones then
        ZoneCache = zones
    end

    if Config and Config.Debug then
        print('^2[RSG-WagonMaker]^7 Server initialized - Database tables verified - Cached ' .. #ZoneCache .. ' zones')
    end
end)

-- ========================================
-- Helper Functions
-- ========================================

function IsAdmin(source)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local playerGroup = Player.PlayerData.group
    for _, group in ipairs(Config and Config.AdminGroups or {}) do
        if playerGroup == group then
            return true
        end
    end
    return false
end

function GetPlayerIdentifier(source)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return nil end
    return Player.PlayerData.citizenid
end

function Log(citizenid, action, model, wagonId, details)
    MySQL.insert.await(
        'INSERT INTO wagonmaker_logs (citizenid, action, wagon_model, wagon_id, details) VALUES (?, ?, ?, ?, ?)',
        { citizenid, action, model, wagonId, details }
    )
end

-- ========================================
-- Zone Management
-- ========================================

RegisterNetEvent('rsg-wagonmaker:server:requestZones', function()
    local src = source
    -- Serve from Cache (Optimization)
    TriggerClientEvent('rsg-wagonmaker:client:loadZones', src, ZoneCache or {})
end)

RegisterNetEvent('rsg-wagonmaker:server:addZone', function(zoneData)
    local src = source
    
    if not IsAdmin(src) then
        TriggerClientEvent('rsg-wagonmaker:client:zoneAddedConfirm', src, false)
        return
    end
    
    local citizenid = GetPlayerIdentifier(src)
    
    local id = MySQL.insert.await(
        'INSERT INTO wagonmaker_zones (type, x, y, z, radius, created_by) VALUES (?, ?, ?, ?, ?, ?)',
        { zoneData.type, zoneData.x, zoneData.y, zoneData.z, zoneData.radius, citizenid }
    )
    
    if id then
        zoneData.id = id
        
        -- Update Cache
        table.insert(ZoneCache, zoneData)
        
        -- Notify all clients
        TriggerClientEvent('rsg-wagonmaker:client:zoneAdded', -1, zoneData)
        TriggerClientEvent('rsg-wagonmaker:client:zoneAddedConfirm', src, true, zoneData.type)
        
        Log(citizenid, 'zone_add', nil, nil, json.encode(zoneData))
        
        if Config and Config.Debug then
            print('^2[RSG-WagonMaker]^7 Zone added: ' .. zoneData.type .. ' at ' .. zoneData.x .. ', ' .. zoneData.y .. ', ' .. zoneData.z)
        end
    else
        TriggerClientEvent('rsg-wagonmaker:client:zoneAddedConfirm', src, false)
    end
end)

RegisterNetEvent('rsg-wagonmaker:server:removeZone', function(zoneId)
    local src = source
    
    if not IsAdmin(src) then
        TriggerClientEvent('rsg-wagonmaker:client:zoneRemovedConfirm', src, false)
        return
    end
    
    local citizenid = GetPlayerIdentifier(src)
    
    local affected = MySQL.update.await(
        'DELETE FROM wagonmaker_zones WHERE id = ?',
        { zoneId }
    )
    
    if affected > 0 then
        -- Update Cache
        for i, z in ipairs(ZoneCache) do
            if z.id == zoneId then
                table.remove(ZoneCache, i)
                break
            end
        end
        
        TriggerClientEvent('rsg-wagonmaker:client:zoneRemoved', -1, zoneId)
        TriggerClientEvent('rsg-wagonmaker:client:zoneRemovedConfirm', src, true)
        
        Log(citizenid, 'zone_remove', nil, nil, 'Zone ID: ' .. zoneId)
    else
        TriggerClientEvent('rsg-wagonmaker:client:zoneRemovedConfirm', src, false)
    end
end)

-- ========================================
-- Job Stash
-- ========================================

RegisterNetEvent('rsg-wagonmaker:server:openJobStash', function(jobName)
    local src = source
    print('^2[RSG-WagonMaker] Server received openJobStash for: ' .. tostring(jobName) .. ' from ' .. src .. '^7')
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Validate job
    local playerJob = Player.PlayerData.job.name
    if Config.JobMode == 'location' then
        if playerJob ~= jobName then
            return
        end
    else
        if playerJob ~= Config.GlobalJobName then
            return
        end
    end

    local stashId = 'wagonmaker_stash_' .. playerJob
    local stashLabel = 'Wagon Maker Storage'

    -- Use ox_inventory for stash
    if GetResourceState('ox_inventory') == 'started' then
        exports.ox_inventory:RegisterStash(stashId, stashLabel, 50, 4000000)
        TriggerClientEvent('ox_inventory:openInventory', src, 'stash', stashId)
    else
        -- Fallback to RSG inventory
        exports['rsg-inventory']:OpenInventory(src, stashId, {
            maxweight = 4000000,
            slots = 50,
            label = stashLabel
        })
    end
end)

RegisterNetEvent('rsg-wagonmaker:server:openWagonStash', function(stashId, data)
    local src = source
    local data = data or {}
    
    if not stashId then return end
    
    local weight = data.maxweight or 50000000
    local slots = data.slots or 50
    local label = data.label or 'Wagon Stash'
    
    print('^2[RSG-WagonMaker] Opening wagon stash: ' .. stashId .. '^7')
    
    if GetResourceState('ox_inventory') == 'started' then
        exports.ox_inventory:RegisterStash(stashId, label, slots, weight)
        TriggerClientEvent('ox_inventory:openInventory', src, 'stash', stashId)
    else
        exports['rsg-inventory']:OpenInventory(src, stashId, {
            maxweight = weight,
            slots = slots,
            label = label
        })
    end
end)

-- ========================================
-- Player Material Callback
-- ========================================

lib.callback.register('rsg-wagonmaker:server:getPlayerMaterials', function(source)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return {} end
    
    local materials = {}
    
    for itemName, _ in pairs(Config and Config.Materials or {}) do
        local item = Player.Functions.GetItemByName(itemName)
        materials[itemName] = item and item.amount or 0
    end
    
    return materials
end)

-- ========================================
-- Wagon Count Check
-- ========================================

lib.callback.register('rsg-wagonmaker:server:getWagonCount', function(source)
    local citizenid = GetPlayerIdentifier(source)
    if not citizenid then return 0 end
    
    local result = MySQL.scalar.await(
        'SELECT COUNT(*) FROM wagonmaker_wagons WHERE citizenid = ?',
        { citizenid }
    )
    return result or 0
end)

-- ========================================
-- Management System (Fallback)
-- ========================================

RegisterNetEvent('rsg-wagonmaker:server:depositMoney', function(amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local jobName = Player.PlayerData.job.name
    local amount = tonumber(amount)

    if amount and amount > 0 then
        if Player.Functions.RemoveMoney('cash', amount) then
            MySQL.insert('INSERT INTO management_funds (job_name, amount, type) VALUES (?, ?, "boss") ON DUPLICATE KEY UPDATE amount = amount + ?', {jobName, amount, amount})
            TriggerClientEvent('ox_lib:notify', src, {type='success', description='Deposited $'..amount})
        else
            TriggerClientEvent('ox_lib:notify', src, {type='error', description='Not enough cash'})
        end
    end
end)

RegisterNetEvent('rsg-wagonmaker:server:withdrawMoney', function(amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local jobName = Player.PlayerData.job.name
    local amount = tonumber(amount)
    
    -- Check permission (Manager+)
    if Player.PlayerData.job.grade.level < Config.JobGrades.manager then
        TriggerClientEvent('ox_lib:notify', src, {type='error', description='No permission'})
        return
    end

    if amount and amount > 0 then
        local result = MySQL.scalar.await('SELECT amount FROM management_funds WHERE job_name = ?', {jobName})
        if result and result >= amount then
            MySQL.update('UPDATE management_funds SET amount = amount - ? WHERE job_name = ?', {amount, jobName})
            Player.Functions.AddMoney('cash', amount)
            TriggerClientEvent('ox_lib:notify', src, {type='success', description='Withdrew $'..amount})
        else
            TriggerClientEvent('ox_lib:notify', src, {type='error', description='Insufficient company funds'})
        end
    end
end)

lib.callback.register('rsg-wagonmaker:server:getFundBalance', function(source)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return 0 end
    
    local jobName = Player.PlayerData.job.name
    return MySQL.scalar.await('SELECT amount FROM management_funds WHERE job_name = ?', {jobName}) or 0
end)

-- ========================================
-- Exports
-- ========================================

exports('GetPlayerWagonCount', function(source)
    local citizenid = GetPlayerIdentifier(source)
    if not citizenid then return 0 end
    
    local result = MySQL.scalar.await(
        'SELECT COUNT(*) FROM wagonmaker_wagons WHERE citizenid = ?',
        { citizenid }
    )
    
    return result or 0
end)

exports('GetPlayerWagons', function(source)
    local citizenid = GetPlayerIdentifier(source)
    if not citizenid then return {} end
    
    local wagons = MySQL.query.await(
        'SELECT * FROM wagonmaker_wagons WHERE citizenid = ?',
        { citizenid }
    )
    
    return wagons or {}
end)

exports('IsAdmin', IsAdmin)
