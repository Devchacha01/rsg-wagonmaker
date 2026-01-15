-- ========================================
-- RSG Wagon Maker - Parking System
-- NPC-based wagon storage and retrieval
-- ========================================

local RSGCore = exports['rsg-core']:GetCoreObject()

MyWagon = nil
local MyWagonId = nil
local MyWagonBlip = nil
local MyWagonData = nil

local ParkingPrompt = nil
local WagonStashPrompt = nil
local WagonStorePrompt = nil
local ParkPrompt = nil
local ParkingGroup = GetRandomIntInRange(0, 0xffffff)
local WagonGroup = GetRandomIntInRange(0, 0xffffff)

-- ========================================
-- Prompt Setup
-- ========================================

CreateThread(function()
    -- Parking NPC Prompt
    ParkingPrompt = Citizen.InvokeNative(0x04F97DE45A519419)
    PromptSetControlAction(ParkingPrompt, GetHashKey(Config.Keys.Interact))
    PromptSetText(ParkingPrompt, CreateVarString(10, "LITERAL_STRING", "Access Wagon Yard"))
    PromptSetEnabled(ParkingPrompt, true)
    PromptSetVisible(ParkingPrompt, true)
    PromptSetStandardMode(ParkingPrompt, true)
    PromptSetGroup(ParkingPrompt, ParkingGroup, 0)
    PromptRegisterEnd(ParkingPrompt)
    
    -- Wagon Stash Prompt (when ox_target disabled)
    WagonStashPrompt = Citizen.InvokeNative(0x04F97DE45A519419)
    PromptSetControlAction(WagonStashPrompt, GetHashKey("INPUT_CONTEXT"))
    PromptSetText(WagonStashPrompt, CreateVarString(10, "LITERAL_STRING", "Open Stash"))
    PromptSetEnabled(WagonStashPrompt, true)
    PromptSetVisible(WagonStashPrompt, true)
    PromptSetHoldMode(WagonStashPrompt, true)
    PromptSetGroup(WagonStashPrompt, WagonGroup, 0)
    PromptRegisterEnd(WagonStashPrompt)
    
    -- Wagon Store Prompt (when ox_target disabled)
    WagonStorePrompt = Citizen.InvokeNative(0x04F97DE45A519419)
    PromptSetControlAction(WagonStorePrompt, GetHashKey("INPUT_CHARACTER_WHEEL")) -- Left Alt
    PromptSetText(WagonStorePrompt, CreateVarString(10, "LITERAL_STRING", "Store Wagon"))
    PromptSetEnabled(WagonStorePrompt, true)
    PromptSetVisible(WagonStorePrompt, true)
    PromptSetHoldMode(WagonStorePrompt, true)
    PromptSetGroup(WagonStorePrompt, WagonGroup, 0)
    PromptRegisterEnd(WagonStorePrompt)
    
    -- Park Wagon Prompt (Drive-In)
    ParkPrompt = Citizen.InvokeNative(0x04F97DE45A519419)
    PromptSetControlAction(ParkPrompt, GetHashKey("INPUT_CHARACTER_WHEEL")) -- Left Alt
    PromptSetText(ParkPrompt, CreateVarString(10, "LITERAL_STRING", "Park Your Wagon"))
    PromptSetEnabled(ParkPrompt, true)
    PromptSetVisible(ParkPrompt, true)
    PromptSetHoldMode(ParkPrompt, true)
    PromptSetGroup(ParkPrompt, ParkingGroup, 0)
    PromptRegisterEnd(ParkPrompt)
end)

-- ========================================
-- Wagon Interaction Loop (when ox_target disabled)
-- ========================================

CreateThread(function()
    -- Stop this thread if using ox_target (interactions handled via target)
    if Config.UseOxTarget then return end
    
    while true do
        local sleep = 500
        
        if not Config.UseOxTarget and MyWagon and DoesEntityExist(MyWagon) then
            local playerCoords = GetEntityCoords(cache.ped)
            local wagonCoords = GetEntityCoords(MyWagon)
            local dist = #(playerCoords - wagonCoords)
            
            if dist < 5.0 then
                sleep = 0
                local groupLabel = CreateVarString(10, "LITERAL_STRING", "Your Wagon")
                PromptSetActiveGroupThisFrame(WagonGroup, groupLabel, 0, 0, 0, 0)
                
                if PromptHasHoldModeCompleted(WagonStashPrompt) and MyWagonData then
                    OpenWagonStash(MyWagonData)
                elseif PromptHasHoldModeCompleted(WagonStorePrompt) then
                    StoreWagon(MyWagonId)
                end
            end
        end
        
        Wait(sleep)
    end
end)

