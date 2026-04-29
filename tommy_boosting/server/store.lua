Store = {stock={}}
CreateThread(function() for _,i in ipairs(Config.Store.items) do Store.stock[i.item]=i.stock end end)
function Store.Buy(src,item)
 local id=Bridge.GetIdentifier(src); local profile=DB.single('SELECT * FROM tommy_boosting_players WHERE identifier=?',{id}); if not profile then return false,'No profile' end
 local cfg=nil for _,i in ipairs(Config.Store.items) do if i.item==item then cfg=i end end; if not cfg then return false,'Invalid item' end
 if (not Config.Store.infiniteStock) and (Store.stock[item] or 0)<=0 then return false,'Out of stock' end
 if profile.crypto < cfg.price then return false,'Not enough crypto' end
 if not Bridge.AddItem(src,item,1,{source='tommy_boosting'}) then return false,'Inventory full' end
 DB.update('UPDATE tommy_boosting_players SET crypto = crypto - ? WHERE identifier=?',{cfg.price,id}); if not Config.Store.infiniteStock then Store.stock[item]=Store.stock[item]-1 end
 DB.update('INSERT INTO tommy_boosting_store_purchases (identifier,item,label,price) VALUES (?,?,?,?)',{id,item,cfg.label,cfg.price}); return true
end
