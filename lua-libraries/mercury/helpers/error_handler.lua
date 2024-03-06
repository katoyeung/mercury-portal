local cjson = require "cjson.safe"

local _M = {}

function _M.abort(status_code, message, headers)
    if headers then
        for k, v in pairs(headers) do
            ngx.header[k] = v
        end
    end

    ngx.header.content_type = 'application/json; charset=utf-8'
    ngx.status = status_code or ngx.HTTP_BAD_REQUEST
    local response = {
        success = false,
        message = message or "An error occurred",
    }
    ngx.say(cjson.encode(response))
    ngx.exit(ngx.status)
end

return _M
