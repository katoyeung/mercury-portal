local token_repo = require "mercury.repositories.user_token_repository"

local _M = {}

function _M:find_all_tokens(user_id)
    local token, err = token_repo:find_all(user_id)
    if not token then
        return nil, "Failed to find the user token: " .. (err or "unknown error")
    end
    return token, nil
end

function _M:create_token(user_id, name)
    local token, err = token_repo:create(user_id, name)
    if not token then
        return nil, "Failed to create user token: " .. (err or "unknown error")
    end
    return token, nil
end

function _M:update_token(user_id, id, data)
    local token, err = token_repo:update(user_id, id, data)
    if not token then
        return nil, "Failed to update_token user token: " .. (err or "unknown error")
    end
    return token, nil
end

function _M:show_token(user_id, id)
    local token, err = token_repo:find(user_id, id)
    if not token then
        return nil, "Failed to find user token: " .. (err or "unknown error")
    end
    return token, nil
end

function _M:delete_token(user_id, id)
    local token, err = token_repo:delete(user_id, id)
    if not token then
        return nil, "Failed to delete user token: " .. (err or "unknown error")
    end
    return token, nil
end

return _M
