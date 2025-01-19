-- ZoneManager.lua
local Trove = require(game:GetService("ReplicatedStorage").Source.Packages.trove)
local Time = require(game:GetService("ReplicatedStorage").Source.Modules.Time)

local ZoneManager = {}
ZoneManager.__index = ZoneManager

function ZoneManager.new(zone, onActivation, onLoop, onDeactivation, loopDelay)
    local self = setmetatable({}, ZoneManager)
    self.zone = zone
    self.trove = Trove.new()
    self.inside = 0
    self.loopDelay = loopDelay or 1.5

    zone.playerEntered:Connect(function(_: Player)
        self.inside += 1
        if self.inside == 1 then
            onActivation()
            self.trove:Clean()
            self.trove:Add(Time.onIntervalPassed(self.loopDelay, nil, function()
                onLoop()
            end))
        end
    end)

    zone.playerExited:Connect(function(_: Player)
        self.inside -= 1
        if self.inside == 0 then
            self.trove:Clean()
            if onDeactivation then
                onDeactivation()
            end
        end
    end)

    return self
end

function ZoneManager:Destroy()
    self.trove:Destroy()
end

return ZoneManager
