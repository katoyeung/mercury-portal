local authenticate = require "mercury.middleware.authenticate"

local verified = authenticate.verify_jwt()

if verified then
    ngx.req.set_header("X-User-Id", verified.payload.sub)

    -- Hash the request body
    ngx.req.read_body()
    local data = ngx.req.get_body_data()
    if data then
        local request_body_hash = ngx.md5(data)
        ngx.req.set_header("X-Request-Body-Hash", request_body_hash)
    else
        ngx.req.set_header("X-Request-Body-Hash", "no_body")
    end
end
