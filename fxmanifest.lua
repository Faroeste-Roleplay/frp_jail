fx_version "adamant"
games {"rdr3"}
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

lua54 'yes'
-- use_experimental_fxv2_oal 'yes'



server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'config.lua',
	'server/query.lua',
	'server/main.lua'
}

client_scripts {
	'@ox_lib/init.lua',
	'config.lua',
	'client/main.lua',
	'client/Util.lua',
	'client/jobjail.lua'
}

shared_scripts {
    '@frp_lib/library/linker.lua',
	'locale/*.lua',
}
