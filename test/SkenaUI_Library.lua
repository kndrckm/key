local SkenaUI = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local parentUI = nil
if pcall(function() return CoreGui.RobloxGui end) then
    parentUI = CoreGui
else
    parentUI = game.Players.LocalPlayer:WaitForChild("PlayerGui")
end

local function LoadLucideIcons()
    local success, result = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/src/Icons.lua"))()
    end)
    if success and result and result.assets then
        return result.assets
    end
    return {}
end
local LucideIcons = LoadLucideIcons()

-- Midnight Neon Palette
local Palette = {
    Background = Color3.fromRGB(15, 15, 20),
    Card = Color3.fromRGB(25, 25, 30),
    RowItem = Color3.fromRGB(30, 30, 35),
    RowHover = Color3.fromRGB(40, 40, 50),
    TextPrimary = Color3.fromRGB(240, 240, 245),
    TextSecondary = Color3.fromRGB(140, 140, 150),
    Accent = Color3.fromRGB(0, 170, 255), -- Neon Blue
    NeonGradient = {
        Color3.fromRGB(0, 0, 0),     -- Black
        Color3.fromRGB(0, 255, 255)   -- Cyan
    },
    Border = Color3.fromRGB(255, 255, 255),
    BorderTransparency = 0.9,
    RedHover = Color3.fromRGB(232, 17, 35),
    InputHdr = Color3.fromRGB(20, 20, 25)
}

