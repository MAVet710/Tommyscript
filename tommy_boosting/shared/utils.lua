Utils = {}
function Utils.Debug(...) if Config.Debug then print('^3[Tommy Boosting]^7', ...) end end
function Utils.RandomBetween(tbl) return math.random(tbl.min, tbl.max) end
function Utils.RandomFrom(list) return list[math.random(1,#list)] end
function Utils.GeneratePlate() return ('TB%04d'):format(math.random(1000,9999)) end
function Utils.CalcLevel(xp) local lvl=1 for k,v in pairs(Config.Levels) do if xp>=v and k>lvl then lvl=k end end return lvl end
