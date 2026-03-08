-- ==========================================
-- SKENA HUB : +1 Skill Point Legend
-- Game ID: 135668295983945
-- ==========================================
-- Info Game:
--   Mob ada di Workspace.Npcs (Model, nama numerik)
--   Mob punya HumanoidRootPart (bisa TP)
--   Mob TIDAK pakai Humanoid (HP server-side via ByteNet)
--   Attack = client-side click simulation

local SkenaUI_LibURL = "https://raw.githubusercontent.com/kndrckm/kndrckm.github.io/refs/heads/main/key/SkenaUI_Library.lua"
local cacheBuster = "?t=" .. tostring(os.time())
local libBody = game:HttpGet(SkenaUI_LibURL .. cacheBuster, true)
local libFunc, libErr = loadstring(libBody)
if not libFunc then error("SkenaUI Library Syntax Error: " .. tostring(libErr)) end
local SkenaUI = libFunc()

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- ==========================================
-- BUAT WINDOW
-- ==========================================
local Window = SkenaUI.CreateWindow("SkenaHub", "+1 Skill Point Legend", false)
local TabMain = Window:CreateTab("Main", "zap", false)
local TabBoss = Window:CreateTab("Bosses", "map-pin", false)
local TabSettings = Window:CreateTab("Settings", "settings", true)

-- Kill phantom loops
pcall(function()
    if getgenv()._SKENA_SPL_LOOPS then
        for _, flag in pairs(getgenv()._SKENA_SPL_LOOPS) do
            getgenv()[flag] = false
        end
    end
end)
getgenv()._SKENA_SPL_LOOPS = {}

local function RegisterLoop(flagName)
    getgenv()[flagName] = false
    table.insert(getgenv()._SKENA_SPL_LOOPS, flagName)
end
-- ==========================================
-- HELPER: Cached Mob Part Counter
-- ==========================================
local MOB_PART_CACHE = {}

-- ==========================================
-- HELPER: Get Sorted Mob List (Scan Logic)
-- ==========================================
local function getMobList(targetParts)
    local npcsFolder = workspace:FindFirstChild("Npcs")
    if not npcsFolder then return {} end
    
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return {} end
    
    local list = {}
    
    -- Clean dead mobs from cache
    for mobInstance, _ in pairs(MOB_PART_CACHE) do
        if not mobInstance:IsDescendantOf(workspace) then
            MOB_PART_CACHE[mobInstance] = nil
        end
    end
    
    for _, mob in ipairs(npcsFolder:GetChildren()) do
        if mob:IsA("Model") then
            local mobHRP = mob:FindFirstChild("HumanoidRootPart")
            if mobHRP and (not mobHRP.Anchored) and mobHRP.Transparency < 0.9 then
                if targetParts then
                    -- Use cached parts or calculate once if not cached
                    local parts = MOB_PART_CACHE[mob]
                    if not parts then
                        parts = #mob:GetDescendants()
                        MOB_PART_CACHE[mob] = parts
                    end
                    
                    local match = false
                    if type(targetParts) == "table" then
                        for _, p in ipairs(targetParts) do
                            if parts == p then match = true break end
                        end
                    else
                        match = (parts == targetParts)
                    end
                    if not match then continue end
                end
                
                local dist = (hrp.Position - mobHRP.Position).Magnitude
                table.insert(list, {mob = mob, hrp = mobHRP, dist = dist})
            end
        end
    end
    
    table.sort(list, function(a, b) return a.dist < b.dist end)
    
    return list
end

-- ==========================================
-- HELPER: Stepped teleport (long distance)
-- ==========================================
local function steppedTeleport(targetCFrame)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local startPos = hrp.Position
    local endPos = targetCFrame.Position
    local totalDist = (endPos - startPos).Magnitude
    
    -- Short distance: just teleport directly
    if totalDist <= 50 then
        hrp.CFrame = targetCFrame
        hrp.Velocity = Vector3.new(0, 0, 0)
        return
    end
    
    -- Long distance: teleport in small steps to avoid rubber-banding
    local stepSize = 50
    local steps = math.ceil(totalDist / stepSize)
    for i = 1, steps do
        if not char or not char.Parent then return end
        local alpha = i / steps
        local pos = startPos:Lerp(endPos, alpha)
        hrp.CFrame = CFrame.new(pos)
        hrp.Velocity = Vector3.new(0, 0, 0)
        if hrp:FindFirstChild("BodyVelocity") then
            hrp.BodyVelocity:Destroy()
        end
        task.wait(0.15)
    end
    -- Final precise position
    hrp.CFrame = targetCFrame
    hrp.Velocity = Vector3.new(0, 0, 0)
