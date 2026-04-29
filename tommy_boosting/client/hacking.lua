local hackBusy = false
local nextHackAt = 0

local function notify(msg, t)
    Bridge.Notify(cache.serverId, msg, t or 'inform')
end

function StartBoostingHack()
    if hackBusy or GetGameTimer() < nextHackAt then
        return notify('Hacking cooldown active.', 'error')
    end

    local active = LocalState.activeContract
    if not active then
        return notify('No active contract.', 'error')
    end

    if active.requires_hacking ~= 1 then
        return notify('This contract does not require hacking.', 'error')
    end

    if active.hack_completed == 1 then
        return notify('Hack already completed.', 'success')
    end

    local preset = (Config.Hacking.difficultyByClass or {})[active.class]
    if not preset or preset == false then
        TriggerServerEvent('tommy_boosting:server:hackResult', true)
        return
    end

    hackBusy = true
    nextHackAt = GetGameTimer() + 5000

    local success = lib.skillCheck(preset, {'w', 'a', 's', 'd'})
    TriggerServerEvent('tommy_boosting:server:hackResult', success)

    if success then
        notify('Hack successful.', 'success')
    else
        notify('Hack failed.', 'error')
    end

    hackBusy = false
end

RegisterNetEvent('tommy_boosting:client:startHack', StartBoostingHack)
RegisterNetEvent('tommy_boosting:client:hackUpdated', function(success, attemptsUsed)
    if LocalState.activeContract then
        LocalState.activeContract.hack_completed = success and 1 or 0
        LocalState.activeContract.hack_attempts_used = attemptsUsed or 0
    end
end)
