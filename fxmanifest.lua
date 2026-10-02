fx_version 'cerulean'
game 'gta5'

author 'Project Kita'
description 'NPC market dengan kontrol government, kas society, dan dynamic stash Qbox'
version '1.0.0'
lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_script 'client/main.lua'
server_script 'server/main.lua'

dependencies {
    'qbx_core',
    'ox_lib',
    'ox_inventory',
    'ox_target',
    'dd_stash'
}
