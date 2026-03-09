-- ==========================================
-- SKENA HUB : Simple Spells!
-- Place ID: 118433033586507
-- ==========================================

local SkenaUI = getgenv().SkenaLoad("SkenaUI_Library.lua")

-- 1. Buat Window
local Window = SkenaUI.CreateWindow("SkenaHub", "Skena Hub | Simple Spells!", false)

-- 2. Buat Tab
local TabMain = Window:CreateTab("Main", "zap", false)
local TabTeleport = Window:CreateTab("Teleport", "map-pin", false)

-- HELPER: Kill phantom loops
pcall(function()
    if getgenv()._SKENA_SS_LOOPS then
        for _, flag in pairs(getgenv()._SKENA_SS_LOOPS) do
            getgenv()[flag] = false
        end
    end
end)
getgenv()._SKENA_SS_LOOPS = {}

local function RegisterLoop(flagName)
    getgenv()[flagName] = false
    table.insert(getgenv()._SKENA_SS_LOOPS, flagName)
end

-- ==========================================
-- 0. TELEPORT FEATURES
-- ==========================================

TabTeleport:CreateButtonRow({
    Name = "Common Zone",
    Text = "Teleport",
    Callback = function()
        local char = game.Players.LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = CFrame.new(853.272, 132.774, -114.176) end
    end
})

TabTeleport:CreateButtonRow({
    Name = "Desert Zone",
    Text = "Teleport",
    Callback = function()
        local char = game.Players.LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = CFrame.new(508.961, 126.700, 135.752) end
    end
})

TabTeleport:CreateButtonRow({
    Name = "Mushroom Forest",
    Text = "Teleport",
    Callback = function()
        local char = game.Players.LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = CFrame.new(481.551, 238.700, -472.473) end
    end
})

TabTeleport:CreateButtonRow({
    Name = "Frozen Lands",
    Text = "Teleport",
    Callback = function()
        local char = game.Players.LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = CFrame.new(383.247, 302.700, -567.455) end
    end
})

TabTeleport:CreateButtonRow({
    Name = "Volcanic Caves",
    Text = "Teleport",
    Callback = function()
        local char = game.Players.LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = CFrame.new(136.528, 302.700, -350.816) end
    end
})

TabTeleport:CreateButtonRow({
    Name = "Secret Weapon - Ice Arrow",
    Text = "Teleport",
    Callback = function()
        local char = game.Players.LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = CFrame.new(1060.314, 132.567, -231.072) end
    end
})

TabTeleport:CreateButtonRow({
    Name = "Secret Weapon - Fire Sword",
    Text = "Teleport",
    Callback = function()
        local char = game.Players.LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = CFrame.new(869.619, 135.231, -390.111) end
    end
})

TabTeleport:CreateButtonRow({
    Name = "Secret Weapon - Ancient Catalyst",
    Text = "Teleport",
    Callback = function()
        local char = game.Players.LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = CFrame.new(527.259, 39.619, 493.563) end
    end
})

-- ==========================================
-- 1.0 AUTO FARM MASTER
-- ==========================================

local cachedBuster = "?t=" .. tostring(os.time())
local autoFarmEnabled = false
local isSelling = false
local savedFarmLocation1 = nil
local savedFarmLocation2 = nil
local savedFarmLocation3 = nil
local savedFarmLocation4 = nil
local currentSpotIndex = 1
local autoSellConfig = { cooldown = 60, enabled = true }

-- ==========================================
-- 1.1 SHARED HELPERS
-- ==========================================

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
-- 1. MAIN FEATURES
-- ==========================================

local selectedSpell = "Common [50 Gold]"
local quantity = 1
local spellMap = {
    ["Common [50 Gold]"] = {ball = "CrystallBall_1"},
    ["Desert [300 Gold]"] = {ball = "CrystallBall_2"},
    ["Forest [3,500 Gold]"] = {ball = "CrystallBall_3"},
    ["Frozen [25,000 Gold]"] = {ball = "CrystallBall_4"},
    ["Volcanic [100,000 Gold]"] = {ball = "CrystallBall_5"},
}

