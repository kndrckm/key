local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer

-- ==========================================
-- CLEANUP OLD MEMORY
-- ==========================================
pcall(function()
    getgenv().SkenaAutoFarm_Jagung = false
    getgenv().SkenaAutoFarm_Crop = false
    getgenv().SkenaAutoFarm_Egg = false
    getgenv()._SKENA_CALIBRATING = false
end)

-- ==========================================
-- INIT SKENA UI
-- ==========================================
local SkenaUI_Loaded = false
local SkenaUI
pcall(function()
    SkenaUI = getgenv().SkenaLoad("SkenaUI_Library.lua")
    SkenaUI_Loaded = true
end)

if not SkenaUI_Loaded then
    warn("Koneksi gagal ke SkenaUI_Library. Hubungkan ke Internet.")
    return
end

local GameName = "SAWAH indo Finder"
local success, info = pcall(function()
    return MarketplaceService:GetProductInfo(game.PlaceId)
end)
if success and info and info.Name then
    GameName = info.Name .. " Hub"
end

local Window = SkenaUI:CreateWindow({
    Name = "SkenaHub - " .. GameName
})

local TabAutoFarm1 = Window:CreateTab("Auto Farm 1", "wheat") 
local TabAutoFarm2 = Window:CreateTab("Auto Farm 2", "egg") 
local TabFarming = Window:CreateTab("Farming", "shovel") 
local TabSettings = Window:CreateTab("Settings", "settings", true) 

-- ==========================================
-- GLOBAL SETTINGS & CROP DATA 
-- ==========================================
getgenv().AFK_PlantAmount = 15
getgenv().AFK_HarvestDelay = 60
getgenv().SelectedCrop_AF1 = "Padi"
getgenv().SelectedCrop_Manual = "Padi"
getgenv().SkenaPlantPauseTime = 0

if not getgenv().SkenaNamecallHooked and hookmetamethod then
    getgenv().SkenaNamecallHooked = true
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        if method == "FireServer" and tostring(self.Name) == "Notification" then
            if type(args[1]) == "string" and string.find(args[1], "Maximum 15 crops!") then
                getgenv().SkenaPlantPauseTime = os.clock() + 30
            end
        end
        return oldNamecall(self, ...)
    end))
end

getgenv().SkenaSession = {
    StartTime = os.clock(),
    TotalSold = 0,
    TotalEarned = 0
}

local function FormatNumber(n)
    local formatted = tostring(math.floor(tonumber(n) or 0))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return formatted
end

local CROP_DATA = {
    ["Padi"]       = { SeedName = "Bibit Padi",       EnglishName = "Rice",       Price = 10 },
    ["Jagung"]     = { SeedName = "Bibit Jagung",     EnglishName = "Corn",       Price = 20 },
    ["Tomat"]      = { SeedName = "Bibit Tomat",      EnglishName = "Tomato",     Price = 30 },
    ["Terong"]     = { SeedName = "Bibit Terong",     EnglishName = "Eggplant",   Price = 50 },
    ["Strawberry"] = { SeedName = "Bibit Strawberry", EnglishName = "Strawberry", Price = 75 }
}

local CROP_ORDER = {
    { key = "Padi",       label = "Padi [lv. 0]" },
    { key = "Jagung",     label = "Jagung [lv. 20]" },
    { key = "Tomat",      label = "Tomat [lv. 40]" },
    { key = "Terong",     label = "Terong [lv. 60]" },
    { key = "Strawberry", label = "Strawberry [lv. 80]" },
}

local function UpdateSelectedCrop_AF1(val)
    for _, entry in ipairs(CROP_ORDER) do
        if entry.label == val or entry.key == val then
            getgenv().SelectedCrop_AF1 = entry.key
            warn("Target AFK Tanaman: " .. entry.key)
            return
        end
    end
    getgenv().SelectedCrop_AF1 = val
end

local function UpdateSelectedCrop_Manual(val)
    for _, entry in ipairs(CROP_ORDER) do
        if entry.label == val or entry.key == val then
            getgenv().SelectedCrop_Manual = entry.key
            warn("Target Manual Tanaman: " .. entry.key)
            return
        end
    end
    getgenv().SelectedCrop_Manual = val
