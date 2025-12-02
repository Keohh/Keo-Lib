-- Server-side validation for /radioanim

RegisterNetEvent('k_wakanim:requestAnimChange')
AddEventHandler('k_wakanim:requestAnimChange', function(animType)
    local src = source
    -- Example validation: only allow if player is alive (you can expand this)
    -- In a real server, you might check player data, permissions, etc.
    -- For now, always approve
    TriggerClientEvent('k_wakanim:animChangeApproved', src, animType)
end) 