-- ========================================
-- RSG Wagon Maker - Server Transfer
-- Player-to-player wagon transfer system
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

local function GetPlayerName(source)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return 'Unknown' end
    return Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
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
-- Get Pending Transfers
-- ========================================

lib.callback.register('rsg-wagonmaker:server:getPendingTransfers', function(source)
    local citizenid = GetPlayerIdentifier(source)
    if not citizenid then return {} end
    
    local transfers = MySQL.query.await([[
        SELECT 
            t.*,
            w.name as wagon_name,
            w.model as wagon_model,
            c.charinfo
        FROM wagonmaker_transfers t
        JOIN wagonmaker_wagons w ON t.wagon_id = w.id
        JOIN players c ON t.from_citizenid = c.citizenid
        WHERE t.to_citizenid = ? AND t.status = 'pending'
        ORDER BY t.created_at DESC
    ]], { citizenid })
    
    -- Parse charinfo to get name
    if transfers then
        for _, transfer in ipairs(transfers) do
            local charinfo = json.decode(transfer.charinfo or '{}')
            transfer.from_name = (charinfo.firstname or 'Unknown') .. ' ' .. (charinfo.lastname or '')
            transfer.charinfo = nil -- Remove raw data
        end
    end
    
    return transfers or {}
end)

-- ========================================
-- Create Transfer Offer
-- ========================================

RegisterNetEvent('rsg-wagonmaker:server:createTransfer', function(wagonId, targetServerId, price)
    local src = source
    local citizenid = GetPlayerIdentifier(src)
    
    if not citizenid then return end
    
    -- Verify ownership
    local wagon = MySQL.single.await(
        'SELECT * FROM wagonmaker_wagons WHERE id = ? AND citizenid = ?',
        { wagonId, citizenid }
    )
    
    if not wagon then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'You do not own this wagon',
            type = 'error'
        })
        return
    end
    
    -- Check if wagon is spawned
    if wagon.spawned == 1 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'Store the wagon first before transferring',
            type = 'error'
        })
        return
    end
    
    -- Get target player
    local TargetPlayer = RSGCore.Functions.GetPlayer(targetServerId)
    if not TargetPlayer then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'Player not found',
            type = 'error'
        })
        return
    end
    
    local targetCitizenId = TargetPlayer.PlayerData.citizenid
    
    -- Don't allow self-transfer
    if targetCitizenId == citizenid then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'Cannot transfer to yourself',
            type = 'error'
        })
        return
    end
    
    -- Check if target has room for another wagon
    local targetWagonCount = GetWagonCount(targetCitizenId)
    if targetWagonCount >= Config.MaxWagonsPerPlayer then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'Target player has maximum wagons',
            type = 'error'
        })
        return
    end
    
    -- Cancel any existing pending transfer for this wagon
    MySQL.update.await(
        "UPDATE wagonmaker_transfers SET status = 'cancelled' WHERE wagon_id = ? AND status = 'pending'",
        { wagonId }
    )
    
    -- Create new transfer
    local transferId = MySQL.insert.await(
        'INSERT INTO wagonmaker_transfers (wagon_id, from_citizenid, to_citizenid, price) VALUES (?, ?, ?, ?)',
        { wagonId, citizenid, targetCitizenId, price or 0 }
    )
    
    if transferId then
        local senderName = GetPlayerName(src)
        local wagonConfig = Config.Wagons[wagon.model]
        local wagonLabel = wagonConfig and wagonConfig.label or wagon.model
        
        Log(citizenid, 'transfer_create', wagon.model, wagonId, json.encode({
            to = targetCitizenId,
            price = price
        }))
        
        TriggerClientEvent('rsg-wagonmaker:client:transferSent', src)
        TriggerClientEvent('rsg-wagonmaker:client:transferReceived', targetServerId, senderName, wagonLabel, price or 0)
        
        if Config.Debug then
            print('^2[RSG-WagonMaker]^7 Transfer created: Wagon ' .. wagonId .. ' from ' .. citizenid .. ' to ' .. targetCitizenId)
        end
    end
end)

-- ========================================
-- Respond to Transfer Offer
-- ========================================

