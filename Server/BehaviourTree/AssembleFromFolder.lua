local function identifyNodeType(folder)
    --[[ Remove o número inicial e extrai o prefixo do nome do folder ]]
    local nameWithoutNumber = folder.Name:gsub("^%d+_", "") -- Remove números seguidos de "_"
    local nodeType = nameWithoutNumber:match("^(%w+)_")

    --[[ Define os tipos conhecidos ]]
    local validTypes = {
        Selector = "selector",
        Sequence = "sequence",
        Parallel = "parallel",
        Decorator = "decorator",
        Action = "action",
        Condition = "condition"
    }

    --[[ Retorna o tipo identificado ou 'unknown' se não for válido ]]
    return validTypes[nodeType] or "unknown"
end

local function extractOrder(name)
    --[[ Extrai o número inicial do nome da pasta (caso exista) ]]
    return tonumber(name:match("^(%d+)")) or math.huge
end

--[[ Função para extrair os meta-dados de uma pasta ]]
local function extractMetadata(folder)
    return folder:GetAttributes()
end

local function buildBehaviourTree(parentFolder)
    --[[ Cria o nó raiz da árvore de comportamento ]]
    local rootNode = {
        name = parentFolder.Name,
        type = identifyNodeType(parentFolder),
        attributes = extractMetadata(parentFolder),
        children = {}
    }

    --[[ Coleta todos os filhos que são folders ]]
    local subfolders = {}

    --[[ Percorre todos os filhos do folder pai ]]
    for _, child in ipairs(parentFolder:GetChildren()) do
        --[[ Verifica se o filho é um folder ]]
        if child:IsA("Folder") then
            --[[ Adiciona o folder na tabela junto com sua numeração ]]
            table.insert(subfolders, {order = extractOrder(child.Name), folder = child})
        end
    end

    --[[ Ordena os subfolders pela numeração extraída ]]
    table.sort(subfolders, function(a, b)
        return a.order < b.order
    end)

    --[[ Cria os nós filhos em ordem correta ]]
    for _, entry in ipairs(subfolders) do
        local childNode = buildBehaviourTree(entry.folder)
        table.insert(rootNode.children, childNode)
    end

    --[[ Retorna o nó da árvore de comportamento ]]
    return rootNode
end

--[[ Função para exibir a árvore de comportamento ]]
local function printBehaviourTree(node, indent)
    indent = indent or ""

    --[[ Exibe o nome e o tipo do nó ]]
    print(indent .. node.type:upper() .. ": " .. node.name)

    --[[ Chama recursivamente para os filhos ]]
    for _, child in ipairs(node.children) do
        printBehaviourTree(child, indent .. "  ")
    end
end

--[[ Exemplo de uso ]]
--[[ Constrói a árvore de comportamento a partir do folder raiz ]]
--local behaviourTree = buildBehaviourTree(game.Workspace.AI)
--printBehaviourTree(behaviourTree)

return buildBehaviourTree