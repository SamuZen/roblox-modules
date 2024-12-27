local HttpService = game:GetService("HttpService")

local Serialization = {}

local DECIMAL_PRECISION = 2

local function roundToDecimals(value: number, decimals: number): number
    local factor = 10 ^ decimals
    return math.round(value * factor) / factor
end

local function ceilToDecimals(value: number, decimals: number): number
    local factor = 10 ^ decimals
    return math.ceil(value * factor) / factor
end

-- Tabela de serialização
Serialization.serialize = {
    vector3 = function(vec3: Vector3, precision: number?): {number}
        return {
            roundToDecimals(vec3.X, precision or DECIMAL_PRECISION),
            roundToDecimals(vec3.Y, precision or DECIMAL_PRECISION),
            roundToDecimals(vec3.Z, precision or DECIMAL_PRECISION),
        }
    end,
    color = function(color: Color3, precision: number?): {number}
        return {
            roundToDecimals(color.R, precision or DECIMAL_PRECISION),
            roundToDecimals(color.G, precision or DECIMAL_PRECISION),
            roundToDecimals(color.B, precision or DECIMAL_PRECISION),
        }
    end,
    cframe = function(cframe: CFrame, precision: number?): {number}
        local position = cframe.Position
        local orientationX, orientationY, orientationZ = cframe:ToOrientation()

        return {
            roundToDecimals(position.X, precision or DECIMAL_PRECISION),
            ceilToDecimals(position.Y, precision or DECIMAL_PRECISION),
            roundToDecimals(position.Z, precision or DECIMAL_PRECISION),
            roundToDecimals(orientationX, precision or DECIMAL_PRECISION),
            roundToDecimals(orientationY, precision or DECIMAL_PRECISION),
            roundToDecimals(orientationZ, precision or DECIMAL_PRECISION),
        }
    end,
}

-- Tabela de deserialização
Serialization.deserialize = {
    vector3 = function(data: {number}): Vector3
        return Vector3.new(data[1], data[2], data[3])
    end,
    color = function(data: {number}): Color3
        return Color3.fromRGB(data[1], data[2], data[3])
    end,
    cframe = function(data: {number}): CFrame
        return CFrame.new(data[1], data[2], data[3]) * CFrame.fromOrientation(data[4], data[5], data[6])
    end,
}

-- Funções utilitárias para JSON
Serialization.jsonEncode = function(tbl: {any}): string
    return HttpService:JSONEncode(tbl)
end

Serialization.jsonDecode = function(jsonString: string): {any}
    return HttpService:JSONDecode(jsonString)
end









--- ### OLD

local function decimals(value, decimals)
    local v = 10 * decimals
    return math.round(value * v) / v
end

local function decimalsCeil(value, decimals)
    local v = 10 * decimals
    return math.ceil(value * v) / v
end

function Serialization.tableToJsonString(table: {any}): string
    return HttpService:JSONEncode(table)
end

function Serialization.jsonStringToTable(jsonString: string): {any}
    return HttpService:JSONDecode(jsonString)
end

-- ### Buildshape

function Serialization.buildShape(data: string): Enum.PartType
    return data
end

function Serialization.splitShape(shape: Enum.PartType)
    return tostring(shape)
end

-- ### Vector3

function Serialization.splitVector3(vec3: Vector3): {number}
    return {
        [1] = decimals(vec3.X, 2),
        [2] = decimals(vec3.Y, 2),
        [3] = decimals(vec3.Z, 2),
    }
end

function Serialization.buildVector3(data: {number}): Vector3
    return Vector3.new(data[1], data[2], data[3])
end

-- ### Color

function Serialization.splitColor(color: Color3): {number}
    return {
        [1] = decimals(color.R, 2),
        [2] = decimals(color.G, 2),
        [3] = decimals(color.B, 2),
    }
end

function Serialization.buildColor(data: {number}): Color3
    return Color3.fromRGB(data[1], data[2], data[3])
end

-- ### CFrame

function Serialization.buildCFrame(data:{number}): CFrame
    return CFrame.new(data[1], data[2], data[3]) * CFrame.fromOrientation(data[4], data[5], data[6])
end

function Serialization.splitCFrameData(cframe: CFrame): {number}
    local roundedX = decimals(cframe.Position.X, 2)
	local roundedY = decimalsCeil(cframe.Position.Y, 2)
	local roundedZ = decimals(cframe.Position.Z, 2)

    local x,y,z = cframe:ToOrientation()
    local roundOriX = decimals(x, 2)
	local roundOriY = decimals(y, 2)
    local roundOriZ = decimals(z, 2)

    local data = {
        [1] = roundedX,
        [2] = roundedY,
        [3] = roundedZ,
        [4] = roundOriX,
        [5] = roundOriY,
        [6] = roundOriZ,
    }

    return data
end

return Serialization