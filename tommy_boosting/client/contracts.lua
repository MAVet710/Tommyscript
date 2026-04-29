RegisterNetEvent('tommy_boosting:client:startContract', function(contract)
 local s=contract.zone.spawns[math.random(1,#contract.zone.spawns)]; local model=joaat(contract.vehicle_model); RequestModel(model); while not HasModelLoaded(model) do Wait(0) end
 local v=CreateVehicle(model,s.x,s.y,s.z,s.w,true,true); SetVehicleNumberPlateText(v,contract.plate)
 if contract.is_locked==1 and contract.requires_hacking==1 and contract.hack_completed~=1 then SetVehicleDoorsLocked(v,2) else SetVehicleDoorsLocked(v,1) end
 LocalState.spawnedVehicle=v
 if Guards and Guards.Spawn then Guards.Spawn(contract, v) end
 local b=AddBlipForRadius(contract.zone.center.x,contract.zone.center.y,contract.zone.center.z,contract.zone.radius); SetBlipColour(b,1); SetBlipAlpha(b,120); LocalState.blips.search=b
end)

RegisterNetEvent('tommy_boosting:client:hackUpdated', function(success, attemptsUsed)
    if LocalState.activeContract then
        if success then
            LocalState.activeContract.hack_completed = 1
            if LocalState.spawnedVehicle and DoesEntityExist(LocalState.spawnedVehicle) then SetVehicleDoorsLocked(LocalState.spawnedVehicle, 1) end
        end
        LocalState.activeContract.hack_attempts_used = attemptsUsed or 0
    end
end)

CreateThread(function() while true do Wait(0) local c=LocalState.activeContract if c and LocalState.spawnedVehicle and DoesEntityExist(LocalState.spawnedVehicle) then local d= #(GetEntityCoords(PlayerPedId())-vector3(c.drop.coords.x,c.drop.coords.y,c.drop.coords.z)); if d<25 then DrawMarker(1,c.drop.coords.x,c.drop.coords.y,c.drop.coords.z-1.0,0,0,0,0,0,0,2.0,2.0,0.5,255,120,0,200,false,false,2) end if c.requires_hacking~=1 and c.is_locked==1 then SetVehicleDoorsLocked(LocalState.spawnedVehicle,1) end end end end)
RegisterNetEvent('tommy_boosting:client:contractCompleted', function() if LocalState.spawnedVehicle and DoesEntityExist(LocalState.spawnedVehicle) then DeleteEntity(LocalState.spawnedVehicle) end for _,b in pairs(LocalState.blips) do RemoveBlip(b) end LocalState.blips={}; LocalState.activeContract=nil end)
