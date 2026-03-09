--!strict

--[[ SkillEffectsClient.lua ]]
-- クライアントサイドでスキルの視覚効果を処理するスクリプト

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ActivateSkillEvent = ReplicatedStorage:WaitForChild("ActivateSkillEvent")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Function to create a generic particle effect (can be customized per skill)
local function createGenericEffect(position, color, size, lifetime)
    local part = Instance.new("Part")
    part.Shape = Enum.PartType.Ball
    part.Size = Vector3.new(size, size, size)
    part.CFrame = CFrame.new(position)
    part.Material = Enum.Material.Neon
    part.Color = color
    part.CanCollide = false
    part.Anchored = true
    part.Transparency = 0.5
    part.Parent = workspace

    Debris:AddItem(part, lifetime)
end

-- Function to handle skill-specific visual effects
local function playSkillEffect(skillName, auraType, effectColor)
    print("Playing client-side effect for: " .. skillName)

    local effectPosition = rootPart.Position + Vector3.new(0, 2, 0) -- Example position above player

    if skillName == "パンチ" then
        -- Short, quick burst effect
        createGenericEffect(effectPosition + rootPart.CFrame.LookVector * 2, effectColor, 1, 0.3)
    elseif skillName == "キック" then
        -- Slightly larger, sweeping effect
        createGenericEffect(effectPosition + rootPart.CFrame.RightVector * 2, effectColor, 1.5, 0.4)
    elseif skillName == "指から紫のビーム" then
        -- Create a beam visual (example: using a Part or Beam object)
        local beamPart = Instance.new("Part")
        beamPart.Size = Vector3.new(0.5, 0.5, 10) -- Thin, long part
        beamPart.CFrame = rootPart.CFrame * CFrame.new(0, 0, -5) -- In front of player
        beamPart.Material = Enum.Material.Neon
        beamPart.Color = effectColor
        beamPart.CanCollide = false
        beamPart.Anchored = true
        beamPart.Parent = workspace
        Debris:AddItem(beamPart, 1) -- Beam lasts 1 second
    elseif skillName == "かめはめ波" then
        -- Large, expanding sphere effect
        local sphere = Instance.new("Part")
        sphere.Shape = Enum.PartType.Ball
        sphere.Size = Vector3.new(2, 2, 2)
        sphere.CFrame = rootPart.CFrame * CFrame.new(0, 0, -3)
        sphere.Material = Enum.Material.Neon
        sphere.Color = effectColor
        sphere.CanCollide = false
        sphere.Anchored = true
        sphere.Parent = workspace
        Debris:AddItem(sphere, 2)

        -- Animate expansion
        local tweenService = game:GetService("TweenService")
        local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0)
        local goal = { Size = Vector3.new(10, 10, 10), Transparency = 1 }
        local tween = tweenService:Create(sphere, tweenInfo, goal)
        tween:Play()
    elseif skillName == "龍拳" then
        -- Fast forward dash effect with trail
        local trailPart = Instance.new("Part")
        trailPart.Size = Vector3.new(1, 1, 1)
        trailPart.CFrame = rootPart.CFrame
        trailPart.Material = Enum.Material.Neon
        trailPart.Color = effectColor
        trailPart.CanCollide = false
        trailPart.Anchored = false
        trailPart.Parent = workspace
        Debris:AddItem(trailPart, 0.5)

        local attachment0 = Instance.new("Attachment")
        attachment0.Parent = trailPart
        local attachment1 = Instance.new("Attachment")
        attachment1.Parent = trailPart
        attachment1.Position = Vector3.new(0, 0, -1) -- Offset for trail

        local trail = Instance.new("Trail")
        trail.Attachment0 = attachment0
        trail.Attachment1 = attachment1
        trail.Color = ColorSequence.new(effectColor, effectColor)
        trail.Lifetime = 0.5
        trail.Transparency = NumberSequence.new(0, 1)
        trail.WidthScale = NumberSequence.new(1, 0)
        trail.Parent = trailPart

        -- Simple forward movement for demonstration
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bodyVelocity.Velocity = rootPart.CFrame.LookVector * 50
        bodyVelocity.Parent = trailPart
        Debris:AddItem(bodyVelocity, 0.5)

    elseif skillName == "ベジットソード" then
        -- Create a glowing sword effect attached to player's hand (requires character rig knowledge)
        -- For simplicity, a temporary glowing part near the player
        local swordPart = Instance.new("Part")
        swordPart.Size = Vector3.new(0.3, 0.3, 3)
        swordPart.CFrame = rootPart.CFrame * CFrame.new(1, 0, -1) * CFrame.Angles(0, math.rad(90), 0) -- Example position/orientation
        swordPart.Material = Enum.Material.Neon
        swordPart.Color = effectColor
        swordPart.CanCollide = false
        swordPart.Anchored = true
        swordPart.Parent = workspace
        Debris:AddItem(swordPart, 1.5)
    elseif skillName == "攻撃自動回避" then
        -- Temporary visual buff (e.g., faint silver glow around player)
        local highlight = Instance.new("Highlight")
        highlight.FillColor = effectColor
        highlight.FillTransparency = 0.7
        highlight.OutlineColor = effectColor
        highlight.OutlineTransparency = 0.5
        highlight.Parent = character
        Debris:AddItem(highlight, 2) -- Lasts 2 seconds
    end
end

-- Listen for skill activation events from the server
ActivateSkillEvent.OnClientEvent:Connect(playSkillEffect)

-- Update character and rootPart if player respawns
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    rootPart = newCharacter:WaitForChild("HumanoidRootPart")
end)

print("SkillEffectsClient loaded.")
