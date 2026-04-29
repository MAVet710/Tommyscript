Contracts = Contracts or { available = {}, activeByIdentifier = {}, cooldowns = {}, trackerThreads = {} }

local function classCfg(class) return Config.Classes[class] end
local function cooldownLeft(id) return math.max(0, (Contracts.cooldowns[id] or 0) - os.time()) end

local function startTrackerPing(src, identifier)
    if Contracts.trackerThreads[identifier] then return end
    Contracts.trackerThreads[identifier] = true
    CreateThread(function()
        while Contracts.trackerThreads[identifier] do
            Wait(5000)
            local c = Contracts.activeByIdentifier[identifier]
            if not c or c.has_tracker ~= 1 or c.tracker_removed == 1 then break end
            local playerSrc = tonumber(src)
            if playerSrc and GetPlayerPed(playerSrc) ~= 0 then
                local coords = GetEntityCoords(GetPlayerPed(playerSrc))
                if Config.CustomDispatchAlert then Config.CustomDispatchAlert(coords, {model=c.vehicle_model,plate=c.plate}, c.class, 'Tracker ping') end
            end
            Wait((Config.Tracker.pingIntervalSeconds[c.class] or 60) * 1000)
        end
        Contracts.trackerThreads[identifier] = nil
    end)
end

local function stopTrackerPing(identifier) Contracts.trackerThreads[identifier] = nil end

function Contracts.Accept(src, idx)
    local id = Bridge.GetIdentifier(src); if not id then return false,'Invalid identity' end
    local p = DB.single('SELECT * FROM tommy_boosting_players WHERE identifier=?',{id}); if not p then return false,'Profile missing' end
    if Contracts.activeByIdentifier[id] then return false,'Already active' end
    if cooldownLeft(id) > 0 then return false,('Cooldown %ss'):format(cooldownLeft(id)) end
    local list = Contracts.available[id] or Contracts.GenerateForPlayer(src)
    local c = list[tonumber(idx or 0)]; if not c then return false,'Invalid contract' end
    if p.level < classCfg(c.class).levelRequired then return false,'Level too low' end
    c.status='accepted'; c.hack_completed=0; c.hack_attempts_used=0; c.tracker_removed=0
    Contracts.activeByIdentifier[id]=c; list[tonumber(idx)] = nil
    DB.update('INSERT INTO tommy_boosting_contracts (contract_id,owner_identifier,assigned_identifier,class,vehicle_model,plate,search_zone,dropoff,cash_reward,crypto_reward,xp_reward,status,requires_hacking,has_tracker,tracker_removed,has_guards,is_locked,requires_partner,hack_completed,hack_attempts_used,expires_at,accepted_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,NOW())',{c.contract_id,id,id,c.class,c.vehicle_model,c.plate,c.search_zone,c.dropoff,c.cash_reward,c.crypto_reward,c.xp_reward,'accepted',c.requires_hacking,c.has_tracker,0,c.has_guards,c.is_locked,c.requires_partner,0,0,c.expires_at})
    if c.has_tracker == 1 then startTrackerPing(src,id) end
    return true,c
end

function Contracts.MarkHack(src, success)
    local id=Bridge.GetIdentifier(src); local c=Contracts.activeByIdentifier[id]; if not c then return false,'No active contract' end
    if c.requires_hacking ~= 1 then return false,'No hack required' end
    if success then c.hack_completed=1; DB.update('UPDATE tommy_boosting_contracts SET hack_completed=1 WHERE contract_id=?',{c.contract_id}); return true,'Hack completed' end
    c.hack_attempts_used=(c.hack_attempts_used or 0)+1
    DB.update('UPDATE tommy_boosting_contracts SET hack_attempts_used=? WHERE contract_id=?',{c.hack_attempts_used,c.contract_id})
    if c.hack_attempts_used >= (Config.Hacking.attempts or 3) then
      c.status='failed'; DB.update('UPDATE tommy_boosting_contracts SET status=?, failure_reason=? WHERE contract_id=?',{'failed','Hack attempts exceeded',c.contract_id});
      DB.update('INSERT INTO tommy_boosting_history (contract_id,identifier,class,vehicle_model,plate,status,cash_reward,crypto_reward,xp_reward,failure_reason) VALUES (?,?,?,?,?,?,?,?,?,?)',{c.contract_id,id,c.class,c.vehicle_model,c.plate,'failed',c.cash_reward,c.crypto_reward,c.xp_reward,'Hack attempts exceeded'})
      Contracts.activeByIdentifier[id]=nil; stopTrackerPing(id); return false,'Contract failed: hacking attempts exceeded'
    end
    return false,('Hack failed (%d/%d)'):format(c.hack_attempts_used, Config.Hacking.attempts or 3)
end