end

local function GetCropInventoryCount(itemName)
    local count = 0
    local rs = game:GetService("ReplicatedStorage")
    pcall(function()
        local inv = rs.Remotes.TutorialRemotes.RequestSell:InvokeServer("GET_LIST")
        if typeof(inv) == "table" and typeof(inv.Items) == "table" then
            for _, itemData in pairs(inv.Items) do
                if typeof(itemData) == "table" and tonumber(itemData.Owned) then
                    local name = itemData.Name or itemData.DisplayName
                    if string.find(string.lower(name), string.lower(itemName)) then
                        count = count + tonumber(itemData.Owned)
                    end
                end
            end
        end
    end)
    return count
end

local function SellTargetCrop(cropKey)
    local rs = game:GetService("ReplicatedStorage")
    local remotes = rs.Remotes.TutorialRemotes
    local totalSold = 0
    local cData = CROP_DATA[cropKey]
    if not cData then return 0 end

    pcall(function()
        local inv = remotes.RequestSell:InvokeServer("GET_LIST")
        if typeof(inv) == "table" and typeof(inv.Items) == "table" then
            for _, itemData in pairs(inv.Items) do
                if typeof(itemData) == "table" and tonumber(itemData.Owned) and tonumber(itemData.Owned) > 0 then
                    local name = itemData.Name or itemData.DisplayName
                    if string.find(string.lower(name), string.lower(cData.EnglishName)) or string.find(string.lower(name), string.lower(cropKey)) then
                        local amt = tonumber(itemData.Owned)
                        local price = tonumber(itemData.SellPrice) or tonumber(itemData.Price) or cData.Price or 0
                        pcall(function()
                            remotes.RequestSell:InvokeServer("SELL", name, amt)
                        end)
                        totalSold = totalSold + amt
                        if getgenv().SkenaSession then
                            getgenv().SkenaSession.TotalSold = getgenv().SkenaSession.TotalSold + amt
                            getgenv().SkenaSession.TotalEarned = getgenv().SkenaSession.TotalEarned + (amt * price)
                        end
                        task.wait(0.3)
                    end
                end
            end
        end
    end)
    return totalSold
end

