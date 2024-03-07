local redis_connector = require "mercury.connectors.redis_connector"
local uuid = require "resty.jit-uuid"

uuid.seed()

local token_cache = ngx.shared.my_tokens

local _M = {}

function _M.find_all(user_id)
    return redis_connector.execute(function(red)
        local token_ids, err = red:smembers("user_tokens:" .. user_id)
        if err then
            return nil, err
        end

        local tokens = {}
        for _, token_id in ipairs(token_ids) do
            local token_key = "tokens:" .. token_id
            local token_data, err = red:hgetall(token_key)
            if token_data and #token_data > 0 then
                -- Convert the hash map to a Lua table
                local token = { id = token_id }
                for i = 1, #token_data, 2 do
                    token[token_data[i]] = token_data[i + 1]
                end
                table.insert(tokens, token)
            else
                ngx.log(ngx.ERR, "Failed to get token data: ", err or "unknown error")
            end
        end

        return tokens, nil
    end)
end

function _M.find(user_id, id)
    return redis_connector.execute(function(red)
        local is_member, err = red:sismember("user_tokens:" .. user_id, id)
        if err then
            return nil, "Failed to check membership: " .. err
        end

        if is_member == 0 then
            return nil, "Token ID does not exist for this user"
        end

        local token_key = "tokens:" .. id
        local token_data, err = red:hgetall(token_key)
        if err or #token_data == 0 then
            return nil, err or "Token data not found"
        end

        local token = { id = id }
        for i = 1, #token_data, 2 do
            token[token_data[i]] = token_data[i + 1]
        end

        return token, nil
    end)
end

function _M.create(user_id, name, token)
    local token_id = uuid()
    local token_key = "tokens:" .. token_id
    local created_at = ngx.now()

    return redis_connector.execute(function(red)
        local ok, err = red:hmset(token_key, {
            user_id = user_id,
            name = name,
            token = token,
            created_at = created_at,
            last_used_at = created_at
        })

        if not ok then
            return nil, "Failed to create token: " .. err
        end

        local _, err = red:sadd("user_tokens:" .. user_id, token_id)
        if err then
            return nil, "Failed to index token for user: " .. err
        end

        local _, err = red:hset("global_token_map", token, token_id)
        if err then
            return nil, "Failed to index token for user: " .. err
        end

        return { id = token_id, token = token, created_at = created_at }, nil
    end)
end

function _M.update(user_id, id, data)
    return redis_connector.execute(function(red)
        local is_member, err = red:sismember("user_tokens:" .. user_id, id)
        if err then
            return nil, "Failed to check token id in user set: " .. err
        end
        if is_member == 0 then
            return nil, "Token id does not exist in user's set"
        end

        local token_key = "tokens:" .. id
        for key, value in pairs(data) do
            local ok, err = red:hset(token_key, key, value)
            if not ok then
                return nil, "Failed to update token data: " .. err
            end
        end

        return true, nil
    end)
end

function _M.delete(user_id, id)
    return redis_connector.execute(function(red)
        -- Step 1: Remove the token ID from the user's set of tokens
        local ok, err = red:srem("user_tokens:" .. user_id, id)
        if not ok then
            return nil, "Failed to remove token ID from user set: " .. err
        end

        -- Fetch the token value using the token ID
        local token_value, err = red:hget("tokens:" .. id, "token")
        if not token_value or token_value == ngx.null then
            ngx.log(ngx.ERR, "Failed to fetch token value for deletion: ", err)
            -- Proceed with deletion even if token value cannot be fetched, to ensure cleanup
        end

        -- Step 2: Delete the token data from Redis
        local ok, err = red:del("tokens:" .. id)
        if not ok then
            return nil, "Failed to delete token data: " .. err
        end

        -- Step 3: Remove the entry from the global token map (if the token value was fetched successfully)
        if token_value then
            local ok, err = red:hdel("global_token_map", token_value)
            if not ok then
                ngx.log(ngx.ERR, "Failed to delete token from global token map: ", err)
            end

            -- Also, remove the token from the Nginx shared dictionary cache
            token_cache:delete(token_value)
        end

        return true, nil
    end)
end

function _M.exists(token)
    local exists = token_cache:get(token)
    if exists then
        return true, nil
    else
        -- Token not in cache, check Redis
        return redis_connector.execute(function(red)
            local exists, err = red:hexists("global_token_map", token)
            if exists == 1 then
                token_cache:set(token, true, 3600)
                return true, nil
            else
                return false, "Token not exists"
            end
        end)
    end
end

return _M
