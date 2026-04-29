TrackerState = {active=false,thread=false}

local function trackerLoop()
    if TrackerState.thread then return end
    TrackerState.thread=true
    CreateThread(function()
        while TrackerState.active and LocalState.activeContract do
            Wait(1000)
            if IsPedInAnyVehicle(PlayerPedId(), false) then
                -- purely client feedback; real police ping is server-side
                if math.random(1,100) <= 2 then lib.notify({description='Tracker pulse detected',type='warning'}) end
            end
        end
        TrackerState.thread=false
    end)
end

function StartTrackerIfNeeded(c)
    TrackerState.active = c and c.has_tracker == 1 and c.tracker_removed ~= 1
    if TrackerState.active then trackerLoop() end
end

function StopTracker() TrackerState.active=false end

function RemoveTracker()
    local c=LocalState.activeContract
    if not c or c.has_tracker ~= 1 then return end
    if not lib.progressBar({duration=(Config.Tracker.removeTimeSeconds or 12)*1000,label='Removing tracker...',canCancel=true}) then return end
    local ok = true
    if Config.Hacking.enabled then ok = lib.skillCheck({'easy','medium'},{'w','a','s','d'}) end
    TriggerServerEvent('tommy_boosting:server:removeTracker', ok)
end

RegisterNUICallback('removeTracker', function(_,cb) RemoveTracker(); cb({ok=true}) end)
RegisterNetEvent('tommy_boosting:client:trackerRemoved', function(ok,msg)
    if ok then StopTracker(); if LocalState.activeContract then LocalState.activeContract.tracker_removed=1 end end
    lib.notify({description=msg or (ok and 'Tracker disabled' or 'Tracker removal failed'),type=ok and 'success' or 'error'})
end)
