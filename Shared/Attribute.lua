local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FusionHelper = require(script.Parent.FusionHelper)
local Serialization = require(ReplicatedStorage.Source.Modules.Serialization)

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

function Attribute.SyncAttributeToFusion(instance: Instance, attribute: string, scope, val, default)
    val:set(instance:GetAttribute(attribute) or default)
    local connection = instance:GetAttributeChangedSignal(attribute):Connect(function()
        val:set(instance:GetAttribute(attribute) or default)
    end)
    table.insert(scope, function()
        connection:Disconnect()
    end)
end

function Attribute.SetStringArray(instance: Instance, attribute: string, value: table)
    instance:SetAttribute(attribute, Serialization.serializeStringArray(value))
end

function Attribute.GetStringArray(instance: Instance, attribute)
    return Serialization.deserializeStringArray(instance:GetAttribute(attribute))
end

function Attribute.Increment(instance: Instance, attribute: string, increment: number)
    local now = instance:GetAttribute(attribute)
    instance:SetAttribute(attribute, now + increment)
end

function Attribute.CloneAttribute(origin: Instance, target: Instance, attribute: string)
    return Attribute.SyncFromAttribute(origin, attribute, function(value)
        target:SetAttribute(attribute, value)
    end)
end

return Attribute