-- ========================================
-- RSG Wagon Maker - Preview System
-- Live wagon preview in preview zones
-- ========================================

local RSGCore = exports['rsg-core']:GetCoreObject()

PreviewWagon = nil
local PreviewModel = nil
local PreviewCustomization = {
    livery = -1,
    tint = 0
}
local InPreviewZone = false
local PreviewTimeout = nil

local PreviewPrompt = nil
local PreviewGroup = GetRandomIntInRange(0, 0xffffff)

-- ========================================
-- Prompt Setup
-- ========================================

CreateThread(function()
    PreviewPrompt = Citizen.InvokeNative(0x04F97DE45A519419)
    PromptSetControlAction(PreviewPrompt, GetHashKey(Config.Keys.Cancel))
    PromptSetText(PreviewPrompt, CreateVarString(10, "LITERAL_STRING", "Exit Preview"))
    PromptSetEnabled(PreviewPrompt, true)
    PromptSetVisible(PreviewPrompt, true)
    PromptSetStandardMode(PreviewPrompt, true)
    PromptSetGroup(PreviewPrompt, PreviewGroup, 0)
    PromptRegisterEnd(PreviewPrompt)
end)

-- ========================================
-- Zone Detection Loop
-- ========================================

CreateThread(function()
    while true do
        local sleep = 500
        local zone, dist = GetClosestZone('preview')
        
        if zone and dist < zone.radius then
            InPreviewZone = true
            
            if PreviewWagon and DoesEntityExist(PreviewWagon) then
                sleep = 0
                -- Show exit prompt
                local groupLabel = CreateVarString(10, "LITERAL_STRING", GetLocale("preview_zone"))
                PromptSetActiveGroupThisFrame(PreviewGroup, groupLabel, 0, 0, 0, 0)
                
                -- Check for rotation inputs
                if IsControlPressed(0, GetHashKey(Config.Keys.RotateLeft)) then
                    local heading = GetEntityHeading(PreviewWagon)
                    SetEntityHeading(PreviewWagon, heading + 1.0)
                end
                
                if IsControlPressed(0, GetHashKey(Config.Keys.RotateRight)) then
                    local heading = GetEntityHeading(PreviewWagon)
                    SetEntityHeading(PreviewWagon, heading - 1.0)
                end
                
                -- Exit preview on prompt
                if PromptHasStandardModeCompleted(PreviewPrompt) then
                    EndPreview()
                end
            end
        else
            InPreviewZone = false
            -- Don't auto-delete preview - let it stay until timeout or manual cancel
        end
        
        Wait(sleep)
    end
end)

-- ========================================
-- Preview Events
-- ========================================

