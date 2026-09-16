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
        brain.FarAt=nil
        record.Aggressor=nil
        state(brain,"Return",now)
        if ops.Reset then ops.Reset(record) end
    end
    if ops.Disabled(record) and brain.State~="Return" then
        if brain.Action then ops.Action(record,nil);brain.Action=nil end
        brain.Target=nil
        state(brain,"Idle",now)
        return nil,brain.State
    end
    local position=record.Frame.Position
    if record.Aggressor and brain.State~="Return" then
        -- Damage bypasses passive detection, but never resets a committed attack.
        if not brain.Target then brain.LastProgress,brain.LastPosition=now,position end
        if not brain.Action then brain.Target=record.Aggressor end
        brain.LostAt,brain.FarAt=nil,nil
        record.Aggressor=nil
    end
    local targetPosition=brain.Target and ops.Position(record,brain.Target)
    local committedCharge=brain.Action and config.Attack.Charge and now-brain.Action.Start>=config.Attack.Windup
    if brain.Target and (flat(position-record.Home).Magnitude>config.Leash or (not committedCharge
        and (not targetPosition
            or math.abs(targetPosition.Y-position.Y)>config.MaxHeight))) then
        cancel();targetPosition=nil
    end
    if brain.Target and targetPosition and not committedCharge then
        if flat(targetPosition-position).Magnitude>(config.ChaseRange or config.Leash) then
            brain.FarAt=brain.FarAt or now
            if now-brain.FarAt>=(config.LoseTargetAfter or 3) then cancel();targetPosition=nil end
        else brain.FarAt=nil end
    end
    if brain.Action then
        local action=brain.Action
        local age=now-action.Start
        local movedFrame
        local charge=config.Attack.Charge
        if charge and age>=config.Attack.Windup then
            if age<config.Attack.Windup+config.Attack.Active and not action.ChargeStopped then
                local elapsed=math.min(dt,age-config.Attack.Windup)
                if elapsed>0 then
                    local previous=action.Frame
                    movedFrame=ops.Move(record,previous.LookVector*charge.Speed*elapsed)
                    if movedFrame and flat(movedFrame.Position-record.Home).Magnitude<=config.Leash then
                        action.Frame=CFrame.new(movedFrame.Position)*previous.Rotation
                        movedFrame=action.Frame
                        ops.Contact(record,action,previous,movedFrame)
                    else
                        movedFrame=nil;action.ChargeStopped=true
                    end
                end
            else
                action.Resolved=true
            end
            if action.ChargeStopped then action.Resolved=true end
        end
        local lunge=config.Attack.Lunge
        if lunge and not action.LungeBlocked and age<config.Attack.Windup then
            -- Only consume this tick's overlap: never teleport to catch up after a stall.
            local elapsed=math.max(0,math.min(age,lunge.Delay+lunge.Duration)-math.max(age-dt,lunge.Delay))
            local distance=math.min(action.LungeRemaining,elapsed*lunge.Distance/lunge.Duration)
            if distance>0 then
                movedFrame=ops.Move(record,action.Frame.LookVector*distance)
                if movedFrame and flat(movedFrame.Position-record.Home).Magnitude<=config.Leash then
                    action.Frame=CFrame.new(movedFrame.Position)*action.Frame.Rotation
                    movedFrame=action.Frame
                    action.LungeRemaining-=distance
                else
                    movedFrame=nil;action.LungeBlocked=true
                end
            end
        end
        if not charge and not action.Resolved and age>=config.Attack.Windup then
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
            state(brain,if age<config.Attack.Windup then "Windup"
                elseif charge and not action.Resolved then "Charging" else "Recovery",now)
            return movedFrame,brain.State
        end
    end
    if brain.State=="Return" then
        local offset=flat(record.Home-position)
        if offset.Magnitude<.25 then
            record.Aggressor=nil
            state(brain,"Patrol",now);brain.NextSense=now+config.ReacquireDelay
        elseif now-brain.Since>(config.ReturnTimeout or 12) then
            -- Navigation can fail on obstacles: never leave an invulnerable creature stranded.
            return CFrame.new(record.Home)*record.Frame.Rotation,brain.State
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
        if offset.Magnitude<=(config.Attack.TriggerRange or config.Attack.Range) and ops.Visible(record,brain.Target) then
            brain.LastProgress=now
            state(brain,"Idle",now)
            if now>=brain.NextAttack then
                brain.Sequence+=1
                local frame=face(position,targetPosition,record.Frame)
                brain.Action={Sequence=brain.Sequence,Start=now,Frame=frame,Resolved=false}
                if config.Attack.Lunge then
                    brain.Action.LungeRemaining=math.min(config.Attack.Lunge.Distance,math.max(0,offset.Magnitude-config.Attack.Range*.75))
                end
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
        local stopRange=math.min(config.Attack.Range,config.Attack.TriggerRange or config.Attack.Range)*.9
        local frame=ops.Move(record,offset.Unit*math.min(math.max(0,offset.Magnitude-stopRange),config.ChaseSpeed*dt))
        return frame,brain.State
    end
    brain.LastProgress=now
    state(brain,"Patrol",now)
    return ops.Patrol(record,dt,now),brain.State
end
return Behaviour
