version '1.0.1'
author 'Prefech'
description 'Prefech Properties (https://prefech.com/)'

-- Server Scripts
server_scripts {
    'server.lua',
    '@oxmysql/lib/MySQL.lua'
}

--Client Scripts
client_scripts {
    'client.lua'
}

--Shares Scripts
shared_scripts {
    'config.lua'
}

lua54 'yes'
game 'gta5'
fx_version 'cerulean'