local uiOpen=false
LocalState = {activeContract=nil, spawnedVehicle=nil, blips={}, guards={}}
function OpenBoostingUI() SetNuiFocus(true,true); uiOpen=true; SendNUIMessage({action='open'}) end
exports('OpenBoostingUI', OpenBoostingUI)
exports('GetActiveContract', function() return LocalState.activeContract end)
RegisterCommand(Config.Command, function()
    if Config.RequireLaptopItem then
        local ok, hasLaptop = pcall(function() return lib.callback.await('tommy_boosting:cb:hasLaptop', false) end)
        if (not ok) or (not hasLaptop) then
            return Bridge.Notify(cache.serverId,'Need boosting laptop','error')
        end
    end
    OpenBoostingUI()
end)
RegisterNetEvent('tommy_boosting:client:openUI', OpenBoostingUI)
RegisterNUICallback('close', function(_,cb) SetNuiFocus(false,false); uiOpen=false; cb(1) end)
CreateThread(function() while true do Wait(1000) if uiOpen then local data=lib.callback.await('tommy_boosting:cb:getDashboard',false); SendNUIMessage({action='state',data=data}) end end end)
RegisterNUICallback('acceptContract', function(data,cb) TriggerServerEvent('tommy_boosting:server:acceptContract', data.index); cb(1) end)
RegisterNUICallback('completeContract', function(_,cb) local ped=PlayerPedId(); local veh=GetVehiclePedIsIn(ped,false); TriggerServerEvent('tommy_boosting:server:completeContract', VehToNet(veh)); cb(1) end)
RegisterNUICallback('buyStoreItem', function(data,cb) TriggerServerEvent('tommy_boosting:server:buyItem', data.item); cb(1) end)
RegisterNUICallback('vinScratch', function(_,cb) TriggerEvent('tommy_boosting:client:startVinScratch'); cb(1) end)
RegisterNUICallback('getHistory', function(_,cb) cb(lib.callback.await('tommy_boosting:cb:getHistory', false)) end)
RegisterNUICallback('getLeaderboard', function(_,cb) cb(lib.callback.await('tommy_boosting:cb:getLeaderboard', false)) end)
RegisterNUICallback('startHack', function(_,cb) TriggerEvent('tommy_boosting:client:startHack'); cb(1) end)
RegisterNUICallback('removeTracker', function(_,cb) TriggerEvent('tommy_boosting:client:removeTracker'); cb(1) end)
RegisterNUICallback('cancelContract', function(_,cb) TriggerServerEvent('tommy_boosting:server:cancelContract'); cb(1) end)
RegisterNUICallback('updateProfile', function(data,cb) cb(lib.callback.await('tommy_boosting:cb:updateProfile', false, data)) end)
RegisterNUICallback('transferContract', function(data,cb) cb(lib.callback.await('tommy_boosting:cb:transferContract', false, data)) end)
RegisterNetEvent('tommy_boosting:client:acceptResult', function(ok,data) if ok then LocalState.activeContract=data; TriggerEvent('tommy_boosting:client:startContract',data); Bridge.Notify(cache.serverId,'Contract accepted','success') else Bridge.Notify(cache.serverId,data,'error') end end)
RegisterNetEvent('tommy_boosting:client:completeResult', function(ok,data) if ok then TriggerEvent('tommy_boosting:client:contractCompleted',data); LocalState.activeContract=nil; Bridge.Notify(cache.serverId,'Contract delivered','success') else Bridge.Notify(cache.serverId,data,'error') end end)
