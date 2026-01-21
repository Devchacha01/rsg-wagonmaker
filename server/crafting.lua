-- ========================================
-- RSG Wagon Maker - Server Crafting (Business Ownership)
-- ========================================
--
-- Projects are owned by the business (job_name) and any authorized employee can contribute.
-- Completed wagons are stored in business stock (wagonmaker_stock) until transferred to a customer.
--
-- Depends on:
--  - rsg-core
--  - ox_lib (lib.callback)
--  - oxmysql (MySQL.*.await)
--  - rsg-inventory (stash access)

-- RedM compatibility: GetRandomIntInRange may be unavailable in some runtimes
if GetRandomIntInRange == nil then
    local __rsg_rng_seeded = false
    function GetRandomIntInRange(min, max)
        min = tonumber(min) or 0
        max = tonumber(max) or (min + 1)
        if max < min then min, max = max, min end

        -- Seed once (best effort). If GetGameTimer exists, it gives better variability.
        if not __rsg_rng_seeded then
            __rsg_rng_seeded = true
            local seed = nil
            if type(GetGameTimer) == 'function' then
                seed = GetGameTimer()
            else
                seed = os.time()
            end
            math.randomseed(seed)
            -- warm up
            math.random(); math.random(); math.random()
        end

        -- Cfx GetRandomIntInRange behavior is [min, max). Guard max==min.
        if max == min then return min end
        return math.random(min, max - 1)
    end
end

local RSGCore = exports['rsg-core']:GetCoreObject()


-- Safe localization helper (supports builds without GetLocale)
local function _L(key, fallback)
    if type(GetLocale) == 'function' then
        local ok, val = pcall(GetLocale, key)
        if ok and val and val ~= '' then return val end
    end
    if Lang and type(Lang.t) == 'function' then
        local ok, val = pcall(function() return Lang:t(key) end)
        if ok and val and val ~= '' then return val end
    end
    return fallback
end

-- ------------------------------
-- JSON helpers
-- ------------------------------
local function SafeJsonDecode(str, fallback)
    if not str or str == '' then return fallback end
    local ok, decoded = pcall(json.decode, str)
    if ok and decoded ~= nil then return decoded end
    return fallback
end

-- ------------------------------
-- Permission helpers
-- ------------------------------
local function IsEmployeeOfRequiredJob(Player, requiredJob)
    if not Config.JobRequired then return true end
    if not Player or not Player.PlayerData or not Player.PlayerData.job then return false end

    local jobName = tostring(Player.PlayerData.job.name or '')

    if Config.JobMode == 'location' then
        if requiredJob and jobName ~= tostring(requiredJob) then
            return false
        end
        return true
    end

    return jobName == tostring(Config.GlobalJobName)
end

local function HasMinGrade(Player, minGrade)
    minGrade = tonumber(minGrade) or 0
    if minGrade <= 0 then return true end
    if not Player or not Player.PlayerData or not Player.PlayerData.job then return false end
    local lvl = tonumber(Player.PlayerData.job.grade and Player.PlayerData.job.grade.level or 0) or 0
    return lvl >= minGrade
end

local function CanBuild(Player)
    local minGrade = (Config.BuildPermissions and Config.BuildPermissions.minGrade) or 0
    return HasMinGrade(Player, minGrade)
end

local function CanCancel(Player)
    local minGrade = (Config.CancelPermissions and Config.CancelPermissions.minGrade) or 2
    return HasMinGrade(Player, minGrade)
end

local function CanTransfer(Player)
    local minGrade = (Config.TransferPermissions and Config.TransferPermissions.minGrade) or 2
    return HasMinGrade(Player, minGrade)
end

-- ------------------------------
-- Shop storage (job stash)
-- ------------------------------
local function GetShopStashId(jobName)
    return 'wagonmaker_stash_' .. tostring(jobName)
end

local function EnsureShopStashExists(stashId)
    if not stashId then return end
    exports['rsg-inventory']:CreateInventory(stashId, {
        label = 'Wagon Maker Storage',
        maxweight = 4000000,
        slots = 50
    })
end

local function CountItemInStash(stashId, item)
    local stash = exports['rsg-inventory']:GetInventory(stashId)
    if not stash or not stash.items then return 0 end
    local total = 0
    for _, it in pairs(stash.items) do
        if it and it.name == item then
            total = total + (tonumber(it.amount) or 0)
        end
    end
    return total
end

