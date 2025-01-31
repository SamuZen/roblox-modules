return function(scope, timeLeftValue, parent, adornee)
    -- debug
    scope:New "BillboardGui" {
        Size = UDim2.fromScale(4, 2),
        Adornee = adornee,
        Parent = parent,
        StudsOffset = Vector3.new(0, 4, 0),
        AlwaysOnTop = true,
        [scope.Children] = {
            scope:New "TextLabel" {
                Text = scope:Computed(function(use, scope)
                    local t = use(timeLeftValue)
                    if t < 0 then return "0" end
                    return `{string.format("%." .. (1 or 0) .. "f", t)}`
                end),
                Size = UDim2.fromScale(1, 1),
                TextScaled = true,
            }
        }
    }
end