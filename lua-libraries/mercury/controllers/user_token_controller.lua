local auth = require "mercury.helpers.auth_helper"
local token_service = require "mercury.services.token_service"
local response = require "mercury.utils.response"
local request = require "mercury.utils.request"
local token_resource = require "mercury.resources.token_resource"
local v = require "resty.validation"

local _M = {}

function _M.index()
    local user_id = auth.id()
    local result, err = token_service:find_all_tokens(user_id)
    if result then
        local resource = token_resource:new(result)
        result, err = resource:transform()
    end

    response().json(result, err)
end

function _M.store()
    local user_id = auth.id()
    local name = request.get("name") or ""

    local validator = v.new {
        name = v.string:trim():minlen(4):maxlen(30):match("^[a-z_ ]+$"),
    }

    local valid, fields = validator({
        name = name,
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

    local token, err = token_service:create_token(user_id, name)

    response().json(token, err)
end

function _M.update()
    local user_id = auth.id()
    local id = request.get("id")
    local data = request.get_body()
    local token, err = token_service:update_token(user_id, id, data)

    response().json(token, err)
end

function _M.show()
    local user_id = auth.id()
    local id = request.get("id")
    local token, err = token_service:show_token(user_id, id)

    response().json(token, err)
end

function _M.delete()
    local user_id = auth.id()
    local id = request.get("id")
    local token, err = token_service:delete_token(user_id, id)

    response().json(token, err)
end

return _M
