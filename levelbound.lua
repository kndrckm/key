-- ==========================================
-- SKENA HUB : Levelbound
-- Place IDs: 74848159470277, 128981447330754
-- ==========================================

local SkenaUI_LibURL = "https://raw.githubusercontent.com/kndrckm/kndrckm.github.io/refs/heads/main/key/SkenaUI_Library.lua"
local SkenaUI = loadstring(game:HttpGet(SkenaUI_LibURL .. "?t=" .. tostring(os.time()), true))()

-- 1. Buat Window
local Window = SkenaUI.CreateWindow("SkenaHub", "Skena Hub | Levelbound", false)

-- 2. Buat Tab
local TabMain = Window:CreateTab("Main", "zap", false)
local TabVisuals = Window:CreateTab("Visuals", "eye", false)
local TabInvasion = Window:CreateTab("Invasion", "shield", false)
local TabTeleport = Window:CreateTab("Teleport", "map-pin", false)
local TabModifiers = Window:CreateTab("Modifiers", "gamepad-2", false)

-- HELPER: Kill phantom loops
pcall(function()
    if getgenv()._SKENA_LB_LOOPS then
        for _, flag in pairs(getgenv()._SKENA_LB_LOOPS) do
            getgenv()[flag] = false
        end
    end
end)
getgenv()._SKENA_LB_LOOPS = {}

local function RegisterLoop(flagName)
    getgenv()[flagName] = false
    table.insert(getgenv()._SKENA_LB_LOOPS, flagName)
end

-- ==========================================
-- 1. MAIN FEATURES
-- ==========================================

TabMain:CreateToggleRow({
    Name = "Kill Aura Range (WIP)",
    Default = false,
    OnToggle = function(state)
        if state then
            warn("[Auto] Kill Aura Range: ON")
        else
            warn("[Auto] Kill Aura Range: OFF")
        end
    end
})

local KillAuraConnection
TabMain:CreateToggleRow({
    Name = "Kill Aura Melee",
    Default = false,
    OnToggle = function(state)
        if state then
            local placeId = game.PlaceId
            local gameId = game.GameId
            if placeId == 74848159470277 or placeId == 128981447330754 or gameId == 9529182643 then
                local Event = game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("AttackV2")
                warn("[Auto] Kill Aura Melee Levelbound: ON")
                
                KillAuraConnection = game:GetService("RunService").Heartbeat:Connect(function()
                    local char = game.Players.LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    local charactersFolder = workspace:FindFirstChild("Characters")
                    
                    if hrp and charactersFolder then
                        local closestEnemyID = nil
                        local shortestDist = 20 -- radius 20 studs
                        
                        -- Cari musuh di dalam folder Characters
                        for _, obj in pairs(charactersFolder:GetChildren()) do
                            -- Pastikan dia model, bukan player (char sendiri), tidak ada label (NPC)
                            if obj:IsA("Model") and obj ~= char and not string.find(obj.Name, "%(NPC%)") then
                                local enemyHrp = obj:FindFirstChild("HumanoidRootPart")
                                local enemyHum = obj:FindFirstChild("Humanoid")
                                
                                if enemyHrp and enemyHum and enemyHum.Health > 0 then
                                    local dist = (hrp.Position - enemyHrp.Position).Magnitude
                                    if dist < shortestDist then
                                        -- Ekstrak ID dari nama (Contoh: "Goblin [2]" -> 2)
                                        local idMatch = string.match(obj.Name, "%[(%d+)%]$")
                                        if idMatch then
                                            shortestDist = dist
                                            closestEnemyID = tonumber(idMatch)
                                        end
                                    end
                                end
                            end
                        end
                        
                        if closestEnemyID then
                            -- Simulasi swing sequence berdasarkan log
                            local lv = hrp.CFrame.LookVector
                            local dirStr = string.format("%.2f:%.2f:%.2f", lv.X, lv.Y, lv.Z)
                            
                            Event:FireServer(1, 1) -- Memulai Ayun
                            Event:FireServer(4, 1, nil, dirStr) -- Inject koordinat penglihatan
                            Event:FireServer(2, 1, {closestEnemyID}) -- Hit Type 2 -> Kirim ID Angka!
                            Event:FireServer(2, 1, {closestEnemyID})
                            Event:FireServer(5, 1, {closestEnemyID}) -- Hit Type 5
                            Event:FireServer(5, 1, {closestEnemyID})
                            Event:FireServer(3, 1) -- Selesai Ayun
                        end
                    end
                end)
            else
                warn("[Auto] Kill Aura Melee: ON (Not Levelbound)")
            end
        else
            warn("[Auto] Kill Aura Melee: OFF")
            if KillAuraConnection then
                KillAuraConnection:Disconnect()
                KillAuraConnection = nil
            end
        end
    end
})

