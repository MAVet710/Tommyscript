function StartVinScratch()
    local c = LocalState.activeContract
    if not c then return end
    if not lib.progressBar({duration=(Config.VinScratch.timeSeconds or 30)*1000,label='Scratching VIN...',canCancel=true}) then return end
    local ok = lib.skillCheck({'medium','hard'},{'w','a','s','d'})
    TriggerServerEvent('tommy_boosting:server:vinScratch', ok)
end
RegisterNUICallback('vinScratch', function(_,cb) StartVinScratch(); cb({ok=true}) end)
RegisterNetEvent('tommy_boosting:client:vinResult', function(ok,msg) lib.notify({description=msg or (ok and 'VIN scratch complete' or 'VIN scratch failed'),type=ok and 'success' or 'error'}) if ok then TriggerEvent('tommy_boosting:client:contractCompleted') end end)
