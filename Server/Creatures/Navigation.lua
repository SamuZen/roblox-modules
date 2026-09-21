-- Recovery steering for terrestrial encounter creatures. Geometry/path APIs are injected.
local Navigation={}
Navigation.__index=Navigation
local DEFAULTS={ProbeInterval=.15,DirectInterval=.4,ClearConfirm=.3,LookAhead=.4,
    StuckTime=1.2,LoopTime=3,RetryTime=1.5,MaxRetry=8,TargetShift=8,
    WaypointRadius=.6,MaxConcurrent=2,StartInterval=.25,MaxQueue=64,RequestLifetime=8}
local function flat(v) return Vector3.new(v.X,0,v.Z) end
local function seek(position,destination,speed,dt,stop)
    local offset=flat(destination-position)
    return if offset.Magnitude>.001 then offset.Unit*math.min(speed*dt,math.max(0,offset.Magnitude-(stop or 0))) else Vector3.zero
end
local function clearRoute(memory)
    memory.Path=nil;memory.Index=nil;memory.Pending=nil
end
function Navigation.new(options)
    local config=table.clone(DEFAULTS)
    for key,value in options.Config or {} do config[key]=value end
    return setmetatable({Options=options,Config=config,Queue={},Running=0,NextStart=0,Closed=false,
        Stats={Requests=0,Failures=0,Discarded=0,Completed=0,QueueWait=0}},Navigation)
end
function Navigation:Valid(record,memory)
    return not self.Closed and record.Alive and record.Navigation==memory and record.Encounter
        and not record.Encounter.Closed and record.Brain and record.Brain.Target==memory.Target
        and not record.Brain.Action and (record.Part:GetAttribute("MagicRootUntil") or 0)<=self.Options.Clock()
        and self.Options.Position(record,memory.Target)~=nil
end
function Navigation:Forget(record)
    record.Navigation=nil
end
function Navigation:Request(record,memory,position,now)
    local config=self.Config
    if memory.Pending or now<memory.RetryAt or #self.Queue>=config.MaxQueue then return end
    local request={Record=record,Memory=memory,Target=position,QueuedAt=now,Encounter=record.Encounter}
    memory.Pending=request
    memory.RetryAt=now+config.RetryTime
    table.insert(self.Queue,request)
    self.Stats.Requests+=1
end
function Navigation:Step(now)
    if self.Closed then return end
    if self.Options.BeginFrame then self.Options.BeginFrame() end
    -- Prune canceled/expired requests even while the workers are occupied.
    for i=#self.Queue,1,-1 do
        local request=self.Queue[i]
        if not self:Valid(request.Record,request.Memory) or request.Memory.Pending~=request
            or now-request.QueuedAt>self.Config.RequestLifetime then
            if request.Memory.Pending==request then request.Memory.Pending=nil end
            table.remove(self.Queue,i)
            self.Stats.Discarded+=1
        end
    end
    if self.Running>=self.Config.MaxConcurrent or now<self.NextStart or #self.Queue==0 then return end
    local request=table.remove(self.Queue,1)
    self.Running+=1;self.NextStart=now+self.Config.StartInterval
    self.Stats.QueueWait+=now-request.QueuedAt
    task.spawn(function()
        local record,memory=request.Record,request.Memory
        local ok,points=pcall(self.Options.ComputePath,record,request.Target)
        self.Running-=1
        local finished=self.Options.Clock()
        local targetPosition=if self:Valid(record,memory) then self.Options.Position(record,memory.Target) else nil
        if not targetPosition or memory.Pending~=request or record.Encounter~=request.Encounter
            or finished-request.QueuedAt>self.Config.RequestLifetime
            or flat(targetPosition-request.Target).Magnitude>self.Config.TargetShift then
            if memory.Pending==request then memory.Pending=nil end
            self.Stats.Discarded+=1
            return
        end
        memory.Pending=nil
        if ok and points and #points>1 then
            -- Include the start point: movement can continue while ComputeAsync yields.
            memory.Path=points;memory.Index=1;memory.PathTarget=request.Target
            memory.Mode="Path";memory.BlockedTime=0;memory.LoopElapsed=0;memory.BestDistance=nil
            memory.NextProbe=0;memory.Direction=nil
            memory.Failures=0;memory.RetryAt=finished+self.Config.RetryTime
            self.Stats.Completed+=1
        else
            memory.Failures+=1
            memory.RetryAt=finished+math.min(self.Config.MaxRetry,self.Config.RetryTime*2^math.min(memory.Failures,4))
            self.Stats.Failures+=1
        end
    end)
