local resty_sha256 = require "resty.sha256"
local str = require "resty.string"

local _M = {}

function _M.id()
    local user_id = ngx.ctx.user_id
    if not user_id then
        ngx.log(ngx.ERR, "user_id not found in request context")
        return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    return user_id
end

function _M.hash(password, salt)
    salt = salt or "" -- Ensure salt is not nil, defaulting to an empty string if it is

    local sha256 = resty_sha256:new()
    if not sha256 then
        ngx.log(ngx.ERR, "Failed to create SHA256 instance")
        return nil
    end

    local ok = sha256:update(password .. salt)
    if not ok then
        ngx.log(ngx.ERR, "Failed to update SHA256 hash")
        return nil
    end

    local provided_hashed_password = sha256:final()
    return str.to_hex(provided_hashed_password)
end

return _M
