--!strict

--[[
    CooldownHelper - Static utility functions for managing cooldowns
    
    Usage:
        local cooldowns = {}
        if CooldownHelper.checkAndSetCooldown(cooldowns, "greeting_123", 3) then
            -- Action allowed, cooldown set
        else
            -- Action blocked, on cooldown
        end
]]

local CooldownHelper = {}

--[[
    Check if a cooldown is currently active
    @param cooldownTable - Table to check cooldowns in
    @param key - Cooldown key to check
    @return isOnCooldown (boolean), remainingTime (number?) - true if on cooldown, remaining seconds if applicable
]]
function CooldownHelper.isOnCooldown(cooldownTable: {[string]: number}?, key: string): (boolean, number?)
    if not cooldownTable or not cooldownTable[key] then 
        return false 
    end
    
    local now = os.clock()
    if now >= cooldownTable[key] then
        cooldownTable[key] = nil -- Clean up expired cooldown
        return false
    end
    
    return true, cooldownTable[key] - now
end

--[[
    Set a cooldown for a specific key
    @param cooldownTable - Table to store cooldown in
    @param key - Cooldown key
    @param durationSeconds - How long the cooldown should last
]]
function CooldownHelper.setCooldown(cooldownTable: {[string]: number}?, key: string, durationSeconds: number)
    if not cooldownTable then
        warn("Cannot set cooldown on nil table")
        return -- Cannot set cooldown on nil table
    end
    cooldownTable[key] = os.clock() + durationSeconds
end

--[[
    Set cooldown if not already active, then check if on cooldown
    @param cooldownTable - Table to check and set cooldown in
    @param key - Cooldown key
    @param durationSeconds - How long the cooldown should last if set
    @return isOnCooldown (boolean) - true if on cooldown (action blocked), false if cooldown was set (action allowed)
]]
function CooldownHelper.setAndCheckOnCooldown(cooldownTable: {[string]: number}, key: string, durationSeconds: number): boolean
    if CooldownHelper.isOnCooldown(cooldownTable, key) then
        return true -- Return true = cooldown is active, block the action
    end
    CooldownHelper.setCooldown(cooldownTable, key, durationSeconds)
    return false -- Return false = no cooldown, action allowed
end

--[[
    Clear a specific cooldown or all cooldowns
    @param cooldownTable - Table to clear cooldowns from
    @param key - Specific key to clear, or nil to clear all cooldowns
]]
function CooldownHelper.clearCooldown(cooldownTable: {[string]: number}, key: string?)
    if key then
        cooldownTable[key] = nil
    else
        -- Clear all cooldowns
        for k in pairs(cooldownTable) do
            cooldownTable[k] = nil
        end
    end
end

--[[
    Get the remaining time for a cooldown (useful for debugging/logging)
    @param cooldownTable - Table to check cooldown in
    @param key - Cooldown key to check
    @return remainingTime (number?) - seconds remaining, or nil if not on cooldown
]]
function CooldownHelper.getRemainingTime(cooldownTable: {[string]: number}, key: string): number?
    local onCooldown, remainingTime = CooldownHelper.isOnCooldown(cooldownTable, key)
    return onCooldown and remainingTime or nil
end

return CooldownHelper