RegisterNetEvent('rsg-wagonmaker:server:respondTransfer', function(transferId, accepted)
    local src = source
    local citizenid = GetPlayerIdentifier(src)
    
    if not citizenid then return end
    
    -- Get transfer
    local transfer = MySQL.single.await([[
        SELECT t.*, w.model, w.name as wagon_name
        FROM wagonmaker_transfers t
        JOIN wagonmaker_wagons w ON t.wagon_id = w.id
        WHERE t.id = ? AND t.to_citizenid = ? AND t.status = 'pending'
    ]], { transferId, citizenid })
    
    if not transfer then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'Transfer not found or already processed',
            type = 'error'
        })
        return
    end
    
    if accepted then
        local Player = RSGCore.Functions.GetPlayer(src)
        
        -- Check if recipient can afford it
        if transfer.price > 0 then
            local money = Player.PlayerData.money[Config.MoneyType] or 0
            if money < transfer.price then
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Error',
                    description = 'Insufficient funds',
                    type = 'error'
                })
                return
            end
            
            -- Deduct money from buyer
            Player.Functions.RemoveMoney(Config.MoneyType, transfer.price, 'wagon-transfer')
            
            -- Add money to seller (if online)
            local SenderPlayer = RSGCore.Functions.GetPlayerByCitizenId(transfer.from_citizenid)
            if SenderPlayer then
                SenderPlayer.Functions.AddMoney(Config.MoneyType, transfer.price, 'wagon-sale')
                TriggerClientEvent('ox_lib:notify', SenderPlayer.PlayerData.source, {
                    title = 'Wagon Sold',
                    description = 'Your wagon was sold for $' .. transfer.price,
                    type = 'success'
                })
            else
                -- TODO: Add to offline player balance (requires additional logic)
                if Config.Debug then
                    print('^3[RSG-WagonMaker]^7 Seller offline, money not added: $' .. transfer.price)
                end
            end
        end
        
        -- Transfer wagon ownership
        MySQL.update.await(
            'UPDATE wagonmaker_wagons SET citizenid = ? WHERE id = ?',
            { citizenid, transfer.wagon_id }
        )
        
        -- Mark transfer as accepted
        MySQL.update.await(
            "UPDATE wagonmaker_transfers SET status = 'accepted' WHERE id = ?",
            { transferId }
        )
        
        Log(citizenid, 'transfer_accept', transfer.model, transfer.wagon_id, json.encode({
            from = transfer.from_citizenid,
            price = transfer.price
        }))
        
        TriggerClientEvent('rsg-wagonmaker:client:transferAccepted', src)
        
        -- Notify sender if online
        local SenderPlayer = RSGCore.Functions.GetPlayerByCitizenId(transfer.from_citizenid)
        if SenderPlayer then
            TriggerClientEvent('ox_lib:notify', SenderPlayer.PlayerData.source, {
                title = 'Transfer Accepted',
                description = 'Your wagon transfer was accepted',
                type = 'success'
            })
        end
        
        if Config.Debug then
            print('^2[RSG-WagonMaker]^7 Transfer accepted: Wagon ' .. transfer.wagon_id .. ' transferred to ' .. citizenid)
        end
    else
        -- Decline transfer
        MySQL.update.await(
            "UPDATE wagonmaker_transfers SET status = 'declined' WHERE id = ?",
            { transferId }
        )
        
        Log(citizenid, 'transfer_decline', transfer.model, transfer.wagon_id, nil)
        
        TriggerClientEvent('rsg-wagonmaker:client:transferDeclined', src)
        
        -- Notify sender if online
        local SenderPlayer = RSGCore.Functions.GetPlayerByCitizenId(transfer.from_citizenid)
        if SenderPlayer then
            TriggerClientEvent('ox_lib:notify', SenderPlayer.PlayerData.source, {
                title = 'Transfer Declined',
                description = 'Your wagon transfer was declined',
                type = 'error'
            })
        end
        
        if Config.Debug then
            print('^2[RSG-WagonMaker]^7 Transfer declined: Wagon ' .. transfer.wagon_id)
        end
    end
end)

-- ========================================
-- Cancel Transfer (by owner)
-- ========================================

RegisterNetEvent('rsg-wagonmaker:server:cancelTransfer', function(transferId)
    local src = source
    local citizenid = GetPlayerIdentifier(src)
    
    if not citizenid then return end
    
    -- Verify ownership
    local transfer = MySQL.single.await(
        "SELECT * FROM wagonmaker_transfers WHERE id = ? AND from_citizenid = ? AND status = 'pending'",
        { transferId, citizenid }
    )
    
    if not transfer then return end
    
    MySQL.update.await(
        "UPDATE wagonmaker_transfers SET status = 'cancelled' WHERE id = ?",
        { transferId }
    )
    
    Log(citizenid, 'transfer_cancel', nil, transfer.wagon_id, nil)
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Transfer Cancelled',
        description = 'Transfer offer cancelled',
        type = 'success'
    })
end)

-- ========================================
-- Exports
-- ========================================

exports('GetPendingTransfersFor', function(citizenid)
    local transfers = MySQL.query.await(
        "SELECT * FROM wagonmaker_transfers WHERE to_citizenid = ? AND status = 'pending'",
        { citizenid }
    )
    return transfers or {}
end)

exports('GetPendingTransfersFrom', function(citizenid)
    local transfers = MySQL.query.await(
        "SELECT * FROM wagonmaker_transfers WHERE from_citizenid = ? AND status = 'pending'",
        { citizenid }
    )
    return transfers or {}
end)
