Guards = Guards or {}

local function loadModel(model)
    local hash = type(model) == 'string' and joaat(model) or model
    RequestModel(hash)
    local timeout = GetGameTimer() + 3000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do Wait(10) end
    return HasModelLoaded(hash), hash
end

function Guards.Clear()
    for _, ped in ipairs(LocalState.guards or {}) do if DoesEntityExist(ped) then DeleteEntity(ped) end end
    LocalState.guards = {}
end

function Guards.Spawn(contract, vehicle)
    Guards.Clear()
    if not contract or contract.has_guards ~= 1 or not Config.Guards.enabled then return end
    local count = (Config.Guards.countByClass or {})[contract.class] or 0
    if count <= 0 then return end
    local vcoords = GetEntityCoords(vehicle)
    for i=1,count do
        local mdl = Utils.RandomFrom(Config.Guards.models)
        local ok, hash = loadModel(mdl)
        if ok then
            local ped = CreatePed(4, hash, vcoords.x + math.random(-8,8), vcoords.y + math.random(-8,8), vcoords.z, math.random(0,360)+0.0, true, true)
            local weapon = Utils.RandomFrom(Config.Guards.weapons)
            GiveWeaponToPed(ped, joaat(weapon), 200, false, true)
            SetPedArmour(ped, Config.Guards.armor or 25)
            SetPedAccuracy(ped, Config.Guards.accuracy or 35)
            SetPedAsEnemy(ped, true)
            SetPedRelationshipGroupHash(ped, joaat('HATES_PLAYER'))
            LocalState.guards[#LocalState.guards+1] = ped
        end
    end
end

function Guards.SetHostile()
    local player = PlayerPedId()
    for _, ped in ipairs(LocalState.guards or {}) do
        if DoesEntityExist(ped) then TaskCombatPed(ped, player, 0, 16) end
    end
end

CreateThread(function()
    while true do
        Wait(500)
        local c = LocalState.activeContract
        if c and LocalState.spawnedVehicle and DoesEntityExist(LocalState.spawnedVehicle) and #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(LocalState.spawnedVehicle)) < 25.0 then
            Guards.SetHostile()
        end
    end
end)

RegisterNetEvent('tommy_boosting:client:guardsCleanup', Guards.Clear)
RegisterNetEvent('tommy_boosting:client:contractEnded', Guards.Clear)
RegisterNetEvent('tommy_boosting:client:contractCompleted', Guards.Clear)
