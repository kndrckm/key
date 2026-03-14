-- ==========================================
-- SKENA HUB : Simple Spells (Redesigned)
-- Place ID: 118433033586507
-- ==========================================

local Window = SkenaHub.UI
local Theme = getgenv().SkenaHubTheme

-- 1. Tab: Main (Vibrant Purple)
local MainElements, MainPage, MainLayout = Window:CreateTab("Main", 10747376565, Color3.fromRGB(160, 80, 255))

-- 2. Tab: Teleport (Ocean Blue)
local TeleElements, TelePage, TeleLayout = Window:CreateTab("Teleport", 10734886004, Color3.fromRGB(50, 150, 255))

-- ==========================================
-- SHARED STATE & LOOPS
-- ==========================================
local autoFarmEnabled = false
local isSelling = false
local savedFarmLocations = {nil, nil, nil, nil}
local currentSpotIndex = 1
local autoSellConfig = { cooldown = 60, enabled = true }
local spellStates = {
    ["1"] = { enabled = false, delay = 10 },
    ["2"] = { enabled = false, delay = 10 },
    ["3"] = { enabled = false, delay = 10 },
    ["4"] = { enabled = false, delay = 10 },
}

local function secureRemoteFire(...)
    local remoteNames = {"RemoteEvent_1", "RemoteEvent_2", "RemoteEvent_3", "RemoteEvent_4"}
    for _, name in ipairs(remoteNames) do
        local remote = game:GetService("ReplicatedStorage"):FindFirstChild(name)
        if remote and remote:IsA("RemoteEvent") then
            remote:FireServer(...)
        end
    end
end

-- ==========================================
-- MAIN TAB: FEATURES
-- ==========================================

-- 1. Buy Spell Row
local BuyRowL, BuyRowM, BuyRowR = MainElements:CreateRow(3)
BuyRowL.Size = UDim2.new(0, 171, 1, 0) -- Label slot
BuyRowM.Size = UDim2.new(0, 126, 1, 0) -- Dropdown slot (3 slots + gaps)
BuyRowR.Size = UDim2.new(0, 36, 1, 0)  -- Ghost Button slot

local selectedSpell = "Common [50 Gold]"
local spellMap = {
    ["Common [50 Gold]"] = {ball = "CrystallBall_1"},
    ["Desert [300 Gold]"] = {ball = "CrystallBall_2"},
    ["Forest [3,500 Gold]"] = {ball = "CrystallBall_3"},
    ["Frozen [25,000 Gold]"] = {ball = "CrystallBall_4"},
    ["Volcanic [100,000 Gold]"] = {ball = "CrystallBall_5"},
}

MainElements:CreateLabel("Buy Spell", BuyRowL)
local buyDrop = MainElements:CreateDropdown("Select Spell", nil, function(item)
    selectedSpell = item
end, BuyRowM)

buyDrop:AddItem("Common [50 Gold]", true)
buyDrop:AddItem("Desert [300 Gold]")
buyDrop:AddItem("Forest [3,500 Gold]")
buyDrop:AddItem("Frozen [25,000 Gold]")
buyDrop:AddItem("Volcanic [100,000 Gold]")

MainElements:CreateCircleButton("rbxassetid://10709791437", function()
    local data = spellMap[selectedSpell]
    local ballName = data and data.ball
    local targetBall = ballName and workspace:FindFirstChild(ballName)
    if targetBall then
        secureRemoteFire("BuyCrystalBall", targetBall, 1)
    end
end, BuyRowR, true)

-- ==========================================
-- TELEPORT TAB REDESIGN (3-Column)
-- ==========================================
local zoneData = {
    {"Common", CFrame.new(853.272, 132.774, -114.176)},
    {"Desert", CFrame.new(508.961, 126.700, 135.752)},
    {"Mushroom", CFrame.new(481.551, 238.700, -472.473)},
    {"Frozen", CFrame.new(383.247, 302.700, -567.455)},
    {"Volcanic", CFrame.new(136.528, 302.700, -350.816)}
}

local secretData = {
    {"Ice Arrow", CFrame.new(1060.314, 132.567, -231.072)},
    {"Fire Sword", CFrame.new(869.619, 135.231, -390.111)},
    {"Catalyst", CFrame.new(527.259, 39.619, 493.563)}
}

local function CreateTeleportSection(title, data)
    TeleElements:CreateSection(title)
    
    for i = 1, #data, 3 do
        local cols = {TeleElements:CreateRow(3)}
        for j = 1, 3 do
            local slotIdx = i + (j - 1)
            local item = data[slotIdx]
            local container = cols[j]
            
            if item and container then
                container.Size = UDim2.new(0, 111, 1, 0)
                TeleElements:CreateButton(item[1], function()
                    local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then hrp.CFrame = item[2] end
                end, container)
            end
        end
    end
end

CreateTeleportSection("Zone", zoneData)
CreateTeleportSection("Secret Spell Location", secretData)

