-- Local roots never move or weld to replicated markers. Owns stream-in/out cleanup.
local Collection = game:GetService("CollectionService")
local Run = game:GetService("RunService")
local Presentation = {}
Presentation.__index = Presentation

function Presentation.new(options)
    local self = setmetatable({Options=options, Records={}, Pending={}, Connections={}}, Presentation)
    self.Folder = Instance.new("Folder")
    self.Folder.Name, self.Folder.Parent = options.Name or "CreatureVisuals", workspace
    local function add(part) self:Add(part) end
    table.insert(self.Connections, Collection:GetInstanceAddedSignal(options.Tag):Connect(add))
    table.insert(self.Connections, Collection:GetInstanceRemovedSignal(options.Tag):Connect(function(part) self:Remove(part) end))
    for _,part in Collection:GetTagged(options.Tag) do add(part) end
    table.insert(self.Connections, Run.PreRender:Connect(function(dt) self:Step(dt) end))
    return self
end

function Presentation:Add(part)
    if self.Records[part] or not part:IsA("BasePart") or not part:IsDescendantOf(workspace) then return end
    if not part:GetAttribute("CreatureId") or not part:GetAttribute("CreatureType") or not part:GetAttribute("Health") then
        self.Pending[part]=true
        return
    end
    self.Pending[part]=nil
    local root = Instance.new("Part")
    root.Name = part.Name
    root.Size = part.Size
    root.Anchored, root.CanCollide, root.CanTouch, root.CanQuery = true, false, false, false
    root.Transparency, root.CastShadow, root.CFrame = 1, false, part.CFrame
    for _,name in {"CreatureId", "CreatureType", "Health", "MaxHealth", "ExpeditionId", "OwnerUserId"} do
        root:SetAttribute(name, part:GetAttribute(name))
    end
    root.Parent = self.Folder
    local record = {Marker=part, Root=root, From=part.CFrame, To=part.CFrame, Elapsed=0, Connections={}}
    self.Records[part] = record
    local ok, visual = pcall(self.Options.CreateVisual, root, part)
    if not ok then self:Remove(part); warn("[Creatures] "..tostring(visual)); return end
    record.Visual = visual
    if self.Options.LocalTag then Collection:AddTag(root, self.Options.LocalTag) end
    table.insert(record.Connections, part:GetAttributeChangedSignal("Health"):Connect(function()
        root:SetAttribute("Health", part:GetAttribute("Health"))
    end))
    table.insert(record.Connections, part.AncestryChanged:Connect(function()
        if not part:IsDescendantOf(workspace) then self:Remove(part) end
    end))
end

function Presentation:Remove(part)
    self.Pending[part]=nil
    local record = self.Records[part]
    if not record then return end
    self.Records[part] = nil
    for _,connection in record.Connections do connection:Disconnect() end
    if self.Options.Removed then self.Options.Removed(record) end
    record.Root:Destroy()
end

function Presentation:Step(dt)
    for part in self.Pending do
        if part:IsDescendantOf(workspace) then self:Add(part) else self.Pending[part]=nil end
    end
    for part,record in self.Records do
        if not part:IsDescendantOf(workspace) then self:Remove(part); continue end
        local frame = part.CFrame
        if frame ~= record.To then
            record.From, record.To, record.Elapsed = record.Root.CFrame, frame, 0
            if (frame.Position-record.From.Position).Magnitude > (self.Options.TeleportDistance or 20) then
                record.From = frame
            end
        end
        record.Elapsed += dt
        local interval = math.clamp(part:GetAttribute("MoveInterval") or .1, .03, 1)
        record.Root.CFrame = record.From:Lerp(record.To, math.min(1, record.Elapsed/interval))
    end
end

function Presentation:Destroy()
    for _,connection in self.Connections do connection:Disconnect() end
    for part in self.Records do self:Remove(part) end
    table.clear(self.Pending)
    self.Folder:Destroy()
end
return Presentation