local function DepositFromShopStash(stashId, required, delivered)
    delivered = delivered or {}
    if not stashId then return delivered end

    EnsureShopStashExists(stashId)

    for item, reqAmount in pairs(required or {}) do
        local req = tonumber(reqAmount) or 0
        local haveAlready = tonumber(delivered[item] or 0) or 0
        local remaining = req - haveAlready
        if remaining > 0 then
            local stashCount = CountItemInStash(stashId, item)
            if stashCount > 0 then
                local take = math.min(stashCount, remaining)
                if take > 0 then
                    local ok = exports['rsg-inventory']:RemoveItem(stashId, item, take, nil, 'wagonmaker-project', true)
                    if ok then
                        delivered[item] = haveAlready + take
                    end
                end
            end
        end
    end

    return delivered
end

local function DepositFromInventory(src, required, delivered)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return delivered end

    delivered = delivered or {}

    for item, reqAmount in pairs(required or {}) do
        local req = tonumber(reqAmount) or 0
        local haveAlready = tonumber(delivered[item] or 0) or 0
        local remaining = req - haveAlready
        if remaining > 0 then
            local invItem = Player.Functions.GetItemByName(item)
            local invCount = invItem and invItem.amount or 0
            if invCount > 0 then
                local take = math.min(invCount, remaining)
                if take > 0 then
                    Player.Functions.RemoveItem(item, take)
                    delivered[item] = haveAlready + take
                end
            end
        end
    end

    return delivered
end

local function TotalDeliveredCount(delivered)
    local total = 0
    for _, amt in pairs(delivered or {}) do
        total = total + (tonumber(amt) or 0)
    end
    return total
end

-- ------------------------------
-- Progress computation
-- ------------------------------
local function ComputeProgress(required, delivered)
    local totalNeeded, totalDelivered = 0, 0
    local missing = {}

    for item, reqAmount in pairs(required or {}) do
        totalNeeded = totalNeeded + (tonumber(reqAmount) or 0)
        local del = tonumber(delivered and delivered[item] or 0) or 0
        totalDelivered = totalDelivered + math.min(del, tonumber(reqAmount) or 0)
        local needLeft = (tonumber(reqAmount) or 0) - del
        if needLeft > 0 then
            missing[item] = needLeft
        end
    end

    local pct = 0
    if totalNeeded > 0 then
        pct = math.floor((totalDelivered / totalNeeded) * 100)
    end

    local isComplete = (next(missing) == nil)
    return pct, isComplete, missing
end


-- Generate a 6-char serial like AB1234.
local function GenerateWagonSerial()
    local letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local i1 = math.random(1, 26)
    local i2 = math.random(1, 26)
    local c1 = letters:sub(i1, i1)
    local c2 = letters:sub(i2, i2)

    local nums = tostring(math.random(0, 9999))
    nums = string.rep('0', 4 - #nums) .. nums
    return (c1 .. c2) .. nums
end

local function GenerateUniqueWagonSerial()
    for _ = 1, 50 do
        local serial = GenerateWagonSerial()
        local existsStock = MySQL.scalar.await('SELECT COUNT(*) FROM wagonmaker_stock WHERE serial = ?', { serial }) or 0
        if existsStock == 0 then
            local existsOwned = MySQL.scalar.await('SELECT COUNT(*) FROM wagonmaker_wagons WHERE serial = ?', { serial }) or 0
            if existsOwned == 0 then
                return serial
            end
        end
    end
    return 'ZZ' .. tostring(math.random(1000, 9999))
end


-- ------------------------------
-- Logging helper
-- ------------------------------
local function Log(citizenid, action, model, wagonId, details)
    -- Keep existing log table usage for auditability
    MySQL.insert.await(
        'INSERT INTO wagonmaker_logs (citizenid, action, wagon_model, wagon_id, details) VALUES (?, ?, ?, ?, ?)',
        { citizenid, action, model, wagonId, details }
    )
end



-- ------------------------------
-- Company funds (management_funds)
-- Uses the same table rsg-bossmenu / rsg-core ecosystem uses.
-- ------------------------------
local function AddCompanyFunds(jobName, amount)
    if not Config.TransferRules or Config.TransferRules.depositToCompanyFunds ~= true then return end
    local a = tonumber(amount) or 0
    if a <= 0 then return end

    local row = MySQL.single.await('SELECT amount FROM management_funds WHERE job_name = ?', { jobName })
    if row and row.amount ~= nil then
        MySQL.update.await('UPDATE management_funds SET amount = amount + ? WHERE job_name = ?', { a, jobName })
    else
        -- Default type is 'boss' (matches rsg-bossmenu expectation)
        MySQL.insert.await('INSERT INTO management_funds (job_name, amount, type) VALUES (?, ?, ?)', { jobName, a, 'boss' })
    end
end

-- ------------------------------
-- Project ownership: business/job
-- ------------------------------
local function GetOrCreateBusinessProject(jobName, model, wagonName, customization, createdByCitizenId)
    -- One active project per business per model (simple collaboration model).
    local row = MySQL.single.await(
        'SELECT id, materials_required, materials_delivered FROM wagonmaker_projects WHERE job_name = ? AND model = ? AND status = ? LIMIT 1',
        { jobName, model, 'in_progress' }
    )

    if row and row.id then
        return row.id, SafeJsonDecode(row.materials_required, {}), SafeJsonDecode(row.materials_delivered, {})
    end

    local wagonConfig = Config.Wagons[model]
    if not wagonConfig then return nil end

    local required = {}
    for _, mat in ipairs(wagonConfig.materials or {}) do
        required[mat.item] = mat.amount
    end

    local delivered = {}

    local projectId = MySQL.insert.await(
        'INSERT INTO wagonmaker_projects (job_name, created_by, model, name, customization, materials_required, materials_delivered, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        {
            jobName,
            createdByCitizenId,
            model,
            wagonName or wagonConfig.label or model,
            json.encode(customization or {}),
            json.encode(required),
            json.encode(delivered),
            'in_progress'
        }
    )

    return projectId, required, delivered
