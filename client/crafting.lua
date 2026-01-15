-- ========================================
-- RSG Wagon Maker - Crafting System
-- Handles wagon crafting in crafting zones
-- ========================================

local RSGCore = exports['rsg-core']:GetCoreObject()


local InCraftingZone = false
local CurrentCraftingZone = nil
local ActiveCraftingJob = nil  -- Stores the zone's requiredJob when crafting menu opens
local CurrentCraftingWagon = nil  -- The wagon being crafted (preview wagon converted to crafting)
local CurrentCraftingData = nil   -- Data about the current crafting session
local CraftingPrompt = nil
local CraftingGroup = GetRandomIntInRange(0, 0xffffff)

-- ========================================
-- Prompt Setup
-- ========================================

CreateThread(function()
    CraftingPrompt = Citizen.InvokeNative(0x04F97DE45A519419)
    PromptSetControlAction(CraftingPrompt, GetHashKey(Config.Keys.Interact))
    PromptSetText(CraftingPrompt, CreateVarString(10, "LITERAL_STRING", "Open Workshop"))
    PromptSetEnabled(CraftingPrompt, true)
    PromptSetVisible(CraftingPrompt, true)
    PromptSetHoldMode(CraftingPrompt, true)
    PromptSetGroup(CraftingPrompt, CraftingGroup, 0)
    PromptRegisterEnd(CraftingPrompt)
end)

-- ========================================
-- Zone Detection Loop
-- ========================================

CreateThread(function()
    -- Stop this thread if using ox_target (interactions handled via target)
    if Config.UseOxTarget then return end
    
    while true do
        local sleep = 500
        local zone, dist = GetClosestZone('crafting')
        
        if zone and dist < zone.radius then
            InCraftingZone = true
            CurrentCraftingZone = zone
            
            if IsWagonMaker(zone) then
                -- Only run at frame-rate for prompt display
                sleep = 0
                local groupLabel = CreateVarString(10, "LITERAL_STRING", GetLocale("crafting_zone"))
                PromptSetActiveGroupThisFrame(CraftingGroup, groupLabel, 0, 0, 0, 0)
                
                if PromptHasHoldModeCompleted(CraftingPrompt) then
                    OpenCraftingMenu()
                end
            else
                -- Not authorized - slower loop, just show text occasionally
                sleep = 100
                DrawText3D(zone.x, zone.y, zone.z + 1.0, "Authorized Personnel Only")
            end
        else
            InCraftingZone = false
            CurrentCraftingZone = nil
        end
        
        Wait(sleep)
    end
end)

-- ========================================
-- Crafting Menu
-- ========================================

function OpenCraftingMenu()
    -- Ensure we have a valid zone (especially if ox_target is used and loop is disabled)
    if not CurrentCraftingZone then
        local zone, dist = GetClosestZone('crafting')
        if zone and dist < (zone.radius + 2.0) then 
            CurrentCraftingZone = zone
        end
    end

    if not IsWagonMaker(CurrentCraftingZone) then
        Notify(GetLocale('job_required'), 'error')
        return
    end
    
    -- Store the zone's required job for later use (persists when player moves to preview)
    ActiveCraftingJob = CurrentCraftingZone and CurrentCraftingZone.requiredJob or nil
    
    local options = {}
    
    -- Crafting Option
    table.insert(options, {
        title = '🛠️ Craft Wagon',
        description = 'Build new wagons and carts',
        onSelect = function()
            OpenWagonCatalog()
        end
    })
    
    -- Storage Option (Job Stash)
    table.insert(options, {
        title = '📦 Storage',
        description = 'Access wagon maker supplies',
        onSelect = function()
            TriggerServerEvent('rsg-wagonmaker:server:openJobStash', CurrentCraftingZone.requiredJob)
        end
    })
    
    -- Management Option (Boss/Manager)
    if PlayerData.job.grade.level >= Config.JobGrades.manager then
        table.insert(options, {
            title = '💼 Management',
            description = 'Manage employees and finances',
            onSelect = function()
                TriggerEvent('rsg-bossmenu:client:OpenMenu')
            end
        })
    end

    local jobLabel = 'Wagon Maker'
    if CurrentCraftingZone.requiredJob and RSGCore.Shared.Jobs[CurrentCraftingZone.requiredJob] then
        jobLabel = RSGCore.Shared.Jobs[CurrentCraftingZone.requiredJob].label
    end
    
    -- Prepare NUI Options
    local nuiOptions = {}
    
    -- Craft Cart/Wagon
    table.insert(nuiOptions, {
        icon = 'hammer', -- FontAwesome icon name (fas fa-hammer)
        label = 'Craft Wagon',
        description = 'Build new wagons and carts',
        value = 'craft_wagon'
    })
    
    -- Storage
    table.insert(nuiOptions, {
        icon = 'box',
        label = 'Storage',
        description = 'Access wagon maker supplies',
        value = 'open_storage'
    })
    
    -- Management
    if PlayerData.job.grade.level >= Config.JobGrades.manager then
        table.insert(nuiOptions, {
            icon = 'briefcase',
            label = 'Management',
            description = 'Manage employees and finances',
            value = 'open_management'
        })
    end

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openOptions',
        title = jobLabel,
        options = nuiOptions,
        callbackName = 'mainMenuSelect' -- New callback needed in script.js or lua event
    })
