RegisterCommand('loadout', function(source, args, rawCommand)
    if not exports['scully_perms']:hasPermission(source, 'leo') then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1SYSTEM', 'You do not have permission to use this command!' } })
        return
    end
    
    local loadoutType = args[1]
    if not loadoutType or not Config.Loadouts[loadoutType] then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1SYSTEM', 'Invalid loadout type!' } })
        return
    end
    
    for weapon, data in pairs(Config.Loadouts[loadoutType]) do
        local ped = GetPlayerPed(source)
        GiveWeaponToPed(ped, GetHashKey(weapon), data.ammo, false, true)
        for _, component in ipairs(data.components) do
            GiveWeaponComponentToPed(ped, GetHashKey(weapon), GetHashKey(component))
        end
    end
    
    TriggerClientEvent('chat:addMessage', source, { args = { '^2SYSTEM', 'Loadout applied: ' .. loadoutType } })
    
    -- Store last loadout type
    TriggerClientEvent('setLastLoadout', source, loadoutType)
end, false)

RegisterCommand('reloadloadout', function(source, args, rawCommand)
    if not exports['scully_perms']:hasPermission(source, 'leo') then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1SYSTEM', 'You do not have permission to use this command!' } })
        return
    end
    
    TriggerClientEvent('reloadLastLoadout', source)
end, false)