local function CreateTracker()
    pcall(function()
        if game.CoreGui:FindFirstChild("SkenaAFKHUD") then game.CoreGui.SkenaAFKHUD:Destroy() end
        if player.PlayerGui:FindFirstChild("SkenaAFKHUD") then player.PlayerGui.SkenaAFKHUD:Destroy() end
    end)
    local sg = Instance.new("ScreenGui")
    sg.Name = "SkenaAFKHUD"
    if not pcall(function() sg.Parent = game:GetService("CoreGui") end) then
        sg.Parent = player.PlayerGui
    end
    local frm = Instance.new("Frame", sg)
    frm.Size = UDim2.new(0, 220, 0, 95)
    frm.Position = UDim2.new(1, -240, 1, -120)
    frm.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
    Instance.new("UICorner", frm).CornerRadius = UDim.new(0, 6)
    local stroke = Instance.new("UIStroke", frm)
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(60, 60, 60)
    local lblTitle = Instance.new("TextLabel", frm)
    lblTitle.Size = UDim2.new(1, 0, 0, 22)
    lblTitle.BackgroundTransparency = 1
    lblTitle.Text = "  [AFK Tracker]"
    lblTitle.Font = Enum.Font.GothamBold
    lblTitle.TextColor3 = Color3.new(1,1,1)
    lblTitle.TextSize = 13
    lblTitle.TextXAlignment = Enum.TextXAlignment.Left
    local lblStat = Instance.new("TextLabel", frm)
    lblStat.Size = UDim2.new(1, -16, 0, 18)
    lblStat.Position = UDim2.new(0, 8, 0, 30)
    lblStat.BackgroundTransparency = 1
    lblStat.Text = "Uptime: 00:00:00"
    lblStat.Font = Enum.Font.GothamMedium
    lblStat.TextColor3 = Color3.fromRGB(200, 200, 200)
    lblStat.TextSize = 12
    lblStat.TextXAlignment = Enum.TextXAlignment.Left
    local lblNext = Instance.new("TextLabel", frm)
    lblNext.Size = UDim2.new(1, -16, 0, 18)
    lblNext.Position = UDim2.new(0, 8, 0, 50)
    lblNext.BackgroundTransparency = 1
    lblNext.Text = "Sold: 0 Items"
    lblNext.Font = Enum.Font.Gotham
    lblNext.TextColor3 = Color3.fromRGB(150, 150, 150)
    lblNext.TextSize = 11
    lblNext.TextXAlignment = Enum.TextXAlignment.Left
    local lblTime = Instance.new("TextLabel", frm)
    lblTime.Size = UDim2.new(1, -16, 0, 18)
    lblTime.Position = UDim2.new(0, 8, 0, 70)
    lblTime.BackgroundTransparency = 1
    lblTime.Text = "Earned: Rp 0"
    lblTime.Font = Enum.Font.GothamBold
    lblTime.TextColor3 = Color3.fromRGB(80, 255, 120)
    lblTime.TextSize = 12
    lblTime.TextXAlignment = Enum.TextXAlignment.Left
    frm.Visible = false
    getgenv().SkenaTracker = {
        Update = function()
            frm.Visible = true
            if not getgenv().SkenaSession then return end
            local elapsed = os.clock() - getgenv().SkenaSession.StartTime
            local h = math.floor(elapsed / 3600)
            local m = math.floor((elapsed % 3600) / 60)
            local s = math.floor(elapsed % 60)
            lblStat.Text = string.format("Uptime: %02d:%02d:%02d", h, m, s)
            lblNext.Text = "Sold: " .. FormatNumber(getgenv().SkenaSession.TotalSold) .. " Items"
            lblTime.Text = "Earned: Rp " .. FormatNumber(getgenv().SkenaSession.TotalEarned)
        end,
        Hide = function() frm.Visible = false end
    }
end
CreateTracker()

task.spawn(function()
    while task.wait(1) do
        if getgenv().SkenaTracker and (getgenv().SkenaAutoFarm_Crop or getgenv().SkenaAutoFarm_Egg) then
            getgenv().SkenaTracker.Update()
        end
    end
end)

local function DoPlantCrops(isEggLoop)
    if os.clock() < (getgenv().SkenaPlantPauseTime or 0) then return end
    local rs = game:GetService("ReplicatedStorage")
    local cData = CROP_DATA[getgenv().SelectedCrop_AF1]
    local maxSeeds = getgenv().AFK_PlantAmount or 15
    local currentSeeds = 0
    local function getCount(parent)
        for _, v in ipairs(parent:GetChildren()) do
            if v:IsA("Tool") and string.find(v.Name, cData.SeedName) then
                local amt = 1
                local match = string.match(v.Name, "%d+")
                if match then amt = tonumber(match) end
                for _, child in ipairs(v:GetChildren()) do
                    if (child:IsA("IntValue") or child:IsA("NumberValue")) and string.find(string.lower(child.Name), "amount") then
                        amt = child.Value
                    end
                end
                currentSeeds = currentSeeds + amt
            end
        end
    end
    local char = player.Character
    if char then getCount(char) end
    getCount(player.Backpack)
    if getgenv().AutoBuySeed and currentSeeds < maxSeeds then
        local toBuy = maxSeeds - currentSeeds
        pcall(function() rs.Remotes.TutorialRemotes.RequestShop:InvokeServer("BUY", cData.SeedName, toBuy) end)
        task.wait(1)
    end
    if char and char:FindFirstChild("HumanoidRootPart") then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local function getTool(parent)
            for _, v in ipairs(parent:GetChildren()) do
                if v:IsA("Tool") and string.find(v.Name, cData.SeedName) then return v end
            end
            return nil
        end
        if hum then
            local heldCrop = getTool(char)
            if not heldCrop then
                hum:UnequipTools()
                task.wait(0.1)
                local inBp = getTool(player.Backpack)
                if inBp then hum:EquipTool(inBp) task.wait(0.2) end
            end
            if not getTool(char) then
                local recheckBp = getTool(player.Backpack)
                if recheckBp then
                    hum:UnequipTools()
                    task.wait(0.1)
                    hum:EquipTool(recheckBp)
                    task.wait(0.2)
                end
            end
        end
        if getTool(char) then
            local startPos = char.HumanoidRootPart.Position
            local angle = math.rad(math.random(0, 360))
            local dist = 0.5 + math.random() * 1.5
            local offset = Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
            local pos = startPos + offset
            pcall(function() rs.Remotes.TutorialRemotes.PlantCrop:FireServer(pos) end)
            task.wait(0.6)
        else
            task.wait(1)
        end
    else
        task.wait(2)
    end