end

-- ------------------------------
-- Crafting validation callback
-- ------------------------------
lib.callback.register('rsg-wagonmaker:server:canCraft', function(source, model, requiredJob)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return false, 'Player not found' end

    local wagonConfig = Config.Wagons[model]
    if not wagonConfig then return false, 'Invalid wagon model' end

    -- Must be the correct job for the location
    if not IsEmployeeOfRequiredJob(Player, requiredJob) then
        return false, Config.Locale and Config.Locale['job_required'] or 'Authorized Job Required'
    end

    -- Must have grade for this wagon type
    if wagonConfig.requiredGrade then
        local lvl = tonumber(Player.PlayerData.job.grade and Player.PlayerData.job.grade.level or 0) or 0
        if lvl < tonumber(wagonConfig.requiredGrade) then
            return false, Config.Locale and Config.Locale['grade_required'] or 'Insufficient grade'
        end
    end

    -- Business mode: crafting does NOT require player funds (payment happens at transfer).
    -- Non-business mode: keep original intent (optional)
    if not Config.BusinessOwnership then
        if wagonConfig.price and wagonConfig.price > 0 then
            local moneyType = Config.MoneyType or 'cash'
            local money = Player.PlayerData.money and Player.PlayerData.money[moneyType] or 0
            if money < wagonConfig.price then
                return false, string.format(Config.Locale and Config.Locale['insufficient_funds'] or 'Insufficient funds ($%s)', wagonConfig.price)
            end
        end
    end

    -- Progressive mode always allowed to start even without all materials
    if not Config.ProgressiveCrafting then
        -- If someone disables progressive crafting, enforce full materials in player inventory
        for _, mat in ipairs(wagonConfig.materials or {}) do
            local item = Player.Functions.GetItemByName(mat.item)
            local count = item and item.amount or 0
            if count < mat.amount then
                local label = (Config.Materials and Config.Materials[mat.item] and Config.Materials[mat.item].label) or mat.item
                return false, string.format(Config.Locale and Config.Locale['missing_materials'] or 'Missing materials: %s', label)
            end
        end
    end

    return true
end)

-- ------------------------------
-- Start/attach business project
-- ------------------------------
RegisterNetEvent('rsg-wagonmaker:server:startCraftProject', function(model, wagonName, customization, requiredJob)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    if not Config.ProgressiveCrafting then return end

    local wagonConfig = Config.Wagons[model]
    if not wagonConfig then
        TriggerClientEvent('rsg-wagonmaker:client:craftFailed', src, 'Invalid wagon model')
        return
    end

    if not IsEmployeeOfRequiredJob(Player, requiredJob) then
        TriggerClientEvent('rsg-wagonmaker:client:craftFailed', src, 'Unauthorized')
        return
    end

    if not CanBuild(Player) then
        TriggerClientEvent('rsg-wagonmaker:client:craftFailed', src, 'Insufficient permissions')
        return
    end

    -- Per-wagon grade requirement
    if wagonConfig.requiredGrade then
        local lvl = tonumber(Player.PlayerData.job.grade and Player.PlayerData.job.grade.level or 0) or 0
        if lvl < tonumber(wagonConfig.requiredGrade) then
            TriggerClientEvent('rsg-wagonmaker:client:craftFailed', src, Config.Locale and Config.Locale['grade_required'] or 'Grade required')
            return
        end
    end

    local jobName = tostring(Player.PlayerData.job.name)
    local citizenid = tostring(Player.PlayerData.citizenid)

    local projectId, required, delivered = GetOrCreateBusinessProject(jobName, model, wagonName, customization, citizenid)
    if not projectId then
        TriggerClientEvent('rsg-wagonmaker:client:craftFailed', src, 'Project creation failed')
        return
    end

    local pct, isComplete, missing = ComputeProgress(required, delivered)

    TriggerClientEvent('rsg-wagonmaker:client:setCraftProject', src, {
        projectId = projectId,
        progress = pct,
        complete = isComplete,
        missing = missing
    })
end)