RegisterLoop("_SKENALB_AUTO_DAILY")
TabMain:CreateToggleRow({
    Name = "Auto Claim Daily Quest (WIP)",
    Default = false,
    OnToggle = function(state)
        getgenv()._SKENALB_AUTO_DAILY = state
        -- Placeholder
    end
})

RegisterLoop("_SKENALB_AUTO_SKILL")
TabMain:CreateToggleRow({
    Name = "Auto Skill (WIP)",
    Default = false,
    OnToggle = function(state)
        getgenv()._SKENALB_AUTO_SKILL = state
        -- Placeholder
    end
})

getgenv()._SKENALB_HITBOX_SIZE = 10

TabMain:CreateSliderRow({
    Name = "Hitbox Size",
    Min = 2,
    Max = 100,
    Default = 30,
    Suffix = " studs",
    Callback = function(val)
        getgenv()._SKENALB_HITBOX_SIZE = val
    end
})

local function handleHitboxToggle(state)
    getgenv()._SKENALB_HITBOX_EXPANDER = state
    if state then
        warn("[Auto] Hitbox Expander: ON")
        task.spawn(function()
            while getgenv()._SKENALB_HITBOX_EXPANDER do
                local charFolder = workspace:FindFirstChild("Characters")
                if charFolder then
                    for _, enemyModel in pairs(charFolder:GetChildren()) do
                        if enemyModel:IsA("Model") and enemyModel ~= game.Players.LocalPlayer.Character and not string.find(enemyModel.Name, "%(NPC%)") then
                            local charHitbox = enemyModel:FindFirstChild("CharHitbox")
                            if charHitbox and charHitbox:IsA("Part") then
                                local s = getgenv()._SKENALB_HITBOX_SIZE or 10
                                charHitbox.Size = Vector3.new(s, s, s)
                                charHitbox.Transparency = 1
                                charHitbox.CanCollide = false
                                
                                if not charHitbox:FindFirstChild("SkenaBoxLine") then
                                    local sel = Instance.new("SelectionBox")
                                    sel.Name = "SkenaBoxLine"
                                    sel.Adornee = charHitbox
                                    sel.LineThickness = 0.01
                                    sel.Color3 = Color3.fromRGB(255, 0, 0)
                                    sel.Parent = charHitbox
                                end
                            end
                        end
                    end
                end

                -- Tampilkan jebakan/hitbox lain tanpa mengubah ukuran aslinya
                local localChar = game.Players.LocalPlayer.Character
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("Part") and (obj.Name == "Hitbox" or obj.BrickColor == BrickColor.new("Bright red") or obj.BrickColor == BrickColor.new("Really red")) then
                        if obj.Parent and (not localChar or not obj:IsDescendantOf(localChar)) and obj.Name ~= "CharHitbox" then
                            -- Tidak mengubah obj.Size agar ukurannya tetap asli (terutama untuk area jebakan)
                            obj.Transparency = 0.7 -- Buat agar terlihat/semi-transparan
                            
                            -- Hapus outline lama jika ada
                            if obj:FindFirstChild("SkenaBoxLine") then
                                obj.SkenaBoxLine:Destroy()
                            end
                        end
                    end
                end
                
                -- Tunggu 1 detik sebelum mengecek lagi, ini sangat penting untuk mencegah lag ekstrim!
                task.wait(1)
            end
        end)
    else
        warn("[Auto] Hitbox Expander: OFF")
    end
