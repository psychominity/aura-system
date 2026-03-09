--!strict

--[[ ClientAuraSkillHandler.lua ]]
-- クライアントサイドでオーラエフェクトの表示、スキル発動の入力処理、サーバーへの通知を行うスクリプト

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- RemoteEvents & RemoteFunctions
local ActivateSkillEvent = ReplicatedStorage:WaitForChild("ActivateSkillEvent")
local GetAuraDataFunction = ReplicatedStorage:WaitForChild("GetAuraDataFunction")
local GachaEvent = ReplicatedStorage:WaitForChild("GachaEvent")
local EquipSkillEvent = ReplicatedStorage:WaitForChild("EquipSkillEvent")
local GetPlayerStatsFunction = ReplicatedStorage:WaitForChild("GetPlayerStatsFunction")
local GetEquippedSkillsFunction = ReplicatedStorage:WaitForChild("GetEquippedSkillsFunction")
local StartRaidEvent = ReplicatedStorage:WaitForChild("StartRaidEvent")
local UpdateBossHealthEvent = ReplicatedStorage:WaitForChild("UpdateBossHealthEvent")
local RaidResultEvent = ReplicatedStorage:WaitForChild("RaidResultEvent")
local ShowGachaUIEvent = ReplicatedStorage:WaitForChild("ShowGachaUIEvent") -- 新しく追加
local GetRaidDataFunction = ReplicatedStorage:WaitForChild("GetRaidDataFunction")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local currentAuraEffect = nil
local currentEquippedAura = nil
local equippedSkills = {} -- { [slotIndex] = "SkillName" }
local playerInventoryAuras = {}
local playerInventorySkills = {}
local playerStats = {}
local playerCurrency = 0
local currentAuraSkillSlots = 0

local currentRaidStatus = {
    IsActive = false,
    BossType = nil,
    CurrentBossHP = 0,
    MaxBossHP = 0,
    TimeRemaining = 0,
}

-- Function to create and display aura effect
local function createAuraEffect(color)
    if currentAuraEffect then
        currentAuraEffect:Destroy()
    end

    local attachment = Instance.new("Attachment")
    attachment.Parent = rootPart

    local particleEmitter = Instance.new("ParticleEmitter")
    particleEmitter.Parent = attachment
    particleEmitter.Color = ColorSequence.new(color)
    particleEmitter.Size = NumberSequence.new(0.5, 2)
    particleEmitter.Transparency = NumberSequence.new(0, 0.7)
    particleEmitter.Lifetime = 1
    particleEmitter.Rate = 50
    particleEmitter.Speed = 1
    particleEmitter.SpreadAngle = Vector2.new(360, 360)
    particleEmitter.LightEmission = 1
    particleEmitter.Texture = "rbxassetid://215103403" -- Example particle texture
    particleEmitter.Enabled = true

    currentAuraEffect = particleEmitter
end

-- Function to remove aura effect
local function removeAuraEffect()
    if currentAuraEffect then
        currentAuraEffect:Destroy()
        currentAuraEffect = nil
    end
end

-- Function to handle skill activation from server
local function onSkillActivated(skillName, auraType, effectColor)
    print("Client received skill activation: " .. skillName .. " with aura: " .. auraType)
    -- Play client-side effects/animations for the skill
    -- For example, if it's a beam, create the beam visual here.
    -- For now, we'll just print and ensure aura effect is correct.
    createAuraEffect(effectColor)
end

-- Function to handle raid start event
local function onRaidStarted(bossType, maxHP, timeRemaining)
    print("Raid Started! Boss: " .. bossType .. ", Max HP: " .. maxHP .. ", Time: " .. timeRemaining .. "s")
    currentRaidStatus.IsActive = true
    currentRaidStatus.BossType = bossType
    currentRaidStatus.MaxBossHP = maxHP
    currentRaidStatus.CurrentBossHP = maxHP
    currentRaidStatus.TimeRemaining = timeRemaining
    -- Update UI to show raid information
end

-- Function to handle boss health update event
local function onBossHealthUpdated(currentHP, maxHP)
    print("Boss Health Updated: " .. currentHP .. "/" .. maxHP)
    currentRaidStatus.CurrentBossHP = currentHP
    currentRaidStatus.MaxBossHP = maxHP
    -- Update UI to show boss health
end

-- Function to handle raid result event
local function onRaidResult(isSuccess, message)
    print("Raid Result: " .. (isSuccess and "Success" or "Failure") .. ", Message: " .. message)
    currentRaidStatus.IsActive = false
    -- Update UI to show raid result and hide raid info
end

-- Function to request raid data from server and update client
local function updateRaidData()
    local isActive, bossType, currentHP, maxHP, timeRemaining = GetRaidDataFunction:InvokeServer()
    currentRaidStatus.IsActive = isActive
    currentRaidStatus.BossType = bossType
    currentRaidStatus.CurrentBossHP = currentHP
    currentRaidStatus.MaxBossHP = maxHP
    currentRaidStatus.TimeRemaining = timeRemaining
    if isActive then
        print("Client received current raid status: Boss " .. bossType .. ", HP: " .. currentHP .. "/" .. maxHP)
    else
        print("Client received no active raid.")
    end
    -- Update UI for raid status here
end

