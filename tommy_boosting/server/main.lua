RegisterNetEvent('tommy_boosting:server:acceptContract', function(idx)
    local src = source
    local ok, data = Contracts.Accept(src, idx)
    if ok then Dispatch.StartTrackerLoop(src, data) end
    TriggerClientEvent('tommy_boosting:client:acceptResult', src, ok, data)
end)

RegisterNetEvent('tommy_boosting:server:completeContract', function(netId)
    local src = source
    local ok, data = Contracts.Complete(src, netId)
    TriggerClientEvent('tommy_boosting:client:completeResult', src, ok, data)
end)

RegisterNetEvent('tommy_boosting:server:hackResult', function(success)
    local src = source
    local id = Bridge.GetIdentifier(src)
    local c = Contracts.activeByIdentifier[id]
    if not c or c.requires_hacking ~= 1 or c.hack_completed == 1 then return end

    local maxAttempts = tonumber(Config.Hacking.attempts) or 1
    if not success and (c.hack_attempts_used or 0) >= maxAttempts then return end

    if success then
        c.hack_completed = 1
    else
        c.hack_attempts_used = (c.hack_attempts_used or 0) + 1
        if c.hack_attempts_used >= maxAttempts then
            if Config.Hacking.failAction == 'fail' then
                local affected = DB.update("UPDATE tommy_boosting_contracts SET status='failed' WHERE contract_id=? AND status IN ('accepted','in_progress')", { c.contract_id })
                if affected and affected > 0 then
                    DB.update('INSERT INTO tommy_boosting_history (contract_id,identifier,class,vehicle_model,plate,status,cash_reward,crypto_reward,xp_reward) VALUES (?,?,?,?,?,?,?,?,?)', {c.contract_id,id,c.class,c.vehicle_model,c.plate,'failed',0,0,0})
                    Contracts.activeByIdentifier[id] = nil
                    Dispatch.StopTrackerLoop(id)
                    TriggerClientEvent('tommy_boosting:client:contractEnded', src)
                end
            elseif Config.Hacking.failAction == 'alert' then
                Dispatch.SendAlert(src, GetEntityCoords(GetPlayerPed(src)), { model = c.vehicle_model, plate = c.plate }, c.class, 'hack_fail_limit')
            end
        end
    end

    DB.update('UPDATE tommy_boosting_contracts SET hack_completed=?, hack_attempts_used=? WHERE contract_id=?', { c.hack_completed or 0, c.hack_attempts_used or 0, c.contract_id })
    TriggerClientEvent('tommy_boosting:client:hackUpdated', src, success, c.hack_attempts_used or 0)
end)

RegisterNetEvent('tommy_boosting:server:removeTracker', function()
    local src=source; local id=Bridge.GetIdentifier(src); local c=Contracts.activeByIdentifier[id]
    if not c then return TriggerClientEvent('tommy_boosting:client:trackerRemoved', src, false, 'No active contract') end
    if c.has_tracker~=1 or c.tracker_removed==1 then return TriggerClientEvent('tommy_boosting:client:trackerRemoved', src, false, 'No active tracker') end
    if Config.Tracker.removeRequiresItem and not Bridge.HasItem(src, Config.Tracker.item, 1) then return TriggerClientEvent('tommy_boosting:client:trackerRemoved', src, false, 'Missing tracker remover') end
    if Config.Tracker.removeRequiresItem and not Bridge.RemoveItem(src, Config.Tracker.item, 1) then return TriggerClientEvent('tommy_boosting:client:trackerRemoved', src, false, 'Failed to consume tracker remover') end
    c.tracker_removed=1; DB.update('UPDATE tommy_boosting_contracts SET tracker_removed=1 WHERE contract_id=?', { c.contract_id }); Dispatch.StopTrackerLoop(id)
    TriggerClientEvent('tommy_boosting:client:trackerRemoved', src, true, 'Tracker removed')
end)
RegisterNetEvent('tommy_boosting:server:vinScratch', function(netId, plate, model) local src=source; local ok, msg = Vin.Scratch(src, netId, plate, model); TriggerClientEvent('tommy_boosting:client:vinResult', src, ok, msg) end)
RegisterNetEvent('tommy_boosting:server:buyItem', function(item) local src=source; local ok,msg=Store.Buy(src,item); TriggerClientEvent('tommy_boosting:client:buyResult',src,ok,msg) end)


