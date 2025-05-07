-- MIT License

-- Copyright (c) 2023 SamuZen
-- https://github.com/SamuZen

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

-- ### Roblox Services
local LightService = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

export type Attributes = {[string]: any}

export type Data = {
	Lighting: Attributes,
	Sky: Attributes,
	Atmosphere: Attributes,
	PostEffects: {
		Lightning: {[string]: Attributes},
		Camera: {[string]: Attributes},
	},
}

local function clear(camera: Camera)
	-- lighting
	for _, obj in LightService:GetChildren() do
		obj:Destroy()
	end

	-- camera
	for _, obj in camera:GetChildren() do
		obj:Destroy()
	end

	-- sky
	for _, sky in LightService:GetChildren() do
		if sky:IsA("Sky") then
			sky:Destroy()
		end
	end
end

local function applyAttributes(obj, att: Attributes)
	for key, value in att do
		obj[key] = value
	end
end

local Lighting = {}
function Lighting.apply(data: Data)
	local camera = Workspace.CurrentCamera
	clear(camera)

	-- lighting
	applyAttributes(LightService, data.Lighting)

	-- sky
	if data.Sky ~= nil then
		local sky = Instance.new("Sky")
		sky.Parent = LightService
		applyAttributes(sky, data.Sky)
	end

	-- atmosphere
	if data.Atmosphere ~= nil then
		local atmosphere = Instance.new("Atmosphere")
		atmosphere.Parent = LightService
		applyAttributes(atmosphere, data.Atmosphere)
	end

	if data.PostEffects then
		-- lighting effects
		if data.PostEffects.Lightning then
			for effectName, effectAttributes in data.PostEffects.Lightning do
				local effect = Instance.new(effectName)
				effect.Parent = LightService
				applyAttributes(effect, effectAttributes)
			end
		end

		-- camera effects
		if data.PostEffects.Camera then
			for effectName, effectAttributes in data.PostEffects.Camera do
				local effect = Instance.new(effectName)
				effect.Parent = camera
				applyAttributes(effect, effectAttributes)
			end
		end
	end

end

return Lighting