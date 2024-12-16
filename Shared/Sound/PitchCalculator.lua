export type Config = {
    minPitch: number,
    maxPitch: number,
    maxValue: number,
    loop: boolean,
    maxInterval: number,
}

export type ClassInstance = {
    config: Config,
    interval: number,
    pitchIncrement: number,
}

local PitchCalculator: ClassInstance = {}
PitchCalculator.__index = PitchCalculator

function PitchCalculator.new(config: Config)
    local self = setmetatable({}, PitchCalculator)
    
    local pitchVariation = config.maxPitch - config.minPitch

    self.config = config
    self.pitchIncrement = pitchVariation / (config.maxValue - 1)

    self.maxInterval = config.maxInterval
    self.sequences = {}

    return self
end

function PitchCalculator:addToSequence(id: string)
    if self.sequences[id] == nil then
        self.sequences[id] = {
            amount = 0,
            t = 0,
        }
    end

    local newT = os.clock()
    if newT - self.sequences[id].t > self.maxInterval then
        self.sequences[id].amount = 0
    end

    self.sequences[id].amount += 1
    self.sequences[id].t = newT
end

function PitchCalculator:getPitch(id: string): number
    local v = self.sequences[id].amount

    if self.config.loop then
        if v > self.config.maxValue then
            local rest = v % self.config.maxValue
            if rest ~= 0 then
                v = rest
            end
        end
    end
    
    if v > self.config.maxValue then
        return self.config.maxPitch
    end

    local pitch = self.config.minPitch + (self.pitchIncrement * (v - 1))
    return pitch
end

return PitchCalculator