local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer

-- ==========================================
-- CLEAUP PREVIOUS LOGIC
-- ==========================================
if getgenv().SkenaHub_SurviveCold_Connections then
    for _, c in pairs(getgenv().SkenaHub_SurviveCold_Connections) do
        pcall(function() c:Disconnect() end)
    end
end
getgenv().SkenaHub_SurviveCold_Connections = {}
local cons = getgenv().SkenaHub_SurviveCold_Connections

if getgenv().SkenaHub_SurviveCold_LoopActive ~= nil then
    getgenv().SkenaHub_SurviveCold_LoopActive = false 
end
getgenv().SkenaHub_SurviveCold_LoopActive = true

if CoreGui:FindFirstChild("EzSurviveESP") then
    CoreGui.EzSurviveESP:Destroy()
end

-- ==========================================
-- VARIABLES
-- ==========================================
local TP_FOOD_POS = Vector3.new(848.004, -15.116, 230.371)
local TP_CLOTHES_POS = Vector3.new(591.745, -15.130, 1818.479)
local TP_SPEED = 60
local WALK_SPEED = 38
local RUN_SPEED = 76

local speedEnabled = false
local infJumpEnabled = false
local espEnabled = false

local espFolder = nil
local activeTween = nil
local speedKey = Enum.KeyCode.X
local itemFilters = {}
local espDropdownObj = nil
local capturedPaths = {}

local BLACKLIST = {
    "HumanoidRootPart", "Torso", "Board", "Proximity", "Meshes_cartello_cube", 
    "Campfire", "Post", "Window", "Chest", "meshes/cartello", "AchievementFrame", "SniperRifle",
    "2xSpeed", "Head", "Left Arm", "Right Arm", "Left Leg", "Right Leg", 
    "EmptyHouseNPC", "OutfitNPC", "CraftingNPC", "Avatar", "BrokenWall", "cartello","Keyboard","Door",
    "MainDoorPart", "Scavenger", "Relic Machine"
}

local EXACT_BLACKLIST = {
    "Part", "GUISign1", "GUISign2", "Plank", "Base", "Baseplate", "SpawnLocation", "Folder", "Model",
    "Sign", "Title", "Roof", "Entrance", "Carpet", "Carpet2", "Red Carpet", "Small Red Carpet", 
    "PlacedPlank", "HB"
}

-- ==========================================
-- ESP & LOGIC FUNCTIONS
-- ==========================================
local function getCleanName(n, objContext) 
    if string.match(n, "^BrokenWall%d+$") then return "BrokenWall" end
    if string.match(n, "^Cube%.%d+$") then return "Cube" end
    
    local clean = n:split("_")[1] or n 
    
    -- Jaring konteks untuk nama-nama generik
    if objContext and objContext.Parent and objContext.Parent ~= workspace then
        local ln = string.lower(clean)
        local genericNames = {
            yellow = true, green = true, red = true, blue = true, purple = true,
            tutorial = true, part = true, sphere = true, block = true, cylinder = true,
            wedge = true, meshpart = true, mesh = true, handle = true,
            ["1"] = true, ["2"] = true, ["3"] = true, ["4"] = true, ["5"] = true
        }
        
        if genericNames[ln] then
            local pName = objContext.Parent.Name
            if pName ~= "Workspace" and not string.match(pName, "Folder") and not string.match(pName, "^Model$") then
                return "[" .. pName .. "] " .. clean
            end
        end
    end
    
    return clean
end

local function isBlacklisted(n) 
    if string.match(n, "^Avatar%d+$") then return true end
    if string.match(n, "^Cube%.%d+$") then return true end
    if string.lower(n) == "cube" then return true end
    if string.match(n, "%[x%d+%]") then return true end
    
    for _, b in ipairs(EXACT_BLACKLIST) do
        if n == b then return true end
        if string.lower(n) == string.lower(b) then return true end
    end
    
    for _, b in ipairs(BLACKLIST) do 
        if string.find(n, b) then return true end 
    end
    return false 
end

local function clearESP() 
    if espFolder then 
        espFolder:Destroy() 
    end
    espFolder = nil 
end