end
function Navigation:Delta(record,target,targetPosition,dt,now,serial)
    local config=self.Config
    local position=record.Frame.Position
    local behaviour=record.Definition.Behaviour
    local speed=behaviour.ChaseSpeed
    local stop=math.min(behaviour.Attack.Range,behaviour.Attack.TriggerRange or behaviour.Attack.Range)*.9
    local memory=record.Navigation
    if not memory or memory.Target~=target then
        memory={Target=target,Mode="Direct",Side=if serial%2==0 then 1 else -1,
            NextProbe=0,NextDirect=now+(serial%7)*.03,RetryAt=0,BlockedTime=0,LoopElapsed=0,
            Failures=0,Anchor=position,PreviousPosition=position,LastTick=now}
        memory.History={};memory.Travel=0;memory.HistoryClock=0;memory.NextSample=0
        record.Navigation=memory
    end
    memory.LastTick=now
    local direct=seek(position,targetPosition,speed,dt,stop)
    -- Visibility remains Behaviour's attack policy; reaching a band behind a wall
    -- is not arrival. Probe toward the target when no attack is actually possible.
    if direct.Magnitude<.001 and not self.Options.Visible(record,target) then
        stop=0
        direct=seek(position,targetPosition,speed,dt,0)
    elseif direct.Magnitude<.001 then
        clearRoute(memory);memory.Mode="Direct";memory.BlockedTime=0;memory.LoopElapsed=0
        return Vector3.zero
    end
    if memory.Mode~="Direct" and now>=memory.NextDirect then
        memory.NextDirect=now+config.DirectInterval
        local clear=self.Options.Probe(record,direct.Unit*math.max(0,flat(targetPosition-position).Magnitude-stop),false)
        if clear and not memory.ForcedAvoid then
            memory.ClearSince=memory.ClearSince or now
            if now-memory.ClearSince>=config.ClearConfirm then
                clearRoute(memory);memory.Mode="Direct";memory.BlockedTime=0;memory.LoopElapsed=0
                memory.NextProbe=0;memory.ClearSince=nil
            end
        elseif clear==false then memory.ClearSince=nil end
    end
    local destination=targetPosition
    local intended=direct
    if memory.Path then
        while memory.Index<=#memory.Path and flat(memory.Path[memory.Index]-position).Magnitude<=config.WaypointRadius do
            memory.Index+=1;memory.BestDistance=nil;memory.LoopElapsed=0
        end
        if memory.Index>#memory.Path then
            memory.Path=nil;memory.Mode="Avoid";memory.NextProbe=0
        else
            destination=memory.Path[memory.Index]
            intended=seek(position,destination,speed,dt,0)
            local distance=flat(destination-position).Magnitude
            if not memory.BestDistance or distance<memory.BestDistance-.25 then
                memory.BestDistance=distance;memory.LoopElapsed=0
            end
            if flat(targetPosition-memory.PathTarget).Magnitude>config.TargetShift then
                self:Request(record,memory,targetPosition,now)
            end
        end
    end
    if intended.Magnitude<.001 then return Vector3.zero end
    -- A timeout uses active locomotion time, not wall time or target distance.
    local moved=flat(position-memory.PreviousPosition).Magnitude
    if memory.SceneBlocked and not memory.Crowded then
        if moved<math.min(.05,(memory.Requested or 0)*.25) then memory.BlockedTime+=dt
        else memory.BlockedTime=math.max(0,memory.BlockedTime-dt) end
        memory.LoopElapsed+=dt
        if not memory.Path and flat(position-memory.Anchor).Magnitude>math.max(3,speed*config.LoopTime*.6) then
            memory.Anchor=position;memory.LoopElapsed=0
        end
    else memory.BlockedTime=0;memory.LoopElapsed=0;memory.Anchor=position end
    memory.PreviousPosition=position
    memory.Travel+=moved;memory.HistoryClock+=dt
    if memory.Mode=="Avoid" and memory.HistoryClock>=memory.NextSample then
        memory.NextSample=memory.HistoryClock+.5
        for _,sample in memory.History do
            if memory.SceneBlocked and not memory.Crowded and memory.HistoryClock-sample.Time>=config.LoopTime
                and memory.Travel-sample.Travel>math.max(3,speed)
                and flat(position-sample.Position).Magnitude<1
                and flat(targetPosition-sample.Target).Magnitude<3 then
                memory.LoopElapsed=config.LoopTime;break
            end
        end
        table.insert(memory.History,{Time=memory.HistoryClock,Position=position,Target=targetPosition,Travel=memory.Travel})
        if #memory.History>24 then table.remove(memory.History,1) end
    elseif memory.Mode=="Direct" then table.clear(memory.History) end
    if memory.BlockedTime>=config.StuckTime or memory.LoopElapsed>=config.LoopTime then
        self:Request(record,memory,targetPosition,now)
        -- Do not continue pulling into a failed waypoint while its replacement is pending.
        if memory.Path and memory.BlockedTime>=config.StuckTime then
            memory.Path=nil;memory.Mode="Avoid";memory.NextProbe=0
        end
    end
    if now>=memory.NextProbe then
        memory.NextProbe=now+config.ProbeInterval
        local ahead=math.max(intended.Magnitude,math.min(speed*config.LookAhead,3))
        ahead=math.min(ahead,flat(destination-position).Magnitude)
        local forward=intended.Unit
        local clear=self.Options.Probe(record,forward*ahead,false)
        if clear and not memory.ForcedAvoid then
            memory.Direction=forward;memory.SceneBlocked=false
            if not memory.Path and memory.Mode=="Direct" then memory.ClearSince=nil end
        elseif clear==false or (clear~=nil and memory.ForcedAvoid) then
            memory.ForcedAvoid=nil
            memory.SceneBlocked=true
            if not memory.Path then memory.Mode="Avoid" end
            local chosen
            -- Keep a side through a corner. Try the opposite only when this side has no exit.
            for _,side in {memory.Side,-memory.Side} do
                for _,angle in {45,80,115,150} do
                    local direction=CFrame.Angles(0,math.rad(angle*side),0):VectorToWorldSpace(forward)
                    local passage=self.Options.Probe(record,direction*ahead,false)
                    if passage then chosen=direction;memory.Side=side;break end
                    if passage==nil then break end
                end
                if chosen then break end
            end
            memory.Direction=chosen or Vector3.zero
        end
    end
    local direction=memory.Direction or intended.Unit
    -- Follow moving targets immediately when direct; cached probes only anticipate walls.
    if not memory.SceneBlocked then direction=intended.Unit end
    local delta=direction*intended.Magnitude
    memory.Requested=intended.Magnitude
    return delta
end
function Navigation:Observe(record,reason)
    local memory=record.Navigation
    if not memory then return end
    memory.Crowded=reason=="Crowd"
    if reason=="Crowd" then memory.ForcedAvoid=true;memory.NextProbe=0 end
    if reason=="Wall" or reason=="Ground" or reason=="Bounds" then
        memory.SceneBlocked=true;memory.NextProbe=0
        if not memory.Path then memory.Mode="Avoid" end
    end
end
function Navigation:Destroy()
    self.Closed=true
    for _,request in self.Queue do
        if request.Memory.Pending==request then request.Memory.Pending=nil end
    end
    table.clear(self.Queue)
end
return Navigation
