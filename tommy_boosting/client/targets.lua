local targetAdded = false

local function openUI()
    OpenBoostingUI()
end

local function addFallbackZone()
    CreateThread(function()
        while true do
            Wait(0)
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            local laptopPos = vec3(215.0, -810.0, 30.7)
            local dist = #(pos - laptopPos)
            if dist < 10.0 then
                DrawMarker(1, laptopPos.x, laptopPos.y, laptopPos.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.2, 1.2, 0.3, 255, 120, 0, 180, false, false, 2)
                if dist < 1.5 then
                    lib.showTextUI('[E] Open Boosting Laptop')
                    if IsControlJustReleased(0, 38) then openUI() end
                else
                    lib.hideTextUI()
                end
            else
                lib.hideTextUI()
            end
        end
    end)
end

CreateThread(function()
    if not Config.UseTarget then
        addFallbackZone()
        return
    end

    if Config.TargetSystem == 'ox_target' and GetResourceState('ox_target') == 'started' then
        exports.ox_target:addSphereZone({coords = vec3(215.0, -810.0, 30.7), radius = 1.5, debug = false, options = {
            {name = 'tb_laptop', label = 'Open Boosting Laptop', onSelect = openUI},
            {name = 'tb_deliver', label = 'Deliver Active Vehicle', onSelect = function() TriggerServerEvent('tommy_boosting:server:completeContract', VehToNet(GetVehiclePedIsIn(PlayerPedId(), false)), GetEntityCoords(PlayerPedId())) end},
            {name = 'tb_hack', label = 'Start Hack', onSelect = function() TriggerEvent('tommy_boosting:client:startHack') end},
            {name = 'tb_tracker', label = 'Remove Tracker', onSelect = function() TriggerEvent('tommy_boosting:client:removeTracker') end},
            {name = 'tb_vin', label = 'VIN Scratch', onSelect = function() TriggerEvent('tommy_boosting:client:startVinScratch') end}
        }})
        targetAdded = true
    elseif Config.TargetSystem == 'qb-target' and GetResourceState('qb-target') == 'started' then
        exports['qb-target']:AddCircleZone('tb_laptop', vector3(215.0, -810.0, 30.7), 1.5, {}, {options = {
            {label = 'Open Boosting Laptop', action = openUI},
            {label = 'Deliver Active Vehicle', action = function() TriggerServerEvent('tommy_boosting:server:completeContract', VehToNet(GetVehiclePedIsIn(PlayerPedId(), false)), GetEntityCoords(PlayerPedId())) end},
            {label = 'Start Hack', action = function() TriggerEvent('tommy_boosting:client:startHack') end},
            {label = 'Remove Tracker', action = function() TriggerEvent('tommy_boosting:client:removeTracker') end},
            {label = 'VIN Scratch', action = function() TriggerEvent('tommy_boosting:client:startVinScratch') end}
        }, distance = 2.0})
        targetAdded = true
    end

    if not targetAdded then
        addFallbackZone()
    end
end)
