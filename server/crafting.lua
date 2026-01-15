-- ========================================
-- RSG Wagon Maker - Server Crafting
-- Material validation and wagon creation
-- ========================================

local RSGCore = exports['rsg-core']:GetCoreObject()

-- ========================================
-- Helper Functions
-- ========================================

local function GetPlayerIdentifier(source)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return nil end
    return Player.PlayerData.citizenid
end

local function IsWagonMaker(source, requiredJob)
    if not Config.JobRequired then return true end
    
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local job = Player.PlayerData.job
    local jobName = string.lower(tostring(job.name))
    local reqJob = requiredJob and string.lower(tostring(requiredJob)) or "nil"
    
    print(string.format("[WM Debug] Job Check: PlayerJob='%s', Required='%s'", jobName, reqJob))
    
    -- Check strict match first
    if requiredJob and jobName == string.lower(requiredJob) then
        print("[WM Debug] Strict match success")
        return true
    end
    
    -- Check global match
    if jobName == string.lower(Config.GlobalJobName) then
        print("[WM Debug] Global match success")
        return true
    end
    
    -- Check partial match (Lenient fallback)
    if string.find(jobName, "wagonmaker") or string.find(jobName, "wagon_") then
        print("[WM Debug] Partial match success")
        return true
    end
    
    print("[WM Debug] Job Check FAILED")
    return false
end

local function HasMaterials(source, materials)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return false, 'player_not_found' end
    
    for _, mat in ipairs(materials) do
        local item = Player.Functions.GetItemByName(mat.item)
        local count = item and item.amount or 0
        if count < mat.amount then
            return false, mat.item
        end
    end
    return true
end

local function RemoveMaterials(source, materials)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return end
    
    for _, mat in ipairs(materials) do
        Player.Functions.RemoveItem(mat.item, mat.amount)
    end
end

local function GetWagonCount(citizenid)
    local result = MySQL.scalar.await(
        'SELECT COUNT(*) FROM wagonmaker_wagons WHERE citizenid = ?',
        { citizenid }
    )
    return result or 0
end

local function Log(citizenid, action, model, wagonId, details)
    MySQL.insert.await(
        'INSERT INTO wagonmaker_logs (citizenid, action, wagon_model, wagon_id, details) VALUES (?, ?, ?, ?, ?)',
        { citizenid, action, model, wagonId, details }
    )
end

-- ========================================
-- Crafting Validation Callback
-- ========================================

lib.callback.register('rsg-wagonmaker:server:canCraft', function(source, model, requiredJob)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then 
        return false, 'Player not found' 
    end
    
    local citizenid = Player.PlayerData.citizenid
    local wagonConfig = Config.Wagons[model]
    
    if not wagonConfig then
        return false, 'Invalid wagon model'
    end
    
    -- Check job requirement (and specific location if provided)
    if not IsWagonMaker(source, requiredJob) then
        local pJob = Player.PlayerData.job.name
        -- return false, Config.Locale and Config.Locale['job_required'] or 'Authorized Job Required'
        return false, string.format("Job Mismatch! You are '%s', Zone needs '%s'", pJob, tostring(requiredJob))
    end
    
    -- Check grade requirement
    if wagonConfig.requiredGrade then
        local job = Player.PlayerData.job
        if job.grade.level < wagonConfig.requiredGrade then
            return false, Config.Locale['grade_required']
        end
    end
    
    -- Check wagon limit
    local count = GetWagonCount(citizenid)
    if count >= Config.MaxWagonsPerPlayer then
        return false, Config.Locale['max_wagons_reached']
    end
    
    -- Check materials
    local hasMats, missingItem = HasMaterials(source, wagonConfig.materials)
    if not hasMats then
        local matConfig = Config.Materials[missingItem]
        local label = matConfig and matConfig.label or missingItem
        return false, string.format(Config.Locale['missing_materials'], label)
    end
    
    -- Check additional cost
    if wagonConfig.price > 0 then
        local money = Player.PlayerData.money[Config.MoneyType] or 0
        if money < wagonConfig.price then
            return false, string.format(Config.Locale['insufficient_funds'], wagonConfig.price)
        end
    end
    
    return true
end)

-- ========================================
-- Craft Wagon Event
-- ========================================

-- (Old server-spawned wagon events removed - now using local wagon flow via finalizeCraftLocal)

-- ========================================
-- Local Wagon Crafting Finalize (New Flow)
-- ========================================

RegisterNetEvent('rsg-wagonmaker:server:finalizeCraftLocal', function(model, wagonName, customization, requiredJob)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local wagonConfig = Config.Wagons[model]
    
    if not wagonConfig then
        TriggerClientEvent('rsg-wagonmaker:client:craftFailed', src, 'Invalid wagon model')
        return
    end
    
    -- Validate job again
    if not IsWagonMaker(src, requiredJob) then
        TriggerClientEvent('rsg-wagonmaker:client:craftFailed', src, 'Unauthorized')
        return
    end
    
    -- Check and remove materials
    local hasMats, missingItem = HasMaterials(src, wagonConfig.materials)
    if not hasMats then
        TriggerClientEvent('rsg-wagonmaker:client:craftFailed', src, 'Missing materials')
        return
    end
    
    -- Check and deduct money
    if wagonConfig.price > 0 then
        local money = Player.PlayerData.money[Config.MoneyType] or 0
        if money < wagonConfig.price then
            TriggerClientEvent('rsg-wagonmaker:client:craftFailed', src, 'Insufficient funds')
            return
        end
        Player.Functions.RemoveMoney(Config.MoneyType, wagonConfig.price, 'wagon-crafting')
    end
    
    -- Remove materials
    RemoveMaterials(src, wagonConfig.materials)
    
    -- Save to database
    local wagonId = MySQL.insert.await(
        'INSERT INTO wagonmaker_wagons (citizenid, model, name, livery, tint, parking_location) VALUES (?, ?, ?, ?, ?, ?)',
        { 
            citizenid, 
            model, 
            wagonName, 
            customization and customization.livery or -1,
            customization and customization.tint or 0,
            1  -- Default parking location
        }
    )
    
    if wagonId then
        Log(citizenid, 'craft', model, wagonId, json.encode({
            name = wagonName,
            customization = customization,
            materials_used = wagonConfig.materials,
            price_paid = wagonConfig.price
        }))
        
        TriggerClientEvent('rsg-wagonmaker:client:craftSuccess', src, wagonName)
        print('^2[WM SERVER] Wagon crafted successfully - ID: ' .. wagonId .. ' Model: ' .. model .. '^7')
    else
        TriggerClientEvent('rsg-wagonmaker:client:craftFailed', src, 'Database error')
    end
end)

-- ========================================
-- Material Check Export
-- ========================================

exports('HasCraftingMaterials', function(source, model)
    local wagonConfig = Config.Wagons[model]
    if not wagonConfig then return false end
    
    return HasMaterials(source, wagonConfig.materials)
end)
