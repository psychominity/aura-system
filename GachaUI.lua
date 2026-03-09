--!strict

--[[ GachaUI.lua ]]
-- ガチャUIの表示と操作を管理するクライアントサイドスクリプト

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- RemoteEvents & RemoteFunctions
local GachaEvent = ReplicatedStorage:WaitForChild("GachaEvent")
local GetPlayerStatsFunction = ReplicatedStorage:WaitForChild("GetPlayerStatsFunction")

-- UI Elements (GachaUIスクリプトの親がGachaScreenなので、script.Parentで参照)
local GachaScreen = script.Parent -- ScreenGui
local GachaFrame = GachaScreen:WaitForChild("GachaFrame") -- Frame
local PullButton = GachaFrame:WaitForChild("PullButton") -- TextButton
local ResultText = GachaFrame:WaitForChild("ResultText") -- TextLabel
local CurrencyText = GachaFrame:WaitForChild("CurrencyText") -- TextLabel

local GACHA_COST = 100 -- Display cost

-- Function to update currency display
local function updateCurrencyDisplay()
    local stats, currency = GetPlayerStatsFunction:InvokeServer()
    if currency then
        CurrencyText.Text = "所持金: " .. currency .. " (1回 " .. GACHA_COST .. ")"
    else
        CurrencyText.Text = "所持金: N/A"
    end
end

-- Function to handle gacha pull button click
local function onPullButtonClicked()
    PullButton.Active = false -- Disable button during pull
    ResultText.Text = "ガチャを引いています..."

    local result = GachaEvent:FireServer()

    if result == "Not enough currency" then
        ResultText.Text = "所持金が足りません！"
    elseif result == "Failed to get aura" then
        ResultText.Text = "ガチャに失敗しました。"
    else
        ResultText.Text = "新しいオーラを獲得しました: " .. result .. "!"
        -- Optionally, trigger a visual effect for the new aura
    end
    updateCurrencyDisplay()
    PullButton.Active = true -- Re-enable button
end

-- Event Connections
PullButton.MouseButton1Click:Connect(onPullButtonClicked)

-- 初期設定: UIは最初は非表示にしておく
GachaScreen.Enabled = false

-- GachaScreenのEnabledプロパティが変更されたときに通貨表示を更新
GachaScreen.Changed:Connect(function(property)
    if property == "Enabled" and GachaScreen.Enabled then
        updateCurrencyDisplay()
    end
end)

print("GachaUI loaded.")
