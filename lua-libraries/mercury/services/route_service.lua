local http = require "resty.http"

local _M = {}

function _M.proxy_pass(upstream_url)
    return function(params)
        local httpc = http.new()
        httpc:set_timeout(60000)     -- Sets both send and read timeout to 60 seconds.

        -- Preparing the request headers.
        local forwarded_for = ngx.var.proxy_add_x_forwarded_for
        if forwarded_for then
            forwarded_for = forwarded_for .. ", " .. ngx.var.remote_addr
        else
            forwarded_for = ngx.var.remote_addr
        end

        local headers = {
            ["X-Real-IP"] = ngx.var.remote_addr,
            ["X-Forwarded-For"] = forwarded_for,
            ["X-Forwarded-Proto"] = ngx.var.scheme,
            ["X-User-Id"] = ngx.var.http_x_user_id,
            -- Not overriding the Host header to let the upstream server determine the Host
            -- Keeping connections alive efficiently
            ["Connection"] = "keep-alive"
        }

        ngx.req.read_body()     -- Read the request body
        local body = ngx.req.get_body_data()

        local res, err = httpc:request_uri(upstream_url, {
            method = ngx.req.get_method(),
            body = body,
            headers = headers,
            keepalive_timeout = 60000,     -- For httpc:set_keepalive
            keepalive_pool = 100
        })

        if not res then
            ngx.log(ngx.ERR, "Failed to proxy request: ", err)
            ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
            ngx.say("Failed to proxy request")
            ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
        end

        -- Processing and forwarding the response to the client
        ngx.status = res.status
        for k, v in pairs(res.headers) do
            if k ~= "Connection" and k ~= "Transfer-Encoding" then
                ngx.header[k] = v
            end
        end

        ngx.print(res.body)
        ngx.eof()

        -- It's crucial to properly manage the keep-alive connections.
        -- The lua-resty-http library handles this if you do not manually close the connection.
        -- The connection will be kept alive for reuse if the server supports it.
        -- Explicitly closing or setting keepalive is not needed after the response is fully processed.
    end
end

return _M
