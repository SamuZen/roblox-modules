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

--
local DEFAULT_PART_COLOR = Color3.fromRGB(163,162,165)

local ShortProperty = {
    Size = 'si',
    Color = 'co',
    CFrame = 'cf',
    Shape = 'sh',
    Material = 'ma',
    Anchored = 'an',
    CanCollide = 'cc',
    CastShadow = 'cs',

    TopSurface = 'ts',
    BottomSurface = 'bos',
    LeftSurface = 'ls',
    RightSurface = 'rs',
    FrontSurface = 'fs',
    BackSurface = 'bas',

    Style = 'st',

}

local LongProperty = {
    cs = 'CastShadow',
    st = 'Style',

    ts = 'TopSurface',
    bos = 'BottomSurface',
    ls = 'LeftSurface',
    rs = 'RightSurface',
    fs = 'FrontSurface',
    bas = 'BackSurface',

    si = 'Size',
    co = 'Color',
    cf = 'CFrame',
    sh = 'Shape',
    ma = 'Material',
    an = 'Anchored',
    cc = 'CanCollide',
}

local PropertyToSerial = {
    CastShadow = {'boolean'},
    Style = {'enum', Enum.Style},

    Size = {'vector3'},
    Color = {'color'},
    CFrame = {'cframe'},
    Shape = {'enum', Enum.PartType},
    Material = {'enum', Enum.Material},
    Anchored = {'boolean'},
    CanCollide = {'boolean'},

    TopSurface = {'enum', Enum.SurfaceType},
    BottomSurface = {'enum', Enum.SurfaceType},
    LeftSurface = {'enum', Enum.SurfaceType},
    RightSurface = {'enum', Enum.SurfaceType},
    FrontSurface = {'enum', Enum.SurfaceType},
    BackSurface = {'enum', Enum.SurfaceType},
}

-- ### SERIALIZATION

Serialization.serialize = {}

-- Base Values

Serialization.serialize.vector3 = function(vec3: Vector3, precision: number?): {number}
    return {
        roundToDecimals(vec3.X, precision or DECIMAL_PRECISION),
        roundToDecimals(vec3.Y, precision or DECIMAL_PRECISION),
        roundToDecimals(vec3.Z, precision or DECIMAL_PRECISION),
    }
end

Serialization.serialize.color = function(color: Color3, ignore, precision: number?): {number}
    if ignore ~= nil and color == ignore then return nil end
    return {
        roundToDecimals(color.R * 255, precision or DECIMAL_PRECISION),
        roundToDecimals(color.G * 255, precision or DECIMAL_PRECISION),
        roundToDecimals(color.B * 255, precision or DECIMAL_PRECISION),
    }
end

Serialization.serialize.cframe = function(cframe: CFrame, precision: number?): {number}
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
end

Serialization.serialize.enum = function(enum: EnumItem, ignore)
    if ignore ~= nil and enum.Value == ignore.Value then return nil end
    return enum.Value
end

Serialization.serialize.boolean = function(bool, ignore)
    if bool ~= nil and bool == ignore then return nil end
    if bool then
        return 1
    else
        return 0
    end
end

-- Instances

