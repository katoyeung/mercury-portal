local auth_service = require "mercury.services.auth_service"
local response = require "mercury.utils.response"
local request = require "mercury.utils.request"
local v = require "resty.validation"
local auth = require "mercury.helpers.auth_helper"

local _M = {}

function _M.login()
    local username    = request.get("username")
    local password    = request.get("password")

    local result, err = auth_service.authenticate(username, password)
    if result and result.id then
        result, err = auth_service.generate_jwt(result.id)
    end

    response().json(result, err)
end

function _M.register()
    local username = request.get("username")
    local password = request.get("password")

    local validator = v.new {
        username = v.string:trim():minlen(4):maxlen(30):match("^[a-z_]+$"),
        password = v.string:trim():minlen(8):maxlen(64)
    }

    local valid, fields = validator({
        username = username,
        password = password
    })

    if not valid then
        local errors = {}
        for _, field in pairs(fields) do
            if field.invalid then
                -- Initialize the error list for this field if it hasn't been already
                errors[field.name] = errors[field.name] or {}
                -- Append the error message for this field
                table.insert(errors[field.name], field.error)
            end
        end

        if next(errors) then
            response().error(errors, ngx.HTTP_BAD_REQUEST)
        end
    end

    local result, err = auth_service.register(username, password)
    if result and result.id then
        result, err = auth_service.generate_jwt(result.id)
    end

    response().json(result, err)
end

function _M.refresh_token()
    local refresh_token = request.get("refresh_token")
    local result, err = auth_service.verify_refresh_token(refresh_token)
    if result then
        result, err = auth_service.generate_jwt(result)
    end

    response().json(result, err)
end

function _M.me()
    local user_id = auth.id()
    local user, err = auth_service.get_user_by_id(user_id)
    response().json(user, err)
end

return _M
