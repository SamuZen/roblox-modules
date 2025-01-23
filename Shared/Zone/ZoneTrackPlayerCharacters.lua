-- ZoneManager.lua
local Trove = require(game:GetService("ReplicatedStorage").Source.Packages.trove)
local Time = require(game:GetService("ReplicatedStorage").Source.Modules.Time)

local ZoneManager = {}
ZoneManager.__index = ZoneManager

function ZoneManager.new(zone, onFirstEntered)
    local self = setmetatable({}, ZoneManager)
    self.zone = zone
    self.trove = Trove.new()

    self.inside = 0
    self.players = {}
    self.characters = {}

    zone.playerEntered:Connect(function(player: Player)
        self.inside += 1
        self.players[player] = true
        self.characters[player] = player.Character
        if onFirstEntered ~= nil then
            onFirstEntered(player.Character)
        end
    end)

    zone.playerExited:Connect(function(player: Player)
        self.inside -= 1
        self.players[player] = nil
        self.characters[player] = nil
    end)

    return self
end

function ZoneManager:HasPlayer()
    return self.inside > 0
end

function ZoneManager:GetRandomCharacter()
    if not self:HasPlayer() then return end
    local characters = {}
    for player, character in self.characters do
        table.insert(characters, character)
    end

    return characters[math.random(1, #characters)]
end

function ZoneManager:Destroy()
    self.trove:Destroy()
end

return ZoneManager
