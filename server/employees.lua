local RSGCore = exports['rsg-core']:GetCoreObject()

-- ============================================================================
-- RSG WAGONMAKER - SERVER EMPLOYEES
-- Hire/Fire/Promote Logic (similar to rsg-saloon)
-- ============================================================================

-- Data Helper
local function GetGradeLabel(grade)
    local labels = {
        [0] = 'Apprentice',
        [1] = 'Craftsman',
        [2] = 'Manager',
        [3] = 'Owner'
    }
    return labels[grade] or 'Unknown'
end

-- ============================================================================
-- HIRE PLAYER
-- ============================================================================
RegisterNetEvent('rsg-wagonmaker:server:hirePlayer', function(targetId, jobName)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local TargetPlayer = RSGCore.Functions.GetPlayer(targetId)

    if not Player or not TargetPlayer then return end

    -- Permission Check: Must be Boss (Grade 3) or Manager (Grade 2) depending on config
    -- For now, enforcing Grade 3 (Owner/Boss) for Hiring
    if Player.PlayerData.job.name ~= jobName or Player.PlayerData.job.grade.level < 3 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You do not have permission to hire.' })
        return
    end

    -- Check if target already has a job
    if TargetPlayer.PlayerData.job.name ~= 'unemployed' and TargetPlayer.PlayerData.job.name ~= jobName then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Player is already employed elsewhere.' })
        return
    end

    -- Check Employee Limit (Max 4)
    local count = MySQL.scalar.await('SELECT COUNT(*) FROM wagon_maker_employees WHERE job_name = ?', { jobName })
    if count >= 4 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Max employees reached (4).' })
        return
    end

    -- Default Hire Grade: 0
    local grade = 0
    
    -- Set Job
    TargetPlayer.Functions.SetJob(jobName, grade)
    TargetPlayer.Functions.Save()

    -- Notify
    local targetName = TargetPlayer.PlayerData.charinfo.firstname .. ' ' .. TargetPlayer.PlayerData.charinfo.lastname
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Hired ' .. targetName })
    TriggerClientEvent('ox_lib:notify', targetId, { type = 'success', description = 'You were hired as ' .. GetGradeLabel(grade) })

    -- Add to Database
    MySQL.insert('INSERT IGNORE INTO wagon_maker_employees (job_name, citizenid, player_name) VALUES (?, ?, ?)',
        { jobName, TargetPlayer.PlayerData.citizenid, targetName })
end)

-- ============================================================================
-- FIRE PLAYER
-- ============================================================================
RegisterNetEvent('rsg-wagonmaker:server:firePlayer', function(targetCitizenId, jobName)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end

    -- Permission: Boss Only
    if Player.PlayerData.job.name ~= jobName or Player.PlayerData.job.grade.level < 3 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Only the Boss can fire employees.' })
        return
    end

    local TargetPlayer = RSGCore.Functions.GetPlayerByCitizenId(targetCitizenId)
    
    if TargetPlayer then
        -- Online
        if TargetPlayer.PlayerData.job.grade.level >= Player.PlayerData.job.grade.level then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Cannot fire someone of equal/higher rank.' })
            return
        end

        TargetPlayer.Functions.SetJob('unemployed', 0)
        TargetPlayer.Functions.Save()
        TriggerClientEvent('ox_lib:notify', TargetPlayer.PlayerData.source, { type = 'error', description = 'You have been fired.' })
    else
        -- Offline
        MySQL.update.await('UPDATE players SET job = ?, job_grade = ? WHERE citizenid = ? AND job = ?',
            { 'unemployed', 0, targetCitizenId, jobName })
    end

    -- Remove from Employee Table (Optional: keep for history? For now, we keep them but maybe mark inactive? 
    -- Logic in saloon keeps them. We will just leave them in table for stats history.)
    
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Employee fired.' })
end)

-- ============================================================================
-- PROMOTE / DEMOTE PLAYER
-- ============================================================================
RegisterNetEvent('rsg-wagonmaker:server:updateGrade', function(targetCitizenId, jobName, newGrade)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Permission: Boss Only
    if Player.PlayerData.job.name ~= jobName or Player.PlayerData.job.grade.level < 3 then
        return
    end
    
    -- Prevent promoting to Boss (optional check)
    if newGrade >= 3 then
         TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Cannot promote to Boss rank.' })
         return
    end

    local TargetPlayer = RSGCore.Functions.GetPlayerByCitizenId(targetCitizenId)
    if TargetPlayer then
        TargetPlayer.Functions.SetJob(jobName, newGrade)
        TargetPlayer.Functions.Save()
        TriggerClientEvent('ox_lib:notify', TargetPlayer.PlayerData.source, { type = 'success', description = 'Your grade was updated to: ' .. GetGradeLabel(newGrade) })
    else
        MySQL.update.await('UPDATE players SET job_grade = ? WHERE citizenid = ? AND job = ?', { newGrade, targetCitizenId, jobName })
    end

    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Employee grade updated.' })
end)

-- ============================================================================
-- GET EMPLOYEES
-- ============================================================================
RSGCore.Functions.CreateCallback('rsg-wagonmaker:server:getEmployees', function(source, cb, jobName)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then cb({}) return end

    if Player.PlayerData.job.name ~= jobName then cb({}) return end

    -- Fetch employees from `players` table based on job
    local query = 'SELECT citizenid, charinfo, job FROM players WHERE job = ?'
    -- Note: RSGCore stores job as a JSON string usually if utilizing older methods, but standard is `job` column name string. 
    -- Wait, `rsg-core` usually stores job details.
    
    -- Using the logic from rsg-saloon:
    -- json_extract(job, '$.name') is safest if job is json, but standard QBCore/RSG uses `job` column as varchar usually?
    -- Actually rsg-saloon used: `WHERE job LIKE ?` with pattern. Ensuring compatibility.
    
    local jobPattern = '%"name":"' .. jobName .. '"%'
    
    MySQL.query('SELECT citizenid, charinfo, job FROM players WHERE job LIKE ?', { jobPattern }, function(results)
        local employees = {}
        for _, row in ipairs(results) do
            local charinfo = json.decode(row.charinfo)
            local jobInfo = json.decode(row.job)
            
            -- exclude self if desired, or include all
            table.insert(employees, {
                citizenid = row.citizenid,
                name = charinfo.firstname .. ' ' .. charinfo.lastname,
                grade = jobInfo.grade.level,
                gradeLabel = jobInfo.grade.name
            })
        end
        cb(employees)
    end)
end)

-- ============================================================================
-- GET NEARBY PLAYERS
-- ============================================================================
RSGCore.Functions.CreateCallback('rsg-wagonmaker:server:getNearbyPlayers', function(source, cb)
    local players = {}
    local pCoords = GetEntityCoords(GetPlayerPed(source))
    
    for _, playerId in ipairs(GetPlayers()) do
        local targetPed = GetPlayerPed(playerId)
        local tCoords = GetEntityCoords(targetPed)
        if #(pCoords - tCoords) < 10.0 and tonumber(playerId) ~= source then
            local TargetPlayer = RSGCore.Functions.GetPlayer(playerId)
            if TargetPlayer then
                table.insert(players, {
                    source = playerId,
                    name = TargetPlayer.PlayerData.charinfo.firstname .. ' ' .. TargetPlayer.PlayerData.charinfo.lastname
                })
            end
        end
    end
    cb(players)
end)