-- ------------------------------
-- Contribute to a business project
-- sourceType: 'player' | 'stash' | 'both'
-- ------------------------------
RegisterNetEvent('rsg-wagonmaker:server:contributeCraftProject', function(projectId, requiredJob, sourceType)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    if not Config.ProgressiveCrafting then return end

    if not IsEmployeeOfRequiredJob(Player, requiredJob) then
        TriggerClientEvent('rsg-wagonmaker:client:craftFailed', src, 'Unauthorized')
        return
    end

    if not CanBuild(Player) then
        TriggerClientEvent('rsg-wagonmaker:client:craftFailed', src, 'Insufficient permissions')
        return
    end

    local jobName = tostring(Player.PlayerData.job.name)

    local row = MySQL.single.await(
        'SELECT id, job_name, model, name, customization, materials_required, materials_delivered, status FROM wagonmaker_projects WHERE id = ? AND job_name = ? LIMIT 1',
        { projectId, jobName }
    )

    if not row or not row.id then
        TriggerClientEvent('rsg-wagonmaker:client:craftFailed', src, 'No active project found')
        return
    end

    if row.status ~= 'in_progress' then
        TriggerClientEvent('rsg-wagonmaker:client:craftFailed', src, 'Project not active')
        return
    end

    local wagonConfig = Config.Wagons[row.model]
    if not wagonConfig then
        TriggerClientEvent('rsg-wagonmaker:client:craftFailed', src, 'Invalid wagon model')
        return
    end

    local required = SafeJsonDecode(row.materials_required, {})
    local delivered = SafeJsonDecode(row.materials_delivered, {})

    local beforeCount = TotalDeliveredCount(delivered)

    local mode = sourceType or 'player'

    if mode == 'stash' or mode == 'both' then
        local stashId = GetShopStashId(jobName)
        delivered = DepositFromShopStash(stashId, required, delivered)
    end

    if mode == 'player' or mode == 'both' then
        delivered = DepositFromInventory(src, required, delivered)
    end

    local afterCount = TotalDeliveredCount(delivered)
    local contributed = math.max(0, afterCount - beforeCount)

    MySQL.update.await(
        'UPDATE wagonmaker_projects SET materials_delivered = ?, updated_at = CURRENT_TIMESTAMP() WHERE id = ?',
        { json.encode(delivered), row.id }
    )

    local pct, isComplete, missing = ComputeProgress(required, delivered)

    TriggerClientEvent('rsg-wagonmaker:client:craftProgress', src, {
        projectId = row.id,
        progress = pct,
        complete = isComplete,
        missing = missing,
        contributed = contributed
    })

    if not isComplete then return end

    -- Completion: move to business stock
    local customization = SafeJsonDecode(row.customization, {})

    local stockId = MySQL.insert.await(
        'INSERT INTO wagonmaker_stock (job_name, serial, model, name, livery, tint, status, price, created_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        {
            jobName,
            GenerateUniqueWagonSerial(),
            row.model,
            row.name,
            (customization and customization.livery) or -1,
            (customization and customization.tint) or 0,
            'in_stock',
            0,
            tostring(Player.PlayerData.citizenid)
        }
    )

    if not stockId then
        TriggerClientEvent('rsg-wagonmaker:client:craftFailed', src, 'Database error (stock)')
        return
    end

    MySQL.update.await('UPDATE wagonmaker_projects SET status = ?, updated_at = CURRENT_TIMESTAMP() WHERE id = ?', { 'completed', row.id })

    -- Audit log: use employee citizenid
    Log(tostring(Player.PlayerData.citizenid), 'craft_stock', row.model, stockId, json.encode({
        name = row.name,
        job_name = jobName,
        materials_used = delivered,
        progressive = true
    }))

    TriggerClientEvent('rsg-wagonmaker:client:craftSuccess', src, row.name)
end)

