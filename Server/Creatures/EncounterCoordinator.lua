-- Encounter state only. Target adapters and validity belong to the host game.
local Coordinator={}
Coordinator.__index=Coordinator
function Coordinator.new(options)
    return setmetatable({Options=options,Participants={},Records={},Assignments={},Counts={},Serial=0,Closed=false},Coordinator)
end
function Coordinator:AddParticipant(participant)
    if not table.find(self.Participants,participant) then table.insert(self.Participants,participant) end
end
function Coordinator:RemoveParticipant(participant)
    local index=table.find(self.Participants,participant)
    if index then table.remove(self.Participants,index) end
    for record,entry in self.Assignments do
        if entry.Participant==participant then self:Assign(record,nil,nil,0) end
    end
end
function Coordinator:Assign(record,participant,target,now)
    local entry=self.Assignments[record]
    if entry and entry.Participant then self.Counts[entry.Participant]=math.max(0,(self.Counts[entry.Participant] or 0)-1) end
    self.Assignments[record]={Participant=participant,Target=target,Since=now,NextReview=now+(self.Options.ReviewInterval or .75)}
    if participant then self.Counts[participant]=(self.Counts[participant] or 0)+1 end
    return target
end
function Coordinator:Register(record,now)
    assert(not self.Closed,"Closed encounter")
    if self.Records[record] then return self:GetTarget(record,now,false) end
    assert(not record.Encounter,"Creature already belongs to an encounter")
    self.Serial+=1
    self.Records[record]=self.Serial
    record.Encounter=self
    record.CombatReadyAt=now+(self.Options.Preparation or 1)
    return self:GetTarget(record,now,false)
end
function Coordinator:Remove(record)
    self:Assign(record,nil,nil,0)
    self.Assignments[record]=nil
    self.Records[record]=nil
    record.Encounter=nil
    record.CombatReadyAt=nil
    record.CombatPosition=nil
    record.Navigation=nil
end
function Coordinator:Contains(position)
    return not self.Options.Contains or self.Options.Contains(position)
end
function Coordinator:GetTarget(record,now,committed)
    if self.Closed or not self.Records[record] then return nil end
    local entry=self.Assignments[record]
    local current=entry and entry.Target
    local currentPosition=current and self.Options.Position(record,current)
    local valid=currentPosition and self:Contains(currentPosition)
        and table.find(self.Participants,entry.Participant)~=nil
    -- Behaviour owns cancellation of invalid committed attacks, including charge.
    if committed then return current end
    if valid and now<entry.NextReview then return current end
    if valid then entry.NextReview=now+(self.Options.ReviewInterval or .75) end
    local function cost(participant,position)
        local delta=position-record.Frame.Position
        local distance=Vector3.new(delta.X,0,delta.Z).Magnitude
        local count=(self.Counts[participant] or 0)-(if entry and entry.Participant==participant then 1 else 0)
        return distance/(self.Options.DistanceScale or 24)+count*(self.Options.PressureWeight or .6)
    end
    local best,bestTarget,bestCost=nil,nil,math.huge
    local count=#self.Participants
    for offset=1,count do
        local participant=self.Participants[(self.Records[record]+offset-2)%count+1]
        local target=self.Options.Target(record,participant)
        local position=target and self.Options.Position(record,target)
        if position and self:Contains(position) then
            local score=cost(participant,position)
            if self.Options.Score then score+=self.Options.Score(record,participant,target) end
            if score<bestCost then best,bestTarget,bestCost=participant,target,score end
        end
    end
    if valid then
        local score=cost(entry.Participant,currentPosition)
        if self.Options.Score then score+=self.Options.Score(record,entry.Participant,current) end
        if best==entry.Participant or now-entry.Since<(self.Options.MinLock or 2.5)
            or bestCost+(self.Options.SwitchMargin or .5)>=score then return current end
    end
    return self:Assign(record,best,bestTarget,now)
end
function Coordinator:Destroy()
    if self.Closed then return end
    self.Closed=true
    for record in self.Records do self:Remove(record) end
    table.clear(self.Participants)
    table.clear(self.Counts)
    self.SpatialIndex=nil
end
return Coordinator