RegisterNetEvent('rsg-wagonmaker:client:startPreview', function(model, customization)
    -- Check job requirements for nearest preview zone or generally
    local zone, dist = GetClosestZone('preview')
    
    -- if not IsWagonMaker(zone) then
    --     Notify(GetLocale('job_required'), 'error')
    --     return
    -- end

    local spawnLocation = nil
    
    -- Priority 1: Explicit Preview Zone
    if zone and dist < 50.0 then
        spawnLocation = {x = zone.x, y = zone.y, z = zone.z, h = zone.h or 0.0}
    else
        -- Priority 2: Closest Crafting NPC (with previewPoint)
        -- THIS IS PRIORITY now because the user provided specific coords for crafting areas
        local craftingNPC, cDist = GetClosestCraftingNPC()
        if craftingNPC and cDist < 50.0 and craftingNPC.previewPoint then
             spawnLocation = {
                 x = craftingNPC.previewPoint.x, 
                 y = craftingNPC.previewPoint.y, 
                 z = craftingNPC.previewPoint.z, 
                 h = craftingNPC.previewHeading or 0.0
             }
        else
            -- Priority 3: Nearest Parking Spawn Point (Garage)
            -- Only use if no specific crafting preview point exists
            local parkingNPC, pDist = GetClosestParkingNPC()
            if parkingNPC and pDist < 50.0 then
                 -- Use the parking spawn point
                 spawnLocation = {
                     x = parkingNPC.spawnPoint.x, 
                     y = parkingNPC.spawnPoint.y, 
                     z = parkingNPC.spawnPoint.z, 
                     h = parkingNPC.spawnHeading or 0.0
                 }
            else
                -- Priority 4: Fallback (In front of player)
                local ped = PlayerPedId()
                local fwd = GetOffsetFromEntityInWorldCoords(ped, 0.0, 5.0, 0.0)
                local h = GetEntityHeading(ped)
                spawnLocation = {x = fwd.x, y = fwd.y, z = fwd.z, h = h}
                Notify('Previewing at your location (No designated spot found).', 'inform')
            end
        end
    end
    
    PreviewModel = model
    PreviewCustomization = customization or { livery = -1, tint = 0 }
    
    SpawnPreview(spawnLocation)

    -- ADDED: Rotation Loop for Q/E
    CreateThread(function()
        while PreviewWagon and DoesEntityExist(PreviewWagon) do
            Wait(0)
            -- Left Arrow Key (Rotate Left)
            if IsControlPressed(0, 0xA65EBAB4) then 
                local currentHeading = GetEntityHeading(PreviewWagon)
                SetEntityHeading(PreviewWagon, currentHeading + 1.0)
            end
            
            -- Right Arrow Key (Rotate Right)
            if IsControlPressed(0, 0xDEB34313) then 
                local currentHeading = GetEntityHeading(PreviewWagon)
                SetEntityHeading(PreviewWagon, currentHeading - 1.0)
            end
        end
    end)
end)

RegisterNetEvent('rsg-wagonmaker:client:endPreview', function()
    EndPreview()
end)

-- NUI Callbacks for Customization
RegisterNUICallback('selectLivery', function(data, cb)
    SetNuiFocus(false, false)
    if data.value then
        PreviewCustomization.livery = data.value
        ApplyCustomization(PreviewWagon, PreviewCustomization)
    end
    cb('ok')
end)

RegisterNUICallback('selectTint', function(data, cb)
    SetNuiFocus(false, false)
    if data.value then
        PreviewCustomization.tint = data.value
        ApplyCustomization(PreviewWagon, PreviewCustomization)
    end
    cb('ok')
end)

RegisterNetEvent('rsg-wagonmaker:client:updatePreviewLivery', function(livery)
    PreviewCustomization.livery = livery
    
    if PreviewWagon and DoesEntityExist(PreviewWagon) then
        ApplyCustomization(PreviewWagon, PreviewCustomization)
    end
end)

RegisterNetEvent('rsg-wagonmaker:client:updatePreviewTint', function(tint)
    PreviewCustomization.tint = tint
    
    if PreviewWagon and DoesEntityExist(PreviewWagon) then
        ApplyCustomization(PreviewWagon, PreviewCustomization)
    end
end)

-- ========================================
-- Preview Functions
-- ========================================