function Contracts.RemoveTracker(src, success)
    local id=Bridge.GetIdentifier(src); local c=Contracts.activeByIdentifier[id]; if not c then return false,'No active contract' end
    if c.has_tracker ~= 1 then return false,'No tracker on contract' end
    if not success then return false,'Removal failed' end
    if Config.Tracker.removeRequiresItem and not Bridge.RemoveItem(src, Config.Tracker.item, 1) then return false,'Missing tracker remover' end
    c.tracker_removed=1; DB.update('UPDATE tommy_boosting_contracts SET tracker_removed=1 WHERE contract_id=?',{c.contract_id}); stopTrackerPing(id); return true,'Tracker removed'
end

function Contracts.Complete(src, coords)
    local id=Bridge.GetIdentifier(src); local c=Contracts.activeByIdentifier[id]; if not c then return false,'No contract' end
    if c.requires_hacking==1 and c.hack_completed~=1 then return false,'Hack not completed' end
    local ped=GetPlayerPed(src); local veh=GetVehiclePedIsIn(ped,false); if veh==0 then return false,'Not in vehicle' end
    if GetVehicleNumberPlateText(veh) ~= c.plate then return false,'Wrong vehicle' end
    if string.lower(GetDisplayNameFromVehicleModel(GetEntityModel(veh))) ~= string.lower(c.vehicle_model) then return false,'Wrong vehicle model' end
    local drop = c.drop and c.drop.coords; if not drop then return false,'Dropoff missing' end
    local dist = #(vec3(coords.x,coords.y,coords.z)-vec3(drop.x,drop.y,drop.z)); if dist > Config.Security.maxDropoffDistance then return false,'Too far' end
    if GetVehicleEngineHealth(veh) < (classCfg(c.class).vehicleHealthRequired or 0) then return false,'Vehicle too damaged' end
    local rows = DB.update('UPDATE tommy_boosting_contracts SET status=?, completed_at=NOW() WHERE contract_id=? AND status IN (?,?)',{'delivered',c.contract_id,'accepted','in_progress'})
    if not rows or rows < 1 then return false,'Already processed' end
    DB.update('INSERT INTO tommy_boosting_history (contract_id,identifier,class,vehicle_model,plate,status,cash_reward,crypto_reward,xp_reward) VALUES (?,?,?,?,?,?,?,?,?)',{c.contract_id,id,c.class,c.vehicle_model,c.plate,'delivered',c.cash_reward,c.crypto_reward,c.xp_reward})
    Rewards.Give(src,{identifier=id},c); Contracts.activeByIdentifier[id]=nil; Contracts.cooldowns[id]=os.time()+((classCfg(c.class).cooldown or 0)*60); stopTrackerPing(id)
    return true,c
end

function Contracts.Cancel(src)
 local id=Bridge.GetIdentifier(src); local c=Contracts.activeByIdentifier[id]; if not c then return false,'No active contract' end
 DB.update('UPDATE tommy_boosting_contracts SET status=? WHERE contract_id=?',{'cancelled',c.contract_id}); Contracts.activeByIdentifier[id]=nil; stopTrackerPing(id); return true,'Cancelled'
end

function Contracts.GenerateForPlayer(src, forcedClass)
    local identifier = Bridge.GetIdentifier(src); local p=DB.single('SELECT level FROM tommy_boosting_players WHERE identifier=?',{identifier}); if not p then return {} end
    Contracts.available[identifier]={}
    for i=1,Config.MaxAvailableContracts do
      local pick=forcedClass; if not pick then local opts={} for cls,cfg in pairs(Config.Classes) do if p.level>=cfg.levelRequired then opts[#opts+1]=cls end end pick=opts[math.random(1,#opts)] end
      local cfg=classCfg(pick); local zone=Config.SearchZones[math.random(1,#Config.SearchZones)]; local drop=Config.Dropoffs[math.random(1,#Config.Dropoffs)]
      Contracts.available[identifier][i]={contract_id=('tb-%s-%d'):format(identifier:gsub(':',''), os.time()+i),class=pick,vehicle_model=cfg.vehicles[math.random(1,#cfg.vehicles)],plate=Utils.GeneratePlate(),search_zone=zone.label,dropoff=drop.label,cash_reward=Utils.RandomBetween(cfg.cashReward),crypto_reward=Utils.RandomBetween(cfg.cryptoReward),xp_reward=Utils.RandomBetween(cfg.xpReward),status='available',requires_hacking=cfg.hacking and 1 or 0,has_tracker=cfg.tracker and 1 or 0,has_guards=cfg.guards and 1 or 0,is_locked=cfg.locked and 1 or 0,requires_partner=cfg.requiresPartner and 1 or 0,expires_at=os.date('%Y-%m-%d %H:%M:%S', os.time()+Config.ContractExpireMinutes*60),zone=zone,drop=drop}
    end
    return Contracts.available[identifier]
end

function Contracts.GetActive(src) return Contracts.activeByIdentifier[Bridge.GetIdentifier(src)] end
function Contracts.CleanupPlayer(identifier) stopTrackerPing(identifier) end