-- ------------------------------
-- Cancel a business project (refund materials to shop stash)
-- ------------------------------
RegisterNetEvent('rsg-wagonmaker:server:cancelCraftProject', function(projectId, requiredJob)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    if not Config.ProgressiveCrafting then return end

    if not IsEmployeeOfRequiredJob(Player, requiredJob) then
        TriggerClientEvent('rsg-wagonmaker:client:craftFailed', src, 'Unauthorized')
        return
    end

    if not CanCancel(Player) then
        TriggerClientEvent('rsg-wagonmaker:client:craftFailed', src, 'Insufficient permissions')
        return
    end

    local jobName = tostring(Player.PlayerData.job.name)

    local row = MySQL.single.await(
        'SELECT id, job_name, model, materials_delivered, status FROM wagonmaker_projects WHERE id = ? AND job_name = ? LIMIT 1',
        { projectId, jobName }
    )

    if not row or not row.id then
        TriggerClientEvent('rsg-wagonmaker:client:craftFailed', src, 'No active project found')
        return
    end

    if row.status ~= 'in_progress' then
        TriggerClientEvent('rsg-wagonmaker:client:craftFailed', src, 'Project not active')
        return
    end

    local stashId = GetShopStashId(jobName)
    EnsureShopStashExists(stashId)

    local delivered = SafeJsonDecode(row.materials_delivered, {})
    local refunded = {}

    for item, amount in pairs(delivered or {}) do
        local amt = tonumber(amount) or 0
        if amt > 0 then
            local ok = exports['rsg-inventory']:AddItem(stashId, item, amt, nil, nil, 'wagonmaker-project-cancel')
            if ok then
                refunded[item] = amt
            end
        end
    end

    MySQL.update.await('UPDATE wagonmaker_projects SET status = ?, updated_at = CURRENT_TIMESTAMP() WHERE id = ?', { 'cancelled', row.id })

    Log(tostring(Player.PlayerData.citizenid), 'cancel_project', row.model, row.id, json.encode({
        job_name = jobName,
        refunded = refunded
    }))

    TriggerClientEvent('rsg-wagonmaker:client:craftCancelled', src, {
        projectId = row.id,
        refunded = refunded
    })
end)

-- ------------------------------
-- Business stock listing (for employee menu)
-- ------------------------------
lib.callback.register('rsg-wagonmaker:server:getStockList', function(source)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return {} end

    local jobName = tostring(Player.PlayerData.job.name)

    if not IsEmployeeOfRequiredJob(Player, nil) then
        return {}
    end

    local rows = MySQL.query.await(
        "SELECT id, serial, model, name, livery, tint, status FROM wagonmaker_stock WHERE job_name = ? AND status IN ('in_stock','reserved') ORDER BY id DESC",
        { jobName }
    )

    return rows or {}
end)



-- ------------------------------
-- Reserve/unreserve stock wagons (for employee spawn/return)
-- ------------------------------
RegisterNetEvent('rsg-wagonmaker:server:reserveStockWagon', function(stockId)
    local src = source
    local Seller = RSGCore.Functions.GetPlayer(src)
    if not Seller then return end
    if not CanTransfer(Seller) then return end

    local jobName = tostring(Seller.PlayerData.job.name)
    local id = tonumber(stockId)
    if not id then return end

    MySQL.update.await(
        "UPDATE wagonmaker_stock SET status = 'reserved' WHERE id = ? AND job_name = ? AND status = 'in_stock'",
        { id, jobName }
    )
end)

RegisterNetEvent('rsg-wagonmaker:server:unreserveStockWagon', function(stockId)
    local src = source
    local Seller = RSGCore.Functions.GetPlayer(src)
    if not Seller then return end
    if not CanTransfer(Seller) then return end

    local jobName = tostring(Seller.PlayerData.job.name)
    local id = tonumber(stockId)
    if not id then return end

    MySQL.update.await(
        "UPDATE wagonmaker_stock SET status = 'in_stock' WHERE id = ? AND job_name = ? AND status = 'reserved'",
        { id, jobName }
    )
end)