-- Function to request aura data from server and update client
local function updateAuraData()
    local auraType, skillSlots, inventoryAuras, inventorySkills = GetAuraDataFunction:InvokeServer()
    if auraType then
        print("Client received current aura: " .. auraType)
        currentEquippedAura = auraType
        currentAuraSkillSlots = skillSlots
        playerInventoryAuras = inventoryAuras
        playerInventorySkills = inventorySkills
        local auraConfig = game.ServerScriptService.AuraSkillManager.AURA_CONFIG[auraType] -- Access server config for color
        if auraConfig then
            createAuraEffect(auraConfig.EffectColor)
        end
    else
        print("Client has no aura equipped.")
        removeAuraEffect()
        currentEquippedAura = nil
        currentAuraSkillSlots = 0
        playerInventoryAuras = inventoryAuras
        playerInventorySkills = inventorySkills
    end
    -- Update UI for equipped skills and inventory here
    print("Player Aura Inventory: ", playerInventoryAuras)
    print("Player Skill Inventory: ", playerInventorySkills)
end

-- Function to request equipped skills from server and update client
local function updateEquippedSkills()
    equippedSkills = GetEquippedSkillsFunction:InvokeServer()
    print("Client received equipped skills: ", equippedSkills)
    -- Update UI for equipped skills here
end

-- Function to request player stats from server and update client
local function updatePlayerStats()
    local stats, currency = GetPlayerStatsFunction:InvokeServer()
    if stats and currency then
        playerStats = stats
        playerCurrency = currency
        print("Player Stats: ", playerStats)
        print("Player Currency: ", playerCurrency)
    end
    -- Update UI for stats and currency here
end

-- Function to handle equip aura request
local function requestEquipAura(auraType)
    print("Requesting to equip aura: " .. auraType)
    local success = EquipSkillEvent:FireServer(auraType, nil) -- skillName and slotIndex are nil for aura equip
    if success then
        print("Successfully equipped aura: " .. auraType)
        updateAuraData() -- Refresh equipped aura and skill slots
        updateEquippedSkills() -- Refresh equipped skills (they would be cleared on server)
    else
        warn("Failed to equip aura: " .. auraType)
    end
end

-- Function to handle equip skill into slot request
local function requestEquipSkillInSlot(skillName, slotIndex)
    print("Requesting to equip skill: " .. skillName .. " into slot: " .. slotIndex)
    local success = EquipSkillEvent:FireServer(currentEquippedAura, skillName, slotIndex)
    if success then
        print("Successfully equipped skill: " .. skillName .. " in slot: " .. slotIndex)
        updateEquippedSkills() -- Refresh equipped skills
    else
        warn("Failed to equip skill: " .. skillName .. " in slot: " .. slotIndex)
    end
end

-- Input handling for skill activation (example: pressing '1', '2', '3', '4' keys for slots)
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end

    local slotKeyMap = {
        [Enum.KeyCode.One] = 1,
        [Enum.KeyCode.Two] = 2,
        [Enum.KeyCode.Three] = 3,
        [Enum.KeyCode.Four] = 4,
    }

    local slotIndex = slotKeyMap[input.KeyCode]
    if slotIndex and equippedSkills[slotIndex] then
        ActivateSkillEvent:FireServer(equippedSkills[slotIndex])
        print("Client requested skill activation for slot " .. slotIndex .. ": " .. equippedSkills[slotIndex])

    elseif input.KeyCode == Enum.KeyCode.E then -- Example key for equipping first aura in inventory
        if #playerInventoryAuras > 0 then
            requestEquipAura(playerInventoryAuras[1])
        else
            warn("No auras in inventory to equip.")
        end
    end
end)

-- Initial data fetch and effect setup
character.ChildAdded:Connect(function(child)
    if child:IsA("HumanoidRootPart") then
        rootPart = child
        updateAuraData()
        updatePlayerStats()
        updateEquippedSkills()
        updateRaidData()
    end
end)

player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = newCharacter:WaitForChild("Humanoid")
    rootPart = newCharacter:WaitForChild("HumanoidRootPart")
    updateAuraData()
    updatePlayerStats()
    updateEquippedSkills()
    updateRaidData()
end)

ActivateSkillEvent.OnClientEvent:Connect(onSkillActivated)
StartRaidEvent.OnClientEvent:Connect(onRaidStarted)
UpdateBossHealthEvent.OnClientEvent:Connect(onBossHealthUpdated)
RaidResultEvent.OnClientEvent:Connect(onRaidResult)

-- Initial call to set up aura if character already loaded
if character and rootPart then
    updateAuraData()
    updatePlayerStats()
    updateEquippedSkills()
    updateRaidData()
end

-- ShowGachaUIEventのリスナーを設定
ShowGachaUIEvent.OnClientEvent:Connect(function(shouldShow)
    local PlayerGui = player:WaitForChild("PlayerGui")
    local GachaScreen = PlayerGui:FindFirstChild("GachaScreen")
    if GachaScreen then
        GachaScreen.Enabled = shouldShow
        if shouldShow then
            print("Gacha UI shown.")
            -- UIが表示されるときに通貨情報を更新
            -- GachaUIスクリプトがGachaScreen.Enabledの変化を監視するように変更済みなので、ここでは何もしない
        else
            print("Gacha UI hidden.")
        end
    end
end)

print("ClientAuraSkillHandler loaded.")
