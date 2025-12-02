local statusFile = 'status.json'
local resourceName = GetCurrentResourceName()
local statusData = {
    fireems = false,
    police = false,
    tow = false
}

-- Load status from file using FiveM native
local function loadStatus()
    local content = LoadResourceFile(resourceName, statusFile)
    if content then
        local ok, data = pcall(json.decode, content)
        if ok and data then
            statusData = data
        end
    end
end

-- Save status to file using FiveM native
local function saveStatus()
    SaveResourceFile(resourceName, statusFile, json.encode(statusData), -1)
end

-- On resource start, load status
AddEventHandler('onResourceStart', function(res)
    if resourceName ~= res then return end
    loadStatus()
end)

-- On resource stop, set all statuses to offline and save
AddEventHandler('onResourceStop', function(res)
    if resourceName ~= res then return end
    statusData = {
        fireems = false,
        police = false,
        tow = false
    }
    saveStatus()
end)

-- Send status to client on join
RegisterNetEvent('k-jstatus:server:requestStatus')
AddEventHandler('k-jstatus:server:requestStatus', function()
    TriggerClientEvent('k-jstatus:client:receiveStatus', source, statusData)
end)

-- Toggle status with ACE check
RegisterNetEvent('k-jstatus:server:toggleStatus')
AddEventHandler('k-jstatus:server:toggleStatus', function(statusType)
    local src = source
    local permMap = {
        fireems = 'status.fireems',
        police = 'status.police',
        tow = 'status.tow'
    }
    local perm = permMap[statusType]
    if not perm then return end
    if IsPlayerAceAllowed(src, perm) then
        statusData[statusType] = not statusData[statusType]
        saveStatus()
        -- Notify all clients of update
        TriggerClientEvent('k-jstatus:client:updateStatus', -1, statusData)
    else
        TriggerClientEvent('chat:addMessage', src, {
            color = {255,0,0},
            args = {"Status", "You do not have permission to toggle this status."}
        })
    end
end)

-- Ensure status is loaded on resource start
loadStatus() 