end

-- ==========================================
-- WORLDS & MOB LIST (fingerprinted by parts count)
-- ==========================================
local WORLDS = {
    Grassland = Vector3.new(149.254, 12.000, 518.938),
    CursedKingdom = Vector3.new(2543.238, 84.500, -669.682)
}

local MOB_LIST = {
    -- FILTERED OUT (Archived per user request, using Dynamic Scan instead)
    --[[
    { name = "Snail",           hp = "10",     parts = {116}, world = "Grassland" },
    { name = "Pig",             hp = "800",    parts = {109}, world = "Grassland" },
    { name = "Turtle",          hp = "2.5k",   parts = {157}, world = "Grassland" },
    { name = "Caveman",         hp = "4.5k",   parts = {311}, world = "Grassland" },
    { name = "Spider",          hp = "12.5k",  parts = {107}, world = "Grassland" },
    { name = "Mammoth",         hp = "75k",    parts = {141}, world = "Grassland" },
    
    { name = "Viperbloom",      hp = "125k",   parts = {255}, world = "CursedKingdom" },
    { name = "Warlock",         hp = "100k",   parts = {162}, world = "CursedKingdom" },
    { name = "Spartan",         hp = "250k",   parts = {189, 177}, world = "CursedKingdom" },
    
    { name = "Reaper",          hp = "750k",   parts = {120} },
    { name = "Angel",           hp = "1.5m",   parts = {133} },
    { name = "Cowboy",          hp = "15m",    parts = {171} },
    { name = "Ghost",           hp = "60m",    parts = {84} },
    { name = "Totem Sentinel",  hp = "250m",   parts = {222} },
    { name = "Mummy",           hp = "500m",   parts = {816} },
    { name = "Blightleap",      hp = "2.5b",   parts = nil },
    { name = "Bonepicker",      hp = "25b",    parts = nil },
    { name = "Oculon",          hp = "100b",   parts = nil },
    { name = "Magmaton",        hp = "600b",   parts = nil },
    ]]
}

local BOSS_LIST = {
    -- Grassland Bosses
    { name = "Chief",           hp = "25k",    parts = {321}, world = "Grassland", bscheckpoint = Vector3.new(149.58, 4, -689.58) },
    { name = "Dino",            hp = "250k",   parts = {267}, world = "Grassland", bscheckpoint = Vector3.new(1289.93, 725, 637.99) },
    { name = "Arachenex",       hp = "450k",   parts = {144, 143}, world = "Grassland", bscheckpoint = Vector3.new(1332.46, 7, -59.47) },
    
    -- Cursed Kingdom Bosses
    { name = "Grimroot",        hp = "950k",   parts = {497, 498}, world = "CursedKingdom", bscheckpoint = Vector3.new(1233.23, 19, -590.66) },
    { name = "Leonidas",        hp = "1.25m",  parts = {163, 164}, world = "CursedKingdom", bscheckpoint = Vector3.new(2696.89, 84, -649.57) },
    
    -- Unknown World
    { name = "Minotaur",        hp = "30b",    parts = {263}, bscheckpoint = Vector3.new(307.29, -90.4, -542.14) },
    { name = "Lightning God",   hp = "25m",    parts = {123}, bscheckpoint = Vector3.new(673.74, 407, -2146.04) },
    { name = "Sand Golem",      hp = "2b",     parts = {614}, bscheckpoint = Vector3.new(577.86, 40.8, -3905.71) },
    { name = "Hydra Worm",      hp = "4b",     parts = {355}, bscheckpoint = Vector3.new(627.96, 40.8, -3512.46) },
    { name = "Dragon",          hp = "8b",     parts = {151}, bscheckpoint = Vector3.new(693.95, 321.92, -3557.43) },
    { name = "Nevermore",       hp = "75b",    parts = nil, bscheckpoint = Vector3.new(1232.99, -489.2, -3897.2) },
    { name = "Simba",           hp = "750b",   parts = nil, bscheckpoint = Vector3.new(1205.18, -488.6, -3131.8) },
    { name = "Anibis",          hp = "1.5t",   parts = nil, bscheckpoint = Vector3.new(1264.43, -489.3, -3588.42) },
    { name = "Ashgor",          hp = "1.6t",   parts = nil, bscheckpoint = Vector3.new(597.25, 4, -33.63) },
}

