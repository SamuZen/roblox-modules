-- ### Roblox Services
local RunService = game:GetService("RunService")

local Time = {}

function Time.getCurrentTime(): number
    return os.time(os.date("!*t"))
end

function Time.getCurrentDecimalTime(): number
    return os.time(os.date("!*t")) + (os.clock() % 1)
end

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

function Time.createTimerDisplay(duration: number, position: Vector3)

    local cleanupFunction

    local p = Instance.new("Part")
    p.CanQuery = false
    p.CanTouch = false
    p.CanCollide = false
    p.Transparency = 1
    p.Anchored = true
    p.CFrame = CFrame.new(position)

    local billboard = Instance.new("BillboardGui")
    billboard.Parent = p
    billboard.Size = UDim2.fromScale(8, 3)

    billboard.MaxDistance = 50
    
    local text = Instance.new("TextLabel")
    text.BackgroundTransparency = 1
    text.Size = UDim2.fromScale(1, 1)
    text.TextScaled = true
    text.Parent = billboard
    text.TextColor3 = Color3.new(1, 1, 1)
    text.Font = Enum.Font.FredokaOne

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.new(0, 0, 0)
    stroke.Parent = text

    local connection = Time.onIntervalPassed(0.1, duration, function(elapsed)
        local timeLeft = (duration - elapsed) + 1
        local minutes = math.floor(timeLeft / 60)
        local seconds = timeLeft % 60
        text.Text = string.format("%02d:%02d", minutes, seconds)
        if timeLeft <= 1 then
            cleanupFunction()
        end
    end)

    p.Parent = workspace

    cleanupFunction = function ()
        print("CLEANUP")
        connection:Disconnect()
        text:Destroy()
        billboard:Destroy()
        p:Destroy()
    end

    return cleanupFunction
end

return Time