function SkenaUI:CreateWindow(Options, Title, IsMobile)
    if type(Options) == "string" then
        Options = {Name = Options, Title = Title, IsMobile = IsMobile}
    end
    Options = Options or {}
    local WindowName = Options.Name or "SkenaHub"
    
    if parentUI:FindFirstChild("SkenaHub_UI") then
        parentUI.SkenaHub_UI:Destroy()
    end

    local SG = Instance.new("ScreenGui")
    SG.Name = "SkenaHub_UI"
    SG.Parent = parentUI
    SG.ResetOnSpawn = false
    SG.DisplayOrder = 9999
    SG.ZIndexBehavior = Enum.ZIndexBehavior.Global

    local WindowObj = {
        CurrentTab = nil,
        Tabs = {},
        ToggleKey = Enum.KeyCode.RightControl,
        Cooldowns = {}
    }

    local Container = Instance.new("Frame", SG)
    Container.Name = "Container"
    Container.Size = UDim2.new(0, 260, 0, 520) -- Taller, closer to reference
    Container.Position = UDim2.new(0, 15, 0.5, -260) -- Centered left
    Container.BackgroundTransparency = 1

    -- Drop Shadow (Sirius EXACT Implementation)
    local Shadow = Instance.new("ImageLabel", Container)
    Shadow.Name = "Shadow"
    Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    Shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    Shadow.Size = UDim2.new(1, 47, 1, 47) -- EXACT Sirius spread
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxassetid://6015667362" -- EXACT Sirius asset
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(47, 47, 450, 450) -- Standard for 512x512 shadows
    Shadow.ImageColor3 = Color3.new(1, 1, 1) -- Must be white for UIGradient to work
    Shadow.ImageTransparency = 0.7 
    Shadow.ZIndex = 0

    local ShadowGradient = Instance.new("UIGradient", Shadow)
    ShadowGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Palette.Background), -- Dark base
        ColorSequenceKeypoint.new(1, Palette.NeonGradient[2]) -- Neon glow end
    })
    ShadowGradient.Rotation = -45

    -- Main Visual Container
    local Main = Instance.new("Frame", Container)
    Main.Name = "Main"
    Main.Size = UDim2.new(1, 0, 1, 0) 
    Main.BackgroundColor3 = Palette.Background
    Main.BorderSizePixel = 0
    Main.ZIndex = 1
    
    local CornerRadius = 12
    local MainCorner = Instance.new("UICorner", Main)
    MainCorner.CornerRadius = UDim.new(0, CornerRadius)
    
    -- Neon Gradient Stroke
    local MainStroke = Instance.new("UIStroke", Main)
    MainStroke.Thickness = 1
    MainStroke.Color = Color3.new(1, 1, 1) -- WHITE base is CRITICAL for UIGradient visibility
    MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    MainStroke.Transparency = 0
    
    local MainGradient = Instance.new("UIGradient", MainStroke)
    MainGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Palette.NeonGradient[1]),
        ColorSequenceKeypoint.new(1, Palette.NeonGradient[2])
    })
    MainGradient.Rotation = -45

    -- Profile Header
    local ProfileFrame = Instance.new("Frame", Main)
    ProfileFrame.Name = "Profile"
    ProfileFrame.Size = UDim2.new(1, -24, 0, 80)
    ProfileFrame.Position = UDim2.new(0, 12, 0, 12)
    ProfileFrame.BackgroundColor3 = Palette.Card
    ProfileFrame.BorderSizePixel = 0
    Instance.new("UICorner", ProfileFrame).CornerRadius = UDim.new(0, 12)

    local Avatar = Instance.new("ImageLabel", ProfileFrame)
    Avatar.Size = UDim2.new(0, 56, 0, 56)
    Avatar.Position = UDim2.new(0, 12, 0, 12)
    Avatar.BackgroundColor3 = Palette.Background
    Avatar.BorderSizePixel = 0
    Avatar.Image = "rbxassetid://16020739345" -- Placeholder avatar
    Instance.new("UICorner", Avatar).CornerRadius = UDim.new(0, 10)

    local NameLabel = Instance.new("TextLabel", ProfileFrame)
    NameLabel.Size = UDim2.new(1, -85, 0, 18)
    NameLabel.Position = UDim2.new(0, 78, 0, 15)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = WindowName -- Using window name as profile name for now
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextSize = 16
    NameLabel.TextColor3 = Palette.TextPrimary
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left

    local LevelBadge = Instance.new("TextLabel", ProfileFrame)
    LevelBadge.Size = UDim2.new(0, 20, 0, 18)
    LevelBadge.Position = UDim2.new(1, -25, 0, 15)
    LevelBadge.BackgroundTransparency = 1
    LevelBadge.Text = "5"
    LevelBadge.Font = Enum.Font.GothamBold
    LevelBadge.TextSize = 12
    LevelBadge.TextColor3 = Palette.Accent
    LevelBadge.TextXAlignment = Enum.TextXAlignment.Right

    local UserHandle = Instance.new("TextLabel", ProfileFrame)
    UserHandle.Size = UDim2.new(1, -80, 0, 14)
    UserHandle.Position = UDim2.new(0, 78, 0, 35)
    UserHandle.BackgroundTransparency = 1
    UserHandle.Text = "@username"
    UserHandle.Font = Enum.Font.Gotham
    UserHandle.TextSize = 12
    UserHandle.TextColor3 = Palette.TextSecondary
    UserHandle.TextXAlignment = Enum.TextXAlignment.Left

    local EXPBarBG = Instance.new("Frame", ProfileFrame)
    EXPBarBG.Size = UDim2.new(1, -95, 0, 3)
    EXPBarBG.Position = UDim2.new(0, 78, 0, 55)
    EXPBarBG.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    EXPBarBG.BorderSizePixel = 0
    Instance.new("UICorner", EXPBarBG)

    local EXPBarFill = Instance.new("Frame", EXPBarBG)
    EXPBarFill.Size = UDim2.new(0.6, 0, 1, 0)
    EXPBarFill.BackgroundColor3 = Palette.Accent
    EXPBarFill.BorderSizePixel = 0
    Instance.new("UICorner", EXPBarFill)

    local EXPText = Instance.new("TextLabel", ProfileFrame)
    EXPText.Size = UDim2.new(0, 100, 0, 12)
    EXPText.Position = UDim2.new(0, 78, 0, 62)
    EXPText.BackgroundTransparency = 1
    EXPText.Text = "<font color='#00AAFF'>1,450</font> / 1,850 EXP"
    EXPText.RichText = true
    EXPText.Font = Enum.Font.GothamBold
    EXPText.TextSize = 9
    EXPText.TextColor3 = Palette.TextSecondary
    EXPText.TextXAlignment = Enum.TextXAlignment.Left

    local uiVisible = true
    local function ToggleUIAnim()
        uiVisible = not uiVisible
        if uiVisible then
            SG.Enabled = true
            Main.GroupTransparency = 1
            TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {GroupTransparency = Palette.BackgroundTransparency}):Play()
        else
            local tw = TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {GroupTransparency = 1})
            tw:Play()
            task.delay(0.3, function()
                if not uiVisible then SG.Enabled = false end
            end)
        end
    end

    -- Toolbar/Title
    local TitleBar = Instance.new("Frame", Main)
    TitleBar.Size = UDim2.new(1, 0, 0, 40)
    TitleBar.BackgroundTransparency = 1

    -- Main Content Area
    local BodyFrame = Instance.new("Frame", Main)
    BodyFrame.Size = UDim2.new(1, -24, 1, -165)
    BodyFrame.Position = UDim2.new(0, 12, 0, 105)
    BodyFrame.BackgroundTransparency = 1

    local ListLayout = Instance.new("UIListLayout", BodyFrame)
    ListLayout.Padding = UDim.new(0, 4)
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- Search Bar
    local SearchFrame = Instance.new("Frame", BodyFrame)
    SearchFrame.Name = "Search"
    SearchFrame.Size = UDim2.new(1, 0, 0, 40)
    SearchFrame.BackgroundTransparency = 1
    SearchFrame.LayoutOrder = 1

    local SearchIcon = Instance.new("ImageLabel", SearchFrame)
    SearchIcon.Size = UDim2.new(0, 20, 0, 20)
    SearchIcon.Position = UDim2.new(0, 10, 0.5, -10)
    SearchIcon.BackgroundTransparency = 1
    SearchIcon.Image = "rbxassetid://10734898144" -- lucide-search
    SearchIcon.ImageColor3 = Palette.TextSecondary

    local SearchBox = Instance.new("TextBox", SearchFrame)
    SearchBox.Size = UDim2.new(1, -80, 1, 0)
    SearchBox.Position = UDim2.new(0, 40, 0, 0)
    SearchBox.BackgroundTransparency = 1
    SearchBox.Text = ""
    SearchBox.PlaceholderText = "Search"
    SearchBox.PlaceholderColor3 = Palette.TextSecondary
    SearchBox.TextColor3 = Palette.TextPrimary
    SearchBox.Font = Enum.Font.Gotham
    SearchBox.TextSize = 14
    SearchBox.TextXAlignment = Enum.TextXAlignment.Left

    local SearchPill = Instance.new("TextLabel", SearchFrame)
    SearchPill.Size = UDim2.new(0, 40, 0, 18)
    SearchPill.Position = UDim2.new(1, -50, 0.5, -9)
    SearchPill.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    SearchPill.Text = "Tab"
    SearchPill.TextColor3 = Palette.TextSecondary
    SearchPill.Font = Enum.Font.Gotham
    SearchPill.TextSize = 10
    Instance.new("UICorner", SearchPill).CornerRadius = UDim.new(0, 4)

    -- Bottom Section (Settings)
    local BottomSection = Instance.new("Frame", Main)
    BottomSection.Size = UDim2.new(1, -24, 0, 50)
    BottomSection.Position = UDim2.new(0, 12, 1, -60)
    BottomSection.BackgroundTransparency = 1

    local function CreateNavItem(Parent, Name, Icon, Shortcut, LayoutOrder, IsActive)
        local Item = Instance.new("TextButton", Parent)
        Item.Name = Name
        Item.Size = UDim2.new(1, 0, 0, 44)
        Item.BackgroundTransparency = IsActive and 0.85 or 1
        Item.BackgroundColor3 = Palette.Accent
        Item.Text = ""
        Item.LayoutOrder = LayoutOrder
        Instance.new("UICorner", Item).CornerRadius = UDim.new(0, 8)

        if IsActive then
            local ActiveStroke = Instance.new("UIStroke", Item)
            ActiveStroke.Color = Palette.Accent
            ActiveStroke.Thickness = 0.8
            ActiveStroke.Transparency = 0.5
        end

        local IconImg = Instance.new("ImageLabel", Item)
        IconImg.Size = UDim2.new(0, 20, 0, 20)
        IconImg.Position = UDim2.new(0, 12, 0.5, -10)
        IconImg.BackgroundTransparency = 1
        IconImg.Image = LucideIcons[Icon] or "rbxassetid://10734898144"
        IconImg.ImageColor3 = IsActive and Palette.TextPrimary or Palette.TextSecondary

        local Label = Instance.new("TextLabel", Item)
        Label.Size = UDim2.new(1, -80, 1, 0)
        Label.Position = UDim2.new(0, 44, 0, 0)
        Label.BackgroundTransparency = 1
        Label.Text = Name
        Label.Font = IsActive and Enum.Font.GothamBold or Enum.Font.Gotham
        Label.TextSize = 14
        Label.TextColor3 = IsActive and Palette.TextPrimary or Palette.TextSecondary
        Label.TextXAlignment = Enum.TextXAlignment.Left

        if Shortcut then
            local Pill = Instance.new("TextLabel", Item)
            Pill.Size = UDim2.new(0, 45, 0, 18)
            Pill.Position = UDim2.new(1, -55, 0.5, -9)
            Pill.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
            Pill.Text = Shortcut
            Pill.TextColor3 = Palette.TextSecondary
            Pill.Font = Enum.Font.Gotham
            Pill.TextSize = 10
            Pill.ZIndex = 2
            Instance.new("UICorner", Pill).CornerRadius = UDim.new(0, 4)
        end

        -- Premium Sirius Effects: Shimmer & Click Stroke
        local Shimmer = Instance.new("UIGradient", Item)
        Shimmer.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))
        })
        Shimmer.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0.8),
            NumberSequenceKeypoint.new(1, 1)
        })
        Shimmer.Rotation = 45
        Shimmer.Offset = Vector2.new(-1, 0)

        local ClickStroke = Instance.new("UIStroke", Item)
        ClickStroke.Color = Color3.new(1, 1, 1)
        ClickStroke.Thickness = 1.2
        ClickStroke.Transparency = 1
        ClickStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

        -- Hover Logic
        Item.MouseEnter:Connect(function()
            if not IsActive then
                TweenService:Create(Item, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.9, BackgroundColor3 = Palette.Accent}):Play()
            end
            -- Shimmer Animation
            Shimmer.Offset = Vector2.new(-1, 0)
            TweenService:Create(Shimmer, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Offset = Vector2.new(1, 0)}):Play()
        end)

        Item.MouseLeave:Connect(function()
            if not IsActive then
                TweenService:Create(Item, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()
            end
        end)

        -- Click Feedback Logic
        Item.MouseButton1Down:Connect(function()
            TweenService:Create(ClickStroke, TweenInfo.new(0.1, Enum.EasingStyle.Quint), {Transparency = 0}):Play()
            TweenService:Create(Item, TweenInfo.new(0.1, Enum.EasingStyle.Quint), {Size = UDim2.new(1, -4, 0, 42)}):Play() -- Subtle squash
        end)

        Item.MouseButton1Up:Connect(function()
            TweenService:Create(ClickStroke, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {Transparency = 1}):Play()
            TweenService:Create(Item, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 44)}):Play()
        end)

        return Item
    end

    -- Reload Item (Fixed at bottom)
    local ReloadBtn = CreateNavItem(BottomSection, "Reload", "rotate-cw", "Rec", 0, false)
    ReloadBtn.MouseButton1Click:Connect(function()
        SG:Destroy()
        if Options.ReloadURL then
            task.spawn(function()
                loadstring(game:HttpGet(Options.ReloadURL, true))()
            end)
        else
            print("[SkenaUI] No ReloadURL specified in CreateWindow options.")
        end
    end)

    function WindowObj:CreateTab(Name, Icon, Shortcut)
        local TabOrder = #WindowObj.Tabs + 2
        local TabItem = CreateNavItem(BodyFrame, Name, Icon, Shortcut, TabOrder, #WindowObj.Tabs == 0)
        
        local Tab = {
            Name = Name,
            Item = TabItem
        }
        
        function Tab:CreateInputRow() end -- Placeholder for now
        
        table.insert(WindowObj.Tabs, Tab)
        return Tab
    end

    return WindowObj
end

return SkenaUI