end

getgenv().SkenaAutoFarm_Crop = false
getgenv().AutoBuySeed = true

local CropDropAF1 = TabAutoFarm1:CreateDropdown({
    Name = " Target Tanaman",
    Callback = function(val) UpdateSelectedCrop_AF1(val) end
})
for _, entry in ipairs(CROP_ORDER) do CropDropAF1:AddItem(entry.label, entry.key == "Padi") end

TabAutoFarm1:CreateToggleRow({
    Name = "Auto Farm 1",
    HasSubToggle = true,
    SubToggleName = "Auto Beli",
    SubToggleDefault = true,
    OnSubToggle = function(state) getgenv().AutoBuySeed = state end,
    OnToggle = function(state)
        getgenv().SkenaAutoFarm_Crop = state
        if not state and getgenv().SkenaTracker then getgenv().SkenaTracker.Hide() end
        if state then
            task.spawn(function()
                local lp = game.Players.LocalPlayer
                while getgenv().SkenaAutoFarm_Crop do
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local actCrops = workspace:FindFirstChild("ActiveCrops")
                        local pool = actCrops and actCrops:GetDescendants() or workspace:GetDescendants()
                        for _, obj in ipairs(pool) do
                            if not getgenv().SkenaAutoFarm_Crop then break end
                            if obj:IsA("ProximityPrompt") and obj.Enabled then
                                local part = obj.Parent
                                if part and part:IsA("BasePart") then
                                    local dist = (hrp.Position - part.Position).Magnitude
                                    if dist < 30 then
                                        pcall(function()
                                            if fireproximityprompt then
                                                fireproximityprompt(obj)
                                            else
                                                obj:InputHoldBegin() task.wait(0.1) obj:InputHoldEnd()
                                            end
                                        end)
                                        task.wait(0.15)
                                    end
                                end
                            end
                        end
                    end
                    task.wait(0.5)
                end
            end)
            task.spawn(function()
                while getgenv().SkenaAutoFarm_Crop do
                    DoPlantCrops(false)
                    task.wait(0.1)
                end
            end)
            task.spawn(function()
                while getgenv().SkenaAutoFarm_Crop do
                    local totalSold = SellTargetCrop(getgenv().SelectedCrop_AF1)
                    if totalSold > 0 then warn("[Sell Target] Berhasil jual " .. totalSold .. " item") end
                    local sDelay = getgenv().AFK_HarvestDelay or 60
                    for sw = sDelay, 1, -1 do
                        if not getgenv().SkenaAutoFarm_Crop then return end
                        task.wait(1)
                    end
                end
            end)
        end
    end
})

TabAutoFarm1:CreateInputRow({
    Name = " Maksimal Simpan Bibit di Tas",
    Placeholder = "15",
    Default = "15",
    Callback = function(val) getgenv().AFK_PlantAmount = tonumber(val) or 15 end
})

TabAutoFarm1:CreateInputRow({
    Name = " Jeda Waktu Auto Sell (Detik)",
    Placeholder = "60",
    Default = "60",
    Callback = function(val) getgenv().AFK_HarvestDelay = tonumber(val) or 60 end
})

TabAutoFarm1:CreateTextRow({
    Text = "Step: Atur Target Tanaman, lalu nyalakan Auto Farm 1."
})

getgenv().SkenaAutoFarm_Egg = false

