--!strict

--[[ EquipSkillUI.lua ]]
-- 技装備UIの表示と操作を管理するクライアントサイドスクリプト

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- RemoteEvents & RemoteFunctions
local EquipSkillEvent = ReplicatedStorage:WaitForChild("EquipSkillEvent")
local GetAuraDataFunction = ReplicatedStorage:WaitForChild("GetAuraDataFunction")
local GetEquippedSkillsFunction = ReplicatedStorage:WaitForChild("GetEquippedSkillsFunction")

-- UI Elements (These should be created in StarterGui in Roblox Studio)
local PlayerGui = player:WaitForChild("PlayerGui")
local EquipScreen = PlayerGui:WaitForChild("EquipScreen") -- ScreenGui
local EquipFrame = EquipScreen:WaitForChild("EquipFrame") -- Frame

local EquippedAuraText = EquipFrame:WaitForChild("EquippedAuraText") -- TextLabel
local AuraListFrame = EquipFrame:WaitForChild("AuraListFrame") -- ScrollingFrame to hold aura buttons
local AuraButtonTemplate = AuraListFrame:WaitForChild("AuraButtonTemplate") -- TextButton template

local SkillSlotsFrame = EquipFrame:WaitForChild("SkillSlotsFrame") -- Frame to hold skill slot buttons
local SkillSlotButtonTemplate = SkillSlotsFrame:WaitForChild("SkillSlotButtonTemplate") -- TextButton template for skill slots

local AvailableSkillsFrame = EquipFrame:WaitForChild("AvailableSkillsFrame") -- ScrollingFrame to hold available skill buttons
local AvailableSkillButtonTemplate = AvailableSkillsFrame:WaitForChild("AvailableSkillButtonTemplate") -- TextButton template for available skills

AuraButtonTemplate.Visible = false -- Hide the template
SkillSlotButtonTemplate.Visible = false -- Hide the template
AvailableSkillButtonTemplate.Visible = false -- Hide the template

local currentSelectedSkillToEquip = nil

-- Function to update the list of owned auras, equipped aura display, skill slots, and available skills
local function updateEquipUI()
    -- Clear existing aura buttons
    for _, child in ipairs(AuraListFrame:GetChildren()) do
        if child:IsA("TextButton") and child ~= AuraButtonTemplate then
            child:Destroy()
        end
    end

    -- Clear existing skill slot buttons
    for _, child in ipairs(SkillSlotsFrame:GetChildren()) do
        if child:IsA("TextButton") and child ~= SkillSlotButtonTemplate then
            child:Destroy()
        end
    end

    -- Clear existing available skill buttons
    for _, child in ipairs(AvailableSkillsFrame:GetChildren()) do
        if child:IsA("TextButton") and child ~= AvailableSkillButtonTemplate then
            child:Destroy()
        end
    end

    local currentAura, skillSlotsCount, inventoryAuras, inventorySkills = GetAuraDataFunction:InvokeServer()
    local equippedSkills = GetEquippedSkillsFunction:InvokeServer()

    if currentAura then
        EquippedAuraText.Text = "装備中のオーラ: " .. currentAura .. " (スロット: " .. skillSlotsCount .. ")"
    else
        EquippedAuraText.Text = "装備中のオーラ: なし"
    end

    -- Populate Aura List
    for _, auraType in ipairs(inventoryAuras) do
        local auraButton = AuraButtonTemplate:Clone()
        auraButton.Name = auraType .. "Button"
        auraButton.Text = auraType .. "オーラ"
        auraButton.Visible = true
        auraButton.Parent = AuraListFrame

        auraButton.MouseButton1Click:Connect(function()
            EquipSkillEvent:FireServer(auraType, nil, nil) -- Equip Aura
            updateEquipUI() -- Refresh UI after equipping
        end)
    end

    -- Populate Skill Slots
    for i = 1, skillSlotsCount do
        local slotButton = SkillSlotButtonTemplate:Clone()
        slotButton.Name = "SkillSlot" .. i .. "Button"
        slotButton.Text = (equippedSkills[i] and equippedSkills[i]) or "空きスロット"
        slotButton.Visible = true
        slotButton.Parent = SkillSlotsFrame

        local slotIndex = i
        slotButton.MouseButton1Click:Connect(function()
            if currentSelectedSkillToEquip then
                EquipSkillEvent:FireServer(currentAura, currentSelectedSkillToEquip, slotIndex)
                currentSelectedSkillToEquip = nil -- Clear selection
                updateEquipUI()
            else
                print("Slot " .. slotIndex .. " clicked. No skill selected to equip.")
            end
        end)
    end

    -- Populate Available Skills
    for _, skillName in ipairs(inventorySkills) do
        local skillButton = AvailableSkillButtonTemplate:Clone()
        skillButton.Name = skillName .. "Button"
        skillButton.Text = skillName
        skillButton.Visible = true
        skillButton.Parent = AvailableSkillsFrame

        skillButton.MouseButton1Click:Connect(function()
            currentSelectedSkillToEquip = skillName
            print("Selected skill to equip: " .. skillName)
            -- Optionally, highlight the selected skill button
        end)
    end
end

-- Initial setup
updateEquipUI()
EquipScreen.Enabled = true -- Make sure the UI is visible

print("EquipSkillUI loaded.")
