-- ### Roblox Services
local RunService = game:GetService("RunService")

local Time = {}

function Time.onTimePassed(time: number, callback:() -> nil): RBXScriptConnection
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if os.clock() - time >= 0 then
            connection:Disconnect()
            callback()
        end
    end)
    return connection
end

function Time.onIntervalPassed(interval: number, duration: number, callback:(elapsed: number) -> nil): RBXScriptConnection
    local myDt = 0
    local elapsed = 0
    local connection
    connection = RunService.Heartbeat:Connect(function(deltaTime)
        myDt += deltaTime
        if myDt >= interval then
            myDt -= interval
            elapsed += interval
            callback(elapsed)
            if duration and elapsed >= duration then
                connection:Disconnect()
            end
        end
    end)
    return connection
end

return Time