end

-- (Removed duplicate logic)


function OpenCategoryMenu(category, playerMaterials)
    local options = {}
    
    for model, wagon in pairs(Config.Wagons) do
        if wagon.category == category then
            -- Check if player meets grade requirement
            local meetsGrade = true
            if wagon.requiredGrade and PlayerData.job then
                meetsGrade = PlayerData.job.grade.level >= wagon.requiredGrade
            end
            
            -- Build material list
            local materialDesc = BuildMaterialDescription(wagon.materials, playerMaterials)
            local canCraft = CanCraftWagon(wagon, playerMaterials) and meetsGrade
            
            local priceText = wagon.price > 0 and ('+ $' .. wagon.price) or ''
            local gradeText = not meetsGrade and ' ⚠️ Skill Required' or ''
            
            table.insert(options, {
                title = wagon.label .. gradeText,
                description = wagon.description .. '\n\n' .. materialDesc .. '\n' .. priceText,
                disabled = not canCraft,
                onSelect = function()
                    OpenWagonCraftMenu(model, wagon, playerMaterials)
                end
            })
        end
    end
    
    if #options == 0 then
        table.insert(options, {
            title = 'No wagons available',
            description = 'No recipes in this category',
            disabled = true
        })
    end
    
    lib.registerContext({
        id = 'wagonmaker_category',
        title = string.upper(category:sub(1,1)) .. category:sub(2) .. ' Wagons',
        menu = 'wagonmaker_main',
        options = options
    })
    lib.showContext('wagonmaker_category')
end

-- ========================================
-- Custom UI Logic
-- ========================================

RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('selectWagon', function(data, cb)
    local model = data.model
    SetNuiFocus(false, false) -- Release focus immediately selection is made
    if not model then return end
    
    -- Job check before previewing
    if not IsWagonMaker(CurrentCraftingZone) then
        Notify(GetLocale('job_required'), 'error')
        cb('ok')
        return
    end
    
    TriggerEvent('rsg-wagonmaker:client:startPreview', model)
    cb('ok')
end)

RegisterNUICallback('mainMenuSelect', function(data, cb)
    local value = data.value
    SetNuiFocus(false, false)
    
    if value == 'craft_wagon' then
        OpenWagonCatalog()
    elseif value == 'open_storage' then
        if CurrentCraftingZone and CurrentCraftingZone.requiredJob then
            TriggerServerEvent('rsg-wagonmaker:server:openJobStash', CurrentCraftingZone.requiredJob)
        else
            Notify(GetLocale('job_required'), 'error')
        end
    elseif value == 'open_management' then
        OpenManagementOptions()
    end
    
    cb('ok')
end)

-- Emergency command to unlock cursor/UI
RegisterCommand('wm_fixui', function()
    SetNuiFocus(false, false)
    Notify('UI Focus Reset', 'success')
end, false)



function OpenManagementOptions()
    lib.callback('rsg-wagonmaker:server:getFundBalance', false, function(balance)
        SetNuiFocus(true, true)
        local grade = RSGCore.Functions.GetPlayerData().job.grade.level
        SendNUIMessage({
            action = 'openManagement',
            balance = balance or 0,
            grade = grade
        })
    end)
end

