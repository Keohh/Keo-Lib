-- K-Prio Server
local cooldownTimer = 0
local prioRequestId = 1
local prioDataFile = 'prio_data.json'

local prioStatus = {
    status = "None", -- None, Cooldown, Active, Hold
    cooldown = 0,
    activePlayer = nil,
    holdReason = nil,
    queue = {},
}

local function printDebug(msg)
    --print("[K-Prio][SERVER] " .. msg)
end

-- Helper to sync status to all clients
function SyncStatus()
    TriggerClientEvent('kprio:syncStatus', -1, prioStatus)
    printDebug("Synced prio status to all clients.")
end

-- Helper to sync status to one client
function SyncStatusTo(source)
    TriggerClientEvent('kprio:syncStatus', source, prioStatus)
    printDebug("Synced prio status to player " .. tostring(source))
end

-- Helper to save prio status to file
function SavePrioData()
    local data = json.encode(prioStatus)
    SaveResourceFile(GetCurrentResourceName(), prioDataFile, data, #data)
    printDebug("Saved prio data: " .. data)
end

-- Helper to load prio status from file
function LoadPrioData()
    local data = LoadResourceFile(GetCurrentResourceName(), prioDataFile)
    if data then
        local loaded = json.decode(data)
        if loaded then
            prioStatus = loaded
            printDebug("Loaded prio data: " .. data)
        else
            printDebug("Failed to decode prio data, using default.")
        end
    else
        printDebug("No prio data file found, using default.")
    end
end

-- Load prio data on resource start
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        LoadPrioData()
    end
end)

-- Also load prio data immediately on script load
LoadPrioData()

-- Save after any change
local function PrioChanged()
    SyncStatus()
    SavePrioData()
end

-- On player join, sync status
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    SyncStatusTo(src)
end)

-- Prio request
RegisterNetEvent('kprio:requestPrio')
AddEventHandler('kprio:requestPrio', function(reason)
    local src = source
    local name = GetPlayerName(src)
    local entry = {id = prioRequestId, playerId = src, playerName = name, reason = reason}
    table.insert(prioStatus.queue, entry)
    prioRequestId = prioRequestId + 1
    -- Notify staff
    TriggerClientEvent('chat:addMessage', -1, {args = {"^3[PRIO]^7 New prio request from " .. name .. " (ID: " .. entry.id .. "): " .. reason}})
    PrioChanged()
end)

-- Approve prio (staff only)
RegisterCommand('approveprio', function(source, args, rawCommand)
    if not IsPlayerAceAllowed(source, 'kprio.staff') then
        TriggerClientEvent('chat:addMessage', source, {args = {"^1No permission."}})
        return
    end
    local id = tonumber(args[1])
    if not id then
        TriggerClientEvent('chat:addMessage', source, {args = {"^1Invalid prio ID."}})
        return
    end
    local idx, entry = nil, nil
    for i, v in ipairs(prioStatus.queue) do
        if v.id == id then idx = i; entry = v; break end
    end
    if not entry then
        TriggerClientEvent('chat:addMessage', source, {args = {"^1Prio request with that ID not found."}})
        return
    end
    table.remove(prioStatus.queue, idx)
    prioStatus.status = "Active"
    prioStatus.activePlayer = entry.playerName
    PrioChanged()
    TriggerClientEvent('chat:addMessage', -1, {args = {"^2[PRIO]^7 " .. entry.playerName .. " has been granted prio! (ID: " .. entry.id .. ")"}})
end, false)

-- Reject prio (staff only)
RegisterCommand('rejectprio', function(source, args, rawCommand)
    if not IsPlayerAceAllowed(source, 'kprio.staff') then
        TriggerClientEvent('chat:addMessage', source, {args = {"^1No permission."}})
        return
    end
    local id = tonumber(args[1])
    if not id then
        TriggerClientEvent('chat:addMessage', source, {args = {"^1Invalid prio ID."}})
        return
    end
    local idx, entry = nil, nil
    for i, v in ipairs(prioStatus.queue) do
        if v.id == id then idx = i; entry = v; break end
    end
    if not entry then
        TriggerClientEvent('chat:addMessage', source, {args = {"^1Prio request with that ID not found."}})
        return
    end
    table.remove(prioStatus.queue, idx)
    TriggerClientEvent('chat:addMessage', -1, {args = {"^3[PRIO]^7 " .. entry.playerName .. "'s prio request (ID: " .. entry.id .. ") was rejected."}})
    PrioChanged()
end, false)

-- Hold prio (staff only)
RegisterCommand('holdprio', function(source, args, rawCommand)
    if not IsPlayerAceAllowed(source, 'kprio.staff') then
        TriggerClientEvent('chat:addMessage', source, {args = {"^1No permission."}})
        return
    end
    local reason = table.concat(args, ' ')
    prioStatus.status = "Hold"
    prioStatus.holdReason = reason
    PrioChanged()
    TriggerClientEvent('chat:addMessage', -1, {args = {"^3[PRIO]^7 Prio is now on hold: " .. reason}})
end, false)

-- End prio (staff only)
RegisterCommand('endprio', function(source, args, rawCommand)
    if not IsPlayerAceAllowed(source, 'kprio.staff') then
        TriggerClientEvent('chat:addMessage', source, {args = {"^1No permission."}})
        return
    end
    prioStatus.status = "Cooldown"
    prioStatus.cooldown = 300 -- 5 min cooldown
    prioStatus.activePlayer = nil
    prioStatus.holdReason = nil
    PrioChanged()
    TriggerClientEvent('chat:addMessage', -1, {args = {"^3[PRIO]^7 Prio ended. Cooldown started."}})
    cooldownTimer = prioStatus.cooldown
    Citizen.CreateThread(function()
        while cooldownTimer > 0 do
            Citizen.Wait(1000)
            cooldownTimer = cooldownTimer - 1
            prioStatus.cooldown = cooldownTimer
            PrioChanged()
        end
        prioStatus.status = "None"
        prioStatus.cooldown = 0
        PrioChanged()
        TriggerClientEvent('chat:addMessage', -1, {args = {"^2[PRIO]^7 Prio is now available!"}})
    end)
end, false)

-- Show prio queue
RegisterNetEvent('kprio:getQueue')
AddEventHandler('kprio:getQueue', function()
    local src = source
    TriggerClientEvent('kprio:showQueue', src, prioStatus.queue)
end)

-- Handle client request for prio status
RegisterNetEvent('kprio:requestStatus')
AddEventHandler('kprio:requestStatus', function()
    local src = source
    SyncStatusTo(src)
    printDebug('Handled prio status request from player ' .. tostring(src))
end) 