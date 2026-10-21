local module = {}

local sides = { "Left", "Right" }

-- Server only. Keep authored slots/motors intact, including their bind frames.
function module.SetupHandSlots(model: Model)
    assert(game:GetService("RunService"):IsServer(), "Hand slots must be created on the server")
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.RigType ~= Enum.HumanoidRigType.R6 then return false end

    for _, side in sides do
        local arm = model:WaitForChild(side .. " Arm", 10)
        if not arm or not arm:IsA("BasePart") or not model.Parent then return false end
        local name = side .. "HandSlot"
        local slot = model:FindFirstChild(name)
        local motor = arm:FindFirstChild(name)
        assert(not slot or slot:IsA("BasePart"), "Expected a BasePart at " .. name)
        assert(not motor or motor:IsA("Motor6D"), "Expected a Motor6D at " .. name)
        assert(not motor or (motor.Part0 == arm and motor.Part1 == slot and slot ~= nil),
            "Existing hand slot motor is connected to a different part: " .. name)

        local bind
        if not slot then
            local grip = arm:FindFirstChild(side .. "GripAttachment")
            local position = if grip and grip:IsA("Attachment") then grip.Position
                else Vector3.new(0, -arm.Size.Y / 2, 0)
            -- Grove's slots share the arm's local axes. Standard R6 grip
            -- attachments may be rotated; copying that rotation turns our weapons.
            bind = CFrame.new(position)
            slot = Instance.new("Part")
            slot.Name, slot.Size = name, Vector3.new(0.2, 0.2, 0.2)
            slot.Transparency, slot.CastShadow = 1, false
            slot.Anchored, slot.Massless = false, true
            slot.CanCollide, slot.CanTouch, slot.CanQuery = false, false, false
            slot.CFrame = arm.CFrame * bind
        else
            bind = arm.CFrame:ToObjectSpace(slot.CFrame)
        end

        if not slot:FindFirstChild("GripAttachment") then
            local attachment = Instance.new("Attachment")
            attachment.Name = "GripAttachment"
            attachment.Parent = slot
        end
        if not motor then
            motor = Instance.new("Motor6D")
            motor.Name, motor.Part0, motor.Part1 = name, arm, slot
            motor.C0, motor.C1 = bind, CFrame.identity
            motor.Parent = arm
        end
        slot.Parent = model
    end
    return true
end

-- Wait for the actual replicated joints, not just a readiness Attribute:
-- Part0/Part1 references may arrive after the slot itself.
function module.WaitForHandSlots(model: Model, timeout: number?): boolean
    local deadline = os.clock() + (timeout or 10)
    repeat
        if not model.Parent then return false end
        local ready = true
        for _, side in sides do
            local arm = model:FindFirstChild(side .. " Arm")
            local slot = model:FindFirstChild(side .. "HandSlot")
            local motor = arm and arm:FindFirstChild(side .. "HandSlot")
            local grip = slot and slot:FindFirstChild("GripAttachment")
            if not arm or not arm:IsA("BasePart") or not slot or not slot:IsA("BasePart")
                or not motor or not motor:IsA("Motor6D") or motor.Part0 ~= arm or motor.Part1 ~= slot
                or not grip or not grip:IsA("Attachment") then
                ready = false
                break
            end
        end
        if ready then return true end
        task.wait(0.05)
    until os.clock() >= deadline
    return false
end

return module
