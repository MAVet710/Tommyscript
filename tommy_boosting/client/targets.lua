CreateThread(function()
    if not Config.UseTarget then return end
    if Config.TargetSystem == 'ox_target' and GetResourceState('ox_target') == 'started' then
        exports.ox_target:addGlobalVehicle({
            {name='tb_deliver',label='Deliver Boosted Vehicle',icon='fa-solid fa-car',onSelect=function() TriggerServerEvent('tommy_boosting:server:completeContract', GetEntityCoords(PlayerPedId())) end},
            {name='tb_hack',label='Hack Vehicle',icon='fa-solid fa-laptop-code',onSelect=function() StartContractHack() end},
            {name='tb_tracker',label='Remove Tracker',icon='fa-solid fa-satellite',onSelect=function() RemoveTracker() end},
            {name='tb_vin',label='Scratch VIN',icon='fa-solid fa-id-card',onSelect=function() StartVinScratch() end}
        })
    end
end)
