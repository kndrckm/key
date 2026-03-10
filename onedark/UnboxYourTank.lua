-- =============================================
-- SKENA HUB : UNBOX YOUR TANK
-- =============================================

-- 1. Load Library
local SkenaUI
local success, err = pcall(function()
    SkenaUI = getgenv().SkenaLoad("SkenaUI_Library.lua")
end)

if not success or not SkenaUI then
    warn("[SkenaUI] Gagal memuat UI Library: ", err)
    return
end

-- 2. Create Window
local Window = SkenaUI.CreateWindow("SkenaHub", "Unbox Your Tank", false)

-- 3. Load Admin Panel
local adminLoaded, SkenaAdmin = pcall(function()
    return getgenv().SkenaLoad("SkenaUI_Admin.lua")
end)

if adminLoaded and SkenaAdmin then
    SkenaAdmin.Attach(Window, {})
else
    warn("[SkenaUI] Gagal memuat Admin Module atau Anda tidak di-whitelist.")
end

-- 4. Main Script Features
local TabMain = Window:CreateTab("Main", "home")

TabMain:CreateTextRow({
    Text = "Game: Unbox Your Tank"
})

-- Auto Collect Money via Physical Touch (Teleport)
TabMain:CreateToggleRow({
    Name = "Auto Collect Money (Teleport)",
    OnToggle = function(state)
        getgenv()._SKENA_AUTO_COLLECT_TP = state
        if state then
            task.spawn(function()
                while getgenv()._SKENA_AUTO_COLLECT_TP do
                    pcall(function()
                        local player = game.Players.LocalPlayer
                        local char = player.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        local plotName = player.Name .. " Plot"
                        local plot = workspace:FindFirstChild("Plots") and workspace.Plots:FindFirstChild(plotName)
                        
                        if hrp and plot then
                            local podiumsFolder = plot:FindFirstChild("PodiumFloorParts")
                            if podiumsFolder then
                                local originalPos = hrp.CFrame
                                
                                for i = 1, 8 do
                                    if not getgenv()._SKENA_AUTO_COLLECT_TP then break end
                                    local targetPart = podiumsFolder:FindFirstChild(tostring(i))
                                    if targetPart and targetPart:IsA("BasePart") then
                                        hrp.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
                                        task.wait(0.2)
                                        
                                        pcall(function()
                                            local event = game:GetService("ReplicatedStorage"):FindFirstChild("CollectMoney")
                                                or game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                                                    and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("CollectMoney")
                                            if event then
                                                event:FireServer()
                                            end
                                        end)
                                    end
                                end
                                
                                hrp.CFrame = originalPos
                            end
                        end
                    end)
                    task.wait(1)
                end
            end)
        end
    end
})

-- Auto Open Tank
TabMain:CreateToggleRow({
    Name = "Auto Open Tank",
    OnToggle = function(state)
        getgenv()._SKENA_AUTO_OPEN_TANK = state
        if state then
            task.spawn(function()
                while getgenv()._SKENA_AUTO_OPEN_TANK do
                    pcall(function()
                        local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                        if remotes then
                            local openEvent = remotes:FindFirstChild("OpenTank") or remotes:FindFirstChild("Unbox")
                            if openEvent then
                                openEvent:FireServer()
                            end
                        end
                    end)
                    task.wait(0.5)
                end
            end)
        end
    end
})
