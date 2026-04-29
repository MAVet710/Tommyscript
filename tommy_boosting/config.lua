Config = {}
Config.Name = 'Tommy Boosting'
Config.Debug = true
Config.Framework = 'auto'
Config.Inventory = 'auto'
Config.UseTarget = false
Config.TargetSystem = 'ox_target'
Config.Command = 'boosting'
Config.RequireLaptopItem = true
Config.LaptopItem = 'boosting_laptop'
Config.ContractExpireMinutes = 30
Config.ContractRefreshMinutes = 10
Config.MaxAvailableContracts = 5
Config.LeaderboardSort = 'xp'
Config.TeamModeEnabled = true

Config.Levels = { [1]=0,[2]=250,[3]=600,[4]=1000,[5]=1600,[6]=2300,[7]=3200,[8]=4300,[9]=5600,[10]=7200,[11]=9000,[12]=11500,[13]=14500,[14]=18000,[15]=22000 }
Config.Classes = {
['D']={label='Class D',levelRequired=1,xpReward={min=50,max=100},cashReward={min=500,max=1000},cryptoReward={min=2,max=5},policeChance=10,tracker=false,hacking=false,guards=false,locked=false,vehicleHealthRequired=300,cooldown=5,vehicles={'blista','asea','prairie'}},
['C']={label='Class C',levelRequired=2,xpReward={min=100,max=180},cashReward={min=1000,max=1800},cryptoReward={min=5,max=9},policeChance=20,tracker=false,hacking=true,guards=false,locked=true,vehicleHealthRequired=400,cooldown=8,vehicles={'sultan','futo','sentinel'}},
['B']={label='Class B',levelRequired=4,xpReward={min=180,max=300},cashReward={min=1800,max=3000},cryptoReward={min=9,max=15},policeChance=35,tracker=true,hacking=true,guards=false,locked=true,vehicleHealthRequired=500,cooldown=12,vehicles={'kuruma','schafter3','comet2'}},
['A']={label='Class A',levelRequired=7,xpReward={min=300,max=500},cashReward={min=3000,max=5000},cryptoReward={min=15,max=25},policeChance=50,tracker=true,hacking=true,guards=true,locked=true,vehicleHealthRequired=600,cooldown=18,vehicles={'jester','elegy','ninef'}},
['S']={label='Class S',levelRequired=10,xpReward={min=500,max=800},cashReward={min=5000,max=8000},cryptoReward={min=25,max=40},policeChance=70,tracker=true,hacking=true,guards=true,locked=true,requiresPartner=true,vehicleHealthRequired=700,cooldown=25,vehicles={'t20','italigto','pariah'}},
['S+']={label='Class S+',levelRequired=15,xpReward={min=800,max=1200},cashReward={min=8000,max=13000},cryptoReward={min=40,max=70},policeChance=90,tracker=true,hacking=true,guards=true,locked=true,requiresPartner=true,vehicleHealthRequired=800,cooldown=35,vehicles={'zentorno','tempesta','xa21'}}
}
Config.SearchZones={{label='Vinewood Backstreets',center=vec3(320.0,200.0,104.0),radius=250.0,spawns={vec4(310.0,210.0,104.0,80.0),vec4(340.0,180.0,104.0,160.0)}},{label='South LS',center=vec3(-300.0,-1600.0,31.0),radius=220.0,spawns={vec4(-260.0,-1660.0,33.0,110.0),vec4(-380.0,-1540.0,25.0,220.0)}}}
Config.Dropoffs={{label='Docks Container Yard',coords=vec3(1200.0,-3000.0,5.0),heading=90.0,radius=8.0},{label='Sandy Airfield',coords=vec3(1742.0,3282.0,41.1),heading=192.0,radius=8.0}}
Config.Hacking={enabled=true,attempts=3,difficultyByClass={['D']=false,['C']={'easy','easy'},['B']={'easy','medium'},['A']={'medium','medium'},['S']={'medium','hard'},['S+']={'hard','hard','medium'}},failAction='alert'}
Config.Tracker={enabled=true,pingIntervalSeconds={['B']=90,['A']=60,['S']=45,['S+']=30},allowRemoval=true,removeRequiresItem=true,item='tracker_remover',removeTimeSeconds=12}
Config.Guards={enabled=true,models={'g_m_m_chigoon_02','g_m_y_mexgoon_02'},weapons={'WEAPON_PISTOL','WEAPON_BAT'},countByClass={['A']=2,['S']=3,['S+']=4},accuracy=35,armor=25}
Config.Dispatch={enabled=true,system='custom',policeJobs={'police','sheriff','state'},highClassAcceptanceAlert=true}
Config.CustomDispatchAlert=function(coords,vehicleData,contractClass,alertType) print(('[Tommy Boosting Dispatch] %s %s %s'):format(alertType,vehicleData.plate,contractClass)) end
Config.Store={enabled=true,infiniteStock=false,items={{item='tracker_remover',label='Tracker Remover',description='Disable GPS trackers.',price=25,stock=5,icon='satellite'},{item='advanced_lockpick',label='Advanced Lockpick',description='Bypass advanced locks.',price=15,stock=10,icon='key'},{item='hacking_device',label='Hacking Device',description='Run advanced bypass.',price=30,stock=3,icon='terminal'}}}
Config.ContractTransfers={enabled=true,allowPrice=true,currency='crypto',allowAboveLevel=false}
Config.VinScratch={enabled=true,requiredItem='vin_scratcher',costCrypto=100,allowedClasses={['A']=true,['S']=true,['S+']=true},timeSeconds=30,removeItemOnUse=true,saveToPlayerVehicles=true,completeStatus='completed_vin'}
Config.Admin={enabled=true,useAce=true,acePermission='tommyboosting.admin',allowedGroups={'god','admin'},identifiers={'license:xxxxxxxx'}}
Config.Security={dropOnExploit=false,logExploitAttempts=true,maxDropoffDistance=15.0,maxVehicleDistance=25.0,allowStandaloneItemBypass=false,dropContractStatusOnDisconnect='cancelled'}
Config.UI={theme='dark-orange'}
