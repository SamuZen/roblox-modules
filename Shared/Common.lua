-- ### Roblox Services
local HTTPService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

-- ### Modules
local Time = require(script.Parent.Time)

local Common = {
    isStudio = RunService:IsStudio(),
    isServer = RunService:IsServer(),
    isClient = RunService:IsClient(),

    printDatastoreEnabled = false,
}

Common.getCurrentDecimalTime = Time.getCurrentTime

function printDatastore(...)
    if Common.printDatastoreEnabled then
        print(...)
    end
end

function Common.tableToString(mod)
    local code = "error"
    local success, err = pcall(function()
        code = HTTPService:JSONEncode(mod)
    end)
    if not success then
        warn("!!! [CRITICAL] FAILED TO CONVERT TABLE TO STRING: ", err, mod)
        return nil
    end
    return code
end

function Common.updateAsync(store, key, method)
    printDatastore("@@@ UPDATING KEY: ", key, method)

    local success, result = pcall(function()
        return store:UpdateAsync(key, method)
    end)

    if not success then
        warn("!!! FAILED TO UPDATE KEY: ", key, result)
        return success, result
    end

    return success, result
end

function Common.randomDecimal()
    local decimal = math.random() + 0.01
    if math.random(100) >= 50 then
        decimal = -decimal
    end
    return decimal
end

function Common.getRandomFlatDir()
    local randX = Common.randomDecimal()
    local randZ = Common.randomDecimal()

    -- NOTE: remember you CANNOT put .unit on an empty vector
    local moveDir = Vector3.new(randX, 0, randZ).unit

    if moveDir.X ~= moveDir.X then
        error("NAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAN")
    end

    return moveDir
end

function Common.createTestLine(posA, posB, duration)
    local line = Instance.new("Part")
    line.Transparency = 0
    line.Color = Color3.fromRGB(255, 0, 0)
    line.CanCollide = false
    line.CanTouch = false
    line.Anchored = true

    local midPos = (posA + posB) / 2
    local vect = (posB - posA).unit
    local length = (posA - posB).Magnitude
    local finalFrame = CFrame.new(midPos, midPos + vect)

    line.Size = Vector3.new(0.1, 0.1, length)
    line.CFrame = finalFrame
    line.Name = "TESTLINE123"
    line.Parent = game.Workspace

    if duration then
        Debris:AddItem(line, duration)
    end

    return line
end

function Common.getGUID()
    local randomID = HTTPService:GenerateGUID(false)

    -- Remove hyphens and truncate to 10 characters
    randomID = string.gsub(randomID, "-", "")
    randomID = string.sub(randomID, 1, 15)

    return randomID
end

function Common.getHorizontalVector(pos1, pos2)
    return Vector3.new(pos2.X - pos1.X, 0, pos2.Z - pos1.Z)
end

function Common.getHorizontalDist(pos1, pos2)
    local finalVect = Common.getHorizontalVector(pos2, pos1)
    if finalVect == Vector3.new() then
        return 0
    end
    return finalVect.Magnitude
end

function Common.len(lst)
    local count = 0
    for name, obj in pairs(lst) do
        count = count + 1
    end
    return count
end

return Common