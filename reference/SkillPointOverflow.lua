-- ==========================================
-- +1 SKILL POINT TYPE GAME (Reference Script)
-- Mob Aura, Kill All Players, Infinite SP
-- Pattern: __THINGS/__REMOTES/dealdamage & update_stats
-- Credits: Vade Hub
-- ==========================================
-- Techniques:
--   dealdamage:FireServer({{"Melee", position, target}})
--   update_stats:FireServer({{"Magic Damage", 1e15}}) then negative to get SP overflow

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

if CoreGui:FindFirstChild("VadeHub") then
    CoreGui.VadeHub:Destroy()
end

local Things = Workspace:FindFirstChild("__THINGS")
local Remotes = Things and Things:FindFirstChild("__REMOTES")
local DamageRemote = Remotes and Remotes:FindFirstChild("dealdamage")
local StatsRemote = Remotes and Remotes:FindFirstChild("update_stats")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VadeHub"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 260, 0, 280)
MainFrame.Position = UDim2.new(0.5, -130, 0.5, -140)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 0, 40)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Vade Hub"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Parent = MainFrame
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

local function CreateButton(text, pos, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 40)
    btn.Position = pos
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.Parent = MainFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local MobAuraBtn = CreateButton("Mob Aura: OFF", UDim2.new(0.05, 0, 0.18, 0), Color3.fromRGB(180, 40, 40))
local PlayerAuraBtn = CreateButton("Kill All Players: OFF", UDim2.new(0.05, 0, 0.36, 0), Color3.fromRGB(180, 40, 40))
local SetSPBtn = CreateButton("Give Infinite SP", UDim2.new(0.05, 0, 0.54, 0), Color3.fromRGB(60, 60, 70))
local BindBtn = CreateButton("Keybind: RightControl", UDim2.new(0.05, 0, 0.78, 0), Color3.fromRGB(45, 45, 50))

local isMobAuraOn = false
local isPlayerAuraOn = false
local currentKey = Enum.KeyCode.RightControl
local isBinding = false

task.spawn(function()
    while task.wait(0.2) do
        if isMobAuraOn and DamageRemote then
            for _, folder in pairs(Things:GetChildren()) do
                if folder:IsA("Folder") and folder.Name ~= "__REMOTES" then
                    for _, entity in pairs(folder:GetChildren()) do
                        pcall(function()
                            if entity:IsA("Model") or entity:IsA("BasePart") then
                                DamageRemote:FireServer(unpack({{"Melee", entity:GetPivot().Position, entity}}))
                            end
                        end)
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if isPlayerAuraOn and DamageRemote then
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    pcall(function()
                        DamageRemote:FireServer(unpack({{"Melee", plr.Character.HumanoidRootPart.Position, plr.Character}}))
                    end)
                end
            end
        end
    end
end)

MobAuraBtn.MouseButton1Click:Connect(function()
    isMobAuraOn = not isMobAuraOn
    MobAuraBtn.Text = isMobAuraOn and "Mob Aura: ON" or "Mob Aura: OFF"
    MobAuraBtn.BackgroundColor3 = isMobAuraOn and Color3.fromRGB(40, 160, 40) or Color3.fromRGB(180, 40, 40)
end)

PlayerAuraBtn.MouseButton1Click:Connect(function()
    isPlayerAuraOn = not isPlayerAuraOn
    PlayerAuraBtn.Text = isPlayerAuraOn and "Kill All Players: ON" or "Kill All Players: OFF"
    PlayerAuraBtn.BackgroundColor3 = isPlayerAuraOn and Color3.fromRGB(40, 160, 40) or Color3.fromRGB(180, 40, 40)
end)

SetSPBtn.MouseButton1Click:Connect(function()
    if StatsRemote then
        pcall(function()
            StatsRemote:FireServer(unpack({{"Magic Damage", 1000000000000000}}))
            StatsRemote:FireServer(unpack({{"Magic Damage", -1000000000000000}}))
            SetSPBtn.Text = "SUCCESS!"
            task.wait(1)
            SetSPBtn.Text = "Give Infinite SP"
        end)
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

BindBtn.MouseButton1Click:Connect(function()
    isBinding = true
    BindBtn.Text = "Press any key..."
end)

UIS.InputBegan:Connect(function(input, processed)
    if isBinding then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            currentKey = input.KeyCode
            BindBtn.Text = "Keybind: " .. input.KeyCode.Name
            isBinding = false
        end
    elseif not processed then
        if input.KeyCode == currentKey then
            MainFrame.Visible = not MainFrame.Visible
        end
    end
end)
