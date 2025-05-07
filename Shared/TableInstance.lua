local TableInstance = {}


function TableInstance.TableFromInstance(instance: Instance): {}
	local result = {}
	if instance == nil then return result end
	-- Coleta os atributos do objeto atual
	local attributes = instance:GetAttributes()
	for key, value in pairs(attributes) do
		result[key] = value
	end

	-- Percorre os filhos do tipo Folder
	for _, child in ipairs(instance:GetChildren()) do
		if child:IsA("Folder") then
			result[child.Name] = TableInstance.TableFromInstance(child)
		end
	end

	return result
end

return TableInstance
