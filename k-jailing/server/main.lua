local jailedPlayers = {}
local jailFile = 'jailedPlayers.json'

local function getLicenseId(src)
    local identifiers = GetPlayerIdentifiers(src)
    for _, id in ipairs(identifiers) do
        if string.sub(id, 1, string.len("license:")) == "license:" then
            return id
        end
    end
    return nil
end

local function saveJailData()
    local data = json.encode(jailedPlayers)
    SaveResourceFile(GetCurrentResourceName(), jailFile, data, -1)
end

local function loadJailData()
    local data = LoadResourceFile(GetCurrentResourceName(), jailFile)
    if data then
        local decoded = json.decode(data)
        if decoded then
            jailedPlayers = decoded
        end
    end
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        loadJailData()
        -- Add chat suggestions for commands
        for _, playerId in ipairs(GetPlayers()) do
            TriggerClientEvent('chat:addSuggestion', playerId, '/jail', 'Jail a player', {
                { name = 'id', help = 'Player ID to jail' },
                { name = 'seconds', help = 'Jail time in seconds' }
            })
            TriggerClientEvent('chat:addSuggestion', playerId, '/unjail', 'Unjail a player', {
                { name = 'id', help = 'Player ID to unjail' }
            })
            TriggerClientEvent('chat:addSuggestion', playerId, '/jailtime', 'Check your remaining jail time')
        end
    end
end)

RegisterCommand('jail', function(source, args, rawCommand)
    if not IsPlayerAceAllowed(source, 'leo') then
        TriggerClientEvent('notify', source, 'You do not have permission to use this command.')
        return
    end
    -- Usage: /jail [id] [seconds]
    local targetId = tonumber(args[1])
    local jailTime = tonumber(args[2])
    if not targetId or not jailTime then
        TriggerClientEvent('notify', source, 'Usage: /jail [id] [seconds]')
        return
    end
    local license = getLicenseId(targetId)
    if not license then
        TriggerClientEvent('notify', source, 'Could not find license for target.')
        return
    end
    -- Only start mugshot, don't jail yet
    TriggerClientEvent('cqc-mugshot:client:trigger', targetId)
    -- Store jail time for later, but don't send to jail yet
    jailedPlayers[license] = jailTime
    saveJailData()
end)

RegisterCommand('unjail', function(source, args, rawCommand)
    if not IsPlayerAceAllowed(source, 'leo') then
        TriggerClientEvent('notify', source, 'You do not have permission to use this command.')
        return
    end
    -- Usage: /unjail [id]
    local targetId = tonumber(args[1])
    if not targetId then
        TriggerClientEvent('notify', source, 'Usage: /unjail [id]')
        return
    end
    local license = getLicenseId(targetId)
    if not license or not jailedPlayers[license] then
        TriggerClientEvent('notify', source, 'Target is not jailed.')
        return
    end
    jailedPlayers[license] = nil
    saveJailData()
    TriggerClientEvent('k-jailing:client:UnjailPlayer', targetId)
    TriggerClientEvent('notify', source, 'Player unjailed.')
end)

-- Listen for mugshot completion from client
RegisterNetEvent('cqc-mugshot:server:mugshotComplete')
AddEventHandler('cqc-mugshot:server:mugshotComplete', function()
    local src = source
    local license = getLicenseId(src)
    local jailTime = jailedPlayers[license]
    if jailTime and jailTime > 0 then
        TriggerClientEvent('k-jailing:client:JailPlayer', src, jailTime)
    end
end)

RegisterCommand('jailtime', function(source)
    if not IsPlayerAceAllowed(source, 'leo') then
        TriggerClientEvent('notify', source, 'You do not have permission to use this command.')
        return
    end
    local license = getLicenseId(source)
    local jailTime = license and jailedPlayers[license] or nil
    if jailTime and jailTime > 0 then
        TriggerClientEvent('notify', source, 'Time remaining: ' .. jailTime .. ' seconds.')
    else
        TriggerClientEvent('notify', source, 'You are not jailed.')
    end
end)

RegisterNetEvent('k-jailing:server:UnjailPlayer')
AddEventHandler('k-jailing:server:UnjailPlayer', function()
    local src = source
    local license = getLicenseId(src)
    if license then
        jailedPlayers[license] = nil
        saveJailData()
    end
    TriggerClientEvent('k-jailing:client:UnjailPlayer', src)
end)

AddEventHandler('playerDropped', function(reason)
    saveJailData()
end)

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    loadJailData()
    local src = source
    local license = getLicenseId(src)
    if license and jailedPlayers[license] and jailedPlayers[license] > 0 then
        TriggerClientEvent('k-jailing:client:JailPlayer', src, jailedPlayers[license])
    end
end)

-- Jail time decrement loop
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        for license, time in pairs(jailedPlayers) do
            if time > 0 then
                jailedPlayers[license] = time - 1
                if jailedPlayers[license] <= 0 then
                    -- Find all players with this license and unjail them
                    for _, playerId in ipairs(GetPlayers()) do
                        if getLicenseId(playerId) == license then
                            TriggerClientEvent('k-jailing:client:UnjailPlayer', playerId)
                        end
                    end
                    jailedPlayers[license] = nil
                end
            end
        end
        saveJailData()
    end
end) 