function SpawnPreview(location)
    -- Clean up existing preview
    if PreviewWagon and DoesEntityExist(PreviewWagon) then
        DeleteEntity(PreviewWagon)
        PreviewWagon = nil
    end
    
    if not PreviewModel then
        Notify('Select a wagon to preview first', 'error')
        return
    end
    
    local wagonConfig = Config.Wagons[PreviewModel]
    if not wagonConfig then
        Notify('Invalid wagon model', 'error')
        return
    end
    
    local hash = GetHashKey(PreviewModel)
    RequestModel(hash, false)
    while not HasModelLoaded(hash) do
        Wait(10)
    end
    
    -- Spawn wagon (Networked for visibility)
    -- CreateVehicle(modelHash, x, y, z, heading, isNetwork, netMissionEntity, p7, p8)
    PreviewWagon = CreateVehicle(hash, location.x, location.y, location.z, location.h or 0.0, true, true, false, false)
    
    -- Set as mission entity so it doesn't despawn
    SetEntityAsMissionEntity(PreviewWagon, true, true)
    
    -- Set on ground properly (Native)
    Citizen.InvokeNative(0x7263332501E07F52, PreviewWagon, true)
    
    -- Freeze in place
    FreezeEntityPosition(PreviewWagon, true)
    
    -- Make invincible
    SetEntityInvincible(PreviewWagon, true)
    
    -- Remove any attached horses/peds (Brute Force Loop)
    CreateThread(function()
        local attempts = 0
        while attempts < 20 do -- Try for 2 seconds
            Wait(100)
            if PreviewWagon and DoesEntityExist(PreviewWagon) then
                -- Method 1: Native Draft Horse Deletion
                Citizen.InvokeNative(0xB32A5813C7F87B09, PreviewWagon)
                
                -- Method 2: Radius/Attachment Cleanup
                local peds = GetGamePool('CPed')
                local wagonCoords = GetEntityCoords(PreviewWagon)
                
                for _, ped in ipairs(peds) do
                    if DoesEntityExist(ped) and ped ~= PlayerPedId() then
                        local pedCoords = GetEntityCoords(ped)
                        local dist = #(wagonCoords - pedCoords)
                        
                        -- CRITICAL: Logic to remove draft horses
                        -- 1. If it is physically attached to the wagon, it is a draft horse. DELETE IT.
                        if IsEntityAttachedToEntity(ped, PreviewWagon) then
                            DeleteEntity(ped)
                        
                        -- 2. If it is very close and looks like a horse, delete it (catch loose draft horses)
                        elseif dist < 15.0 and IsModelAHorse(GetEntityModel(ped)) then
                            DeleteEntity(ped)
                        end
                    end
                end
            end
            attempts = attempts + 1
        end
    end)
    
    -- Apply customization
    ApplyCustomization(PreviewWagon, PreviewCustomization)
    
    -- Clean dirt
    SetVehicleDirtLevel(PreviewWagon, 0.0)
    
    SetModelAsNoLongerNeeded(hash)
    
    Notify(GetLocale('preview_started', wagonConfig.label), 'inform')
    
    -- Add ox_target interactions for customization
    if Config.UseOxTarget then
        exports.ox_target:addLocalEntity(PreviewWagon, {
            {
                name = 'preview_livery',
                icon = 'fas fa-paint-brush',
                label = 'Change Livery',
                onSelect = function()
                    OpenPreviewLiveryMenu(PreviewModel)
                end,
                distance = 3.0
            },
            {
                name = 'preview_tint',
                icon = 'fas fa-palette',
                label = 'Change Color',
                onSelect = function()
                    OpenPreviewTintMenu(PreviewModel)
                end,
                distance = 3.0
            },
            {
                name = 'preview_exit',
                icon = 'fas fa-check-circle',
                label = 'Confirm & Craft',
                onSelect = function()
                    local wagonConfig = Config.Wagons[PreviewModel]
                    -- Call the crafting function via event
                    TriggerEvent('rsg-wagonmaker:client:startCraftingInternal', PreviewModel, wagonConfig, PreviewCustomization)
                end,
                distance = 3.0
            },
            {
                name = 'preview_stop',
                icon = 'fas fa-times-circle',
                label = 'Stop Preview',
                onSelect = function()
                    EndPreview()
                end,
                distance = 3.0
            }
        })
    end
    
    -- Start timeout
    StartPreviewTimeout()
end



-- Helper: Check if model is a horse (Comparing Hashes Directly)
function IsModelAHorse(model)
    -- Wagons typically only spawn with Draft horses (Shire, Belgian, Suffolk Punch)
    local horseModels = {
        `a_c_horse_shire_darkbay`, 
        `a_c_horse_shire_lightgrey`, 
        `a_c_horse_shire_ravenblack`,
        `a_c_horse_belgian_blondchestnut`, 
        `a_c_horse_belgian_mealychestnut`,
        `a_c_horse_suffolkpunch_redchestnut`, 
        `a_c_horse_suffolkpunch_sorrel`
    }
    
    for _, horseHash in ipairs(horseModels) do
        if model == horseHash then
            return true
        end
    end
    return false
end

