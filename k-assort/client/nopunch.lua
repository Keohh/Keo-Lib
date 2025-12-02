
-- Completely disable unarmed melee (punching)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        
        -- Prevent punch if player is unarmed
        if not IsPedArmed(playerPed, 7) then
            DisableControlAction(0, 140, true) -- R melee attack
        end
    end
end)

-- Prevent accidental punching when pressing spacebar
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        SetPedCanPlayGestureAnims(PlayerPedId(), false)
    end
end)
