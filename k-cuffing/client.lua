local maxCuffs = 2
local cuffCount = maxCuffs
-- Debug mode
local debug = false -- Set to true to enable debug info

-- ACE Permissions
local useAcePerms = false -- Set to true to use ACE permissions, false to disable
local acePermission = 'leo' -- The ACE permission to check for

-- Notification function to replace lib.notify
function ShowNotification(title, message, type)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(message)
    DrawNotification(false, false)
end

-- Cuff state tracking (client-side, for demo; should sync with server in prod)
-- State 1 = Cuffed, State 2 = Uncuffed
local cuffState = 2 -- Default to uncuffed
local playerCuffStates = {} -- Track other players' states
local isCuffed = false -- Track if player is currently cuffed for animation loop



-- Find nearest player within a certain radius
function GetNearestPlayer(radius)
    local players = GetActivePlayers()
    local myPed = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)
    local nearestPlayer, nearestDist = nil, radius
    for _,player in ipairs(players) do
        local ped = GetPlayerPed(player)
        if ped ~= myPed then
            local pedCoords = GetEntityCoords(ped)
            local dist = #(myCoords - pedCoords)
            if dist < nearestDist then
                nearestPlayer = player
                nearestDist = dist
            end
        end
    end
    return nearestPlayer, nearestDist
end

-- Restrict controls if cuffed
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if cuffState == 1 then -- Cuffed
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 22, true) -- Jump
            DisableControlAction(0, 21, true) -- Sprint
            DisableControlAction(0, 23, true) -- Enter vehicle
            DisableControlAction(0, 44, true) -- Cover
            DisableControlAction(0, 37, true) -- Weapon wheel
            DisablePlayerFiring(PlayerPedId(), true)
        else
            Citizen.Wait(500)
        end
    end
end)

-- Continuous cuffed animation loop
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(250)
        if isCuffed and cuffState == 1 then
            local ped = PlayerPedId()
            if not IsEntityPlayingAnim(ped, 'mp_arresting', 'idle', 3) then
                PlayCuffedIdleAnim(ped)
            end
        end
    end
end)

-- Function to check if player has permission to use cuffing
function HasCuffPermission()
    if not useAcePerms then
        return true -- If ACE perms disabled, allow everyone
    end
    
    -- Check ACE permissions using scully_perms export
    local hasPermission = exports['scully_perms']:hasPermission(GetPlayerServerId(PlayerId()), acePermission)
    
    if debug then
        ShowNotification('Debug', ('Permission check - Has %s: %s'):format(acePermission, tostring(hasPermission)), 'inform')
    end
    
    return hasPermission
end

-- Function to handle cuffing
function HandleCuff()
    -- Check permissions first
    if not HasCuffPermission() then
        ShowNotification('Permission Denied', ('You do not have permission to use cuffing! Required: %s'):format(acePermission), 'error')
        return
    end
    
    local ped = PlayerPedId()
    local weapon = GetSelectedPedWeapon(ped)
    if weapon == GetHashKey("weapon_speedcuffs") then
        local nearestPlayer, dist = GetNearestPlayer(2.0)
        if nearestPlayer then
            local targetPlayerId = GetPlayerServerId(nearestPlayer)
            local currentState = GetPlayerCuffState(targetPlayerId)
            
            if currentState == 2 then -- Uncuffed, so cuff them
                if cuffCount > 0 then
                    -- Debug info
                    if debug then
                        ShowNotification('Debug', ('Cuffing - Target State = %s, Cuff Count = %s'):format(currentState, cuffCount), 'inform')
                    end
                    TriggerEvent('k-cuffing:playCuffAnim')
                    TriggerServerEvent('k-cuffing:setCuffState', targetPlayerId, GetPlayerServerId(PlayerId()), 1)
                else
                    ShowNotification('No Cuffs', 'You are out of cuffs! Use /restockcuffs at a police car.', 'error')
                end
            else
                ShowNotification('Already Cuffed', 'Player is already cuffed! Use ] to uncuff.', 'error')
            end
        else
            ShowNotification('No Target', 'No one nearby to cuff!', 'error')
        end
    else
        ShowNotification('Equipment Required', 'You need to have speedcuffs equipped!', 'error')
    end
end