-- ------------------------------
-- Move a stock wagon into the employee's personal wagon yard (internal transfer, no payment)
-- ------------------------------
RegisterNetEvent('rsg-wagonmaker:server:moveStockToPersonal', function(stockId, parkingLocation)
    local src = source
    local Seller = RSGCore.Functions.GetPlayer(src)
    if not Seller then return end

    if not CanTransfer(Seller) then
        TriggerClientEvent('rsg-wagonmaker:client:notify', src, 'You are not authorized to transfer wagons.', 'error')
        return
    end

    local jobName = tostring(Seller.PlayerData.job.name)
    local citizenid = tostring(Seller.PlayerData.citizenid)
    local id = tonumber(stockId)
    if not id then
        TriggerClientEvent('rsg-wagonmaker:client:notify', src, 'Invalid stock ID.', 'error')
        return
    end

    local stock = MySQL.single.await(
        "SELECT * FROM wagonmaker_stock WHERE id = ? AND job_name = ? AND status IN ('in_stock','reserved') LIMIT 1",
        { id, jobName }
    )

    if not stock or not stock.id then
        TriggerClientEvent('rsg-wagonmaker:client:notify', src, 'Stock wagon not available.', 'error')
        return
    end

    -- Enforce personal wagon limit (optional)
    local ownedCount = MySQL.scalar.await('SELECT COUNT(*) FROM wagonmaker_wagons WHERE citizenid = ?', { citizenid }) or 0
    if Config.MaxWagonsPerPlayer and ownedCount >= Config.MaxWagonsPerPlayer then
        TriggerClientEvent('rsg-wagonmaker:client:notify', src, 'You have reached your wagon limit.', 'error')
        return
    end

    -- Create personal wagon entry (no payment)
    local serial = (stock.serial and tostring(stock.serial) ~= '' and tostring(stock.serial)) or GenerateUniqueWagonSerial()
    local wagonId = MySQL.insert.await(
        'INSERT INTO wagonmaker_wagons (citizenid, model, name, serial, livery, tint, spawned, stored, parking_location) VALUES (?, ?, ?, ?, ?, ?, 0, 1, ?)',
        {
            citizenid,
            stock.model,
            stock.name,
            serial,
            stock.livery or 0,
            stock.tint or 0,
            parkingLocation
        }
    )

    -- Remove from stock (internal transfer)
    MySQL.delete.await('DELETE FROM wagonmaker_stock WHERE id = ? AND job_name = ?', { id, jobName })

    TriggerClientEvent('rsg-wagonmaker:client:notify', src, 'Cart transferred to your personal wagon yard.', 'success')
end)

-- ------------------------------

-- ------------------------------
-- Rename a stock wagon (business yard)
-- ------------------------------
RegisterNetEvent('rsg-wagonmaker:server:renameStockWagon', function(stockId, newName)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    if type(stockId) ~= 'number' then
        stockId = tonumber(stockId)
    end
    if not stockId then return end

    if type(newName) ~= 'string' then return end
    newName = newName:gsub('[\r\n\t]', ' '):sub(1, 50)

    if newName == '' then return end

    if not CanTransfer(Player) then
        TriggerClientEvent('rsg-wagonmaker:client:notify', src, 'You are not authorized to rename stock wagons.', 'error')
        return
    end

    local jobName = tostring(Player.PlayerData.job.name)

    local stock = MySQL.single.await(
        'SELECT id, job_name FROM wagonmaker_stock WHERE id = ? AND job_name = ? LIMIT 1',
        { stockId, jobName }
    )

    if not stock then
        TriggerClientEvent('rsg-wagonmaker:client:notify', src, 'Stock cart not found for your business.', 'error')
        return
    end

    MySQL.update.await(
        'UPDATE wagonmaker_stock SET name = ? WHERE id = ? AND job_name = ?',
        { newName, stockId, jobName }
    )

    TriggerClientEvent('rsg-wagonmaker:client:notify', src, 'Stock cart renamed to: ' .. newName, 'success')
end)