-- ========================================
-- Utility Functions
-- ========================================

function GetClosestParkingNPC()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local closestNPC = nil
    local closestDist = 10.0 -- Max distance check
    
    for _, npc in ipairs(Config.ParkingNPCs) do
        local dist = #(playerCoords - npc.coords)
        if dist < closestDist then
            closestDist = dist
            closestNPC = npc
        end
    end
    
    return closestNPC, closestDist
end

-- ========================================
-- Interaction Loops
-- ========================================

-- NPC Detection Loop (only when ox_target is disabled)
-- ========================================

CreateThread(function()
    -- Skip this loop if using ox_target (interactions handled via target)
    if Config.UseOxTarget then return end
    
    while true do
        local sleep = 500
        local npc, dist = GetClosestParkingNPC()
        
        if npc and dist < 3.0 then
            sleep = 0
            
            local ped = PlayerPedId()
            local inVehicle = IsPedInAnyVehicle(ped, false)
            
            -- Fallback: Brute Force Search (Ghost Wagon Fix)
            if not inVehicle then
                local pCoords = GetEntityCoords(ped)
                local vehicles = GetGamePool('CVehicle')
                
                for _, veh in ipairs(vehicles) do
                    if DoesEntityExist(veh) then
                        local vCoords = GetEntityCoords(veh)
                        local dist = #(pCoords - vCoords)
                        
                        -- If any vehicle is within 10 meters, assume it's the user's wagon
                        if dist < 10.0 then
                            inVehicle = true
                            break
                        end
                    end
                end
            end
            
            -- Only show prompt when NOT in a vehicle (on foot)
            if not inVehicle then
                -- Dynamic Prompt Text Update
                local promptText = "Access Wagon Yard"
                
                -- Update the prompt text (Top Right)
                local str = CreateVarString(10, "LITERAL_STRING", promptText)
                PromptSetText(ParkingPrompt, str)

                local groupLabel = CreateVarString(10, "LITERAL_STRING", npc.name)
                PromptSetActiveGroupThisFrame(ParkingGroup, groupLabel, 0, 0, 0, 0)
                
                -- Input Check
                local pressed = Citizen.InvokeNative(0xC92AC953F0A982AE, ParkingPrompt)
                
                if not pressed then
                     -- Fallback Keys
                     if Config.Keys and Config.Keys.Interact and IsControlJustReleased(0, GetHashKey(Config.Keys.Interact)) then pressed = true end
                     if not pressed and (IsControlJustReleased(0, GetHashKey("INPUT_ENTER")) or IsControlJustReleased(0, GetHashKey("INPUT_FRONTEND_ACCEPT")) or IsControlJustReleased(0, GetHashKey("INPUT_CONTEXT_A"))) then pressed = true end
                end
                
                if pressed then
                    OpenParkingMenu(npc)
                    Wait(500)
                end
            end
        end
        
        Wait(sleep)
    end
end)

-- ========================================
-- Parking Menu
-- ========================================

function OpenParkingMenu(parkingNPC)
    lib.callback('rsg-wagonmaker:server:getPlayerWagons', false, function(wagons)
        if not wagons or #wagons == 0 then
            Notify(GetLocale('no_wagons'), 'inform')
            return
        end
        
        local nuiOptions = {}
        
        -- Pending Transfers Option (if any)
        lib.callback('rsg-wagonmaker:server:getPendingTransfers', false, function(transfers)
            if transfers and #transfers > 0 then
                table.insert(nuiOptions, {
                    label = '📬 Pending Transfers (' .. #transfers .. ')',
                    description = 'View incoming wagon transfer offers',
                    value = 'pending_transfers',
                    metadata = transfers -- Pass transfer data for next step
                })
            end
            
            -- Wagon List
            for _, wagon in ipairs(wagons) do
                local wagonConfig = Config.Wagons[wagon.model]
                local label = wagonConfig and wagonConfig.label or wagon.model
                local isSpawned = wagon.spawned == 1
                
                table.insert(nuiOptions, {
                    label = wagon.name,
                    -- Combine info into description for NUI display
                    description = label .. '\n' .. (isSpawned and 'Status: Currently Out' or 'Status: Stored'),
                    value = wagon.id, -- Pass wagon ID as value
                    icon = isSpawned and 'horse-head' or 'warehouse'
                })
            end
            
            SetNuiFocus(true, true)
            SendNUIMessage({
                action = 'openOptions',
                title = parkingNPC.name,
                options = nuiOptions,
                callbackName = 'parkingMenuSelect',
                layout = 'list'
            })
        end)
    end)
