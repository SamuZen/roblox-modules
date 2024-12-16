return function(model: Model, type: string, property: string, value: any)
    for _, child in model:GetDescendants() do
        if not child:IsA(type) then continue end
        child[property] = value
    end
end