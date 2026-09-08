-- One-way adapter. Mutate the producer through actions, never the returned Value.
local Bridge = {}
function Bridge.Value(scope, producer, selector)
    local value = scope:Value(selector(producer:getState()))
    table.insert(scope, producer:subscribe(selector, function(nextValue)
        value:set(nextValue)
    end))
    return value
end
return Bridge
