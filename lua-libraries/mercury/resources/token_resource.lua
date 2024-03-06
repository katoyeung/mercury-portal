local function to_iso8601(timestamp)
    local integer_part, decimal_part = math.modf(timestamp)
    local iso_date = os.date("!%Y-%m-%dT%H:%M:%S", integer_part) .. string.format(".%03dZ", decimal_part * 1000)
    return iso_date
end

local token_resource = {}

function token_resource:new(tokens)
    local self = setmetatable({}, { __index = token_resource })
    self.tokens = tokens
    return self
end

function token_resource:transform()
    local transformed = {}
    for _, token in ipairs(self.tokens) do
        table.insert(transformed, {
            id = token.id,
            token = token.token,
            name = token.name,
            created_at = to_iso8601(tonumber(token.created_at)),
            last_used_at = to_iso8601(tonumber(token.last_used_at)),
        })
    end
    return transformed
end

return token_resource