-- Build fingerprint lookup: parts -> mob name
local PARTS_TO_NAME = {}
for _, m in ipairs(MOB_LIST) do
    if m.parts then
        for _, p in ipairs(m.parts) do PARTS_TO_NAME[p] = m.name end
    end
end
for _, m in ipairs(BOSS_LIST) do
    if m.parts then
        for _, p in ipairs(m.parts) do PARTS_TO_NAME[p] = m.name .. " (Boss)" end
    end
end

-- Only show mobs with known fingerprints in Target Mob dropdown
local MOB_LABELS = {}
for _, m in ipairs(MOB_LIST) do
    if m.parts then
        table.insert(MOB_LABELS, { key = m.name, parts = m.parts, world = m.world, label = m.name .. " [" .. m.hp .. "]" })
    end
end
getgenv().SelectedMob = MOB_LABELS[1] and MOB_LABELS[1].key or "Pig"
getgenv().SelectedMobParts = MOB_LABELS[1] and MOB_LABELS[1].parts or nil
getgenv().SelectedMobWorld = MOB_LABELS[1] and MOB_LABELS[1].world or nil

-- ==========================================
-- TAB MAIN
-- ==========================================

-- Dropdown + Toggle: Target Mob & Auto TP
-- Dropdown + Toggle: Target Mob & Auto TP (SCAN MODE)
-- Replicates "Script 1" logic by grouping mobs by Size (HumanoidRootPart.Size.Y)
RegisterLoop("_SKENA_AUTO_TP_MOB")
local MobDrop
MobDrop = TabMain:CreateDropdownButton({
    Name = " [ TP to Mob ]",
    ButtonText = "Scan",
    Columns = 2,
    Callback = function(val)
        -- Format: "Size: 5.5 | Count: 3"
        local sizeStr = string.match(val, "Size: ([%d%.]+)")
        if sizeStr then
            getgenv().SelectedMobSize = tonumber(sizeStr)
            warn("Target Size: " .. sizeStr)
        end
    end,
    OnButton = function()
        -- Dynamic Scan Logic
        local npcsF = workspace:FindFirstChild("Npcs")
        if not npcsF then return end
        
        local sizeGroups = {}
        for _, mob in ipairs(npcsF:GetChildren()) do
            if mob:IsA("Model") then
                local hrp = mob:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local sz = math.floor(hrp.Size.Y * 10) / 10 -- Round to 1 decimal
                    if not sizeGroups[sz] then sizeGroups[sz] = 0 end
                    sizeGroups[sz] = sizeGroups[sz] + 1
                end
            end
        end
        
        local sorted = {}
        for sz, count in pairs(sizeGroups) do
            table.insert(sorted, {sz = sz, count = count})
        end
        table.sort(sorted, function(a,b) return a.sz < b.sz end)
        
        MobDrop:ClearItems()
        for _, data in ipairs(sorted) do
            MobDrop:AddItem("Size: " .. data.sz .. " | Count: " .. data.count, false)
        end
    end,
    OnToggle = function(state)
        getgenv()._SKENA_AUTO_TP_MOB = state
        if state then
            task.spawn(function()
                while getgenv()._SKENA_AUTO_TP_MOB do
                    local char = player.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then task.wait(0.5) continue end
                    
                    local targetSize = getgenv().SelectedMobSize
                    if not targetSize then task.wait(0.5) continue end
                    
                    local bestMob = nil
                    local minDist = 9e9
                    
                    local npcsF = workspace:FindFirstChild("Npcs")
                    if npcsF then
                        for _, mob in ipairs(npcsF:GetChildren()) do
                            if mob:IsA("Model") then
                                local mHrp = mob:FindFirstChild("HumanoidRootPart")
                                if mHrp and mHrp.Transparency < 0.9 and (not mHrp.Anchored) then
                                    local sz = math.floor(mHrp.Size.Y * 10) / 10
                                    if sz == targetSize then
                                        local dist = (hrp.Position - mHrp.Position).Magnitude
                                        if dist < minDist then
                                            minDist = dist
                                            bestMob = mHrp
                                        end
                                    end
                                end
                            end
                        end
                    end
                    
                    if bestMob then
                        local behindPos = bestMob.CFrame * CFrame.new(0, 0, 3) 
                        steppedTeleport(behindPos)
                    end
                    task.wait(0.1)
                end
            end)
        end
    end
})

