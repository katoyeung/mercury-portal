local user_token_controller = require "mercury.controllers.user_token_controller"
local auth_controller = require "mercury.controllers.auth_controller"
local page_controller = require "mercury.controllers.page_controller"
local authenticate = require "mercury.middleware.authenticate"
local route_service = require "mercury.services.route_service"

local _M = {}

_M.route_table = {
    -- { ['method'] = "GET",    ['middleware'] = {},                          ["path"] = "/app/",             ['handle'] = route_service.proxy_pass("http://app:8080/") },
    { ['method'] = "GET",    ['middleware'] = { authenticate.verify_token }, ["path"] = "/",                 ['handle'] = page_controller.index },
    { ['method'] = "POST",   ['middleware'] = {},                            ["path"] = "/register",         ['handle'] = auth_controller.register },
    { ['method'] = "POST",   ['middleware'] = {},                            ["path"] = "/login",            ['handle'] = auth_controller.login },
    { ['method'] = "POST",   ['middleware'] = {},                            ["path"] = "/refresh-token",    ['handle'] = auth_controller.refresh_token },
    { ['method'] = "GET",    ['middleware'] = { authenticate.verify_jwt },   ["path"] = "/me",               ['handle'] = auth_controller.me },
    { ['method'] = "POST",   ['middleware'] = { authenticate.verify_jwt },   ["path"] = "/user-tokens",      ['handle'] = user_token_controller.store },
    { ['method'] = "GET",    ['middleware'] = { authenticate.verify_jwt },   ["path"] = "/user-tokens",      ['handle'] = user_token_controller.index },
    { ['method'] = "POST",   ['middleware'] = { authenticate.verify_jwt },   ["path"] = "/user-tokens",      ['handle'] = user_token_controller.store },
    { ['method'] = "GET",    ['middleware'] = { authenticate.verify_jwt },   ["path"] = "/user-tokens/{id}", ['handle'] = user_token_controller.show },
    { ['method'] = "PATCH",  ['middleware'] = { authenticate.verify_jwt },   ["path"] = "/user-tokens/{id}", ['handle'] = user_token_controller.update },
    { ['method'] = "DELETE", ['middleware'] = { authenticate.verify_jwt },   ["path"] = "/user-tokens/{id}", ['handle'] = user_token_controller.delete },
}

local function preprocess_route_table(route_table)
    for _, route in ipairs(route_table) do
        local names = {}
        local pattern = route.path:gsub("{([^}]+)}", function(name)
            table.insert(names, name)
            return "([^/]+)"
        end)
        route.compiled_pattern = "^" .. pattern .. "$"
        route.segment_names = names
    end
end

preprocess_route_table(_M.route_table)

function _M.route()
    local method = ngx.req.get_method()
    local uri = ngx.var.uri

    for _, route in ipairs(_M.route_table) do
        local matches, err = ngx.re.match(uri, route.compiled_pattern, "jo")
        if matches and method == route.method then
            for _, middleware in ipairs(route.middleware or {}) do
                middleware()
            end

            if route.segment_names then
                local params = {}
                for i, name in ipairs(route.segment_names) do
                    if matches[i] then
                        params[name] = matches[i]
                    end
                end

                ngx.req.set_uri_args(params)
                ngx.header.content_type = "application/json"
                local handler_response = route.handle(params) -- Ensure your handlers are prepared to accept params
                if handler_response then
                    ngx.say(handler_response)
                end
                ngx.exit(ngx.HTTP_OK)
                return
            end
        end
    end
end

return _M
