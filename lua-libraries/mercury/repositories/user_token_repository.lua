local redis_connector = require "mercury.connectors.redis_connector"
local token_generator = require "mercury.utils.token_generator"
local uuid = require "resty.jit-uuid"

uuid.seed()

local _M = {}

-- Generate a unique token identifier
local function generate_token_id()
    return uuid()
end

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
    local token_id = generate_token_id()
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
        local ok, err = red:srem("user_tokens:" .. user_id, id)
        if not ok then
            return nil, "Failed to remove token id from user set: " .. err
        end

        local token_key = "tokens:" .. id
        local ok, err = red:del(token_key)
        if not ok then
            return nil, "Failed to delete token data: " .. err
        end

        return true, nil
    end)
end

return _M
