-- ### Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ### Packages
local Trove = require(ReplicatedStorage.Source.Packages.trove)
local Signal = require(ReplicatedStorage.Source.Packages.signal)

-- ### Modules
local Time = require(ReplicatedStorage.Source.Modules.Time)

-- ### Internal
local Interval = require(script.Interval)


export type Class = {
    new: () -> ClassInstance,
    newInterval: (id: string, duration: number) -> Interval.ClassInstance,
}

export type ActionOrInterval = () -> nil | Interval.ClassInstance

export type PrivateClassInstance = {
    actions: {[number] : {
        actionType: "interval" | "function",
        action: ActionOrInterval,
    }},
    intervals: {[string]: Interval.ClassInstance},
    index: number,
    trove: typeof(Trove),
}

export type ClassInstance = {
    add: (nil, actionOrInterval: ActionOrInterval) -> nil,
    start: (nil, tickInterval: number) -> nil,
    stop: () -> nil,

    onIntervalTick: (nil, id: string, callback: (timeLeft: number) -> nil) -> nil,
    onIntervalStart: (nil, id: string, callback: (timeLeft: number) -> nil) -> nil,
    onIntervalFinished: (nil, id: string, callback: (timeLeft: number) -> nil) -> nil,

    onTick: Signal.Signal<number>,
    onStart: Signal.Signal<string>,
    onFinished: Signal.Signal<string>,
}

local TimeLoop: Class | ClassInstance | PrivateClassInstance = {}
TimeLoop.__index = TimeLoop

function TimeLoop.new(): ClassInstance
    local self = setmetatable({}, TimeLoop)

    self.actions = {}
    self.intervals = {}
    self.index = 1

    self.trove = Trove.new()

    self.onTick = Signal.new()
    self.onStart = Signal.new()
    self.onFinished = Signal.new()

    return self
end

function TimeLoop.newInterval(id: string, duration: number): Interval.ClassInstance
    return Interval.new(id, duration)
end

function TimeLoop:add(actionOrInterval: ActionOrInterval)
    if type(actionOrInterval) == "function" then
        self.actions[#self.actions + 1] = {
            actionType = "function",
            action = actionOrInterval
        }
    elseif Interval.is(actionOrInterval) then
        local interval = actionOrInterval :: Interval.ClassInstance
        self.actions[#self.actions + 1] = {
            actionType = "interval",
            action = interval
        }

        self.trove:Add(interval.onTick:Connect(function(timeLeft)
            self.onTick:Fire(timeLeft)
        end))

        self.trove:Add(interval.onStart:Connect(function()
            self.onStart:Fire(interval.id, interval.duration)
        end))

        self.trove:Add(interval.onFinished:Connect(function()
            self.onFinished:Fire(interval.id)
        end))

        self.intervals[interval.id] = interval
    end
end

function TimeLoop:start(tickRate: number)
    self.index = 1
    if self.index > #self.actions then
        warn("Cannot start a timeloop without actions")
        return
    end

    self.trove:Add(Time.onIntervalPassed(tickRate, nil, function(elapsed: number)
        self:tick()
    end))
end

function TimeLoop:stop()
    self.trove:Clean()
end

function TimeLoop:tick()
    local actionObj = self.actions[self.index]
    
    if actionObj.actionType == "function" then
        actionObj.action()
        self:stepFinished()

    elseif actionObj.actionType == "interval" then
        local action = actionObj.action :: Interval.ClassInstance
        action:tick()

        if action:finished() then
            self:stepFinished()
        end
    end


end

function TimeLoop:stepFinished()
    self.index += 1
    if self.index > #self.actions then self.index = 1 end
end

-- ### Interval Signals

function TimeLoop:onIntervalStart(id, callback)
    return self.intervals[id].onStart:Connect(callback)
end

function TimeLoop:onIntervalFinished(id, callback)
    return self.intervals[id].onFinished:Connect(callback)
end

function TimeLoop:onIntervalTick(id, callback)
    return self.intervals[id].onTick:Connect(callback)
end

return TimeLoop