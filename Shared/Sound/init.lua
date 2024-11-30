--- ### Roblox services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

--- ### Modules
local Part = require(script.Parent.Part)

local Sound = {}

function Sound.soundId(id: string): string
    if string.find(id, "rbxassetid://") then return id end
    return "rbxassetid://" .. id
end

function Sound.CreateSound(soundId: string): Sound
    local sound = Instance.new("Sound")
    sound.SoundId = Sound.soundId(soundId)
    return sound
end

function Sound.PlayLocalSound(soundId: string, pitch: number)
    if RunService:IsServer() then
        error("PlayLocalSound can only be called from the client")
    end
    task.spawn(function()
        local sound = Sound.CreateSound(soundId)

        if pitch ~= nil then
            local pitchFx = Instance.new("PitchShiftSoundEffect")
            pitchFx.Parent = sound
            pitchFx.Octave = pitch
        end

        SoundService:PlayLocalSound(sound)

        sound.Ended:Once(function()
            sound:Destroy()
        end)
    end)
end

function Sound.PlayWorldSound(soundId: string, position: Vector3, pitch: number)
    task.spawn(function()
        local part = Part.create({
            Parent = workspace,
            CanCollide = false,
            CanQuery = false,
            CanTouch = false,
            Transparency = 1,
            Anchored = true,
        })
        part:PivotTo(CFrame.new(position))
        
        local sound = Sound.CreateSound(soundId)

        if pitch ~= nil then
            local pitchFx = Instance.new("PitchShiftSoundEffect")
            pitchFx.Parent = sound
            pitchFx.Octave = pitch
        end

        sound.Parent = part
        part.Parent = workspace

        sound:Play()
        sound.Ended:Once(function()
            part:Destroy()
        end)
    end)
end

return Sound