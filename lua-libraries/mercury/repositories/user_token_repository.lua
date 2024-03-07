local redis_connector = require "mercury.connectors.redis_connector"
local token_generator = require "mercury.utils.token_generator"

local _M = {}

-- Generate a unique token identifier
local function generate_token_id(user_id)
    return "token:" .. user_id .. ":" .. token_generator.generate_secure_token(8)
end

function _M.find_all(user_id)
    return redis_connector.execute(function(red)
        local token_ids, err = red:smembers("user_tokens:" .. user_id)
        if err then
            return nil, err
        end

        local tokens = {}
        for _, token_id in ipairs(token_ids) do
            local token_data, err = red:hgetall(token_id)
            if token_data and #token_data > 0 then
                -- Convert the hash map to a Lua table
                local token = { id = token_id } -- Include token_id as 'id'
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

        local token_data, err = red:hgetall(id)
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
    local token_id = generate_token_id(user_id)
    local created_at = ngx.now()

    return redis_connector.execute(function(red)
        -- Use a Redis hash to store the token data
        local ok, err = red:hmset(token_id, {
            name = name,
            token = token,
            created_at = created_at,
            last_used_at = created_at -- Initially, last_used_at is the creation time
        })

        if not ok then
            return nil, "Failed to create token: " .. err
        end

        -- Add the token ID to the set of tokens for the user
        local _, err = red:sadd("user_tokens:" .. user_id, token_id)
        if err then
            return nil, "Failed to index token for user: " .. err
        end

        return { token_id = token_id, token = token, created_at = created_at }, nil
    end)
end

function _M.update(user_id, id, data)
    return redis_connector.execute(function(red)
        -- Check if the token ID exists in the user's set of tokens
        local is_member, err = red:sismember("user_tokens:" .. user_id, id)
        if err then
            return nil, "Failed to check token ID in user set: " .. err
        end
        if is_member == 0 then
            return nil, "Token ID does not exist in user's set"
        end

        -- Attempt to update the record with new data if key exists
        for key, value in pairs(data) do
            local ok, err = red:hset(id, key, value)
            if not ok then
                return nil, "Failed to update token data: " .. err
            end
        end

        return true, nil
    end)
end

function _M.delete(user_id, id)
    return redis_connector.execute(function(red)
        -- Remove the token ID from the user's set of tokens
        local ok, err = red:srem("user_tokens:" .. user_id, id)
        if not ok then
            return nil, "Failed to remove token ID from user set: " .. err
        end

        -- Delete the hash storing the token's details
        local ok, err = red:del(id)
        if not ok then
            return nil, "Failed to delete token data: " .. err
        end

        return true, nil
    end)
end

return _M