local VIM = game:GetService("VirtualInputManager")

local function doAttack()
    pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        local punch = rs:FindFirstChild("Source") and rs.Source:FindFirstChild("Weapons") and rs.Source.Weapons:FindFirstChild("Punch")
        if punch then require(punch).onActivated(true) end
    end)
end

-- ==========================================
-- AUTO ATTACK
-- ==========================================
getgenv()._SKENA_AUTO_ATTACK = false

RegisterLoop("_SKENA_AUTO_ATTACK")
TabMain:CreateToggleRow({
    Name = " [ Auto Attack ]",
    Callback = function(state) end,
    OnToggle = function(state)
        getgenv()._SKENA_AUTO_ATTACK = state
        if state then
            task.spawn(function()
                while getgenv()._SKENA_AUTO_ATTACK do
                    doAttack()
                    task.wait(0.15)
                end
            end)
        end
    end
})

-- ==========================================
-- KILL AURA (WIP - slider + toggle)
-- ==========================================
getgenv()._SKENA_KILL_RANGE = 25

-- ==========================================
-- KILL AURA (Slider + Toggle)
-- ==========================================
getgenv()._SKENA_KILL_RANGE = 25

TabMain:CreateSliderRow({
    Name = "Kill Aura Range",
    Min = 5,
    Max = 100,
    Default = 25,
    Suffix = "", -- Force no suffix
    Callback = function(val)
        getgenv()._SKENA_KILL_RANGE = tonumber(val) or 25
    end
})

RegisterLoop("_SKENA_KILL_AURA")
TabMain:CreateToggleRow({
    Name = " [ Enable Kill Aura ]",
    OnToggle = function(state)
        getgenv()._SKENA_KILL_AURA = state
        if state then
            task.spawn(function()
                while getgenv()._SKENA_KILL_AURA do
                    pcall(function()
                        local char = player.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if not hrp then return end
                        
                        local range = getgenv()._SKENA_KILL_RANGE or 25
                        local npcsF = workspace:FindFirstChild("Npcs")
                        if not npcsF then return end
                        
                        for _, mob in ipairs(npcsF:GetChildren()) do
                            if not getgenv()._SKENA_KILL_AURA then return end
                            if mob:IsA("Model") then
                                local mobHRP = mob:FindFirstChild("HumanoidRootPart")
                                if mobHRP then
                                    local dist = (hrp.Position - mobHRP.Position).Magnitude
                                    if dist <= range then
                                        pcall(function()
                                            -- Use the powerful Module Punch from Script 1
                                            doAttack()
                                        end)
                                    end
                                end
                            end
                        end
                    end)
                    task.wait(0.2)
                end
            end)
        end
    end
})

-- ==========================================
-- IDENTIFY MOBS (Scan & TP via Dropdown)
-- Untuk temukan mob baru yang belum di-mapping
-- ==========================================
TabMain:CreateTextRow({
    Text = "── Identifikasi Mob ──"
})

