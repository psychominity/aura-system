--!strict

--[[ RaidUI.lua ]]
-- レイドUIの表示と操作を管理するクライアントサイドスクリプト

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- RemoteEvents & RemoteFunctions
local StartRaidEvent = ReplicatedStorage:WaitForChild("StartRaidEvent")
local UpdateBossHealthEvent = ReplicatedStorage:WaitForChild("UpdateBossHealthEvent")
local RaidResultEvent = ReplicatedStorage:WaitForChild("RaidResultEvent")
local GetRaidDataFunction = ReplicatedStorage:WaitForChild("GetRaidDataFunction")

-- UI Elements (These should be created in StarterGui in Roblox Studio)
local PlayerGui = player:WaitForChild("PlayerGui")
local RaidScreen = PlayerGui:WaitForChild("RaidScreen") -- ScreenGui
local RaidFrame = RaidScreen:WaitForChild("RaidFrame") -- Frame
local BossNameText = RaidFrame:WaitForChild("BossNameText") -- TextLabel
local BossHealthBar = RaidFrame:WaitForChild("BossHealthBar") -- Frame (inner frame for health)
local BossHealthText = RaidFrame:WaitForChild("BossHealthText") -- TextLabel
local TimeRemainingText = RaidFrame:WaitForChild("TimeRemainingText") -- TextLabel
-- local PartStatusFrame = RaidFrame:WaitForChild("PartStatusFrame") -- Frame to show part destruction
-- local PartStatusTemplate = PartStatusFrame:WaitForChild("PartStatusTemplate") -- TextLabel template
local StartRaidButton = RaidFrame:WaitForChild("StartRaidButton") -- TextButton (for testing/lobby)

-- PartStatusTemplate.Visible = false -- Hide the template
RaidFrame.Visible = false -- Hide raid UI initially

local currentRaidStatus = {
    IsActive = false,
    BossType = nil,
    CurrentBossHP = 0,
    MaxBossHP = 0,
    TimeRemaining = 0,
    -- BossParts = {} -- Removed part destruction
}

-- Function to update raid UI display
local function updateRaidUIDisplay()
    if currentRaidStatus.IsActive then
        RaidFrame.Visible = true
        BossNameText.Text = currentRaidStatus.BossType
        BossHealthText.Text = string.format("HP: %d / %d", currentRaidStatus.CurrentBossHP, currentRaidStatus.MaxBossHP)
        BossHealthBar.Size = UDim2.new(currentRaidStatus.CurrentBossHP / currentRaidStatus.MaxBossHP, 0, 1, 0)
        TimeRemainingText.Text = string.format("残り時間: %d秒", math.max(0, math.floor(currentRaidStatus.TimeRemaining)))

        -- Update part status (removed)
        -- for _, child in ipairs(PartStatusFrame:GetChildren()) do
        --     if child:IsA("TextLabel") and child ~= PartStatusTemplate then
        --         child:Destroy()
        --     end
        -- end
        -- for partName, partData in pairs(currentRaidStatus.BossParts) do
        --     local partLabel = PartStatusTemplate:Clone()
        --     partLabel.Name = partName .. "Status"
        --     partLabel.Text = partName .. ": " .. (partData.IsDestroyed and "破壊済み" or "健在")
        --     partLabel.TextColor3 = partData.IsDestroyed and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)
        --     partLabel.Visible = true
        --     partLabel.Parent = PartStatusFrame
        -- end
    else
        RaidFrame.Visible = false
    end
end

-- Function to request raid data from server and update client
local function updateRaidData()
    local isActive, bossType, currentHP, maxHP, timeRemaining = GetRaidDataFunction:InvokeServer()
    currentRaidStatus.IsActive = isActive
    currentRaidStatus.BossType = bossType
    currentRaidStatus.CurrentBossHP = currentHP
    currentRaidStatus.MaxBossHP = maxHP
    currentRaidStatus.TimeRemaining = timeRemaining
    -- currentRaidStatus.BossParts = bossParts -- Removed part destruction
    updateRaidUIDisplay()
end

-- Event Handlers
local function onRaidStarted(bossType, maxHP, timeRemaining)
    print("RaidUI: Raid Started! Boss: " .. bossType)
    currentRaidStatus.IsActive = true
    currentRaidStatus.BossType = bossType
    currentRaidStatus.MaxBossHP = maxHP
    currentRaidStatus.CurrentBossHP = maxHP
    currentRaidStatus.TimeRemaining = timeRemaining
    -- currentRaidStatus.BossParts = {} -- Reset parts, will be updated by UpdateBossHealthEvent -- Removed part destruction
    updateRaidUIDisplay()
end

local function onBossHealthUpdated(currentHP, maxHP)
    print("RaidUI: Boss Health Updated: " .. currentHP .. "/" .. maxHP)
    currentRaidStatus.CurrentBossHP = currentHP
    currentRaidStatus.MaxBossHP = maxHP
    -- currentRaidStatus.BossParts = bossParts -- Removed part destruction
    updateRaidUIDisplay()
end

local function onRaidResult(isSuccess, message)
    print("RaidUI: Raid Result: " .. (isSuccess and "Success" or "Failure") .. ", Message: " .. message)
    currentRaidStatus.IsActive = false
    updateRaidUIDisplay()
    -- Display a temporary message to the player about the result
    -- ResultText.Text = message -- Assuming a ResultText label exists in RaidFrame or elsewhere
    -- task.delay(5, function() ResultText.Text = "" end)
end

local function onStartRaidButtonClicked()
    -- For testing purposes, trigger a raid start from client
    -- In a real game, this would be triggered by entering a specific area or a server event
    StartRaidEvent:FireServer("Dragon") -- Example: Start Dragon raid
    print("RaidUI: Requested to start Dragon raid.")
end

-- Event Connections
StartRaidEvent.OnClientEvent:Connect(onRaidStarted)
UpdateBossHealthEvent.OnClientEvent:Connect(onBossHealthUpdated)
RaidResultEvent.OnClientEvent:Connect(onRaidResult)
StartRaidButton.MouseButton1Click:Connect(onStartRaidButtonClicked)

-- Update raid UI every second if active
RunService.Heartbeat:Connect(function()
    if currentRaidStatus.IsActive then
        currentRaidStatus.TimeRemaining = currentRaidStatus.TimeRemaining - RunService.Heartbeat:Wait()
        updateRaidUIDisplay()
    end
end)

-- Initial data fetch and UI setup
updateRaidData()
RaidScreen.Enabled = true -- Make sure the UI is visible

print("RaidUI loaded.")
