Security = {}
function Security.GetIdentifier(src) return Bridge.GetIdentifier(src) end
function Security.IsPlayerAdmin(src) return Bridge.IsAdmin(src) end
function Security.ValidateDistance(src, coords, maxDistance)
  local ped = GetPlayerPed(src); if ped==0 then return false end
  return #(GetEntityCoords(ped)-coords) <= (maxDistance or Config.Security.maxDropoffDistance)
end
function Security.SanitizeString(input,maxLength)
  local s=tostring(input or ''):gsub('<',''):gsub('>',''):gsub('script','')
  return s:sub(1,maxLength or 255)
end
function Security.LogExploitAttempt(src, reason, data)
  if Config.Security.logExploitAttempts then print(('[Tommy Boosting] exploit %s %s %s'):format(src, reason, json.encode(data or {}))) end
  if Config.Security.dropOnExploit then DropPlayer(src,'Tommy Boosting exploit flagged') end
end
