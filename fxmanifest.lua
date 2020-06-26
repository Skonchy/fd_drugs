fx_version "adamant"

game "gta5"

shared_scripts {
    "config.lua",
    --"@drp_inventory/config.lua",
    --"@drp_inventory/inventoryItems.lua"
}

client_scripts {
    "client.lua"
}

server_scripts {
    "server.lua"
}

dependencies {
    "drp_inventory"
}