local buyDrop = TabMain:CreateDropdownButton({
    Name = "Buy Spell",
    ButtonText = "Buy!",
    DropWidth = 140,
    Callback = function(item)
        selectedSpell = item
    end,
    OnButton = function()
        local data = spellMap[selectedSpell]
        local ballName = data and data.ball
        local targetBall = ballName and workspace:FindFirstChild(ballName)
        
        if targetBall then
            warn("[Skena] Membeli " .. selectedSpell)
            -- Kita set angka terakhir jadi 1 (1x open) sesuai permintaan
            secureRemoteFire("BuyCrystalBall", targetBall, 1)
        else
            warn("[Skena] Gagal membeli: CrystalBall tidak ditemukan!")
        end
    end
})

buyDrop:AddItem("Common [50 Gold]", true)
buyDrop:AddItem("Desert [300 Gold]")
buyDrop:AddItem("Forest [3,500 Gold]")
buyDrop:AddItem("Frozen [25,000 Gold]")
buyDrop:AddItem("Volcanic [100,000 Gold]")

-- ==========================================
-- 1.5 COMBINED AUTO FARM CARD
-- ==========================================

autoFarmEnabled = false
isSelling = false
local spellStates = {
    ["1"] = { enabled = false, delay = 10 },
    ["2"] = { enabled = false, delay = 10 },
    ["3"] = { enabled = false, delay = 10 },
    ["4"] = { enabled = false, delay = 10 },
}

local sellRow -- Forward declaration
local farmCard = TabMain:CreateAutoFarmGroup({
    Name = "Auto Farm",
    HasMasterToggle = true,
    OnMasterToggle = function(state)
        autoFarmEnabled = state
        if not state then
            isSelling = false
            Window:UpdateCooldown("Auto Sell", 0)
            Window:UpdateCooldown("Selling...", 0)
            Window:UpdateCooldown("Skill 1", 0)
            Window:UpdateCooldown("Skill 2", 0)
            Window:UpdateCooldown("Skill 3", 0)
            Window:UpdateCooldown("Skill 4", 0)
        end
    end
})

-- 1. Add Auto Cast Skills
local skillEntries = {}
for i = 1, 4 do
    local id = tostring(i)
    local data = spellStates[id]
    
    task.spawn(function()
        while true do
            if autoFarmEnabled and data.enabled then
                if isSelling then
                    Window:UpdateCooldown("Skill " .. id, 0)
                    while isSelling and autoFarmEnabled and data.enabled do task.wait(0.5) end
                end
                
                if autoFarmEnabled and data.enabled then
                    local char = game.Players.LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local myCF = hrp.CFrame
                        local targetPos = (myCF * CFrame.new(0, 0, -10)).Position
                        secureRemoteFire("UseSpell", id, myCF, targetPos, true)
                    end
                    
                    local remaining = data.delay
                    while remaining > 0 and autoFarmEnabled and data.enabled and not isSelling do
                        Window:UpdateCooldown("Skill " .. id, remaining)
                        task.wait(0.1)
                        remaining = remaining - 0.1
                    end
                    Window:UpdateCooldown("Skill " .. id, 0)
                end
            else
                Window:UpdateCooldown("Skill " .. id, 0)
                task.wait(1)
            end
            task.wait(0.1)
        end
    end)

    table.insert(skillEntries, {
        Name = "Skill " .. id,
        DefaultToggle = false,
        DefaultDelay = data.delay,
        OnToggle = function(state) data.enabled = state end,
        OnDelay = function(val) data.delay = tonumber(val) or 10 end
    })
end
farmCard:AddMultiSkillRow(skillEntries)

-- 2. Add Unified Auto Sell & Spots Row
local function updateSpotButton(obj, success)
    local btn = obj.Button
    local status = obj.StatusLabel
    local oldText = btn.Text
    local oldColor = btn.BackgroundColor3
    btn.Text = success and "Saved!" or "Error"
    btn.BackgroundColor3 = success and Color3.fromRGB(0, 150, 80) or Color3.fromRGB(180, 50, 50)
    
    if success then
        status.Text = "Saved"
        status.TextColor3 = Color3.fromRGB(0, 255, 120)
    end
    
    task.delay(1.5, function()
        btn.Text = oldText
        btn.BackgroundColor3 = oldColor
    end)
