local openssl_rand = require "resty.openssl.rand"
local str = require "resty.string"

local _M = {}

function _M.generate_secure_token(length)
    length = length or 32 -- Default length if not specified

    -- Generate secure random bytes
    local random_bytes, err = openssl_rand.bytes(length, true) -- true for strong randomness
    if not random_bytes then
        ngx.log(ngx.ERR, "Failed to generate random bytes for token: ", err)
        return nil
    end

    -- Convert the random bytes to a hexadecimal string
    local token = str.to_hex(random_bytes)
    return token
end

return _M
