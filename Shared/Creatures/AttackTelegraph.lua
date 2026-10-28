-- Local outline of the authoritative attack sector. No collision or gameplay queries.
local Telegraph={}
Telegraph.__index=Telegraph
function Telegraph.new(parent,range,halfAngle,shape,width)
    local model=Instance.new("Model")
    model.Name,model.Parent="AttackTelegraph",parent
    local self=setmetatable({Model=model,Parts={},Range=range,Angle=math.rad(halfAngle),Circle=shape=="Circle",
        Charge=shape=="Charge" or shape=="Projectile",Ranged=shape=="Projectile",Width=width},Telegraph)
    for index=1,if self.Charge then 4 elseif self.Circle then 32 else 14 do
        local part=Instance.new("Part")
        part.Name="Edge"
        part.Anchored,part.CanCollide,part.CanTouch,part.CanQuery=true,false,false,false
        part.Material,part.CastShadow,part.Transparency=if self.Ranged then Enum.Material.Plastic else Enum.Material.Neon,false,1
        part.Parent=model
        self.Parts[index]=part
    end
    return self
end
function Telegraph:Show(frame,progress,strike,opacity,emphasis)
    local function point(angle) return frame:PointToWorldSpace(Vector3.new(math.sin(angle)*self.Range,0,-math.cos(angle)*self.Range)) end
    for index,part in self.Parts do
        local a,b
        if self.Charge then
            local corners={Vector3.new(-self.Width/2,0,0),Vector3.new(self.Width/2,0,0),
                Vector3.new(self.Width/2,0,-self.Range),Vector3.new(-self.Width/2,0,-self.Range)}
            a,b=frame:PointToWorldSpace(corners[index]),frame:PointToWorldSpace(corners[index%4+1])
        elseif self.Circle then a,b=point((index-1)*math.pi/16),point(index*math.pi/16)
        elseif index<=12 then a,b=point(-self.Angle+(index-1)*self.Angle/6),point(-self.Angle+index*self.Angle/6)
        elseif index==13 then a,b=frame.Position,point(-self.Angle)
        else a,b=frame.Position,point(self.Angle) end
        part.Size=Vector3.new(if self.Ranged then .065 else .10+progress*.10,
            if self.Ranged then .025 else .045,math.max(.01,(b-a).Magnitude))
        part.CFrame=CFrame.lookAt((a+b)/2,b)
        if self.Ranged then
            part.Color=Color3.fromRGB(215,167,98):Lerp(Color3.fromRGB(240,198,130),emphasis or 0)
            part.Transparency=1-math.clamp(opacity or 0,0,1)
        else
            part.Color=if strike then Color3.fromRGB(255,80,35) else Color3.fromRGB(255,175,45)
            part.Transparency=if strike then .05 else .5-progress*.4
        end
    end
end
function Telegraph:Hide()
    for _,part in self.Parts do part.Transparency=1 end
end
function Telegraph:Destroy() self.Model:Destroy() end
return Telegraph