end

local spotBtns = farmCard:AddUnifiedActionRow({
    Name = "Auto Sell",
    InputDefault = "60",
    DefaultToggle = true,
    OnToggle = function(state)
        autoSellConfig.enabled = state
        if not state then
            isSelling = false
            Window:UpdateCooldown("Auto Sell", 0)
            Window:UpdateCooldown("Selling...", 0)
        end
    end,
    Callback = function(val)
        autoSellConfig.cooldown = tonumber(val) or 60
    end
}, {
    {
        Text = "Spot 1",
        Status = "Empty",
        Callback = function(obj)
            local char = game.Players.LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                savedFarmLocation1 = hrp.CFrame
                updateSpotButton(obj, true)
            else
                updateSpotButton(obj, false)
            end
        end
    },
    {
        Text = "Spot 2",
        Status = "Empty",
        Callback = function(obj)
            local char = game.Players.LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                savedFarmLocation2 = hrp.CFrame
                updateSpotButton(obj, true)
            else
                updateSpotButton(obj, false)
            end
        end
    },
    {
        Text = "Spot 3",
        Status = "Empty",
        Callback = function(obj)
            local char = game.Players.LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                savedFarmLocation3 = hrp.CFrame
                updateSpotButton(obj, true)
            else
                updateSpotButton(obj, false)
            end
        end
    },
    {
        Text = "Spot 4",
        Status = "Empty",
        Callback = function(obj)
            local char = game.Players.LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                savedFarmLocation4 = hrp.CFrame
                updateSpotButton(obj, true)
            else
                updateSpotButton(obj, false)
            end
        end
    }
})

-- Master Sell Loop
task.spawn(function()
    while true do
        if autoFarmEnabled and autoSellConfig.enabled then
            local char = game.Players.LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if hrp then
                isSelling = true
                -- 1. Simpan Lokasi Sementara (Safety)
                local oldCF = hrp.CFrame
                local safetyCF = oldCF + Vector3.new(0, 1, 0)
                
                -- 2. Teleport ke Area Jual
                hrp.CFrame = CFrame.new(935.876, 132.344, -52.726)
                
                -- 3. Tunggu Proses (5 detik)
                local sellTimer = 5
                while sellTimer > 0 and autoFarmEnabled and autoSellConfig.enabled do
                    Window:UpdateCooldown("Selling...", sellTimer)
                    task.wait(0.1)
                    sellTimer = sellTimer - 0.1
                end
                Window:UpdateCooldown("Selling...", 0)
                
                -- 4. Kembali ke Spot (Rotation Logic)
                if autoFarmEnabled and autoSellConfig.enabled then
                    local targetCF = safetyCF
                    
                    local activeSpots = {}
                    if savedFarmLocation1 then table.insert(activeSpots, 1) end
                    if savedFarmLocation2 then table.insert(activeSpots, 2) end
                    if savedFarmLocation3 then table.insert(activeSpots, 3) end
                    if savedFarmLocation4 then table.insert(activeSpots, 4) end
                    
                    if #activeSpots > 0 then
                        -- Find next active spot in rotation
                        local foundNext = false
                        for i = 1, #activeSpots do
                            if activeSpots[i] > currentSpotIndex then
                                currentSpotIndex = activeSpots[i]
                                foundNext = true
                                break
                            end
                        end
                        
                        -- If none found higher than current, wrap back to the first active spot
                        if not foundNext then
                            currentSpotIndex = activeSpots[1]
                        end
                        
                        -- Set target
                        if currentSpotIndex == 1 then targetCF = savedFarmLocation1
                        elseif currentSpotIndex == 2 then targetCF = savedFarmLocation2
                        elseif currentSpotIndex == 3 then targetCF = savedFarmLocation3
                        elseif currentSpotIndex == 4 then targetCF = savedFarmLocation4 end
                    end
                    
                    hrp.CFrame = targetCF
                end
                isSelling = false
            end
            
            -- Cooldown
            local cdRemaining = autoSellConfig.cooldown
            while cdRemaining > 0 and autoFarmEnabled and autoSellConfig.enabled do
                Window:UpdateCooldown("Auto Sell", cdRemaining)
                task.wait(0.1)
                cdRemaining = cdRemaining - 0.1
            end
            Window:UpdateCooldown("Auto Sell", 0)
        else
            task.wait(1)
        end
        task.wait(0.1)
    end
end)

