-- ==========================================
-- SKENA HUB : STOP THE BRAINROTS!
-- Game ID: 91764591674792
-- ==========================================

-- Load Library
local SkenaUI = getgenv().SkenaLoad("SkenaUI_Library.lua")

local player = game.Players.LocalPlayer
local rs = game:GetService("ReplicatedStorage")
local remotes = rs:WaitForChild("Remotes")

-- ==========================================
-- BUAT WINDOW
-- ==========================================
local Window = SkenaUI.CreateWindow("SkenaHub", "Stop The Brainrots!", false)
local TabMain = Window:CreateTab("Main", "zap", false)
local TabUtils = Window:CreateTab("Utils", "wrench", false)
local TabSettings = Window:CreateTab("Settings", "settings", true)

-- ==========================================
-- HELPER: Kill phantom loops
-- ==========================================
pcall(function()
    if getgenv()._SKENA_BRAINROT_LOOPS then
        for _, flag in pairs(getgenv()._SKENA_BRAINROT_LOOPS) do
            getgenv()[flag] = false
        end
    end
end)
getgenv()._SKENA_BRAINROT_LOOPS = {}

local function RegisterLoop(flagName)
    getgenv()[flagName] = false
    table.insert(getgenv()._SKENA_BRAINROT_LOOPS, flagName)
end

-- ==========================================
-- TAB MAIN: AUTO FEATURES
-- ==========================================

-- 1. Auto Collect Cash (Spam)
RegisterLoop("_SKENA_AUTO_COLLECT")
TabMain:CreateToggleRow({
    Name = "Auto Collect Cash",
    OnToggle = function(state)
        getgenv()._SKENA_AUTO_COLLECT = state
        if state then
            task.spawn(function()
                while getgenv()._SKENA_AUTO_COLLECT do
                    pcall(function()
                        remotes.CollectCash:FireServer()
                    end)
                    task.wait(0.1)
                end
            end)
        end
    end
})

-- 2. Auto Claim Free Brainrot
RegisterLoop("_SKENA_AUTO_CLAIM")
TabMain:CreateToggleRow({
    Name = "Auto Claim Free Brainrot",
    OnToggle = function(state)
        getgenv()._SKENA_AUTO_CLAIM = state
        if state then
            task.spawn(function()
                while getgenv()._SKENA_AUTO_CLAIM do
                    pcall(function()
                        remotes.ClaimFreeBrainrot:FireServer()
                    end)
                    task.wait(2)
                end
            end)
        end
    end
})

-- 3. Auto Upgrade Brainrot
RegisterLoop("_SKENA_AUTO_UPGRADE")
TabMain:CreateToggleRow({
    Name = "Auto Upgrade Brainrot",
    OnToggle = function(state)
        getgenv()._SKENA_AUTO_UPGRADE = state
        if state then
            task.spawn(function()
                while getgenv()._SKENA_AUTO_UPGRADE do
                    pcall(function()
                        remotes.UpgradeBrainrot:FireServer()
                    end)
                    task.wait(0.5)
                end
            end)
        end
    end
})

-- 4. Start Game
TabMain:CreateButtonRow({
    Name = "Start Game",
    ButtonText = "Start",
    Callback = function()
        pcall(function()
            remotes.StartGameRequest:FireServer()
        end)
    end
})

TabMain:CreateTextRow({
    Text = "Nyalakan Auto Collect Cash untuk mengumpulkan uang otomatis tanpa perlu menginjak pad hijau."
})

-- ==========================================
-- TAB UTILS: MANUAL BUTTONS
-- ==========================================

-- Open Lucky Block
TabUtils:CreateButtonRow({
    Name = "Open Lucky Block",
    ButtonText = "Open",
    Callback = function()
        pcall(function()
            remotes.OpenLuckyBlock:FireServer()
        end)
    end
})

-- Buy Stand
TabUtils:CreateButtonRow({
    Name = "Buy Stand",
    ButtonText = "Buy",
    Callback = function()
        pcall(function()
            remotes.BuyStand:FireServer()
        end)
    end
})

-- Purchase Weapon Upgrade
TabUtils:CreateButtonRow({
    Name = "Purchase Weapon Upgrade",
    ButtonText = "Upgrade",
    Callback = function()
        pcall(function()
            remotes.PurchaseWeaponUpgrade:FireServer()
        end)
    end
})

-- Purchase Stat Upgrade
TabUtils:CreateButtonRow({
    Name = "Purchase Stat Upgrade",
    ButtonText = "Upgrade",
    Callback = function()
        pcall(function()
            remotes.PurchaseStatUpgrade:FireServer()
        end)
    end
})

-- Rebirth
TabUtils:CreateButtonRow({
    Name = "Rebirth",
    ButtonText = "Rebirth!",
    Callback = function()
        pcall(function()
            remotes.RebirthRequest:FireServer()
        end)
    end
})

-- Skip Lucky Block Timer
TabUtils:CreateButtonRow({
    Name = "Skip Lucky Block Timer",
    ButtonText = "Skip",
    Callback = function()
        pcall(function()
            remotes.RequestSkipLuckyBlockTimer:FireServer()
        end)
    end
})

-- Game Speed Request
TabUtils:CreateButtonRow({
    Name = "Game Speed Request",
    ButtonText = "Speed Up",
    Callback = function()
        pcall(function()
            remotes.GameSpeedRequest:FireServer()
        end)
    end
})

-- Fast Interact (Default ON)
getgenv().SkenaNoDelayInteract = true
task.spawn(function()
    while getgenv().SkenaNoDelayInteract do
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") and v.HoldDuration > 0 then
                v.HoldDuration = 0
            end
        end
        task.wait(1)
    end
end)

TabUtils:CreateToggleRow({
    Name = "Fast Interact (No Hold E)",
    Default = true,
    OnToggle = function(state)
        getgenv().SkenaNoDelayInteract = state
        if state then
            task.spawn(function()
                while getgenv().SkenaNoDelayInteract do
                    for _, v in ipairs(workspace:GetDescendants()) do
                        if v:IsA("ProximityPrompt") and v.HoldDuration > 0 then
                            v.HoldDuration = 0
                        end
                    end
                    task.wait(1)
                end
            end)
        end
    end
})

-- ==========================================
-- TAB SETTINGS
-- ==========================================
TabSettings:CreateTextRow({
    Text = getgenv()._SKENA_ANTI_AFK and "🟢 Anti-AFK Active" or "🔴 Anti-AFK Failed"
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
-- ATTACH ADMIN MODULE
-- ==========================================
task.spawn(function()
    local succ, SkenaAdmin = pcall(function()
        return getgenv().SkenaLoad("SkenaUI_Admin.lua")
    end)
    if succ and SkenaAdmin then
        SkenaAdmin.Attach(Window, {})
    end
end)
