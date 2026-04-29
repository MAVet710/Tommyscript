Bridge = {}
local framework, QBCore, ESX = 'standalone', nil, nil

CreateThread(function()
    if Config.Framework == 'qb' or (Config.Framework == 'auto' and GetResourceState('qb-core') == 'started') then
        framework = 'qb'
        QBCore = exports['qb-core']:GetCoreObject()
    elseif Config.Framework == 'esx' or (Config.Framework == 'auto' and GetResourceState('es_extended') == 'started') then
        framework = 'esx'
        ESX = exports['es_extended']:getSharedObject()
    end
    Utils.Debug('Framework:', framework)
end)

function Bridge.GetFramework() return framework end
function Bridge.GetIdentifier(src)
    if framework == 'qb' then local p = QBCore.Functions.GetPlayer(src); return p and p.PlayerData.citizenid or nil end
    if framework == 'esx' then local p = ESX.GetPlayerFromId(src); return p and p.identifier or nil end
    for _, id in ipairs(GetPlayerIdentifiers(src)) do if id:find('license:') then return id end end
    return ('src:%s'):format(src)
end
function Bridge.GetPlayerName(src)
    if framework == 'qb' then local p = QBCore.Functions.GetPlayer(src); if p then return (p.PlayerData.charinfo.firstname .. ' ' .. p.PlayerData.charinfo.lastname) end end
    if framework == 'esx' then local p = ESX.GetPlayerFromId(src); if p then return p.getName() end end
    return GetPlayerName(src)
end
function Bridge.GetJob(src)
    if framework == 'qb' then local p = QBCore.Functions.GetPlayer(src); return p and p.PlayerData.job.name or 'unemployed' end
    if framework == 'esx' then local p = ESX.GetPlayerFromId(src); return p and p.job.name or 'unemployed' end
    return 'civilian'
end
function Bridge.AddMoney(src, account, amount)
    amount = math.max(0, tonumber(amount) or 0)
    if framework == 'qb' then local p = QBCore.Functions.GetPlayer(src); return p and p.Functions.AddMoney(account, amount, 'tommy_boosting') or false end
    if framework == 'esx' then local p = ESX.GetPlayerFromId(src); if p then p.addAccountMoney(account == 'cash' and 'money' or account, amount); return true end end
    return true
end
function Bridge.RemoveMoney(src, account, amount)
    amount = math.max(0, tonumber(amount) or 0)
    if framework == 'qb' then local p = QBCore.Functions.GetPlayer(src); return p and p.Functions.RemoveMoney(account, amount, 'tommy_boosting') or false end
    if framework == 'esx' then local p = ESX.GetPlayerFromId(src); if p then p.removeAccountMoney(account == 'cash' and 'money' or account, amount); return true end end
    return false
end
function Bridge.GetMoney(src, account)
    if framework == 'qb' then local p = QBCore.Functions.GetPlayer(src); return p and p.Functions.GetMoney(account) or 0 end
    if framework == 'esx' then local p = ESX.GetPlayerFromId(src); return p and p.getAccount(account == 'cash' and 'money' or account).money or 0 end
    return 0
end
function Bridge.AddItem(src, item, amount, metadata)
    if GetResourceState('ox_inventory') == 'started' and (Config.Inventory == 'ox' or Config.Inventory == 'auto') then return exports.ox_inventory:AddItem(src, item, amount, metadata) end
    if framework == 'qb' then local p = QBCore.Functions.GetPlayer(src); return p and p.Functions.AddItem(item, amount, false, metadata) or false end
    if framework == 'esx' then local p = ESX.GetPlayerFromId(src); if p then p.addInventoryItem(item, amount); return true end end
    return true
end
function Bridge.RemoveItem(src, item, amount)
    if GetResourceState('ox_inventory') == 'started' and (Config.Inventory == 'ox' or Config.Inventory == 'auto') then return exports.ox_inventory:RemoveItem(src, item, amount) end
    if framework == 'qb' then local p = QBCore.Functions.GetPlayer(src); return p and p.Functions.RemoveItem(item, amount) or false end
    if framework == 'esx' then local p = ESX.GetPlayerFromId(src); if p then p.removeInventoryItem(item, amount); return true end end
    return false
end
function Bridge.HasItem(src, item, amount)
    amount = amount or 1
    if GetResourceState('ox_inventory') == 'started' and (Config.Inventory == 'ox' or Config.Inventory == 'auto') then return exports.ox_inventory:GetItemCount(src, item) >= amount end
    if framework == 'qb' then local p = QBCore.Functions.GetPlayer(src); return p and (p.Functions.GetItemByName(item) and p.Functions.GetItemByName(item).amount >= amount) or false end
    if framework == 'esx' then local p = ESX.GetPlayerFromId(src); return p and (p.getInventoryItem(item).count >= amount) or false end
    return true
end
function Bridge.Notify(src, message, nType)
    TriggerClientEvent('ox_lib:notify', src, { description = message, type = nType or 'inform' })
end
function Bridge.IsAdmin(src)
    if Config.Admin.useAce and IsPlayerAceAllowed(src, Config.Admin.acePermission) then return true end
    local identifier = Bridge.GetIdentifier(src)
    for _, allowed in ipairs(Config.Admin.identifiers) do if identifier == allowed then return true end end
    return false
end
function Bridge.RegisterUsableItem(item, cb)
    if framework == 'qb' then QBCore.Functions.CreateUseableItem(item, function(src, itemData) cb(src, itemData) end) end
    if framework == 'esx' then ESX.RegisterUsableItem(item, function(src) cb(src, {}) end) end
end
