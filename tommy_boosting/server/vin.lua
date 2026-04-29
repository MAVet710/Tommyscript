Vin = {}
function Vin.CanScratch(src)
    local id = Bridge.GetIdentifier(src)
    local c = Contracts.activeByIdentifier[id]
    return c and Config.VinScratch.allowedClasses[c.class]
end

function Vin.Scratch(src, netId, plate, model)
    local id=Bridge.GetIdentifier(src); local c=Contracts.activeByIdentifier[id]; if not c then return false,'No active contract' end
    if not Config.VinScratch.allowedClasses[c.class] then return false,'Class not eligible' end
    if c.status == Config.VinScratch.completeStatus then return false, 'Already VIN scratched' end
    if Config.VinScratch.requiredItem and not Bridge.HasItem(src, Config.VinScratch.requiredItem, 1) then return false, 'Missing item' end

    local ped = GetPlayerPed(src); local veh = NetToVeh(netId or 0)
    if veh == 0 then veh = GetVehiclePedIsIn(ped, false) end
    if veh == 0 then return false, 'No vehicle' end
    local vPlate = tostring(GetVehicleNumberPlateText(veh)):gsub('%s+','')
    local cPlate = tostring(c.plate):gsub('%s+','')
    if vPlate ~= cPlate and tostring(plate or ''):gsub('%s+','') ~= cPlate then return false,'Plate mismatch' end
    if model and tonumber(model) ~= GetEntityModel(veh) then return false, 'Model mismatch' end

    local affected = DB.update("UPDATE tommy_boosting_contracts SET vin_scratched=1,status=?, completed_at=NOW() WHERE contract_id=? AND assigned_identifier=? AND status IN ('accepted','in_progress')",{Config.VinScratch.completeStatus,c.contract_id,id})
    if not affected or affected < 1 then return false, 'Contract already closed' end

    local paid = DB.update('UPDATE tommy_boosting_players SET crypto = crypto - ? WHERE identifier = ? AND crypto >= ?',{Config.VinScratch.costCrypto,id,Config.VinScratch.costCrypto})
    if not paid or paid < 1 then return false,'Not enough crypto' end
    if Config.VinScratch.removeItemOnUse and not Bridge.RemoveItem(src, Config.VinScratch.requiredItem, 1) then
        DB.update('UPDATE tommy_boosting_players SET crypto = crypto + ? WHERE identifier=?',{Config.VinScratch.costCrypto,id})
        return false, 'Failed to consume VIN item'
    end

    if Config.VinScratch.saveToPlayerVehicles then pcall(function() end) end
    DB.update('INSERT INTO tommy_boosting_history (contract_id,identifier,class,vehicle_model,plate,status,cash_reward,crypto_reward,xp_reward) VALUES (?,?,?,?,?,?,?,?,?)',{c.contract_id,id,c.class,c.vehicle_model,c.plate,Config.VinScratch.completeStatus,0,0,0})
    Contracts.activeByIdentifier[id]=nil
    Dispatch.StopTrackerLoop(id)
    TriggerClientEvent('tommy_boosting:client:contractEnded', src)
    return true,'VIN scratched, contract closed.'
end
