--[[
	loadModules - A utility function to load all module scripts in an instance into a dictionary,
	using the module script names as the keys.
--]]

local function loadModules(source: Instance)
	local modules = {}

	for _, module in source:GetChildren() do
		if not module:IsA("ModuleScript") then
			continue
		end
		modules[module.Name] = require(module)
	end

	return modules
end

return loadModules
