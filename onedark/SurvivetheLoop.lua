local SkenaUI

local success, err = pcall(function()
    SkenaUI = getgenv().SkenaLoad("SkenaUI_Library.lua")
end)

if not success or not SkenaUI then warn("Gagal memuat UI Library SkenaHub"); return end

-- ==========================================
-- INISIALISASI VARIABEL & SISTEM
-- ==========================================
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer

-- Cleanup Previous Executions (Pastikan hanya 1 script yang jalan)
local env = getgenv and getgenv() or shared
if env.SkenaHub_Connections then
    for _, conn in pairs(env.SkenaHub_Connections) do
        conn:Disconnect()
    end
end
env.SkenaHub_Connections = {}
local connections = env.SkenaHub_Connections

-- State Variables
local espEnabled = false
local flyEnabled = false
local autoMoveEnabled = false
local autoTpLowHpEnabled = false

local tpThreshold = 50 
local hasTeleportedForLowHp = false 
local flySpeed = 300
local flyKey = Enum.KeyCode.X
local strafeKey = Enum.KeyCode.C

local function doSafeTeleport()
    local char = player.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    hrp.CFrame = hrp.CFrame + Vector3.new(50, 100, 50)
    return true
end

local espFolder = nil
local function clearESP()
    if espFolder then espFolder:Destroy() end
    espFolder = nil
end

local function addHighlight(target)
    if not espFolder then return end
    if target:IsA("ProximityPrompt") or target:IsA("ClickDetector") then
        local parent = target.Parent
        if parent and not espFolder:FindFirstChild(parent.Name .. "_ESP") then
            local hl = Instance.new("Highlight")
            hl.Name = parent.Name .. "_ESP"
            hl.Adornee = parent
            hl.FillTransparency = 1
            hl.OutlineTransparency = 0
            hl.OutlineColor = Color3.fromRGB(0, 255, 0)
            hl.Parent = espFolder
            
            local bb = Instance.new("BillboardGui")
            bb.Size = UDim2.new(0, 100, 0, 20)
            bb.StudsOffset = Vector3.new(0, 2, 0)
            bb.AlwaysOnTop = true
            bb.Parent = hl
            local txt = Instance.new("TextLabel")
            txt.Size = UDim2.new(1, 0, 1, 0)
            txt.BackgroundTransparency = 1
            txt.Text = parent.Name
            txt.TextColor3 = Color3.new(1,1,1)
            txt.TextStrokeTransparency = 0
            txt.Font = Enum.Font.GothamBold
            txt.TextSize = 12
            txt.Parent = bb
        end
    end
end

local function applyFly(state)
    flyEnabled = state
    local c = player.Character
    if flyEnabled then
        if c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChild("Humanoid") then
            local hrp = c.HumanoidRootPart
            local bg = Instance.new("BodyGyro", hrp); bg.Name = "FlyGyro"; bg.P = 9e4; bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            local bv = Instance.new("BodyVelocity", hrp); bv.Name = "FlyVel"; bv.MaxForce = Vector3.new(9e9, 9e9, 9e9); bv.Velocity = Vector3.new(0,0,0)
            c.Humanoid.PlatformStand = true
        end
    else
        if c and c:FindFirstChild("HumanoidRootPart") then
            if c.HumanoidRootPart:FindFirstChild("FlyGyro") then c.HumanoidRootPart.FlyGyro:Destroy() end
            if c.HumanoidRootPart:FindFirstChild("FlyVel") then c.HumanoidRootPart.FlyVel:Destroy() end
            if c:FindFirstChild("Humanoid") then c.Humanoid.PlatformStand = false end
        end
    end
end

-- ==========================================
-- MEMBUAT WINDOW SKENAHUB (Dynamic Game Title)
-- ==========================================
local Window = SkenaUI:CreateWindow({Name = "SkenaHub - Loading..."})

-- Auto grab judul game berdasarkan PlaceId
task.spawn(function()
    local success, info = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
    end)
    if success and info and info.Name then
        Window:SetTitle("SkenaHub - " .. info.Name .. " Helper")
    else
        -- Jika gagal fetch (misal koneksi atau private place), fallback manual
        Window:SetTitle("SkenaHub - Survive the Loop Helper")
    end
end)

-- Icon Tab menggunakan teks sederhana berkat integrasi Lucide Icons
local TabMods = Window:CreateTab("Player Mods", "eye")
local TabSettings = Window:CreateTab("Settings", "settings", true)