end

RegisterNUICallback('parkingMenuSelect', function(data, cb)
    local value = data.value
    SetNuiFocus(false, false)
    
    if value == 'pending_transfers' then
        local parkingNPC = GetClosestParkingNPC()
        if parkingNPC then
             lib.callback('rsg-wagonmaker:server:getPendingTransfers', false, function(transfers)
                OpenPendingTransfersMenu(transfers, parkingNPC)
             end)
        end
    else
        -- Value is wagon.id (number)
        local wagonId = tonumber(value)
        if wagonId then
             lib.callback('rsg-wagonmaker:server:getWagonById', false, function(wagon)
                local parkingNPC = GetClosestParkingNPC()
                if wagon and parkingNPC then
                    OpenWagonOptionsMenu(wagon, parkingNPC)
                end
             end, wagonId)
        end
    end
    
    cb('ok')
end)

function OpenWagonOptionsMenu(wagon, parkingNPC)
    local isSpawned = wagon.spawned == 1
    local wagonConfig = Config.Wagons[wagon.model]
    local label = wagonConfig and wagonConfig.label or wagon.model
    
    local nuiOptions = {}
    
    if isSpawned then
        -- Wagon is currently out
        table.insert(nuiOptions, {
            label = GetLocale('parking_store'),
            description = 'Store your wagon in the yard',
            value = 'store',
            icon = 'warehouse'
        })
    else
        -- Wagon is stored
        table.insert(nuiOptions, {
            label = GetLocale('parking_spawn'),
            description = 'Bring out your wagon',
            value = 'spawn',
            icon = 'horse-head'
        })
    end
    
    table.insert(nuiOptions, {
        label = GetLocale('parking_rename'),
        description = 'Change the wagon name',
        value = 'rename',
        icon = 'pen'
    })
    
    table.insert(nuiOptions, {
        label = GetLocale('parking_transfer'),
        description = 'Transfer wagon to another player',
        value = 'transfer',
        icon = 'exchange-alt'
    })
    
    table.insert(nuiOptions, {
        label = GetLocale('parking_delete'),
        description = 'Permanently delete this wagon',
        value = 'delete',
        icon = 'trash'
    })
    
    -- Store temporary wagon data for the callback
    CurrentWagonOptionData = { wagon = wagon, npc = parkingNPC }

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openOptions',
        title = wagon.name,
        options = nuiOptions,
        callbackName = 'parkingWagonOptionSelect',  -- Must include 'parking' for UI style
        layout = 'list'
    })
end

RegisterNUICallback('parkingWagonOptionSelect', function(data, cb)
    local value = data.value
    SetNuiFocus(false, false)
    
    if not CurrentWagonOptionData then return end
    
    local wagon = CurrentWagonOptionData.wagon
    local npc = CurrentWagonOptionData.npc
    
    if value == 'spawn' then
        SpawnWagon(wagon, npc)
    elseif value == 'store' then
        StoreWagon(wagon.id)
    elseif value == 'rename' then
        RenameWagon(wagon, npc)
    elseif value == 'transfer' then
        TransferWagon(wagon, npc)
    elseif value == 'delete' then
        DeleteWagonConfirm(wagon, npc)
    end
    
    CurrentWagonOptionData = nil -- Clear
    cb('ok')
end)

-- ========================================
-- Wagon Operations
-- ========================================

