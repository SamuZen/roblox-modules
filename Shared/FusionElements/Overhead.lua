-- ### Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Fusion = require(ReplicatedStorage.Source.Fusion)
local New = Fusion.New
local Children = Fusion.Children

-- ### Fusion Components
local Fillbar = require(script.Parent.FillBar)
local BaseText = require(script.Parent.BaseText)

-- ### ColorSequences
local RainbowSequence = require(script.Parent.ColorSequences.rainbow)
local Blue = require(script.Parent.ColorSequences.blue01)
local GreenHard = require(script.Parent.ColorSequences.green)
local Metalic = require(script.Parent.ColorSequences.metalic)

type UsedAs<T> = Fusion.UsedAs<T>

local function Overhead(
    scope: Fusion.Scope<typeof(Fusion)>,
    props: {

    }
)

    -- ### Constants
    local t = os.clock()

    -- ### States
    local name = props.Name or "User Name"

    local maxHealth = props.MaxHealth or scope:Value(100)
    local currentHealth = props.CurrentHealth or scope:Value(80)
    local level = props.Level or scope:Value(10)

    -- ### Effects
    local vip = props.Vip or scope:Value(false)
    local protected = props.Protected or scope:Value(false)
    local shield = props.Shield or scope:Value(0)

    -- ### Variable States
    local movingRotation = scope:Value(0)
    local heartBeat = RunService.RenderStepped:Connect(function(deltaTime)
        local delta = (os.clock() - t) * 1
        local wave = math.sin(delta) + 2
        movingRotation:set(wave * 45)
    end)

    return scope:New "CanvasGroup" {
        AnchorPoint = Vector2.new(0.5, 0.5),
		Position = props.Position or UDim2.fromScale(0.5, 0.5),
		Size = props.Size or UDim2.fromOffset(400,300),
		BackgroundTransparency = props.BackgroundTransparency or 1,
		[Children] = {
            -- hp
			Fillbar(scope, {
                Name = "healthBar",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.5, 0.1),
				FillColor3 = props.FillColor3,
				Thickness = 3,
                MaxValue = maxHealth,
                CurrentValue = currentHealth,
				[Children] = {
					scope:New "UIStroke" {
						Thickness = 2,
						Color = Color3.new(0.121568, 0.192156, 0.121568),
					},
					BaseText(scope, {
						Size = UDim2.fromScale(0.8, 0.8),
						TextXAlignment = Enum.TextXAlignment.Center,
						Text = currentHealth
					})
				}
			}),
            -- level
            scope:New "Frame" {
                Name = "level",
                AnchorPoint = Vector2.new(1, 0.5),
				Size = UDim2.fromScale(0.15, 0.15),
				Position = UDim2.fromScale(0.28, 0.5),
				ZIndex = 10,
                [Children] = {
                    BaseText(scope,{
                        Size = UDim2.fromScale(0.7, 0.7),
                        Text = level,
                        ZIndex = 10,
                    }),
                    scope:New "UICorner" {
                        CornerRadius = UDim.new(1, 0),
                    },
                    scope:New "UIStroke" {
                        Thickness = 2,
                    },
                    scope:New "UIAspectRatioConstraint" {
                        AspectRatio = 1,
                    },
                    scope:New "UIGradient" {
						Color = Blue,
						Rotation = 90,
					}
                }
            },
            -- name
            BaseText(scope, {
				Name = "userName",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.35),
				Size = UDim2.fromScale(0.8, 0.12),
				Text = name,
			}),
            -- vip
            BaseText(scope, {
				Name = "vip",
                Visible = vip,
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0.18),
				Size = UDim2.fromScale(0.5, 0.1),
				Text = "[ VIP ]",
				[Children] = {
					scope:New "UIGradient" {
						Color = RainbowSequence,
                        Rotation = movingRotation,
					}
				}
			}),
            -- protect
            scope:New "Frame" {
                Name = "protected",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromScale(0.55, 0.14),
                BackgroundTransparency = 0.2,
                ZIndex = 5,
                Visible = protected,
                BackgroundColor3 = Color3.new(0.980392, 1, 0.752941),
                [Children] = {
                    scope:New "UIStroke" {
                        Thickness = 2,
                        Color = Color3.new(1, 1, 1),
                    },
                    scope:New "UICorner" {
                        CornerRadius = UDim.new(1, 0),
                    },
                    scope:New "UIGradient" {
                        Rotation = movingRotation,
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0.2),
                            NumberSequenceKeypoint.new(0.2, 1),
        
                            NumberSequenceKeypoint.new(0.8, 1),
                            NumberSequenceKeypoint.new(1, 0.2),
                        })
                    }
                }
            },
            -- shield
            scope:New "Frame" {
                Name = "shield",
                Visible = scope:Computed(function(use)
                    return use(shield) > 0
                end),
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                [Children] = {
                    scope:New "ImageLabel" {
                        Rotation = scope:Computed(function(use)
                            return (use(movingRotation)-90) / 4
                        end),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.fromScale(0.7, 0.5),
                        Size = UDim2.fromScale(0.8, 0.2),
                        BackgroundTransparency = 1,
                        ZIndex = 5,
                        ImageColor3 = Color3.new(0.874509, 0.874509, 0.874509),
                        Image = "rbxassetid://5647507800",
                        Visible = props.Visible,
                        [Fusion.Children] = {
                            scope:New "UIAspectRatioConstraint" {
                                AspectRatio = 1,
                            },
                            BaseText(scope, {
                                Size = UDim2.fromScale(0.5, 0.5),
                                Text = shield,
                                ZIndex = 5,
                            })
                        }
                    },
                    scope:New "Frame" {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.fromScale(0.5, 0.5),
                        Size = UDim2.fromScale(0.5, 0.1),
                        BackgroundTransparency = 0.3,
                        [Fusion.Children] = {
                            scope:New "UIGradient" {
                                Color = Metalic,
                                Rotation = 90,
                            },
                            scope:New "UICorner" {
                                CornerRadius = UDim.new(0, 8)
                            },
                            scope:New "UIStroke" {
                                Thickness = 4,
                                Color = Color3.new(0.141176, 0.156862, 0.2),
                            },
                        }
                    },
                }
            }
		},
        -- [] = {
        --     heartBeat
        -- }
    }

end

return Overhead