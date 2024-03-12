#!/bin/sh

# Check APP_ENV value
if [ "$APP_ENV" = "dev" ]; then
    LUA_CACHE_SETTING="off"
else
    LUA_CACHE_SETTING="on"
fi

# Directory where your .conf files are located
CONF_DIR="/etc/nginx/conf.d"

# Loop through all .conf files in the directory and replace lua_code_cache setting
for file in "$CONF_DIR"/*.conf; do
    sed -i "s/lua_code_cache .*/lua_code_cache $LUA_CACHE_SETTING;/" "$file"
done
