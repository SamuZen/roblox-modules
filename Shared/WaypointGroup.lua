-- PointManager.lua
local WaypointGroup = {}
WaypointGroup.__index = WaypointGroup

WaypointGroup.ORDER = {
    ORDERED = 1,
    RANDOM = 2,
}

function WaypointGroup.new(data:{CFrame}, getOrder)
    local self = setmetatable({}, WaypointGroup)
    self.points = data
    self.index = 1
    self.getOrder = getOrder or WaypointGroup.ORDER.ORDERED
    self.amountOfPoints = #data
    return self
end

function WaypointGroup:GetNextIndex()
    self:Advance()
    return self:GetIndex()
end

function WaypointGroup:GetNextData()
    self:Advance()
    return self:GetCurrent()
end

function WaypointGroup:Advance()
    if self.getOrder == WaypointGroup.ORDER.ORDERED then
        -- Increment index for ordered traversal
        self.index += 1
        if self.index > self.amountOfPoints then
            self.index = 1
        end
    elseif self.getOrder == WaypointGroup.ORDER.RANDOM then
        -- Select a random index that is not the current one
        local newIndex
        repeat
            newIndex = math.random(1, self.amountOfPoints)
        until newIndex ~= self.index
        self.index = newIndex
    end
end

function WaypointGroup:GetIndex()
    return self.index
end

function WaypointGroup:GetCurrent()
    return self.points[self.index]
end

function WaypointGroup.GetPointsFromFolderOfParts(folder)
    local points = {}
    local parts = folder:GetChildren()
    for i = 1, #parts, 1 do
        table.insert(points, folder[i]:GetPivot())
    end
    return points
end

return WaypointGroup
