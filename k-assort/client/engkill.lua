-- Vehicle Flip Engine Kill Script
-- Disables the engine when a non-aircraft vehicle flips upside down.

-- List of vehicle classes considered "regular" (excluding aircraft and special vehicles)
local regularVehicleClasses = {
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 17, 18, 20
}

-- Function to check if a vehicle class is regular
local function isRegularVehicle(vehicle)
    local class = GetVehicleClass(vehicle)
    for _, vClass in ipairs(regularVehicleClasses) do
        if class == vClass then
            return true
        end
    end
    return false
end

-- Main thread
CreateThread(function()
    while true do
        Wait(500) -- Optimize performance by checking every 500ms

        local ped = PlayerPedId() -- Get the player's ped
        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            if isRegularVehicle(vehicle) then
                local roll, pitch, yaw = table.unpack(GetEntityRotation(vehicle, 2))
                
                -- Check if the vehicle is flipped upside down
                if math.abs(pitch) > 160 then
                    -- Set engine health to 0 (disable engine)
                    SetVehicleEngineHealth(vehicle, 0.0)
                end
            end
        end
    end
end)
