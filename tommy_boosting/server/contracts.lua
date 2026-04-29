Contracts = {available = {}, activeByIdentifier = {}, cooldowns = {}}
local function mkContract(identifier, class)
 local cfg=Config.Classes[class]; local zone=Utils.RandomFrom(Config.SearchZones); local drop=Utils.RandomFrom(Config.Dropoffs)
 return {contract_id=('tb-%s-%d'):format(identifier, os.time()+math.random(999)),owner_identifier=identifier,assigned_identifier=identifier,class=class,vehicle_model=Utils.RandomFrom(cfg.vehicles),plate=Utils.GeneratePlate(),search_zone=zone.label,dropoff=drop.label,cash_reward=Utils.RandomBetween(cfg.cashReward),crypto_reward=Utils.RandomBetween(cfg.cryptoReward),xp_reward=Utils.RandomBetween(cfg.xpReward),status='available',requires_hacking=cfg.hacking and 1 or 0,has_tracker=cfg.tracker and 1 or 0,has_guards=cfg.guards and 1 or 0,is_locked=cfg.locked and 1 or 0,requires_partner=cfg.requiresPartner and 1 or 0,expires_at=os.date('%Y-%m-%d %H:%M:%S', os.time()+Config.ContractExpireMinutes*60),zone=zone,drop=drop}
end
function Contracts.GenerateForPlayer(src, forcedClass)
 local id=Bridge.GetIdentifier(src); local p=DB.single('SELECT * FROM tommy_boosting_players WHERE identifier=?',{id}); if not p then return {} end
 Contracts.available[id]={}
 for i=1,Config.MaxAvailableContracts do
  local pick=forcedClass or 'D'; if not forcedClass then local choices={} for cls,cfg in pairs(Config.Classes) do if p.level>=cfg.levelRequired then choices[#choices+1]=cls end end pick=Utils.RandomFrom(choices) end
  local c=mkContract(id,pick); Contracts.available[id][#Contracts.available[id]+1]=c
 end
 return Contracts.available[id]
end
function Contracts.Accept(src, idx)
 local id=Bridge.GetIdentifier(src); local profile=DB.single('SELECT * FROM tommy_boosting_players WHERE identifier=?',{id}); if not profile then return false,'Profile missing' end
 if Contracts.activeByIdentifier[id] then return false,'Already active' end
 local list=Contracts.available[id] or Contracts.GenerateForPlayer(src); local contract=list[tonumber(idx or 0)]; if not contract then return false,'Invalid contract' end
 if profile.level < Config.Classes[contract.class].levelRequired then Security.LogExploitAttempt(src,'accept_above_level',contract); return false,'Level too low' end
 contract.status='accepted'; contract.accepted_at=os.date('%Y-%m-%d %H:%M:%S'); Contracts.activeByIdentifier[id]=contract
 DB.update('INSERT INTO tommy_boosting_contracts (contract_id, owner_identifier, assigned_identifier, class, vehicle_model, plate, search_zone, dropoff, cash_reward, crypto_reward, xp_reward, status, requires_hacking, has_tracker, has_guards, is_locked, requires_partner, expires_at, accepted_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)',{contract.contract_id,id,id,contract.class,contract.vehicle_model,contract.plate,contract.search_zone,contract.dropoff,contract.cash_reward,contract.crypto_reward,contract.xp_reward,'accepted',contract.requires_hacking,contract.has_tracker,contract.has_guards,contract.is_locked,contract.requires_partner,contract.expires_at,contract.accepted_at})
 return true, contract
end
function Contracts.GetActive(src) return Contracts.activeByIdentifier[Bridge.GetIdentifier(src)] end
function Contracts.Complete(src, netId, coords)
 local id=Bridge.GetIdentifier(src); local c=Contracts.activeByIdentifier[id]; if not c then return false,'No contract' end
 if not Security.ValidateDistance(src, vec3(coords.x,coords.y,coords.z), Config.Security.maxDropoffDistance) then return false,'Too far from dropoff' end
 c.status='delivered'; DB.update('UPDATE tommy_boosting_contracts SET status=?, completed_at=NOW() WHERE contract_id=?',{'delivered',c.contract_id})
 DB.update('INSERT INTO tommy_boosting_history (contract_id,identifier,class,vehicle_model,plate,status,cash_reward,crypto_reward,xp_reward) VALUES (?,?,?,?,?,?,?,?,?)',{c.contract_id,id,c.class,c.vehicle_model,c.plate,'delivered',c.cash_reward,c.crypto_reward,c.xp_reward})
 Rewards.Give(src,{identifier=id},c); Contracts.activeByIdentifier[id]=nil; return true,c
end
