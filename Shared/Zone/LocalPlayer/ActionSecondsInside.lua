-- ZoneManager.lua
local Trove = require(game:GetService("ReplicatedStorage").Source.Packages.trove)
local Time = require(game:GetService("ReplicatedStorage").Source.Modules.Time)

local ZoneManager = {}
ZoneManager.__index = ZoneManager

function ZoneManager.new(zone, timer, callback)
    local self = setmetatable({}, ZoneManager)
    self.trove = Trove.new()

    zone.localPlayerEntered:Connect(function(_: Player)
        print(timer)
        self.trove:Add(Time.onIntervalPassed(timer, 1, callback))
    end)

    zone.localPlayerExited:Connect(function(_: Player)
        self.trove:Clean()
    end)

    return self
end

function ZoneManager:Destroy()
    self.trove:Destroy()
end

return ZoneManager
