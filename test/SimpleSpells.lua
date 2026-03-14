-- ==========================================
-- SKENA HUB : Simple Spells (Redesigned)
-- Place ID: 118433033586507
-- ==========================================

local Window = SkenaHub.UI
local Theme = getgenv().SkenaHubTheme
local TweenService = game:GetService("TweenService")

-- Utility Helpers (Local copies since they aren't exported)
local function getBrighterColor(color)
    local hue, sat, val = Color3.toHSV(color)
    return Color3.fromHSV(hue, math.clamp(sat - 0.2, 0, 1), math.clamp(val + 0.4, 0, 1))
end

local function getDarkerColor(color)
    local hue, sat, val = Color3.toHSV(color)
    return Color3.fromHSV(hue, sat, math.clamp(val - 0.2, 0, 1))
end

-- 1. Tab: Spell (Vibrant Purple)
local SpellElements, SpellPage, SpellLayout = Window:CreateTab("Spell", 10747376565, Color3.fromRGB(160, 80, 255))

-- SPELL TAB: FEATURES
-- Row 1: [text "buy spell"] | [button "buy!"] | [single dropdown]
local BRow1, BRow2, BRow3 = SpellElements:CreateRow(3)
BRow1.Size = UDim2.new(0, 100, 1, 0)
BRow2.Size = UDim2.new(0, 60, 1, 0)
BRow3.Size = UDim2.new(1, -160 - (Theme.Gap * 2), 1, 0)

SpellElements:CreateLabel("buy spell", BRow1)
SpellElements:CreateButton("buy!", function() warn("Buy Clicked") end, BRow2)
SpellElements:CreateDropdown("Select Item", {"Common [50 Gold]", "Desert [300 Gold]", "Forest [3,500 Gold]"}, function(val) end, false, BRow3)

-- Row 2: ESP Object to Destroy text, toggle, and dropdown multiple + search
local BRow3_1, BRow3_2, BRow3_3 = SpellElements:CreateRow(3)
BRow3_1.Size = UDim2.new(0, 100, 1, 0)
BRow3_2.Size = UDim2.new(0, 60, 1, 0)
BRow3_3.Size = UDim2.new(1, -160 - (Theme.Gap * 2), 1, 0)

SpellElements:CreateLabel("ESP Object to Destroy", BRow3_1)
SpellElements:CreateToggleSwitch("", false, function(s) warn("ESP Toggle: " .. tostring(s)) end, BRow3_2)
local espMulti = SpellElements:CreateMultiDropdown("Select Objects", {"Part", "Model", "Folder", "MeshPart", "Attachment"}, function(selected)
    warn("Selected objects: " .. #selected)
end, true, BRow3_3)

-- Make ESP Dropdown Panel Green
task.spawn(function()
    if espMulti and espMulti.Container then
        local ContainerStroke = espMulti.Container:FindFirstChildOfClass("UIStroke")
        if ContainerStroke then
            ContainerStroke.Color = Theme.StatusGreen
        end
    end
end)

-- Row 3: Slider with text (x) ESP Search Radius
local SliderRow = SpellElements:CreateRow(1, 20)
SpellElements:CreateSlider("ESP Search Radius", Theme.StatusGreen, 0, 500, 100, function(val)
    warn("Radius updated: " .. val)
end, SliderRow)

SpellElements:CreateGap(6)

-- Row 4: Auto Farm + Auto Sell + Settings Trigger
local Col_AF, Col_AS, Col_Settings = SpellElements:CreateRow(3)
Col_AF.Size = UDim2.new(0, 105, 1, 0)
Col_AS.Size = UDim2.new(0, 105, 1, 0)
Col_Settings.Size = UDim2.new(1, -210 - (Theme.Gap * 2), 1, 0)

local PurpleColor = Color3.fromRGB(160, 80, 255)

-- State for Hard Dropdown
local dropdownOpen = false
local DropContainer = Instance.new("Frame")
DropContainer.Name = "HardDropdown"
DropContainer.LayoutOrder = 100
DropContainer.Size = UDim2.new(1, 0, 0, 0)
DropContainer.BackgroundTransparency = 1
DropContainer.ClipsDescendants = true
DropContainer.BorderSizePixel = 0
DropContainer.Parent = SpellPage

local DropPadding = Instance.new("UIPadding", DropContainer)
DropPadding.PaddingTop = UDim.new(0, 2)
DropPadding.PaddingBottom = UDim.new(0, 4)
DropPadding.PaddingLeft = UDim.new(0, 2)
DropPadding.PaddingRight = UDim.new(0, 1)

local DropLayout = Instance.new("UIListLayout", DropContainer)
DropLayout.SortOrder = Enum.SortOrder.LayoutOrder
DropLayout.Padding = UDim.new(0, Theme.Gap)
DropLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- Placeholder inside Hard Dropdown
local PlaceholderRow = SpellElements:CreateRow(1, nil, DropContainer)
SpellElements:CreateButton("Placeholder Button", function() warn("Placeholder Clicked") end, PlaceholderRow)

-- Auto Farm Toggle
local afData = SpellElements:CreateToggleButton("Auto Farm", false, 10734975692, function(state)
    warn("Auto Farm: " .. tostring(state))
end, Col_AF)

-- Auto Sell Toggle
local asData = SpellElements:CreateToggleButton("", false, nil, function(state)
    warn("Auto Sell: " .. tostring(state))
end, Col_AS)

-- Manual refinement for Auto Sell to include TextBox
if asData and asData.Btn then
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 1, 0)
    Container.BackgroundTransparency = 1
    Container.Parent = asData.Btn
    
    local Layout = Instance.new("UIListLayout")
    Layout.FillDirection = Enum.FillDirection.Horizontal
    Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    Layout.VerticalAlignment = Enum.VerticalAlignment.Center
    Layout.Padding = UDim.new(0, 4)
    Layout.Parent = Container

    local InputBg = Instance.new("Frame")
    InputBg.Size = UDim2.new(0, 22, 0, 16)
    InputBg.BackgroundColor3 = Theme.HoverColor
    InputBg.BackgroundTransparency = 0.5
    InputBg.LayoutOrder = 1
    InputBg.Parent = Container
    Instance.new("UICorner", InputBg).CornerRadius = UDim.new(0, 4)

    local ValInput = Instance.new("TextBox")
    ValInput.Size = UDim2.new(1, 0, 1, 0)
    ValInput.BackgroundTransparency = 1
    ValInput.Text = "30"
    ValInput.TextColor3 = Theme.TextPrimary
    ValInput.FontFace = Theme.Fonts.Regular
    ValInput.TextSize = 11
    ValInput.ClearTextOnFocus = true
    ValInput.Parent = InputBg

    local RightLabel = Instance.new("TextLabel")
    RightLabel.BackgroundTransparency = 1
    RightLabel.Text = "sec Autosell"
    RightLabel.TextColor3 = Theme.TextMuted
    RightLabel.FontFace = Theme.Fonts.SemiBold
    RightLabel.TextSize = 12
    RightLabel.LayoutOrder = 2
    RightLabel.AutomaticSize = Enum.AutomaticSize.X
    RightLabel.Size = UDim2.new(0, 0, 1, 0)
    RightLabel.Parent = Container

    -- Tie label colors to the toggle state
    asData.Btn.MouseButton1Click:Connect(function()
        local isToggled = asData.Stroke.Transparency == 0 -- Simple check for toggled state
        RightLabel.TextColor3 = isToggled and Theme.TextPrimary or Theme.TextMuted
    end)
    
    -- Sync hover color
    asData.Btn.MouseEnter:Connect(function()
        RightLabel.TextColor3 = Theme.TextPrimary
    end)
    asData.Btn.MouseLeave:Connect(function()
        local isToggled = asData.Stroke.Transparency == 0
        if not isToggled then
            RightLabel.TextColor3 = Theme.TextMuted
        end
    end)
end

-- Settings Trigger (Merged Text + Button)
local vTrigger = Instance.new("TextButton")
vTrigger.Size = UDim2.new(1, 0, 1, 0)
vTrigger.BackgroundTransparency = 1
vTrigger.Text = "" -- Using a separate label for more control
vTrigger.Parent = Col_Settings

local vLabel = Instance.new("TextLabel")
vLabel.Size = UDim2.new(1, -22, 1, 0) -- Leave 22px room for the icon
vLabel.Position = UDim2.new(0, 0, 0, 0)
vLabel.BackgroundTransparency = 1
vLabel.Text = "Open Settings"
vLabel.TextColor3 = Theme.TextMuted
vLabel.FontFace = Theme.Fonts.SemiBold
vLabel.TextSize = 12
vLabel.TextXAlignment = Enum.TextXAlignment.Right
vLabel.Parent = vTrigger

local vIcon = Instance.new("ImageLabel")
vIcon.Size = UDim2.new(0, 16, 0, 16)
vIcon.Position = UDim2.new(1, -16, 0.5, -8)
vIcon.BackgroundTransparency = 1
vIcon.Image = "rbxassetid://10709790948"
vIcon.ImageColor3 = Theme.TextPrimary
vIcon.Parent = vTrigger

vTrigger.MouseButton1Click:Connect(function()
    dropdownOpen = not dropdownOpen
    
    TweenService:Create(vIcon, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
        Rotation = dropdownOpen and 180 or 0
    }):Play()
    
    if dropdownOpen then
        DropContainer.Visible = true
        TweenService:Create(DropContainer, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {
            Size = UDim2.new(1, 0, 0, DropLayout.AbsoluteContentSize.Y + 10)
        }):Play()
    else
        local t = TweenService:Create(DropContainer, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {
            Size = UDim2.new(1, 0, 0, 0)
        })
        t:Play()
        t.Completed:Connect(function() 
            if not dropdownOpen then DropContainer.Visible = false end 
        end)
    end
end)

