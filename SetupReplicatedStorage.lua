--!strict

--[[ SetupReplicatedStorage.lua ]]
-- ReplicatedStorageに必要なRemoteEventとRemoteFunction、およびAuraフォルダをセットアップするスクリプト

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function createInstance(className, name, parent)
    if not parent:FindFirstChild(name) then
        local instance = Instance.new(className)
        instance.Name = name
        instance.Parent = parent
        print("Created: " .. name .. " in " .. parent.Name)
    else
        print("Already exists: " .. name .. " in " .. parent.Name)
    end
end

-- RemoteEventsの作成
local eventsToCreate = {
    "ActivateSkillEvent", "GachaEvent", "EquipSkillEvent", 
    "StartRaidEvent", "UpdateBossHealthEvent", "RaidResultEvent",
    "ShowGachaUIEvent" -- 新しく追加
}
for _, name in ipairs(eventsToCreate) do
    createInstance("RemoteEvent", name, ReplicatedStorage)
end

-- RemoteFunctionsの作成
local functionsToCreate = {
    "GetAuraDataFunction", "GetPlayerStatsFunction", "GetRaidDataFunction", "GetEquippedSkillsFunction"
}
for _, name in ipairs(functionsToCreate) do
    createInstance("RemoteFunction", name, ReplicatedStorage)
end

-- Auraフォルダの作成
createInstance("Folder", "Aura", ReplicatedStorage)

print("--- ReplicatedStorageのセットアップが完了しました ---")
