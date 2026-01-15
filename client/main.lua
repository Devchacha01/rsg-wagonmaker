-- ========================================
-- RSG Wagon Maker - Client Main
-- Core initialization and shared utilities
-- ========================================

local RSGCore = exports['rsg-core']:GetCoreObject()

-- Shared state
PlayerData = {}
Zones = {}
ParkingNPCs = {}
ParkingBlips = {}

-- Prompt references
local PromptGroup = GetRandomIntInRange(0, 0xffffff)

-- ========================================
-- Initialization
-- ========================================

CreateThread(function()
    while RSGCore == nil do
        Wait(100)
        RSGCore = exports['rsg-core']:GetCoreObject()
    end
    
    -- Wait for player to be loaded
    while not LocalPlayer.state.isLoggedIn do
        Wait(100)
    end
    
    PlayerData = RSGCore.Functions.GetPlayerData()
    
    -- Load static zones from config immediately
    if Config.StaticZones then
        for _, zone in ipairs(Config.StaticZones) do
            table.insert(Zones, zone)
        end
        if Config.Debug then
            print('^2[RSG-WagonMaker]^7 Loaded ' .. #Config.StaticZones .. ' static zones')
        end
    end
    
    -- Load zones from server (will add to existing static zones)
    TriggerServerEvent('rsg-wagonmaker:server:requestZones')
    
    -- Spawn parking NPCs
    SpawnParkingNPCs()
    
    -- Register Decorator for ID persistence
    DecorRegister("wagon_id", 3) -- 3 = Int
    
    if Config.Debug then
        print('^2[RSG-WagonMaker]^7 Client initialized')
    end
end)

-- Update player data on job change
RegisterNetEvent('RSGCore:Client:OnJobUpdate', function(job)
    PlayerData.job = job
    if Config.Debug then
        print('^3[WagonMaker] Job updated to: ' .. job.name .. '^7')
    end
end)

RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    PlayerData = RSGCore.Functions.GetPlayerData()
    TriggerServerEvent('rsg-wagonmaker:server:requestZones')
    if Config.Debug then
        print('^3[WagonMaker] PlayerData loaded, job: ' .. tostring(PlayerData.job and PlayerData.job.name) .. '^7')
    end
end)

-- Debug command to check current job status
RegisterCommand('wm_checkjob', function()
    local zone, dist = GetClosestZone('crafting')
    print('^3[WagonMaker Debug]^7')
    print('  PlayerData.job.name: ' .. tostring(PlayerData.job and PlayerData.job.name or 'nil'))
    print('  Closest zone requiredJob: ' .. tostring(zone and zone.requiredJob or 'no zone'))
    print('  Distance to zone: ' .. tostring(dist or 'N/A'))
    print('  IsWagonMaker result: ' .. tostring(IsWagonMaker(zone)))
    print('  Config.JobRequired: ' .. tostring(Config.JobRequired))
    print('  Config.JobMode: ' .. tostring(Config.JobMode))
end, false)

-- ========================================
-- Job Verification
-- ========================================

function IsWagonMaker(zone)
    if not Config.JobRequired then 
        return true 
    end
    
    if not PlayerData or not PlayerData.job then 
        return false 
    end
    
    if Config.JobMode == 'location' then
        if not zone or not zone.requiredJob then 
            return false 
        end
        return PlayerData.job.name == zone.requiredJob
    else
        return PlayerData.job.name == Config.GlobalJobName
    end
