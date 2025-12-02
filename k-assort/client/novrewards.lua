-- Vehicle Rewards Disabler
-- Disables native GTA V vehicle rewards and achievements

local vehicleRewardsDisabled = true

-- Disable vehicle rewards continuously
CreateThread(function()
    while true do
        -- Disable vehicle rewards every frame
        Citizen.InvokeNative(0xC142BE3BB9CE125F, PlayerId())
        
        -- Also block vehicle reward events
        if IsPedInAnyVehicle(PlayerPedId(), false) then
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            if vehicle and vehicle ~= 0 then
                -- Prevent vehicle reward triggers
                SetVehicleHasBeenOwnedByPlayer(vehicle, false)
                SetVehicleNeedsToBeHotwired(vehicle, false)
            end
        end
        
        Wait(0) -- Run every frame
    end
end)