-- ==========================================
-- ISI TAB PLAYER MODS
-- ==========================================

local rowFly = TabMods:CreateToggleRow({
    Name = "Fly Mod",
    HasSpeed = true, DefaultSpeed = "300",
    HasKey = true, DefaultKey = "X",
    OnSpeedChange = function(newSpeed) flySpeed = tonumber(newSpeed) or flySpeed end,
    OnKeyChange = function(newKey)
        local key = Enum.KeyCode[string.upper(newKey)]
        if key then flyKey = key end
    end,
    OnToggle = function(state)
        applyFly(state)
    end
})

local rowStrafe = TabMods:CreateToggleRow({
    Name = "Auto Strafe",
    HasKey = true, DefaultKey = "C",
    OnKeyChange = function(newKey)
        local key = Enum.KeyCode[string.upper(newKey)]
        if key then strafeKey = key end
    end,
    OnToggle = function(state)
        autoMoveEnabled = state
    end
})

TabMods:CreateToggleRow({
    Name = "Auto TP (Low HP)",
    OnToggle = function(state)
        autoTpLowHpEnabled = state
        hasTeleportedForLowHp = false
    end
})

TabMods:CreateSliderRow({
    Name = "TP Threshold",
    Min = 10,
    Max = 90,
    Default = 50,
    Suffix = "%",
    Callback = function(val)
        tpThreshold = val
    end
})

TabMods:CreateToggleRow({
    Name = "ESP Node Visualize",
    OnToggle = function(state)
        espEnabled = state
        if espEnabled then
            clearESP()
            espFolder = Instance.new("Folder")
            espFolder.Name = "SkenaHubESP"

            -- Coba taro di CoreGui, jika executor tdk support, taruh di PlayerGui
            local s = pcall(function() espFolder.Parent = CoreGui end)
            if not s then espFolder.Parent = player:WaitForChild("PlayerGui") end

            for _, v in pairs(workspace:GetDescendants()) do addHighlight(v) end
            table.insert(connections, workspace.DescendantAdded:Connect(addHighlight))
        else
            clearESP()
        end
    end
})

-- ==========================================
-- ISI TAB SETTINGS
-- ==========================================
TabSettings:CreateTextRow({
    Text = getgenv()._SKENA_ANTI_AFK and "Anti-AFK Active" or "Anti-AFK Failed"
})

TabSettings:CreateInputRow({
    Name = "Menu Toggle Key",
    Default = "Z",
    Placeholder = "Key",
    Callback = function(val)
        Window:SetToggleKey(val)
    end
})

-- ==========================================
-- RENDERING LOOP & HOTKEYS
-- ==========================================
table.insert(connections, game:GetService("RunService").RenderStepped:Connect(function(dt)
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")

    if autoTpLowHpEnabled and hum and hrp then
        local hpPercent = (hum.Health / hum.MaxHealth) * 100
        if hpPercent <= tpThreshold and not hasTeleportedForLowHp and hum.Health > 0 then
            local success = doSafeTeleport()
            if success then hasTeleportedForLowHp = true end
        elseif hpPercent > tpThreshold then
            hasTeleportedForLowHp = false
        end
    end

    if flyEnabled and hrp and hum then
        local bg = hrp:FindFirstChild("FlyGyro")
        local bv = hrp:FindFirstChild("FlyVel")
        if bg and bv then
            local camCF = workspace.CurrentCamera.CFrame
            bg.CFrame = camCF
            local moveDir = Vector3.new()

            if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCF.LookVector end
            if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCF.LookVector end
            if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCF.RightVector end
            if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCF.RightVector end

            if autoMoveEnabled then moveDir = moveDir + (camCF.RightVector * math.sin(tick() * 5)) end
            bv.Velocity = moveDir.Magnitude > 0 and (moveDir.Unit * flySpeed) or Vector3.new(0,0,0)
        end
    elseif autoMoveEnabled and not flyEnabled and hum then
        hum:Move(workspace.CurrentCamera.CFrame.RightVector * math.sin(tick() * 5), false)
    end
end))

-- Bind Hotkeys
table.insert(connections, game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == strafeKey then
        autoMoveEnabled = not autoMoveEnabled
        if rowStrafe and rowStrafe.ToggleState then rowStrafe.ToggleState(autoMoveEnabled) end
    elseif input.KeyCode == flyKey then
        flyEnabled = not flyEnabled
        if rowFly and rowFly.ToggleState then rowFly.ToggleState(flyEnabled) end
        applyFly(flyEnabled)
    end
end))
