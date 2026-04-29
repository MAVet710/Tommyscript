Contracts = { available = {}, activeByIdentifier = {}, cooldowns = {} }

local function mkContract(identifier, class)
    local cfg = Config.Classes[class]
    local zone = Utils.RandomFrom(Config.SearchZones)
    local drop = Utils.RandomFrom(Config.Dropoffs)
    return {
        contract_id = ('tb-%s-%d'):format(identifier, os.time() + math.random(999)),
        owner_identifier = identifier,
        assigned_identifier = identifier,
        class = class,
        vehicle_model = Utils.RandomFrom(cfg.vehicles),
        plate = Utils.GeneratePlate(),
        search_zone = zone.label,
        dropoff = drop.label,
        cash_reward = Utils.RandomBetween(cfg.cashReward),
        crypto_reward = Utils.RandomBetween(cfg.cryptoReward),
        xp_reward = Utils.RandomBetween(cfg.xpReward),
        status = 'available',
        requires_hacking = cfg.hacking and 1 or 0,
        hack_completed = 0,
        hack_attempts_used = 0,
        has_tracker = cfg.tracker and 1 or 0,
        tracker_removed = 0,
        expires_at = os.date('%Y-%m-%d %H:%M:%S', os.time() + Config.ContractExpireMinutes * 60),
        zone = zone,
        drop = drop
    }
end
function Contracts.GenerateForPlayer(src, forcedClass) -- unchanged logic
 local id=Bridge.GetIdentifier(src); local p=DB.single('SELECT * FROM tommy_boosting_players WHERE identifier=?',{id}); if not p then return {} end
 Contracts.available[id]={}
 for i=1,Config.MaxAvailableContracts do
  local pick=forcedClass or 'D'; if not forcedClass then local choices={} for cls,cfg in pairs(Config.Classes) do if p.level>=cfg.levelRequired then choices[#choices+1]=cls end end pick=Utils.RandomFrom(choices) end
  Contracts.available[id][#Contracts.available[id]+1]=mkContract(id,pick)
 end
 return Contracts.available[id]
end
function Contracts.Accept(src, idx)
    local id = Bridge.GetIdentifier(src)
    if Contracts.activeByIdentifier[id] then return false, 'Already active' end
    local list = Contracts.available[id] or Contracts.GenerateForPlayer(src)
    local contract = list[tonumber(idx or 0)]
    if not contract then return false, 'Invalid contract' end
    contract.status = 'accepted'
    contract.accepted_at = os.date('%Y-%m-%d %H:%M:%S')
    Contracts.activeByIdentifier[id] = contract
    DB.update('INSERT INTO tommy_boosting_contracts (contract_id, owner_identifier, assigned_identifier, class, vehicle_model, plate, search_zone, dropoff, cash_reward, crypto_reward, xp_reward, status, requires_hacking, hack_completed, hack_attempts_used, has_tracker, tracker_removed, expires_at, accepted_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)', {contract.contract_id,id,id,contract.class,contract.vehicle_model,contract.plate,contract.search_zone,contract.dropoff,contract.cash_reward,contract.crypto_reward,contract.xp_reward,'accepted',contract.requires_hacking,0,0,contract.has_tracker,0,contract.expires_at,contract.accepted_at})
    return true, contract
end
function Contracts.GetActive(src) return Contracts.activeByIdentifier[Bridge.GetIdentifier(src)] end
function Contracts.CanStartHack(src) local c=Contracts.GetActive(src); return c and c.requires_hacking==1 and c.hack_completed==0 end
function Contracts.CanRemoveTracker(src) local c=Contracts.GetActive(src); return c and c.has_tracker==1 and c.tracker_removed==0 end

function Contracts.Complete(src, netId, coords)
    local id = Bridge.GetIdentifier(src)
    local c = Contracts.activeByIdentifier[id]
    if not c then return false, 'No contract' end
    if c.requires_hacking == 1 and c.hack_completed ~= 1 then return false, 'Hack required first' end
    if c.has_tracker == 1 and Config.Tracker.allowRemoval and c.tracker_removed ~= 1 then return false, 'Remove tracker first' end
    if not Security.ValidateDistance(src, vec3(coords.x, coords.y, coords.z), Config.Security.maxDropoffDistance) then return false, 'Too far from dropoff' end
    local ped = GetPlayerPed(src); local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return false, 'Must be in vehicle' end
    if tostring(GetVehicleNumberPlateText(veh)):gsub('%s+','') ~= tostring(c.plate):gsub('%s+','') then return false, 'Wrong vehicle plate' end
    if string.lower(GetDisplayNameFromVehicleModel(GetEntityModel(veh))) ~= string.lower(c.vehicle_model) then return false, 'Wrong vehicle model' end
    local body = GetVehicleBodyHealth(veh)
    if body < (Config.Classes[c.class].vehicleHealthRequired or 0) then return false, 'Vehicle too damaged' end

    local affected = DB.update("UPDATE tommy_boosting_contracts SET status='delivered', completed_at=NOW() WHERE contract_id=? AND status IN ('accepted','in_progress')", { c.contract_id })
    if not affected or affected < 1 then return false, 'Already completed' end

    DB.update('INSERT INTO tommy_boosting_history (contract_id,identifier,class,vehicle_model,plate,status,cash_reward,crypto_reward,xp_reward) VALUES (?,?,?,?,?,?,?,?,?)', {c.contract_id,id,c.class,c.vehicle_model,c.plate,'delivered',c.cash_reward,c.crypto_reward,c.xp_reward})
    Rewards.Give(src, { identifier = id }, c)
    Contracts.activeByIdentifier[id] = nil
    return true, c
end
