--[[
	playSoundFromSource - A utility function to clone and play a sound from a specified source,
	destroying it once it has finished playing.
--]]

local Player = game:GetService("Players")

local function playSoundFromSource(soundTemplate: Sound, source: Instance, pitchAdjustment: number?)
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

return playSoundFromSource