local IdentifyDrop
IdentifyDrop = TabMain:CreateDropdownButton({
    Name = " [ Scan Live Mobs ]",
    ButtonText = "Scan",
    Columns = 2,
    KeepOpen = true,
    Callback = function(val)
        -- Parse ID from label: "Pig | ID:173"
        local mobId = string.match(val, "ID:(%d+)")
        if mobId then
            local npcsF = workspace:FindFirstChild("Npcs")
            if npcsF then
                local mob = npcsF:FindFirstChild(mobId)
                if mob and mob:FindFirstChild("HumanoidRootPart") then
                    steppedTeleport(mob.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3))
                    warn("[TP] " .. val)
                end
            end
        end
    end,
    OnButton = function()
        local npcsF = workspace:FindFirstChild("Npcs")
        if not npcsF then warn("[Scan] Folder Npcs tidak ada!") return end
        
        -- Clear existing items
        local dropToUse = IdentifyDrop -- Self reference trick
        dropToUse:ClearItems()
        
        local allMobs = {}
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        
        for _, mob in ipairs(npcsF:GetChildren()) do
            if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") then
                local parts = #mob:GetDescendants()
                local mobHRP = mob.HumanoidRootPart
                local dist = hrp and math.floor((hrp.Position - mobHRP.Position).Magnitude) or 0
                local knownName = PARTS_TO_NAME[parts] or "???"
                table.insert(allMobs, {
                    id = mob.Name,
                    parts = parts,
                    dist = dist,
                    knownName = knownName
                })
            end
        end
        
        table.sort(allMobs, function(a, b) return a.dist < b.dist end)
        
        for i, m in ipairs(allMobs) do
            dropToUse:AddItem(m.knownName .. " #" .. i .. " | ID:" .. m.id .. (m.knownName == "???" and (" (" .. m.parts .. "p)") or ""), i == 1)
        end
        
        warn("[Scan] " .. #allMobs .. " mob total.")
    end
})

-- ==========================================
-- TAB BOSSES (TP via Gate system)
-- ==========================================
TabBoss:CreateTextRow({
    Text = "Teleport ke boss lewat Gates di Workspace.Gates"
})

local function createBossTP(name, gatePath)
    TabBoss:CreateButtonRow({
        Name = name,
        ButtonText = "TP",
        Callback = function()
            pcall(function()
                local gate = workspace
                for _, part in ipairs(string.split(gatePath, ".")) do
                    gate = gate:FindFirstChild(part)
                    if not gate then break end
                end
                if gate then
                    local target = gate:FindFirstChild("HumanoidRootPart") or gate:FindFirstChild("Portal") or gate.PrimaryPart or (gate:IsA("BasePart") and gate)
                    if not target then
                        -- Cari BasePart pertama
                        for _, ch in ipairs(gate:GetDescendants()) do
                            if ch:IsA("BasePart") then target = ch break end
                        end
                    end
                    if target then
                        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            hrp.CFrame = target.CFrame * CFrame.new(0, 3, 0)
                            warn("[TP] Teleported to " .. name)
                        end
                    else
                        warn("[TP] Target part tidak ditemukan di " .. gatePath)
                    end
                else
                    warn("[TP] Gate tidak ditemukan: " .. gatePath)
                end
            end)
        end
    })
end

-- Gate-based TP (dari Workspace.Gates)
createBossTP("Grassland (Spawn)", "Gates.Grassland")

-- Scan gates otomatis
pcall(function()
    local gatesFolder = workspace:FindFirstChild("Gates")
    if gatesFolder then
        for _, gate in ipairs(gatesFolder:GetChildren()) do
            if gate.Name ~= "Grassland" then -- Skip spawn karena sudah di atas
                createBossTP(gate.Name, "Gates." .. gate.Name)
            end
        end
    end
end)

TabBoss:CreateTextRow({
    Text = "─── Teleport Langsung (Bypass Gate) ───"
})

for _, boss in ipairs(BOSS_LIST) do
    if boss.bscheckpoint then
        TabBoss:CreateButtonRow({
            Name = boss.name .. " (" .. boss.hp .. ")",
            ButtonText = "Direct TP",
            Callback = function()
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    steppedTeleport(CFrame.new(boss.bscheckpoint))
                    warn("[Direct TP] Teleported to " .. boss.name)
                end
            end
        })
    end
end

-- ==========================================
-- TAB SETTINGS
-- ==========================================
TabSettings:CreateTextRow({
    Text = getgenv()._SKENA_ANTI_AFK and "🟢 Anti-AFK Active" or "🔴 Anti-AFK Failed"
})

local RunService = game:GetService("RunService")
local blackScreenGui = nil

