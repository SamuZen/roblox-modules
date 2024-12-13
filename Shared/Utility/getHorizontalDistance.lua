return function(pos1: Vector3, pos2: Vector3)
    local p2Normalized = Vector3.new(pos2.X, pos1.Y, pos2.Z)
    return (p2Normalized - pos1).Magnitude
end