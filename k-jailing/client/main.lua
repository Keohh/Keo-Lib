local jailTime = 0
local isJailed = false
local jailCoords = vector3(1757.3052, 2476.6499, 49.2375)

RegisterNetEvent('k-jailing:client:JailPlayer')
AddEventHandler('k-jailing:client:JailPlayer', function(time)
    jailTime = tonumber(time)
    isJailed = true
    -- Clear weapons
    RemoveAllPedWeapons(PlayerPedId(), true)
    -- Teleport to jail
    SetEntityCoords(PlayerPedId(), jailCoords.x, jailCoords.y, jailCoords.z, false, false, false, false)
    -- Start jail timer
    Citizen.CreateThread(function()
        while jailTime > 0 and isJailed do
            Citizen.Wait(1000)
            jailTime = jailTime - 1
            -- Prevent escape
            local playerCoords = GetEntityCoords(PlayerPedId())
            if #(playerCoords - jailCoords) > 10.0 then
                SetEntityCoords(PlayerPedId(), jailCoords.x, jailCoords.y, jailCoords.z, false, false, false, false)
            end
        end
        if isJailed then
            TriggerServerEvent('k-jailing:server:UnjailPlayer')
        end
        isJailed = false
    end)
end)

RegisterNetEvent('k-jailing:client:UnjailPlayer')
AddEventHandler('k-jailing:client:UnjailPlayer', function()
    isJailed = false
    jailTime = 0
    -- Optionally teleport out of jail here
    -- SetEntityCoords(PlayerPedId(), 425.1, -979.5, 30.7, false, false, false, false) -- Example outside MRPD
end)

RegisterCommand('jailtime', function()
    if isJailed then
        TriggerEvent('chat:addMessage', { args = { '^2JAIL', 'Time remaining: ' .. jailTime .. ' seconds.' } })
    else
        TriggerEvent('chat:addMessage', { args = { '^2JAIL', 'You are not jailed.' } })
    end
end)