local function toggleBlackScreen(state)
    if state then
        pcall(function()
            if not blackScreenGui then
                blackScreenGui = Instance.new("ScreenGui")
                blackScreenGui.Name = "SkenaBlackScreen"
                blackScreenGui.IgnoreGuiInset = true
                -- Default to CoreGui, if not possible use PlayerGui but with strictly low DisplayOrder
                blackScreenGui.DisplayOrder = -999999 
                
                local bg = Instance.new("Frame", blackScreenGui)
                bg.Size = UDim2.new(1, 0, 1, 0)
                bg.BackgroundColor3 = Color3.new(0, 0, 0)
                bg.BorderSizePixel = 0
                bg.Active = false
                bg.Interactable = false
            end
            
            -- Prioritize CoreGui so UI libraries (usually in CoreGui) render above it
            local targetParent = pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui") or player.PlayerGui
            blackScreenGui.Parent = targetParent
        end)
    else
        pcall(function()
            if blackScreenGui then
                blackScreenGui.Parent = nil
            end
        end)
    end
end

TabSettings:CreateToggleRow({
    Name = " [ Black Screen (Low CPU) ]",
    Callback = toggleBlackScreen,    -- Jika UI parser pakai Callback
    OnToggle = toggleBlackScreen     -- Jika UI parser pakai OnToggle
})

TabSettings:CreateInputRow({
    Name = "UI Toggle Key",
    Placeholder = "Z",
    Default = "Z",
    Callback = function(keyStr)
        Window:SetToggleKey(keyStr)
    end
})

-- ==========================================
-- FLY MENU (W/A/S/D)
-- ==========================================
getgenv()._SKENA_FLY_SPEED = 100
getgenv()._SKENA_FLY = false
RegisterLoop("_SKENA_FLY")

TabSettings:CreateToggleRow({
    Name = " [ Fly Mode (W/A/S/D/Space/LCtrl) ]",
    Callback = function(state)
        getgenv()._SKENA_FLY = state
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if state and hrp and hum then
            task.spawn(function()
                local UIS = game:GetService("UserInputService")
                local RS = game:GetService("RunService")
                while getgenv()._SKENA_FLY and hrp and hrp.Parent and hum.Health > 0 do
                    local dt = RS.Heartbeat:Wait()
                    local cam = workspace.CurrentCamera
                    local moveVec = Vector3.new(0, 0, 0)
                    local speed = getgenv()._SKENA_FLY_SPEED
                    
                    if UIS:IsKeyDown(Enum.KeyCode.W) then moveVec = moveVec + cam.CFrame.LookVector end
                    if UIS:IsKeyDown(Enum.KeyCode.S) then moveVec = moveVec - cam.CFrame.LookVector end
                    if UIS:IsKeyDown(Enum.KeyCode.A) then moveVec = moveVec - cam.CFrame.RightVector end
                    if UIS:IsKeyDown(Enum.KeyCode.D) then moveVec = moveVec + cam.CFrame.RightVector end
                    if UIS:IsKeyDown(Enum.KeyCode.Space) then moveVec = moveVec + Vector3.new(0, 1, 0) end
                    if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then moveVec = moveVec - Vector3.new(0, 1, 0) end
                    
                    if moveVec.Magnitude > 0 then
                        local targetPos = hrp.CFrame + (moveVec.Unit * speed * dt)
                        hrp.CFrame = hrp.CFrame:Lerp(targetPos, 0.8)
                        local randOffset = math.random(-50, 50) / 100
                        hrp.AssemblyLinearVelocity = moveVec.Unit * (speed + randOffset)
                    else
                        hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity * 0.9
                    end
                    
                    if tick() % 2 > 1.9 then
                        hrp.AssemblyLinearVelocity = Vector3.new(0, -0.1, 0)
                    end
                end
            end)
        end
    end,
    OnToggle = function(state) end
})

TabSettings:CreateInputRow({
    Name = "Fly Speed",
    Placeholder = "100",
    Default = "100",
    Callback = function(val)
        getgenv()._SKENA_FLY_SPEED = tonumber(val) or 100
    end
})

-- ==========================================
-- ATTACH ADMIN MODULE
-- ==========================================
task.spawn(function()
    local succ, SkenaAdmin = pcall(function()
        local adminCacheBuster = "?t=" .. tostring(os.time())
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/kndrckm/kndrckm.github.io/refs/heads/main/key/SkenaUI_Admin.lua" .. adminCacheBuster))()
    end)
    if succ and SkenaAdmin then
        SkenaAdmin.Attach(Window, {})
    end
end)
