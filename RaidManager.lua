--!strict

--[[ RaidManager.lua ]]
-- サーバーサイドでレイドのロジックを管理するスクリプト

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- RemoteEvents & RemoteFunctions
local StartRaidEvent = ReplicatedStorage:WaitForChild("StartRaidEvent")
local UpdateBossHealthEvent = ReplicatedStorage:WaitForChild("UpdateBossHealthEvent")
local RaidResultEvent = ReplicatedStorage:WaitForChild("RaidResultEvent")
local GetRaidDataFunction = ReplicatedStorage:WaitForChild("GetRaidDataFunction")

-- Configuration
local RAID_DURATION = 300 -- 5 minutes in seconds
local MAX_PLAYERS_FOR_RAID = 20

local BOSS_CONFIG = {
    -- Example Boss: Dragon
    ["Dragon"] = {
        Name = "巨大ドラゴン",
        MaxHP = 10000,
        Attack = 50,
        Defense = 20,
        ModelName = "DragonBossModel", -- ServerStorageに配置するボスのモデル名
        Abilities = {"FireBreath", "TailSwipe"},
        Weaknesses = {"Ice", "Thunder"},
    }
}

-- Raid State
local currentRaid = {
    IsActive = false,
    BossType = nil,
    BossModel = nil,
    CurrentBossHP = 0,
    MaxBossHP = 0,
    RaidStartTime = 0,
    TimeRemaining = 0,
    ParticipatingPlayers = {},
    BossAttackCooldown = 0,
    LastBossAttackTime = 0,
}

-- Function to reset raid state
local function resetRaidState()
    currentRaid.IsActive = false
    currentRaid.BossType = nil
    if currentRaid.BossModel then
        currentRaid.BossModel:Destroy()
        currentRaid.BossModel = nil
    end
    currentRaid.CurrentBossHP = 0
    currentRaid.MaxBossHP = 0
    currentRaid.RaidStartTime = 0
    currentRaid.TimeRemaining = 0
    currentRaid.ParticipatingPlayers = {}
    currentRaid.BossAttackCooldown = 0
    currentRaid.LastBossAttackTime = 0
    print("Raid state reset.")
end

-- Function to spawn boss
local function spawnBoss(bossType)
    local config = BOSS_CONFIG[bossType]
    if not config then return nil end

    local bossModel = ServerStorage:FindFirstChild(config.ModelName):Clone()
    if not bossModel then
        warn("Boss model not found in ServerStorage: " .. config.ModelName)
        return nil
    end

    bossModel.Parent = workspace -- Or a specific RaidArea folder
    bossModel:SetPrimaryPartCFrame(CFrame.new(0, 50, 0)) -- Example spawn location

    currentRaid.BossType = bossType
    currentRaid.BossModel = bossModel
    currentRaid.MaxBossHP = config.MaxHP
    currentRaid.CurrentBossHP = config.MaxHP

    -- Setup boss humanoid and health
    local bossHumanoid = bossModel:FindFirstChildOfClass("Humanoid")
    if bossHumanoid then
        bossHumanoid.MaxHealth = config.MaxHP
        bossHumanoid.Health = config.MaxHP
        bossHumanoid.Died:Connect(function()
            if currentRaid.IsActive then
                endRaid(true) -- Boss defeated
            end
        end)
    end

    print("Boss " .. bossType .. " spawned.")
    return bossModel
end

-- Function to start a raid
local function startRaid(bossType)
    if currentRaid.IsActive then
        warn("Raid is already active.")
        return
    end

    resetRaidState()

    local bossModel = spawnBoss(bossType)
    if not bossModel then
        warn("Failed to spawn boss for raid.")
        return
    end

    currentRaid.IsActive = true
    currentRaid.RaidStartTime = os.time()
    currentRaid.TimeRemaining = RAID_DURATION

    -- Notify all players that a raid has started
    for _, player in ipairs(Players:GetPlayers()) do
        StartRaidEvent:FireClient(player, bossType, currentRaid.MaxBossHP, currentRaid.TimeRemaining)
    end
    print("Raid started with boss: " .. bossType)
end

