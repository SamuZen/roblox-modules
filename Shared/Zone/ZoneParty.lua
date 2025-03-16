-- ZoneManager.lua
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(game:GetService("ReplicatedStorage").Source.Packages.trove)
local RunService = game:GetService("RunService")
local Fusion = require(ReplicatedStorage.Source.Fusion)
local Zone = require(ReplicatedStorage.Source.Packages.zoneplus)
local FusionHelper = require(ReplicatedStorage.Source.Modules.FusionHelper)

local ZoneManager = {}
ZoneManager.__index = ZoneManager

function ZoneManager.new(trigger, timer, callback)
    local scope = Fusion.scoped(Fusion)


    local zone = Zone.new(trigger)
    local players = scope:Value({})
    local playerCount = scope:Computed(function(use, scope)
        return #use(players)
    end)    
    local countDown = scope:Value(timer)

    local function removePlayer(player)
        local _players = Fusion.peek(players)
        local i = table.find(_players, player)
        if i == nil then return end
        table.remove(_players, i)
        players:set(_players)
    end

    -- reduce
    RunService.Heartbeat:Connect(function(deltaTime)
        if Fusion.peek(playerCount) > 0 then
            countDown:set(Fusion.peek(countDown) - deltaTime)
        else
            countDown:set(timer)
        end
    end)

    FusionHelper.ObserverCallback(scope, countDown, function(value)
        if value <= 0 then
            local _players = Fusion.peek(players)
            countDown:set(timer)
            callback(_players)
            for _, player in _players do
                removePlayer(player)
            end
        end
    end)

    local billboard = scope:New("BillboardGui") {
        Size = UDim2.fromScale(5, 5),
        [Fusion.Children] = {
            scope:New("TextLabel") {
                Text = scope:Computed(function(use, scope)
                    return `{use(playerCount)} - {use(countDown)}`
                end),
                Size = UDim2.fromScale(1, 1),
            }
        }
    }
    billboard.Parent = trigger

    zone.playerEntered:Connect(function(player: Player)
        local _players = Fusion.peek(players)
        table.insert(_players, player)
        players:set(_players)
    end)

    zone.playerExited:Connect(function(player: Player)
        removePlayer(player)
    end)


end

function ZoneManager:Destroy()
    self.trove:Destroy()
end

return ZoneManager