TabAutoFarm2:CreateToggleRow({
    Name = "Auto Farm 2 (Telur + Tanaman)",
    OnToggle = function(state)
        getgenv().SkenaAutoFarm_Egg = state
        if not state and getgenv().SkenaTracker then getgenv().SkenaTracker.Hide() end
        if state then
            task.spawn(function()
                local lp = game.Players.LocalPlayer
                while getgenv().SkenaAutoFarm_Egg do
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local actCrops = workspace:FindFirstChild("ActiveCrops")
                        local pool = actCrops and actCrops:GetDescendants() or workspace:GetDescendants()
                        for _, obj in ipairs(pool) do
                            if not getgenv().SkenaAutoFarm_Egg then break end
                            if obj:IsA("ProximityPrompt") and obj.Enabled then
                                local part = obj.Parent
                                if part and part:IsA("BasePart") then
                                    local dist = (hrp.Position - part.Position).Magnitude
                                    if dist < 30 then
                                        pcall(function()
                                            if fireproximityprompt then
                                                fireproximityprompt(obj)
                                            else
                                                obj:InputHoldBegin() task.wait(0.1) obj:InputHoldEnd()
                                            end
                                        end)
                                        task.wait(0.15)
                                    end
                                end
                            end
                        end
                    end
                    task.wait(0.5)
                end
            end)
            task.spawn(function()
                while getgenv().SkenaAutoFarm_Egg do
                    DoPlantCrops(true)
                    task.wait(0.1)
                end
            end)
            task.spawn(function()
                while getgenv().SkenaAutoFarm_Egg do
                    SellTargetCrop(getgenv().SelectedCrop_AF1)
                    local sDelay = getgenv().AFK_HarvestDelay or 60
                    for hw = sDelay, 1, -1 do
                        if not getgenv().SkenaAutoFarm_Egg then return end
                        task.wait(1)
                    end
                end
            end)
        end
    end
})

TabAutoFarm2:CreateTextRow({
    Text = "Draft Auto Farm 2: auto farm tanaman di background + egg farm siklus 15 menit."
})

local CropDropManual = TabFarming:CreateDropdown({
    Name = " Target Tanaman",
    Callback = function(val) UpdateSelectedCrop_Manual(val) end
})
for _, entry in ipairs(CROP_ORDER) do CropDropManual:AddItem(entry.label, entry.key == "Padi") end

TabFarming:CreateInputButtonRow({
    Name = "Beli Bibit",
    Placeholder = "Jml",
    Default = "15",
    ButtonText = "Beli",
    Callback = function(inputValue)
        local cData = CROP_DATA[getgenv().SelectedCrop_Manual]
        local amount = tonumber(inputValue) or 15
        pcall(function()
            local rs = game:GetService("ReplicatedStorage")
            rs.Remotes.TutorialRemotes.RequestShop:InvokeServer("BUY", cData.SeedName, amount)
        end)
    end
})

TabFarming:CreateButtonRow({
    Name = "Sell all target tanaman",
    ButtonText = "Jual",
    Callback = function()
        task.spawn(function()
            local totalSold = SellTargetCrop(getgenv().SelectedCrop_Manual)
            if totalSold > 0 then
                warn("[Sell Target] Berhasil jual " .. totalSold .. " item")
            else
                warn("[Sell Target] Inventaris target crop (" .. getgenv().SelectedCrop_Manual .. ") kosong.")
            end
        end)
    end
})

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

TabFarming:CreateToggleRow({
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

TabSettings:CreateTextRow({
    Text = getgenv()._SKENA_ANTI_AFK and "Anti-AFK Active" or "Anti-AFK Failed"
})

TabSettings:CreateInputRow({
    Name = "UI Toggle Key",
    Placeholder = "Z",
    Default = "Z",
    Callback = function(keyStr)
        Window:SetToggleKey(keyStr)
    end
})

task.spawn(function()
    local succ, SkenaAdmin = pcall(function()
        return getgenv().SkenaLoad("SkenaUI_Admin.lua")
    end)
    if succ and SkenaAdmin then
        SkenaAdmin.Attach(Window, {})
    end
end)