function SpawnWagon(wagon, parkingNPC)
    -- Check if player already has a wagon out
    if MyWagon and DoesEntityExist(MyWagon) then
        Notify(GetLocale('already_spawned'), 'error')
        return
    end
    
    local wagonConfig = Config.Wagons[wagon.model]
    if not wagonConfig then
        Notify(GetLocale('wagon_not_found'), 'error')
        return
    end
    
    local hash = GetHashKey(wagon.model)
    RequestModel(hash, false)
    while not HasModelLoaded(hash) do
        Wait(10)
    end
    
    -- Spawn at parking spawn point
    MyWagon = CreateVehicle(hash, 
        parkingNPC.spawnPoint.x, 
        parkingNPC.spawnPoint.y, 
        parkingNPC.spawnPoint.z, 
        parkingNPC.spawnHeading, 
        true, false, false, false)
    
    MyWagonId = wagon.id
    MyWagonData = wagon  -- Store wagon data for prompt-based stash access
    
    -- Set on ground properly
    Citizen.InvokeNative(0x7263332501E07F52, MyWagon, true)
    
    -- Apply customization
    ApplyWagonCustomization(MyWagon, wagon)
    
    -- Clean
    SetVehicleDirtLevel(MyWagon, 0.0)
    
    -- Network it
    NetworkRegisterEntityAsNetworked(MyWagon)
    
    -- Wait for network ID
    local networkId = NetworkGetNetworkIdFromEntity(MyWagon)
    while not NetworkDoesEntityExistWithNetworkId(networkId) do
        Wait(50)
    end
    
    -- Set player ownership
    Citizen.InvokeNative(0xD0E02AA618020D17, PlayerId(), MyWagon)
    
    SetModelAsNoLongerNeeded(hash)
    
    -- Create blip
    MyWagonBlip = Citizen.InvokeNative(0x23F74C2FDA6E7C61, -1230993421, MyWagon)
    SetBlipSprite(MyWagonBlip, GetHashKey("blip_player_coach"), true)
    Citizen.InvokeNative(0x9CB1A1623062F402, MyWagonBlip, wagon.name)
    
    -- Register ox_target if enabled
    if Config.UseOxTarget then
        Wait(100)
        CreateWagonTarget(MyWagon, wagon)
    end
    
    -- Update server and register inventory
    TriggerServerEvent('rsg-wagonmaker:server:wagonSpawned', wagon.id, networkId, wagon.model)
    
    Notify(GetLocale('wagon_spawned'), 'success')

    -- Camera Effect
    local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    local coords = GetEntityCoords(MyWagon)
    local fwd = GetEntityForwardVector(MyWagon)
    local camPos = coords + (fwd * 5.0) + vector3(0.0, 0.0, 2.0) -- 5m in front, 2m up
    
    SetCamCoord(cam, camPos.x, camPos.y, camPos.z)
    PointCamAtEntity(cam, MyWagon, 0.0, 0.0, 0.0, true)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 1000, true, true)
    
    Wait(3000) -- Focus for 3 seconds
    
    RenderScriptCams(false, true, 1000, true, true)
    DestroyCam(cam, false)
end

-- ========================================
-- ox_target Integration
-- ========================================

function CreateWagonTarget(entity, wagonData)
    local wagonConfig = Config.Wagons[wagonData.model]
    
    exports.ox_target:addLocalEntity(entity, {
        {
            name = "wagon_stash",
            icon = "fas fa-box-open",
            label = "Open Wagon Stash",
            onSelect = function()
                OpenWagonStash(wagonData)
            end,
            distance = 3.0
        },
        {
            name = "wagon_store",
            icon = "fas fa-warehouse",
            label = "Store Wagon",
            onSelect = function()
                StoreWagon(wagonData.id)
            end,
            distance = 3.0,
            canInteract = function(entity, distance, coords, name)
                local ped = PlayerPedId()
                local pCoords = GetEntityCoords(ped)
                
                -- Check proximity to any parking zone
                for _, npc in ipairs(Config.ParkingNPCs) do
                    -- Use specific parking zone if defined, otherwise fallback to NPC location
                    local targetCoords = npc.coords
                    local radius = 10.0 -- Generous fallback radius around NPC
                    
                    if npc.parkingZone then
                        targetCoords = npc.parkingZone.coords
                        radius = npc.parkingZone.radius
                    end

                    local dist = #(pCoords - targetCoords)
                    if dist < radius then 
                        return true 
                    end
                end
                return false
            end
        }
    })
end

function RemoveWagonTarget()
    if MyWagon and DoesEntityExist(MyWagon) then
        exports.ox_target:removeLocalEntity(MyWagon, { "wagon_stash", "wagon_store" })
    end
end

-- ========================================
-- Wagon Stash Functions
-- ========================================

