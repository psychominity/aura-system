--!strict

--[[ CameraControl.lua ]]
-- プレイヤーのカメラ視点を制御するクライアントサイドスクリプト

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local function setupCamera()
    if not player.Character then return end

    -- カメラタイプを「追従」に設定し、プレイヤーキャラクターを追尾させます。
    -- これにより、アバターの背後からの三人称視点になります。
    camera.CameraType = Enum.CameraType.Follow
    camera.CameraSubject = player.Character.Humanoid

    -- ズーム距離を調整して、アバターの全身が見えるようにします。
    -- これらの値はゲームのスケールに合わせて調整してください。
    -- CameraMinZoomDistanceとCameraMaxZoomDistanceはPlayerオブジェクトのプロパティです。
    player.CameraMinZoomDistance = 5 -- 最小ズーム距離
    player.CameraMaxZoomDistance = 15 -- 最大ズーム距離

    print("Camera setup to Follow mode for " .. player.Name)
end

-- プレイヤーがゲームに参加した際、またはキャラクターがリスポーンした際にカメラを設定
player.CharacterAdded:Connect(setupCamera)

-- スクリプトがロードされた時点で既にキャラクターが存在する場合に備えて初期設定
if player.Character then
    setupCamera()
end

print("CameraControl loaded.")
