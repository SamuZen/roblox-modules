local Folder = {}
Folder.__index = Folder

export type FolderAttributes = {
    Parent: Instance?,
    Name: string?,
}

function Folder.create(attributes: FolderAttributes): Folder
    local instance = Instance.new("Folder")
    for key, value in attributes do
        instance[key] = value
    end
    warn(attributes)
    return instance
end

function Folder.createNew(attributes:FolderAttributes): Folder
    local folder = attributes.Parent:FindFirstChild(attributes.Name)
    if folder ~= nil then
        folder:Destroy()
    end
    return Folder.create(attributes)
end

function Folder.getOrCreate(attributes: FolderAttributes): Folder
    if attributes.Parent == nil then
        error("Folder.getOrCreate needs Parent")
    end
    local folder = attributes.Parent:FindFirstChild(attributes.Name)
    if folder == nil then
        folder = Folder.create(attributes)
    end
    return folder
end

return Folder