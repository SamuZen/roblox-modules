-- ### Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ### Fusion
local Fusion = require(ReplicatedStorage.Source.Fusion)

type UsedAs<T> = Fusion.UsedAs<T>

local function FillBar(
    scope: Fusion.Scope<typeof(Fusion)>,
    props: {
        CurrentValue: UsedAs<number>?,
        MaxValue: UsedAs<number>?,
        BackgroundColor3: UsedAs<Color3>?,
        Position: UsedAs<UDim2>?,
        AnchorPoint: UsedAs<UDim2>?,
        Size: UsedAs<UDim2>?,
        FillColor3: UsedAs<Color3>?,
        CornerRadius: UsedAs<UDim>?,
        FillChildren: any?,
    }
)

    local value = props.CurrentValue or scope:Value(60)
    local maxValue = props.MaxValue or scope:Value(80)
    local fillSize = scope:Computed(function(use, scope)
        return UDim2.fromScale(math.clamp(use(value) / use(maxValue), 0, 1), 1)
    end)
    return scope:New "Frame" {
        BackgroundColor3 = props.BackgroundColor3 or Color3.new(0.090196, 0.105882, 0.152941),
        Position = props.Position or UDim2.fromScale(0, 0),
        AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
        Size = props.Size or UDim2.fromScale(1, 1),
        [Fusion.Children] = {
            scope:New "Frame" {
                Name = "fill",
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.fromScale(0, 0.5),
                Size = fillSize,
                BackgroundColor3 = props.FillColor3 or Color3.new(0.109803, 1, 0.066666),
                [Fusion.Children] = {
                    scope:New "UICorner" {
                        CornerRadius = props.CornerRadius or UDim.new(0, 8),
                    },
                    props.FillChildren,
                },
            },
            scope:New "UICorner" {
                CornerRadius = props.CornerRadius or UDim.new(0, 8)
            },
            props[Fusion.Children]
        }
    }
end

return FillBar