-- ==========================================
-- 1.7 ANTI-VOID SAFETY
-- ==========================================
task.spawn(function()
    while true do
        if autoFarmEnabled then
            local char = game.Players.LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if hrp and hrp.Position.Y <= 15 then
                -- Anti-Void Triggered
                if isSelling then
                    -- Teleport back to Sell Area
                    hrp.CFrame = CFrame.new(935.876, 132.344, -52.726)
                else
                    -- Teleport back to Current Spot
                    local targetCF = nil
                    if currentSpotIndex == 1 and savedFarmLocation1 then
                        targetCF = savedFarmLocation1
                    elseif currentSpotIndex == 2 and savedFarmLocation2 then
                        targetCF = savedFarmLocation2
                    elseif currentSpotIndex == 3 and savedFarmLocation3 then
                        targetCF = savedFarmLocation3
                    elseif currentSpotIndex == 4 and savedFarmLocation4 then
                        targetCF = savedFarmLocation4
                    else
                        -- Fallback to any saved spot
                        targetCF = savedFarmLocation1 or savedFarmLocation2 or savedFarmLocation3 or savedFarmLocation4
                    end
                    
                    if targetCF then
                        hrp.CFrame = targetCF
                    end
                end
                task.wait(1) -- Prevent rapid teleporting
            end
        end
        task.wait(1) -- Check every second
    end
end)

-- ==========================================
-- 2. ESP FEATURES (ObjectsToDestroy)
-- ==========================================

local discoveredItems = {}
local dynamicFilters = {} -- Item filter states
local dynamicESPEnabled = false
local dynamicRadius = 50
local dynamicDropdown

local zoneDiscoveredItems = {}
local zoneFilters = {}
local zoneESPEnabled = false
local zoneDropdown

local function applyItemESP(obj, name)
    if not obj or not obj.Parent then return end
    
    local filterState = dynamicFilters[name]
    local shouldEnable = dynamicESPEnabled and (filterState ~= false)
    
    local hl = obj:FindFirstChild("SkenaItemESP")
    
    -- Distance check
    if shouldEnable and dynamicRadius > 0 then
        local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local objPos = obj:IsA("Model") and (obj.PrimaryPart and obj.PrimaryPart.Position or obj:GetPivot().Position) or (obj:IsA("BasePart") and obj.Position)
            if objPos and (hrp.Position - objPos).Magnitude > dynamicRadius then
                shouldEnable = false
            end
        end
    end

    if not shouldEnable then
        if hl and hl.Enabled then
            hl.Enabled = false
            if hl:FindFirstChild("SkenaItemTag") then hl.SkenaItemTag.Enabled = false end
        end
        return
    end

    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = "SkenaItemESP"
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.FillColor = Color3.fromRGB(0, 255, 150)
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.Enabled = false -- Start disabled
        hl.Parent = obj
        
        local bb = Instance.new("BillboardGui")
        bb.Name = "SkenaItemTag"
        bb.Adornee = obj
        bb.Size = UDim2.new(0, 100, 0, 20)
        bb.StudsOffset = Vector3.new(0, 2, 0)
        bb.AlwaysOnTop = true
        bb.Enabled = false -- Start disabled
        bb.Parent = hl
        local tl = Instance.new("TextLabel")
        tl.Size = UDim2.new(1, 0, 1, 0)
        tl.BackgroundTransparency = 1
        tl.Text = name
        tl.TextColor3 = Color3.new(1,1,1)
        tl.Font = Enum.Font.Gotham
        tl.TextSize = 10
        tl.Parent = bb
    end
    
    if not hl.Enabled then
        hl.Enabled = true
        local tag = hl:FindFirstChild("SkenaItemTag")
        if tag and tag.Enabled ~= true then tag.Enabled = true end
    end
