-- ==========================================
-- SKENA HUB : Untitled Melee RNG
-- Game ID: 99248392277037
-- ==========================================

local SkenaUI_LibURL = "https://raw.githubusercontent.com/kndrckm/kndrckm.github.io/refs/heads/main/key/SkenaUI_Library.lua"
local cacheBuster = "?t=" .. tostring(os.time())
local libBody = game:HttpGet(SkenaUI_LibURL .. cacheBuster, true)
local libFunc, libErr = loadstring(libBody)
if not libFunc then error("SkenaUI Library Syntax Error: " .. tostring(libErr)) end
local SkenaUI = libFunc()

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local Window = SkenaUI.CreateWindow("SkenaHub", "Untitled Melee RNG", false)
local TabMain = Window:CreateTab("Main", "zap", false)

-- Kill phantom loops
pcall(function()
    if getgenv()._SKENA_UMR_LOOPS then
        for _, flag in pairs(getgenv()._SKENA_UMR_LOOPS) do
            getgenv()[flag] = false
        end
    end
end)
getgenv()._SKENA_UMR_LOOPS = {}

local function RegisterLoop(flagName)
    getgenv()[flagName] = false
    table.insert(getgenv()._SKENA_UMR_LOOPS, flagName)
end

-- ==========================================
-- TAB MAIN
-- ==========================================

-- Toggle Run: Memaksa karakter berlari layaknya menekan (Shift) dengan mengubah statuslari atau menekan Virtual Input
if getgenv()._SKENA_TOGGLE_RUN == nil then
    getgenv()._SKENA_TOGGLE_RUN = true
end
RegisterLoop("_SKENA_TOGGLE_RUN")

local vim = game:GetService("VirtualInputManager")

task.spawn(function()
    local rs = game:GetService("RunService")
    while task.wait() do
        -- Terus cek agar kalau karakter ada/respawn, kita tekan "LeftShift" di background
        if getgenv()._SKENA_TOGGLE_RUN then
            local char = player.Character
            if char and char:FindFirstChild("Humanoid") then
                pcall(function()
                    vim:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
                end)
            end
        end
    end
end)

TabMain:CreateToggleRow({
    Name = "Toggle Run",
    Default = getgenv()._SKENA_TOGGLE_RUN,
    OnToggle = function(state)
        getgenv()._SKENA_TOGGLE_RUN = state
        if not state then
            -- Release the Shift key holding state as fallback
            pcall(function()
                vim:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
            end)
        end
    end
})

-- Teleports
TabMain:CreateTextRow({
    Text = "── Teleports ──"
})

local function doTP(pos)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = CFrame.new(pos)
    end
end

local TP_ORDERED = {
    { name = "Grassland", pos = Vector3.new(188.961, 35.779, -254.614) },
    { name = "Desert (2x luck, 100 kill)", pos = Vector3.new(260.278, 17.110, -927.792) },
    { name = "Snow (4x luck, 1.5K kill)", pos = Vector3.new(286.322, 16.160, -1581.303) },
    { name = "Jungle (6x luck, 15K kill)", pos = Vector3.new(442.860, 113.981, -2744.834) },
    { name = "Volcano (8x luck, 200K kill)", pos = Vector3.new(668.332, 10.214, -4100.939) }
}

-- Create the Dropdown UI for Teleports
local TPDropdown
TPDropdown = TabMain:CreateDropdownButton({
    Name = "Teleport To",
    ButtonText = "TP",
    Columns = 2,
    Callback = function(val)
        getgenv().SelectedUMR_TP = val
    end,
    OnButton = function()
        local selected = getgenv().SelectedUMR_TP
        if selected then
            for _, loc in ipairs(TP_ORDERED) do
                if loc.name == selected then
                    doTP(loc.pos)
                    break
                end
            end
        end
    end
})

-- Populate the Dropdown with Teleport Locations (preserving exact order)
for i, loc in ipairs(TP_ORDERED) do
    TPDropdown:AddItem(loc.name, i == 1)
    if i == 1 then getgenv().SelectedUMR_TP = loc.name end
end

-- Features
TabMain:CreateTextRow({
    Text = "── Features ──"
})

getgenv()._SKENA_AUTO_SP = false
RegisterLoop("_SKENA_AUTO_SP")

