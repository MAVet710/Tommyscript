Admin = {}
function Admin.Log(src,action,target,details)
 DB.update('INSERT INTO tommy_boosting_admin_logs (admin_identifier,admin_name,action,target_identifier,details) VALUES (?,?,?,?,?)',{Bridge.GetIdentifier(src),Bridge.GetPlayerName(src),action,target or '',json.encode(details or {})})
end
function Admin.Require(src) if not Security.IsPlayerAdmin(src) then Security.LogExploitAttempt(src,'admin_access',{}) return false end return true end
