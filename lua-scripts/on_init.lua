local jwt_config = require "mercury.config.jwt"

if not jwt_config.secret or jwt_config.secret == "" then
    ngx.log(ngx.ERR, "JWT_SECRET_KEY not set")
    error("JWT_SECRET_KEY not set. Application initialization failed.")
end