-- Function to handle uncuffing
function HandleUncuff()
    -- Check permissions first
    if not HasCuffPermission() then
        ShowNotification('Permission Denied', ('You do not have permission to use cuffing! Required: %s'):format(acePermission), 'error')
        return
    end
    
    local ped = PlayerPedId()
    local weapon = GetSelectedPedWeapon(ped)
    if weapon == GetHashKey("weapon_speedcuffs") then
        local nearestPlayer, dist = GetNearestPlayer(2.0)
        if nearestPlayer then
            local targetPlayerId = GetPlayerServerId(nearestPlayer)
            local currentState = GetPlayerCuffState(targetPlayerId)
            
            if currentState == 1 then -- Cuffed, so uncuff them
                -- Debug info
                if debug then
                    ShowNotification('Debug', 'Uncuffing player', 'inform')
                end
                TriggerEvent('k-cuffing:playUncuffOfficerAnim')
                TriggerServerEvent('k-cuffing:setCuffState', targetPlayerId, GetPlayerServerId(PlayerId()), 2)
            else
                ShowNotification('Not Cuffed', 'Player is not cuffed! Use [ to cuff.', 'error')
            end
        else
            ShowNotification('No Target', 'No one nearby to uncuff!', 'error')
        end
    else
        ShowNotification('Equipment Required', 'You need to have speedcuffs equipped!', 'error')
    end
end

-- Register key mappings
RegisterKeyMapping('cuff_player', '[Police] Cuff Player', 'keyboard', '')
RegisterKeyMapping('uncuff_player', '[Police] Uncuff Player', 'keyboard', '')

-- Register commands for key mapping
RegisterCommand('cuff_player', HandleCuff, false)
RegisterCommand('uncuff_player', HandleUncuff, false)

-- Animation helpers
function PlayCuffAnim(ped)
    RequestAnimDict('mp_arresting')
    while not HasAnimDictLoaded('mp_arresting') do
        Citizen.Wait(10)
    end
    -- Play left shove animation
    TaskPlayAnim(ped, 'mp_arresting', 'arresting_cop_shove_left_short', 8.0, -8.0, 1000, 32, 0, false, false, false)
    Citizen.Wait(1000)
    -- Play right shove animation
    TaskPlayAnim(ped, 'mp_arresting', 'arresting_cop_shove_right_short', 8.0, -8.0, 1000, 32, 0, false, false, false)
end

function PlayCuffedIdleAnim(ped)
    RequestAnimDict('mp_arresting')
    while not HasAnimDictLoaded('mp_arresting') do
        Citizen.Wait(10)
    end
    TaskPlayAnim(ped, 'mp_arresting', 'idle', 8.0, -8.0, -1, 49, 0, false, false, false)
end

function PlayCuffedGetAnim(ped)
    RequestAnimDict('mp_arrest_paired')
    while not HasAnimDictLoaded('mp_arrest_paired') do
        Citizen.Wait(10)
    end
    TaskPlayAnim(ped, 'mp_arrest_paired', 'crook_p2_back_left', 8.0, -8.0, 2000, 32, 0, false, false, false)
end

function PlayUncuffAnim(ped)
    RequestAnimDict('mp_arresting')
    while not HasAnimDictLoaded('mp_arresting') do
        Citizen.Wait(10)
    end
    TaskPlayAnim(ped, 'mp_arresting', 'b_uncuff', 8.0, -8.0, 1500, 32, 0, false, false, false)
end

function PlayUncuffOfficerAnim(ped)
    RequestAnimDict('mp_arresting')
    while not HasAnimDictLoaded('mp_arresting') do
        Citizen.Wait(10)
    end
    TaskPlayAnim(ped, 'mp_arresting', 'a_uncuff', 8.0, -8.0, 1500, 32, 0, false, false, false)
end

function StopAnim(ped)
    ClearPedTasksImmediately(ped)
end



-- Function to set cuff state of a player
function SetPlayerCuffState(playerId, state)
    if playerId == GetPlayerServerId(PlayerId()) then
        cuffState = state
    else
        playerCuffStates[playerId] = state
    end
end