RegisterNUICallback('managementOption', function(data, cb)
    local action = data.action
    
    if action == 'boss' then
        SetNuiFocus(false, false)
        
        -- Try to detect and open the correct boss menu
        if GetResourceState('rsg-bossmenu') == 'started' then
            TriggerEvent('rsg-bossmenu:client:openMenu')
        elseif GetResourceState('rsg-management') == 'started' then
            TriggerEvent('rsg-management:client:openMenu')
        else
            -- Fallback: Try common events
            TriggerEvent('rsg-bossmenu:client:OpenMenu')
            TriggerEvent('rsg-management:client:OpenMenu')
        end
    elseif action == 'deposit' then
        -- Keep NUI focus for input? No, standard input dialog is easier
        -- or use lib.inputDialog which works over NUI if configured right, 
        -- but safer to close NUI temporarily or overlay.
        -- Let's close NUI for the input, then maybe reopen? 
        -- For now, simple flow: Close NUI -> Input -> Done.
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'close' })
        
        local input = lib.inputDialog('Deposit Funds', {
            { type = 'number', label = 'Amount', min = 1, required = true }
        })
        
        if input and input[1] then
            TriggerServerEvent('rsg-wagonmaker:server:depositMoney', input[1])
        end
        -- Re-open menu to show updated balance? 
        -- Would need to fetch balance again.
        Wait(500)
        OpenManagementOptions()
        
    elseif action == 'withdraw' then
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'close' })
        
        local input = lib.inputDialog('Withdraw Funds', {
            { type = 'number', label = 'Amount', min = 1, required = true }
        })
        
        if input and input[1] then
            TriggerServerEvent('rsg-wagonmaker:server:withdrawMoney', input[1])
        end
        Wait(500)
        OpenManagementOptions()
    end
    
    cb('ok')
end)

function OpenWagonCatalog()
    if not IsWagonMaker(CurrentCraftingZone) then
        Notify(GetLocale('job_required'), 'error')
        return
    end

    -- Prepare data for NUI
    local wagonList = {}
    local count = 0
    
    for model, data in pairs(Config.Wagons) do
        -- Check job grade requirement
        local canSee = true
        if data.requiredGrade and PlayerData.job.grade.level < data.requiredGrade then
            canSee = false -- Or show as locked
        end
        
        if canSee then
            count = count + 1
            table.insert(wagonList, {
                model = model,
                label = data.label,
                price = data.price,
                description = data.description or "A sturdy wagon.",
                category = data.category or "uncategorized",
                materials = data.materials or {}
            })
        end
    end
    
    -- Safety check
    if count == 0 then
        Notify('No wagons available for you.', 'error')
        return
    end
    
    -- Ensure it sends as an array even if 1 item
    -- Lua tables are usually fine but explicit sorting helps
    table.sort(wagonList, function(a, b) return a.label < b.label end)
    
    -- Open UI
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        wagons = wagonList,
        materialConfig = Config.Materials
    })
end

-- ========================================
-- Crafting Process
-- ========================================

function StartCrafting(model, wagon, customization)
    -- Use stored job from when menu opened (persists when player moves to preview area)
    local requiredJob = ActiveCraftingJob
    
    -- Must have a preview wagon to craft
    if not PreviewWagon or not DoesEntityExist(PreviewWagon) then
        Notify('No wagon preview found. Please preview a wagon first.', 'error')
        return
    end
    
    -- Final validation on server (pass requiredJob for proper validation)
    lib.callback('rsg-wagonmaker:server:canCraft', false, function(canCraft, reason)
        if not canCraft then
            Notify(reason or GetLocale('crafting_failed'), 'error')
            return
        end
        
        -- Get wagon name from player
        local wagonName = lib.inputDialog('Name Your Wagon', {
            { type = 'input', label = 'Wagon Name', placeholder = wagon.label, required = true, max = 50 }
        })
        
        if not wagonName or not wagonName[1] or wagonName[1] == '' then
            Notify('Crafting cancelled', 'inform')
            return
        end
        
        -- REUSE THE PREVIEW WAGON - Don't delete it, convert it to crafting wagon!
        CurrentCraftingWagon = PreviewWagon
        CurrentCraftingData = {
            model = model,
            name = wagonName[1],
            customization = customization
        }
        
        -- Clear preview reference (wagon now belongs to crafting flow)
        PreviewWagon = nil
        
        -- Unfreeze the wagon so it can be interacted with
        FreezeEntityPosition(CurrentCraftingWagon, false)
        
        -- Remove preview ox_target options
        if Config.UseOxTarget then
            exports.ox_target:removeLocalEntity(CurrentCraftingWagon, { 
                'preview_livery', 'preview_tint', 'preview_exit', 'preview_stop' 
            })
        end
        
        -- Add crafting ox_target - Fix Wheel
        if Config.UseOxTarget then
            exports.ox_target:addLocalEntity(CurrentCraftingWagon, {
                {
                    name = 'wagonmaker_fix_wheel',
                    icon = 'fas fa-wrench',
                    label = '🔧 Fix Wagon Wheel',
                    onSelect = function()
                        FixWagonWheel()
                    end,
                    distance = 3.0
                },
                {
                    name = 'wagonmaker_cancel_craft',
                    icon = 'fas fa-times',
                    label = '❌ Cancel Crafting',
                    onSelect = function()
                        CancelCrafting()
                    end,
                    distance = 3.0
                }
            })
        end
        
        Notify('Wagon ready! Go to the wagon and fix the wheel to complete crafting.', 'inform')
    end, model, requiredJob)
