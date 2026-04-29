lib.callback.register('tommy_boosting:cb:getDashboard', function(src)
 local id=Bridge.GetIdentifier(src)
 local p=DB.single('SELECT * FROM tommy_boosting_players WHERE identifier=?',{id})
 return {profile=p, active=Contracts.GetActive(src), available=Contracts.available[id] or Contracts.GenerateForPlayer(src), storeStock=Store.stock, isAdmin=Security.IsPlayerAdmin(src)}
end)
lib.callback.register('tommy_boosting:cb:getHistory', function(src) return DB.query('SELECT * FROM tommy_boosting_history WHERE identifier=? ORDER BY id DESC LIMIT 100',{Bridge.GetIdentifier(src)}) end)
lib.callback.register('tommy_boosting:cb:getLeaderboard', function() return Leaderboard.Get(50) end)
