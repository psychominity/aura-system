--!strict

--[[ StatusUI.lua ]]
-- プレイヤーのステータス表示を管理するクライアントサイドスクリプト

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- RemoteFunctions
local GetPlayerStatsFunction = ReplicatedStorage:WaitForChild("GetPlayerStatsFunction")

-- UI Elements (These should be created in StarterGui in Roblox Studio)
local PlayerGui = player:WaitForChild("PlayerGui")
local StatusScreen = PlayerGui:WaitForChild("StatusScreen") -- ScreenGui
local StatusFrame = StatusScreen:WaitForChild("StatusFrame") -- Frame
local HPText = StatusFrame:WaitForChild("HPText") -- TextLabel
local AttackText = StatusFrame:WaitForChild("AttackText") -- TextLabel
local DefenseText = StatusFrame:WaitForChild("DefenseText") -- TextLabel
local SpeedText = StatusFrame:WaitForChild("SpeedText") -- TextLabel
local CurrencyText = StatusFrame:WaitForChild("CurrencyText") -- TextLabel

-- Function to update player stats display
local function updateStatsDisplay()
    local stats, currency = GetPlayerStatsFunction:InvokeServer()
    if stats and currency then
        HPText.Text = "HP: " .. stats.HP
        AttackText.Text = "攻撃力: " .. stats.Attack
        DefenseText.Text = "防御力: " .. stats.Defense
        SpeedText.Text = "素早さ: " .. stats.Speed
        CurrencyText.Text = "所持金: " .. currency
    else
        HPText.Text = "HP: N/A"
        AttackText.Text = "攻撃力: N/A"
        DefenseText.Text = "防御力: N/A"
        SpeedText.Text = "素早さ: N/A"
        CurrencyText.Text = "所持金: N/A"
    end
end

-- Initial setup
updateStatsDisplay()
StatusScreen.Enabled = true -- Make sure the UI is visible

print("StatusUI loaded.")
