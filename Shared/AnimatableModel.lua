local ReplicatedStorage = game:GetService("ReplicatedStorage")
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local AnimatableModel = {}
AnimatableModel.__index = AnimatableModel

local Trove = require(ReplicatedStorage.Source.Packages.trove)
local CharacterUtils = require(ReplicatedStorage.Source.Modules.Character)
local Signal = require(ReplicatedStorage.Source.Packages.signal)

-- ### Internal
local existingModels = {}

function AnimatableModel.new(model: Model, stopReplication: boolean)
    stopReplication = stopReplication or false
    --print("New Animatable Model: ", model:GetFullName())
    if existingModels[model] ~= nil then
        warn("returning cached animatableModel")
        return existingModels[model]
    end

    local trove = Trove.new()
    
    if CharacterUtils.isPlayerCharacter(model) then
        trove:Add(model.AncestryChanged:Connect(function()
            if model.Parent == nil then
                trove:Destroy()
            end
        end))
    else
        trove:AttachToInstance(model)
    end

    --animation controller
    local animationController = model:FindFirstChild("AnimationController")
	if animationController == nil then
		animationController = model:FindFirstChild("Humanoid")
	end   
   	if animationController == nil then
        animationController = Instance.new("AnimationController")
        animationController.Parent = model
    end

    --animator
    local animator = animationController:FindFirstChild("Animator") :: Animator
    if animator == nil then
        animator = Instance.new("Animator")
        animator.Parent = animationController
    end

    if stopReplication then
        animator.AnimationPlayed:Connect(function(animationTrack)
            if animationTrack.Name == "Animation" then
                animationTrack:Stop()
            end
        end)
    end

    local self = setmetatable({
        trove = trove,
        animator = animator,
        tracks = {},
        playingTracks = {},
        model = model,
        loadedAnimations = {},
    }, AnimatableModel)

    self.signalAnimationLoaded = Signal.new()

    -- cache
    existingModels[model] = self
    self.trove:Add(function()
        existingModels[self.model] = nil
    end)

    return self
end

local function createAnimation(name: string, id: string)
    local animation = Instance.new("Animation")
    animation.AnimationId = id
    animation.Name = name
    return animation
end

function AnimatableModel:OnAnimationLoaded(callback: (AnimationTrack) -> nil): RBXScriptConnection
    local connection = self.signalAnimationLoaded:Connect(callback)
    self.trove:Add(connection)
    return connection
end

function AnimatableModel:_LoadAnimation(name, animation, cleanAnimation)
    if cleanAnimation == nil then
        cleanAnimation = true
    end
    local animationTrack : AnimationTrack = self.animator:LoadAnimation(animation)
    self.tracks[name] = animationTrack
    if cleanAnimation then
        self.trove:Add(animation)
    end
    self.signalAnimationLoaded:Fire(animationTrack)
end

-- ### Animation Sequence ( local animations )

function AnimatableModel:Load(filesToLoad: {[string]: KeyframeSequence | Animation | string})
    if filesToLoad == nil then return end

    for name, file in filesToLoad do

        if typeof(file) == 'string' and string.find(file, "rbxassetid://") then
            self:LoadAnimationId(name, file)
        elseif file:IsA("KeyframeSequence") then
            self:LoadKeyframeSequence(name, file)
        elseif file:IsA("Animation") then
           self:LoadAnimation(name, file, false)
        else
            error("Cannot load this type of file! ", filesToLoad)
        end

    end
end

function AnimatableModel:LoadKeyframeSequence(name, keyframeSequence)
    local hashId = KeyframeSequenceProvider:RegisterKeyframeSequence(keyframeSequence)
    self:LoadAnimationId(name, hashId)
end

function AnimatableModel:LoadAnimation(name, animation, ...)
    if typeof(name) == "number" then
        name = animation.AnimationId
    end
    if self.loadedAnimations[animation] ~= nil and self.tracks[name] ~= nil then
        return
    end
    self.loadedAnimations[animation] = true
    self:_LoadAnimation(name, animation, ...)
end

function AnimatableModel:LoadAnimationId(name, id)
    if typeof(name) == "number" then
        name = id
    end
    if self.loadedAnimations[id] ~= nil and self.tracks[name] ~= nil then
        return
    end
    self.loadedAnimations[id] = true

    local animation = createAnimation(name, id)
    animation.Parent = self.animator

    self:_LoadAnimation(name, animation)
end

-- ###

function AnimatableModel:StopAllAnimations(fadeTime)
    for index = #self.playingTracks, 1, -1 do
        local animation = self.playingTracks[index]
        self.tracks[animation]:Stop(fadeTime or 0.1)
        table.remove(self.playingTracks, index)
    end
end

function AnimatableModel:StopAllAnimationsExept(list)
    for index = #self.playingTracks, 1, -1 do
        local animation = self.playingTracks[index]
        if not list[animation] then
            self.tracks[animation]:Stop()
            table.remove(self.playingTracks, index)
        end
    end
end

function AnimatableModel:StopAnimations(list)
    for index = #self.playingTracks, 1, -1 do
        local animation = self.playingTracks[index]
        if list[animation] then
            self.tracks[animation]:Stop()
            table.remove(self.playingTracks, index)
        end
    end
end

function AnimatableModel:PlayAnimation(animationId: string, fadeTime: number, weight: number, speed: number)
    local animationTrack = self.tracks[animationId]
    if animationTrack == nil then
        warn(self.model:GetFullName())
        return warn("Cannot play animation that is not loaded! ", animationId)
    end

    self.tracks[animationId]:Play(fadeTime, weight, speed)
    table.insert(self.playingTracks, animationId)
end

function AnimatableModel:ClearPlayingList()
	for _, anim in self.playingTracks do
		if not self.tracks[anim].IsPlaying then
			local i = table.find(self.playingTracks, anim)
			if i ~= nil then
				table.remove(self.playingTracks, i)
			end
		end 
	end
end

function AnimatableModel:IsPlaying()
	self:ClearPlayingList()
	return #self.playingTracks > 0
end

function AnimatableModel:Freeze(duration: number, freezeSpeed: number)
    --('playingTracks:', self.playingTracks)
    
    task.spawn(function()
        for _, anim in self.playingTracks do
            local speed = self.tracks[anim].Speed
            self.tracks[anim]:AdjustSpeed(freezeSpeed or 0)
            
            if duration ~= nil and duration ~= 0 then
                task.delay(duration, function()
                    self.tracks[anim]:AdjustSpeed(speed)
                end)
            end
        end
    end)
end

function AnimatableModel:ConnectAnimationEvent(animationId: string, eventName: string, callback: (param: string, animName: string) -> nil): RBXScriptConnection
    local animationTrack = self.tracks[animationId]
    if animationTrack == nil then return warn("Cannot connect event for animation that is not loaded: ", animationId) end

    local connection = animationTrack:GetMarkerReachedSignal(eventName):Connect(function(param)
        callback(param, animationTrack.Name)
    end)
    self.trove:Add(connection)
    return connection
end

function AnimatableModel:ConnectAllAnimationsEvent(eventName: string, callback: (param: string, animName: string) -> nil): typeof(Trove)
    local trove = Trove.new()
    for name, _ in self.tracks do
        trove:Add(self:ConnectAnimationEvent(name, eventName, callback))
    end
    trove:Add(self:OnAnimationLoaded(function(animTrack)
        trove:Add(self:ConnectAnimationEvent(animTrack.Name, eventName, callback))
    end))
    return trove
end

function AnimatableModel:Destroy()
    if self.trove ~= nil then
        self.trove:Destroy()
    end
end

return AnimatableModel