-- ==========================================
-- MAIN TAB: AUTO FARM MASTER
-- ==========================================
local MasterRowL, MasterRowR = MainElements:CreateRow(2)
MasterRowL.Size = UDim2.new(0, 216, 1, 0)
MasterRowR.Size = UDim2.new(0, 36, 1, 0)
MainElements:CreateLabel("Auto Farm", MasterRowL)
MainElements:CreateToggle(function(state)
    autoFarmEnabled = state
end, false, MasterRowR)

-- Card: Auto Skills
local SkillCard = Instance.new("Frame")
SkillCard.Size = UDim2.new(1, 0, 0, 180)
SkillCard.BackgroundTransparency = 1
SkillCard.Parent = MainPage

local SkillLayout = Instance.new("UIListLayout", SkillCard)
SkillLayout.Padding = UDim.new(0, Theme.Gap)

for i = 1, 4 do
    local id = tostring(i)
    local data = spellStates[id]
    
    -- Let the library handle the row creation and parenting naturally
    local R1, R2, R3 = MainElements:CreateRow(3) 
    R1.Size = UDim2.new(0, 171, 1, 0)
    R2.Size = UDim2.new(0, 81, 1, 0)
    R3.Size = UDim2.new(0, 36, 1, 0)

    MainElements:CreateLabel("AUTO SKILL " .. id, R1)
    MainElements:CreateTextBox("10", "Delay", "Sec", function(v) data.delay = tonumber(v) or 10 end, R2)
    MainElements:CreateToggle(function(s) data.enabled = s end, false, R3)

    task.spawn(function()
        while true do
            if autoFarmEnabled and data.enabled and not isSelling then
                local char = game.Players.LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local myCF = hrp.CFrame
                    local targetPos = (myCF * CFrame.new(0, 0, -10)).Position
                    secureRemoteFire("UseSpell", id, myCF, targetPos, true)
                end
                task.wait(data.delay)
            end
            task.wait(0.1)
        end
    end)
end

-- ==========================================
-- MAIN TAB: DISCOVERY (ESP)
-- ==========================================
MainElements:CreateSection("Discovery List")

local ESPCard = Instance.new("Frame", MainPage)
ESPCard.Size = UDim2.new(1, 0, 0, 150)
ESPCard.BackgroundTransparency = 1

local R_Sell = {MainElements:CreateRow(3)}
R_Sell[1].Size = UDim2.new(0, 126, 1, 0) -- Adjust to fit
R_Sell[2].Size = UDim2.new(0, 81, 1, 0)
R_Sell[3].Size = UDim2.new(0, 126, 1, 0)

MainElements:CreateLabel("AUTO SELL COOLDOWN", R_Sell[1])
MainElements:CreateTextBox("60", "Seconds", "60", function(v) autoSellConfig.cooldown = tonumber(v) or 60 end, R_Sell[2])
MainElements:CreateToggle("Auto Sell", function(s) autoSellConfig.enabled = s end, R_Sell[3])

-- Spot Management (Row of 4 small buttons)
local SpotRow = {MainElements:CreateRow(4)}
for i = 1, 4 do
    local btn = MainElements:CreateButton("Set Spot " .. i, function()
        local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then 
            savedFarmLocations[i] = hrp.CFrame 
            warn("[Skena] Spot " .. i .. " Saved!")
        end
    end, SpotRow[i])
end

-- ==========================================
-- BACKGROUND LOOPS (Ported from original)
-- ==========================================

-- Master Sell Loop
task.spawn(function()
    while true do
        if autoFarmEnabled and autoSellConfig.enabled then
            local char = game.Players.LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                isSelling = true
                local oldCF = hrp.CFrame
                hrp.CFrame = CFrame.new(935.876, 132.344, -52.726)
                task.wait(5) -- Selling process
                
                -- Rotation logic
                local activeSpots = {}
                for idx, loc in pairs(savedFarmLocations) do if loc then table.insert(activeSpots, idx) end end
                
                if #activeSpots > 0 then
                    local foundNext = false
                    for _, sIdx in ipairs(activeSpots) do
                        if sIdx > currentSpotIndex then currentSpotIndex = sIdx foundNext = true break end
                    end
                    if not foundNext then currentSpotIndex = activeSpots[1] end
                    hrp.CFrame = savedFarmLocations[currentSpotIndex]
                else
                    hrp.CFrame = oldCF
                end
                isSelling = false
            end
            task.wait(autoSellConfig.cooldown)
        end
        task.wait(1)
    end
end)

-- Anti-Void Safety
task.spawn(function()
    while true do
        if autoFarmEnabled then
            local char = game.Players.LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and hrp.Position.Y <= 15 then
                if isSelling then
                    hrp.CFrame = CFrame.new(935.876, 132.344, -52.726)
                else
                    hrp.CFrame = savedFarmLocations[currentSpotIndex] or hrp.CFrame
                end
                task.wait(1)
            end
        end
        task.wait(1)
    end
end)

warn("[SkenaHub] Simple Spells Redesign Loaded!")
