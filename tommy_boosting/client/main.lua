local uiOpen=false
LocalState = {activeContract=nil, spawnedVehicle=nil, blips={}, guards={}}
function OpenBoostingUI() SetNuiFocus(true,true); uiOpen=true; SendNUIMessage({action='open'}) end
exports('OpenBoostingUI', OpenBoostingUI)
exports('GetActiveContract', function() return LocalState.activeContract end)
RegisterCommand(Config.Command, function() if Config.RequireLaptopItem and not Bridge.HasItem(cache.serverId,Config.LaptopItem,1) then return Bridge.Notify(cache.serverId,'Need boosting laptop','error') end OpenBoostingUI() end)
RegisterNetEvent('tommy_boosting:client:openUI', OpenBoostingUI)
RegisterNUICallback('close', function(_,cb) SetNuiFocus(false,false); uiOpen=false; cb(1) end)
CreateThread(function() while true do Wait(1000) if uiOpen then local data=lib.callback.await('tommy_boosting:cb:getDashboard',false); SendNUIMessage({action='state',data=data}) end end end)