end

local function checkItem(obj)
    if not (obj:IsA("BasePart") or obj:IsA("Model")) then return end
    
    local name = obj.Name
    if not discoveredItems[name] then
        discoveredItems[name] = {}
        dynamicFilters[name] = false
        dynamicDropdown:AddItem(name, false, function(state)
            dynamicFilters[name] = state
            if discoveredItems[name] then
                for _, v in ipairs(discoveredItems[name]) do
                    if v and v.Parent then applyItemESP(v, name) end
                end
            end
        end)
    end
    
    local found = false
    for _, v in ipairs(discoveredItems[name]) do if v == obj then found = true break end end
    if not found then table.insert(discoveredItems[name], obj) end

    applyItemESP(obj, name)
end

-- Radius Slider Row
TabMain:CreateSliderRow({
    Name = "ESP Search Radius",
    Min = 10,
    Max = 1000, -- Increased for zone scanning
    Default = 500,
    Callback = function(val)
        dynamicRadius = val
    end
})

dynamicDropdown = TabMain:CreateMultiSelectDropdown({
    Name = "ESP Objects To Destroy",
    HasMainToggle = true,
    HasSearch = true,
    DropWidth = 120,
    OnMainToggle = function(state)
        dynamicESPEnabled = state
        for name, list in pairs(discoveredItems) do
            for _, v in ipairs(list) do
                if v and v.Parent then applyItemESP(v, name) end
            end
        end
    end
})

-- === ZONE ESP SECTION ===

local function applyZoneESP(obj, name)
    if not obj or not obj.Parent then return end
    local filterState = zoneFilters[name]
    local shouldEnable = zoneESPEnabled and (filterState ~= false)
    
    local hl = obj:FindFirstChild("SkenaZoneESP")
    
    -- Distance check (Zones use same radius for now)
    if shouldEnable and dynamicRadius > 0 then
        local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local objPos = obj:IsA("Model") and (obj.PrimaryPart and obj.PrimaryPart.Position or obj:GetPivot().Position) or (obj:IsA("BasePart") and obj.Position)
            if objPos and (hrp.Position - objPos).Magnitude > dynamicRadius then
                shouldEnable = false
            end
        end
    end

    if not shouldEnable then
        if hl and hl.Enabled then
            hl.Enabled = false
            if hl:FindFirstChild("SkenaItemTag") then hl.SkenaItemTag.Enabled = false end
        end
        return
    end

    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = "SkenaZoneESP"
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.FillColor = Color3.fromRGB(200, 100, 255) -- Purple for Zones
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.Parent = obj
        
        local bb = Instance.new("BillboardGui")
        bb.Name = "SkenaItemTag"
        bb.Adornee = obj
        bb.Size = UDim2.new(0, 120, 0, 20)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true
        bb.Parent = hl
        local tl = Instance.new("TextLabel")
        tl.Size = UDim2.new(1, 0, 1, 0)
        tl.BackgroundTransparency = 1
        tl.Text = name
        tl.TextColor3 = Color3.new(1,1,1)
        tl.Font = Enum.Font.Gotham
        tl.TextSize = 10
        tl.Parent = bb
    end
    
    hl.Enabled = true
    if hl:FindFirstChild("SkenaItemTag") then hl.SkenaItemTag.Enabled = true end
end

local function checkZoneItem(obj)
    local name = obj.Name
    if not zoneDiscoveredItems[name] then
        zoneDiscoveredItems[name] = {}
        zoneFilters[name] = false
        zoneDropdown:AddItem(name, false, function(state)
            zoneFilters[name] = state
            for _, v in ipairs(zoneDiscoveredItems[name]) do
                if v and v.Parent then applyZoneESP(v, name) end
            end
        end)
    end
    
    local found = false
    for _, v in ipairs(zoneDiscoveredItems[name]) do if v == obj then found = true break end end
    if not found then table.insert(zoneDiscoveredItems[name], obj) end

    applyZoneESP(obj, name)
