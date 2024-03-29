local user_repo = require "mercury.repositories.user_repository"
local jwt = require "resty.jwt"
local jwt_config = require "mercury.config.jwt"
local auth_helper = require "mercury.helpers.auth_helper"
local token_repo = require "mercury.repositories.user_token_repository"

local _M = {}

function _M.register(username, password)
    local salt = jwt_config.password_salt
    local hashed_password = auth_helper.hash(password, salt)

    local user, err = user_repo.register(username, hashed_password)
    if not user then
        return nil, err or "unknown error"
    end

    return user, nil
end

function _M.authenticate(username, password)
    local hashed_password, hash_err = auth_helper.hash(password, jwt_config.password_salt)
    local user_id, err = user_repo.validate_credentials(username, hashed_password)
    if not user_id then
        return nil, err or "unknown error"
    end

    return user_id, nil
end

function _M.verify_refresh_token(refresh_token)
    local jwt_secret_key = jwt_config.secret

    -- Safely verify the token
    local ok, verified_jwt_or_err = pcall(jwt.verify, jwt, jwt_secret_key, refresh_token)
    if not ok or not verified_jwt_or_err or not verified_jwt_or_err.verified then
        ngx.log(ngx.ERR, "JWT verification failed: ", verified_jwt_or_err)
        return nil, "Invalid or expired refresh token."
    end

    local verified_jwt = verified_jwt_or_err

    local user_id = verified_jwt.payload.user_id
    local token, err = user_repo.get_refresh_token(user_id, refresh_token)
    if token ~= refresh_token then
        ngx.log(ngx.ERR, "Failed to get refresh token: " .. (err or "unknown error"))
        return nil, "invalid refresh token"
    end

    return user_id, nil
end

local function _generate_jwt_refresh_token(user_id)
    local current_time = ngx.time()
    local jwt_secret_key = jwt_config.secret
    local token_exp = jwt_config.refresh_ttl

    local payload = {
        user_id = user_id,
        exp = current_time + token_exp,
    }

    local token, err = jwt:sign(jwt_secret_key, {
        header = { typ = "JWT", alg = "HS256" },
        payload = payload
    })

    if not token then
        ngx.log(ngx.ERR, "Failed to generate JWT refresh token: ", err)
        return nil, "Failed to generate JWT refresh token."
    end

    local ok, save_err = user_repo.save_refresh_token(user_id, token, token_exp)
    if not ok then
        ngx.log(ngx.ERR, "Failed to store refresh token: " .. (save_err or "unknown error"))
        return nil, "Failed to store refresh token: " .. (save_err or "unknown error")
    end

    -- This log could potentially be moved to a debug level to avoid unnecessary logging in production
    ngx.log(ngx.INFO, "JWT refresh token successfully stored for user_id: ", user_id)
    return token
end

function _M.generate_jwt(user_id)
    local jwt_secret_key = jwt_config.secret
    local ttl = jwt_config.expire_ttl
    local now = os.time()
    local exp = now + ttl
    local token = jwt:sign(jwt_secret_key, {
        header = { typ = "JWT", alg = "HS256" },
        payload = {
            sub = user_id,
            iat = now,
            exp = exp,
        },
    })

    local refresh_token, refresh_err

    if jwt_config.refresh_enable then
        refresh_token, refresh_err = _generate_jwt_refresh_token(user_id)
        -- Handle potential error with refresh_err if necessary
    end

    local response = {
        token = token,
        token_type = "Bearer",
        expires_in = ttl,
        issued_at = os.time()
    }

    if refresh_token then
        response.refresh_token = refresh_token
    end

    return response
end

function _M.get_user_by_id(user_id)
    local user, err = user_repo.find_by_user_id(user_id)
    if not user then
        return nil, "Failed to find user: " .. (err or "unknown error")
    end
    return user, nil
end

function _M.verify_token(token)
    local exists, err = token_repo.exists(token)

    if not exists or err then
        return false, err or "Invalid token"
    end

    return true, nil
end

return _M
