local isInVehicle = false

local function saveWheelPos()
    CreateThread(function()
        local angle = 0.0
        while isInVehicle do
            Wait(5)
            local player = PlayerPedId()
            local veh = GetVehiclePedIsUsing(player)
            local speed = GetEntitySpeed(veh)
            if veh ~= 0 and speed < 0.1 then
                local tangle = GetVehicleSteeringAngle(veh)
                if tangle > 10.0 or tangle < -10.0 then
                    angle = tangle
                end
                if not GetIsTaskActive(player, 151) then
                    SetVehicleSteeringAngle(veh, angle)
                end
            end
        end
    end)
end

lib.onCache('vehicle', function(vehicle)
    Wait(5)
    isInVehicle = vehicle
    if not vehicle then return end
    saveWheelPos()
end)