local function addHighlight(target, cName, rName)
    if not espFolder then return end
    local hlName = rName .. "_ESP_ID_" .. tostring(target:GetDebugId())
    
    if not espFolder:FindFirstChild(hlName) then
        local hl = Instance.new("Highlight")
        hl.Name = hlName
        hl.Adornee = target
        hl.FillTransparency = 1
        hl.OutlineTransparency = 0
        hl.OutlineColor = Color3.fromRGB(52, 199, 89) -- iOS Green from original script
        
        if itemFilters[cName] == false then
            hl.Enabled = false
        else
            hl.Enabled = true
        end
        hl.Parent = espFolder
        
        local bb = Instance.new("BillboardGui")
        bb.Name = "NameTag"
        bb.Adornee = target
        bb.Size = UDim2.new(0, 100, 0, 20)
        bb.StudsOffset = Vector3.new(0, 2, 0)
        bb.AlwaysOnTop = true
        bb.Enabled = hl.Enabled
        bb.Parent = hl
        
        local tl = Instance.new("TextLabel")
        tl.Size = UDim2.new(1, 0, 1, 0)
        tl.BackgroundTransparency = 1
        tl.Text = cName
        tl.TextColor3 = Color3.fromRGB(255, 255, 255)
        tl.TextStrokeTransparency = 0
        tl.Font = Enum.Font.GothamBold
        tl.TextSize = 12
        tl.Parent = bb
    end
end

local function checkObject(o)
    if not o then return end
    local t, rN = nil, ""
    
    if o:IsA("ProximityPrompt") or o:IsA("ClickDetector") then 
        local p = o.Parent
        if p and p:IsA("Attachment") then p = p.Parent end
        if p and (p:IsA("BasePart") or p:IsA("Model")) and p ~= workspace then
            t, rN = p, p.Name
        end
    elseif o:IsA("BillboardGui") or o:IsA("SurfaceGui") then
        if not o:FindFirstAncestor("EzSurviveESP") and o.Name ~= "NameTag" and o.Name ~= "Chat" and o.Name ~= "HealthBar" then
            local p = o.Adornee or o.Parent
            if p and p:IsA("Attachment") then p = p.Parent end
            if p and (p:IsA("BasePart") or p:IsA("Model")) and p ~= workspace and not p:FindFirstChild("Humanoid") then
                t, rN = p, p.Name
            end
        end
    elseif o:IsA("Tool") and o.Parent ~= player.Character and o.Parent ~= player.Backpack then
        t, rN = o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart") or o, o.Name
    elseif o:IsA("Model") and o.Name ~= "Workspace" and o.Name ~= player.Name then 
        if o:FindFirstChild("Humanoid") then
            t, rN = o, o.Name
        elseif o.PrimaryPart and not o.PrimaryPart.Anchored and o.Parent ~= player.Character then
            -- Benda model murni lepas (mis. Kotak supply atau drop item kompleks)
            t, rN = o, o.Name
        end
    elseif (o:IsA("Part") or o:IsA("MeshPart") or o:IsA("UnionOperation")) and o.Parent ~= player.Character then
        if o.CanTouch and not o.Anchored and not o:FindFirstAncestorOfClass("Model") and not o:FindFirstAncestorOfClass("Tool") then 
            t, rN = o, o.Name 
        end
    end
    
    -- Jaring ekstra asuransi untuk benda dengan kata kunci penting (jaga-jaga developernya iseng)
    if not t and (o:IsA("BasePart") or o:IsA("Model")) and o.Parent ~= player.Character and o ~= workspace and o.Name ~= player.Name then
        local ln = string.lower(o.Name)
        if string.find(ln, "pet") then
            t, rN = o, o.Name
        end
    end
    
    if t and rN ~= "" and not isBlacklisted(rN) then
        local cN = getCleanName(rN, t)
        if not isBlacklisted(cN) then 
            capturedPaths[t:GetFullName()] = cN
            if espDropdownObj then
                espDropdownObj:AddItem(cN, true, function(state)
                    itemFilters[cN] = state
                    if espFolder then
                        for _, hl in pairs(espFolder:GetChildren()) do
                            if hl:IsA("Highlight") and hl:FindFirstChild("NameTag") then
                                if hl.NameTag.TextLabel.Text == cN then
                                    hl.Enabled = state
                                    hl.NameTag.Enabled = state
                                end
                            end
                        end
                    end
                end)
            end
            if itemFilters[cN] == nil then itemFilters[cN] = true end
            if espEnabled then addHighlight(t, cN, rN) end 
        end
    end
end

local currentMoveTarget = nil
local function moveToPos(tPos)
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local hum = player.Character and player.Character:FindFirstChild("Humanoid")
    if hrp and hum then
        if hum.Sit then hum.Sit = false end
        if activeTween then activeTween:Cancel() activeTween = nil end
        currentMoveTarget = tPos
        hum:MoveTo(tPos)
        
        task.spawn(function()
            local loopCount = 0
            while currentMoveTarget == tPos and hum.Parent and hrp.Parent do
                local dist = (hrp.Position * Vector3.new(1,0,1) - tPos * Vector3.new(1,0,1)).Magnitude
                if dist < 5 then
                    currentMoveTarget = nil
                    break
                end
                -- Coba pastikan karakter terus mengejar
                if loopCount % 5 == 0 then
                    hum:MoveTo(tPos)
                end
                task.wait(0.2)
                loopCount = loopCount + 1
            end
        end)
    end
