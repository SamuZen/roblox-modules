-- ### Roblox Services
local HTTPService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

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


return Common