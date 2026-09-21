-- Soft preferences, never attack slots. Collision validation remains in the host.
local Positioning={}
local function flat(v) return Vector3.new(v.X,0,v.Z) end
local function limited(v,maximum)
    return if v.Magnitude>maximum then v.Unit*maximum else v
end
local function radius(record)
    local size=record.Definition.Size
    return record.Definition.CombatRadius or math.sqrt(size.X*size.Z)*.5
end
function Positioning.new()
    return {Cells={},Previous={},NextRefresh=0,CellSize=12,MaxRadius=0}
end
function Positioning.Refresh(index,records,now)
    if now<index.NextRefresh then return end
    index.NextRefresh=now+.1
    index.Cells={};index.MaxRadius=0
    local previous={}
    for record,serial in records do
        local p=record.Frame.Position
        local x,z=math.floor(p.X/index.CellSize),math.floor(p.Z/index.CellSize)
        local key=x..":"..z
        index.Cells[key]=index.Cells[key] or {}
        local r=radius(record)
        index.MaxRadius=math.max(index.MaxRadius,r)
        local last=index.Previous[record]
        local velocity=if last and now>last.Time then flat(p-last.Position)/(now-last.Time) else Vector3.zero
        velocity=limited(velocity,record.Definition.Behaviour.ChaseSpeed)
        previous[record]={Position=p,Time=now}
        table.insert(index.Cells[key],{Record=record,Position=p,Radius=r,Serial=serial,Velocity=velocity})
    end
    index.Previous=previous
end
function Positioning.Delta(index,record,target,targetPosition,dt,serial,intent)
    local config=record.Definition.Behaviour
    local position=record.Frame.Position
    local offset=flat(position-targetPosition)
    local distance=offset.Magnitude
    local preferred=math.min(config.Attack.Range,config.Attack.TriggerRange or config.Attack.Range)*.9
    local memory=record.CombatPosition
    if not memory or memory.Target~=target then
        memory={Target=target,Velocity=Vector3.zero,ClearTime=0}
        record.CombatPosition=memory
    end
    local ownRadius=radius(record)
    local speed=config.ChaseSpeed
    local lookAhead=math.min(speed*.35,2.5)
    local reach=ownRadius+index.MaxRadius+.35+lookAhead
    local cell=index.CellSize
    local neighbors={}
    for x=math.floor((position.X-reach)/cell),math.floor((position.X+reach)/cell) do
        for z=math.floor((position.Z-reach)/cell),math.floor((position.Z+reach)/cell) do
            for _,other in index.Cells[x..":"..z] or {} do
                if other.Record~=record and other.Record.Alive~=false
                    and math.abs(other.Position.Y-position.Y)<(record.Definition.Size.Y+other.Record.Definition.Size.Y)*.5 then
                    local away=flat(position-other.Position)
                    local desired=ownRadius+other.Radius+.35
                    if away.Magnitude<desired+lookAhead then table.insert(neighbors,{Other=other,Away=away,Distance=away.Magnitude,Desired=desired}) end
                end
            end
        end
    end
    table.sort(neighbors,function(a,b)
        if a.Distance==b.Distance then return a.Other.Serial<b.Other.Serial end
        return a.Distance<b.Distance
    end)
    -- The nearest point of the combat band is enough; there is no angle to recover.
    -- Keep pursuit speed until arrival. A distance-proportional slowdown outside
    -- trigger range creates a permanent following gap behind a retreating target.
    local seek=if distance>preferred+.2 then -offset.Unit*math.min((distance-preferred)/math.max(dt,.001),speed) else Vector3.zero
    if intent then seek=limited(intent/math.max(dt,.001),speed) end
    local forward=if seek.Magnitude>.001 then seek.Unit else Vector3.zero
    local right=Vector3.new(-forward.Z,0,forward.X)
    local blocker,urgency=nil,0
    for i=1,math.min(12,#neighbors) do
        local neighbor=neighbors[i]
        local away=neighbor.Away
        if neighbor.Distance<.001 then
            local angle=math.min(serial,neighbor.Other.Serial)*2.399963
            away=Vector3.new(math.cos(angle),0,math.sin(angle))*(if serial<neighbor.Other.Serial then 1 else -1)
        else away=away.Unit end
        neighbor.Normal=away
        local ahead=-neighbor.Away:Dot(forward)
        local lateral=math.abs(neighbor.Away:Dot(right))
        local closing=(seek-neighbor.Other.Velocity):Dot(forward)
        -- Predict body congestion only along the intended approach, not behind us.
        if seek.Magnitude>.001 and closing>.1 and ahead>0 and lateral<neighbor.Desired
            and ahead<neighbor.Desired+lookAhead then
            local weight=(1-lateral/neighbor.Desired)*math.clamp(1-(ahead-neighbor.Desired)/math.max(lookAhead,.001),0,1)
                *math.clamp(closing/math.max(speed,.001),0,1)
            if weight>urgency then blocker,urgency=neighbor,weight end
        end
    end
    if blocker then
        memory.ClearTime=0
        if not memory.Side then
            local side=blocker.Normal:Dot(right)
            memory.Side=if math.abs(side)>.1 then (if side>0 then 1 else -1) else (if serial%2==0 then 1 else -1)
        end
    else
        memory.ClearTime+=dt
        if memory.ClearTime>.35 then memory.Side=nil end
    end
    local velocity=limited(seek+right*(memory.Side or 0)*urgency*speed*.85,speed)
    velocity=memory.Velocity:Lerp(velocity,1-math.exp(-12*dt))
    -- Resolve only the component that worsens each overlap. Tangential motion and
    -- escape remain available; never attenuate the whole approach due to crowding.
    for _=1,2 do
        for i=1,math.min(12,#neighbors) do
            local neighbor=neighbors[i]
            local penetration=math.max(0,1-neighbor.Distance/neighbor.Desired)
            if penetration>0 then
                local normal=neighbor.Normal
                local relative=velocity-neighbor.Other.Velocity
                local outward=relative:Dot(normal)
                local tangentSpeed=(relative-normal*outward).Magnitude
                local correcting=math.clamp(tangentSpeed/math.max(speed,.001),0,1)
                local repair=speed*math.min(.65,penetration*2)*(1-correcting*.75)
                -- A creature already escaping fast enough receives no opposing force.
                if outward<repair then velocity+=normal*(repair-outward) end
            end
        end
    end
    memory.Velocity=limited(velocity,speed)
    return memory.Velocity*dt
end
return Positioning
