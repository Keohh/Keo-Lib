-- State to track if animation is playing
local isAnimPlaying = false
local currentAnimType = nil
local currentProp = nil

-- Animation dictionary and names for each type
local animationTypes = {
    chest = {dict = "bigdaddy_radio3", anim = "radio_anim3"},
    ls = {dict = "bigdaddy_radio2", anim = "radio_anim2"},
    rs = {dict = "radiotalk3@animation", anim = "radiotalk3_clip"},
    hand = {
        dict = "ultra@walkie_talkie", anim = "walkie_talkie",
        prop = {
            model = "prop_cs_walkie_talkie", -- default GTA V radio prop
            offset = vector3(0.13036481427844,0.037657181986105,0.031250610017889),
            rot = vector3(-89.321172548417,-9.4007600620038,-33.131308867272)
        }
    },
    -- 'incar' is not included in validAnimTypes and cannot be selected manually
    incar = {
        dict = "ultra@walkie_talkie", anim = "walkie_talkie",
        prop = {
            model = "prop_police_radio_handset",
            offset = vector3(0.140000,0.030000,0.030000),
            rot = vector3(-105.877000,-10.943200,-33.721200)
        }
    }
}

local validAnimTypes = {}
for k, _ in pairs(animationTypes) do
    if k ~= 'incar' then table.insert(validAnimTypes, k) end
end

-- On resource start, load last used animation type
Citizen.CreateThread(function()
    local lastAnim = GetResourceKvpString('k_wakanim_last_anim')
    if lastAnim and animationTypes[lastAnim] then
        currentAnimType = lastAnim
    else
        currentAnimType = 'chest' -- default if none saved
    end
end)

-- Save the current animation type to KVP
local function saveCurrentAnimType()
    if currentAnimType then
        SetResourceKvp('k_wakanim_last_anim', currentAnimType)
    end
end

-- Helper to delete the current prop
local function deleteCurrentProp()
    if currentProp and DoesEntityExist(currentProp) then
        DeleteEntity(currentProp)
        currentProp = nil
    end
end

-- Command to change animation type (now requests server validation)
RegisterCommand("radioanim", function(source, args, rawCommand)
    local animType = table.concat(args, " "):lower():gsub("%s", "_")
    if animType == 'incar' then
        TriggerEvent('chat:addMessage', {args = {"'incar' animation can only be used while in a vehicle."}})
        return
    end
    if animationTypes[animType] and animType ~= 'incar' then
        TriggerServerEvent('k_wakanim:requestAnimChange', animType)
    else
        TriggerEvent('chat:addMessage', {args = {"Invalid animation type. Valid types: " .. table.concat(validAnimTypes, ", ")}})
    end
end, false)

-- Listen for server approval
RegisterNetEvent('k_wakanim:animChangeApproved')
AddEventHandler('k_wakanim:animChangeApproved', function(animType)
    currentAnimType = animType
    saveCurrentAnimType()
    TriggerEvent('chat:addMessage', {args = {"Animation type set to: " .. animType}})
end)

-- Function to get the correct animation type (incar if in vehicle)
local function getActiveAnimType()
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        return 'incar'
    end
    return currentAnimType
end

-- Function to play the current animation and handle props
function playCurrentAnimation()
    local animType = getActiveAnimType()
    local anim = animationTypes[animType]
    if not anim then return end
    local playerPed = PlayerPedId()
    deleteCurrentProp()
    RequestAnimDict(anim.dict)
    while not HasAnimDictLoaded(anim.dict) do
        Wait(10)
    end
    Wait(250)
    -- Play animation first
    TaskPlayAnim(playerPed, anim.dict, anim.anim, 8.0, -8.0, -1, 49, 0, false, false, false)
    -- Then handle prop if needed
    if anim.prop then
        local model = GetHashKey(anim.prop.model)
        print('[K-Wakanim] Requesting model:', anim.prop.model, model)
        RequestModel(model)
        local timeout = 0
        while not HasModelLoaded(model) and timeout < 100 do Wait(10) timeout = timeout + 1 end
        if not HasModelLoaded(model) then
            print('[K-Wakanim] Failed to load model:', anim.prop.model)
            return
        end
        local boneIndex = 57005 -- right hand default
        if animType == 'hand' then boneIndex = 18905 end
        if animType == 'incar' then boneIndex = 18905 end-- left hand for hand anim
        local prop = CreateObject(model, 1.0, 1.0, 1.0, true, true, true)
        print('[K-Wakanim] Prop created:', prop)
        AttachEntityToEntity(prop, playerPed, GetPedBoneIndex(playerPed, boneIndex),
            anim.prop.offset.x, anim.prop.offset.y, anim.prop.offset.z,
            anim.prop.rot.x, anim.prop.rot.y, anim.prop.rot.z,
            true, true, false, true, 1, true)
        currentProp = prop
    end
end

-- Function to clear the current animation and prop
function clearCurrentAnimation()
    local playerPed = PlayerPedId()
    ClearPedTasks(playerPed)
    deleteCurrentProp()
end

-- Register a key mapping for the animation (default: F6)
RegisterKeyMapping('+playradioanim', 'Play selected radio animation', 'keyboard', 'F6')


-- Listen for key press/release using RegisterCommand
RegisterCommand('+playradioanim', function()
    local playerPed = PlayerPedId()
    if not isAnimPlaying and currentAnimType and not IsEntityDead(playerPed) and not IsPedFalling(playerPed) and not IsPlayerFreeAiming(PlayerId()) then
        isAnimPlaying = true
        playCurrentAnimation()
        -- Trigger PMA-Voice radiotalk so player can speak on radio
        ExecuteCommand('+radiotalk')
    end
end, false)

RegisterCommand('-playradioanim', function()
    if isAnimPlaying then
        isAnimPlaying = false
        clearCurrentAnimation()
        -- Release PMA-Voice radiotalk
        ExecuteCommand('-radiotalk')
    end
end, false)