Store = {stock={}}
CreateThread(function() for _,i in ipairs(Config.Store.items) do Store.stock[i.item]=i.stock end end)
function Store.Buy(src,item)
 if not Config.Store.enabled then return false,'Store disabled' end
 local id=Bridge.GetIdentifier(src)
 local cfg=nil for _,i in ipairs(Config.Store.items) do if i.item==item then cfg=i break end end; if not cfg then return false,'Invalid item' end
 local stock = Store.stock[item]
 if stock == nil then stock = cfg.stock end
 if stock ~= -1 and stock <= 0 then return false,'Out of stock' end

 local paid = DB.update('UPDATE tommy_boosting_players SET crypto = crypto - ? WHERE identifier = ? AND crypto >= ?', {cfg.price,id,cfg.price})
 if not paid or paid < 1 then return false,'Not enough crypto' end

 if not Bridge.AddItem(src,item,1,{source='tommy_boosting'}) then
    DB.update('UPDATE tommy_boosting_players SET crypto = crypto + ? WHERE identifier=?',{cfg.price,id})
    return false,'Inventory full'
 end

 if stock ~= -1 then Store.stock[item] = math.max((stock or 0) - 1, 0) end
 DB.update('INSERT INTO tommy_boosting_store_purchases (identifier,item,label,price) VALUES (?,?,?,?)',{id,item,cfg.label,cfg.price})
 return true
end
