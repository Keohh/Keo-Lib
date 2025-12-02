local lastVehicle = nil

-- Utility function to send chat messages
local function sendNotification(msg, type)
    lib.notify({
        title = 'Vehicle System',
        description = msg,
        type = msgType -- 'inform', 'success', 'error', 'warning'
    })
end

-- Function to play keyfob animation using exports
local function playKeyfobAnimation()
    local playerPed = PlayerPedId()
    local animDict = "anim@heists@keycard@"
    local animName = "exit"
    
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(100)
    end
    
    TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, -1, 49, 0, false, false, false)
    
    -- Stop the animation after a short delay
    Wait(1000)
    ClearPedTasks(playerPed)
end

-- Function to lock/unlock the last vehicle
local function toggleLockVehicle()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    if lastVehicle and DoesEntityExist(lastVehicle) then
        local vehicleCoords = GetEntityCoords(lastVehicle)
        local distance = #(playerCoords - vehicleCoords)
        
        if distance <= 10.0 then -- Range check
            local lockStatus = GetVehicleDoorLockStatus(lastVehicle)
            
            if lockStatus == 1 or lockStatus == 0 then
                SetVehicleDoorsLocked(lastVehicle, 2)
                SetVehicleDoorsLockedForAllPlayers(lastVehicle, true)
                sendNotification("Vehicle locked.", 'inform')
                PlaySoundFrontend( -1, "Pin_Bad", "DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS", 1)
            else
                SetVehicleDoorsLocked(lastVehicle, 1)
                SetVehicleDoorsLockedForAllPlayers(lastVehicle, false)
                sendNotification("Vehicle unlocked.", 'inform')
                PlaySoundFrontend( -1, "Pin_Good", "DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS", 1)
            end

            -- Play the lock/unlock sound and animation
            playKeyfobAnimation()
        else
            sendNotification("You are too far from the vehicle to lock/unlock it.", 'inform')
        end
    else
        sendNotification("No vehicle to lock/unlock.", 'error')
    end
end

-- Function to reset lock on the nearest vehicle
local function resetNearestVehicleLock()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local nearestVehicle = GetClosestVehicle(playerCoords.x, playerCoords.y, playerCoords.z, 2.0, 0, 71) -- 71 is for vehicles

    if nearestVehicle and DoesEntityExist(nearestVehicle) then
        SetVehicleDoorsLocked(nearestVehicle, 1)
        SetVehicleDoorsLockedForAllPlayers(nearestVehicle, false)
        sendNotification("Reset Lock", 'inform')
    else
    end
end

-- Event handler to track last vehicle
CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        if IsPedInAnyVehicle(playerPed, false) then
            lastVehicle = GetVehiclePedIsIn(playerPed, false)
        end
        Wait(1000) -- Check every second
    end
end)

-- Register command to lock/unlock vehicle
RegisterCommand('lockVehicle', function()
    toggleLockVehicle()
end, false)

-- Register keybind for locking/unlocking vehicle
RegisterKeyMapping('lockVehicle', 'Lock/Unlock Last Vehicle', 'keyboard', 'L')

-- Register command to reset lock on the nearest vehicle
RegisterCommand('Masterkey', function()
    resetNearestVehicleLock()
end, false)

-- Function to toggle the vehicle engine
local function toggleEngine()
    local playerPed = PlayerPedId()

    if IsPedInAnyVehicle(playerPed, false) then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        if vehicle then
            local engineStatus = GetIsVehicleEngineRunning(vehicle)
            if engineStatus then
                SetVehicleEngineOn(vehicle, false, false, true)
                sendNotification("Engine Off", 'error')
            else
                SetVehicleEngineOn(vehicle, true, false, true)
                sendNotification("Engine On", 'success')

            end
        end
    end
end

-- Function to toggle a specific vehicle door
local function toggleVehicleDoor(doorIndex)
    local playerPed = PlayerPedId()
    local vehicle = nil

    if IsPedInAnyVehicle(playerPed, false) then
        -- Get the vehicle the player is currently in
        vehicle = GetVehiclePedIsIn(playerPed, false)
    else
        -- Find the nearest vehicle within 10 meters
        local playerCoords = GetEntityCoords(playerPed)
        vehicle = GetClosestVehicle(playerCoords.x, playerCoords.y, playerCoords.z, 2.0, 0, 71) -- 71 is for vehicles
    end

    if vehicle and DoesEntityExist(vehicle) then
        if IsVehicleDoorDamaged(vehicle, doorIndex) then
            sendMessage("This door is damaged and cannot be toggled.", {255, 255, 0})
            return
        end

        local doorAngle = GetVehicleDoorAngleRatio(vehicle, doorIndex)
        if doorAngle > 0 then
            SetVehicleDoorShut(vehicle, doorIndex, false)
            sendNotification("Door Closed", 'inform')
        else
            SetVehicleDoorOpen(vehicle, doorIndex, false, false)
            sendNotification("Door Opened", 'inform')
        end
    else
        sendNotification("Can't Find The Door", 'inform')
    end
end

-- Function to toggle the trunk
local function toggleTrunk()
    toggleVehicleDoor(5) -- Trunk is door index 5
end

-- Function to toggle the hood
local function toggleHood()
    toggleVehicleDoor(4) -- Hood is door index 4
end

-- Register command to toggle a specific door
RegisterCommand('toggleDoor', function(source, args)
    local doorIndex = tonumber(args[1])
    if doorIndex ~= nil and doorIndex >= 0 and doorIndex <= 3 then
        toggleVehicleDoor(doorIndex)
    else

    end
end, false)

-- Register command to toggle the trunk
RegisterCommand('trunk', function()
    toggleTrunk()
end, false)

-- Register command to toggle the hood
RegisterCommand('hood', function()
    toggleHood()
end, false)
-- Register command to toggle the engine
RegisterCommand('toggleEngine', function()
    toggleEngine()
end, false)

-- Register keybind for toggling the engine
RegisterKeyMapping('toggleEngine', 'Toggle Engine', 'keyboard', 'G')


-- Example usage in chat: /toggleDoor 0 (front left door), /toggleDoor 5 (trunk)

-- Disable "W" key from starting the vehicle engine
CreateThread(function()
    while true do
        local playerPed = PlayerPedId()

        if IsPedInAnyVehicle(playerPed, false) then
            local vehicle = GetVehiclePedIsIn(playerPed, false)

            if vehicle and not GetIsVehicleEngineRunning(vehicle) then
                DisableControlAction(0, 71, true) -- Disable "W" (Accelerate)
            end
        end

        Wait(0) -- Ensure smooth execution
    end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		local ped = GetPlayerPed(-1)
		
		if DoesEntityExist(ped) and IsPedInAnyVehicle(ped, false) and IsControlPressed(2, 75) and not IsEntityDead(ped) and not IsPauseMenuActive() then
			local engineWasRunning = GetIsVehicleEngineRunning(GetVehiclePedIsIn(ped, true))
			Citizen.Wait(1000)
			if DoesEntityExist(ped) and not IsPedInAnyVehicle(ped, false) and not IsEntityDead(ped) and not IsPauseMenuActive() then
				local veh = GetVehiclePedIsIn(ped, true)
				if (engineWasRunning) then
					SetVehicleEngineOn(veh, true, true, true)
				end
			end
		end
	end
end)


