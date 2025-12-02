local lastLoadoutType = nil

RegisterNetEvent('setLastLoadout')
AddEventHandler('setLastLoadout', function(loadoutType)
    lastLoadoutType = loadoutType
end)

RegisterNetEvent('reloadLastLoadout')
AddEventHandler('reloadLastLoadout', function()
    if not lastLoadoutType or not Config.Loadouts[lastLoadoutType] then
        TriggerEvent('chat:addMessage', { args = { '^1SYSTEM', 'No previous loadout found!' } })
        return
    end
    
    for weapon, data in pairs(Config.Loadouts[lastLoadoutType]) do
        local ped = PlayerPedId()
        GiveWeaponToPed(ped, GetHashKey(weapon), data.ammo, false, true)
        for _, component in ipairs(data.components) do
            GiveWeaponComponentToPed(ped, GetHashKey(weapon), GetHashKey(component))
        end
    end
    
    TriggerEvent('chat:addMessage', { args = { '^2SYSTEM', 'Loadout reloaded: ' .. lastLoadoutType } })
end)