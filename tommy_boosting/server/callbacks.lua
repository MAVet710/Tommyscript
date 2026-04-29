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
    return false, 'Transfer not configured in this build.'
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