-- Function to detect if a player is actually cuffed
function IsPlayerActuallyCuffed(playerId)
    if playerId == GetPlayerServerId(PlayerId()) then
        -- For local player, check if we're in cuffed animation
        local ped = PlayerPedId()
        return IsEntityPlayingAnim(ped, 'mp_arresting', 'idle', 3)
    else
        -- For other players, check their animation state
        local playerPed = GetPlayerPed(GetPlayerFromServerId(playerId))
        if playerPed and DoesEntityExist(playerPed) then
            -- Check if they're playing the cuffed idle animation
            return IsEntityPlayingAnim(playerPed, 'mp_arresting', 'idle', 3)
        end
    end
    return false
end

-- Function to get current cuff state of a player (with actual detection)
function GetPlayerCuffState(playerId)
    if playerId == GetPlayerServerId(PlayerId()) then
        return cuffState
    else
        -- Check if player is actually cuffed by animation state
        if IsPlayerActuallyCuffed(playerId) then
            return 1 -- Cuffed
        else
            return 2 -- Uncuffed
        end
    end
end

-- Register /cuff command
RegisterCommand("cuff", function()
    -- Check permissions first
    if not HasCuffPermission() then
        ShowNotification('Permission Denied', ('You do not have permission to use cuffing! Required: %s'):format(acePermission), 'error')
        return
    end
    
    local ped = PlayerPedId()
    local weapon = GetSelectedPedWeapon(ped)
    if weapon ~= GetHashKey("weapon_speedcuffs") then
        ShowNotification('Equipment Required', 'You need to have speedcuffs equipped!', 'error')
        return
    end
    local nearestPlayer, dist = GetNearestPlayer(2.0)
    if nearestPlayer then
        local targetPlayerId = GetPlayerServerId(nearestPlayer)
        local currentState = GetPlayerCuffState(targetPlayerId)
        
        -- Debug info
        if debug then
            ShowNotification('Debug', ('Target State = %s, Cuff Count = %s'):format(currentState, cuffCount), 'inform')
        end
        
        if currentState == 2 then -- Uncuffed, so cuff them
            if cuffCount > 0 then
                TriggerEvent('k-cuffing:playCuffAnim')
                TriggerServerEvent('k-cuffing:setCuffState', targetPlayerId, GetPlayerServerId(PlayerId()), 1)
            else
                ShowNotification('No Cuffs', 'You are out of cuffs! Use /restockcuffs at a police car.', 'error')
            end
        else -- Cuffed, so uncuff them
            if debug then
                ShowNotification('Debug', 'Attempting to uncuff player', 'inform')
            end
            TriggerEvent('k-cuffing:playUncuffOfficerAnim')
            TriggerServerEvent('k-cuffing:setCuffState', targetPlayerId, GetPlayerServerId(PlayerId()), 2)
        end
    else
        ShowNotification('No Target', 'No one nearby to cuff!', 'error')
    end
end, false)

-- Cuff attempt tracking
local cuffAttempts = {}
local CUFF_ATTEMPT_RESET = 60 -- seconds

function getCuffAttempts(target)
    if not cuffAttempts[target] then
        cuffAttempts[target] = {count = 0, last = 0}
    end
    return cuffAttempts[target]
end

function resetCuffAttempts(target)
    cuffAttempts[target] = {count = 0, last = 0}
end

-- Cooldown thread to reset attempts
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(10000)
        local now = GetGameTimer() / 1000
        for target, data in pairs(cuffAttempts) do
            if data.count > 0 and (now - data.last) > CUFF_ATTEMPT_RESET then
                resetCuffAttempts(target)
            end
        end
    end
end)

