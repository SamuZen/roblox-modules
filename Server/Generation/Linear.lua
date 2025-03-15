
local Linear = {}

function Linear.create(prefab: Instance)
    local level = prefab:Clone()

    local start = level.Setup.Start :: BasePart
    local finish = level.Setup.Finish :: BasePart

    start.Transparency = 1
    finish.Transparency = 1
    start.CanCollide = false
    finish.CanCollide = false

    if level:IsA("Folder") then
		local model = Instance.new("Model")
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
        for _, c in level:GetChildren() do
            c.Parent = model
        end
		level = model
	end

    level.PrimaryPart = start
    
    return {
        model = level,
        start = start,
        finish = finish,
    }
end

function Linear.assemble(assembleData, rootCFrame: CFrame, parent: Instance)
    local currentCFrame = rootCFrame

    local function createRegion(data, index, cframe: CFrame)
        local levelInfo = Linear.create(data.prefab)
        levelInfo.model:PivotTo(cframe)
        levelInfo.model.Parent = parent
        levelInfo.model.Name = `{index}-{data.prefab.Name}`
        currentCFrame = levelInfo.finish.CFrame
    end

    for index, data in assembleData do
        local _cframe = currentCFrame * CFrame.Angles(0, math.rad(data.angle), 0)
        -- create something in beetwen?
        task.wait()
        createRegion(data, index, _cframe)
    end
end

return Linear