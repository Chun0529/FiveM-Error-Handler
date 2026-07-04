fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'qbx-businesses'
description 'Player-owned business system for Qbox'
author 'Cursor Agent'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    'shared/config.lua',
    'shared/businesses.lua',
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'client/main.lua',
    'client/shop.lua',
    'client/management.lua',
    'client/employees.lua',
    'client/delivery.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/main.lua',
    'server/ownership.lua',
    'server/economy.lua',
    'server/employees.lua',
    'server/shop.lua',
    'server/delivery.lua',
}

files {
    'locales/*.json',
}

dependencies {
    'ox_lib',
    'oxmysql',
    'qbx_core',
}

ox_libs {
    'locale',
}

optional_dependencies {
    'ox_target',
    'ox_inventory',
}
