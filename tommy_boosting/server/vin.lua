Vin = {}
function Vin.Scratch(src)
 local id=Bridge.GetIdentifier(src); local c=Contracts.activeByIdentifier[id]; if not c then return false,'No active contract' end
 if not Config.VinScratch.allowedClasses[c.class] then return false,'Class not eligible' end
 local p=DB.single('SELECT * FROM tommy_boosting_players WHERE identifier=?',{id}); if p.crypto < Config.VinScratch.costCrypto then return false,'Not enough crypto' end
 if Config.VinScratch.removeItemOnUse and not Bridge.RemoveItem(src,Config.VinScratch.requiredItem,1) then return false,'Missing item' end
 DB.update('UPDATE tommy_boosting_players SET crypto = crypto - ? WHERE identifier=?',{Config.VinScratch.costCrypto,id})
 DB.update('UPDATE tommy_boosting_contracts SET vin_scratched=1,status=? WHERE contract_id=?',{Config.VinScratch.completeStatus,c.contract_id})
 return true,c
end
