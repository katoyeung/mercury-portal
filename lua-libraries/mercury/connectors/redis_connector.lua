local redis = require "resty.redis"
local config = require "mercury.config.database"

local _M = {}

function _M.execute(func)
    local red = redis:new()
    red:set_timeout(config.redis.timeout or 1000)

    local ok, err = red:connect(config.redis.host, tonumber(config.redis.port))
    if not ok then
        ngx.log(ngx.ERR, "failed to connect to Redis: ", err)
        return nil, err
    end

    if config.redis.password and config.redis.password ~= "" then
        local ok, err = red:auth(config.redis.password)
        if not ok then
            ngx.log(ngx.ERR, "failed to authenticate: ", err)
            return nil, err
        end
    end

    if config.redis.db then
        red:select(config.redis.db)
    end

    -- Call the passed function with the Redis connection
    local result, err = func(red)
    if not result or err then
        return nil, err
    end

    -- Put connection back in the pool
    local ok, err = red:set_keepalive(config.redis.keepalive_timeout or 10000, config.redis.pool_size or 100)
    if not ok then
        ngx.log(ngx.ERR, "failed to set keepalive: ", err)
    end

    return result, nil
end

return _M
