-- Vehicle Weapons Disabler
-- Disables vehicle weapons unless it's a hose (fire truck)

local vehicleWeaponsDisabled = true

-- List of fire truck models that should keep their hose functionality
local fireTruckModels = {
    `firetruk`,     -- Standard fire truck
    `firetruk2`,    -- Alternative fire truck
    `firetruk3`,    -- Another fire truck variant
    `firetruk4`,    -- Additional fire truck variant
    `firetruk5`,    -- Another fire truck variant
    `firetruk6`,    -- Additional fire truck variant
    `firetruk7`,    -- Another fire truck variant
    `firetruk8`,    -- Additional fire truck variant
    `firetruk9`,    -- Another fire truck variant
    `firetruk10`,   -- Additional fire truck variant
    `arroweng`,   -- Additional fire truck variant
}

-- Function to check if vehicle is a fire truck (hose vehicle)
local function isFireTruck(vehicle)
    if not vehicle or vehicle == 0 then
        return false
    end
    
    local vehicleModel = GetEntityModel(vehicle)
    
    for _, fireTruckModel in pairs(fireTruckModels) do
        if vehicleModel == fireTruckModel then
            return true
        end
    end
    
    return false
end

-- Function to disable vehicle weapons
local function disableVehicleWeapons(vehicle)
    if not vehicle or vehicle == 0 then
        return
    end
    
    -- Don't disable weapons for fire trucks (hose vehicles)
    if isFireTruck(vehicle) then
        return
    end
    
    -- Disable all vehicle weapons
    SetVehicleCanBeVisiblyDamaged(vehicle, false)
    SetVehicleEngineCanDegrade(vehicle, false)
    
    -- Disable specific weapon systems
    SetVehicleHasWeapons(vehicle, false)
    SetVehicleWeaponsDisabled(vehicle, true)
    
    -- Disable vehicle turrets and mounted weapons
    SetVehicleTurretLocked(vehicle, 0, true)
    SetVehicleTurretLocked(vehicle, 1, true)
    SetVehicleTurretLocked(vehicle, 2, true)
    SetVehicleTurretLocked(vehicle, 3, true)
    
    -- Disable vehicle bombs and explosives
    SetVehicleBombOn(vehicle, false)
    SetVehicleExplodesOnHighExplosionDamage(vehicle, false)
    
    -- Disable vehicle rockets and missiles
    SetVehicleRocketBoostActive(vehicle, false)
    SetVehicleRocketBoostRefillTime(vehicle, 0.0)
    
    -- Disable vehicle mounted weapons
    SetVehicleWeaponCapacity(vehicle, 0, 0)
    SetVehicleWeaponCapacity(vehicle, 1, 0)
    SetVehicleWeaponCapacity(vehicle, 2, 0)
    SetVehicleWeaponCapacity(vehicle, 3, 0)
end

-- Function to enable vehicle weapons (for fire trucks)
local function enableVehicleWeapons(vehicle)
    if not vehicle or vehicle == 0 then
        return
    end
    
    -- Only enable weapons for fire trucks
    if not isFireTruck(vehicle) then
        return
    end
    
    -- Enable hose functionality for fire trucks
    SetVehicleHasWeapons(vehicle, true)
    SetVehicleWeaponsDisabled(vehicle, false)
    
    -- Enable turrets for hose operation
    SetVehicleTurretLocked(vehicle, 0, false)
    SetVehicleTurretLocked(vehicle, 1, false)
    
    -- Set appropriate weapon capacity for hose
    SetVehicleWeaponCapacity(vehicle, 0, 1000) -- Unlimited water/hose capacity
end

-- Main thread to continuously monitor and disable vehicle weapons
CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        
        if IsPedInAnyVehicle(playerPed, false) then
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            
            if vehicle and vehicle ~= 0 then
                if isFireTruck(vehicle) then
                    -- Enable weapons for fire trucks
                    enableVehicleWeapons(vehicle)
                else
                    -- Disable weapons for all other vehicles
                    disableVehicleWeapons(vehicle)
                end
            end
        end
        
        Wait(100) -- Check every 100ms
    end
end)

-- Event handler for when player enters a vehicle
AddEventHandler('gameEventTriggered', function(name, args)
    if name == "CEventNetworkPlayerEnteredVehicle" then
        local playerPed = args[1]
        local vehicle = args[2]
        
        if playerPed == PlayerPedId() and vehicle and vehicle ~= 0 then
            if isFireTruck(vehicle) then
                -- Enable weapons for fire trucks
                enableVehicleWeapons(vehicle)
            else
                -- Disable weapons for all other vehicles
                disableVehicleWeapons(vehicle)
            end
        end
    end
end)

-- Export function to manually disable weapons on a specific vehicle
exports('disableVehicleWeapons', function(vehicle)
    disableVehicleWeapons(vehicle)
end)

-- Export function to check if vehicle is a fire truck
exports('isFireTruck', function(vehicle)
    return isFireTruck(vehicle)
end)

-- Export function to manually enable weapons on a specific vehicle
exports('enableVehicleWeapons', function(vehicle)
    enableVehicleWeapons(vehicle)
end)