TabMain:CreateToggleRow({
    Name = "Auto Update SP Models",
    OnToggle = function(state)
        getgenv()._SKENA_AUTO_SP = state
        if state then
            task.spawn(function()
                while getgenv()._SKENA_AUTO_SP do
                    pcall(function()
                        local char = player.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            -- Cari ClickDetector/ProximityPrompt terdekat pada mesin upgrade
                            -- Stand in front of the machine to auto click it
                            local fired = false
                            for _, obj in ipairs(workspace:GetDescendants()) do
                                if obj:IsA("ClickDetector") or (obj:IsA("ProximityPrompt") and obj.Enabled) then
                                    local parent = obj.Parent
                                    if parent and parent:IsA("BasePart") then
                                        local dist = (hrp.Position - parent.Position).Magnitude
                                        if dist < 45 then
                                            -- Jika dekat, simulasikan klik/interaction
                                            if obj:IsA("ClickDetector") then
                                                fireclickdetector(obj)
                                            else
                                                fireproximityprompt(obj)
                                            end
                                            fired = true
                                        end
                                    end
                                end
                            end
                            -- Jika ada remote update dengan static arguments, coba panggil fallback. 
                            -- Tapi diutamakan ClickDetector karena harga SP model dinamis.
                            if not fired then
                                local rs = game:GetService("ReplicatedStorage")
                                local remote = rs:FindFirstChild("Remotes") and rs.Remotes:FindFirstChild("UpdateSPModels")
                                if remote then
                                    -- Kadang game menyimpan value yang bisa dibaca di client, tapi kalau tak ada kita biarkan ClickDetector bekerja.
                                end
                            end
                        end
                    end)
                    task.wait(0.5) -- Spam click
                end
            end)
        end
    end
})

TabMain:CreateButtonRow({
    Name = "Open Totem Menu (Must be nearby)",
    ButtonText = "Open",
    Callback = function()
        pcall(function()
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("ProximityPrompt") and obj.ActionText == "Use" then
                    local model = obj:FindFirstAncestorOfClass("Model")
                    if model and (model.Name:lower():find("totem") or model.Name == "Totem of Fortune") then
                        -- Cek jarak supaya gamenya tidak kick karena eksploit jarak jauh
                        local objPart = obj.Parent
                        if objPart and objPart:IsA("BasePart") then
                            local dist = (hrp.Position - objPart.Position).Magnitude
                            if dist < 20 then
                                fireproximityprompt(obj)
                                warn("[Skena Hub] Totem menu triggered.")
                                return
                            else
                                warn("[Skena Hub] Totem terlalu jauh (" .. tostring(math.floor(dist)) .. " studs). Dekati dulu!")
                            end
                        end
                    end
                end
            end
            warn("[Skena Hub] Totem of Fortune tidak ditemukan/tidak aktif di dekatmu.")
        end)
    end
})

getgenv()._SKENA_AUTO_BOSS = false
RegisterLoop("_SKENA_AUTO_BOSS")

TabMain:CreateToggleRow({
    Name = "Auto Boss Raid",
    OnToggle = function(state)
        getgenv()._SKENA_AUTO_BOSS = state
        if state then
            task.spawn(function()
                while getgenv()._SKENA_AUTO_BOSS do
                    pcall(function()
                        local char = player.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if not hrp then return end
                        
                        -- Start Raid process: Try to fire the remote
                        local rs = game:GetService("ReplicatedStorage")
                        local startRaid = rs:FindFirstChild("Remotes") and rs.Remotes:FindFirstChild("StartRaid")
                        if startRaid then
                            startRaid:FireServer(true)
                        end
                        
                        -- Raid Combat Logistics (TP to mobs so auto attack hits them)
                        -- The map often spawns the mob in the workspace, or folders like Npcs or Mobs
                        local minDist = 9e9
                        local targetMobHrp = nil
                        
                        local folders = {workspace:FindFirstChild("Mobs"), workspace:FindFirstChild("Npcs"), workspace:FindFirstChild("Enemies")}
                        for _, folder in ipairs(folders) do
                            if folder then
                                for _, mob in ipairs(folder:GetChildren()) do
                                    if mob:IsA("Model") then
                                        local mHrp = mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart
                                        -- Usually mobs are not players and shouldn't be fully transparent
                                        if mHrp and mHrp.Transparency < 0.9 and (not mHrp.Anchored) then
                                            local dist = (hrp.Position - mHrp.Position).Magnitude
                                            if dist < minDist then
                                                minDist = dist
                                                targetMobHrp = mHrp
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        
                        -- If we found an enemy, float near them (not flying, just TP near them on ground)
                        if targetMobHrp then
                            -- Teleport near the mob (offsetting 3 studs in front/back ideally grounded)
                            hrp.CFrame = targetMobHrp.CFrame * CFrame.new(0, 0, 3)
                            
                            -- Reset velocity to avoid flinging
                            hrp.Velocity = Vector3.new(0,0,0)
                        end
                    end)
                    task.wait(0.2)
                end
            end)
        end
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
