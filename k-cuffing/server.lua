-- Server-side cuffing logic for k-cuffing

RegisterNetEvent('k-cuffing:setCuffState')
AddEventHandler('k-cuffing:setCuffState', function(targetServerId, officerServerId, newState)
    TriggerClientEvent('k-cuffing:setCuffState', targetServerId, targetServerId, officerServerId, newState)
end) 