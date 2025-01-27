-- ZoneManager.lua
local Trove = require(game:GetService("ReplicatedStorage").Source.Packages.trove)
local Time = require(game:GetService("ReplicatedStorage").Source.Modules.Time)

local ZoneManager = {}
ZoneManager.__index = ZoneManager

function ZoneManager.new(zone, enterCallback, exitCallback)
    local self = setmetatable({}, ZoneManager)
    self.trove = Trove.new()

    zone.localPlayerEntered:Connect(function(_: Player)
        if enterCallback ~= nil then
            enterCallback()
        end
    end)

    zone.localPlayerExited:Connect(function(_: Player)
        if exitCallback ~= nil then
            exitCallback()
        end
    end)

    return self
end

function ZoneManager:Destroy()
    self.trove:Destroy()
end

return ZoneManager
