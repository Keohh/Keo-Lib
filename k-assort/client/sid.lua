-- Display state for ID display
local showIds = false
local displayStartTime = 0
local lastActivationTime = 0
local displayDuration = 8000 -- 20 seconds in milliseconds
local cooldownDuration = 15000 -- 25 seconds in milliseconds

-- Register key mapping for display
RegisterCommand('show_player_ids', function()
    local currentTime = GetGameTimer()
    
    -- Check if we're in cooldown
    if currentTime - lastActivationTime < cooldownDuration then
        return
    end
    
    -- Check if display is already active
    if showIds then
        return
    end
    
    -- Activate display
    showIds = true
    displayStartTime = currentTime
    lastActivationTime = currentTime
    
    -- Play sound when activating
    PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
end, false)

-- Register key binding (I key)
RegisterKeyMapping('show_player_ids', 'Show Player IDs', 'keyboard', 'I')

-- Main thread for displaying IDs
CreateThread(function()
    while true do
        Wait(0) -- Prevent crashing, loop every frame

        if showIds then -- Check if IDs should be displayed
            local currentTime = GetGameTimer()
            
            -- Check if display duration has expired
            if currentTime - displayStartTime >= displayDuration then
                showIds = false
            else
                local players = GetActivePlayers() -- Get all active players
                local playerPed = PlayerPedId() -- Get the local player ped
                local playerCoords = GetEntityCoords(playerPed) -- Get local player coords

                for _, playerId in ipairs(players) do
                    local targetPed = GetPlayerPed(playerId) -- Get target ped
                    local targetCoords = GetEntityCoords(targetPed) -- Get their coords
                    local distance = #(playerCoords - targetCoords) -- Calculate distance

                    if distance < 20.0 then -- Only display if close enough
                        local targetServerId = GetPlayerServerId(playerId) -- Get their server ID
                        local isTalking = NetworkIsPlayerTalking(playerId) -- Check if player is talking
                        local isLocalPlayer = (playerId == PlayerId()) -- Check if this is the local player

                        -- Display the ID above their head
                        DrawText3D(
                            targetCoords.x,
                            targetCoords.y,
                            targetCoords.z + 0.95,
                            tostring(targetServerId),
                            isLocalPlayer and { 0, 255, 0 } or (isTalking and { 128, 0, 128 } or { 255, 255, 255 }) -- Green for local player, purple if talking, white otherwise
                        )
                    end
                end
            end
        end
    end
end)

-- Function to draw 3D text with color
function DrawText3D(x, y, z, text, color)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())

    if onScreen then
        SetTextScale(0.8, 0.8) -- Smaller text size
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(color[1], color[2], color[3], 255) -- Use provided color
        SetTextOutline()
        SetTextEntry("STRING")
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end