end

-- ==========================================
-- INIT SKENA UI
-- ==========================================
-- Wait until SkenaUI_Library is loaded from Github properly
local SkenaUI_Loaded = false
local SkenaUI
pcall(function()
    SkenaUI = loadstring(game:HttpGet("http://192.168.100.40:8000/SkenaUI_Library.lua"))()
    SkenaUI_Loaded = true
end)

if not SkenaUI_Loaded then
    warn("Koneksi gagal ke SkenaUI_Library. Hubungkan ke Internet.")
    return
end

-- Fallback Name jika gagal fetch
local GameName = "Survive the Cold Helper"
local success, info = pcall(function()
    return MarketplaceService:GetProductInfo(game.PlaceId)
end)
if success and info and info.Name then
    GameName = info.Name .. " Helper"
end

local Window = SkenaUI:CreateWindow({
    Name = "SkenaHub - " .. GameName
})

local TabMods = Window:CreateTab("Mods", "gamepad-2") 
local TabSettings = Window:CreateTab("Settings", "settings", true) 

-- ROW 1: SPEED MOD
local SpeedRowState
SpeedRowState = TabMods:CreateToggleRow({
    Name = "Speed Mod",
    HasKey = true,
    DefaultKey = "X",
    OnKeyChange = function(newKeyString)
        local parsed = Enum.KeyCode[string.upper(newKeyString)]
        if parsed then speedKey = parsed end
    end,
    OnToggle = function(state)
        speedEnabled = state
        if not speedEnabled and player.Character and player.Character:FindFirstChild("Humanoid") then 
            player.Character.Humanoid.WalkSpeed = 16 
        end
    end
})

-- ROW 2: INF JUMP
TabMods:CreateToggleRow({
    Name = "Infinite Jump",
    OnToggle = function(state)
        infJumpEnabled = state
    end
})

-- ROW 3: ESP & FILTER
espDropdownObj = TabMods:CreateMultiSelectDropdown({
    Name = "ESP Highlight",
    HasMainToggle = true,
    OnMainToggle = function(state)
        espEnabled = state
        clearESP()
        if espEnabled then
            espFolder = Instance.new("Folder")
            espFolder.Name = "EzSurviveESP"
            espFolder.Parent = CoreGui
            
            task.spawn(function()
                local desc = workspace:GetDescendants()
                for i=1, #desc do
                    checkObject(desc[i])
                    if i%1000 == 0 then task.wait() end
                end
            end)
        end
    end
})

-- ROW 4: DOUBLE TELEPORT BUTTON
TabMods:CreateDoubleButtonRow({
    Name = "Move to",
    Button1Text = "Clothes",
    Button2Text = "Food",
    Callback1 = function() moveToPos(TP_CLOTHES_POS) end,
    Callback2 = function() moveToPos(TP_FOOD_POS) end
})

-- ==========================================
-- ISI TAB SETTINGS
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
-- ATTACH ADMIN MODULE ONLINE
-- ==========================================
task.spawn(function()
    local success, SkenaAdmin = pcall(function()
        return loadstring(game:HttpGet("http://192.168.100.40:8000/SkenaUI_Admin.lua"))()
    end)
    if success and SkenaAdmin then
        SkenaAdmin.Attach(Window, { CapturedPaths = capturedPaths })
    end
end)


-- ==========================================
-- INTERNAL LOOPS & EVENTS 
-- ==========================================
table.insert(cons, workspace.DescendantAdded:Connect(checkObject))

task.spawn(function()
    while task.wait(3) and getgenv().SkenaHub_SurviveCold_LoopActive do 
        if espEnabled then 
            local desc = workspace:GetDescendants(); 
            for i=1, #desc do 
                if not getgenv().SkenaHub_SurviveCold_LoopActive then break end
                checkObject(desc[i]); 
                if i%1000 == 0 then task.wait() end 
            end 
        end 
    end
end)

table.insert(cons, UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == speedKey then 
        speedEnabled = not speedEnabled
        if SpeedRowState and SpeedRowState.ToggleState then
            SpeedRowState.ToggleState(speedEnabled)
        end
        if not speedEnabled and player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.WalkSpeed = 16 
        end
    end
end))

table.insert(cons, RunService.RenderStepped:Connect(function() 
    if speedEnabled and player.Character then 
        local hum = player.Character:FindFirstChild("Humanoid")
        if hum then 
            hum.WalkSpeed = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and RUN_SPEED or WALK_SPEED 
        end 
    end 
end))

table.insert(cons, UserInputService.JumpRequest:Connect(function() 
    if infJumpEnabled and player.Character then 
        local hum = player.Character:FindFirstChild("Humanoid")
        if hum then 
            hum:ChangeState(Enum.HumanoidStateType.Jumping) 
        end 
    end 
end))
