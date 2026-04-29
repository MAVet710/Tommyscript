Vin = {}
function Vin.CanScratch(src)
    local id = Bridge.GetIdentifier(src)
    local c = Contracts.activeByIdentifier[id]
    return c and Config.VinScratch.allowedClasses[c.class]
end

function Vin.Scratch(src, netId, plate, model)
    local id=Bridge.GetIdentifier(src); local c=Contracts.activeByIdentifier[id]; if not c then return false,'No active contract' end
    if not Config.VinScratch.allowedClasses[c.class] then return false,'Class not eligible' end
    if Config.VinScratch.requiredItem and not Bridge.HasItem(src, Config.VinScratch.requiredItem, 1) then return false, 'Missing item' end
    local p=DB.single('SELECT * FROM tommy_boosting_players WHERE identifier=?',{id}); if not p or p.crypto < Config.VinScratch.costCrypto then return false,'Not enough crypto' end

    local ped = GetPlayerPed(src); local veh = NetToVeh(netId or 0)
    if veh == 0 then veh = GetVehiclePedIsIn(ped, false) end
    if veh == 0 then return false, 'No vehicle' end
    local vPlate = tostring(GetVehicleNumberPlateText(veh)):gsub('%s+','')
    local cPlate = tostring(c.plate):gsub('%s+','')
    if vPlate ~= cPlate and tostring(plate or ''):gsub('%s+','') ~= cPlate then return false,'Plate mismatch' end
    if model and tonumber(model) ~= GetEntityModel(veh) then return false, 'Model mismatch' end

    DB.update('UPDATE tommy_boosting_players SET crypto = crypto - ? WHERE identifier=?',{Config.VinScratch.costCrypto,id})
    if Config.VinScratch.removeItemOnUse then Bridge.RemoveItem(src, Config.VinScratch.requiredItem, 1) end
    DB.update('UPDATE tommy_boosting_contracts SET vin_scratched=1,status=?, completed_at=NOW() WHERE contract_id=? AND status IN (\'accepted\',\'in_progress\')',{Config.VinScratch.completeStatus,c.contract_id})

    if Config.VinScratch.saveToPlayerVehicles then
        local props = json.encode({ plate = vPlate, model = GetEntityModel(veh) })
        local fw = Bridge.GetFramework()
        if fw == 'qb' then
            local ok, err = pcall(function()
                DB.update('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state) VALUES (?,?,?,?,?,?,?)', {id, id, c.vehicle_model, GetEntityModel(veh), props, vPlate, 0})
            end)
            if not ok then Utils.Debug('VIN save QBCore skipped', err) end
        elseif fw == 'esx' then
            local ok, err = pcall(function()
                DB.update('INSERT INTO owned_vehicles (owner, plate, vehicle, type, stored) VALUES (?,?,?,?,?)', {id, vPlate, props, 'car', 1})
            end)
            if not ok then Utils.Debug('VIN save ESX skipped', err) end
        else
            Utils.Debug('VIN save skipped: unsupported framework')
        end
    end

    DB.update('INSERT INTO tommy_boosting_history (contract_id,identifier,class,vehicle_model,plate,status,cash_reward,crypto_reward,xp_reward) VALUES (?,?,?,?,?,?,?,?,?)',{c.contract_id,id,c.class,c.vehicle_model,c.plate,Config.VinScratch.completeStatus,0,0,0})
    Contracts.activeByIdentifier[id]=nil
    return true,'VIN scratched, contract closed.'
end
