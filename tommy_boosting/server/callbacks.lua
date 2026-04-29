lib.callback.register('tommy_boosting:cb:hasLaptop', function(src)
    if not Config.RequireLaptopItem then return true end
    return Bridge.HasItem(src, Config.LaptopItem, 1)
end)

lib.callback.register('tommy_boosting:cb:getDashboard', function(src)
    local id = Bridge.GetIdentifier(src)
    local profile = DB.single('SELECT * FROM tommy_boosting_players WHERE identifier=?', { id })
    return {
        profile = profile,
        active = Contracts.GetActive(src),
        available = Contracts.available[id] or Contracts.GenerateForPlayer(src),
        storeStock = Store.stock,
        isAdmin = Security.IsPlayerAdmin(src)
    }
end)
lib.callback.register('tommy_boosting:cb:getContracts', function(src)
    local id = Bridge.GetIdentifier(src)
    return Contracts.available[id] or Contracts.GenerateForPlayer(src)
end)
lib.callback.register('tommy_boosting:cb:getActiveContract', function(src) return Contracts.GetActive(src) end)
lib.callback.register('tommy_boosting:cb:getHistory', function(src) return DB.query('SELECT * FROM tommy_boosting_history WHERE identifier=? ORDER BY id DESC LIMIT 100', { Bridge.GetIdentifier(src) }) end)
lib.callback.register('tommy_boosting:cb:getLeaderboard', function() return Leaderboard.Get(50) end)
lib.callback.register('tommy_boosting:cb:getStore', function() return Config.Store.items end)
lib.callback.register('tommy_boosting:cb:updateProfile', function(src, data)
    local id = Bridge.GetIdentifier(src)
    DB.update('UPDATE tommy_boosting_players SET profile_name=?, profile_image=? WHERE identifier=?', { Security.SanitizeString(data.profile_name, 24), Security.SanitizeString(data.profile_image, 255), id })
    return true
end)
lib.callback.register('tommy_boosting:cb:transferContract', function(src, data)
    if not Config.ContractTransfers.enabled then return false, 'Transfers disabled' end
    local fromId = Bridge.GetIdentifier(src)
    local targetIdentifier = Security.SanitizeString((data or {}).target, 64)
    local active = Contracts.activeByIdentifier[fromId]
    if not active then return false, 'No active contract' end
    local targetSrc = Utils.FindSourceByIdentifier(targetIdentifier)
    if not targetSrc then return false, 'Target player offline' end
    if Contracts.activeByIdentifier[targetIdentifier] then return false, 'Target already has active contract' end
    local targetProfile = DB.single('SELECT * FROM tommy_boosting_players WHERE identifier=?', {targetIdentifier})
    if not targetProfile then return false, 'Target profile missing' end
    local reqLvl = (Config.Classes[active.class] or {}).levelRequired or 1
    if (not Config.ContractTransfers.allowAboveLevel) and (targetProfile.level < reqLvl) then return false, 'Target level too low' end
    local price = math.max(tonumber((data or {}).price) or 0, 0)
    if price > 0 and Config.ContractTransfers.allowPrice and Config.ContractTransfers.currency == 'crypto' then
        local fromProfile = DB.single('SELECT * FROM tommy_boosting_players WHERE identifier=?', {fromId})
        if (targetProfile.crypto or 0) < price then return false, 'Target lacks crypto' end
        DB.update('UPDATE tommy_boosting_players SET crypto=crypto-? WHERE identifier=?', {price, targetIdentifier})
        DB.update('UPDATE tommy_boosting_players SET crypto=crypto+? WHERE identifier=?', {price, fromId})
    end
    DB.update('INSERT INTO tommy_boosting_transfers (contract_id, from_identifier, to_identifier, price, currency, note) VALUES (?,?,?,?,?,?)', {active.contract_id, fromId, targetIdentifier, price, Config.ContractTransfers.currency or 'crypto', Security.SanitizeString((data or {}).note, 255)})
    Contracts.activeByIdentifier[fromId] = nil
    active.assigned_identifier = targetIdentifier
    active.owner_identifier = targetIdentifier
    Contracts.activeByIdentifier[targetIdentifier] = active
    DB.update("UPDATE tommy_boosting_contracts SET owner_identifier=?, assigned_identifier=? WHERE contract_id=? AND status IN ('accepted','in_progress')", {targetIdentifier, targetIdentifier, active.contract_id})
    Bridge.Notify(src, 'Contract transferred', 'success')
    Bridge.Notify(targetSrc, 'You received a transferred contract', 'success')
    return true, 'Transferred'
end)
lib.callback.register('tommy_boosting:cb:startHack', function(src) return Contracts.CanStartHack(src) end)
lib.callback.register('tommy_boosting:cb:removeTracker', function(src) return Contracts.CanRemoveTracker(src) end)
lib.callback.register('tommy_boosting:cb:vinScratch', function(src) return Vin.CanScratch(src) end)
lib.callback.register('tommy_boosting:cb:adminSearchPlayer', function(src, data)
    if not Admin.Require(src) then return nil end
    local identifier = Security.SanitizeString((data or {}).identifier, 64)
    return DB.single('SELECT * FROM tommy_boosting_players WHERE identifier=?', { identifier })
end)
lib.callback.register('tommy_boosting:cb:adminGetLogs', function(src)
    if not Admin.Require(src) then return {} end
    return DB.query('SELECT * FROM tommy_boosting_admin_logs ORDER BY id DESC LIMIT 200')
end)
lib.callback.register('tommy_boosting:cb:adminGetRecentContracts', function(src)
    if not Admin.Require(src) then return {} end
    return DB.query('SELECT * FROM tommy_boosting_contracts ORDER BY id DESC LIMIT 100')
end)
lib.callback.register('tommy_boosting:cb:adminGetPurchases', function(src)
    if not Admin.Require(src) then return {} end
    return DB.query('SELECT * FROM tommy_boosting_store_purchases ORDER BY id DESC LIMIT 100')
end)
