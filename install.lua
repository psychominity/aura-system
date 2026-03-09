-- Aura / Gacha / Raid FULL Installer

print("Aura System Installer Starting...")

local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local SPS = game:GetService("StarterPlayer").StarterPlayerScripts
local SG = game:GetService("StarterGui")

--------------------------------------------------
-- Utility
--------------------------------------------------

local function new(class,name,parent)
	local i = Instance.new(class)
	i.Name = name
	i.Parent = parent
	return i
end

local function createScript(parent,class,name,source)
	local s = Instance.new(class)
	s.Name = name
	s.Source = source
	s.Parent = parent
end

local function download(url)
	return game:HttpGet(url)
end

--------------------------------------------------
-- RemoteEvents
--------------------------------------------------

local events = {
"ActivateSkillEvent",
"GachaEvent",
"EquipSkillEvent",
"StartRaidEvent",
"UpdateBossHealthEvent",
"RaidResultEvent",
"ShowGachaUIEvent"
}

for _,v in ipairs(events) do
	if not RS:FindFirstChild(v) then
		new("RemoteEvent",v,RS)
	end
end

--------------------------------------------------
-- RemoteFunctions
--------------------------------------------------

local funcs = {
"GetAuraDataFunction",
"GetPlayerStatsFunction",
"GetRaidDataFunction",
"GetEquippedSkillsFunction"
}

for _,v in ipairs(funcs) do
	if not RS:FindFirstChild(v) then
		new("RemoteFunction",v,RS)
	end
end

--------------------------------------------------
-- Aura Folder
--------------------------------------------------

if not RS:FindFirstChild("Aura") then
	new("Folder","Aura",RS)
end

--------------------------------------------------
-- DOWNLOAD URL BASE
--------------------------------------------------

local BASE =
"https://raw.githubusercontent.com/YOURNAME/aura-system/main/"

--------------------------------------------------
-- SERVER SCRIPTS
--------------------------------------------------

print("Installing server scripts...")

createScript(
	SSS,
	"Script",
	"RaidManager",
	download(BASE.."RaidManager.lua")
)

createScript(
	SSS,
	"Script",
	"AuraSkillManager",
	download(BASE.."AuraSkillManager.lua")
)

--------------------------------------------------
-- CLIENT SCRIPTS
--------------------------------------------------

print("Installing client scripts...")

createScript(
	SPS,
	"LocalScript",
	"ProximityGachaTrigger",
	download(BASE.."ProximityGachaTrigger.lua")
)

createScript(
	SPS,
	"LocalScript",
	"ClientAuraSkillHandler",
	download(BASE.."ClientAuraSkillHandler.lua")
)

createScript(
	SPS,
	"LocalScript",
	"SkillEffectsClient",
	download(BASE.."SkillEffectsClient.lua")
)

createScript(
	SPS,
	"LocalScript",
	"CameraControl",
	download(BASE.."CameraControl.lua")
)

--------------------------------------------------
-- UI
--------------------------------------------------

print("Installing UI...")

local ui = new("ScreenGui","AuraGameUI",SG)

createScript(
	ui,
	"LocalScript",
	"GachaUI",
	download(BASE.."GachaUI.lua")
)

createScript(
	ui,
	"LocalScript",
	"RaidUI",
	download(BASE.."RaidUI.lua")
)

createScript(
	ui,
	"LocalScript",
	"StatusUI",
	download(BASE.."StatusUI.lua")
)

createScript(
	ui,
	"LocalScript",
	"EquipSkillUI",
	download(BASE.."EquipSkillUI.lua")
)

--------------------------------------------------
-- NPC Gacha Trigger (auto create)
--------------------------------------------------

print("Creating Gacha NPC...")

local npc = Instance.new("Part")
npc.Name = "GachaNPC"
npc.Size = Vector3.new(4,6,4)
npc.Position = Vector3.new(0,5,0)
npc.Anchored = true
npc.Parent = workspace

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "ガチャを引く"
prompt.ObjectText = "Gacha"
prompt.Parent = npc

--------------------------------------------------
-- RAID BOSS SPAWN POINT
--------------------------------------------------

print("Creating Raid Spawn...")

local raidSpawn = Instance.new("Part")
raidSpawn.Name = "RaidSpawn"
raidSpawn.Size = Vector3.new(10,1,10)
raidSpawn.Position = Vector3.new(50,1,0)
raidSpawn.Anchored = true
raidSpawn.Parent = workspace

--------------------------------------------------

print("Aura / Gacha / Raid System Installed Successfully!")