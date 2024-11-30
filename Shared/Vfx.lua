-- ### Roblox Modules
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ### Modules
local Part = require(script.Parent.Part)
local Folder = require(script.Parent.Folder)
local Assets = require(script.Parent.Assets)
local Weld = require(script.Parent.Weld)

local vfxFolder = Folder.getOrCreate({
    Parent = workspace,
    Name = "VfxFolder"
})

local Vfx = {}

local AttributeIsNumberSequence = {
    "Size", "Squash", "Transparency"
}

function Vfx.CreateOrigin(cframe: CFrame)
    local part = Part.create({
        Anchored = true,
        CanCollide = false,
        CanQuery = false,
        CanTouch = false,
        Transparency = 0.5,
        CFrame = cframe,
        Size = Vector3.one,
        Parent = vfxFolder,
    })
    return part
end

function Vfx.Emit(instance: Instance, attributes)
    attributes = attributes or {}
    for _, child in instance:GetDescendants() do
        if child:IsA("ParticleEmitter") then

            -- attributes
            for key, value in attributes or {} do
                if key == 'delay' then continue end
                if typeof(value) == "function" then
                    value = value()
                end

                if (key == "Size" or key == "Transparency" or key == "Squash") and typeof(value) == "number" then
                    value = NumberSequence.new(value)
                end
                if (key == "Lifetime") and typeof(value) == "number" then
                    value = NumberRange.new(value)
                end
                if key == "Color" and typeof(value) == "Color3" then
                    value = ColorSequence.new(value)
                end

                pcall(function()
                    child[key] = value
                end)
            end

            -- delay & emit


            local emitDelay = child:GetAttribute("EmitDelay") or 0
            local emitCount = child:GetAttribute("EmitCount") or 10
            local emitDuration = child:GetAttribute("EmitDuration") or 0

            if attributes.duration ~= nil then
                if emitDelay ~= 0 and emitDelay == emitDuration then
                    emitDelay = attributes.duration
                end
                if emitDuration ~= 0 then
                    emitDuration = attributes.duration
                end
            end
            
            task.spawn(function()
                if emitDelay > 0 then
                    task.wait(emitDelay)
                end

                if emitDuration == 0 then
                    child:Emit(emitCount)
                else
                    child.Rate = emitCount
                    child.Enabled = true
                    task.wait(emitDuration)
                    child.Enabled = false
                end
            end)
            
        end
    end
end

function Vfx.EmitAt(cframe:CFrame, instance: Instance, attributes, weldOn)
    task.spawn(function()
        attributes = attributes or {}
        if attributes.delay ~= nil then
            task.wait(attributes.delay)
        end
        if typeof(instance) == 'string' then
            instance = Assets.WaitForPath(instance)
        end
        local origin
        if instance:IsA("BasePart") then
            local fx = instance:Clone()
            origin = fx
            fx.CanCollide = false
            fx.CanQuery = false
            fx.CanTouch = false
            fx.Transparency = 1
            fx.CFrame = cframe
            fx.Parent = vfxFolder
            Debris:AddItem(fx, 10)
            Vfx.Emit(fx, attributes)
        else
            local fx = Vfx.CreateOrigin(cframe)
            origin = fx
            Debris:AddItem(fx, 1)
        end
    
        if weldOn ~= nil then
            origin.Anchored = false
            Weld(weldOn, origin)
        end
    end)
end

return Vfx