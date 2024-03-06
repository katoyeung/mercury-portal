local os = require "os"

local _M = {}

_M.secret = os.getenv("JWT_SECRET_KEY")
_M.refresh_ttl = tonumber(os.getenv("JWT_REFRESH_TOKEN_TTL")) or 7200
_M.expire_ttl = tonumber(os.getenv("JWT_EXPIRE_TTL")) or 3600
_M.password_salt = tonumber(os.getenv("JWT_PASSWORD_SALT")) or 3600

return _M
