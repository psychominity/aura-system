--!strict

--[[ AuraSkillManager.lua ]]
-- サーバーサイドでオーラとスキルのロジックを管理するスクリプト

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local RaidManager = require(script.Parent:WaitForChild("RaidManager")) -- Assuming RaidManager is in the same ServerScriptService

-- RemoteEvents & RemoteFunctions
local ActivateSkillEvent = ReplicatedStorage:WaitForChild("ActivateSkillEvent")
local GetAuraDataFunction = ReplicatedStorage:WaitForChild("GetAuraDataFunction")
local GachaEvent = ReplicatedStorage:WaitForChild("GachaEvent")
local EquipSkillEvent = ReplicatedStorage:WaitForChild("EquipSkillEvent")
local GetPlayerStatsFunction = ReplicatedStorage:WaitForChild("GetPlayerStatsFunction")
local GetEquippedSkillsFunction = ReplicatedStorage:WaitForChild("GetEquippedSkillsFunction")

-- Configuration for Skills
local SKILL_CONFIG = {
    ["パンチ"] = { Damage = 10, Cooldown = 1, EffectColor = Color3.fromRGB(255, 255, 255) },
    ["キック"] = { Damage = 12, Cooldown = 1.2, EffectColor = Color3.fromRGB(0, 255, 0) },
    ["指から紫のビーム"] = { Damage = 20, Cooldown = 3, EffectColor = Color3.fromRGB(128, 0, 128) },
    ["かめはめ波"] = { Damage = 30, Cooldown = 5, EffectColor = Color3.fromRGB(255, 215, 0) },
    ["龍拳"] = { Damage = 25, Cooldown = 4, EffectColor = Color3.fromRGB(255, 0, 0) },
    ["ベジットソード"] = { Damage = 18, Cooldown = 2.5, EffectColor = Color3.fromRGB(0, 0, 255) },
    ["攻撃自動回避"] = { Damage = 0, Cooldown = 10, EffectColor = Color3.fromRGB(192, 192, 192), IsPassive = true }
}

-- Configuration for Auras
local AURA_CONFIG = {
    -- Rarity: Common (60%), Uncommon (25%), Rare (10%), Epic (4%), Legendary (1%)
    -- SkillSlots: Number of skills that can be equipped with this aura
    ["白"] = { EffectColor = Color3.fromRGB(255, 255, 255), Rarity = "Common", SkillSlots = 1 },
    ["緑"] = { EffectColor = Color3.fromRGB(0, 255, 0), Rarity = "Common", SkillSlots = 1 },
    ["紫"] = { EffectColor = Color3.fromRGB(128, 0, 128), Rarity = "Uncommon", SkillSlots = 2 },
    ["金"] = { EffectColor = Color3.fromRGB(255, 215, 0), Rarity = "Rare", SkillSlots = 2 },
    ["赤"] = { EffectColor = Color3.fromRGB(255, 0, 0), Rarity = "Epic", SkillSlots = 3 },
    ["青"] = { EffectColor = Color3.fromRGB(0, 0, 255), Rarity = "Epic", SkillSlots = 3 },
    ["銀"] = { EffectColor = Color3.fromRGB(192, 192, 192), Rarity = "Legendary", SkillSlots = 4 }
}

local GACHA_COST = 100 -- Cost to pull one gacha
local GACHA_PROBABILITIES = {
    Common = 60, -- 60%
    Uncommon = 25, -- 25%
    Rare = 10, -- 10%
    Epic = 4, -- 4%
    Legendary = 1 -- 1%
}

-- Player Data Storage (Server-side)
-- Example: playerAuraData[player.UserId] = {
--   CurrentAura = "白",
--   EquippedSkills = { [1] = "パンチ", [2] = nil }, -- Indexed by slot number
--   Cooldowns = {},
--   Inventory = { Auras = {"白", "緑"}, Skills = {"パンチ", "キック"} },
--   Stats = { HP = 100, Attack = 10, Defense = 5, Speed = 10 },
--   Currency = 1000
-- }
local playerAuraData = {}

-- Function to initialize player data
local function initializePlayerData(player)
    playerAuraData[player.UserId] = {
        CurrentAura = nil, -- No aura equipped initially
        EquippedSkills = {}, -- Stores skill names by slot index: { [1] = "SkillName", [2] = "AnotherSkill" }
        Cooldowns = {}, -- Stores skill cooldowns: { SkillName = timestamp }
        Inventory = { Auras = {}, Skills = {} }, -- Player's owned auras and skills
        Stats = { HP = 100, Attack = 10, Defense = 5, Speed = 10 }, -- Base stats
        Currency = 500 -- Starting currency for testing
    }
    print("Initialized data for player: " .. player.Name)
