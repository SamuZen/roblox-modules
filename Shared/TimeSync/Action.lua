local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Fusion = require(ReplicatedStorage.Source.Fusion)

-- ### Controllers
local SyncController

if RunService:IsClient() then
    SyncController = require(ReplicatedStorage.Source.Shared.Client.Controllers.TimeSyncController)
else
    SyncController = require(ServerStorage.Source.Shared.Server.Services.TimeSyncService)
end

local ActionSync = {}

function ActionSync.new(scope, interval: number, delay: number, callback: (cycle: number) -> nil)
    delay = delay or 0
    interval = interval or 5
    local scope = scope or Fusion.scoped(Fusion)

    local currentCycle = scope:Computed(function(use, scope)
        return math.floor((use(SyncController.serverTime) - delay) / interval)
    end)
    scope:Observer(currentCycle):onChange(function()
        callback(Fusion.peek(currentCycle))
    end)

    local fixedTimeLeft = scope:Computed(function(use, scope) 
        return interval - ((use(SyncController.serverTime) - delay) % interval)
    end)

    return {
        currentCycle = currentCycle,
        fixedTimeLeft = fixedTimeLeft,
        scope = scope,
    }
end

return ActionSync