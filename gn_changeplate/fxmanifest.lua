fx_version 'cerulean'

game 'gta5'

name 'gn_changeplate'
description 'Cambio de matrícula como item para ESX/QBCore'
author 'gn'
version '1.0.0'

lua54 'yes'

shared_scripts {
	'config.lua',
	'shared/framework.lua'
}

client_scripts {
	'client/main.lua'
}

server_scripts {
	'server/main.lua'
}
