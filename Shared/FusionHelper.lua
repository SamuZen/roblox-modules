local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Source.Fusion)
local Observer = Fusion.Observer


local FusionHelper = {}

function FusionHelper.ObserverCallback(scope, watching, callback)
    local observer = scope:Observer(watching)
    callback(Fusion.peek(watching))
    return observer:onChange(function()
        callback(Fusion.peek(watching))
    end)
end

return FusionHelper