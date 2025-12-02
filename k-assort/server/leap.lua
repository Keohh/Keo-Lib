RegisterServerEvent('Tackle:Server:TacklePlayer')
AddEventHandler('Tackle:Server:TacklePlayer', function(playerIds, forwardVector)
        assert(type(playerIds) == 'table')

        for _, playerId in ipairs(playerIds) do TriggerClientEvent('Tackle:Client:TacklePlayer', playerId, forwardVector) end
    end)
