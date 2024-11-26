-- ### Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ### Fusion
local Fusion = require(ReplicatedStorage.Source.Fusion)
local Value = Fusion.Value
local Computed = Fusion.Computed

export type Modifier = {
    id: string | nil,
    add: {[string]: number},
    mult: {[string]: number},
}

export type Base = {[string]: number}

export type Typed = {
    mBase: Base,
    mFinal: Fusion.UsedAs<{[string]: number}>,
    mModifiers: Fusion.UsedAs<{[string]: Modifier}>
}

local Stats : Typed = {}
Stats.__index = Stats

function Stats.new(baseStats: Base)
    local self = setmetatable({}, Stats)
    local scope = {}

    self.mBase = {}
    self.mModifiers = Value(scope, {})

    -- shallow copy initial stats
    local finals = {}
    for k, v in pairs(baseStats) do
        self.mBase[k] = v
        finals[k] = Computed(scope, function(use, _)
            local total = self.mBase[k]
            local multiplier = 0

            for _, modifier in use(self.mModifiers) do
                total = total + (modifier.add[k] or 0)
                multiplier = multiplier + (modifier.mult[k] or 0)
            end

            return total + (total * multiplier)
        end)
    end
    self.mFinal = Value(scope, finals)
    return self
end

function Stats:getBase(id)
    return self.mBase[id]
end

function Stats:get(id)
    return Fusion.peek(self.mFinal)[id]
end

function Stats:getAll()
    return Fusion.peek(self.mFinal)
end

function Stats:addModifier(modifier: Modifier, id: string)
    if modifier.id ~= nil then
        id = modifier.id
    end
    
    local currentModifiers = Fusion.peek(self.mModifiers)
    currentModifiers[id] = {
        add = modifier.add or {},
        mult = modifier.mult or {},
    }

    self.mModifiers:set(currentModifiers)
end

function Stats:removeModifier(id)
    local currentModifiers = Fusion.peek(self.mModifiers)
    currentModifiers[id] = nil
    self.mModifiers:set(currentModifiers)
end

return Stats