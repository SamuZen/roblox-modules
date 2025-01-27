
local Linear = {}

local function create(prefab: Instance)
    local level = prefab:Clone()

    local start = level:FindFirstChild("Start", true) :: BasePart
    local finish = level:FindFirstChild("Finish", true) :: BasePart

    start.Transparency = 1
    finish.Transparency = 1
    start.CanCollide = false
    finish.CanCollide = false

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
        local levelInfo = create(data.prefab)
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