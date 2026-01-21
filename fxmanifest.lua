fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'

name 'rsg-wagonmaker'
description 'Wagon Maker Profession System for RSG Core'
author 'Devchacha'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config/config.lua',
    'shared/items.lua'
}

client_scripts {
    'client/zones.lua',
    'client/crafting.lua',
    'client/preview.lua',
    'client/parking.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/crafting.lua',
    'server/parking.lua',
    'server/transfer.lua',
    'server/employees.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/img/*.jpg',
    'html/img/*.png',
    'locales/*.json'
}

dependencies {
    'rsg-core',
    'ox_lib',
    'oxmysql'
}
