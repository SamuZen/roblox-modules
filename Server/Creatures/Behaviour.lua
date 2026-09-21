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
local function aimCharge(action,position,target)
    local attack=action.Attack
    local charge=attack.Charge
    action.Frame=face(position,target,action.Frame)
    local maximum=charge.Speed*attack.Active
    action.ChargeRemaining=if charge.StopDistance
        then math.min(maximum,math.max(0,flat(target-position).Magnitude-charge.StopDistance)) else maximum
end
function Behaviour.Step(record,dt,now,ops)
    local config=record.Definition.Behaviour
    local brain=record.Brain
    local encounter=record.Encounter
    if not brain then
        brain={State="Patrol",Since=now,NextSense=now,NextAttack=now,NextSpecial=now,Sequence=0,LastProgress=now,LastPosition=record.Frame.Position}
        record.Brain=brain
    end
    if encounter then
        record.Aggressor=nil
        brain.Target=encounter:GetTarget(record,now,brain.Action~=nil)
        if now<record.CombatReadyAt then
            state(brain,"Preparing",now)
            return nil,brain.State
        end
    end
    local function cancel()
        if brain.Action then ops.Action(record,nil);brain.Action=nil end
        brain.Target=nil
        brain.NextAttack=now+config.Attack.Cooldown
        brain.LostAt=nil
        brain.FarAt=nil
        record.Aggressor=nil
        state(brain,if encounter then "Idle" else "Return",now)
        if not encounter and ops.Reset then ops.Reset(record) end
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
    local currentAttack=brain.Action and brain.Action.Attack or config.Attack
    local committedCharge=brain.Action and currentAttack.Charge and now-brain.Action.Start>=currentAttack.Windup
    if brain.Target and ((not encounter and flat(position-record.Home).Magnitude>config.Leash) or (not committedCharge
        and (not targetPosition
            or math.abs(targetPosition.Y-position.Y)>config.MaxHeight))) then
        cancel();targetPosition=nil
    end
    if not encounter and brain.Target and targetPosition and not committedCharge then
        if flat(targetPosition-position).Magnitude>(config.ChaseRange or config.Leash) then
            brain.FarAt=brain.FarAt or now
            if now-brain.FarAt>=(config.LoseTargetAfter or 3) then cancel();targetPosition=nil end
        else brain.FarAt=nil end
    end
    if brain.Action then
        local action=brain.Action
        local attack=action.Attack
        local age=now-action.Start
        local movedFrame
        local charge=attack.Charge
        if charge and charge.TrackDuringWindup and not action.ChargeStarted and targetPosition then
            -- Include the launch tick, then commit both heading and travel distance.
            aimCharge(action,position,targetPosition)
            movedFrame=action.Frame
            ops.Action(record,action)
        end
        if charge and age>=attack.Windup then
            action.ChargeStarted=true
            if age<attack.Windup+attack.Active and not action.ChargeStopped then
                local elapsed=math.min(dt,age-attack.Windup)
                if elapsed>0 then
                    local previous=action.Frame
                    local distance=math.min(action.ChargeRemaining,charge.Speed*elapsed)
                    movedFrame=ops.Move(record,previous.LookVector*distance)
                    if movedFrame and (encounter or flat(movedFrame.Position-record.Home).Magnitude<=config.Leash) then
                        action.Frame=CFrame.new(movedFrame.Position)*previous.Rotation
                        movedFrame=action.Frame
                        action.ChargeRemaining=math.max(0,action.ChargeRemaining-distance)
                        ops.Contact(record,action,previous,movedFrame)
                        if action.ChargeRemaining<=.001 then action.ChargeStopped=true end
                    else
                        movedFrame=nil;action.ChargeStopped=true
                    end
                end
            else
                action.Resolved=true
            end
            if action.ChargeStopped then action.Resolved=true end
            if action.Resolved then action.RecoveryStart=action.RecoveryStart or now end
        end
        local lunge=attack.Lunge
        if lunge and not action.LungeBlocked and age<attack.Windup then
            if lunge.TrackDuringWindup and not action.LungeStarted and targetPosition then
                -- Predict where the target will be at impact; commit before leaving the ground.
                local lead=Vector3.zero
                local sampleTime=now-(action.LungeTargetTime or now)
                if action.LungeTargetPosition and sampleTime>.001 then
                    local velocity=flat(targetPosition-action.LungeTargetPosition)/sampleTime
                    lead=velocity*math.max(0,attack.Windup-age)
                    local limit=lunge.LeadDistance or 0
                    if lead.Magnitude>limit then lead=lead.Unit*limit end
                end
                local destination=targetPosition+lead
                action.Frame=face(position,destination,action.Frame)
                local landingRange=attack.Range*(lunge.LandingRangeScale or .75)
                action.LungeRemaining=math.min(lunge.Distance,math.max(0,flat(destination-position).Magnitude-landingRange))
                action.LungeTargetPosition,action.LungeTargetTime=targetPosition,now
                movedFrame=action.Frame
            end
            if age>=lunge.Delay then action.LungeStarted=true end
            -- Only consume this tick's overlap: never teleport to catch up after a stall.
            local elapsed=math.max(0,math.min(age,lunge.Delay+lunge.Duration)-math.max(age-dt,lunge.Delay))
            local distance=math.min(action.LungeRemaining,elapsed*lunge.Distance/lunge.Duration)
            if distance>0 then
                movedFrame=ops.Move(record,action.Frame.LookVector*distance)
                if movedFrame and (encounter or flat(movedFrame.Position-record.Home).Magnitude<=config.Leash) then
                    action.Frame=CFrame.new(movedFrame.Position)*action.Frame.Rotation
                    movedFrame=action.Frame
                    action.LungeRemaining-=distance
                else
                    movedFrame=nil;action.LungeBlocked=true
                end
            end
        end
        if not charge and not action.Resolved and age>=attack.Windup then
            action.Resolved=true -- consume before callbacks; a late tick must never replay a strike
            if age<=attack.Windup+attack.Active and targetPosition then
                ops.Hit(record,brain.Target,action)
            end
        end
        local finished=if charge and action.RecoveryStart then now>=action.RecoveryStart+attack.Recovery
            else age>=attack.Windup+attack.Active+attack.Recovery
        if finished then
            brain.Action=nil;ops.Action(record,nil)
            -- Independent cooldowns begin after recovery; the special never delays the basic.
            if action.AttackId=="Special" then brain.NextSpecial=now+attack.Cooldown
            else brain.NextAttack=now+attack.Cooldown end
            brain.LastProgress=now
            state(brain,"Chase",now)
            -- Commit this tick's final movement before selecting the next action.
            if movedFrame then return movedFrame,brain.State end
        else
            state(brain,if age<attack.Windup then "Windup"
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
        if not brain.Target and not encounter then brain.Target=ops.Find(record,config.DetectRange) end
        targetPosition=brain.Target and ops.Position(record,brain.Target)
    end
    if targetPosition then
        if not ops.Visible(record,brain.Target) then
            brain.LostAt=brain.LostAt or now
            if not encounter and now-brain.LostAt>config.LoseSightAfter then cancel();return nil,brain.State end
        else brain.LostAt=nil end
        local offset=flat(targetPosition-position)
        local basicRange=config.Attack.TriggerRange or config.Attack.Range
        local basicInRange=offset.Magnitude<=basicRange
        if not basicInRange and encounter and ops.BasicReachable then
            basicInRange=ops.BasicReachable(record,brain.Target,targetPosition)
        end
        local selected,attackId=config.Attack,"Basic"
        local special=config.Special
        -- Ranged specials can fill a basic cooldown; approach specials keep melee priority.
        local specialOpportunity=not basicInRange or (special and special.DuringBasicCooldown and now<brain.NextAttack)
        if special and specialOpportunity and offset.Magnitude>=(special.MinRange or basicRange)
            and (special.Approach or offset.Magnitude<=(special.TriggerRange or special.Range)) and now>=(brain.NextSpecial or 0) then
            selected,attackId=special,"Special"
        end
        local inRange=attackId=="Special" or basicInRange
        if inRange and ops.Visible(record,brain.Target) then
            brain.LastProgress=now
            state(brain,"Idle",now)
            if now>=(if attackId=="Special" then brain.NextSpecial or 0 else brain.NextAttack) then
                brain.Sequence+=1
                local frame=face(position,targetPosition,record.Frame)
                brain.Action={Sequence=brain.Sequence,Start=now,Frame=frame,Resolved=false,AttackId=attackId,Attack=selected}
                if selected.Lunge then
                    brain.Action.LungeTargetPosition,brain.Action.LungeTargetTime=targetPosition,now
                    local landingRange=selected.Range*(selected.Lunge.LandingRangeScale or .75)
                    brain.Action.LungeRemaining=math.min(selected.Lunge.Distance,math.max(0,offset.Magnitude-landingRange))
                end
                if selected.Charge then
                    aimCharge(brain.Action,position,targetPosition)
                end
                state(brain,"Windup",now)
                ops.Action(record,brain.Action)
                return frame,brain.State
            end
            local adjusted=encounter and ops.Positioning and ops.Positioning(record,brain.Target,targetPosition,dt,now)
            if adjusted then
                state(brain,"Chase",now)
                return face(adjusted.Position,targetPosition,adjusted),brain.State
            end
            return face(position,targetPosition,record.Frame),brain.State
        end
        state(brain,"Chase",now)
        if offset.Magnitude<.001 then return nil,brain.State end
        if flat(position-brain.LastPosition).Magnitude>.2 then brain.LastPosition,brain.LastProgress=position,now end
        if not encounter and now-brain.LastProgress>config.StuckTimeout then cancel();brain.LastProgress=now;return nil,brain.State end
        if encounter and ops.Positioning then
            return ops.Positioning(record,brain.Target,targetPosition,dt,now),brain.State
        end
        local stopRange=math.min(config.Attack.Range,config.Attack.TriggerRange or config.Attack.Range)*.9
        local frame=ops.Move(record,offset.Unit*math.min(math.max(0,offset.Magnitude-stopRange),config.ChaseSpeed*dt))
        return frame,brain.State
    end
    brain.LastProgress=now
    if encounter then state(brain,"Idle",now);return nil,brain.State end
    state(brain,"Patrol",now)
    return ops.Patrol(record,dt,now),brain.State
end
return Behaviour
