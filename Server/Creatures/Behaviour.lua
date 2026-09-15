-- Game-independent state machine. Targets, navigation, clocks and damage are injected.
local Behaviour={}
local function flat(v) return Vector3.new(v.X,0,v.Z) end
local function state(brain,name,now)
    if brain.State~=name then brain.State,brain.Since=name,now end
end
local function face(position,target,fallback)
    local direction=flat(target-position)
    return if direction.Magnitude>.001 then CFrame.lookAt(position,position+direction) else fallback
end
function Behaviour.Step(record,dt,now,ops)
    local config=record.Definition.Behaviour
    local brain=record.Brain
    if not brain then
        brain={State="Patrol",Since=now,NextSense=now,NextAttack=now,Sequence=0,LastProgress=now,LastPosition=record.Frame.Position}
        record.Brain=brain
    end
    local function cancel()
        if brain.Action then ops.Action(record,nil);brain.Action=nil end
        brain.Target=nil
        brain.NextAttack=now+config.Attack.Cooldown
        brain.LostAt=nil
        state(brain,"Return",now)
    end
    if ops.Disabled(record) then
        if brain.Action then ops.Action(record,nil);brain.Action=nil end
        brain.Target=nil
        state(brain,"Idle",now)
        return nil,brain.State
    end
    local position=record.Frame.Position
    local targetPosition=brain.Target and ops.Position(record,brain.Target)
    if brain.Target and (not targetPosition or flat(targetPosition-record.Home).Magnitude>config.Leash
        or flat(position-record.Home).Magnitude>config.Leash or math.abs(targetPosition.Y-position.Y)>config.MaxHeight) then
        cancel();targetPosition=nil
    end
    if brain.Action then
        local action=brain.Action
        local age=now-action.Start
        if not action.Resolved and age>=config.Attack.Windup then
            action.Resolved=true -- consume before callbacks; a late tick must never replay a strike
            if age<=config.Attack.Windup+config.Attack.Active and targetPosition then
                ops.Hit(record,brain.Target,action)
            end
        end
        if age>=config.Attack.Windup+config.Attack.Active+config.Attack.Recovery then
            brain.Action=nil;ops.Action(record,nil)
            brain.NextAttack=now+config.Attack.Cooldown
            brain.LastProgress=now
            state(brain,"Chase",now)
        else
            state(brain,if age<config.Attack.Windup then "Windup" else "Recovery",now)
            return nil,brain.State
        end
    end
    if brain.State=="Return" then
        local offset=flat(record.Home-position)
        if offset.Magnitude<.25 then
            state(brain,"Patrol",now);brain.NextSense=now+config.ReacquireDelay
        else
            return ops.Move(record,offset.Unit*math.min(offset.Magnitude,config.ChaseSpeed*dt)),brain.State
        end
    end
    if now>=brain.NextSense then
        brain.NextSense=now+config.SenseInterval
        if not brain.Target then brain.Target=ops.Find(record,config.DetectRange) end
        targetPosition=brain.Target and ops.Position(record,brain.Target)
    end
    if targetPosition then
        if not ops.Visible(record,brain.Target) then
            brain.LostAt=brain.LostAt or now
            if now-brain.LostAt>config.LoseSightAfter then cancel();return nil,brain.State end
        else brain.LostAt=nil end
        local offset=flat(targetPosition-position)
        if offset.Magnitude<=config.Attack.Range and ops.Visible(record,brain.Target) then
            brain.LastProgress=now
            state(brain,"Idle",now)
            if now>=brain.NextAttack then
                brain.Sequence+=1
                local frame=face(position,targetPosition,record.Frame)
                brain.Action={Sequence=brain.Sequence,Start=now,Frame=frame,Resolved=false}
                state(brain,"Windup",now)
                ops.Action(record,brain.Action)
                return frame,brain.State
            end
            return face(position,targetPosition,record.Frame),brain.State
        end
        state(brain,"Chase",now)
        if offset.Magnitude<.001 then return nil,brain.State end
        if flat(position-brain.LastPosition).Magnitude>.2 then brain.LastPosition,brain.LastProgress=position,now end
        if now-brain.LastProgress>config.StuckTimeout then cancel();brain.LastProgress=now;return nil,brain.State end
        local frame=ops.Move(record,offset.Unit*math.min(math.max(0,offset.Magnitude-config.Attack.Range*.9),config.ChaseSpeed*dt))
        return frame,brain.State
    end
    brain.LastProgress=now
    state(brain,"Patrol",now)
    return ops.Patrol(record,dt,now),brain.State
end
return Behaviour
