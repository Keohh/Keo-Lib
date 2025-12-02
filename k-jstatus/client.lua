local statusData = {
    fireems = false,
    police = false,
    tow = false
}

-- Emoji mapping
local statusEmojis = {
    fireems = "",
    police = "",
    tow = ""
}

-- DrawText2D helper with pixel-based positioning
function DrawText2D(text, px, py, scale, alignRight)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextScale(scale, scale)
    SetTextColour(255, 255, 255, 255)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    local resX, resY = GetActiveScreenResolution()
    local x = px / resX
    local y = py / resY
    if alignRight then
        SetTextJustification(2)
        SetTextWrap(0.0, x)
        EndTextCommandDisplayText(x, y)
    else
        EndTextCommandDisplayText(x, y)
    end
end

-- Build status string with emojis and Online/Offline
local function getStatusLines()
    local emojis = string.format("%s  %s  %s", statusEmojis.fireems, statusEmojis.police, statusEmojis.tow)
    local fire = statusData.fireems and "~g~Online~s~" or "~r~Offline~s~"
    local police = statusData.police and "~g~Online~s~" or "~r~Offline~s~"
    local tow = statusData.tow and "~g~Online~s~" or "~r~Offline~s~"
    local text = string.format("|  Fire: %s  |  Law: %s  |  Tow: %s  |", fire, police, tow)
    return emojis, text
end

-- Draw status on screen (top right, scaling for resolution)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local emojis, text = getStatusLines()
        local resX, resY = GetActiveScreenResolution()
        -- Reference: 1920x1080 (1080p)
        -- Place at 60px from right, 40px from top for emojis, 65px for text
        local rightPad = 60
        local emojiY = 40
        local textY = 52
        -- Scale text based on height (base: 1080p)
        local baseScale = 0.8
        local baseTextScale = 0.24
        local scale = baseScale * (resY / 1080)
        local textScale = baseTextScale * (resY / 1080)
        DrawText2D(emojis, resX - rightPad, emojiY, scale, true)
        DrawText2D(text, resX - rightPad, textY, textScale, true)
    end
end)

-- Receive status from server
RegisterNetEvent('k-jstatus:client:receiveStatus')
AddEventHandler('k-jstatus:client:receiveStatus', function(data)
    statusData = data
end)

-- Request status on join
AddEventHandler('playerSpawned', function()
    TriggerServerEvent('k-jstatus:server:requestStatus')
end)

-- Toggle commands
RegisterCommand('togglefire', function()
    TriggerServerEvent('k-jstatus:server:toggleStatus', 'fireems')
end, false)

RegisterCommand('togglelaw', function()
    TriggerServerEvent('k-jstatus:server:toggleStatus', 'police')
end, false)

RegisterCommand('toggletow', function()
    TriggerServerEvent('k-jstatus:server:toggleStatus', 'tow')
end, false)

-- Update status after toggle
RegisterNetEvent('k-jstatus:client:updateStatus')
AddEventHandler('k-jstatus:client:updateStatus', function(data)
    statusData = data
end)
