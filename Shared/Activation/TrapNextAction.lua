-- ActivationManager.lua
local ActivationManager = {}
ActivationManager.__index = ActivationManager

function ActivationManager.new(instance)
    local self = setmetatable({}, ActivationManager)
    self.instance = instance
    return self
end

function ActivationManager:isActivated()
    local nextAction = self.instance:GetAttribute("NextAction") or 0
    return nextAction > workspace:GetServerTimeNow()
end

function ActivationManager:activate(t, callback)
    if self:isActivated() then return end
    self.instance:SetAttribute("NextAction", workspace:GetServerTimeNow() + t)
    task.delay(t, function()
        if callback ~= nil then
            callback()
        end
    end)
end

return ActivationManager