-- Transfer/sell a stock wagon to a customer (payment required)
-- ------------------------------
RegisterNetEvent('rsg-wagonmaker:server:transferStockWagon', function(stockId, targetSource, price)
    local src = source
    local Seller = RSGCore.Functions.GetPlayer(src)
    if not Seller then return end

    if not CanTransfer(Seller) then
        TriggerClientEvent('rsg-wagonmaker:client:notify', src, 'You are not authorized to transfer wagons.', 'error')
        return
    end

    local jobName = tostring(Seller.PlayerData.job.name)

    local stock = MySQL.single.await(
        'SELECT id, job_name, serial, model, name, livery, tint, status FROM wagonmaker_stock WHERE id = ? AND job_name = ? LIMIT 1',
        { stockId, jobName }
    )

    if not stock or not stock.id or stock.status ~= 'in_stock' then
        TriggerClientEvent('rsg-wagonmaker:client:notify', src, 'Stock wagon not available.', 'error')
        return
    end

    local Buyer = RSGCore.Functions.GetPlayer(tonumber(targetSource))
    if not Buyer then
        TriggerClientEvent('rsg-wagonmaker:client:notify', src, 'Customer not found/online.', 'error')
        return
    end

    -- Optional nearby check
    if Config.TransferRules and Config.TransferRules.requireCustomerNearby then
        local maxDist = tonumber(Config.TransferRules.maxDistance) or 3.0
        local sPed = GetPlayerPed(src)
        local bPed = GetPlayerPed(tonumber(targetSource))
        if sPed ~= 0 and bPed ~= 0 then
            local sCoords = GetEntityCoords(sPed)
            local bCoords = GetEntityCoords(bPed)
            local dist = #(sCoords - bCoords)
            if dist > maxDist then
                TriggerClientEvent('rsg-wagonmaker:client:notify', src, ('Customer must be within %.1fm.'):format(maxDist), 'error')
                return
            end
        end
    end

    -- Enforce payment (Option 1A)
    local p = tonumber(price) or 0
    if p <= 0 then
        TriggerClientEvent('rsg-wagonmaker:client:notify', src, 'Invalid price.', 'error')
        return
    end

    local moneyType = (Config.TransferRules and Config.TransferRules.moneyType) or 'cash'
    local buyerMoney = Buyer.PlayerData.money and Buyer.PlayerData.money[moneyType] or 0
    if buyerMoney < p then
        TriggerClientEvent('rsg-wagonmaker:client:notify', src, 'Customer has insufficient funds.', 'error')
        TriggerClientEvent('rsg-wagonmaker:client:notify', tonumber(targetSource), ('You need $%s to buy this wagon.'):format(p), 'error')
        return
    end

    -- Optional: enforce buyer wagon limit
    local buyerCitizenid = tostring(Buyer.PlayerData.citizenid)
    local ownedCount = MySQL.scalar.await('SELECT COUNT(*) FROM wagonmaker_wagons WHERE citizenid = ?', { buyerCitizenid }) or 0
    if Config.MaxWagonsPerPlayer and ownedCount >= Config.MaxWagonsPerPlayer then
        TriggerClientEvent('rsg-wagonmaker:client:notify', src, 'Customer has reached wagon limit.', 'error')
        TriggerClientEvent('rsg-wagonmaker:client:notify', tonumber(targetSource), 'You have reached your wagon limit.', 'error')
        return
    end

    -- Take payment
    Buyer.Functions.RemoveMoney(moneyType, p, 'wagon-purchase')

    -- Deposit sale proceeds into company funds
    AddCompanyFunds(jobName, p)

    -- Create customer-owned wagon entry
    local serial = (stock.serial and tostring(stock.serial) ~= '' and tostring(stock.serial)) or GenerateUniqueWagonSerial()

    local wagonId = MySQL.insert.await(
        'INSERT INTO wagonmaker_wagons (citizenid, model, name, plate, serial, livery, tint, parking_location) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        {
            buyerCitizenid,
            stock.model,
            stock.name,
            serial, -- plate (compat / display)
            serial, -- serial (unique identifier)
            stock.livery or -1,
            stock.tint or 0,
            1
        }
    )

    if not wagonId then
        -- Rollback payment best-effort
        Buyer.Functions.AddMoney(moneyType, p, 'wagon-purchase-rollback')
        TriggerClientEvent('rsg-wagonmaker:client:notify', src, 'Transfer failed (DB).', 'error')
        return
    end

    -- Mark stock sold (schema-safe: only update columns that exist in the bundled SQL)
    pcall(function()
        MySQL.update.await(
            'UPDATE wagonmaker_stock SET status = ?, price = ? WHERE id = ? AND job_name = ?',
            { 'sold', p, stock.id, jobName }
        )
    end)

    -- Optional: sales ledger (only if table exists in your DB)
    pcall(function()
        MySQL.insert.await(
            'INSERT INTO wagonmaker_sales_ledger (job_name, stock_id, wagon_id, serial, model, name, livery, tint, price, money_type, sold_to, sold_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            {
                jobName,
                stock.id,
                wagonId,
                (stock.serial and tostring(stock.serial) ~= '' and tostring(stock.serial)) or 'UNKNOWN',
                stock.model,
                stock.name,
                stock.livery or -1,
                stock.tint or 0,
                p,
                moneyType,
                buyerCitizenid,
                tostring(Seller.PlayerData.citizenid)
            }
        )
    end)

    Log(tostring(Seller.PlayerData.citizenid), 'transfer_stock', stock.model, stock.id, json.encode({
        job_name = jobName,
        sold_to = buyerCitizenid,
        wagon_id = wagonId,
        price = p,
        moneyType = moneyType
    }))

    TriggerClientEvent('rsg-wagonmaker:client:notify', src, ('Sold wagon to customer for $%s.'):format(p), 'success')
    TriggerClientEvent('rsg-wagonmaker:client:notify', tonumber(targetSource), ('Purchase successful. Wagon added to your storage.'):format(p), 'success')
end)