Serialization.serialize.part = function(part: Part)
    return {
        [ShortProperty.Color] = Serialization.serialize.color(part.Color, DEFAULT_PART_COLOR),
        [ShortProperty.Size] = Serialization.serialize.vector3(part.Size),
        [ShortProperty.CFrame] = Serialization.serialize.cframe(part:GetPivot()),
        [ShortProperty.Shape] = Serialization.serialize.enum(part.Shape, Enum.PartType.Block),
        [ShortProperty.Material] = Serialization.serialize.enum(part.Material, Enum.Material.Plastic),
        [ShortProperty.Anchored] = Serialization.serialize.boolean(part.Anchored, true),
        [ShortProperty.CanCollide] = Serialization.serialize.boolean(part.CanCollide, true),
        [ShortProperty.CastShadow] = Serialization.serialize.boolean(part.CastShadow, true),

        [ShortProperty.TopSurface] = Serialization.serialize.enum(part.TopSurface, Enum.SurfaceType.Smooth),
        [ShortProperty.BottomSurface] = Serialization.serialize.enum(part.BottomSurface, Enum.SurfaceType.Smooth),
        [ShortProperty.RightSurface] = Serialization.serialize.enum(part.RightSurface, Enum.SurfaceType.Smooth),
        [ShortProperty.LeftSurface] = Serialization.serialize.enum(part.LeftSurface, Enum.SurfaceType.Smooth),
        [ShortProperty.FrontSurface] = Serialization.serialize.enum(part.FrontSurface, Enum.SurfaceType.Smooth),
        [ShortProperty.BackSurface] = Serialization.serialize.enum(part.BackSurface, Enum.SurfaceType.Smooth),
    }
end

Serialization.serialize.trusspart = function(part: TrussPart)
    return {
        [ShortProperty.Color] = Serialization.serialize.color(part.Color, DEFAULT_PART_COLOR),
        [ShortProperty.Size] = Serialization.serialize.vector3(part.Size),
        [ShortProperty.CFrame] = Serialization.serialize.cframe(part:GetPivot()),
        [ShortProperty.Style] = Serialization.serialize.enum(part.Style, Enum.Style.AlternatingSupports),
        [ShortProperty.Material] = Serialization.serialize.enum(part.Material, Enum.Material.Plastic),
        [ShortProperty.Anchored] = Serialization.serialize.boolean(part.Anchored, true),
        [ShortProperty.CanCollide] = Serialization.serialize.boolean(part.CanCollide, true),
        [ShortProperty.CastShadow] = Serialization.serialize.boolean(part.CastShadow, true),

        [ShortProperty.TopSurface] = Serialization.serialize.enum(part.TopSurface, Enum.SurfaceType.Smooth),
        [ShortProperty.BottomSurface] = Serialization.serialize.enum(part.BottomSurface, Enum.SurfaceType.Smooth),
        [ShortProperty.RightSurface] = Serialization.serialize.enum(part.RightSurface, Enum.SurfaceType.Universal),
        [ShortProperty.LeftSurface] = Serialization.serialize.enum(part.LeftSurface, Enum.SurfaceType.Universal),
        [ShortProperty.FrontSurface] = Serialization.serialize.enum(part.FrontSurface, Enum.SurfaceType.Universal),
        [ShortProperty.BackSurface] = Serialization.serialize.enum(part.BackSurface, Enum.SurfaceType.Universal),
    }
end

Serialization.serialize.cornerwedgepart = function(part: CornerWedgePart)
    return {
        [ShortProperty.Material] = Serialization.serialize.enum(part.Material, Enum.Material.Plastic),
        [ShortProperty.Anchored] = Serialization.serialize.boolean(part.Anchored, true),
        [ShortProperty.CanCollide] = Serialization.serialize.boolean(part.CanCollide, true),
        [ShortProperty.CastShadow] = Serialization.serialize.boolean(part.CastShadow, true),

        [ShortProperty.Color] = Serialization.serialize.color(part.Color),
        [ShortProperty.Size] = Serialization.serialize.vector3(part.Size),
        [ShortProperty.CFrame] = Serialization.serialize.cframe(part:GetPivot()),
    }
end

Serialization.serialize.wedgepart = function(part: WedgePart)
    return {
        [ShortProperty.Material] = Serialization.serialize.enum(part.Material, Enum.Material.Plastic),
        [ShortProperty.Anchored] = Serialization.serialize.boolean(part.Anchored, true),
        [ShortProperty.CanCollide] = Serialization.serialize.boolean(part.CanCollide, true),
        [ShortProperty.CastShadow] = Serialization.serialize.boolean(part.CastShadow, true),
        
        [ShortProperty.Color] = Serialization.serialize.color(part.Color),
        [ShortProperty.Size] = Serialization.serialize.vector3(part.Size),
        [ShortProperty.CFrame] = Serialization.serialize.cframe(part:GetPivot()),
    }
