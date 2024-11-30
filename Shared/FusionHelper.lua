local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Source.Fusion)

local FusionHelper = {}

function FusionHelper.ObserverCallback(scope, watching, callback)
    local observer = scope:Observer(watching)
    callback(Fusion.peek(watching))
    return observer:onChange(function()
        callback(Fusion.peek(watching))
    end)
end

function FusionHelper.ObserverCallbackWithPrevious(scope, watching, callback)
    local observer = scope:Observer(watching)
    local previous = Fusion.peek(watching)
    callback(previous, previous)
    return observer:onChange(function()
        local now = Fusion.peek(watching)
        callback(previous, now)
        previous = now
    end)
end

return FusionHelper