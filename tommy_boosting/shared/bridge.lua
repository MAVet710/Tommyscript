Bridge = {}
local fw, QBCore, ESX = 'standalone'
CreateThread(function()
  if Config.Framework == 'qb' or (Config.Framework=='auto' and GetResourceState('qb-core')=='started') then fw='qb'; QBCore=exports['qb-core']:GetCoreObject()
  elseif Config.Framework == 'esx' or (Config.Framework=='auto' and GetResourceState('es_extended')=='started') then fw='esx'; ESX=exports['es_extended']:getSharedObject() end
  Utils.Debug('Framework', fw)
end)
function Bridge.GetFramework() return fw end
function Bridge.GetIdentifier(src)
  if fw=='qb' then local p=QBCore.Functions.GetPlayer(src); return p and p.PlayerData.citizenid end
  if fw=='esx' then local p=ESX.GetPlayerFromId(src); return p and p.identifier end
  for _,id in ipairs(GetPlayerIdentifiers(src)) do if id:find('license:') then return id end end; return ('src:%s'):format(src)
end
function Bridge.GetPlayerName(src) if fw=='qb' then local p=QBCore.Functions.GetPlayer(src); return p and (p.PlayerData.charinfo.firstname..' '..p.PlayerData.charinfo.lastname) end if fw=='esx' then local p=ESX.GetPlayerFromId(src); return p and p.getName() end return GetPlayerName(src) end
function Bridge.GetJob(src) if fw=='qb' then local p=QBCore.Functions.GetPlayer(src); return p and p.PlayerData.job.name end if fw=='esx' then local p=ESX.GetPlayerFromId(src); return p and p.job.name end return 'civilian' end
function Bridge.AddMoney(src,account,amount) if fw=='qb' then local p=QBCore.Functions.GetPlayer(src); return p and p.Functions.AddMoney(account,amount,'tommy_boosting') end if fw=='esx' then local p=ESX.GetPlayerFromId(src); if p then p.addAccountMoney(account=='cash' and 'money' or account,amount) return true end end return true end
function Bridge.RemoveMoney(src,a,m) if fw=='qb' then local p=QBCore.Functions.GetPlayer(src); return p and p.Functions.RemoveMoney(a,m,'tommy_boosting') end if fw=='esx' then local p=ESX.GetPlayerFromId(src); if p then p.removeAccountMoney(a=='cash' and 'money' or a,m) return true end end return false end
function Bridge.GetMoney(src,a) if fw=='qb' then local p=QBCore.Functions.GetPlayer(src); return p and p.Functions.GetMoney(a) or 0 end if fw=='esx' then local p=ESX.GetPlayerFromId(src); return p and p.getAccount(a=='cash' and 'money' or a).money or 0 end return 0 end
function Bridge.AddItem(src,item,amount,metadata) if GetResourceState('ox_inventory')=='started' and (Config.Inventory=='ox' or Config.Inventory=='auto') then return exports.ox_inventory:AddItem(src,item,amount,metadata) end if fw=='qb' then local p=QBCore.Functions.GetPlayer(src); return p and p.Functions.AddItem(item,amount,false,metadata) end if fw=='esx' then local p=ESX.GetPlayerFromId(src); if p then p.addInventoryItem(item,amount) return true end end return false end
function Bridge.RemoveItem(src,item,amount) if GetResourceState('ox_inventory')=='started' and (Config.Inventory=='ox' or Config.Inventory=='auto') then return exports.ox_inventory:RemoveItem(src,item,amount) end return true end
function Bridge.HasItem(src,item,amount) amount=amount or 1 if GetResourceState('ox_inventory')=='started' and (Config.Inventory=='ox' or Config.Inventory=='auto') then return (exports.ox_inventory:GetItemCount(src,item)>=amount) end return true end
function Bridge.Notify(src,message,type) TriggerClientEvent('ox_lib:notify',src,{description=message,type=type or 'inform'}) end
function Bridge.IsAdmin(src) return IsPlayerAceAllowed(src, Config.Admin.acePermission) end
function Bridge.RegisterUsableItem(item,cb) if fw=='qb' then QBCore.Functions.CreateUseableItem(item, function(src,i) cb(src,i) end) elseif fw=='esx' then ESX.RegisterUsableItem(item,function(src) cb(src,{}) end) end end
