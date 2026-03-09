-- =============================================
-- SKENA HUB : STOP THE BRAINROTS!
-- Game ID: 917645916747920
-- =============================================

-- Load Library
local SkenaUI = getgenv().SkenaLoad("SkenaUI_Library.lua")

local player = game.Players.LocalPlayer
local rs = game:GetService("ReplicatedStorage")
local remotes = rs:WaitForChild("Remotes")

-- =============================================
-- BUAT WINDOW
-- =============================================
local Window = SkenaUI.CreateWindow("SkenaHub", "Stop The Brainrots!", false)
local TabMain = Window:CreateTab("Main", "zap", false)
local TabUtils = Window:CreateTab("Utils", "wrench", false)
local TabSettings = Window:CreateTab("Settings", "settings", true)

-- =============================================
-- HELPER: Kill phantom loops
-- =============================================
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

-- =============================================
-- TAB MAIN: AUTO FEATURES
-- =============================================

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
            remotes.StartGame:FireServer()
        end)
    end
})

-- 5. Auto Start Game
RegisterLoop("_SKENA_AUTO_START")
TabMain:CreateToggleRow({
    Name = "Auto Start Game",
    OnToggle = function(state)
        getgenv()._SKENA_AUTO_START = state
        if state then
            task.spawn(function()
                while getgenv()._SKENA_AUTO_START do
                    pcall(function()
                        remotes.StartGame:FireServer()
                    end)
                    task.wait(1)
                end
            end)
        end
    end
})

-- =============================================
-- TAB UTILS
-- =============================================

-- Anti-AFK
TabUtils:CreateToggleRow({
    Name = "Anti-AFK",
    Default = getgenv()._SKENA_ANTI_AFK or false,
    OnToggle = function(state)
        getgenv()._SKENA_ANTI_AFK = state
    end
})

-- Rejoin Server
TabUtils:CreateButtonRow({
    Name = "Rejoin Server",
    ButtonText = "Rejoin",
    Callback = function()
        local TeleportService = game:GetService("TeleportService")
        TeleportService:Teleport(game.PlaceId, game.Players.LocalPlayer)
    end
})

-- Copy PlaceId
TabUtils:CreateButtonRow({
    Name = "Copy PlaceId",
    ButtonText = "Copy",
    Callback = function()
        if setclipboard then
            setclipboard(tostring(game.PlaceId))
        end
    end
})

-- =============================================
-- TAB SETTINGS (auto-created by Library)
-- =============================================
