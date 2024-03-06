local redis_connector = require "mercury.connectors.redis_connector"

local _M = {}

function _M:new()
    return setmetatable({}, { __index = self })
end

function _M.register(username, password)
    return redis_connector.execute(function(red)
        local user_key = "users:" .. username
        local exists = red:exists(user_key)

        if exists == 1 then
            return nil, "user already exists"
        end

        -- Generate a new user ID
        local user_id_key = "users:last_id"
        local user_id, err = red:incr(user_id_key)
        if not user_id then
            return nil, "failed to generate user ID: " .. (err or "unknown error")
        end

        -- Get current timestamp
        local created_at = os.time()

        -- Save the new user details
        local ok, err = red:hmset(user_key,
            "id", user_id,
            "password", password,
            "username", username,
            "created_at", created_at)
        if not ok then
            return nil, "Failed to save user: " .. (err or "unknown error")
        end

        -- Optionally, you might want to create a reverse lookup by user_id
        local user_id_key = "user_ids:" .. user_id
        ok, err = red:set(user_id_key, username)
        if not ok then
            return nil, "Failed to save user ID reverse lookup: " .. (err or "unknown error")
        end

        return { user_id = user_id, username = username, created_at = created_at }, nil
    end)
end

function _M.find_by_username(username)
    return redis_connector.execute(function(red)
        -- Use the username to find the user's key
        local user_key = "users:" .. username
        local user_id, err = red:hget(user_key, "id")
        if not user_id or user_id == ngx.null then
            return nil, "User not found"
        end

        -- Fetch user details
        local user_details, err = red:hgetall(user_key)
        if err or #user_details == 0 then
            return nil, "Failed to fetch user details: " .. (err or "unknown error")
        end

        -- Convert hash map to Lua table
        local user = { id = tonumber(user_id) }
        for i = 1, #user_details, 2 do
            user[user_details[i]] = user_details[i + 1]
        end

        return user, nil
    end)
end

function _M.find_by_user_id(user_id)
    return redis_connector.execute(function(red)
        local username_key = "user_ids:" .. user_id
        local username, err = red:get(username_key)

        if not username or username == ngx.null then
            return nil, "user not found"
        end

        return _M.find_by_username(username)
    end)
end

function _M.save_refresh_token(user_id, refresh_token, refresh_token_exp)
    return redis_connector.execute(function(red)
        -- Basic validation and logging
        if not user_id or not refresh_token or not refresh_token_exp then
            ngx.log(ngx.ERR, "Invalid arguments to save_refresh_token. user_id: ", user_id, ", refresh_token_exp: ",
                refresh_token_exp, ", refresh_token: ", refresh_token)
            return nil, "Invalid arguments"
        end

        local ok, err = red:setex("refresh_tokens:" .. user_id, refresh_token_exp, refresh_token)
        if not ok then
            ngx.log(ngx.ERR, "Failed to save refresh token for user: ", err)
            return nil, "Failed to save refresh token for user: " .. err
        end

        return ok, nil
    end)
end

function _M.get_refresh_token(user_id, token)
    return redis_connector.execute(function(red)
        if not user_id or not token then
            ngx.log(ngx.ERR, "Invalid arguments to save_refresh_token. user_id: ", user_id, ", refresh_token: ", token)
            return nil, "Invalid arguments"
        end

        local stored_token, err = red:get("refresh_tokens:" .. user_id)
        if not stored_token or stored_token == ngx.null then
            ngx.log(ngx.ERR, "refresh token for user: ", err)
            return nil, "refresh token not found"
        end

        return stored_token
    end)
end

return _M