-- ============================================================
-- Local craft finalization (client-side progress bar completion)
-- ============================================================
RegisterNetEvent('rsg-wagonmaker:server:finalizeCraftLocal', function(modelKey, wagonLabel, customization, requiredJob)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local playerJob = Player.PlayerData.job.name
    local jobOk = true

    if Config.JobRequired then
        if Config.JobMode == 'location' then
            jobOk = (requiredJob and playerJob == requiredJob)
        else
            jobOk = (playerJob == Config.GlobalJobName)
        end
    end

    if not jobOk then
        local msg = _L('no_permission', 'No permission.')
        TriggerClientEvent('RSGCore:Notify', src, msg, 'error')
        -- Let the client know the finalize failed so it does not delete the crafted wagon.
        TriggerClientEvent('rsg-wagonmaker:client:craftFailed', src, msg)
        return
    end

    local wagonCfg = Config.Wagons and Config.Wagons[modelKey] or nil
    if not wagonCfg then
        local msg = 'Invalid wagon recipe.'
        TriggerClientEvent('RSGCore:Notify', src, msg, 'error')
        TriggerClientEvent('rsg-wagonmaker:client:craftFailed', src, msg)
        return
    end

    local materials = wagonCfg.materials or {}
    if type(materials) ~= 'table' or #materials == 0 then
        local msg = 'Recipe has no materials configured.'
        TriggerClientEvent('RSGCore:Notify', src, msg, 'error')
        TriggerClientEvent('rsg-wagonmaker:client:craftFailed', src, msg)
        return
    end

    -- Determine stash id for this job
    local stashId = 'wagonmaker_stash_' .. playerJob

    local function countInOx(inv, item)
        return exports.ox_inventory:Search(inv, 'count', item) or 0
    end

    local function removeFromOx(inv, item, amount)
        local removed = exports.ox_inventory:RemoveItem(inv, item, amount)
        return removed == true or (type(removed) == 'number' and removed > 0)
    end

    local usingOx = (GetResourceState('ox_inventory') == 'started')

    -- IMPORTANT: ox_inventory stashes must be registered before Search/Remove will work reliably.
    -- The job stash is registered when opened, but finalization may happen in a separate session.
    if usingOx and exports.ox_inventory and exports.ox_inventory.RegisterStash then
        exports.ox_inventory:RegisterStash(stashId, 'Wagon Maker Storage', 50, 4000000)
    end

    -- Pre-check: ensure total available across stash + player inv
    for _, req in ipairs(materials) do
        local item = req.item
        local amt = tonumber(req.amount) or 0
        if amt > 0 then
            local have = 0
            if usingOx then
                have = countInOx(stashId, item) + countInOx(src, item)
            else
                -- Best-effort fallback for rsg-inventory
                local ok1, stash = pcall(function() return exports['rsg-inventory']:GetInventory(stashId) end)
                if ok1 and stash and stash.items then
                    for _, it in pairs(stash.items) do
                        if it and it.name == item then have = have + (it.amount or 0) end
                    end
                end
                local ok2, inv = pcall(function() return exports['rsg-inventory']:GetInventory(src) end)
                if ok2 and inv and inv.items then
                    for _, it in pairs(inv.items) do
                        if it and it.name == item then have = have + (it.amount or 0) end
                    end
                end
            end

            if have < amt then
                local msg = ('Missing materials: %s x%s'):format(item, amt - have)
                TriggerClientEvent('RSGCore:Notify', src, msg, 'error')
                TriggerClientEvent('rsg-wagonmaker:client:craftFailed', src, msg)
                return
            end
        end
    end

    -- Consume materials: stash first, then inventory
    for _, req in ipairs(materials) do
        local item = req.item
        local remaining = tonumber(req.amount) or 0
        if remaining > 0 then
            if usingOx then
                local fromStash = math.min(remaining, countInOx(stashId, item))
                if fromStash > 0 then
                    removeFromOx(stashId, item, fromStash)
                    remaining = remaining - fromStash
                end
                if remaining > 0 then
                    removeFromOx(src, item, remaining)
                end
            else
                -- Best-effort rsg-inventory fallback
                local okA = pcall(function() exports['rsg-inventory']:RemoveItem(stashId, item, remaining) end)
                if not okA then
                    pcall(function() exports['rsg-inventory']:RemoveItem(src, item, remaining) end)
                end
            end
        end
    end

    -- Create stock entry
    local serial = (math.random(10000, 99999) .. '-' .. tostring(os.time()))
    local livery = 0
    local tint = 0
    if type(customization) == 'table' then
        livery = tonumber(customization.livery) or 0
        tint = tonumber(customization.tint) or 0
    end

    MySQL.insert('INSERT INTO wagonmaker_stock (job_name, serial, model, name, livery, tint, status, price, created_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        playerJob,
        serial,
        tostring(modelKey),
        tostring(wagonLabel or wagonCfg.label or modelKey),
        livery,
        tint,
        'in_stock',
        tonumber(wagonCfg.price) or 0,
        tostring(Player.PlayerData.citizenid or Player.PlayerData.license or src)
    })

    -- Tell the crafting client it is safe to clean up the local crafted entity.
    TriggerClientEvent('rsg-wagonmaker:client:craftSuccess', src, tostring(wagonLabel or wagonCfg.label or modelKey))
    TriggerClientEvent('RSGCore:Notify', src, _L('craft_complete', 'Craft complete. Added to business stock.'), 'success')
end)
