Dispatch = Dispatch or {}
Dispatch.trackerLoops = Dispatch.trackerLoops or {}

local function sendCustom(coords, vehicleData, contractClass, alertType)
    if type(Config.CustomDispatchAlert) == 'function' then
        local ok, err = pcall(Config.CustomDispatchAlert, coords, vehicleData, contractClass, alertType)
        if not ok then Utils.Debug('Custom dispatch failed', err) end
    end
end

function Dispatch.SendAlert(src, coords, vehicleData, contractClass, alertType)
    if not Config.Dispatch.enabled or (Config.Dispatch.system or 'none') == 'none' then return end
    local system = Config.Dispatch.system or 'custom'
    vehicleData = vehicleData or {}

    if system == 'custom' then return sendCustom(coords, vehicleData, contractClass, alertType) end

    local payload = {
        coords = coords,
        vehicle = vehicleData,
        class = contractClass,
        alertType = alertType,
        message = ('Boosting %s ping: %s [%s]'):format(contractClass or 'N/A', vehicleData.plate or 'unknown', vehicleData.model or 'unknown')
    }

    local function safeExport(resource, fn)
        if GetResourceState(resource) ~= 'started' then return false end
        local ok = pcall(function() exports[resource][fn](payload) end)
        return ok
    end

    if system == 'ps-dispatch' then safeExport('ps-dispatch', 'CustomAlert')
    elseif system == 'cd_dispatch' then safeExport('cd_dispatch', 'AddNotification')
    elseif system == 'core_dispatch' then safeExport('core_dispatch', 'addCall')
    elseif system == 'qs-dispatch' then safeExport('qs-dispatch', 'CreateDispatchCall')
    end
end

function Dispatch.StopTrackerLoop(identifier)
    if not identifier or not Dispatch.trackerLoops[identifier] then return end
    Dispatch.trackerLoops[identifier].active = false
    Dispatch.trackerLoops[identifier] = nil
end

function Dispatch.StartTrackerLoop(src, contract)
    if not contract or contract.has_tracker ~= 1 or contract.tracker_removed == 1 then return end
    local identifier = Bridge.GetIdentifier(src)
    if not identifier then return end
    Dispatch.StopTrackerLoop(identifier)

    local state = { active = true }
    Dispatch.trackerLoops[identifier] = state
    CreateThread(function()
        while state.active do
            local live = Contracts.activeByIdentifier[identifier]
            if not live or live.contract_id ~= contract.contract_id or live.status == 'cancelled' or live.status == 'failed' or live.status == 'delivered' or live.status == Config.VinScratch.completeStatus then
                break
            end
            if live.tracker_removed == 1 then break end

            local ped = GetPlayerPed(src)
            local coords = ped ~= 0 and GetEntityCoords(ped) or vector3(0.0,0.0,0.0)
            local veh = ped ~= 0 and GetVehiclePedIsIn(ped, false) or 0
            if veh ~= 0 then coords = GetEntityCoords(veh) end
            Dispatch.SendAlert(src, coords, { model = live.vehicle_model, plate = live.plate, class = live.class }, live.class, 'tracker_ping')

            local interval = (((Config.Tracker.pingIntervalSeconds or {})[live.class]) or 90) * 1000
            Wait(interval)
        end
        Dispatch.StopTrackerLoop(identifier)
    end)
end
