-- One attribute carries the coherent action sequence + double precision server timestamp.
local Snapshot={}
function Snapshot.Encode(sequence,start)
    local data=buffer.create(12)
    buffer.writeu32(data,0,sequence)
    buffer.writef64(data,4,start)
    return buffer.tostring(data)
end
function Snapshot.Decode(value)
    if type(value)~="string" or #value~=12 then return end
    local data=buffer.fromstring(value)
    local start=buffer.readf64(data,4)
    if start~=start or math.abs(start)==math.huge then return end
    return buffer.readu32(data,0),start
end
return Snapshot