local function getLevelForXp(xp) return Utils.CalcLevel(tonumber(xp) or 0) end
RegisterNetEvent('tommy_boosting:server:adminAction', function(action, data)
    local src = source
    if not Admin.Require(src) then return TriggerClientEvent('tommy_boosting:client:adminResult', src, false, 'No permission') end
    local allowed={addCrypto=true,removeCrypto=true,addXP=true,removeXP=true,setXP=true,generateContract=true,cancelContract=true,forceComplete=true,resetProfile=true,adminGetLogs=true}
    if not allowed[action] then return TriggerClientEvent('tommy_boosting:client:adminResult', src, false, 'Unknown action') end
    local target = Security.SanitizeString((data or {}).identifier, 64)
    local amount = tonumber((data or {}).amount) or 0
    local targetProfile = target ~= '' and DB.single('SELECT * FROM tommy_boosting_players WHERE identifier=?', {target}) or nil
    if action ~= 'adminGetLogs' and (not targetProfile) then return TriggerClientEvent('tommy_boosting:client:adminResult', src, false, 'Target identifier missing') end
    if action == 'addCrypto' then DB.update('UPDATE tommy_boosting_players SET crypto=crypto+? WHERE identifier=?', {amount, target}) end
    if action == 'removeCrypto' then DB.update('UPDATE tommy_boosting_players SET crypto=GREATEST(crypto-?,0) WHERE identifier=?', {amount, target}) end
    if action == 'addXP' then DB.update('UPDATE tommy_boosting_players SET xp=xp+?, level=? WHERE identifier=?', {amount, getLevelForXp((targetProfile.xp or 0)+amount), target}) end
    if action == 'removeXP' then local nx=math.max((targetProfile.xp or 0)-amount,0); DB.update('UPDATE tommy_boosting_players SET xp=?, level=? WHERE identifier=?', {nx, getLevelForXp(nx), target}) end
    if action == 'setXP' then local nx=math.max(amount,0); DB.update('UPDATE tommy_boosting_players SET xp=?, level=? WHERE identifier=?', {nx, getLevelForXp(nx), target}) end
    if action == 'generateContract' then local tSrc=Utils.FindSourceByIdentifier(target); if not tSrc then return TriggerClientEvent('tommy_boosting:client:adminResult', src, false, 'Target offline') end; local class=Security.SanitizeString((data or {}).class,3); Contracts.GenerateForPlayer(tSrc, class); TriggerClientEvent('tommy_boosting:client:adminResult', tSrc, true, ('Admin generated %s contracts for you'):format(class ~= '' and class or 'D')) end
    if action == 'cancelContract' then local c=Contracts.activeByIdentifier[target]; if c then local aff=DB.update("UPDATE tommy_boosting_contracts SET status='cancelled' WHERE contract_id=? AND status IN ('accepted','in_progress')",{c.contract_id}); if aff and aff>0 then DB.update('INSERT INTO tommy_boosting_history (contract_id,identifier,class,vehicle_model,plate,status,cash_reward,crypto_reward,xp_reward) VALUES (?,?,?,?,?,?,?,?,?)',{c.contract_id,target,c.class,c.vehicle_model,c.plate,'cancelled',0,0,0}) end; Contracts.activeByIdentifier[target]=nil; Dispatch.StopTrackerLoop(target); local tSrc=Utils.FindSourceByIdentifier(target); if tSrc then TriggerClientEvent('tommy_boosting:client:contractEnded',tSrc); Bridge.Notify(tSrc,'Your contract was cancelled by an admin','error') end end end
    if action == 'forceComplete' then local c=Contracts.activeByIdentifier[target]; if c then local aff=DB.update("UPDATE tommy_boosting_contracts SET status='delivered', completed_at=NOW() WHERE contract_id=? AND status IN ('accepted','in_progress')",{c.contract_id}); if aff and aff>0 then DB.update('INSERT INTO tommy_boosting_history (contract_id,identifier,class,vehicle_model,plate,status,cash_reward,crypto_reward,xp_reward) VALUES (?,?,?,?,?,?,?,?,?)',{c.contract_id,target,c.class,c.vehicle_model,c.plate,'admin_force_completed',0,0,0}) end; Contracts.activeByIdentifier[target]=nil; Dispatch.StopTrackerLoop(target); local tSrc=Utils.FindSourceByIdentifier(target); if tSrc then TriggerClientEvent('tommy_boosting:client:contractEnded',tSrc) end end end
    if action == 'resetProfile' then DB.update('UPDATE tommy_boosting_players SET xp=0,level=1,crypto=0,completed_contracts=0,failed_contracts=0,total_cash_earned=0,total_crypto_earned=0,total_xp_earned=0 WHERE identifier=?',{target}); Contracts.activeByIdentifier[target]=nil; Contracts.available[target]={}; Dispatch.StopTrackerLoop(target) end
    Admin.Log(src, action, target, data)
    TriggerClientEvent('tommy_boosting:client:adminResult', src, true, 'Admin action completed')
end)

CreateThread(function() while GetResourceState('oxmysql') ~= 'started' do Wait(100) end end)
RegisterNetEvent('tommy_boosting:server:cancelContract', function() local src=source local id=Bridge.GetIdentifier(src) local c=Contracts.activeByIdentifier[id] if c then local affected=DB.update("UPDATE tommy_boosting_contracts SET status='cancelled' WHERE contract_id=? AND status IN ('accepted','in_progress')",{c.contract_id}); if affected and affected>0 then DB.update('INSERT INTO tommy_boosting_history (contract_id,identifier,class,vehicle_model,plate,status,cash_reward,crypto_reward,xp_reward) VALUES (?,?,?,?,?,?,?,?,?)',{c.contract_id,id,c.class,c.vehicle_model,c.plate,'cancelled',0,0,0}); Contracts.cooldowns[id]=os.time()+((Config.Classes[c.class].cooldown or 5)*60) end; Contracts.activeByIdentifier[id]=nil; Dispatch.StopTrackerLoop(id); TriggerClientEvent('tommy_boosting:client:contractEnded',src) end end)

AddEventHandler('playerDropped', function()
    local src = source
    local id = Bridge.GetIdentifier(src)
    if not id then return end
    local c = Contracts.activeByIdentifier[id]
    if c then
        local endStatus = (Config.Security and Config.Security.dropContractStatusOnDisconnect) or 'cancelled'
        DB.update("UPDATE tommy_boosting_contracts SET status=? WHERE contract_id=? AND status IN ('accepted','in_progress')", { endStatus, c.contract_id })
        DB.update('INSERT INTO tommy_boosting_history (contract_id,identifier,class,vehicle_model,plate,status,cash_reward,crypto_reward,xp_reward) VALUES (?,?,?,?,?,?,?,?,?)', {c.contract_id,id,c.class,c.vehicle_model,c.plate,endStatus,0,0,0})
    end
    Contracts.activeByIdentifier[id] = nil
    Dispatch.StopTrackerLoop(id)
end)
