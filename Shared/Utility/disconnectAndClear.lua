--[[
	disconnectAndClear - A simple utility function to disconnect all connections in a table and then clear the table.
--]]

local function disconnectAndClear(connections: { RBXScriptConnection })
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
end

return disconnectAndClear