function OpenPreviewLiveryMenu(model)
    local wagon = Config.Wagons[model]
    if not wagon or not wagon.customizations.livery then return end
    
    local options = {}
    
    for _, livery in ipairs(wagon.customizations.livery) do
        local label = livery == -1 and 'Default' or 'Style ' .. livery
        table.insert(options, {
            label = label,
            value = livery
        })
    end
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openOptions',
        title = 'Select Livery',
        options = options,
        callbackName = 'selectLivery'
    })
end

function OpenPreviewTintMenu(model)
    local wagon = Config.Wagons[model]
    if not wagon or not wagon.customizations.tint then return end
    
    local options = {}
    
    for _, tint in ipairs(wagon.customizations.tint) do
        table.insert(options, {
            label = 'Color ' .. tint,
            value = tint
        })
    end
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openOptions',
        title = 'Select Color',
        options = options,
        callbackName = 'selectTint'
    })
end

function ApplyCustomization(wagon, customization)
    if not wagon or not DoesEntityExist(wagon) then return end
    
    -- Apply tint
    Citizen.InvokeNative(0x8268B098F6FCA4E2, wagon, customization.tint or 0)
    
    -- Apply livery
    if customization.livery and customization.livery >= 0 then
        Citizen.InvokeNative(0xF89D82A0582E46ED, wagon, customization.livery)
    end
    
    -- Apply props if any
    if customization.props then
        Citizen.InvokeNative(0x75F90E4051CC084C, wagon, GetHashKey(customization.props))
    end
    
    -- Apply lantern if any
    if customization.lantern then
        Citizen.InvokeNative(0xC0F0417A90402742, wagon, GetHashKey(customization.lantern))
    end
    
    -- Apply extras
    for i = 0, 10 do
        if DoesExtraExist(wagon, i) then
            Citizen.InvokeNative(0xBB6F89150BC9D16B, wagon, i, true) -- Disable all extras
        end
    end
    
    if customization.extra and customization.extra > 0 then
        Citizen.InvokeNative(0xBB6F89150BC9D16B, wagon, customization.extra, false) -- Enable selected extra
    end
end

function EndPreview()
    if PreviewWagon then
        if DoesEntityExist(PreviewWagon) then
            SetEntityAsMissionEntity(PreviewWagon, true, true)
            DeleteVehicle(PreviewWagon)
            DeleteEntity(PreviewWagon)
        end
        PreviewWagon = nil
    end
    
    PreviewModel = nil
    
    if PreviewTimeout then
        PreviewTimeout = nil
    end
end

function StartPreviewTimeout()
    if PreviewTimeout then
        PreviewTimeout = nil
    end
    
    PreviewTimeout = true
    
    CreateThread(function()
        local elapsed = 0
        while PreviewTimeout and elapsed < Config.MaxPreviewTime do
            Wait(1000)
            elapsed = elapsed + 1
        end
        
        if PreviewTimeout and PreviewWagon and DoesEntityExist(PreviewWagon) then
            Notify(GetLocale('preview_timeout'), 'inform')
            EndPreview()
        end
    end)
end

-- ========================================
-- Camera System (Optional Enhanced View)
-- ========================================

local PreviewCam = nil
local CamActive = false

function StartPreviewCamera(targetCoords)
    if CamActive then return end
    
    local camCoords = targetCoords + vector3(5.0, 5.0, 2.0)
    
    PreviewCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(PreviewCam, camCoords.x, camCoords.y, camCoords.z)
    PointCamAtCoord(PreviewCam, targetCoords.x, targetCoords.y, targetCoords.z + 1.0)
    SetCamActive(PreviewCam, true)
    RenderScriptCams(true, true, 500, true, true)
    
    CamActive = true
end

function EndPreviewCamera()
    if not CamActive then return end
    
    RenderScriptCams(false, true, 500, true, true)
    DestroyCam(PreviewCam, false)
    PreviewCam = nil
    CamActive = false
end

-- Export for external use
exports('IsInPreviewZone', function()
    return InPreviewZone
end)

exports('GetPreviewWagon', function()
    return PreviewWagon
end)
