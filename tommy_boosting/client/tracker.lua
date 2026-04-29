local trackerThread = nil
local trackerActive = false
local removeBusy = false

local function stopTracker()
    trackerActive = false
    trackerThread = nil
end

local function startTrackerIfNeeded()
    local active = LocalState.activeContract
    if not active or active.has_tracker ~= 1 or active.tracker_removed == 1 then
        return
    end

    if trackerActive then return end
    trackerActive = true
    Bridge.Notify(cache.serverId, 'Vehicle tracker is active.', 'error')

    trackerThread = CreateThread(function()
        while trackerActive do
            Wait(30000)
            if not LocalState.activeContract or LocalState.activeContract.tracker_removed == 1 then
                stopTracker()
                return
            end
            Bridge.Notify(cache.serverId, 'Tracker ping detected.', 'inform')
        end
    end)
end

function RemoveBoostingTracker()
    if removeBusy then return end
    local active = LocalState.activeContract
    if not active then return Bridge.Notify(cache.serverId, 'No active contract.', 'error') end
    if active.has_tracker ~= 1 then return Bridge.Notify(cache.serverId, 'No tracker on this contract.', 'error') end
    if active.tracker_removed == 1 then return Bridge.Notify(cache.serverId, 'Tracker already removed.', 'success') end

    removeBusy = true
    local duration = (Config.Tracker.removeTimeSeconds or 10) * 1000
    local ok = lib.progressBar({duration = duration, label = 'Removing tracker...', canCancel = true, useWhileDead = false})
    if not ok then removeBusy = false return end

    if Config.Tracker.allowRemoval and Config.Tracker.skillCheckOnRemove then
        local skillOk = lib.skillCheck({'easy', 'easy'}, {'e', 'q'})
        if not skillOk then
            removeBusy = false
            return Bridge.Notify(cache.serverId, 'Tracker removal failed.', 'error')
        end
    end

    TriggerServerEvent('tommy_boosting:server:removeTracker')
    removeBusy = false
end

RegisterNetEvent('tommy_boosting:client:trackerRemoved', function(ok, msg)
    if ok and LocalState.activeContract then
        LocalState.activeContract.tracker_removed = 1
        stopTracker()
    end
    Bridge.Notify(cache.serverId, msg or (ok and 'Tracker removed.' or 'Tracker removal failed.'), ok and 'success' or 'error')
end)

RegisterNetEvent('tommy_boosting:client:startContract', function()
    startTrackerIfNeeded()
end)
RegisterNetEvent('tommy_boosting:client:contractCompleted', stopTracker)
RegisterNetEvent('tommy_boosting:client:contractEnded', stopTracker)
RegisterNetEvent('tommy_boosting:client:removeTracker', RemoveBoostingTracker)
