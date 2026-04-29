local uiOpen = false
LocalState = { activeContract = nil, spawnedVehicle = nil, blips = {} }

function OpenBoostingUI()
    SetNuiFocus(true, true)
    uiOpen = true
    SendNUIMessage({ action = 'open' })
end

exports('OpenBoostingUI', OpenBoostingUI)
exports('GetActiveContract', function() return LocalState.activeContract end)

RegisterCommand(Config.Command, function()
    if Config.RequireLaptopItem and not lib.callback.await('tommy_boosting:cb:hasLaptop', false) then
        lib.notify({ description = 'You need a boosting_laptop', type = 'error' })
        return
    end
    OpenBoostingUI()
end, false)

RegisterNetEvent('tommy_boosting:client:openUI', OpenBoostingUI)

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    uiOpen = false
    cb({ ok = true })
end)

CreateThread(function()
    while true do
        Wait(1000)
        if uiOpen then
            local data = lib.callback.await('tommy_boosting:cb:getDashboard', false)
            SendNUIMessage({ action = 'state', data = data })
        end
    end
end)