function OpenWagonStash(wagonData)
    if not wagonData or not wagonData.id then
        Notify('Invalid wagon data', 'error')
        return
    end
    
    local stashId = 'wagon_' .. wagonData.id
    local wagonConfig = Config.Wagons[wagonData.model]
    
    if not wagonConfig then
        Notify('Unknown wagon type', 'error')
        return
    end
    
    print('^2[RSG-WagonMaker]^7 Opening stash: ' .. stashId)
    
    -- Trigger server to open the stash (works with both ox and rsg inventory)
    TriggerServerEvent('rsg-wagonmaker:server:openWagonStash', stashId, {
        maxweight = wagonConfig.maxWeight or 500000,
        slots = wagonConfig.slots or 50,
        label = wagonConfig.label or 'Wagon Stash'
    })
end

function StoreWagon(wagonId)
    print(string.format('^3[RSG-WagonMaker] StoreWagon called. MyWagon: %s^7', tostring(MyWagon)))
    
    -- Attempt to recover wagon if nil (e.g. after script restart or ghost wagon)
    local ped = PlayerPedId()
    if not MyWagon or not DoesEntityExist(MyWagon) then
        local veh =0
        if IsPedInVehicle(ped, GetVehiclePedIsIn(ped, false), false) then 
             veh = GetVehiclePedIsIn(ped, false)
        end
        
        -- Fallback: Closest vehicle (Ghost Wagon Detection)
        if veh == 0 then
             local pCoords = GetEntityCoords(ped)
             veh = GetClosestVehicle(pCoords.x, pCoords.y, pCoords.z, 5.0, 0, 70) -- 5 meters, model/flags ignored
             if veh ~= 0 then
                  print('^3[RSG-WagonMaker] StoreWagon: Recovered via Proximity Fallback.^7')
             end
        end

        if veh ~= 0 then
             print('^3[RSG-WagonMaker] StoreWagon: Recovered MyWagon handle: ' .. veh .. '^7')
             MyWagon = veh
        end
    end
    
    -- Attempt to recover ID from Decorator if nil
    if (not wagonId or wagonId == 0) and MyWagon and DoesEntityExist(MyWagon) then
        if DecorExistOn(MyWagon, "wagon_id") then
            local decorId = DecorGetInt(MyWagon, "wagon_id")
            print('^3[RSG-WagonMaker] Recovered wagonId from Decorator: ' .. decorId .. '^7')
            wagonId = decorId
            MyWagonId = decorId -- Update local global too
        end
    end
    
    if not MyWagon or not DoesEntityExist(MyWagon) then
        Notify('No wagon to store (try getting inside it)', 'error')
        print('^1[RSG-WagonMaker] StoreWagon Failed: MyWagon not exist/found^7')
        return
    end

    -- Network Debug
    if MyWagon and DoesEntityExist(MyWagon) then
        print('[RSG-WagonMaker] StoreWagon: IsNetworked: ' .. tostring(NetworkGetEntityIsNetworked(MyWagon)))
    end
    
    -- Remove ox_target if enabled
    if Config.UseOxTarget then
        RemoveWagonTarget()
    end
    
    -- Remove blip
    if MyWagonBlip and DoesBlipExist(MyWagonBlip) then
        RemoveBlip(MyWagonBlip)
        MyWagonBlip = nil
    end
    
    -- Delete entity
    print('^3[RSG-WagonMaker] Attempting to delete wagon...^7')
    
    -- Request control first (crucial after restart)
    local netId = NetworkGetNetworkIdFromEntity(MyWagon)
    local ped = PlayerPedId()
    
    -- Eject player first to prevent "occupied vehicle" deletion block
    if IsPedInVehicle(ped, MyWagon, false) then
        TaskLeaveVehicle(ped, MyWagon, 16) -- 16 = Warp out
        Wait(100)
    end

    if NetworkGetEntityIsNetworked(MyWagon) then
        NetworkRequestControlOfEntity(MyWagon)
        local timeout = 0
        while not NetworkHasControlOfEntity(MyWagon) and timeout < 20 do
            Wait(10)
            timeout = timeout + 1
        end
        -- Trigger Server Deletion (Reliable)
        TriggerServerEvent('rsg-wagonmaker:server:forceDeleteWagon', netId)
    end
    
    SetEntityAsMissionEntity(MyWagon, true, true)
    DeleteVehicle(MyWagon) -- Try specific vehicle delete first
    DeleteEntity(MyWagon) -- Fallback
    
    -- Fallback deletion check
    if DoesEntityExist(MyWagon) then
        print('^3[RSG-WagonMaker] DeleteEntity failed, trying DeleteVehicle...^7')
        DeleteVehicle(MyWagon)
    end
    
    if DoesEntityExist(MyWagon) then
         print('^1[RSG-WagonMaker] Wagon STILL exists after deletion attempts!^7')
    else
         print('^2[RSG-WagonMaker] Wagon deleted successfully.^7')
    end
    
    MyWagon = nil
    MyWagonId = nil
    MyWagonData = nil
    
    -- Update server
    TriggerServerEvent('rsg-wagonmaker:server:wagonStored', wagonId)
    
    Notify(GetLocale('wagon_stored'), 'success')
