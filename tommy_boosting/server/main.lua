local function ensureProfile(src)
    local identifier = Bridge.GetIdentifier(src)
    if not identifier then return end
    local name = Bridge.GetPlayerName(src) or GetPlayerName(src)
    DB.update('INSERT INTO tommy_boosting_players (identifier,name,profile_name,last_active) VALUES (?,?,?,NOW()) ON DUPLICATE KEY UPDATE name=VALUES(name), last_active=NOW()', { identifier, name, name })
end

RegisterNetEvent('tommy_boosting:server:acceptContract', function(index)
    local src = source
    local ok, data = Contracts.Accept(src, index)
    TriggerClientEvent('tommy_boosting:client:acceptResult', src, ok, data)
end)

RegisterNetEvent('tommy_boosting:server:completeContract', function(coords)
    local src = source
    local ok, data = Contracts.Complete(src, coords)
    TriggerClientEvent('tommy_boosting:client:completeResult', src, ok, data)
end)

RegisterNetEvent('tommy_boosting:server:cancelContract', function()
    local src = source
    local ok, data = Contracts.Cancel(src)
    TriggerClientEvent('tommy_boosting:client:cancelResult', src, ok, data)
end)

RegisterNetEvent('tommy_boosting:server:buyItem', function(item)
    local src = source
    local ok, msg = Store.Buy(src, item)
    TriggerClientEvent('tommy_boosting:client:buyResult', src, ok, msg)
end)

RegisterNetEvent('tommy_boosting:server:vinScratch', function()
    local src = source
    local ok, msg = Vin.Scratch(src)
    TriggerClientEvent('tommy_boosting:client:vinResult', src, ok, msg)
end)

AddEventHandler('playerDropped', function()
    local src = source
    local identifier = Bridge.GetIdentifier(src)
    if identifier then
        Contracts.CleanupPlayer(identifier)
    end
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    print('[Tommy Boosting] started')
    for _, id in ipairs(GetPlayers()) do ensureProfile(tonumber(id)) end
end)

CreateThread(function()
    while true do
        Wait(Config.ContractRefreshMinutes * 60000)
        for _, id in ipairs(GetPlayers()) do
            Contracts.GenerateForPlayer(tonumber(id))
        end
    end
end)

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    ensureProfile(source)
end)

RegisterNetEvent('esx:playerLoaded', function(playerId)
    ensureProfile(playerId or source)
end)

exports('GetPlayerBoostingProfile', function(identifier)
    return DB.single('SELECT * FROM tommy_boosting_players WHERE identifier=?', { identifier })
end)
exports('AddBoostingCrypto', function(identifier, amount)
    return DB.update('UPDATE tommy_boosting_players SET crypto = crypto + ? WHERE identifier=?', { math.max(0, tonumber(amount) or 0), identifier })
end)
exports('RemoveBoostingCrypto', function(identifier, amount)
    return DB.update('UPDATE tommy_boosting_players SET crypto = GREATEST(crypto-?,0) WHERE identifier=?', { math.max(0, tonumber(amount) or 0), identifier })
end)
exports('AddBoostingXP', function(identifier, amount)
    return DB.update('UPDATE tommy_boosting_players SET xp = xp + ? WHERE identifier=?', { math.max(0, tonumber(amount) or 0), identifier })
end)
exports('GenerateContractForPlayer', function(src, class)
    return Contracts.GenerateForPlayer(src, class)
end)
exports('CancelPlayerContract', function(src)
    return Contracts.Cancel(src)
end)
