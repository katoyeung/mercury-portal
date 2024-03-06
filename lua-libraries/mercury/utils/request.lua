local cjson = require "cjson.safe"

local _M = {}
local mt = {}

-- Private function to read JSON body if content type is application/json
local function read_json_body()
    local headers = ngx.req.get_headers()
    local content_type = headers["content-type"]
    if content_type and content_type:match("application/json") then
        ngx.req.read_body()
        local body_data = ngx.req.get_body_data()
        if body_data then
            local params, err = cjson.decode(body_data)
            if not params then
                ngx.log(ngx.ERR, "Failed to decode JSON body: ", err)
                return {}
            end
            return params
        end
    end
    return {}
end

function _M.get_body()
    local body_params = read_json_body()
    return body_params
end

-- Private function to initialize request parameters lazily
local function lazy_init(self)
    if not rawget(self, "__params") then      -- Use rawget to directly access __params without triggering __index
        local params = ngx.req.get_uri_args() -- Populate query parameters
        local body_params = read_json_body()  -- Attempt to read JSON body
        for k, v in pairs(body_params) do     -- Merge body params into query params for unified access
            params[k] = v
        end
        rawset(self, "__params", params) -- Use rawset to directly set __params without triggering __newindex
    end
    return rawget(self, "__params")      -- Use rawget to return __params directly
end

function mt:__index(key)
    local params = lazy_init(self)
    return params[key] -- Retrieve parameter by key
end

function _M.get(key)
    local self = setmetatable({}, mt)
    return self[key] -- Utilize metatable __index to fetch parameter
end

return setmetatable(_M, {
    __call = function(_, key)
        return _M.get(key) -- Allow direct invocation to fetch parameter
    end
})
