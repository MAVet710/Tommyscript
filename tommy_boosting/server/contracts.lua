Contracts = { available = {}, activeByIdentifier = {}, cooldowns = {} }

local function getDropByLabel(label)
    for _, drop in ipairs(Config.Dropoffs or {}) do
        if drop.label == label then return drop end
    end
end

local function mkContract(identifier, class)
    local cfg = Config.Classes[class]
    local zone = Utils.RandomFrom(Config.SearchZones)
    local drop = Utils.RandomFrom(Config.Dropoffs)
    local vehicleModel = Utils.RandomFrom(cfg.vehicles)
    return {
        contract_id = ('tb-%s-%d'):format(identifier, os.time() + math.random(999)), owner_identifier = identifier, assigned_identifier = identifier,
        class = class, vehicle_model = vehicleModel, vehicle_model_hash = joaat(vehicleModel),
        plate = Utils.GeneratePlate(), search_zone = zone.label, dropoff = drop.label, cash_reward = Utils.RandomBetween(cfg.cashReward),
        crypto_reward = Utils.RandomBetween(cfg.cryptoReward), xp_reward = Utils.RandomBetween(cfg.xpReward), status = 'available',
        requires_hacking = cfg.hacking and 1 or 0, hack_completed = 0, hack_attempts_used = 0, has_tracker = cfg.tracker and 1 or 0,
        tracker_removed = 0, has_guards = cfg.guards and 1 or 0, is_locked = cfg.locked and 1 or 0, requires_partner = cfg.requiresPartner and 1 or 0, vehicle_health_required = cfg.vehicleHealthRequired or 0, expires_at = os.date('%Y-%m-%d %H:%M:%S', os.time() + Config.ContractExpireMinutes * 60), metadata = { vehicle_model_hash = joaat(vehicleModel), requires_hacking = cfg.hacking and 1 or 0, has_tracker = cfg.tracker and 1 or 0, has_guards = cfg.guards and 1 or 0, is_locked = cfg.locked and 1 or 0, requires_partner = cfg.requiresPartner and 1 or 0, vehicle_health_required = cfg.vehicleHealthRequired or 0 }, zone = zone, drop = drop
    }
end

function Contracts.GenerateForPlayer(src, forcedClass)
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
    local profile = DB.single('SELECT * FROM tommy_boosting_players WHERE identifier=?', { id })
    if not profile then return false, 'Profile missing' end
    local active = Contracts.activeByIdentifier[id]
    if active then return false, 'Already active' end
    local list = Contracts.available[id] or Contracts.GenerateForPlayer(src)
    local contract = list[tonumber(idx or 0)]
    if not contract or contract.owner_identifier ~= id then return false, 'Invalid contract' end
    local cfg = Config.Classes[contract.class]
    if not cfg then return false, 'Invalid class' end
    if profile.level < (cfg.levelRequired or 1) then return false, 'Level too low' end
    local cd = Contracts.cooldowns[id]
    if cd and cd > os.time() then return false, 'On cooldown' end
    if contract.expires_at and contract.expires_at < os.date('%Y-%m-%d %H:%M:%S') then return false, 'Contract expired' end

    contract.status = 'accepted'; contract.accepted_at = os.date('%Y-%m-%d %H:%M:%S')
    Contracts.activeByIdentifier[id] = contract
    table.remove(list, tonumber(idx))
    DB.update('INSERT INTO tommy_boosting_contracts (contract_id, owner_identifier, assigned_identifier, class, vehicle_model, plate, search_zone, dropoff, cash_reward, crypto_reward, xp_reward, status, requires_hacking, hack_completed, hack_attempts_used, has_tracker, tracker_removed, has_guards, is_locked, requires_partner, expires_at, accepted_at, metadata) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
      {contract.contract_id,id,id,contract.class,contract.vehicle_model,contract.plate,contract.search_zone,contract.dropoff,contract.cash_reward,contract.crypto_reward,contract.xp_reward,'accepted',contract.requires_hacking,0,0,contract.has_tracker,0,contract.has_guards,contract.is_locked,contract.requires_partner,contract.expires_at,contract.accepted_at,json.encode(contract.metadata or {vehicle_model_hash=contract.vehicle_model_hash})})
    return true, contract
end
function Contracts.GetActive(src) return Contracts.activeByIdentifier[Bridge.GetIdentifier(src)] end
function Contracts.CanStartHack(src) local c=Contracts.GetActive(src); return c and c.requires_hacking==1 and c.hack_completed==0 end
function Contracts.CanRemoveTracker(src) local c=Contracts.GetActive(src); return c and c.has_tracker==1 and c.tracker_removed==0 end

function Contracts.Complete(src, netId)
    local id = Bridge.GetIdentifier(src)
    local c = Contracts.activeByIdentifier[id]
    if not c or c.assigned_identifier ~= id then return false, 'No contract' end
    if c.status ~= 'accepted' and c.status ~= 'in_progress' then return false, 'Invalid status' end
    if c.requires_hacking == 1 and c.hack_completed ~= 1 then return false, 'Hack required first' end
    if c.has_tracker == 1 and Config.Tracker.allowRemoval and c.tracker_removed ~= 1 then return false, 'Remove tracker first' end
    local drop = c.drop or getDropByLabel(c.dropoff)
    if not drop then return false, 'Dropoff missing' end
    local radius = (drop.radius or 8.0) + (Config.Security.maxDropoffDistance or 15.0)
    if not Security.ValidateDistance(src, drop.coords, radius) then return false, 'Too far from dropoff' end

    local ped = GetPlayerPed(src); local veh = netId and NetToVeh(netId) or 0
    if veh == 0 then veh = GetVehiclePedIsIn(ped, false) end
    if veh == 0 then return false, 'Must be in vehicle' end
    if tostring(GetVehicleNumberPlateText(veh)):gsub('%s+','') ~= tostring(c.plate):gsub('%s+','') then return false, 'Wrong vehicle plate' end
    local expectedHash = tonumber(c.vehicle_model_hash) or joaat(c.vehicle_model)
    if expectedHash ~= GetEntityModel(veh) then return false, 'Wrong vehicle model' end
    if GetVehicleBodyHealth(veh) < (Config.Classes[c.class].vehicleHealthRequired or 0) then return false, 'Vehicle too damaged' end

    local affected = DB.update("UPDATE tommy_boosting_contracts SET status='delivered', completed_at=NOW() WHERE contract_id=? AND assigned_identifier=? AND status IN ('accepted','in_progress')", { c.contract_id, id })
    if not affected or affected < 1 then return false, 'Already completed' end
    Dispatch.StopTrackerLoop(id)
    DB.update('INSERT INTO tommy_boosting_history (contract_id,identifier,class,vehicle_model,plate,status,cash_reward,crypto_reward,xp_reward) VALUES (?,?,?,?,?,?,?,?,?)', {c.contract_id,id,c.class,c.vehicle_model,c.plate,'delivered',c.cash_reward,c.crypto_reward,c.xp_reward})
    Rewards.Give(src, { identifier = id }, c)
    Contracts.activeByIdentifier[id] = nil
    Contracts.cooldowns[id] = os.time() + ((Config.Classes[c.class].cooldown or 5) * 60)
    TriggerClientEvent('tommy_boosting:client:contractEnded', src)
    return true, c
end
