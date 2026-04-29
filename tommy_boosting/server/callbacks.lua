lib.callback.register('tommy_boosting:cb:hasLaptop', function(src)
    if not Config.RequireLaptopItem then return true end
    return Bridge.HasItem(src, Config.LaptopItem, 1)
end)

lib.callback.register('tommy_boosting:cb:getDashboard', function(src)
    local identifier = Bridge.GetIdentifier(src)
    local profile = DB.single('SELECT * FROM tommy_boosting_players WHERE identifier=?', { identifier })
    local available = Contracts.available[identifier] or Contracts.GenerateForPlayer(src)
    return {
        profile = profile,
        active = Contracts.GetActive(src),
        available = available,
        storeStock = Store.stock,
        isAdmin = Security.IsPlayerAdmin(src)
    }
end)

lib.callback.register('tommy_boosting:cb:getHistory', function(src)
    return DB.query('SELECT * FROM tommy_boosting_history WHERE identifier=? ORDER BY id DESC LIMIT 100', { Bridge.GetIdentifier(src) })
end)

lib.callback.register('tommy_boosting:cb:getLeaderboard', function()
    return Leaderboard.Get(50)
end)
