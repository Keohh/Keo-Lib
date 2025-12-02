local sounds = {
    --"AI_OFFICER_REQUEST_BACKUP",
    "ATTENTION_THIS_IS_DISPATCH_HIGH",
    "BLURRY_CHATTER",
    "BUFFALO_CLEAR",
    "COMMUNICATION_CHATTER",
    "COMPLAINANT_GONE",
    "DISPATCH_FEDS_ASSUMING_COMMAND",
    "DISPATCH_SUSPECT_LOCATED_ENGAGE",
    "GARBLED",
    "LAST_COM",
    "OK_TRANS",
    "REACH_OUT",
    "RESPOND_CODE_1",
    "SHORT_TRANSMISSION_01",
    "SHORT_TRANSMISSION_02",
    "SHORT_TRANSMISSION_03",
    "SUSPECT_CLEAN",
    "UNIT_RESPOND_CALL_01",
    "UNIT_RESPOND_CALL_02",
    "UNIT_RESPOND_CALL_03",
    "UNIT_RESPOND_CALL_04"
}

local minDelay = 900  -- minimum 30 seconds
local maxDelay = 11000  -- maximum 90 seconds

local function isInPoliceVehicle()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        local vehicle = GetVehiclePedIsIn(ped, false)
        return GetVehicleClass(vehicle) == 18
    end
    return false
end

local function playPoliceRadioChatter()
    Citizen.CreateThread(function()
        while true do
            local delay = math.random(minDelay, maxDelay)
            Citizen.Wait(delay)

            if isInPoliceVehicle() then
                --local coords = GetEntityCoords(PlayerPedId())
                local randomSound = sounds[math.random(1, #sounds)]
                TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 1.0, randomSound, 0.05)
                print("[Radio Chatter]:", randomSound, "is playing")
            end
        end
    end)
end

local function getUniqueRandomSound()
    if #sounds == 1 then return sounds[1] end

    local sound
    repeat
        sound = sounds[math.random(#sounds)]
    until sound ~= lastSound

    lastSound = sound
    return sound
end


local function WaitAndPlaySound()
    Citizen.CreateThread(function()
        while true do
            local waitTime = math.random(minDelay, maxDelay)
            Citizen.Wait(waitTime)

            if isInPoliceVehicle() then
                local coords = GetEntityCoords(PlayerPedId())
                local sound = sounds[math.random(#sounds)]
                TriggerServerEvent('radiochatter:playSoundInDistance', coords, sound, soundRadius)
            end
        end
    end)
end

AddEventHandler('onClientResourceStart', function(resName)
    if resName == GetCurrentResourceName() then
        playPoliceRadioChatter()
    end
end)

RegisterCommand("playsound", function()
    playPoliceRadioChatter()
end)