end

exports('StartCrafting', StartCrafting)
RegisterNetEvent('rsg-wagonmaker:client:startCraftingInternal', StartCrafting)

function FixWagonWheel()
    if not CurrentCraftingWagon or not DoesEntityExist(CurrentCraftingWagon) then
        Notify('No wagon to fix', 'error')
        return
    end
    
    local ped = PlayerPedId()
    local wagonCoords = GetEntityCoords(CurrentCraftingWagon)
    local playerCoords = GetEntityCoords(ped)
    
    -- Face towards the wagon
    local heading = GetHeadingFromVector_2d(wagonCoords.x - playerCoords.x, wagonCoords.y - playerCoords.y)
    SetEntityHeading(ped, heading)
    Wait(100)
    
    -- Play hammering scenario animation
    -- specific RedM scenario for hammering/repairing
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_HAMMER_TABLE', -1, true)
    
    -- Show progress bar with crafting animation
    local success = lib.progressBar({
        duration = 12000,
        label = '🔧 Assembling wagon wheel...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
            mouse = false
        }
    })
    
    ClearPedTasks(ped)
    
    if success then
        -- Tell server to finalize the craft (no netId - wagon is local)
        TriggerServerEvent('rsg-wagonmaker:server:finalizeCraftLocal', 
            CurrentCraftingData.model,
            CurrentCraftingData.name,
            CurrentCraftingData.customization,
            ActiveCraftingJob  -- Pass job for validation
        )
        
        -- Clean up local tracking
        if CurrentCraftingWagon and DoesEntityExist(CurrentCraftingWagon) then
            exports.ox_target:removeLocalEntity(CurrentCraftingWagon, {'wagonmaker_fix_wheel', 'wagonmaker_cancel_craft'})
            -- Delete the local wagon (player will get it from parking)
            DeleteEntity(CurrentCraftingWagon)
        end
        CurrentCraftingWagon = nil
        CurrentCraftingData = nil
    else
        Notify('Wheel fix cancelled', 'inform')
    end
end

function CancelCrafting()
    if CurrentCraftingWagon and DoesEntityExist(CurrentCraftingWagon) then
        exports.ox_target:removeLocalEntity(CurrentCraftingWagon, {'wagonmaker_fix_wheel', 'wagonmaker_cancel_craft'})
        DeleteEntity(CurrentCraftingWagon)
    end
    CurrentCraftingWagon = nil
    CurrentCraftingData = nil
    
    Notify('Crafting cancelled', 'inform')
end

-- Handle craft success
RegisterNetEvent('rsg-wagonmaker:client:craftSuccess', function(wagonLabel)
    Notify('Successfully crafted ' .. wagonLabel .. '! Visit Wagon Yard to retrieve it.', 'success')
end)

-- Handle craft failed
RegisterNetEvent('rsg-wagonmaker:client:craftFailed', function(reason)
    Notify(reason or 'Crafting failed', 'error')
    
    if CurrentCraftingWagon and DoesEntityExist(CurrentCraftingWagon) then
        exports.ox_target:removeLocalEntity(CurrentCraftingWagon, {'wagonmaker_fix_wheel', 'wagonmaker_cancel_craft'})
    end
    CurrentCraftingWagon = nil
    CurrentCraftingData = nil
end)