end

function ApplyWagonCustomization(wagon, wagonData)
    if not wagon or not DoesEntityExist(wagon) then return end
    
    -- Apply tint
    Citizen.InvokeNative(0x8268B098F6FCA4E2, wagon, wagonData.tint or 0)
    
    -- Apply livery
    if wagonData.livery and wagonData.livery >= 0 then
        Citizen.InvokeNative(0xF89D82A0582E46ED, wagon, wagonData.livery)
    end
    
    -- Apply props
    if wagonData.props and wagonData.props ~= '' then
        Citizen.InvokeNative(0x75F90E4051CC084C, wagon, GetHashKey(wagonData.props))
    end
    
    -- Apply lantern
    if wagonData.lantern and wagonData.lantern ~= '' then
        Citizen.InvokeNative(0xC0F0417A90402742, wagon, GetHashKey(wagonData.lantern))
    end
    
    -- Apply extra
    if wagonData.extra and wagonData.extra > 0 then
        for i = 0, 10 do
            if DoesExtraExist(wagon, i) then
                Citizen.InvokeNative(0xBB6F89150BC9D16B, wagon, i, true)
            end
        end
        Citizen.InvokeNative(0xBB6F89150BC9D16B, wagon, wagonData.extra, false)
    end
end

function RenameWagon(wagon, parkingNPC)
    local input = lib.inputDialog('Rename Wagon', {
        { type = 'input', label = 'New Name', placeholder = wagon.name, required = true, max = 50 }
    })
    
    if not input or not input[1] or input[1] == '' then
        return
    end
    
    TriggerServerEvent('rsg-wagonmaker:server:renameWagon', wagon.id, input[1])
    
    Wait(500)
    OpenParkingMenu(parkingNPC)
end

function DeleteWagonConfirm(wagon, parkingNPC)
    local confirm = lib.alertDialog({
        header = 'Delete Wagon',
        content = 'Are you sure you want to permanently delete "' .. wagon.name .. '"? This cannot be undone!',
        centered = true,
        cancel = true
    })
    
    if confirm == 'confirm' then
        TriggerServerEvent('rsg-wagonmaker:server:deleteWagon', wagon.id)
        Wait(500)
        OpenParkingMenu(parkingNPC)
    end
end

-- ========================================
-- Transfer System (Client Side)
-- ========================================

function TransferWagon(wagon, parkingNPC)
    local input = lib.inputDialog(GetLocale('transfer_title'), {
        { type = 'number', label = GetLocale('transfer_player_id'), required = true },
        { type = 'number', label = GetLocale('transfer_price'), default = 0 }
    })
    
    if not input or not input[1] then
        return
    end
    
    local targetId = tonumber(input[1])
    local price = tonumber(input[2]) or 0
    
    if not targetId or targetId < 1 then
        Notify('Invalid player ID', 'error')
        return
    end
    
    TriggerServerEvent('rsg-wagonmaker:server:createTransfer', wagon.id, targetId, price)
end

function OpenPendingTransfersMenu(transfers, parkingNPC)
    local options = {}
    
    for _, transfer in ipairs(transfers) do
        local wagonConfig = Config.Wagons[transfer.wagon_model]
        local label = wagonConfig and wagonConfig.label or transfer.wagon_model
        local priceText = transfer.price > 0 and ('$' .. transfer.price) or 'Free'
        
        table.insert(options, {
            title = transfer.wagon_name .. ' (' .. label .. ')',
            description = 'From: ' .. transfer.from_name .. '\nPrice: ' .. priceText,
            onSelect = function()
                HandleTransferOffer(transfer, parkingNPC)
            end
        })
    end
    
    lib.registerContext({
        id = 'wagonmaker_pending_transfers',
        title = 'Pending Transfers',
        menu = 'wagonmaker_parking',
        options = options
    })
    lib.showContext('wagonmaker_pending_transfers')