end

zoneDropdown = TabMain:CreateMultiSelectDropdown({
    Name = "ESP Zone Items",
    HasMainToggle = true,
    HasSearch = true,
    DropWidth = 120,
    OnMainToggle = function(state)
        zoneESPEnabled = state
        for name, list in pairs(zoneDiscoveredItems) do
            for _, v in ipairs(list) do
                if v and v.Parent then applyZoneESP(v, name) end
            end
        end
    end
})

-- Optimized Scanning Logic for ObjectsToDestroy
task.spawn(function()
    local root = workspace:FindFirstChild("ObjectsToDestroy")
    if not root then return end

    local function runSpatialScan()
        if not dynamicESPEnabled then return end
        local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        local params = OverlapParams.new()
        params.FilterType = Enum.RaycastFilterType.Include
        params.FilterDescendantsInstances = {root}
        
        local parts = workspace:GetPartBoundsInRadius(hrp.Position, dynamicRadius, params)
        local seenInTick = {}

        for _, part in ipairs(parts) do
            -- Identify the logical "Item" (Model or Part inside a Folder)
            local item = part
            if part.Parent:IsA("Model") then
                item = part.Parent
            end
            
            -- Must be inside ObjectsToDestroy and NOT a structural folder
            if item ~= root and not (item:IsA("Folder") and item.Parent == root) then
                if not seenInTick[item] then
                    seenInTick[item] = true
                    checkItem(item)
                end
            end
        end
    end

    -- Initial scan
    runSpatialScan()

    -- Monitor only nearby additions
    root.DescendantAdded:Connect(function(obj)
        if not dynamicESPEnabled then return end
        local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local pos = obj:IsA("BasePart") and obj.Position or (obj:IsA("Model") and obj:GetPivot().Position)
            if pos and (pos - hrp.Position).Magnitude <= dynamicRadius then
                task.delay(0.1, function()
                    if obj and obj.Parent then
                        local item = obj
                        if obj:IsA("BasePart") and obj.Parent:IsA("Model") then item = obj.Parent end
                        if item ~= root and not (item:IsA("Folder") and item.Parent == root) then
                            checkItem(item)
                        end
                    end
                end)
            end
        end
    end)
    
    -- Periodic Refresher & Discovery
    while task.wait(1) do
        if dynamicESPEnabled then
            runSpatialScan() 
            
            local categories = 0
            for name, list in pairs(discoveredItems) do
                if dynamicFilters[name] ~= false then
                    categories = categories + 1
                    for i, v in ipairs(list) do
                        if v and v.Parent then 
                            applyItemESP(v, name) 
                            if i % 100 == 0 then task.wait() end 
                        end
                    end
                    if categories % 3 == 0 then task.wait() end -- Throttle between groups
                end
            end
        end
    end
end)

-- Optimized Scanning for ZoneDoors
task.spawn(function()
    local zoneRoot = workspace:FindFirstChild("ZoneDoors")
    if not zoneRoot then return end

    local function runZoneScan()
        if not zoneESPEnabled then return end
        
        -- Kita scan semua folder di dalam ZoneDoors (seperti Frozen Lands)
        for _, zoneFolder in ipairs(zoneRoot:GetChildren()) do
            if zoneFolder:IsA("Folder") or zoneFolder:IsA("Model") then
                for _, item in ipairs(zoneFolder:GetChildren()) do
                    if item:IsA("Model") or item:IsA("BasePart") then
                        checkZoneItem(item)
                    end
                end
            end
        end
    end

    -- Initial scan
    runZoneScan()

    -- Periodic Refresh (setiap 5 detik untuk efisiensi)
    while task.wait(5) do
        if zoneESPEnabled then
            runZoneScan()
        end
    end
end)


-- ==========================================
-- ATTACH ADMIN MODULE
-- ==========================================
task.spawn(function()
    local success, SkenaAdmin = pcall(function()
        return getgenv().SkenaLoad("SkenaUI_Admin.lua")
    end)
    if success and SkenaAdmin then
        SkenaAdmin.Attach(Window, {})
    end
end)

