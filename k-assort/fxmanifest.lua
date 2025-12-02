fx_version "cerulean"
lua54 'yes'
game 'gta5'

author 'Discord: keooh'

client_scripts {
	"client/**.lua",
}

files {
	'data/**/handling.meta',
}

server_scripts {
    "server/**.lua",
}

dependencies {
    'ox_lib',
}

shared_scripts {
    '@ox_lib/init.lua',
}