end

-- Function to get player's current aura
local function getPlayerCurrentAura(player)
    local data = playerAuraData[player.UserId]
    if data then
        return data.CurrentAura
    end
    return nil
end

-- Function to set player's current aura (e.g., after gacha or equipping)
local function setPlayerCurrentAura(player, auraType)
    local data = playerAuraData[player.UserId]
    if not data or not AURA_CONFIG[auraType] then
        warn(player.Name .. " tried to equip an invalid aura: " .. auraType)
        return false
    end

    -- Check if player owns this aura
    local ownsAura = false
    for _, ownedAura in ipairs(data.Inventory.Auras) do
        if ownedAura == auraType then
            ownsAura = true
            break
        end
    end

    if not ownsAura then
        warn(player.Name .. " does not own aura: " .. auraType)
        return false
    end

    data.CurrentAura = auraType
    -- Clear equipped skills when changing aura, as slot count might change
    data.EquippedSkills = {}
    print(player.Name .. " equipped aura: " .. auraType)
    return true
end

-- Function to equip a skill into a specific slot
local function onEquipSkill(player, skillName, slotIndex)
    local data = playerAuraData[player.UserId]
    if not data or not data.CurrentAura then
        warn(player.Name .. " tried to equip skill without an equipped aura.")
        return false
    end

    local auraConfig = AURA_CONFIG[data.CurrentAura]
    if not auraConfig then
        warn("Invalid aura config for current aura: " .. data.CurrentAura)
        return false
    end

    if slotIndex < 1 or slotIndex > auraConfig.SkillSlots then
        warn(player.Name .. " tried to equip skill in invalid slot: " .. slotIndex .. " for aura: " .. data.CurrentAura)
        return false
    end

    if not SKILL_CONFIG[skillName] then
        warn(player.Name .. " tried to equip an invalid skill: " .. skillName)
        return false
    end

    -- Check if player owns this skill (for now, assume all skills are available if aura is owned)
    -- In a more complex system, skills would also be obtained via gacha or other means
    local ownsSkill = false
    for _, ownedSkill in ipairs(data.Inventory.Skills) do
        if ownedSkill == skillName then
            ownsSkill = true
            break
        end
    end
    -- For now, if player owns the aura, they implicitly own its primary skill. We need to adjust this.
    -- Let's simplify: if the skill is in SKILL_CONFIG, it can be equipped if the player has an aura.
    -- A better system would have a separate skill inventory.
    -- For now, let's assume player has all skills for simplicity of this iteration.
    ownsSkill = true -- TEMPORARY: Assume player owns all skills for now

    if not ownsSkill then
        warn(player.Name .. " does not own skill: " .. skillName)
        return false
    end

    data.EquippedSkills[slotIndex] = skillName
    print(player.Name .. " equipped skill: " .. skillName .. " in slot: " .. slotIndex .. " for aura: " .. data.CurrentAura)
    return true
end

-- Function to handle skill activation
local function onActivateSkill(player, skillName)
    local data = playerAuraData[player.UserId]
    if not data or not data.CurrentAura then
        warn(player.Name .. " tried to activate skill without an equipped aura.")
        return
    end

    local currentAuraType = data.CurrentAura
    local auraConfig = AURA_CONFIG[currentAuraType]
    local skillConfig = SKILL_CONFIG[skillName]

    if not skillConfig then
        warn(player.Name .. " tried to activate an invalid skill: " .. skillName)
        return
    end

    -- Check if the skill is actually equipped in any slot for the current aura
    local isEquipped = false
    for _, equippedSkill in pairs(data.EquippedSkills) do
        if equippedSkill == skillName then
            isEquipped = true
            break
        end
    end

    if not isEquipped then
        warn(player.Name .. " tried to activate unequipped skill: " .. skillName .. " for aura: " .. currentAuraType)
        return
    end

    if data.Cooldowns[skillName] and os.time() < data.Cooldowns[skillName] then
        warn(player.Name .. " tried to activate " .. skillName .. " while on cooldown.")
        return
    end

    -- Apply cooldown
    data.Cooldowns[skillName] = os.time() + skillConfig.Cooldown

    print(player.Name .. " activated skill: " .. skillName .. " with aura: " .. currentAuraType)

    -- --- Skill-specific logic --- --
    local damageAmount = skillConfig.Damage

    if skillName == "パンチ" then
        print("Executing Punch for " .. player.Name)
        RaidManager.dealBossDamage(damageAmount)
    elseif skillName == "キック" then
        print("Executing Kick for " .. player.Name)
        RaidManager.dealBossDamage(damageAmount)
    elseif skillName == "指から紫のビーム" then
        print("Executing Purple Beam for " .. player.Name)
        RaidManager.dealBossDamage(damageAmount)
    elseif skillName == "かめはめ波" then
        print("Executing Kamehameha for " .. player.Name)
        RaidManager.dealBossDamage(damageAmount)
    elseif skillName == "龍拳" then
        print("Executing Dragon Fist for " .. player.Name)
        RaidManager.dealBossDamage(damageAmount)
    elseif skillName == "ベジットソード" then
        print("Executing Vegito Sword for " .. player.Name)
        RaidManager.dealBossDamage(damageAmount)
    elseif skillName == "攻撃自動回避" then
        print("Activating Auto-Dodge for " .. player.Name)
        -- This is a passive skill, so its activation might just be a buff application
    end

    -- Notify clients to play effects
    ActivateSkillEvent:FireClient(player, skillName, currentAuraType, skillConfig.EffectColor)
