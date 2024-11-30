-- ### Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ### Fusion
local Fusion = require(ReplicatedStorage.Source.Fusion)

type UsedAs<T> = Fusion.UsedAs<T>

local function FillBar(
    scope: Fusion.Scope<typeof(Fusion)>,
    props: {
        
    }
)
    return scope:New "TextLabel" {
		Name = props.Name or "TextLabel",
		Position = props.Position or UDim2.fromScale(0.5, 0.5),
		AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5),
		Size = props.Size or UDim2.fromScale(0.9, 0.9),
		TextScaled = props.TextScaled == nil or props.TextScaled == true,
		TextSize = props.TextSize or 14,
		TextColor3 = props.TextColor3 or Color3.new(1, 1, 1),
		BackgroundTransparency = props.BackgroundTransparency or 1,
		Font = Enum.Font.FredokaOne,
		TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Center,
		LayoutOrder = props.LayoutOrder or 1,
		Text = props.Text or "??",
		AutomaticSize = props.AutomaticSize or Enum.AutomaticSize.None,
		ZIndex = props.ZIndex or 1,
		Visible = props.Visible,
		[Fusion.Children] = {
			scope:New "UIStroke" {
				Thickness = 2,
				Color = Color3.new(0,0,0)
			},
			props[Fusion.Children]
		}
	}
    
end

return FillBar