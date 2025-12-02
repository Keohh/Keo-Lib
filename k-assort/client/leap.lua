local _tackleDuration = 5500 -- In milliseconds
local _tackledDuration = 8500 -- In milliseconds (longer for the tackled player)

function GetTouchedPlayers()
    local players = {}

    local ped = PlayerPedId()

    for _, playerId in ipairs(GetActivePlayers()) do
        if IsEntityTouchingEntity(ped, GetPlayerPed(playerId)) then table.insert(players, playerId) end
    end

    return players
end

function Tackle()
    local ped = PlayerPedId()

    if IsPedOnFoot(ped) then
        if IsPedJumping(ped) then
            local forwardVector = GetEntityForwardVector(ped)

            SetPedToRagdollWithFall(ped, _tackleDuration, 6000, 0, forwardVector, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)

            Citizen.CreateThread(
                function()
                    local tackled = {}

                    while IsPedRagdoll(ped) do
                        local justTackledServierIds = {}

                        for _, playerId in ipairs(GetTouchedPlayers()) do
                            if not tackled[playerId] then
                                tackled[playerId] = true
                                table.insert(justTackledServierIds, GetPlayerServerId(playerId))
                            end
                        end

                        if #justTackledServierIds > 0 then TriggerServerEvent('Tackle:Server:TacklePlayer', justTackledServierIds, forwardVector) end
                        Wait(0)
                    end
                end)
        end
    end
end

-- Command --
RegisterCommand('+Tackle', Tackle, false)
RegisterCommand('-Tackle', function() end, false)
RegisterKeyMapping('+Tackle', 'Tackle another player', 'keyboard', 'E')

-- Event --
RegisterNetEvent('Tackle:Client:TacklePlayer')
AddEventHandler(
    'Tackle:Client:TacklePlayer', function(forwardVector)
        SetPedToRagdollWithFall(PlayerPedId(), _tackledDuration, _tackledDuration, 0, forwardVector, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
    end)
