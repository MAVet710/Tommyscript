RegisterNUICallback('acceptContract', function(data, cb)
    TriggerServerEvent('tommy_boosting:server:acceptContract', tonumber(data.index))
    cb({ ok = true })
end)

RegisterNUICallback('completeContract', function(_, cb)
    local c = GetEntityCoords(PlayerPedId())
    TriggerServerEvent('tommy_boosting:server:completeContract', { x = c.x, y = c.y, z = c.z })
    cb({ ok = true })
end)

RegisterNUICallback('cancelContract', function(_, cb)
    TriggerServerEvent('tommy_boosting:server:cancelContract')
    cb({ ok = true })
end)

RegisterNUICallback('buyStoreItem', function(data, cb)
    TriggerServerEvent('tommy_boosting:server:buyItem', data.item)
    cb({ ok = true })
end)

RegisterNUICallback('vinScratch', function(_, cb)
    TriggerServerEvent('tommy_boosting:server:vinScratch')
    cb({ ok = true })
end)

RegisterNUICallback('getHistory', function(_, cb)
    cb(lib.callback.await('tommy_boosting:cb:getHistory', false) or {})
end)

RegisterNUICallback('getLeaderboard', function(_, cb)
    cb(lib.callback.await('tommy_boosting:cb:getLeaderboard', false) or {})
end)

RegisterNetEvent('tommy_boosting:client:acceptResult', function(ok, data)
    if ok then
        LocalState.activeContract = data
        TriggerEvent('tommy_boosting:client:startContract', data)
        lib.notify({ description = 'Contract accepted', type = 'success' })
    else
        lib.notify({ description = data or 'Contract failed', type = 'error' })
    end
end)

RegisterNetEvent('tommy_boosting:client:completeResult', function(ok, data)
    if ok then
        TriggerEvent('tommy_boosting:client:contractCompleted', data)
        lib.notify({ description = 'Contract delivered', type = 'success' })
    else
        lib.notify({ description = data or 'Delivery failed', type = 'error' })
    end
end)


RegisterNUICallback('getDashboard', function(_, cb) cb(lib.callback.await('tommy_boosting:cb:getDashboard', false)) end)
RegisterNUICallback('getContracts', function(_, cb) cb(lib.callback.await('tommy_boosting:cb:getContracts', false)) end)
RegisterNUICallback('getActiveContract', function(_, cb) cb(lib.callback.await('tommy_boosting:cb:getActiveContract', false)) end)
RegisterNUICallback('updateProfile', function(data, cb) cb(lib.callback.await('tommy_boosting:cb:updateProfile', false, data)) end)
RegisterNUICallback('transferContract', function(data, cb) cb(lib.callback.await('tommy_boosting:cb:transferContract', false, data)) end)