-- Listen for cuff state change event
RegisterNetEvent('k-cuffing:setCuffState')
AddEventHandler('k-cuffing:setCuffState', function(targetPlayerId, officerId, newState)
    local ped = PlayerPedId()
    local playerServerId = GetPlayerServerId(PlayerId())
    local oldState = GetPlayerCuffState(targetPlayerId)
    
    -- Debug info
    if debug then
        ShowNotification('Debug', ('Event received - Target: %s, Officer: %s, Old State: %s, New State: %s'):format(targetPlayerId, officerId, oldState, newState), 'inform')
    end
    
    -- Update the state
    SetPlayerCuffState(targetPlayerId, newState)
    
    if targetPlayerId == playerServerId then -- This is the target player
        if newState == 1 then -- Being cuffed
            -- Surge override minigame to resist (one time, increasing difficulty)
            local attempts = getCuffAttempts(officerId)
            attempts.count = attempts.count + 1
            attempts.last = GetGameTimer() / 1000
            
            if attempts.count < 3 then
                -- Configure difficulty based on attempt number
                local circles = 1 -- 3, 4, 5 circles
                local time = 8 - (attempts.count - 3) -- 17, 14, 11 seconds
                
                -- Play cuffing animation and start minigame simultaneously
                StopAnim(ped)
                PlayCuffedGetAnim(ped)
                
                exports['ps-ui']:Circle(function(success)
                    if success then
                        isCuffed = false
                        StopAnim(ped)
                        ShowNotification('Resisted', 'You resisted the cuffs!', 'success')
                        TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 10.0, 'handcuff_break', 0.5, playerServerId)
                        SetPlayerCuffState(targetPlayerId, 2) -- Reset to uncuffed
                        return
                    else
                        -- If failed, continue with cuffing
                        isCuffed = true
                        PlayCuffedIdleAnim(ped)
                        ShowNotification('Cuffed', 'You have been cuffed!', 'error')
                        TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 10.0, 'handcuff_on', 0.5, playerServerId)
                        resetCuffAttempts(officerId)
                        -- Only decrement cuffCount if this is a new cuff (not an uncuff)
                        if oldState == 2 and cuffCount > 0 then
                            cuffCount = cuffCount - 1
                        end
                    end
                end, circles, time)
                return -- Exit early to prevent immediate cuffing
            end
            -- If 3rd attempt or more, cuff immediately without minigame
            isCuffed = true
            StopAnim(ped)
            PlayCuffedGetAnim(ped)
            Citizen.Wait(2000)
            PlayCuffedIdleAnim(ped)
            ShowNotification('Cuffed', 'You have been cuffed!', 'error')
            TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 10.0, 'handcuff_on', 0.5, playerServerId)
            resetCuffAttempts(officerId)
            -- Only decrement cuffCount if this is a new cuff (not an uncuff)
            if oldState == 2 and cuffCount > 0 then
                cuffCount = cuffCount - 1
            end
        else -- Being uncuffed
            isCuffed = false
            StopAnim(ped)
            PlayUncuffAnim(ped)
            Citizen.Wait(1500)
            StopAnim(ped)
            ShowNotification('Uncuffed', 'You have been uncuffed!', 'success')
            TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 10.0, 'handcuff_remove', 0.5, playerServerId)
        end
    end
end)

-- Play cuffing animation on the player who uses /cuff
AddEventHandler('k-cuffing:playCuffAnim', function()
    local ped = PlayerPedId()
    PlayCuffAnim(ped)
end)

-- Play uncuffing animation on the officer
AddEventHandler('k-cuffing:playUncuffOfficerAnim', function()
    local ped = PlayerPedId()
    PlayUncuffOfficerAnim(ped)
end)


function IsNearPoliceCar(radius)
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local vehicles = GetGamePool('CVehicle')
    for _,veh in ipairs(vehicles) do
        if DoesEntityExist(veh) and GetVehicleClass(veh) == 18 then
            local vehPos = GetEntityCoords(veh)
            if #(pos - vehPos) < radius then
                return true
            end
        end
    end
    return false
end

RegisterCommand("restockcuffs", function()
    if IsNearPoliceCar(5.0) then
        cuffCount = maxCuffs
        ShowNotification('Restocked', 'You have restocked your speedcuffs!', 'success')
    else
        ShowNotification('Too Far', 'You must be near a police car to restock cuffs!', 'error')
    end
end, false)

-- Debug command to check nearby player's cuff state
RegisterCommand("checkcuff", function()
    if not debug then
        ShowNotification('Debug Disabled', 'Debug mode is disabled. Set debug = true to use this command.', 'error')
        return
    end
    local nearestPlayer, dist = GetNearestPlayer(2.0)
    if nearestPlayer then
        local targetPlayerId = GetPlayerServerId(nearestPlayer)
        local detectedState = IsPlayerActuallyCuffed(targetPlayerId)
        local storedState = playerCuffStates[targetPlayerId] or "Unknown"
        ShowNotification('Debug Info', ('Player %s - Detected Cuffed: %s, Stored State: %s'):format(targetPlayerId, tostring(detectedState), tostring(storedState)), 'inform')
    else
        ShowNotification('No Target', 'No one nearby to check!', 'error')
    end
end, false)




