local cjson = require "cjson.safe"
local error_handler = require "mercury.helpers.error_handler"

local function jsonResponse()
    return {
        json = function(success_data, err, status_code)
            if not success_data then
                error_handler.abort(status_code or ngx.HTTP_BAD_REQUEST, err)
                return
            end

            local success_function = jsonResponse().success
            success_function(success_data)
        end,
        success = function(data, message)
            ngx.header.content_type = 'application/json; charset=utf-8'
            ngx.status = ngx.HTTP_OK
            local response = {
                success = true,
                message = message or "success",
                data = data
            }
            ngx.say(cjson.encode(response))
            ngx.exit(ngx.HTTP_OK)
        end,

        error = function(message, status_code)
            error_handler.abort(status_code or ngx.HTTP_BAD_REQUEST, message)
        end,

        http_401 = function(message)
            error_handler.abort(ngx.HTTP_UNAUTHORIZED, message or "Unauthorized")
        end,

        http_403 = function(message)
            error_handler.abort(ngx.HTTP_FORBIDDEN, message or "Forbidden")
        end,

        http_404 = function(message)
            error_handler.abort(ngx.HTTP_NOT_FOUND, message or "Not Found")
        end,

        http_429 = function(message)
            error_handler.abort(ngx.HTTP_TOO_MANY_REQUESTS, message or "Too Many Requests")
        end,

        http_500 = function(message)
            error_handler.abort(ngx.HTTP_INTERNAL_SERVER_ERROR, message or "Internal Server Error")
        end,
    }
end

local _M = {}

function _M.response()
    return jsonResponse()
end

return setmetatable(_M, {
    __call = function(_, ...)
        return _M.response(...)
    end
})
