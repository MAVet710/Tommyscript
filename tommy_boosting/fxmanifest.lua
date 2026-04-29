fx_version 'cerulean'
game 'gta5'

name 'tommy_boosting'
author 'Tommy Boosting'
description 'Tommy Boosting - Full vehicle boosting gameplay system'
version '1.0.0'

lua54 'yes'

ui_page 'nui/index.html'

files {
  'nui/index.html',
  'nui/style.css',
  'nui/app.js',
  'nui/assets/logo.svg'
}

shared_scripts {
  '@ox_lib/init.lua',
  'config.lua',
  'shared/locales.lua',
  'shared/utils.lua',
  'shared/bridge.lua'
}

client_scripts {
  'client/main.lua',
  'client/ui.lua',
  'client/contracts.lua',
  'client/hacking.lua',
  'client/tracker.lua',
  'client/vin.lua',
  'client/admin.lua',
  'client/targets.lua'
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/security.lua',
  'server/database.lua',
  'server/rewards.lua',
  'server/store.lua',
  'server/leaderboard.lua',
  'server/vin.lua',
  'server/admin.lua',
  'server/contracts.lua',
  'server/callbacks.lua',
  'server/main.lua'
}
