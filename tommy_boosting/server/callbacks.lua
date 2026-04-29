lib.callback.register('tommy_boosting:cb:hasLaptop', function(src)
    return (not Config.RequireLaptopItem) or Bridge.HasItem(src, Config.LaptopItem, 1)
end)
lib.callback.register('tommy_boosting:cb:getDashboard', function(src)
    local id=Bridge.GetIdentifier(src)
    return {profile=DB.single('SELECT * FROM tommy_boosting_players WHERE identifier=?',{id}),available=Contracts.available[id] or Contracts.GenerateForPlayer(src),active=Contracts.GetActive(src),storeStock=Store.stock,isAdmin=Bridge.IsAdmin(src)}
end)
lib.callback.register('tommy_boosting:cb:getContracts', function(src) local id=Bridge.GetIdentifier(src); return Contracts.available[id] or Contracts.GenerateForPlayer(src) end)
lib.callback.register('tommy_boosting:cb:getActiveContract', function(src) return Contracts.GetActive(src) end)
lib.callback.register('tommy_boosting:cb:getHistory', function(src) return DB.query('SELECT * FROM tommy_boosting_history WHERE identifier=? ORDER BY id DESC LIMIT 100',{Bridge.GetIdentifier(src)}) end)
lib.callback.register('tommy_boosting:cb:getLeaderboard', function() return Leaderboard.Get(50) end)
lib.callback.register('tommy_boosting:cb:updateProfile', function(src,data)
    local id=Bridge.GetIdentifier(src); local n=Security.SanitizeString(data.profile_name,24); local i=Security.SanitizeString(data.profile_image,255)
    DB.update('UPDATE tommy_boosting_players SET profile_name=?, profile_image=? WHERE identifier=?',{n,i,id}); return {ok=true}
end)
lib.callback.register('tommy_boosting:cb:transferContract', function(src,data) return {ok=false,msg='Transfer not yet enabled in this build'} end)
lib.callback.register('tommy_boosting:cb:adminSearchPlayer', function(src,data)
    if not Bridge.IsAdmin(src) then return {ok=false,msg='Not admin'} end
    local target=data and data.identifier
    local row=DB.single('SELECT * FROM tommy_boosting_players WHERE identifier=?',{target})
    return {ok=row~=nil,player=row}
end)
lib.callback.register('tommy_boosting:cb:adminAction', function(src,action,data)
    if not Bridge.IsAdmin(src) then return {ok=false,msg='Not admin'} end
    local id = data.identifier
    if action=='add_crypto' then DB.update('UPDATE tommy_boosting_players SET crypto=crypto+? WHERE identifier=?',{tonumber(data.amount) or 0,id}) end
    if action=='remove_crypto' then DB.update('UPDATE tommy_boosting_players SET crypto=GREATEST(crypto-?,0) WHERE identifier=?',{tonumber(data.amount) or 0,id}) end
    if action=='add_xp' then DB.update('UPDATE tommy_boosting_players SET xp=xp+? WHERE identifier=?',{tonumber(data.amount) or 0,id}) end
    if action=='remove_xp' then DB.update('UPDATE tommy_boosting_players SET xp=GREATEST(xp-?,0) WHERE identifier=?',{tonumber(data.amount) or 0,id}) end
    if action=='set_xp' then DB.update('UPDATE tommy_boosting_players SET xp=? WHERE identifier=?',{tonumber(data.amount) or 0,id}) end
    DB.update('INSERT INTO tommy_boosting_admin_logs (admin_identifier,admin_name,action,target_identifier,details) VALUES (?,?,?,?,?)',{Bridge.GetIdentifier(src),Bridge.GetPlayerName(src),action,id or '',json.encode(data or {})})
    return {ok=true}
end)
lib.callback.register('tommy_boosting:cb:adminGetLogs', function(src)
    if not Bridge.IsAdmin(src) then return {} end
    return DB.query('SELECT * FROM tommy_boosting_admin_logs ORDER BY id DESC LIMIT 100')
end)
