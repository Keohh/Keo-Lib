RegisterCommand('vec3', function ()
    CopyVec3Coords()
end)

RegisterCommand('vec4', function ()
    CopyVec4Coords()
end)


function CopyVec3Coords()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local formattedCoords = string.format('%.4f %.4f %.4f', playerCoords.x, playerCoords.y, playerCoords.z)
    lib.setClipboard(formattedCoords)
    print('[Dev] vec3 Copied')
end

function CopyVec4Coords()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local heading = GetEntityHeading(PlayerPedId())
    local formattedCoords = string.format('%.4f %.4f %.4f %.4f', playerCoords.x, playerCoords.y, playerCoords.z, heading)
    lib.setClipboard(formattedCoords)
    print('[Dev] vec4 Copied')
end