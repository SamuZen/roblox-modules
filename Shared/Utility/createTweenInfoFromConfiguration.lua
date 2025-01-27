return function(configuration, overwrite)
    local function getValue(key, defaultValue)
        if overwrite[key] ~= nil then return overwrite[key] end

        if configuration ~= nil and configuration:GetAttribute(key) ~= nil and configuration:GetAttribute(key) ~= '' then
            if key == 'easingStyle' then
                return Enum.EasingStyle[configuration:GetAttribute(key)]
            elseif key == 'easingDirection' then
                return Enum.EasingDirection[configuration:GetAttribute(key)]
            else
                return configuration:GetAttribute(key)
            end
        end

        return defaultValue
    end

    return TweenInfo.new(
        getValue('time', 1),
        getValue('easingStyle', Enum.EasingStyle.Linear),
        getValue('easingDirection', Enum.EasingDirection.InOut),
        getValue('repeatCount', 0),
        getValue('reverses', false),
        getValue('delayTime', 0)
    )
end