local jwt = require "resty.jwt"
local response = require "mercury.utils.response"
local jwt_config = require "mercury.config.jwt"

local _M = {}

function _M.verify_jwt()
    local auth_header = ngx.var.http_Authorization
    if not auth_header then
        response().http_401()
    end

    local _, _, token = string.find(auth_header, "Bearer%s+(.+)")

    if not token then
        response().http_401("auth token not found")
    end

    local jwt_secret_key = jwt_config.secret

    -- Safely verify the token
    local ok, verified = pcall(jwt.verify, jwt, jwt_secret_key, token)
    if not ok or not verified or not verified.verified then
        response().http_401()
    end

    ngx.ctx.user_id = verified.payload.sub

    return verified
end

function _M.verify_token()
    local auth_header = ngx.var.http_Authorization
    if not auth_header then
        response().http_401()
    end

    local _, _, token = string.find(auth_header, "Bearer%s+(.+)")

    if not token then
        response().http_401("auth token not found")
    end

    local jwt_secret_key = jwt_config.secret

    -- Safely verify the token
    local ok, verified = pcall(jwt.verify, jwt, jwt_secret_key, token)
    if not ok or not verified or not verified.verified then
        response().http_401()
    end

    ngx.ctx.user_id = verified.payload.sub

    return verified
end

return _M
