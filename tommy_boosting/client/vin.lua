local vinBusy = false

function StartVinScratch()
    if vinBusy then return end
    local active = LocalState.activeContract
    if not active then return Bridge.Notify(cache.serverId, 'No active contract.', 'error') end

    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh == 0 or LocalState.spawnedVehicle ~= veh then
        return Bridge.Notify(cache.serverId, 'You must be in the contract vehicle.', 'error')
    end

    vinBusy = true
    local ok = lib.progressBar({duration = (Config.VinScratch.timeSeconds or 30) * 1000, label = 'Scratching VIN...', canCancel = true, useWhileDead = false})
    if not ok then vinBusy = false return end

    if Config.VinScratch.skillCheck then
        local skillOk = lib.skillCheck({'medium', 'medium'}, {'w', 'a', 's', 'd'})
        if not skillOk then vinBusy = false return Bridge.Notify(cache.serverId, 'VIN scratch failed.', 'error') end
    end

    TriggerServerEvent('tommy_boosting:server:vinScratch', VehToNet(veh), GetVehicleNumberPlateText(veh), GetEntityModel(veh))
    vinBusy = false
end

RegisterNUICallback('vinScratch', function(_, cb) StartVinScratch(); cb(1) end)
RegisterNetEvent('tommy_boosting:client:startVinScratch', StartVinScratch)
RegisterNetEvent('tommy_boosting:client:vinResult', function(ok, msg)
    if ok then
        TriggerEvent('tommy_boosting:client:contractCompleted')
    end
    Bridge.Notify(cache.serverId, msg or (ok and 'VIN scratched.' or 'VIN scratch failed.'), ok and 'success' or 'error')
end)
