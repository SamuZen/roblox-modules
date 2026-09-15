-- Samples baked Grove poses locally. No asset registration, Humanoid, or replicated animation tracks.
local Tween=game:GetService("TweenService")
local ClipRig={}
ClipRig.__index=ClipRig
function ClipRig.new(root,data,origin)
    local model=Instance.new("Model")
    model.Name,model.Parent="Visual",root
    local self=setmetatable({Model=model,Data=data,Parts={},Motors={},Clip=nil,Blend=1,Previous={}},ClipRig)
    for _,entry in data.Parts do
        local part=Instance.new(entry.Class)
        part.Name,part.Size=entry.Name,entry.Size
        part.Material,part.MaterialVariant,part.Color=Enum.Material.Plastic,entry.Variant,entry.Color
        part.Transparency=entry.Transparency
        part.Anchored,part.Massless,part.CanCollide,part.CanTouch,part.CanQuery=false,true,false,false,false
        part.CFrame=root.CFrame*origin*entry.Frame
        part.Parent=model
        self.Parts[entry.Name]=part
    end
    model.PrimaryPart=assert(self.Parts.RigRoot)
    local anchor=Instance.new("WeldConstraint")
    anchor.Part0,anchor.Part1,anchor.Parent=root,model.PrimaryPart,model.PrimaryPart
    for _,entry in data.Motors do
        local motor=Instance.new("Motor6D")
        motor.Name,motor.Part0,motor.Part1=entry.Name,self.Parts[entry.Part0],self.Parts[entry.Part1]
        motor.C0,motor.C1,motor.Parent=entry.C0,entry.C1,motor.Part0
        self.Motors[entry.Part1]=motor
    end
    for _,entry in data.Welds do
        local weld=Instance.new("WeldConstraint")
        weld.Part0,weld.Part1,weld.Parent=self.Parts[entry[1]],self.Parts[entry[2]],self.Parts[entry[2]]
    end
    return self
end
function ClipRig:Sample(name,time,dt,key)
    local clip=assert(self.Data.Clips[name],"Unknown creature clip")
    key=key or name
    if self.Clip~=key then
        self.Clip,self.Blend=key,0
        for part,motor in self.Motors do self.Previous[part]=motor.Transform end
    end
    self.Blend=math.min(1,self.Blend+(dt or 0)/.1)
    time=if clip.Loop then time%clip.Duration else math.clamp(time,0,clip.Duration)
    local a,b=clip.Frames[1],clip.Frames[#clip.Frames]
    for index=2,#clip.Frames do
        if clip.Frames[index].Time>=time then a,b=clip.Frames[index-1],clip.Frames[index];break end
    end
    local alpha=if b.Time>a.Time then math.clamp((time-a.Time)/(b.Time-a.Time),0,1) else 1
    for part,motor in self.Motors do
        local from,to=a.Poses[part],b.Poses[part]
        local eased=Tween:GetValue(alpha,Enum.EasingStyle[from.Style],Enum.EasingDirection[from.Direction])
        local pose=from.Frame:Lerp(to.Frame,eased)
        motor.Transform=(self.Previous[part] or CFrame.identity):Lerp(pose,self.Blend)
    end
end
function ClipRig:Destroy() self.Model:Destroy() end
return ClipRig
