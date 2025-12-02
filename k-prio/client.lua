-- K-Prio Client

-- Configurable display position
local prioDisplayConfig = {
    x = 0.89, -- horizontal position (0.0 - 1.0), near right edge
    y = 0.03,  -- vertical position (0.0 - 1.0), near top of screen
}

local prioStatus = {
    status = "None", -- None, Cooldown, Active, Hold
    cooldown = 0,
    activePlayer = nil,
    holdReason = nil,
    queue = {},
}

-- DrawText2D helper with outline
function DrawText2D(text, x, y, scale, r, g, b, a, outline)
    SetTextFont(0)
    SetTextProportional(1)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    if outline then SetTextOutline() end
    DrawText(x, y)
end

-- Main display loop
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local status = prioStatus.status
        local prioLabel = "Priority:"
        local statusText = status
        local prioR, prioG, prioB = 180, 180, 180 -- gray for 'Prio:'
        local statusR, statusG, statusB = 255, 255, 255
        local nameText = nil
        local reasonText = nil
        local reasonR, reasonG, reasonB = 180, 180, 180 -- gray
        local mainScale = 0.32
        local noteScale = 0.24
        if status == "None" then
            statusR, statusG, statusB = 0, 200, 0 -- green
        elseif status == "Cooldown" then
            statusR, statusG, statusB = 255, 255, 0 -- yellow
            statusText = statusText .. " (" .. prioStatus.cooldown .. "s)"
        elseif status == "Active" then
            statusR, statusG, statusB = 200, 0, 0 -- red
            nameText = " ("  .. prioStatus.activePlayer .. ")" or " ("  .. "Unknown" .. ")"
        elseif status == "Hold" then
            statusR, statusG, statusB = 255, 140, 0 -- orange
            reasonText = prioStatus.holdReason or  "No reason" 
        end
        -- Draw 'Priority:' label
        DrawText2D(prioLabel, prioDisplayConfig.x, prioDisplayConfig.y, mainScale, prioR, prioG, prioB, 255, true)
        -- Draw status next to label
        local labelWidth = 0.045 -- adjust if needed for spacing
        DrawText2D(statusText, prioDisplayConfig.x + labelWidth, prioDisplayConfig.y, mainScale, statusR, statusG, statusB, 255, true)
        -- Draw name (gray) if Active
        if status == "Active" and nameText then
            DrawText2D(nameText, prioDisplayConfig.x + labelWidth, prioDisplayConfig.y + 0.03, noteScale, reasonR, reasonG, reasonB, 255, true)
        end
        -- Draw reason (gray, in parentheses) if Hold
        if status == "Hold" and reasonText then
            DrawText2D("(" .. reasonText .. ")", prioDisplayConfig.x + labelWidth, prioDisplayConfig.y + 0.03, noteScale, reasonR, reasonG, reasonB, 255, true)
        end
    end
end)

-- Sync event from server
RegisterNetEvent('kprio:syncStatus')
AddEventHandler('kprio:syncStatus', function(data)
    print("[K-Prio][CLIENT] Received prio status from server: " .. json.encode(data))
    prioStatus = data
end)

-- Function to request prio status from server
function RequestPrioStatus()
    print("[K-Prio][CLIENT] Requesting prio status from server...")
    TriggerServerEvent('kprio:requestStatus')
end

-- Request prio status on client resource start
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        RequestPrioStatus()
    end
end)

-- Request prio status on player spawn
AddEventHandler('playerSpawned', function()
    RequestPrioStatus()
end)

-- Request prio command
RegisterCommand('requestprio', function(source, args, rawCommand)
    local reason = table.concat(args, ' ')
    if reason == '' then
        TriggerEvent('chat:addMessage', {args = {"^1Usage: /requestprio [scene reason/idea]"}})
        return
    end
    TriggerServerEvent('kprio:requestPrio', reason)
end, false)

-- Add chat suggestion for /requestprio
TriggerEvent('chat:addSuggestion', '/requestprio', 'Request priority for a scene', {
    { name = 'scene reason/idea', help = 'Describe your scene or idea for prio' }
})

-- View prio queue command
RegisterCommand('prioqueue', function()
    TriggerServerEvent('kprio:getQueue')
end, false)

-- Add chat suggestion for /prioqueue
TriggerEvent('chat:addSuggestion', '/prioqueue', 'View the current prio queue')

-- Add chat suggestion for /approveprio (staff)
TriggerEvent('chat:addSuggestion', '/approveprio', 'Approve a prio request by ID (staff only)', {
    { name = 'prio id', help = 'ID of the prio request' }
})

-- Add chat suggestion for /rejectprio (staff)
TriggerEvent('chat:addSuggestion', '/rejectprio', 'Reject a prio request by ID (staff only)', {
    { name = 'prio id', help = 'ID of the prio request' }
})

-- Add chat suggestion for /holdprio (staff)
TriggerEvent('chat:addSuggestion', '/holdprio', 'Put prio on hold with a reason (staff only)', {
    { name = 'reason', help = 'Reason for holding prio' }
})

-- Add chat suggestion for /endprio (staff)
TriggerEvent('chat:addSuggestion', '/endprio', 'End the current prio and start cooldown (staff only)')

-- Receive prio queue
RegisterNetEvent('kprio:showQueue')
AddEventHandler('kprio:showQueue', function(queue)
    local msg = "^2Prio Queue:^7\n"
    for i, entry in ipairs(queue) do
        msg = msg .. i .. ". [ID: " .. (entry.id or '?') .. "] " .. entry.playerName .. " - " .. entry.reason .. "\n"
    end
    TriggerEvent('chat:addMessage', {args = {msg}})
end)