-- Delete any non-player peds within range of wagon (catches horses)
function DeleteNearbyHorses(wagon)
    if not wagon or not DoesEntityExist(wagon) then return end
    
    local wagonCoords = GetEntityCoords(wagon)
    local handle, ped = FindFirstPed()
    local success = true
    local pedsToDelete = {}
    
    repeat
        if DoesEntityExist(ped) and ped ~= PlayerPedId() then
            local pedCoords = GetEntityCoords(ped)
            local pedDist = #(wagonCoords - pedCoords)
            
            -- Delete ANY non-player ped within 8m of the wagon
            if pedDist < 8.0 then
                table.insert(pedsToDelete, ped)
            end
        end
        success, ped = FindNextPed(handle)
    until not success
    
    EndFindPed(handle)
    
    -- Delete collected peds
    for _, p in ipairs(pedsToDelete) do
        if DoesEntityExist(p) then
            SetEntityAsMissionEntity(p, true, true)
            DeleteEntity(p)
        end
    end
end
function IsModelAHorse(model)
    local horseModels = {
        `a_c_horse_americanpaint_greyovero`,
        `a_c_horse_americanpaint_overo`,
        `a_c_horse_americanpaint_splashedwhite`,
        `a_c_horse_americanpaint_tobiano`,
        `a_c_horse_americanstandardbred_black`,
        `a_c_horse_americanstandardbred_buckskin`,
        `a_c_horse_americanstandardbred_lightbuckskin`,
        `a_c_horse_americanstandardbred_palominodapple`,
        `a_c_horse_americanstandardbred_silvertailbuckskin`,
        `a_c_horse_andalusian_darkbay`,
        `a_c_horse_andalusian_perlino`,
        `a_c_horse_andalusian_rosegray`,
        `a_c_horse_appaloosa_blacksnowflake`,
        `a_c_horse_appaloosa_blanket`,
        `a_c_horse_appaloosa_brownleopard`,
        `a_c_horse_appaloosa_fewspotted_pc`,
        `a_c_horse_appaloosa_leopard`,
        `a_c_horse_appaloosa_leopardblanket`,
        `a_c_horse_arabian_black`,
        `a_c_horse_arabian_grey`,
        `a_c_horse_arabian_redchestnut`,
        `a_c_horse_arabian_redchestnut_pc`,
        `a_c_horse_arabian_rosegreybay`,
        `a_c_horse_arabian_warpedbrindle_pc`,
        `a_c_horse_arabian_white`,
        `a_c_horse_ardennes_bayroan`,
        `a_c_horse_ardennes_irongreyroan`,
        `a_c_horse_ardennes_strawberryroan`,
        `a_c_horse_belgian_blondchestnut`,
        `a_c_horse_belgian_mealychestnut`,
        `a_c_horse_breton_grullodun`,
        `a_c_horse_breton_mealydapplebay`,
        `a_c_horse_breton_redroan`,
        `a_c_horse_breton_sealbrown`,
        `a_c_horse_breton_sorrel`,
        `a_c_horse_breton_steelgrey`,
        `a_c_horse_buell_warvets`,
        `a_c_horse_criollo_baybrindle`,
        `a_c_horse_criollo_bayframeovero`,
        `a_c_horse_criollo_blueroanovero`,
        `a_c_horse_criollo_dun`,
        `a_c_horse_criollo_marblesabino`,
        `a_c_horse_criollo_sorrelovero`,
        `a_c_horse_dutchwarmblood_chocolateroan`,
        `a_c_horse_dutchwarmblood_sealbrown`,
        `a_c_horse_dutchwarmblood_sootybuckskin`,
        `a_c_horse_gang_bill`,
        `a_c_horse_gang_charles`,
        `a_c_horse_gang_charles_endlesssummer`,
        `a_c_horse_gang_dutch`,
        `a_c_horse_gang_hosea`,
        `a_c_horse_gang_javier`,
        `a_c_horse_gang_john`,
        `a_c_horse_gang_karen`,
        `a_c_horse_gang_kieran`,
        `a_c_horse_gang_lenny`,
        `a_c_horse_gang_micah`,
        `a_c_horse_gang_sadie`,
        `a_c_horse_gang_sadie_endlesssummer`,
        `a_c_horse_gang_sean`,
        `a_c_horse_gang_trelawney`,
        `a_c_horse_gang_uncle`,
        `a_c_horse_gang_uncle_endlesssummer`,
        `a_c_horse_klad_dunperlino`,
        `a_c_horse_klad_rose`,
        `a_c_horse_klad_silver`,
        `a_c_horse_hungarian_darkdapplegrey`,
        `a_c_horse_hungarian_flaxenchestnut`,
        `a_c_horse_hungarian_liverchestnut`,
        `a_c_horse_hungarian_piebaldtobiano`,
        `a_c_horse_kentuckysaddle_black`,
        `a_c_horse_kentuckysaddle_buttermilkbuckskin_pc`,
        `a_c_horse_kentuckysaddle_chestnutpinto`,
        `a_c_horse_kentuckysaddle_grey`,
        `a_c_horse_kentuckysaddle_silverbay`,
        `a_c_horse_missourifoxtrotter_amberchampagne`,
        `a_c_horse_missourifoxtrotter_blacktovero`,
        `a_c_horse_missourifoxtrotter_blueroan`,
        `a_c_horse_missourifoxtrotter_buckskinbrindle`,
        `a_c_horse_missourifoxtrotter_dapplegrey`,
        `a_c_horse_missourifoxtrotter_sablechampagne`,
        `a_c_horse_missourifoxtrotter_silverdapplepinto`,
        `a_c_horse_morgan_bay`,
        `a_c_horse_morgan_bayroan`,
        `a_c_horse_morgan_flaxenchestnut`,
        `a_c_horse_morgan_liverchestnut_pc`,
        `a_c_horse_morgan_palomino`,
        `a_c_horse_mp_mangy_backup`,
        `a_c_horse_mule_01`,
        `a_c_horse_mustang_blackovero`,
        `a_c_horse_mustang_buckskin`,
        `a_c_horse_mustang_chestnuttovero`,
        `a_c_horse_mustang_goldendun`,
        `a_c_horse_mustang_grullodun`,
        `a_c_horse_mustang_tigerstripedbay`,
        `a_c_horse_mustang_wildbaytovero`,
        `a_c_horse_nokota_blueroan`,
        `a_c_horse_nokota_reversedappleroan`,
        `a_c_horse_nokota_whiteroan`,
        `a_c_horse_norfolkroadster_black`,
        `a_c_horse_norfolkroadster_dappledbuckskin`,
        `a_c_horse_norfolkroadster_piebaldroan`,
        `a_c_horse_norfolkroadster_rosegrey`,
        `a_c_horse_norfolkroadster_speckledgrey`,
        `a_c_horse_norfolkroadster_spottedtricolor`,
    }
    
    for _, horseHash in ipairs(horseModels) do
        if model == horseHash then
            return true
        end
    end
    return false
