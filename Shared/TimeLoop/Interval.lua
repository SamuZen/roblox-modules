-- ### Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ### Packages
local Signal = require(ReplicatedStorage.Source.Packages.signal)

export type Class = {
    new: (id: string, duration: number) -> nil,
    is: (obj: table) -> boolean,
}
export type ClassInstance = {
    id: string,
    duration: number,
    running: boolean,
    startTime: number,
    endTime: number,

    tick: () -> nil,
    finished: () -> boolean,

    onStart: Signal.Signal,
    onFinished: Signal.Signal,
    onTick: Signal.Signal<number>,
}
export type ClassPrivateInstance = {}

local Interval : Class | ClassInstance | ClassPrivateInstance = {}
Interval.__index = Interval

function Interval.new(id: string, duration: number): ClassInstance
    local self: ClassInstance | ClassPrivateInstance = setmetatable({}, Interval)

    self.id = id
    self.duration = duration
    self.running = false
    self.startTime = nil
    self.endTime = nil

    self.onStart = Signal.new()
    self.onFinished = Signal.new()
    self.onTick = Signal.new()

    return self
end

function Interval:tick()
    -- check start
    if self.running == false then
        self.startTime = os.clock()
        self.endTime = self.startTime + self.duration
        self.running = true
        self.onStart:Fire()
    end

    -- tick
    local timeLeft = math.round(self.endTime - os.clock())
    self.onTick:Fire(timeLeft)

    if timeLeft <= 0 then
        self.running = false
        self.onFinished:Fire()
    end

end

function Interval:finished(): boolean
    return not self.running
end

function Interval.is(obj: any)
    return type(obj) == "table" and obj.id and obj.duration
end

return Interval :: Class