-- Function to end a raid
local function endRaid(isSuccess)
    if not currentRaid.IsActive then return end

    local result = isSuccess and "Success" or "Failure"
    print("Raid ended: " .. result)

    -- Distribute rewards or penalties
    for _, player in ipairs(currentRaid.ParticipatingPlayers) do
        if isSuccess then
            -- Example: give currency
            local playerData = game.ServerScriptService.AuraSkillManager.playerAuraData[player.UserId]
            if playerData then
                playerData.Currency = playerData.Currency + 500 -- Raid clear reward
            end
            RaidResultEvent:FireClient(player, true, "Raid Cleared! Rewards received.")
        else
            RaidResultEvent:FireClient(player, false, "Raid Failed! Better luck next time.")
        end
    end

    resetRaidState()
end

-- Function to handle boss damage (called by AuraSkillManager or other combat scripts)
function dealBossDamage(damageAmount)
    if not currentRaid.IsActive or not currentRaid.BossModel then return end

    local bossHumanoid = currentRaid.BossModel:FindFirstChildOfClass("Humanoid")
    if not bossHumanoid then return end

    -- Damage overall boss HP
    currentRaid.CurrentBossHP = math.max(0, currentRaid.CurrentBossHP - damageAmount)
    bossHumanoid.Health = currentRaid.CurrentBossHP -- Sync humanoid health

    -- Notify clients of health update
    UpdateBossHealthEvent:FireAllClients(currentRaid.CurrentBossHP, currentRaid.MaxBossHP)

    if currentRaid.CurrentBossHP <= 0 then
        endRaid(true)
    end
end

-- Function to handle player joining raid
local function onPlayerJoinedRaid(player)
    if currentRaid.IsActive then
        if not table.find(currentRaid.ParticipatingPlayers, player) then
            table.insert(currentRaid.ParticipatingPlayers, player)
            print(player.Name .. " joined the raid.")
            -- Send current raid status to newly joined player
            StartRaidEvent:FireClient(player, currentRaid.BossType, currentRaid.MaxBossHP, currentRaid.TimeRemaining)
            UpdateBossHealthEvent:FireClient(player, currentRaid.CurrentBossHP, currentRaid.MaxBossHP)
        end
    end
end

-- Function to provide raid data to client
local function onGetRaidData(player)
    if currentRaid.IsActive then
        return currentRaid.IsActive, currentRaid.BossType, currentRaid.CurrentBossHP, currentRaid.MaxBossHP, currentRaid.TimeRemaining
    end
    return false, nil, 0, 0, 0
end

-- Game loop for raid timer and boss AI (simplified)
local function raidGameLoop()
    while true do
        if currentRaid.IsActive then
            local elapsedTime = os.time() - currentRaid.RaidStartTime
            currentRaid.TimeRemaining = RAID_DURATION - elapsedTime

            if currentRaid.TimeRemaining <= 0 then
                endRaid(false) -- Time ran out
            end

            -- Boss AI (simplified: periodic attack)
            if os.time() - currentRaid.LastBossAttackTime >= currentRaid.BossAttackCooldown then
                currentRaid.LastBossAttackTime = os.time()
                currentRaid.BossAttackCooldown = math.random(5, 10) -- Attack every 5-10 seconds
                -- Perform boss attack (e.g., damage random player in raid area)
                if #currentRaid.ParticipatingPlayers > 0 then
                    local targetPlayer = currentRaid.ParticipatingPlayers[math.random(1, #currentRaid.ParticipatingPlayers)]
                    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChildOfClass("Humanoid") then
                        local damage = BOSS_CONFIG[currentRaid.BossType].Attack
                        targetPlayer.Character:FindFirstChildOfClass("Humanoid"):TakeDamage(damage)
                        print(currentRaid.BossType .. " attacked " .. targetPlayer.Name .. " for " .. damage .. " damage.")
                    end
                end
            end
        end
        task.wait(1) -- Update every second
    end
end

-- Event Connections
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        onPlayerJoinedRaid(player)
    end)
end)

GetRaidDataFunction.OnServerInvoke = onGetRaidData

-- Start the raid game loop
task.spawn(raidGameLoop)

-- Example: Manually start a raid for testing (can be triggered by a lobby UI later)
-- task.wait(10) -- Wait a bit after server starts
-- startRaid("Dragon")

print("RaidManager loaded.")
