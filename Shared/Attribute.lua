local FusionHelper = require(script.Parent.FusionHelper)

local Attribute = {}

function Attribute.SyncFromAttribute(instance: Instance, attribute: string, callback: (any) -> nil, ignoreFirst: boolean): RBXScriptConnection
    if not ignoreFirst then
        callback(instance:GetAttribute(attribute))
    end
    return instance:GetAttributeChangedSignal(attribute):Connect(function()
        callback(instance:GetAttribute(attribute))
    end)
end

function Attribute.SyncFusionToAttribute(instance: Instance, attribute: string, scope, value)
    FusionHelper.ObserverCallback(scope, value, function(result)
        instance:SetAttribute(attribute, result)
    end)
end

function Attribute.SyncAttributeToFusion(instance: Instance, attribute: string, val, default)
    val:set(instance:GetAttribute(attribute) or default)
    instance:GetAttributeChangedSignal(attribute):Connect(function()
        val:set(instance:GetAttribute(attribute) or default)
    end)
end

function Attribute.Increment(instance: Instance, attribute: string, increment: number)
    local now = instance:GetAttribute(attribute)
    instance:SetAttribute(attribute, now + increment)
end

return Attribute