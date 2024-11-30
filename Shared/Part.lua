local Part = {}

export type PartAttributes = {
    Parent: Instance?,
    Size: Vector3?,
    CanCollide: boolean?,
    CanTouch: boolean?,
    CanQuery: boolean?,
    Transparency: number?,
    Color: Color3?,
    Anchored: boolean?,
    Massless: boolean?,
    CastShadow: boolean?,
    Shape: Enum.PartType?,
    CFrame: CFrame?,
    PivotOffset: CFrame?,
    Material: Enum.Material,
}
function Part.create(attributes: PartAttributes): Part
    local part = Instance.new("Part")
    for key, value in attributes do
        part[key] = value
    end
    return part
end

return Part