end

getgenv()._SKENALB_HITBOX_KEY = "r"
local HitboxToggleObj = TabMain:CreateToggleRow({
    Name = "Hitbox Expander",
    Default = false,
    HasKey = true,
    DefaultKey = getgenv()._SKENALB_HITBOX_KEY,
    OnKeyChange = function(newKey)
        getgenv()._SKENALB_HITBOX_KEY = string.lower(newKey)
    end,
    OnToggle = handleHitboxToggle
})

game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode.Name:lower() == getgenv()._SKENALB_HITBOX_KEY then
        local newState = not getgenv()._SKENALB_HITBOX_EXPANDER
        if HitboxToggleObj and HitboxToggleObj.ToggleState then
            HitboxToggleObj.ToggleState(newState)
        end
        handleHitboxToggle(newState)
    end
end)

-- ==========================================
-- 2. VISUALS
-- ==========================================

TabVisuals:CreateSliderRow({
    Name = "ESP Range (WIP)",
    Min = 10,
    Max = 500,
    Default = 100,
    Suffix = " studs",
    Callback = function(val)
        -- Placeholder
    end
})

local visualToggles = {"Chest ESP", "Enemy ESP", "Ruby ESP", "Altar ESP"}
for _, name in ipairs(visualToggles) do
    TabVisuals:CreateToggleRow({
        Name = name .. " (WIP)",
        Default = false,
        OnToggle = function(state)
            -- Placeholder
        end
    })
end

-- ==========================================
-- 3. INVASION & TELEPORT
-- ==========================================

TabInvasion:CreateButtonRow({
    Name = "Join Dungeon as PK (WIP)",
    ButtonText = "Join",
    Callback = function()
        warn("[Action] Joining Dungeon as PK...")
    end
})

TabInvasion:CreateToggleRow({
    Name = "Auto Farm Invasion (WIP)",
    Default = false,
    OnToggle = function(state)
        -- Placeholder
    end
})

TabTeleport:CreateButtonRow({
    Name = "Teleport Settings [GUI] (WIP)",
    ButtonText = "Setup",
    Callback = function()
        warn("[Info] Gunakan Dropdown di layar utama untuk setup Dungeon")
    end
})

local tpMods = {"Lucky Dungeon", "Invasions", "Ghostified", "Private Group", "Solo Mode"}
for _, name in ipairs(tpMods) do
    TabTeleport:CreateToggleRow({
        Name = name .. " (WIP)",
        Default = false,
        OnToggle = function(state)
            -- Placeholder
        end
    })
end

TabTeleport:CreateButtonRow({
    Name = "Create Dungeon Group (WIP)",
    ButtonText = "Create",
    Callback = function()
        warn("[Action] Creating Dungeon Group...")
    end
})

-- ==========================================
-- 4. MODIFIERS
-- ==========================================

local gameMods = {
    "No EXP Lose", 
    "Elite Enemies Only", 
    "Mobs 2x HP", 
    "No Campfires", 
    "Reduce Damage By...", 
    "Damage 2x"
}

for _, modName in ipairs(gameMods) do
    TabModifiers:CreateToggleRow({
        Name = modName .. " (WIP)",
        Default = false,
        OnToggle = function(state)
            -- Placeholder
        end
    })
end

-- ==========================================
-- ATTACH ADMIN MODULE
-- ==========================================
task.spawn(function()
    local succ, SkenaAdmin = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/kndrckm/kndrckm.github.io/refs/heads/main/key/SkenaUI_Admin.lua?t=" .. tostring(os.time())))()
    end)
    if succ and SkenaAdmin then
        SkenaAdmin.Attach(Window, {})
    end
end)