-- 2. Tab: Teleport (Ocean Blue)
local TeleElements, TelePage, TeleLayout = Window:CreateTab("Teleport", 10734886004, Color3.fromRGB(50, 150, 255))

-- TELEPORT TAB: FEATURES
local zoneData = {
    {"Common", CFrame.new(853.272, 132.774, -114.176)},
    {"Desert", CFrame.new(508.961, 126.700, 135.752)},
    {"Mushroom", CFrame.new(481.551, 238.700, -472.473)},
    {"Frozen", CFrame.new(383.247, 302.700, -567.455)},
    {"Volcanic", CFrame.new(136.528, 302.700, -350.816)}
}

local secretData = {
    {"Ice Arrow", CFrame.new(1060.314, 132.567, -231.072)},
    {"Fire Sword", CFrame.new(869.619, 135.231, -390.111)},
    {"Catalyst", CFrame.new(527.259, 39.619, 493.563)}
}

local function CreateTeleportSection(title, data)
    TeleElements:CreateSection(title)
    
    for i = 1, #data, 3 do
        local r1, r2, r3 = TeleElements:CreateRow(3)
        local cols = {r1, r2, r3}
        
        for j = 1, 3 do
            local slotIdx = i + (j - 1)
            local item = data[slotIdx]
            local container = cols[j]
            
            if item and container then
                container.Size = UDim2.new(0, 111, 1, 0)
                TeleElements:CreateButton(item[1], function()
                    local char = game.Players.LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then hrp.CFrame = item[2] end
                end, container)
            end
        end
    end
end

CreateTeleportSection("Zone", zoneData)
CreateTeleportSection("Secret Spell Location", secretData)

-- Initial sizing update
task.delay(0.5, function()
    SpellPage.CanvasSize = UDim2.new(0, 0, 0, SpellLayout.AbsoluteContentSize.Y + 20)
    TelePage.CanvasSize = UDim2.new(0, 0, 0, TeleLayout.AbsoluteContentSize.Y + 20)
end)

warn("[SkenaHub] Simple Spells with Hard Dropdown Loaded!")
