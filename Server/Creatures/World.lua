-- Reusable authoritative creature registry. Game policy enters through callbacks.
local Http = game:GetService("HttpService")
local Collection = game:GetService("CollectionService")
local World = {}
World.__index = World

function World.new(options)
    assert(options.Parent and options.Definitions and options.Tag)
    return setmetatable({Options=options, Records={}, ByPart={}, Time=if options.Clock then options.Clock() else 0, Serial=0}, World)
end

function World:Spawn(kind, groundFrame, context)
    local definition = assert(self.Options.Definitions[kind], "Unknown creature: "..tostring(kind))
    assert(definition.Health > 0 and definition.Size.X > 0 and definition.Size.Y > 0 and definition.Size.Z > 0)
    local part = Instance.new("Part")
    part.Name = kind
    part.Size = definition.Size
    part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, true
    part.Transparency, part.CastShadow = 1, false
    part.CFrame = groundFrame * CFrame.new(0, definition.Size.Y/2, 0)
    local id = Http:GenerateGUID(false)
    local record = {Id=id, Kind=kind, Part=part, Definition=definition, Health=definition.Health,
        Context=context or {}, Home=part.Position, Frame=part.CFrame, Alive=true}
    self.Serial += 1
    record.NextMove = self.Time + (self.Serial % 10)/10 * (definition.MoveInterval or .1)
    record.Heading = self.Serial * 2.399963
    record.TurnAt = self.Time + 2
    part:SetAttribute("CreatureId", id)
    part:SetAttribute("CreatureType", kind)
    part:SetAttribute("Health", record.Health)
    part:SetAttribute("MaxHealth", record.Health)
    part:SetAttribute("MoveInterval", definition.MoveInterval or .1)
    part:SetAttribute("CreatureState", "Idle")
    if self.Options.Configure then self.Options.Configure(record) end
    self.Records[id], self.ByPart[part] = record, record
    record.Removing = part.Destroying:Connect(function() self:Remove(record, "Removed") end)
    part.Parent = record.Context.Parent or self.Options.Parent
    Collection:AddTag(part, self.Options.Tag)
    return record
end

function World:Get(value)
    if typeof(value)=="Instance" then return self.ByPart[value] end
    return self.Records[value]
end

function World:Remove(record, reason)
    if self.Records[record.Id] ~= record then return false end
    self.Records[record.Id], self.ByPart[record.Part] = nil, nil
    record.Alive = false
    record.Removing:Disconnect()
    record.Part:Destroy()
    if self.Options.Removed then self.Options.Removed(record, reason or "Removed") end
    return true
end

function World:Damage(record, amount, source)
    if not record or self.Records[record.Id]~=record or not record.Alive then return nil, "InactiveCreature" end
    if type(amount)~="number" or amount~=amount or amount<=0 or amount==math.huge then return nil, "InvalidDamage" end
    if self.Options.CanDamage and not self.Options.CanDamage(record, source) then return nil, "CreaturePermission" end
    record.Health = math.max(0, record.Health-amount)
    record.Part:SetAttribute("Health", record.Health)
    if record.Health>0 then return nil end
    -- Retire synchronously, before any game callback can yield or award twice.
    local defeat = {Id=record.Id, Kind=record.Kind, Position=record.Frame.Position, Context=record.Context}
    self:Remove(record, "Killed")
    if self.Options.Defeated then self.Options.Defeated(record, source, defeat) end
    return defeat
end

function World:Step(dt)
    self.Time = if self.Options.Clock then self.Options.Clock() else self.Time+dt
    for _,record in self.Records do
        if not record.Part:IsDescendantOf(workspace) then self:Remove(record, "Removed"); continue end
        local interval = math.max(.03, record.Definition.MoveInterval or .1)
        if self.Time < record.NextMove then continue end
        local elapsed = math.min(.25, self.Time-(record.LastMove or self.Time-interval))
        record.LastMove, record.NextMove = self.Time, self.Time+interval
        if self.Options.Move then
            local frame, state = self.Options.Move(record, elapsed, self.Time)
            local moving=frame~=nil and (frame.Position-record.Frame.Position).Magnitude>.001
            state=state or (if moving then "Moving" else "Idle")
            if record.Part:GetAttribute("CreatureState")~=state then record.Part:SetAttribute("CreatureState",state) end
            if frame and frame~=record.Frame then
                record.Frame = frame
                record.Part.CFrame = frame
            end
        end
    end
end

function World:Destroy()
    for _,record in self.Records do self:Remove(record, "Shutdown") end
end
return World