end

-- Tabela de deserialização

Serialization.deserialize = {}

-- base values

Serialization.deserialize.vector3 = function(data: {number}): Vector3
    return Vector3.new(data[1], data[2], data[3])
end

Serialization.deserialize.color = function(data: {number}): Color3
    return Color3.fromRGB(data[1], data[2], data[3])
end

Serialization.deserialize.cframe = function(data: {number}): CFrame
    return CFrame.new(data[1], data[2], data[3]) * CFrame.fromOrientation(data[4], data[5], data[6])
end

Serialization.deserialize.enum = function(data, enum: Enum)
    return enum:FromValue(data)
end

Serialization.deserialize.boolean = function(data)
    if data == 1 then
        return true
    else
        return false
    end
end

-- instances

Serialization.deserialize.part = function(data)
    local part = Instance.new("Part")

    part.Anchored = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth

    for key, value in data do
        local property = LongProperty[key]
        if property == nil then continue end
        local serialData = PropertyToSerial[property]

        local result = Serialization.deserialize[serialData[1]](value, serialData[2])

        if key == 'CFrame' then
            part:PivotTo(result)
        else
            part[property] = result
        end
    end

    return part
end

Serialization.deserialize.trusspart = function(data)
    local part = Instance.new("TrussPart")
    part.Anchored = true

    for key, value in data do
        local property = LongProperty[key]
        if property == nil then continue end
        local serialData = PropertyToSerial[property]

        local result = Serialization.deserialize[serialData[1]](value, serialData[2])

        if key == 'CFrame' then
            part:PivotTo(result)
        else
            part[property] = result
        end
    end

    return part
end

Serialization.deserialize.cornerwedgepart = function(data)
    local part = Instance.new("CornerWedgePart")
    part.Anchored = true

    for key, value in data do
        local property = LongProperty[key]
        if property == nil then continue end
        local serialData = PropertyToSerial[property]

        local result = Serialization.deserialize[serialData[1]](value, serialData[2])

        if key == 'CFrame' then
            part:PivotTo(result)
        else
            part[property] = result
        end
    end

    return part
end

Serialization.deserialize.wedgepart = function(data)
    local part = Instance.new("WedgePart")
    part.Anchored = true

    for key, value in data do
        local property = LongProperty[key]
        if property == nil then continue end
        local serialData = PropertyToSerial[property]

        local result = Serialization.deserialize[serialData[1]](value, serialData[2])

        if key == 'CFrame' then
            part:PivotTo(result)
        else
            part[property] = result
        end
    end

    return part
end

Serialization.deserialize.seat = function(data)
    local part = Instance.new("Seat")
    part.Size = Serialization.deserialize["vector3"](data.size)
	part.Color = Serialization.deserialize["color"](data.color)
	part.CFrame = Serialization.deserialize["cframe"](data.origin)
	part.Anchored = true
    return part
end

Serialization.deserialize.vehicleseat = function(data)
    local part = Instance.new("VehicleSeat")
    part.Size = Serialization.deserialize["vector3"](data.size)
	part.Color = Serialization.deserialize["color"](data.color)
	part.CFrame = Serialization.deserialize["cframe"](data.origin)
	part.Anchored = true
    return part
end








-- Funções utilitárias para JSON
Serialization.jsonEncode = function(tbl: {any}): string
    return HttpService:JSONEncode(tbl)
end

Serialization.jsonDecode = function(jsonString: string): {any}
    return HttpService:JSONDecode(jsonString)
end





function Serialization.getSerializationFunction(instance: Instance)
    local className = instance.ClassName
    local serializationFuncion = Serialization.serialize[string.lower(className)]
    return serializationFuncion
end

function Serialization.getDeserializationFunction(className: string)
    return Serialization.deserialize[string.lower(className)]
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

return Serialization