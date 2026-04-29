HackState = {busy=false,lastTry=0}

function StartContractHack()
    local c = LocalState.activeContract
    if not c or c.requires_hacking ~= 1 then return lib.notify({description='No hack required',type='error'}) end
    if HackState.busy or (GetGameTimer()-HackState.lastTry)<3000 then return end
    HackState.busy = true
    HackState.lastTry = GetGameTimer()
    local seq = (Config.Hacking.difficultyByClass[c.class] or {'easy'})
    if not lib.progressBar({duration=3000,label='Bypassing ECU...',canCancel=true}) then HackState.busy=false return end
    local ok = lib.skillCheck(seq, {'w','a','s','d'})
    TriggerServerEvent('tommy_boosting:server:hackResult', ok)
    HackState.busy=false
end

RegisterNUICallback('startHack', function(_, cb) StartContractHack(); cb({ok=true}) end)
RegisterNetEvent('tommy_boosting:client:hackUpdate', function(ok,msg) lib.notify({description=msg or (ok and 'Hack complete' or 'Hack failed'), type=ok and 'success' or 'error'}) end)
