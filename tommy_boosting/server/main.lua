RegisterNetEvent('tommy_boosting:server:acceptContract', function(idx)
    local src = source
    local ok, data = Contracts.Accept(src, idx)
    TriggerClientEvent('tommy_boosting:client:acceptResult', src, ok, data)
end)

RegisterNetEvent('tommy_boosting:server:completeContract', function(netId, coords)
    local src = source
    local c = Contracts.GetActive(src)
    if not c then return TriggerClientEvent('tommy_boosting:client:completeResult', src, false, 'No active contract') end
    local drop = c.drop and c.drop.coords or nil
    if drop then
        local dist = #(vector3(coords.x, coords.y, coords.z) - vector3(drop.x, drop.y, drop.z))
        if dist > (Config.Dropoffs[1].radius + Config.Security.maxDropoffDistance) then
            return TriggerClientEvent('tommy_boosting:client:completeResult', src, false, 'Not at dropoff')
        end
    end
    local ok, data = Contracts.Complete(src, netId, coords)
    TriggerClientEvent('tommy_boosting:client:completeResult', src, ok, data)
end)

RegisterNetEvent('tommy_boosting:server:hackResult', function(success)
    local src = source
    local id = Bridge.GetIdentifier(src)
    local c = Contracts.activeByIdentifier[id]
    if not c or c.requires_hacking ~= 1 then return end
    if c.hack_completed == 1 then return end
    c.hack_attempts_used = (c.hack_attempts_used or 0) + 1
    if success then c.hack_completed = 1 end
    DB.update('UPDATE tommy_boosting_contracts SET hack_completed=?, hack_attempts_used=? WHERE contract_id=?', { c.hack_completed or 0, c.hack_attempts_used, c.contract_id })
    TriggerClientEvent('tommy_boosting:client:hackUpdated', src, success, c.hack_attempts_used)
    if (not success) and Config.Hacking.failAction == 'alert' then Config.CustomDispatchAlert(GetEntityCoords(GetPlayerPed(src)), { plate = c.plate }, c.class, 'hack_failed') end
    if (not success) and c.hack_attempts_used >= (Config.Hacking.attempts or 3) and Config.Hacking.failContractOnExhaust then
        c.status = 'failed'
        DB.update('UPDATE tommy_boosting_contracts SET status=?, failure_reason=? WHERE contract_id=?', {'failed', 'hack_attempts_exhausted', c.contract_id})
        Contracts.activeByIdentifier[id] = nil
        TriggerClientEvent('tommy_boosting:client:contractEnded', src)
    end
end)

RegisterNetEvent('tommy_boosting:server:removeTracker', function()
    local src = source
    local id = Bridge.GetIdentifier(src)
    local c = Contracts.activeByIdentifier[id]
    if not c then return TriggerClientEvent('tommy_boosting:client:trackerRemoved', src, false, 'No active contract') end
    if c.has_tracker ~= 1 or c.tracker_removed == 1 then return TriggerClientEvent('tommy_boosting:client:trackerRemoved', src, false, 'No active tracker') end
    if Config.Tracker.removeRequiresItem and not Bridge.HasItem(src, Config.Tracker.item, 1) then return TriggerClientEvent('tommy_boosting:client:trackerRemoved', src, false, 'Missing tracker remover') end
    if Config.Tracker.removeRequiresItem then Bridge.RemoveItem(src, Config.Tracker.item, 1) end
    c.tracker_removed = 1
    DB.update('UPDATE tommy_boosting_contracts SET tracker_removed=1 WHERE contract_id=?', { c.contract_id })
    TriggerClientEvent('tommy_boosting:client:trackerRemoved', src, true, 'Tracker removed')
end)

RegisterNetEvent('tommy_boosting:server:vinScratch', function(netId, plate, model)
    local src = source
    local ok, msg = Vin.Scratch(src, netId, plate, model)
    TriggerClientEvent('tommy_boosting:client:vinResult', src, ok, msg)
end)
RegisterNetEvent('tommy_boosting:server:buyItem', function(item) local src=source; local ok,msg=Store.Buy(src,item); TriggerClientEvent('tommy_boosting:client:buyResult',src,ok,msg) end)

RegisterNetEvent('tommy_boosting:server:adminAction', function(action, data)
    local src = source
    if not Admin.Require(src) then return TriggerClientEvent('tommy_boosting:client:adminResult', src, false, 'No permission') end
    local target = (data or {}).identifier
    local amount = tonumber((data or {}).amount) or 0
    if action == 'addCrypto' then DB.update('UPDATE tommy_boosting_players SET crypto=crypto+? WHERE identifier=?', {amount, target}) end
    if action == 'removeCrypto' then DB.update('UPDATE tommy_boosting_players SET crypto=GREATEST(crypto-?,0) WHERE identifier=?', {amount, target}) end
    if action == 'addXP' then DB.update('UPDATE tommy_boosting_players SET xp=xp+? WHERE identifier=?', {amount, target}) end
    if action == 'removeXP' then DB.update('UPDATE tommy_boosting_players SET xp=GREATEST(xp-?,0) WHERE identifier=?', {amount, target}) end
    if action == 'setXP' then DB.update('UPDATE tommy_boosting_players SET xp=? WHERE identifier=?', {amount, target}) end
    Admin.Log(src, action, target, data)
    TriggerClientEvent('tommy_boosting:client:adminResult', src, true, 'Admin action completed')
end)

CreateThread(function()
    while GetResourceState('oxmysql') ~= 'started' do Wait(100) end
end)

RegisterNetEvent('tommy_boosting:server:cancelContract', function()
 local src=source
 local id=Bridge.GetIdentifier(src)
 local c=Contracts.activeByIdentifier[id]
 if c then c.status='cancelled'; DB.update('UPDATE tommy_boosting_contracts SET status=? WHERE contract_id=?',{'cancelled',c.contract_id}); Contracts.activeByIdentifier[id]=nil; TriggerClientEvent('tommy_boosting:client:contractEnded',src) end
end)