end

-- Function to handle gacha pull
local function onGachaPull(player)
    local data = playerAuraData[player.UserId]
    if not data then return end

    if data.Currency < GACHA_COST then
        warn(player.Name .. " does not have enough currency for gacha.")
        return "Not enough currency"
    end

    data.Currency = data.Currency - GACHA_COST

    local rand = math.random(1, 100)
    local cumulativeProbability = 0
    local obtainedAura = nil

    for rarity, prob in pairs(GACHA_PROBABILITIES) do
        cumulativeProbability = cumulativeProbability + prob
        if rand <= cumulativeProbability then
            -- Find an aura of this rarity
            local possibleAuras = {}
            for auraType, config in pairs(AURA_CONFIG) do
                if config.Rarity == rarity then
                    table.insert(possibleAuras, auraType)
                end
            end
            if #possibleAuras > 0 then
                obtainedAura = possibleAuras[math.random(1, #possibleAuras)]
                break
            end
        end
    end

    if obtainedAura then
        -- Add to inventory if not already owned
        local alreadyOwned = false
        for _, ownedAura in ipairs(data.Inventory.Auras) do
            if ownedAura == obtainedAura then
                alreadyOwned = true
                break
            end
        end

        if not alreadyOwned then
            table.insert(data.Inventory.Auras, obtainedAura)
            print(player.Name .. " obtained new aura: " .. obtainedAura)
        else
            print(player.Name .. " obtained duplicate aura: " .. obtainedAura)
            -- Optionally, give some compensation for duplicates
        end
        -- For now, add all skills to inventory when an aura is obtained
        for skillName, _ in pairs(SKILL_CONFIG) do
            local skillAlreadyOwned = false
            for _, ownedSkill in ipairs(data.Inventory.Skills) do
                if ownedSkill == skillName then
                    skillAlreadyOwned = true
                    break
                end
            end
            if not skillAlreadyOwned then
                table.insert(data.Inventory.Skills, skillName)
            end
        end
        return obtainedAura
    end
    return "Failed to get aura"
end

-- Function to provide aura data to client (e.g., for UI display)
local function onGetAuraData(player)
    local data = playerAuraData[player.UserId]
    if data then
        local currentAuraConfig = AURA_CONFIG[data.CurrentAura]
        local skillSlots = currentAuraConfig and currentAuraConfig.SkillSlots or 0
        return data.CurrentAura, skillSlots, data.Inventory.Auras, data.Inventory.Skills
    end
    return nil, 0, {}, {}
end

-- Function to provide player stats to client
local function onGetPlayerStats(player)
    local data = playerAuraData[player.UserId]
    if data then
        return data.Stats, data.Currency
    end
    return nil, nil
end

-- Function to provide equipped skills to client
local function onGetEquippedSkills(player)
    local data = playerAuraData[player.UserId]
    if data then
        return data.EquippedSkills
    end
    return {}
end

-- Event Connections
Players.PlayerAdded:Connect(initializePlayerData)
ActivateSkillEvent.OnServerEvent:Connect(onActivateSkill)
GachaEvent.OnServerEvent:Connect(onGachaPull)
EquipSkillEvent.OnServerEvent:Connect(onEquipSkill)
GetAuraDataFunction.OnServerInvoke = onGetAuraData
GetPlayerStatsFunction.OnServerInvoke = onGetPlayerStats
GetEquippedSkillsFunction.OnServerInvoke = onGetEquippedSkills

-- Initial setup for players already in game
for _, player in ipairs(Players:GetPlayers()) do
    initializePlayerData(player)
end

print("AuraSkillManager loaded.")
