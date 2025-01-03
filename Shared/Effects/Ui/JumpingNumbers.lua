-- ### Roblox services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- ### Fusion
local Fusion = require(ReplicatedStorage.Source.Fusion)

-- ### Var
local info = TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

local DamageNumbers = {}

local function createBillboard(text, color, sizeMultiplier): BillboardGui
    local scope = Fusion.scoped(Fusion)
	local billboard = scope:New "BillboardGui" {
		Enabled = true,
		Size = UDim2.fromScale(2,2),
		[Fusion.Children] = {
			scope:New "TextLabel" {
				Size = UDim2.fromScale(1 * sizeMultiplier, 0.5 * sizeMultiplier),
				TextScaled = true,
				Text = if sizeMultiplier > 1 then `-{text}` else text,
				TextColor3 = color or Color3.new(1,1,1),
				BackgroundTransparency = 1,
				Font = Enum.Font.FredokaOne,
				[Fusion.Children] = {
					scope:New "UIStroke" {}
				}
			}
		}
	}
	billboard.Enabled = true
	return billboard
end

local offset = Vector3.new(0, 4, 0)
local range = 0.5

local defaultColor = Color3.new(1,1,1)
function DamageNumbers.createNumber(position: Vector3, damage: number, color: Color3?, sizeMultiplier: number)
	sizeMultiplier = sizeMultiplier or 1
    color = color or defaultColor

    local part = Instance.new("Part")
	part.CanCollide = false
	part.CanQuery = false
	part.CastShadow = false
	part.Transparency = 1
	part.Anchored = false
	part:PivotTo(CFrame.new(position))
	part.Anchored = true
	part.Parent = workspace

	local billboard = createBillboard(tostring(math.ceil(damage)), color, sizeMultiplier)
    billboard.AlwaysOnTop = true
	billboard.StudsOffset = Vector3.new(math.random(-2, 2), math.random(0, 2), 0)
	billboard.Parent = part
	billboard.Adornee = part

	local tween = TweenService:Create(billboard, info, {
		StudsOffset = billboard.StudsOffset + Vector3.new(0, 6, 0)
	})
	tween:Play()
	tween:Destroy()

	--- apply random upwards force
	--local randUpwardsForce = Vector3.new(math.random(-10, 10), math.random(30, 35), math.random(-10, 10));
	--part:ApplyImpulse(randUpwardsForce * part.AssemblyMass)

	task.delay(2.5, function()
		part:Destroy()
	end)
end

function DamageNumbers.createText(position: Vector3, text: string, color: Color3?)
	local part = Instance.new("Part")
	part.CanCollide = false
	part.CanQuery = false
	part.CastShadow = false
	part.Transparency = 1
	part.Anchored = true

	local randomOffset = Vector3.new(math.random(-range, range), math.random(-range, range), math.random(-range, range))
	part:PivotTo(CFrame.new(position + offset + randomOffset))
	part.Parent = workspace

	local billboard = createBillboard(text, color)
	billboard.Size = UDim2.fromScale(8,3)
	billboard.Parent = part
	billboard.Adornee = part

	--- apply random upwards force
	local randUpwardsForce = Vector3.new(math.random(-10, 10), math.random(30, 35), math.random(-10, 10));
	part:ApplyImpulse(randUpwardsForce * part.AssemblyMass)

	task.delay(0.8, function()
		part:Destroy()
	end)
end

return DamageNumbers