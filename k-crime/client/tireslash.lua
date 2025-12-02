local KNIFE_WEAPONS = {
    ["WEAPON_KNIFE"] = true,
    ["WEAPON_SWITCHBLADE"] = true,
    ["WEAPON_DAGGER"] = true,
    ["WEAPON_MACHETE"] = true,
    ["WEAPON_BOTTLE"] = true,
}

local SLASH_KEY = 38 -- E
local SLASH_RANGE = 1.2
local TEXT_DISPLAY_DIST = 10.0

-- Pre-load animation dictionaries
local ANIM_DICTS = {
    "move_crouch_proto",
    "melee@knife@streamed_core"
}

local ANIM_LOADED = {}

-- Load all animation dictionaries at startup
Citizen.CreateThread(function()
    for _, dict in ipairs(ANIM_DICTS) do
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Citizen.Wait(10)
        end
        ANIM_LOADED[dict] = true
    end
    print("[TireSlash] All animation dictionaries loaded successfully")
end)

function Draw3DText(x, y, z, text)
    if not x or not y or not z then return end
    
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if not onScreen then return end
    
    local px, py, pz = table.unpack(GetGameplayCamCoord())
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    DrawText(_x, _y)
    local factor = (string.len(text)) / 370
    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 0, 0, 0, 100)
end

function GetNearestVehicleWithTire()
    local playerPed = PlayerPedId()
    if not playerPed or playerPed == 0 then return nil end
    
    local pos = GetEntityCoords(playerPed)
    if not pos then return nil end
    
    local veh = GetClosestVehicle(pos.x, pos.y, pos.z, 5.0, 0, 70)
    if veh and veh ~= 0 then
        return veh
    end
    return nil
end

function GetNearestTire(veh)
    if not veh or veh == 0 then return nil, nil, math.huge end
    
    local playerPed = PlayerPedId()
    if not playerPed or playerPed == 0 then return nil, nil, math.huge end
    
    local playerPos = GetEntityCoords(playerPed)
    if not playerPos then return nil, nil, math.huge end
    
    local closestTire, closestBone, minDist = nil, nil, SLASH_RANGE
    local tireBones = {
        "wheel_lf", "wheel_rf", "wheel_lm1", "wheel_rm1", "wheel_lr", "wheel_rr"
    }
    
    for i, boneName in ipairs(tireBones) do
        local boneIndex = GetEntityBoneIndexByName(veh, boneName)
        if boneIndex and boneIndex ~= -1 then
            local bonePos = GetWorldPositionOfEntityBone(veh, boneIndex)
            if bonePos then
                local dist = #(playerPos - bonePos)
                if dist < minDist then
                    minDist = dist
                    closestTire = i - 1 -- tire index for SetVehicleTyreBurst
                    closestBone = bonePos
                end
            end
        end
    end
    return closestTire, closestBone, minDist
end

function IsPlayerHoldingKnife()
    local playerPed = PlayerPedId()
    if not playerPed or playerPed == 0 then return false end
    
    local weapon = GetSelectedPedWeapon(playerPed)
    for hash, _ in pairs(KNIFE_WEAPONS) do
        if weapon == GetHashKey(hash) then
            return true
        end
    end
    return false
end

function PlaySlashAnimation()
    local playerPed = PlayerPedId()
    if not playerPed or playerPed == 0 then return end
    
    -- Check if animations are loaded
    if not ANIM_LOADED["move_crouch_proto"] or not ANIM_LOADED["melee@knife@streamed_core"] then
        print("[TireSlash] Warning: Animation dictionaries not loaded yet")
        return
    end
    
    -- Crouch anim
    TaskPlayAnim(playerPed, "move_crouch_proto", "idle_intro", 8.0, -8.0, 1200, 1, 0, false, false, false)
    Citizen.Wait(600)
    
    -- Slash anim
    TaskPlayAnim(playerPed, "melee@knife@streamed_core", "ground_attack_on_spot", 8.0, -8.0, 1000, 1, 0, false, false, false)
    Citizen.Wait(700)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100) -- Reduced from 0 to improve performance
        
        if IsPlayerHoldingKnife() then
            local veh = GetNearestVehicleWithTire()
            if veh then
                local tireIndex, tirePos, dist = GetNearestTire(veh)
                if tireIndex and tirePos and dist < SLASH_RANGE then
                    -- Draw 3D text
                    if #(GetEntityCoords(PlayerPedId()) - tirePos) < TEXT_DISPLAY_DIST then
                        Draw3DText(tirePos.x, tirePos.y, tirePos.z + 0.2, "Press ~g~E~w~ to slash tire")
                    end
                    
                    -- Handle slash input
                    if IsControlJustPressed(0, SLASH_KEY) then
                        PlaySlashAnimation()
                        SetVehicleTyreCanBurst(veh, true)
                        SetVehicleTyreBurst(veh, tireIndex, false, 1000.0)
                    end
                end
            end
        else
            Citizen.Wait(500) -- Wait longer when not holding knife to save resources
        end
    end
end)