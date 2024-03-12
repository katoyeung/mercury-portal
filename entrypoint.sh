#!/bin/sh

# Run your sed script
/usr/local/bin/setup-script.sh

# Then start OpenResty
exec /usr/local/openresty/bin/openresty -g "daemon off;"
