Contracts = { available = {}, activeByIdentifier = {}, cooldowns = {} }

local function getClassCooldownMinutes(class)
    local cfg = Config.Classes[class]
    return cfg and (cfg.cooldown or 0) or 0
end

local function onCooldown(identifier)
    local untilTs = Contracts.cooldowns[identifier]
    return untilTs and untilTs > os.time()
end

local function mkContract(identifier, class)
    local cfg = Config.Classes[class]
    local zone = Utils.RandomFrom(Config.SearchZones)
    local drop = Utils.RandomFrom(Config.Dropoffs)
    local now = os.time()
    return {
        contract_id = ('tb-%s-%d'):format(identifier:gsub(':', ''), now + math.random(1000, 9999)),
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
        has_tracker = cfg.tracker and 1 or 0,
        has_guards = cfg.guards and 1 or 0,
        is_locked = cfg.locked and 1 or 0,
        requires_partner = cfg.requiresPartner and 1 or 0,
        expires_at = os.date('%Y-%m-%d %H:%M:%S', now + (Config.ContractExpireMinutes * 60)),
        zone = zone,
        drop = drop
    }
end

function Contracts.GenerateForPlayer(src, forcedClass)
    local identifier = Bridge.GetIdentifier(src)
    if not identifier then return {} end
    local profile = DB.single('SELECT * FROM tommy_boosting_players WHERE identifier=?', { identifier })
    if not profile then return {} end

    Contracts.available[identifier] = {}
    for _ = 1, Config.MaxAvailableContracts do
        local class = forcedClass
        if not class then
            local choices = {}
            for classId, cfg in pairs(Config.Classes) do
                if profile.level >= cfg.levelRequired then choices[#choices + 1] = classId end
            end
            class = #choices > 0 and Utils.RandomFrom(choices) or 'D'
        end
        Contracts.available[identifier][#Contracts.available[identifier] + 1] = mkContract(identifier, class)
    end

    return Contracts.available[identifier]
end

function Contracts.GetActive(src)
    return Contracts.activeByIdentifier[Bridge.GetIdentifier(src)]
end

function Contracts.Accept(src, idx)
    local identifier = Bridge.GetIdentifier(src)
    if not identifier then return false, 'Invalid identity' end
    if Contracts.activeByIdentifier[identifier] then return false, 'You already have an active contract' end
    if onCooldown(identifier) then return false, 'You are on cooldown' end

    local profile = DB.single('SELECT * FROM tommy_boosting_players WHERE identifier=?', { identifier })
    if not profile then return false, 'Profile missing' end

    local list = Contracts.available[identifier] or Contracts.GenerateForPlayer(src)
    local contract = list[tonumber(idx or 0)]
    if not contract then return false, 'Invalid contract' end

    local classCfg = Config.Classes[contract.class]
    if not classCfg then return false, 'Invalid class' end
    if profile.level < classCfg.levelRequired then
        Security.LogExploitAttempt(src, 'accept_above_level', contract)
        return false, 'Level too low'
    end

    contract.status = 'accepted'
    contract.accepted_at = os.date('%Y-%m-%d %H:%M:%S')
    Contracts.activeByIdentifier[identifier] = contract

    DB.update('INSERT INTO tommy_boosting_contracts (contract_id, owner_identifier, assigned_identifier, class, vehicle_model, plate, search_zone, dropoff, cash_reward, crypto_reward, xp_reward, status, requires_hacking, has_tracker, has_guards, is_locked, requires_partner, expires_at, accepted_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)', {
        contract.contract_id, identifier, identifier, contract.class, contract.vehicle_model, contract.plate, contract.search_zone, contract.dropoff, contract.cash_reward, contract.crypto_reward, contract.xp_reward, 'accepted', contract.requires_hacking, contract.has_tracker, contract.has_guards, contract.is_locked, contract.requires_partner, contract.expires_at, contract.accepted_at
    })

    return true, contract
end

function Contracts.Cancel(src)
    local identifier = Bridge.GetIdentifier(src)
    local contract = Contracts.activeByIdentifier[identifier]
    if not contract then return false, 'No active contract' end

    DB.update('UPDATE tommy_boosting_contracts SET status=? WHERE contract_id=?', { 'cancelled', contract.contract_id })
    DB.update('INSERT INTO tommy_boosting_history (contract_id,identifier,class,vehicle_model,plate,status,cash_reward,crypto_reward,xp_reward,failure_reason) VALUES (?,?,?,?,?,?,?,?,?,?)', {
        contract.contract_id, identifier, contract.class, contract.vehicle_model, contract.plate, 'cancelled', contract.cash_reward, contract.crypto_reward, contract.xp_reward, 'Cancelled by player'
    })
    Contracts.activeByIdentifier[identifier] = nil
    Contracts.cooldowns[identifier] = os.time() + (getClassCooldownMinutes(contract.class) * 60)
    return true, 'Cancelled'
end

function Contracts.Complete(src, coords)
    local identifier = Bridge.GetIdentifier(src)
    local contract = Contracts.activeByIdentifier[identifier]
    if not contract then return false, 'No contract' end

    local dropCoords = contract.drop and contract.drop.coords
    if not dropCoords then return false, 'Invalid drop-off' end
    if not coords or not coords.x then return false, 'Invalid coords' end

    local claimed = vec3(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
    local dist = #(claimed - vec3(dropCoords.x, dropCoords.y, dropCoords.z))
    if dist > Config.Security.maxDropoffDistance then
        Security.LogExploitAttempt(src, 'dropoff_too_far', { dist = dist })
        return false, 'Too far from drop-off'
    end

    local ped = GetPlayerPed(src)
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return false, 'You must be inside the target vehicle' end
    if GetVehicleNumberPlateText(veh) ~= contract.plate then return false, 'Wrong vehicle plate' end

    DB.update('UPDATE tommy_boosting_contracts SET status=?, completed_at=NOW() WHERE contract_id=? AND status=?', { 'delivered', contract.contract_id, 'accepted' })
    DB.update('INSERT INTO tommy_boosting_history (contract_id,identifier,class,vehicle_model,plate,status,cash_reward,crypto_reward,xp_reward) VALUES (?,?,?,?,?,?,?,?,?)', {
        contract.contract_id, identifier, contract.class, contract.vehicle_model, contract.plate, 'delivered', contract.cash_reward, contract.crypto_reward, contract.xp_reward
    })

    Rewards.Give(src, { identifier = identifier }, contract)
    Contracts.activeByIdentifier[identifier] = nil
    Contracts.cooldowns[identifier] = os.time() + (getClassCooldownMinutes(contract.class) * 60)
    return true, contract
end

function Contracts.CleanupPlayer(identifier)
    Contracts.available[identifier] = Contracts.available[identifier] or nil
end