end

function HandleTransferOffer(transfer, parkingNPC)
    local wagonConfig = Config.Wagons[transfer.wagon_model]
    local label = wagonConfig and wagonConfig.label or transfer.wagon_model
    local priceText = transfer.price > 0 and ('$' .. transfer.price) or 'Free'
    
    local options = {
        {
            title = '✅ Accept Transfer',
            description = 'Accept this wagon for ' .. priceText,
            onSelect = function()
                TriggerServerEvent('rsg-wagonmaker:server:respondTransfer', transfer.id, true)
                Wait(500)
                OpenParkingMenu(parkingNPC)
            end
        },
        {
            title = '❌ Decline Transfer',
            description = 'Decline this offer',
            onSelect = function()
                TriggerServerEvent('rsg-wagonmaker:server:respondTransfer', transfer.id, false)
                Wait(500)
                OpenParkingMenu(parkingNPC)
            end
        }
    }
    
    lib.registerContext({
        id = 'wagonmaker_transfer_offer',
        title = 'Transfer: ' .. transfer.wagon_name,
        menu = 'wagonmaker_pending_transfers',
        options = options
    })
    lib.showContext('wagonmaker_transfer_offer')
end

-- ========================================
-- Helper Functions
-- ========================================

function GetParkingName(locationId)
    for _, npc in ipairs(Config.ParkingNPCs) do
        if npc.id == locationId then
            return npc.name
        end
    end
    return 'Unknown'
end

-- ========================================
-- Server Event Handlers
-- ========================================

RegisterNetEvent('rsg-wagonmaker:client:wagonRenamed', function(newName)
    Notify('Wagon renamed to: ' .. newName, 'success')
end)

RegisterNetEvent('rsg-wagonmaker:client:wagonDeleted', function()
    Notify('Wagon deleted', 'success')
end)

RegisterNetEvent('rsg-wagonmaker:client:transferSent', function()
    Notify(GetLocale('transfer_sent'), 'success')
end)

RegisterNetEvent('rsg-wagonmaker:client:transferReceived', function(fromName, wagonName, price)
    Notify(GetLocale('transfer_received', fromName, wagonName, price), 'inform')
end)

RegisterNetEvent('rsg-wagonmaker:client:transferAccepted', function()
    Notify(GetLocale('transfer_accepted'), 'success')
end)

RegisterNetEvent('rsg-wagonmaker:client:transferDeclined', function()
    Notify(GetLocale('transfer_declined'), 'inform')
end)

-- ========================================
-- Exports
-- ========================================

exports('GetMyWagon', function()
    return MyWagon
end)

exports('GetMyWagonId', function()
    return MyWagonId
end)

exports('HasWagonOut', function()
    return MyWagon ~= nil and DoesEntityExist(MyWagon)
end)

-- Drive-in Parking Detection Loop
CreateThread(function()
    while true do
        local sleep = 1000
        
        -- Check if player has a wagon out and is driving it
        local ped = PlayerPedId()
        if MyWagon and DoesEntityExist(MyWagon) and IsPedInVehicle(ped, MyWagon, false) then
            local wagonCoords = GetEntityCoords(MyWagon)
            
            -- Check all parking zones
            for _, npc in ipairs(Config.ParkingNPCs) do
                if npc.parkingZone then
                    local zoneCoords = vector3(npc.parkingZone.coords.x, npc.parkingZone.coords.y, npc.parkingZone.coords.z)
                    local dist = #(wagonCoords - zoneCoords)
                    
                    if dist < npc.parkingZone.radius then
                        sleep = 0
                        
                        -- Show white medium text (no Enter key)
                        SetTextScale(0.4, 0.4)
                        SetTextColor(255, 255, 255, 255)
                        SetTextCentre(true)
                        SetTextDropshadow(2, 0, 0, 0, 255)
                        DisplayText(CreateVarString(10, "LITERAL_STRING", "Get off your wagon to park here"), 0.5, 0.85)
                        
                        -- Don't allow storing while on wagon
                        break
                    end
                end
            end
        end
        
        Wait(sleep)
    end
end)
