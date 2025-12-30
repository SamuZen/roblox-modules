local Spacer = {}




-- given data:
-- 1 - cframe
-- 2 - amount of entities
-- 3 - spacing between entities
-- space the entities side by side in a line, return a list of cframes
function Spacer.spaceEntities(cframe: CFrame, amount: number, spacing: number)
	local cframes = {}
	
	-- Calcular largura total necessária
	local totalWidth = (amount - 1) * spacing
	
	-- Calcular offset inicial (centralizar)
	local startOffset = -totalWidth / 2
	
	-- Criar CFrame para cada entidade
	for i = 1, amount do
		-- Calcular offset para esta entidade
		local offset = startOffset + ((i - 1) * spacing)
		
		-- Criar CFrame deslocado no eixo X (direita do CFrame original)
		local entityCFrame = cframe * CFrame.new(offset, 0, 0)
		
		table.insert(cframes, entityCFrame)
	end
	
	return cframes
end

return Spacer
