--[[
	playSoundFromSource - A utility function to clone and play a sound from a specified source,
	destroying it once it has finished playing.
--]]

local Player = game:GetService("Players")
local RunService = game:GetService("RunService")

local event : RemoteEvent
if RunService:IsServer() then
	event = Instance.new("RemoteEvent")
	event.Parent = script
else
	event = script:WaitForChild("RemoteEvent")
end

local function playSoundFromSource(soundTemplate: Sound, source: Instance, pitchAdjustment: number?, toClient)
	if toClient ~= nil and RunService:IsServer() then
		event:FireClient(toClient, soundTemplate)
		return
	end
	local sound = soundTemplate:Clone()
	if pitchAdjustment then
		sound.PlaybackSpeed *= pitchAdjustment
	end

	if source == nil then
		source = Player.LocalPlayer:WaitForChild("PlayerGui")
	end
	sound.Parent = source

	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)

	return sound
end

if RunService:IsClient() then
	event.OnClientEvent:Connect(function(soundTemplate)
		playSoundFromSource(soundTemplate)
	end)
end

return playSoundFromSource
