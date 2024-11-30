local function weld(p0: BasePart, p1: BasePart): WeldConstraint
    local _weld = Instance.new("WeldConstraint")
    _weld.Parent = p0
    _weld.Part0 = p0
    _weld.Part1 = p1
    return _weld
end

return weld