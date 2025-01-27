local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CustomRequire = require(ReplicatedStorage.Source.Modules.CustomRequire)

local Generator = CustomRequire(ServerStorage.Source.Modules.Generation.Linear)
local Folder = require(ReplicatedStorage.Source.Modules.Folder)
local Asset = require(ReplicatedStorage.Source.Modules.Assets)

local newFolder = Folder.getOrCreate({
    Parent = workspace,
    Name = "TestMap",
})
newFolder:ClearAllChildren()

Asset.GetRandomNameOnPath(`Levels`)

local data = {
    {angle = 0, prefab = ReplicatedStorage.Start},
    {angle = 0, prefab = Asset.GetRandomOnPath(`Levels.Forest.Start`)},
    {angle = 0, prefab = Asset.GetRandomOnPath(`Levels.Forest.Middle`)},
    {angle = 0, prefab = Asset.GetRandomOnPath(`Levels.Forest.Middle`)},
    {angle = 0, prefab = Asset.GetRandomOnPath(`Levels.Forest.Middle`)},
    {angle = 0, prefab = Asset.GetRandomOnPath(`Levels.Forest.Middle`)},
    {angle = 0, prefab = Asset.GetRandomOnPath(`Levels.Forest.End`)},
    {angle = 0, prefab = Asset.GetRandomOnPath(`Levels.Dungeon`)},
    {angle = 0, prefab = Asset.GetRandomOnPath(`Levels.Dungeon`)},
    {angle = 0, prefab = Asset.GetRandomOnPath(`Levels.Dungeon`)},
    {angle = 0, prefab = Asset.GetRandomOnPath(`Levels.Dungeon`)},
    {angle = 0, prefab = Asset.GetRandomOnPath(`Levels.Dungeon`)},
}

local cframe = workspace:FindFirstChild("LobbyFinish", true).CFrame
Generator.assemble(data, cframe, newFolder)