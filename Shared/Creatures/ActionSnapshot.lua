-- One attribute carries the coherent action sequence + double precision server timestamp.
local Snapshot={}
function Snapshot.Encode(sequence,start,point)
    local data=buffer.create(if point then 24 else 12)
    buffer.writeu32(data,0,sequence)
    buffer.writef64(data,4,start)
    if point then
        buffer.writef32(data,12,point.X);buffer.writef32(data,16,point.Y);buffer.writef32(data,20,point.Z)
    end
    return buffer.tostring(data)
end
function Snapshot.Decode(value)
    if type(value)~="string" or (#value~=12 and #value~=24) then return end
    local data=buffer.fromstring(value)
    local start=buffer.readf64(data,4)
    if start~=start or math.abs(start)==math.huge then return end
    local point
    if #value==24 then
        point=Vector3.new(buffer.readf32(data,12),buffer.readf32(data,16),buffer.readf32(data,20))
        if point.Magnitude~=point.Magnitude or point.Magnitude==math.huge then return end
    end
    return buffer.readu32(data,0),start,point
end
return Snapshot
