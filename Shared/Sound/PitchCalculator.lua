export type Config = {
    minPitch: number,
    maxPitch: number,
    maxValue: number,
    loop: boolean,
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

    return self
end

function PitchCalculator:getPitch(value: number): number
    local v = value

    if self.config.loop then
        if v > self.config.maxValue then
            local rest = value % self.config.maxValue
            if rest ~= 0 then
                v = rest
            end
        end
    end
    
    if v > self.config.maxValue then
        warn('max')
        return self.config.maxPitch
    end

    local pitch = self.config.minPitch + (self.pitchIncrement * (v - 1))
    return pitch
end

return PitchCalculator