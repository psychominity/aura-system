--!strict

--[[ ProximityGachaTrigger.lua ]]
-- ProximityPromptがトリガーされたときにガチャUIを表示するイベントをクライアントに送信するスクリプト

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShowGachaUIEvent = ReplicatedStorage:WaitForChild("ShowGachaUIEvent")

local part = script.Parent -- このスクリプトが置かれているPartを想定
local proximityPrompt = part:WaitForChild("ProximityPrompt")

local function onPromptTriggered(player)
    print("ProximityPrompt triggered by " .. player.Name .. ". Showing Gacha UI.")
    ShowGachaUIEvent:FireClient(player, true) -- クライアントにUI表示を要求
end

local function onPromptHidden(player)
    print("ProximityPrompt hidden for " .. player.Name .. ". Hiding Gacha UI.")
    ShowGachaUIEvent:FireClient(player, false) -- クライアントにUI非表示を要求
end

proximityPrompt.Triggered:Connect(onPromptTriggered)

-- プレイヤーがProximityPromptの範囲外に出たときにUIを非表示にするための処理
-- ProximityPromptのMaxActivationDistanceを適切に設定することで、
-- プレイヤーが離れたときに自動的に非表示になるようにできます。
-- または、ProximityPromptのEnabledプロパティを制御するロジックを追加することも可能です。

print("ProximityGachaTrigger loaded.")