end

-- ========================================
-- Helper Functions
-- ========================================

function BuildMaterialDescription(materials, playerMaterials)
    local lines = {}
    playerMaterials = playerMaterials or {}  -- Default to empty table if nil
    
    for _, mat in ipairs(materials) do
        local playerAmount = playerMaterials[mat.item] or 0
        local matConfig = Config.Materials[mat.item]
        local label = matConfig and matConfig.label or mat.item
        
        local status = playerAmount >= mat.amount and '✅' or '❌'
        table.insert(lines, string.format('%s %s: %d/%d', status, label, playerAmount, mat.amount))
    end
    
    return table.concat(lines, '\n')
end

function CanCraftWagon(wagon, playerMaterials)
    playerMaterials = playerMaterials or {}  -- Default to empty table if nil
    for _, mat in ipairs(wagon.materials) do
        local playerAmount = playerMaterials[mat.item] or 0
        if playerAmount < mat.amount then
            return false
        end
    end
    return true
end

-- ========================================
-- Server Response Handlers
-- ========================================

RegisterNetEvent('rsg-wagonmaker:client:craftSuccess', function(wagonLabel)
    Notify(GetLocale('crafting_complete', wagonLabel), 'success')
end)

RegisterNetEvent('rsg-wagonmaker:client:craftFailed', function(reason)
    Notify(reason or GetLocale('crafting_failed'), 'error')
end)