end

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = GetScreenCoordFromWorldCoord(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFontForCurrentCommand(1)
        SetTextColor(255, 255, 255, 215)
        SetTextCentre(1)
        DisplayText(CreateVarString(10, "LITERAL_STRING", text), _x, _y)
    end
end

-- ========================================
-- Zone Loading
-- ========================================

RegisterNetEvent('rsg-wagonmaker:client:loadZones', function(zones)
    -- Add database zones to existing static zones (don't reset Zones table)
    if zones then
        for _, zone in ipairs(zones) do
            table.insert(Zones, zone)
        end
    end
    
    -- Add ox_target for static zones (only once on first load)
    if Config.UseOxTarget and Config.StaticZones then
        for _, zoneData in ipairs(Config.StaticZones) do
            local zone = zoneData -- Capture loop variable for closure
            local zoneCoords = vector3(zone.x, zone.y, zone.z)
            
            if zone.type == "crafting" then
                exports.ox_target:addSphereZone({
                    coords = zoneCoords,
                    radius = zone.radius,
                    debug = Config.Debug,
                    options = {
                        {
                            name = 'wagonmaker_craft_' .. zone.id,
                            icon = 'fas fa-hammer',
                            label = 'Craft Wagon',
                            onSelect = function()
                                OpenCraftingMenu()
                            end,
                            distance = zone.radius + 1.0,
                            canInteract = function()
                                return IsWagonMaker(zone)
                            end
                        }
                    }
                })
            elseif zone.type == "preview" then
                exports.ox_target:addSphereZone({
                    coords = zoneCoords,
                    radius = zone.radius,
                    debug = Config.Debug,
                    options = {
                        {
                            name = 'wagonmaker_preview_' .. zone.id,
                            icon = 'fas fa-hammer',
                            label = 'Wagon Assembly Area',
                            canInteract = function()
                                return false  -- Just a visual marker, no interaction
                            end,
                            distance = zone.radius + 1.0
                        }
                    }
                })
            end
        end
    end
    
    if Config.Debug then
        print('^2[RSG-WagonMaker]^7 Total zones: ' .. #Zones)
    end
end)

RegisterNetEvent('rsg-wagonmaker:client:zoneAdded', function(zone)
    table.insert(Zones, zone)
end)

RegisterNetEvent('rsg-wagonmaker:client:zoneRemoved', function(zoneId)
    for i, zone in ipairs(Zones) do
        if zone.id == zoneId then
            table.remove(Zones, i)
            break
        end
    end
end)

-- ========================================
-- Parking NPC System
-- ========================================

function SpawnParkingNPCs()
    for _, npc in ipairs(Config.ParkingNPCs) do
        local model = GetHashKey(npc.model)
        
        RequestModel(model, false)
        while not HasModelLoaded(model) do
            Wait(10)
        end
        
        local ped = CreatePed(model, npc.coords.x, npc.coords.y, npc.coords.z - 1.0, npc.heading, false, false, false, false)
        SetRandomOutfitVariation(ped, true)  -- Apply random outfit to make ped visible
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        FreezeEntityPosition(ped, true)
        SetModelAsNoLongerNeeded(model)
        
        ParkingNPCs[npc.id] = ped
        
        -- Add ox_target interaction for parking NPC
        if Config.UseOxTarget then
            exports.ox_target:addLocalEntity(ped, {
                {
                    name = 'parking_access_' .. npc.id,
                    icon = 'fas fa-warehouse',
                    label = 'Access Wagon Yard',
                    onSelect = function()
                        OpenParkingMenu(npc)
                    end,
                    distance = 3.0
                }
            })
        end
        
        -- Create blip
        if npc.blip.enabled then
            local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, npc.coords.x, npc.coords.y, npc.coords.z)
            Citizen.InvokeNative(0x74F74D3207ED525C, blip, npc.blip.sprite, true)
            Citizen.InvokeNative(0x9CB1A1623062F402, blip, npc.blip.name)
            ParkingBlips[npc.id] = blip
        end
    end
end

-- ========================================
-- Helper Functions
-- ========================================

function GetLocale(key, ...)
    local text = Config.Locale[key] or key
    if ... then
        text = string.format(text, ...)
    end
    return text
end

function Notify(message, type)
    lib.notify({
        title = GetLocale("wagonmaker"),
        description = message,
        type = type or "inform",
        duration = 5000
    })
end

-- NOTE: IsWagonMaker is defined earlier in this file with proper zone-based job checking

function IsAdmin()
    local playerGroup = RSGCore.Functions.GetPlayerData().group
    for _, group in ipairs(Config.AdminGroups) do
        if playerGroup == group then
            return true
        end
    end
    return false
end

function LoadModel(model)
    local hash = type(model) == 'number' and model or GetHashKey(model)
    if not IsModelValid(hash) then
        return false
    end
    
    RequestModel(hash, false)
    while not HasModelLoaded(hash) do
        Wait(10)
    end
    return hash
end

function DrawMarker3D(coords, radius, height, color)
    DrawMarker(
        0x94FDAE17,                             -- Ring marker
        coords.x, coords.y, coords.z - 0.98,    -- Position
        0.0, 0.0, 0.0,                          -- Direction
        0.0, 0.0, 0.0,                          -- Rotation
        radius, radius, height,                 -- Scale
        color.r, color.g, color.b, color.a,     -- Color
        false, false, 2, false, nil, nil, false -- Other params
    )
end

function GetClosestZone(zoneType)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local closestZone = nil
    local closestDist = 999
    
    for _, zone in ipairs(Zones) do
        if zoneType == nil or zone.type == zoneType then
            local dist = #(playerCoords - vector3(zone.x, zone.y, zone.z))
            if dist < closestDist then
                closestDist = dist
                closestZone = zone
            end
        end
    end
    
    return closestZone, closestDist
end

function GetClosestParkingNPC()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local closestNPC = nil
    local closestDist = 999
    
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
-- Main Loop for Zone Detection
-- ========================================

CreateThread(function()
    while true do
        local sleep = 1000
        
        -- If using ox_target, we might not need markers at all, but we'll keep them efficient
        -- You could add: if not Config.UseOxTarget then ... to disable completely
        
        local playerCoords = GetEntityCoords(PlayerPedId())
        
        for _, zone in ipairs(Zones) do
            local zoneCoords = vector3(zone.x, zone.y, zone.z)
            local dist = #(playerCoords - zoneCoords)
            
            -- Only processing if within 20m
            if dist < 20.0 then
                sleep = 0 -- Tick faster when near a zone
                
                -- Draw marker if within range (and it's a crafting zone)
                if dist < 10.0 and zone.type == 'crafting' then
                    DrawMarker3D(zoneCoords, Config.CraftingMarker.radius, Config.CraftingMarker.height, Config.CraftingMarker.color)
                end
            end
        end
        
        Wait(sleep)
    end
end)

-- ========================================
-- NUI Callbacks (Global)
-- ========================================

-- Ensure the 'close' callback is always available
RegisterNUICallback('close', function(data, cb)
    if Config.Debug then print('^3[WagonMaker] NUI Close Requested^7') end
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Employee Management Callbacks
RegisterNUICallback('getEmployees', function(data, cb)
    local jobName = data.jobName or Config.GlobalJobName
    RSGCore.Functions.TriggerCallback('rsg-wagonmaker:server:getEmployees', function(employees)
        cb(employees)
    end, jobName)
end)

RegisterNUICallback('getNearbyPlayers', function(data, cb)
    RSGCore.Functions.TriggerCallback('rsg-wagonmaker:server:getNearbyPlayers', function(players)
        cb(players)
    end)
end)

RegisterNUICallback('hirePlayer', function(data, cb)
    TriggerServerEvent('rsg-wagonmaker:server:hirePlayer', data.targetId, data.jobName)
    cb('ok')
end)

RegisterNUICallback('firePlayer', function(data, cb)
    TriggerServerEvent('rsg-wagonmaker:server:firePlayer', data.citizenId, data.jobName)
    cb('ok')
end)

RegisterNUICallback('updateGrade', function(data, cb)
    TriggerServerEvent('rsg-wagonmaker:server:updateGrade', data.citizenId, data.jobName, data.newGrade)
    cb('ok')
end)

-- ========================================
-- Resource Cleanup
-- ========================================

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    
    -- Delete parking NPCs
    for _, ped in pairs(ParkingNPCs) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    
    -- Remove blips
    for _, blip in pairs(ParkingBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    
    -- Clean up preview wagon if exists
    if PreviewWagon and DoesEntityExist(PreviewWagon) then
        DeleteEntity(PreviewWagon)
    end
    
    -- Clean up spawned wagon if exists
    if MyWagon and DoesEntityExist(MyWagon) then
        DeleteEntity(MyWagon)
    end
end)
