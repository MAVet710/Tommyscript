local function cbAwait(name, data)
    return lib.callback.await(name, false, data)
end

RegisterNUICallback('adminSearchPlayer', function(data, cb) cb(cbAwait('tommy_boosting:cb:adminSearchPlayer', data)); end)
RegisterNUICallback('adminGetLogs', function(_, cb) cb(cbAwait('tommy_boosting:cb:adminGetLogs')); end)
RegisterNUICallback('adminGetRecentContracts', function(_, cb) cb(cbAwait('tommy_boosting:cb:adminGetRecentContracts')); end)
RegisterNUICallback('adminGetPurchases', function(_, cb) cb(cbAwait('tommy_boosting:cb:adminGetPurchases')); end)

RegisterNUICallback('adminAddCrypto', function(data, cb) TriggerServerEvent('tommy_boosting:server:adminAction', 'addCrypto', data); cb(1); end)
RegisterNUICallback('adminRemoveCrypto', function(data, cb) TriggerServerEvent('tommy_boosting:server:adminAction', 'removeCrypto', data); cb(1); end)
RegisterNUICallback('adminAddXP', function(data, cb) TriggerServerEvent('tommy_boosting:server:adminAction', 'addXP', data); cb(1); end)
RegisterNUICallback('adminRemoveXP', function(data, cb) TriggerServerEvent('tommy_boosting:server:adminAction', 'removeXP', data); cb(1); end)
RegisterNUICallback('adminSetXP', function(data, cb) TriggerServerEvent('tommy_boosting:server:adminAction', 'setXP', data); cb(1); end)
RegisterNUICallback('adminGenerateContract', function(data, cb) TriggerServerEvent('tommy_boosting:server:adminAction', 'generateContract', data); cb(1); end)
RegisterNUICallback('adminCancelContract', function(data, cb) TriggerServerEvent('tommy_boosting:server:adminAction', 'cancelContract', data); cb(1); end)
RegisterNUICallback('adminForceComplete', function(data, cb) TriggerServerEvent('tommy_boosting:server:adminAction', 'forceComplete', data); cb(1); end)

RegisterNetEvent('tommy_boosting:client:adminResult', function(ok, msg)
    Bridge.Notify(cache.serverId, msg or (ok and 'Admin action complete.' or 'Admin action failed.'), ok and 'success' or 'error')
end)
