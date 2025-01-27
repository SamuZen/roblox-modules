return function(scope, instance, timeLeftValue, time, color)
    for _, child in instance:GetDescendants() do
        if child.Name == "Color" then
            local originalColor = child.Color
            scope:Hydrate(child) {
                Color = scope:Computed(function(use, scope)
                    local t = use(timeLeftValue)
                    if t < time and t > 0 then
                        return color
                    else
                        return originalColor
                    end
                end)
            }
        end
    end
end