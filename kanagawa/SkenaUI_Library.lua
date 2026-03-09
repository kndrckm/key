local SkenaUI = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

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

-- One Dark Glassmorphism Palette
local Palette = {
    Background  = Color3.fromRGB(40, 44, 52),    -- #282C34 base
    Sidebar     = Color3.fromRGB(33, 37, 43),    -- #21252B darker panel
    Card        = Color3.fromRGB(44, 49, 59),    -- #2C313B elevated surface
    RowItem     = Color3.fromRGB(44, 49, 59),    -- #2C313B
    RowHover    = Color3.fromRGB(53, 59, 69),    -- #353B45 hover state
    TextPrimary = Color3.fromRGB(171, 178, 191), -- #ABB2BF
    TextSecondary = Color3.fromRGB(92, 99, 112), -- #5C6370
    Accent      = Color3.fromRGB(97, 175, 239),  -- #61AFEF blue
    AccentDark  = Color3.fromRGB(78, 150, 210),  -- slightly darker blue
    Border      = Color3.fromRGB(60, 65, 75),    -- subtle border
    RedHover    = Color3.fromRGB(224, 108, 117),  -- #E06C75
    InputHdr    = Color3.fromRGB(33, 37, 43),    -- #21252B
    Green       = Color3.fromRGB(152, 195, 121), -- #98C379 for toggle on
    Yellow      = Color3.fromRGB(229, 192, 123), -- #E5C07B
    Purple      = Color3.fromRGB(198, 120, 221), -- #C678DD
    Cyan        = Color3.fromRGB(86, 182, 194),  -- #56B6C2

    -- Glass effect values
    GlassTransparency = 0.35,
    GlassBorder = Color3.fromRGB(255, 255, 255), -- white at low opacity for glass edge
    GlassBorderTransparency = 0.88,
}


local function ApplyGlassEffect(frame, intensity)
    intensity = intensity or "normal" -- "subtle", "normal", "strong"

    -- Glass border (thin white edge)
    local stroke = frame:FindFirstChildOfClass("UIStroke")
    if not stroke then
        stroke = Instance.new("UIStroke", frame)
    end
    stroke.Color = Palette.GlassBorder
    stroke.Thickness = 1

    if intensity == "subtle" then
        stroke.Transparency = 0.92
        frame.BackgroundTransparency = 0.5
    elseif intensity == "strong" then
        stroke.Transparency = 0.82
        frame.BackgroundTransparency = 0.2
    else -- normal
        stroke.Transparency = Palette.GlassBorderTransparency
        frame.BackgroundTransparency = Palette.GlassTransparency
    end
end

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

    -- Glassmorphism: blur the game world behind the UI
    local _blurEffect = Instance.new("BlurEffect")
    _blurEffect.Name = "SkenaUI_Blur"
    _blurEffect.Size = 16
    _blurEffect.Parent = Lighting

    local WindowObj = {
        CurrentTab = nil,
        Tabs = {},
        ToggleKey = Enum.KeyCode.Z,
        Cooldowns = {}
    }

    local DragFrame = Instance.new("Frame", SG)
    DragFrame.Name = "DragFrame"
    DragFrame.Size = UDim2.new(0, 450, 0, 420) 
    DragFrame.Position = UDim2.new(0.5, -225, 0.5, -210)
    DragFrame.BackgroundTransparency = 1
    DragFrame.Active = true

    local Main = Instance.new("CanvasGroup", DragFrame)
    Main.Name = "Main"
    Main.Size = UDim2.new(1, 0, 1, 0) 
    Main.BackgroundColor3 = Palette.Background
    Main.BorderSizePixel = 0
    
    local MainCorner = Instance.new("UICorner", Main)
    MainCorner.CornerRadius = UDim.new(0, 16)
    ApplyGlassEffect(Main, "strong")
    

    local MainScale = Instance.new("UIScale", Main)
    MainScale.Scale = 0.85
    
    -- Initial Fade In Pop-Up
    Main.GroupTransparency = 1
    TweenService:Create(Main, TweenInfo.new(0.35, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {GroupTransparency = 0}):Play()
    TweenService:Create(MainScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()

    local uiVisible = true
    local isScaled = false -- state track untuk logic original
    local function ToggleUIAnim()
        uiVisible = not uiVisible
        if uiVisible then
            SG.Enabled = true
            if _blurEffect then _blurEffect.Size = 16 end
            MainScale.Scale = 0.85
            Main.GroupTransparency = 1
            TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {GroupTransparency = 0}):Play()
            
            -- Restore ke skala aslinya menyesuaikan kondisi terakhir
            local targetScale = isScaled and 0.75 or 1 
            TweenService:Create(MainScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = targetScale}):Play()
        else
            local tw = TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {GroupTransparency = 1})
            TweenService:Create(MainScale, TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {Scale = 0.9}):Play()
            tw:Play()
            task.delay(0.2, function()
                if not uiVisible then SG.Enabled = false end
                if _blurEffect then _blurEffect.Size = 0 end
            end)
        end
    end

    -- Global shortcut to toggle UI w/ Animation
    local uiToggleConnection
    uiToggleConnection = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == WindowObj.ToggleKey then
            ToggleUIAnim()
        end
    end)
    
    -- When SG is destroyed, cleanup Toggle shortcut
    SG.Destroying:Connect(function()
        if uiToggleConnection then uiToggleConnection:Disconnect() end
        if _blurEffect then _blurEffect:Destroy() _blurEffect = nil end
    end)

    -- Drag Logic
    local dragging, dragInput, dragStart, startPos
    DragFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPos = DragFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    DragFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            DragFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Top Area (Title Bar Controls)
    local TitleBar = Instance.new("Frame", Main)
    TitleBar.Size = UDim2.new(1, 0, 0, 32)
    TitleBar.BackgroundTransparency = 1

    local TitleText = Instance.new("TextLabel", TitleBar)
    TitleText.Size = UDim2.new(1, -100, 1, 0)
    TitleText.Position = UDim2.new(0, 12, 0, 0)
    TitleText.BackgroundTransparency = 1
    TitleText.Text = WindowName
    TitleText.Font = Enum.Font.Gotham
    TitleText.TextSize = 12
    TitleText.TextColor3 = Palette.TextSecondary
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    WindowObj.TitleText = TitleText

    local ControlContainer = Instance.new("Frame", TitleBar)
    ControlContainer.Size = UDim2.new(0, 96, 1, 0)
    ControlContainer.Position = UDim2.new(1, -104, 0, 0)
    ControlContainer.BackgroundTransparency = 1

    -- Modern floating window buttons
    local ScaleBtn = Instance.new("TextButton", ControlContainer)
    ScaleBtn.Size = UDim2.new(0, 26, 0, 26)
    ScaleBtn.Position = UDim2.new(0, 0, 0.5, -13)
    ScaleBtn.Text = "" -- Replaced by Icon
    ScaleBtn.BackgroundColor3 = Palette.Background
    ScaleBtn.BackgroundTransparency = 1
    ScaleBtn.TextColor3 = Palette.TextPrimary
    ScaleBtn.Font = Enum.Font.Gotham
    ScaleBtn.TextSize = 14
    ScaleBtn.BorderSizePixel = 0
    Instance.new("UICorner", ScaleBtn).CornerRadius = UDim.new(0, 10)

    local ScaleIcon = Instance.new("ImageLabel", ScaleBtn)
    ScaleIcon.Size = UDim2.new(0, 14, 0, 14)
    ScaleIcon.Position = UDim2.new(0.5, -7, 0.5, -7)
    ScaleIcon.BackgroundTransparency = 1
    ScaleIcon.Image = "rbxassetid://10734886735" -- lucide-maximize
    ScaleIcon.ImageColor3 = Palette.TextPrimary

    local Minibtn = Instance.new("TextButton", ControlContainer)
    Minibtn.Size = UDim2.new(0, 26, 0, 26)
    Minibtn.Position = UDim2.new(0, 32, 0.5, -13)
    Minibtn.Text = "-"
    Minibtn.BackgroundColor3 = Palette.Background
    Minibtn.BackgroundTransparency = 1
    Minibtn.TextColor3 = Palette.TextPrimary
    Minibtn.Font = Enum.Font.Gotham
    Minibtn.TextSize = 14
    Minibtn.BorderSizePixel = 0
    Instance.new("UICorner", Minibtn).CornerRadius = UDim.new(0, 10)

    local CloseBtn = Instance.new("TextButton", ControlContainer)
    CloseBtn.Size = UDim2.new(0, 26, 0, 26)
    CloseBtn.Position = UDim2.new(0, 64, 0.5, -13)
    CloseBtn.Text = "X"
    CloseBtn.BackgroundColor3 = Palette.Background
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.TextColor3 = Palette.TextPrimary
    CloseBtn.Font = Enum.Font.Gotham
    CloseBtn.TextSize = 14
    CloseBtn.BorderSizePixel = 0
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 10)

    -- Hover logic for window controls
    ScaleBtn.MouseEnter:Connect(function() ScaleBtn.BackgroundTransparency = 0; ScaleBtn.BackgroundColor3 = Palette.RowHover end)
    ScaleBtn.MouseLeave:Connect(function() ScaleBtn.BackgroundTransparency = 1 end)
    Minibtn.MouseEnter:Connect(function() Minibtn.BackgroundTransparency = 0; Minibtn.BackgroundColor3 = Palette.RowHover end)
    Minibtn.MouseLeave:Connect(function() Minibtn.BackgroundTransparency = 1 end)
    CloseBtn.MouseEnter:Connect(function() CloseBtn.BackgroundTransparency = 0; CloseBtn.BackgroundColor3 = Palette.RedHover end)
    CloseBtn.MouseLeave:Connect(function() CloseBtn.BackgroundTransparency = 1 end)

    ScaleBtn.MouseButton1Click:Connect(function()
        isScaled = not isScaled
        local targetScale = isScaled and 0.75 or 1
        TweenService:Create(MainScale, TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Scale = targetScale}):Play()
    end)

    Minibtn.MouseButton1Click:Connect(function()
        ToggleUIAnim()
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        if _blurEffect then _blurEffect:Destroy() _blurEffect = nil end
        SG:Destroy()
    end)

    -- Under Title Bar
    local BodyFrame = Instance.new("Frame", Main)
    BodyFrame.Size = UDim2.new(1, 0, 1, -72)
    BodyFrame.Position = UDim2.new(0, 0, 0, 72)
    BodyFrame.BackgroundTransparency = 1
    
    local BodyPadding = Instance.new("UIPadding", BodyFrame)
    BodyPadding.PaddingBottom = UDim.new(0, 12)

    -- NavBar (horizontal tab bar below TitleBar)
    local NavBar = Instance.new("Frame", Main)
    NavBar.Name = "NavBar"
    NavBar.Size = UDim2.new(1, 0, 0, 40)
    NavBar.Position = UDim2.new(0, 0, 0, 32)
    NavBar.BackgroundTransparency = 1
    NavBar.BorderSizePixel = 0

    local NavScroll = Instance.new("ScrollingFrame", NavBar)
    NavScroll.Name = "NavScroll"
    NavScroll.Size = UDim2.new(1, -16, 1, 0)
    NavScroll.Position = UDim2.new(0, 8, 0, 0)
    NavScroll.BackgroundTransparency = 1
    NavScroll.BorderSizePixel = 0
    NavScroll.ScrollBarThickness = 0
    NavScroll.ScrollingDirection = Enum.ScrollingDirection.X
    NavScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
    NavScroll.CanvasSize = UDim2.new(0, 0, 1, 0)
    NavScroll.ClipsDescendants = true

    local NavLayout = Instance.new("UIListLayout", NavScroll)
    NavLayout.FillDirection = Enum.FillDirection.Horizontal
    NavLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    NavLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    NavLayout.SortOrder = Enum.SortOrder.LayoutOrder
    NavLayout.Padding = UDim.new(0, 4)

    local NavPadding = Instance.new("UIPadding", NavScroll)
    NavPadding.PaddingLeft = UDim.new(0, 4)
    NavPadding.PaddingRight = UDim.new(0, 4)

    -- Inner Card (Full-width)
    local Card = Instance.new("Frame", BodyFrame)
    Card.Size = UDim2.new(1, -16, 1, -8)
    Card.Position = UDim2.new(0, 8, 0, 0)
    Card.BackgroundColor3 = Palette.Card
    Card.BorderSizePixel = 0
    Card.ClipsDescendants = true

    local CardCorner = Instance.new("UICorner", Card)
    CardCorner.CornerRadius = UDim.new(0, 16)
    ApplyGlassEffect(Card, "normal")

    -- ScrollingFrame inside Card
    local CardScroll = Instance.new("ScrollingFrame", Card)
    CardScroll.Size = UDim2.new(1, 0, 1, 0)
    CardScroll.BackgroundTransparency = 1
    CardScroll.BorderSizePixel = 0
    CardScroll.ScrollBarThickness = 3
    CardScroll.ScrollBarImageColor3 = Palette.Accent
    CardScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    CardScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    CardScroll.ScrollingDirection = Enum.ScrollingDirection.Y
    
    local ScrollPadding = Instance.new("UIPadding", CardScroll)
    ScrollPadding.PaddingTop = UDim.new(0, 12)
    ScrollPadding.PaddingBottom = UDim.new(0, 12)
    ScrollPadding.PaddingLeft = UDim.new(0, 12)
    ScrollPadding.PaddingRight = UDim.new(0, 16)

    local TabContainer = Instance.new("Folder", CardScroll)
    TabContainer.Name = "Tabs"
    
    local function CreateTabButton(TabName, IconID, isSettings)
        local TabBtn = Instance.new("TextButton", NavScroll)
        TabBtn.Name = "Tab_" .. TabName
        TabBtn.Size = UDim2.new(0, 0, 0, 32)
        TabBtn.AutomaticSize = Enum.AutomaticSize.X
        TabBtn.BackgroundColor3 = Palette.RowHover
        TabBtn.BackgroundTransparency = 1
        TabBtn.Text = ""
        TabBtn.AutoButtonColor = false
        TabBtn.LayoutOrder = isSettings and 9999 or 0
        Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 8)

        local BtnPadding = Instance.new("UIPadding", TabBtn)
        BtnPadding.PaddingLeft = UDim.new(0, 10)
        BtnPadding.PaddingRight = UDim.new(0, 10)

        local BtnLayout = Instance.new("UIListLayout", TabBtn)
        BtnLayout.FillDirection = Enum.FillDirection.Horizontal
        BtnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        BtnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        BtnLayout.SortOrder = Enum.SortOrder.LayoutOrder
        BtnLayout.Padding = UDim.new(0, 6)

        local TabIcon = Instance.new("ImageLabel", TabBtn)
        TabIcon.Name = "Icon"
        TabIcon.Size = UDim2.new(0, 16, 0, 16)
        TabIcon.BackgroundTransparency = 1
        TabIcon.LayoutOrder = 1

        local finalImage = ""
        if type(IconID) == "string" then
            local checkKey = "lucide-" .. IconID
            if LucideIcons[checkKey] then
                finalImage = LucideIcons[checkKey]
            elseif LucideIcons[IconID] then
                finalImage = LucideIcons[IconID]
            else
                finalImage = "rbxassetid://10709798174"
            end
        else
            finalImage = "rbxassetid://" .. tostring(IconID)
        end

        TabIcon.Image = finalImage
        TabIcon.ImageColor3 = Palette.TextSecondary

        local TabLabel = Instance.new("TextLabel", TabBtn)
        TabLabel.Name = "Label"
        TabLabel.Size = UDim2.new(0, 0, 1, 0)
        TabLabel.AutomaticSize = Enum.AutomaticSize.X
        TabLabel.BackgroundTransparency = 1
        TabLabel.Text = TabName
        TabLabel.Font = Enum.Font.Gotham
        TabLabel.TextSize = 12
        TabLabel.TextColor3 = Palette.TextSecondary
        TabLabel.LayoutOrder = 2

        -- Bottom underline indicator (iOS style)
        local Indicator = Instance.new("Frame", TabBtn)
        Indicator.Name = "Indicator"
        Indicator.Size = UDim2.new(1, -8, 0, 2)
        Indicator.Position = UDim2.new(0, 4, 1, -3)
        Indicator.BackgroundColor3 = Palette.Accent
        Indicator.BorderSizePixel = 0
        Indicator.Visible = false
        Instance.new("UICorner", Indicator).CornerRadius = UDim.new(1, 0)

        TabBtn.MouseEnter:Connect(function()
            if WindowObj.CurrentTab ~= TabName then
                TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
            end
        end)
        TabBtn.MouseLeave:Connect(function()
            if WindowObj.CurrentTab ~= TabName then
                TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            end
        end)

        return TabBtn, TabIcon, Indicator
    end

    function WindowObj:CreateTab(TabName, IconID, isSettings)
        local TabData = {}
        
        local TabBtn, TabIcon, Indicator = CreateTabButton(TabName, IconID, isSettings)

        local Page = Instance.new("CanvasGroup", TabContainer)
        Page.Size = UDim2.new(1, 0, 0, 150)
        Page.AutomaticSize = Enum.AutomaticSize.Y
        Page.BackgroundTransparency = 1
        Page.GroupTransparency = 1
        Page.Visible = false

        local PageConstraint = Instance.new("UISizeConstraint", Page)
        PageConstraint.MinSize = Vector2.new(0, 180)
        
        local PLayout = Instance.new("UIListLayout", Page)
        PLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PLayout.Padding = UDim.new(0, 4)

        function TabData:CreateInputRow(Options)
            local Title = Options.Name or "Input"
            local Default = Options.Default or ""
            local Placeholder = Options.Placeholder or ""
            local cb = Options.Callback or function() end
            
            local Row = AddRowContainer()
            
            local Txt = Instance.new("TextLabel", Row)
            Txt.Size = UDim2.new(0.5, 0, 1, 0)
            Txt.Position = UDim2.new(0, 12, 0, 0)
            Txt.BackgroundTransparency = 1
            Txt.Text = Title
            Txt.Font = Enum.Font.Gotham
            Txt.TextSize = 13
            Txt.TextColor3 = Palette.TextPrimary
            Txt.TextXAlignment = Enum.TextXAlignment.Left

            local Box = Instance.new("TextBox", Row)
            Box.Size = UDim2.new(0, 100, 0, 24)
            Box.Position = UDim2.new(1, -112, 0.5, -12)
            Box.BackgroundColor3 = Palette.InputHdr
            Box.Text = tostring(Default)
            Box.PlaceholderText = Placeholder
            Box.TextColor3 = Palette.TextPrimary
            Box.Font = Enum.Font.Gotham
            Box.TextSize = 12
            Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 4)
            
            Box.FocusLost:Connect(function()
                pcall(cb, Box.Text)
            end)
            
            return Row
        end

        function TabData:CreateAutoFarmGroup(Options)
            local GroupName = Options.Name or "Auto Farm"
            local MasterCallback = Options.OnMasterToggle or function() end
            
            local GroupFrame = Instance.new("Frame", Page)
            GroupFrame.Size = UDim2.new(1, 0, 0, 0)
            GroupFrame.AutomaticSize = Enum.AutomaticSize.Y
            GroupFrame.BackgroundColor3 = Palette.Card
            GroupFrame.BorderSizePixel = 0
            Instance.new("UICorner", GroupFrame).CornerRadius = UDim.new(0, 16)
            
            local GLayout = Instance.new("UIListLayout", GroupFrame)
            GLayout.SortOrder = Enum.SortOrder.LayoutOrder
            GLayout.Padding = UDim.new(0, 4)
            Instance.new("UIPadding", GroupFrame).PaddingBottom = UDim.new(0, 12)

            local Header = Instance.new("Frame", GroupFrame)
            Header.Size = UDim2.new(1, 0, 0, 36)
            Header.BackgroundTransparency = 1
            
            local HTxt = Instance.new("TextLabel", Header)
            HTxt.Size = UDim2.new(1, -60, 1, 0)
            HTxt.Position = UDim2.new(0, 12, 0, 0)
            HTxt.BackgroundTransparency = 1
            HTxt.Text = GroupName
            HTxt.Font = Enum.Font.Gotham
            HTxt.TextSize = 14
            HTxt.TextColor3 = Palette.TextPrimary
            HTxt.TextXAlignment = Enum.TextXAlignment.Left

            if Options.HasMasterToggle then
                local masterState = false
                local MToggle = Instance.new("TextButton", Header)
                MToggle.Size = UDim2.new(0, 40, 0, 20)
                MToggle.Position = UDim2.new(1, -52, 0.5, -10)
                MToggle.BackgroundColor3 = Palette.InputHdr
                MToggle.Text = ""
                Instance.new("UICorner", MToggle).CornerRadius = UDim.new(1, 0)
                ApplyGlassEffect(MToggle, "subtle") -- glass effect for input
                local MKnob = Instance.new("Frame", MToggle)
                MKnob.Size = UDim2.new(0, 14, 0, 14)
                MKnob.Position = UDim2.new(0, 3, 0.5, -7)
                MKnob.BackgroundColor3 = Palette.TextSecondary
                Instance.new("UICorner", MKnob).CornerRadius = UDim.new(1, 0)
                
                MToggle.MouseButton1Click:Connect(function()
                    masterState = not masterState
                    TweenService:Create(MToggle, TweenInfo.new(0.2), {BackgroundColor3 = masterState and Palette.Green or Palette.InputHdr}):Play()
                    TweenService:Create(MKnob, TweenInfo.new(0.2), {Position = masterState and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)}):Play()
                    pcall(MasterCallback, masterState)
                end)
            end

            local SkillObj = {}
            
            function SkillObj:AddSkill(Name, Default, OnToggle, OnDelay)
                local Row = Instance.new("Frame", GroupFrame)
                Row.Size = UDim2.new(1, -16, 0, 32)
                Row.Position = UDim2.new(0, 8, 0, 0)
                Row.BackgroundTransparency = 1
                
                local Txt = Instance.new("TextLabel", Row)
                Txt.Size = UDim2.new(0.4, 0, 1, 0)
                Txt.BackgroundTransparency = 1
                Txt.Text = Name
                Txt.Font = Enum.Font.Gotham
                Txt.TextSize = 12
                Txt.TextColor3 = Palette.TextSecondary
                Txt.TextXAlignment = Enum.TextXAlignment.Left

                local skillState = Default or false
                local Tgl = Instance.new("TextButton", Row)
                Tgl.Size = UDim2.new(0, 32, 0, 16)
                Tgl.Position = UDim2.new(0.4, 0, 0.5, -8)
                Tgl.BackgroundColor3 = skillState and Palette.Green or Palette.InputHdr
                Tgl.Text = ""
                Instance.new("UICorner", Tgl).CornerRadius = UDim.new(1, 0)
                
                Tgl.MouseButton1Click:Connect(function()
                    skillState = not skillState
                    Tgl.BackgroundColor3 = skillState and Palette.Green or Palette.InputHdr
                    pcall(OnToggle, skillState)
                end)

                local Box = Instance.new("TextBox", Row)
                Box.Size = UDim2.new(0, 40, 0, 20)
                Box.Position = UDim2.new(1, -45, 0.5, -10)
                Box.BackgroundColor3 = Palette.InputHdr
                Box.Text = "10"
                Box.TextColor3 = Palette.TextPrimary
                Box.Font = Enum.Font.Gotham
                Box.TextSize = 11
                Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 4)
                ApplyGlassEffect(Box, "subtle") -- glass effect for input
                
                Box.FocusLost:Connect(function()
                    pcall(OnDelay, Box.Text)
                end)
            end

            function SkillObj:AddMultiSkillRow(SkillsData)
                local Row = Instance.new("Frame", GroupFrame)
                Row.Size = UDim2.new(1, -16, 0, 32)
                Row.Position = UDim2.new(0, 8, 0, 0)
                Row.BackgroundTransparency = 1

                local Layout = Instance.new("UIListLayout", Row)
                Layout.FillDirection = Enum.FillDirection.Horizontal
                Layout.Padding = UDim.new(0, 4)
                Layout.VerticalAlignment = Enum.VerticalAlignment.Center

                for _, data in ipairs(SkillsData) do
                    local SkillBox = Instance.new("Frame", Row)
                    SkillBox.Size = UDim2.new(0.33, -3, 0, 26)
                    SkillBox.BackgroundTransparency = 1
                    
                    local SLayout = Instance.new("UIListLayout", SkillBox)
                    SLayout.FillDirection = Enum.FillDirection.Horizontal
                    SLayout.Padding = UDim.new(0, 3)
                    SLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                    SLayout.SortOrder = Enum.SortOrder.LayoutOrder

                    local Btn = Instance.new("TextButton", SkillBox)
                    Btn.Size = UDim2.new(0, 42, 0, 20)
                    local state = data.DefaultToggle or false
                    Btn.BackgroundColor3 = state and Palette.Green or Palette.InputHdr
                    Btn.Text = data.Name or "Skill"
                    Btn.Font = Enum.Font.Gotham
                    Btn.TextSize = 10
                    Btn.TextColor3 = Palette.TextPrimary
                    Btn.LayoutOrder = 1
                    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
                    
                    Btn.MouseButton1Click:Connect(function()
                        state = not state
                        Btn.BackgroundColor3 = state and Palette.Green or Palette.InputHdr
                        pcall(data.OnToggle, state)
                    end)

                    local Box = Instance.new("TextBox", SkillBox)
                    Box.Size = UDim2.new(0, 24, 0, 20)
                    Box.BackgroundColor3 = Palette.InputHdr
                    Box.Text = tostring(data.DefaultDelay or "10")
                    Box.TextColor3 = Palette.TextPrimary
                    Box.Font = Enum.Font.Gotham
                    Box.TextSize = 10
                    Box.LayoutOrder = 2
                    Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 4)
                    Box.FocusLost:Connect(function() pcall(data.OnDelay, Box.Text) end)

                    local Sec = Instance.new("TextLabel", SkillBox)
                    Sec.Size = UDim2.new(0, 15, 1, 0)
                    Sec.BackgroundTransparency = 1
                    Sec.Text = "sec"
                    Sec.Font = Enum.Font.Gotham
                    Sec.TextSize = 9
                    Sec.TextColor3 = Palette.TextSecondary
                    Sec.LayoutOrder = 3
                end
            end

            function SkillObj:AddActionInputRow(Opt)
                local Row = Instance.new("Frame", GroupFrame)
                Row.Size = UDim2.new(1, -16, 0, 32)
                Row.Position = UDim2.new(0, 8, 0, 0)
                Row.BackgroundTransparency = 1
                
                -- Left Group: Toggle Button + Input + "sec"
                local Left = Instance.new("Frame", Row)
                Left.Size = UDim2.new(0.65, 0, 1, 0)
                Left.BackgroundTransparency = 1
                local LLayout = Instance.new("UIListLayout", Left)
                LLayout.FillDirection = Enum.FillDirection.Horizontal
                LLayout.Padding = UDim.new(0, 10)
                LLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                LLayout.SortOrder = Enum.SortOrder.LayoutOrder

                local state = Opt.DefaultToggle or false
                local TglBtn = Instance.new("TextButton", Left)
                TglBtn.Size = UDim2.new(0, 65, 0, 20)
                TglBtn.BackgroundColor3 = state and Palette.Green or Palette.InputHdr
                TglBtn.Text = Opt.Name or "Action"
                TglBtn.TextColor3 = Palette.TextPrimary
                TglBtn.Font = Enum.Font.Gotham
                TglBtn.TextSize = 10
                TglBtn.LayoutOrder = 1
                Instance.new("UICorner", TglBtn).CornerRadius = UDim.new(0, 4)
                TglBtn.MouseButton1Click:Connect(function()
                    state = not state
                    TglBtn.BackgroundColor3 = state and Palette.Green or Palette.InputHdr
                    pcall(Opt.OnToggle, state)
                end)

                local Box = Instance.new("TextBox", Left)
                Box.Size = UDim2.new(0, 32, 0, 20)
                Box.BackgroundColor3 = Palette.InputHdr
                Box.Text = Opt.InputDefault or ""
                Box.TextColor3 = Palette.TextPrimary
                Box.Font = Enum.Font.Gotham
                Box.TextSize = 11
                Box.LayoutOrder = 2
                Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 4)
                Box.FocusLost:Connect(function() pcall(Opt.Callback, Box.Text) end)

                local Sec = Instance.new("TextLabel", Left)
                Sec.AutomaticSize = Enum.AutomaticSize.X
                Sec.Size = UDim2.new(0, 0, 0.5, 0)
                Sec.BackgroundTransparency = 1
                Sec.Text = "sec"
                Sec.Font = Enum.Font.Gotham
                Sec.TextSize = 10
                Sec.TextColor3 = Palette.TextSecondary
                Sec.LayoutOrder = 3

                -- Right Group: Status + Button
                local Right = Instance.new("Frame", Row)
                Right.Size = UDim2.new(0.35, 0, 1, 0)
                Right.Position = UDim2.new(0.65, 0, 0, 0)
                Right.BackgroundTransparency = 1
                local RLayout = Instance.new("UIListLayout", Right)
                RLayout.FillDirection = Enum.FillDirection.Horizontal
                RLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
                RLayout.Padding = UDim.new(0, 12)
                RLayout.VerticalAlignment = Enum.VerticalAlignment.Center

                local Status = Instance.new("TextLabel", Right)
                Status.AutomaticSize = Enum.AutomaticSize.X
                Status.Size = UDim2.new(0, 0, 0.5, 0)
                Status.BackgroundTransparency = 1
                Status.Text = Opt.StatusText or ""
                Status.Font = Enum.Font.Gotham
                Status.TextSize = 10
                Status.TextColor3 = Color3.fromRGB(150, 150, 150)

                local Btn = Instance.new("TextButton", Right)
                Btn.Size = UDim2.new(0, 90, 0, 20)
                Btn.BackgroundColor3 = Palette.InputHdr
                Btn.Text = Opt.ButtonText or "Action"
                Btn.TextColor3 = Palette.TextPrimary
                Btn.Font = Enum.Font.Gotham
                Btn.TextSize = 11
                Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
                ApplyGlassEffect(Btn, "subtle") -- glass effect for input
                Btn.MouseButton1Click:Connect(function() pcall(Opt.OnButton) end)
                
                return {Row = Row, StatusLabel = Status, Button = Btn}
            end

            return SkillObj
        end

        WindowObj.Tabs[TabName] = { Button = TabBtn, Icon = TabIcon, Indicator = Indicator, Page = Page }
        
        TabBtn.MouseButton1Click:Connect(function() WindowObj:SelectTab(TabName) end)

        if not WindowObj.CurrentTab then WindowObj:SelectTab(TabName) end

        -- Header within Tab
        local Header = Instance.new("TextLabel", Page)
        Header.Size = UDim2.new(1, 0, 0, 36)
        Header.BackgroundTransparency = 1
        Header.Text = TabName
        Header.Font = Enum.Font.GothamBold
        Header.TextSize = 20
        Header.TextColor3 = Palette.TextPrimary
        Header.TextXAlignment = Enum.TextXAlignment.Left

        -- Utility to add a generic Row Container
        local function AddRowContainer()
            local Row = Instance.new("Frame", Page)
            Row.Size = UDim2.new(1, 0, 0, 44)
            Row.BackgroundColor3 = Palette.RowItem
            Row.BorderSizePixel = 0
            Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 12)
            ApplyGlassEffect(Row, "subtle")
            return Row
        end

        function TabData:CreateToggleRow(Options)
            local Title = Options.Name or "Toggle"
            local cbToggle = Options.OnToggle or function() end
            
            local Row = AddRowContainer()
            
            local Txt = Instance.new("TextLabel", Row)
            Txt.Size = UDim2.new(0.4, 0, 1, 0)
            Txt.Position = UDim2.new(0, 12, 0, 0)
            Txt.BackgroundTransparency = 1
            Txt.Text = Title
            Txt.Font = Enum.Font.Gotham
            Txt.TextSize = 13
            Txt.TextColor3 = Palette.TextPrimary
            Txt.TextXAlignment = Enum.TextXAlignment.Left

            local RightContainer = Instance.new("Frame", Row)
            RightContainer.Size = UDim2.new(0.6, -12, 1, 0)
            RightContainer.Position = UDim2.new(0.4, 0, 0, 0)
            RightContainer.BackgroundTransparency = 1
            local RCLayout = Instance.new("UIListLayout", RightContainer)
            RCLayout.FillDirection = Enum.FillDirection.Horizontal
            RCLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
            RCLayout.VerticalAlignment = Enum.VerticalAlignment.Center
            RCLayout.Padding = UDim.new(0, 12)
            RCLayout.SortOrder = Enum.SortOrder.LayoutOrder

            -- Toggle Button
            local ToggleBg = Instance.new("TextButton", RightContainer)
            ToggleBg.Size = UDim2.new(0, 44, 0, 22)
            ToggleBg.BackgroundColor3 = Palette.InputHdr
            ToggleBg.Text = ""
            ToggleBg.AutoButtonColor = false
            ToggleBg.LayoutOrder = 10
            Instance.new("UICorner", ToggleBg).CornerRadius = UDim.new(1, 0)
            ApplyGlassEffect(ToggleBg, "subtle") -- glass effect for input

            local Knob = Instance.new("Frame", ToggleBg)
            Knob.Size = UDim2.new(0, 14, 0, 14)
            Knob.Position = UDim2.new(0, 4, 0.5, -7)
            Knob.BackgroundColor3 = Palette.TextSecondary
            Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

            local state = Options.Default or false

            local function UpdateToggleRender(noAnim)
                local targetColor = state and Palette.Green or Palette.InputHdr
                local knobColor = state and Color3.fromRGB(255, 255, 255) or Palette.TextSecondary
                local knobPos = state and UDim2.new(1, -18, 0.5, -7) or UDim2.new(0, 4, 0.5, -7)
                
                if noAnim then
                    ToggleBg.BackgroundColor3 = targetColor
                    Knob.BackgroundColor3 = knobColor
                    Knob.Position = knobPos
                else
                    TweenService:Create(ToggleBg, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
                    TweenService:Create(Knob, TweenInfo.new(0.2), {BackgroundColor3 = knobColor, Position = knobPos}):Play()
                end
            end
            
            if state then UpdateToggleRender(true) end

            ToggleBg.MouseButton1Click:Connect(function()
                state = not state
                UpdateToggleRender(false)
                pcall(cbToggle, state)
            end)
            
            if Options.HasSubToggle then
                local SubBtn = Instance.new("TextButton", RightContainer)
                SubBtn.Size = UDim2.new(0, 64, 0, 22)
                SubBtn.BackgroundColor3 = Options.SubToggleDefault and Palette.Green or Palette.InputHdr
                SubBtn.Text = Options.SubToggleName or "Sub"
                SubBtn.TextColor3 = Color3.new(1,1,1)
                SubBtn.Font = Enum.Font.Gotham
                SubBtn.TextSize = 11
                SubBtn.LayoutOrder = 1
                Instance.new("UICorner", SubBtn).CornerRadius = UDim.new(0, 4)
                
                local subState = Options.SubToggleDefault == nil and true or Options.SubToggleDefault
                SubBtn.MouseButton1Click:Connect(function()
                    subState = not subState
                    SubBtn.BackgroundColor3 = subState and Palette.Green or Palette.InputHdr
                    pcall(Options.OnSubToggle, subState)
                end)
                -- Jalankan initial callback
                task.spawn(function() pcall(Options.OnSubToggle, subState) end)
            end
            local function attachTextBox(placeholder, defaultVal, callback, width, layoutOrder, prefix)
                local container = Instance.new("Frame", RightContainer)
                container.BackgroundTransparency = 1
                container.LayoutOrder = layoutOrder
                local UIList = Instance.new("UIListLayout", container)
                UIList.FillDirection = Enum.FillDirection.Horizontal
                UIList.VerticalAlignment = Enum.VerticalAlignment.Center
                UIList.Padding = UDim.new(0, 4)

                if prefix then
                    local lbl = Instance.new("TextLabel", container)
                    lbl.BackgroundTransparency = 1
                    lbl.Size = UDim2.new(0, 0, 0, 24)
                    lbl.AutomaticSize = Enum.AutomaticSize.X
                    lbl.Text = prefix
                    lbl.Font = Enum.Font.Gotham
                    lbl.TextSize = 12
                    lbl.TextColor3 = Palette.TextSecondary
                end

                local Box = Instance.new("TextBox", container)
                Box.Size = UDim2.new(0, width, 0, 24)
                Box.BackgroundColor3 = Palette.InputHdr
                Box.Text = tostring(defaultVal or "")
                Box.PlaceholderText = placeholder
                Box.TextColor3 = Palette.TextPrimary
                Box.Font = Enum.Font.Gotham
                Box.TextSize = 12
                Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 4)
                
                Box.FocusLost:Connect(function()
                    pcall(callback, Box.Text)
                end)
                container.Size = UDim2.new(0, 0, 0, 24)
                container.AutomaticSize = Enum.AutomaticSize.X
                return Box
            end

            local out = { ToggleState = function(s) state=s; UpdateToggleRender(true) end }
            
            if Options.HasKey then
                out.KeyBox = attachTextBox("Key", Options.DefaultKey, Options.OnKeyChange, 30, 9, nil)
            end
            if Options.HasSpeed then
                out.SpeedBox = attachTextBox("Spd", Options.DefaultSpeed, Options.OnSpeedChange, 40, 8, "Speed")
            end
            if Options.HasSpeedometer then
                local container = Instance.new("Frame", RightContainer)
                container.BackgroundTransparency = 1
                container.LayoutOrder = 7
                container.Size = UDim2.new(0, 50, 0, 24)
                
                local lbl = Instance.new("TextLabel", container)
                lbl.BackgroundTransparency = 1
                lbl.Size = UDim2.new(1, 0, 1, 0)
                lbl.Text = "0.0 s/s"
                lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 11
                lbl.TextColor3 = Palette.Accent
                lbl.TextXAlignment = Enum.TextXAlignment.Right
                
                out.Speedometer = lbl
            end
            if Options.HasInput then
                out.InputBox = attachTextBox(Options.InputPlaceholder or "", Options.InputDefault or "", Options.OnInputChange, Options.InputWidth or 80, 8, Options.InputPrefix)
            end

            return out
        end

        function TabData:CreateSliderRow(Options)
            local Title = Options.Name or "Slider"
            local Min = Options.Min or 0
            local Max = Options.Max or 100
            local Default = Options.Default or 50
            local Prefix = Options.Prefix or ""
            local Suffix = Options.Suffix or "%"
            local cb = Options.Callback or function() end

            local Row = AddRowContainer()

            local Txt = Instance.new("TextLabel", Row)
            Txt.Size = UDim2.new(0.3, 0, 1, 0)
            Txt.Position = UDim2.new(0, 12, 0, 0)
            Txt.BackgroundTransparency = 1
            Txt.Text = Title
            Txt.Font = Enum.Font.Gotham
            Txt.TextSize = 13
            Txt.TextColor3 = Palette.TextPrimary
            Txt.TextXAlignment = Enum.TextXAlignment.Left

            local RightContainer = Instance.new("Frame", Row)
            RightContainer.Size = UDim2.new(0.7, -12, 1, 0)
            RightContainer.Position = UDim2.new(0.3, 0, 0, 0)
            RightContainer.BackgroundTransparency = 1

            local ValTxt = Instance.new("TextLabel", RightContainer)
            ValTxt.Size = UDim2.new(0, 40, 1, 0)
            ValTxt.Position = UDim2.new(0, 0, 0, 0)
            ValTxt.BackgroundTransparency = 1
            ValTxt.Text = Prefix .. tostring(Default) .. Suffix
            ValTxt.Font = Enum.Font.Gotham
            ValTxt.TextSize = 12
            ValTxt.TextColor3 = Palette.TextSecondary
            ValTxt.TextXAlignment = Enum.TextXAlignment.Right

            -- Perbesar area interaksi (transparan) agar sangat mudah di-klik/geser
            local SlideBg = Instance.new("TextButton", RightContainer)
            SlideBg.Size = UDim2.new(1, -50, 0, 24)
            SlideBg.Position = UDim2.new(0, 50, 0.5, -12)
            SlideBg.BackgroundTransparency = 1
            SlideBg.Text = ""

            -- Garis visual
            local SlideTrack = Instance.new("Frame", SlideBg)
            SlideTrack.Size = UDim2.new(1, 0, 0, 6)
            SlideTrack.Position = UDim2.new(0, 0, 0.5, -3)
            SlideTrack.BackgroundColor3 = Palette.InputHdr
            Instance.new("UICorner", SlideTrack).CornerRadius = UDim.new(1,0)
            ApplyGlassEffect(SlideTrack, "subtle") -- glass effect for input

            -- Isi bar slider
            local SlideFill = Instance.new("Frame", SlideTrack)
            SlideFill.Size = UDim2.new((Default-Min)/(Max-Min), 0, 1, 0)
            SlideFill.BackgroundColor3 = Palette.TextPrimary
            Instance.new("UICorner", SlideFill).CornerRadius = UDim.new(1,0)

            -- Knob raksasa berbentuk persegi panjang lekuk
            local SlideKnob = Instance.new("Frame", SlideFill)
            SlideKnob.Size = UDim2.new(0, 12, 0, 16)
            SlideKnob.Position = UDim2.new(1, -6, 0.5, -8)
            SlideKnob.BackgroundColor3 = Palette.TextPrimary
            local KnobCorner = Instance.new("UICorner", SlideKnob)
            KnobCorner.CornerRadius = UDim.new(0, 4)

            local dragging = false
            local function update(input)
                local relX = math.clamp(input.Position.X - SlideBg.AbsolutePosition.X, 0, SlideBg.AbsoluteSize.X)
                local pct = relX / SlideBg.AbsoluteSize.X
                local val = math.floor(Min + (pct * (Max-Min)))
                SlideFill.Size = UDim2.new(pct, 0, 1, 0)
                ValTxt.Text = Prefix .. tostring(val) .. Suffix
                pcall(cb, val)
            end

            SlideBg.InputBegan:Connect(function(input) 
                if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging=true; update(input) end 
            end)
            UserInputService.InputEnded:Connect(function(input) 
                if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging=false end 
            end)
            UserInputService.InputChanged:Connect(function(input) 
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then update(input) end 
            end)
        end

        function TabData:CreateTextRow(Options)
            local Text = Options.Text or "Description string here"

            local Row = Instance.new("Frame", Page)
            Row.Size = UDim2.new(1, 0, 0, 0)
            Row.AutomaticSize = Enum.AutomaticSize.Y
            Row.BackgroundTransparency = 1
            Row.BorderSizePixel = 0

            local Txt = Instance.new("TextLabel", Row)
            Txt.Size = UDim2.new(1, -24, 0, 0)
            Txt.Position = UDim2.new(0, 12, 0, 0)
            Txt.AutomaticSize = Enum.AutomaticSize.Y
            Txt.BackgroundTransparency = 1
            Txt.Text = Text
            Txt.Font = Enum.Font.Gotham
            Txt.TextSize = 11
            Txt.TextColor3 = Palette.TextSecondary
            Txt.TextWrapped = true
            Txt.TextXAlignment = Enum.TextXAlignment.Left
            Txt.TextYAlignment = Enum.TextYAlignment.Top
            
            local padding = Instance.new("UIPadding", Txt)
            padding.PaddingTop = UDim.new(0, 4)
            padding.PaddingBottom = UDim.new(0, 4)
            
            return Row
        end

        function TabData:CreateButtonRow(Options)
            local Title = Options.Name or "Action"
            local BtnText = Options.ButtonText or "Execute"
            local cb = Options.Callback or function() end

            local Row = AddRowContainer()

            local Txt = Instance.new("TextLabel", Row)
            Txt.Size = UDim2.new(0.6, 0, 1, 0)
            Txt.Position = UDim2.new(0, 12, 0, 0)
            Txt.BackgroundTransparency = 1
            Txt.Text = Title
            Txt.Font = Enum.Font.Gotham
            Txt.TextSize = 13
            Txt.TextColor3 = Palette.TextPrimary
            Txt.TextXAlignment = Enum.TextXAlignment.Left

            local ExecBtn = Instance.new("TextButton", Row)
            ExecBtn.Size = UDim2.new(0, 80, 0, 24)
            ExecBtn.Position = UDim2.new(1, -92, 0.5, -12)
            ExecBtn.BackgroundColor3 = Palette.InputHdr
            ExecBtn.Text = BtnText
            ExecBtn.TextColor3 = Palette.TextPrimary
            ExecBtn.Font = Enum.Font.Gotham
            ExecBtn.TextSize = 12
            ExecBtn.AutoButtonColor = false
            Instance.new("UICorner", ExecBtn).CornerRadius = UDim.new(0, 4)

            ExecBtn.MouseEnter:Connect(function() TweenService:Create(ExecBtn, TweenInfo.new(0.2), {BackgroundColor3 = Palette.RowHover}):Play() end)
            ExecBtn.MouseLeave:Connect(function() TweenService:Create(ExecBtn, TweenInfo.new(0.2), {BackgroundColor3 = Palette.InputHdr}):Play() end)
            ExecBtn.MouseButton1Click:Connect(function() pcall(cb, ExecBtn) end)
            
            return { Row = Row, Button = ExecBtn }
        end

        function TabData:CreateToggleButtonRow(Options)
            local Title = Options.Name or "Toggle"
            local BtnText = Options.ButtonText or "Copy"
            local cbToggle = Options.OnToggle or function() end
            local cbButton = Options.OnButton or function() end

            local Row = AddRowContainer()

            local Txt = Instance.new("TextLabel", Row)
            Txt.Size = UDim2.new(0.35, 0, 1, 0)
            Txt.Position = UDim2.new(0, 12, 0, 0)
            Txt.BackgroundTransparency = 1
            Txt.Text = Title
            Txt.Font = Enum.Font.Gotham
            Txt.TextSize = 13
            Txt.TextColor3 = Palette.TextPrimary
            Txt.TextXAlignment = Enum.TextXAlignment.Left

            -- Toggle (center-left)
            local ToggleBg = Instance.new("TextButton", Row)
            ToggleBg.Size = UDim2.new(0, 36, 0, 18)
            ToggleBg.Position = UDim2.new(0.35, 12, 0.5, -9)
            ToggleBg.BackgroundColor3 = Palette.InputHdr
            ToggleBg.Text = ""
            ToggleBg.AutoButtonColor = false
            Instance.new("UICorner", ToggleBg).CornerRadius = UDim.new(1, 0)
            ApplyGlassEffect(ToggleBg, "subtle") -- glass effect for input

            local Knob = Instance.new("Frame", ToggleBg)
            Knob.Size = UDim2.new(0, 14, 0, 14)
            Knob.Position = UDim2.new(0, 4, 0.5, -7)
            Knob.BackgroundColor3 = Palette.TextSecondary
            Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

            local state = Options.Default or false

            local function UpdateToggleRender(noAnim)
                local targetColor = state and Palette.Green or Palette.InputHdr
                local knobColor = state and Color3.fromRGB(255, 255, 255) or Palette.TextSecondary
                local knobPos = state and UDim2.new(1, -18, 0.5, -7) or UDim2.new(0, 4, 0.5, -7)
                if noAnim then
                    ToggleBg.BackgroundColor3 = targetColor
                    Knob.BackgroundColor3 = knobColor
                    Knob.Position = knobPos
                else
                    TweenService:Create(ToggleBg, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
                    TweenService:Create(Knob, TweenInfo.new(0.2), {BackgroundColor3 = knobColor, Position = knobPos}):Play()
                end
            end

            if state then UpdateToggleRender(true) end

            ToggleBg.MouseButton1Click:Connect(function()
                state = not state
                UpdateToggleRender(false)
                pcall(cbToggle, state)
            end)

            -- Button (right)
            local ExecBtn = Instance.new("TextButton", Row)
            ExecBtn.Size = UDim2.new(0, 64, 0, 24)
            ExecBtn.Position = UDim2.new(1, -76, 0.5, -12)
            ExecBtn.BackgroundColor3 = Palette.InputHdr
            ExecBtn.Text = BtnText
            ExecBtn.TextColor3 = Palette.TextPrimary
            ExecBtn.Font = Enum.Font.Gotham
            ExecBtn.TextSize = 12
            ExecBtn.AutoButtonColor = false
            Instance.new("UICorner", ExecBtn).CornerRadius = UDim.new(0, 4)

            ExecBtn.MouseEnter:Connect(function() TweenService:Create(ExecBtn, TweenInfo.new(0.2), {BackgroundColor3 = Palette.RowHover}):Play() end)
            ExecBtn.MouseLeave:Connect(function() TweenService:Create(ExecBtn, TweenInfo.new(0.2), {BackgroundColor3 = Palette.InputHdr}):Play() end)
            ExecBtn.MouseButton1Click:Connect(function() pcall(cbButton, ExecBtn) end)

            return { Row = Row, Button = ExecBtn, ToggleState = function(s) state=s; UpdateToggleRender(true) end }
        end

        function TabData:CreateDoubleButtonRow(Options)
            local Title = Options.Name or "Double Action"
            local Btn1Text = Options.Button1Text or "Btn1"
            local Btn2Text = Options.Button2Text or "Btn2"
            local cb1 = Options.Callback1 or function() end
            local cb2 = Options.Callback2 or function() end

            local Row = AddRowContainer()

            local Txt = Instance.new("TextLabel", Row)
            Txt.Size = UDim2.new(0.4, 0, 1, 0)
            Txt.Position = UDim2.new(0, 12, 0, 0)
            Txt.BackgroundTransparency = 1
            Txt.Text = Title
            Txt.Font = Enum.Font.Gotham
            Txt.TextSize = 13
            Txt.TextColor3 = Palette.TextPrimary
            Txt.TextXAlignment = Enum.TextXAlignment.Left

            local RightContainer = Instance.new("Frame", Row)
            RightContainer.Size = UDim2.new(0.6, -12, 1, 0)
            RightContainer.Position = UDim2.new(0.4, 0, 0, 0)
            RightContainer.BackgroundTransparency = 1
            local RCLayout = Instance.new("UIListLayout", RightContainer)
            RCLayout.FillDirection = Enum.FillDirection.Horizontal
            RCLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
            RCLayout.VerticalAlignment = Enum.VerticalAlignment.Center
            RCLayout.Padding = UDim.new(0, 12)
            RCLayout.SortOrder = Enum.SortOrder.LayoutOrder

            local function SetupBtn(txt, callback, order)
                local btn = Instance.new("TextButton", RightContainer)
                btn.Size = UDim2.new(0, 80, 0, 24)
                btn.BackgroundColor3 = Palette.InputHdr
                btn.Text = txt
                btn.TextColor3 = Palette.TextPrimary
                btn.Font = Enum.Font.Gotham
                btn.TextSize = 12
                btn.AutoButtonColor = false
                btn.LayoutOrder = order
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

                btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Palette.RowHover}):Play() end)
                btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Palette.InputHdr}):Play() end)
                btn.MouseButton1Click:Connect(function() pcall(callback) end)
            end
            
            SetupBtn(Btn1Text, cb1, 1)
            SetupBtn(Btn2Text, cb2, 2)
        end

        function TabData:CreateDropdown(Options)
            local Title = Options.Name or "Dropdown"
            local cb = Options.Callback or function() end
            local columns = Options.Columns or 1
            local keepOpen = Options.KeepOpen or false
            local itemH = 26
            local gridGap = 4
            
            local Row = Instance.new("Frame", Page)
            Row.Size = UDim2.new(1, 0, 0, 0)
            Row.AutomaticSize = Enum.AutomaticSize.Y
            Row.BackgroundColor3 = Palette.RowItem
            Row.BorderSizePixel = 0
            Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 12)
            
            local Header = Instance.new("Frame", Row)
            Header.Size = UDim2.new(1, 0, 0, 44)
            Header.BackgroundTransparency = 1
            
            local Txt = Instance.new("TextLabel", Header)
            Txt.Size = UDim2.new(0.4, 0, 1, 0)
            Txt.Position = UDim2.new(0, 12, 0, 0)
            Txt.BackgroundTransparency = 1
            Txt.Text = Title
            Txt.Font = Enum.Font.Gotham
            Txt.TextSize = 13
            Txt.TextColor3 = Palette.TextPrimary
            Txt.TextXAlignment = Enum.TextXAlignment.Left

            local RightContainer = Instance.new("Frame", Header)
            RightContainer.Size = UDim2.new(0.6, -12, 1, 0)
            RightContainer.Position = UDim2.new(0.4, 0, 0, 0)
            RightContainer.BackgroundTransparency = 1
            local RCLayout = Instance.new("UIListLayout", RightContainer)
            RCLayout.FillDirection = Enum.FillDirection.Horizontal
            RCLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
            RCLayout.VerticalAlignment = Enum.VerticalAlignment.Center
            RCLayout.Padding = UDim.new(0, 12)
            
            local DropLabel = Instance.new("TextLabel", RightContainer)
            DropLabel.Size = UDim2.new(0, 100, 0, 24)
            DropLabel.BackgroundColor3 = Palette.InputHdr
            DropLabel.Text = "Select v"
            DropLabel.TextColor3 = Palette.TextSecondary
            DropLabel.Font = Enum.Font.Gotham
            DropLabel.TextSize = 12
            Instance.new("UICorner", DropLabel).CornerRadius = UDim.new(0, 4)
            ApplyGlassEffect(DropLabel, "subtle") -- glass effect for input
            
            local ExpandBtn = Instance.new("TextButton", DropLabel)
            ExpandBtn.Size = UDim2.new(1, 0, 1, 0)
            ExpandBtn.BackgroundTransparency = 1
            ExpandBtn.Text = ""
            
            ExpandBtn.MouseEnter:Connect(function() TweenService:Create(DropLabel, TweenInfo.new(0.2), {BackgroundColor3 = Palette.RowHover}):Play() end)
            ExpandBtn.MouseLeave:Connect(function() TweenService:Create(DropLabel, TweenInfo.new(0.2), {BackgroundColor3 = Palette.InputHdr}):Play() end)

            local DropFrame = Instance.new("Frame", Row)
            DropFrame.Size = UDim2.new(1, 0, 0, 0)
            DropFrame.Position = UDim2.new(0, 0, 0, 44)
            DropFrame.BackgroundTransparency = 1
            DropFrame.ClipsDescendants = true
            
            local Scroll = Instance.new("ScrollingFrame", DropFrame)
            Scroll.Size = UDim2.new(1, -16, 1, -8)
            Scroll.Position = UDim2.new(0, 8, 0, 0)
            Scroll.BackgroundTransparency = 1
            Scroll.ScrollBarThickness = 3
            Scroll.ScrollBarImageColor3 = Palette.Accent
            Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
            Scroll.BorderSizePixel = 0
            
            local itemCount = 0
            local expandedHeight = 155 -- default
            
            if columns > 1 then
                local SGrid = Instance.new("UIGridLayout", Scroll)
                SGrid.CellSize = UDim2.new(1 / columns, -(gridGap * 2), 0, itemH)
                SGrid.CellPadding = UDim2.new(0, gridGap, 0, gridGap)
                SGrid.SortOrder = Enum.SortOrder.LayoutOrder
                SGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
            else
                local SList = Instance.new("UIListLayout", Scroll)
                SList.Padding = UDim.new(0, gridGap)
                SList.SortOrder = Enum.SortOrder.LayoutOrder
            end
            
            local isExpanded = false
            ExpandBtn.MouseButton1Click:Connect(function()
                isExpanded = not isExpanded
                TweenService:Create(DropFrame, TweenInfo.new(0.25, Enum.EasingStyle.Cubic), {Size = isExpanded and UDim2.new(1, 0, 0, expandedHeight) or UDim2.new(1, 0, 0, 0)}):Play()
            end)

            local out = {}
            out.Items = {}
            function out:AddItem(itemStr, isDefault)
                itemCount = itemCount + 1
                local Itm = Instance.new("TextButton", Scroll)
                if columns > 1 then
                    Itm.Size = UDim2.new(1 / columns, -(gridGap * 2), 0, itemH)
                else
                    Itm.Size = UDim2.new(1, -8, 0, itemH)
                end
                Itm.BackgroundColor3 = isDefault and Palette.AccentDark or Palette.InputHdr
                Itm.Text = columns > 1 and itemStr or ("  " .. itemStr)
                Itm.TextXAlignment = columns > 1 and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
                Itm.TextColor3 = isDefault and Color3.new(1,1,1) or Palette.TextSecondary
                Itm.Font = Enum.Font.Gotham
                Itm.TextSize = columns > 1 and 11 or 12
                Itm.AutoButtonColor = false
                Instance.new("UICorner", Itm).CornerRadius = UDim.new(0,4)
                
                if isDefault then
                    DropLabel.Text = itemStr .. " v"
                    task.spawn(function() pcall(cb, itemStr) end)
                end
                
                table.insert(out.Items, {Btn = Itm, Str = itemStr})
                
                Itm.MouseButton1Click:Connect(function()
                    for _, data in ipairs(out.Items) do
                        data.Btn.BackgroundColor3 = Palette.InputHdr
                        data.Btn.TextColor3 = Palette.TextSecondary
                    end
                    Itm.BackgroundColor3 = Palette.AccentDark
                    Itm.TextColor3 = Color3.new(1,1,1)
                    DropLabel.Text = itemStr .. " v"
                    
                    if not keepOpen then
                        isExpanded = false
                        TweenService:Create(DropFrame, TweenInfo.new(0.15), {Size = UDim2.new(1, 0, 0, 0)}):Play()
                    end
                    
                    pcall(cb, itemStr)
                end)
                
                -- Recalculate expanded height
                local rows = math.ceil(itemCount / columns)
                expandedHeight = (rows * (itemH + gridGap)) + gridGap + 4
                Scroll.CanvasSize = UDim2.new(0, 0, 0, expandedHeight)
            end

            function out:ClearItems()
                for _, data in ipairs(out.Items) do
                    pcall(function() data.Btn:Destroy() end)
                end
                out.Items = {}
                itemCount = 0
                expandedHeight = 155
                Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
                DropLabel.Text = "Select v"
            end
            
            return out
        end

        function TabData:CreateDropdownToggle(Options)
            local Title = Options.Name or "Dropdown"
            local cb = Options.Callback or function() end
            local tcb = Options.OnToggle or function() end
            local columns = Options.Columns or 1
            local keepOpen = Options.KeepOpen or false
            local itemH = 26
            local gridGap = 4
            
            local Row = Instance.new("Frame", Page)
            Row.Size = UDim2.new(1, 0, 0, 0)
            Row.AutomaticSize = Enum.AutomaticSize.Y
            Row.BackgroundColor3 = Palette.RowItem
            Row.BorderSizePixel = 0
            Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 12)
            
            local Header = Instance.new("Frame", Row)
            Header.Size = UDim2.new(1, 0, 0, 44)
            Header.BackgroundTransparency = 1
            
            -- Left side: Title
            local Txt = Instance.new("TextLabel", Header)
            Txt.Size = UDim2.new(0.4, 0, 1, 0)
            Txt.Position = UDim2.new(0, 12, 0, 0)
            Txt.BackgroundTransparency = 1
            Txt.Text = Title
            Txt.Font = Enum.Font.Gotham
            Txt.TextSize = 13
            Txt.TextColor3 = Palette.TextPrimary
            Txt.TextXAlignment = Enum.TextXAlignment.Left

            -- Right: Container
            local RightContainer = Instance.new("Frame", Header)
            RightContainer.Size = UDim2.new(0.6, -12, 1, 0)
            RightContainer.Position = UDim2.new(0.4, 0, 0, 0)
            RightContainer.BackgroundTransparency = 1
            local RCLayout = Instance.new("UIListLayout", RightContainer)
            RCLayout.FillDirection = Enum.FillDirection.Horizontal
            RCLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
            RCLayout.VerticalAlignment = Enum.VerticalAlignment.Center
            RCLayout.Padding = UDim.new(0, 12)
            
            -- Right side: Toggle
            local ToggleBg = Instance.new("TextButton", RightContainer)
            ToggleBg.Size = UDim2.new(0, 44, 0, 22)
            ToggleBg.BackgroundColor3 = Palette.InputHdr
            ToggleBg.Text = ""
            ToggleBg.AutoButtonColor = false
            Instance.new("UICorner", ToggleBg).CornerRadius = UDim.new(1, 0)
            ApplyGlassEffect(ToggleBg, "subtle") -- glass effect for input

            local Knob = Instance.new("Frame", ToggleBg)
            Knob.Size = UDim2.new(0, 14, 0, 14)
            Knob.Position = UDim2.new(0, 4, 0.5, -7)
            Knob.BackgroundColor3 = Palette.TextSecondary
            Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

            local mainState = false
            local function UpdateMainToggle(noAnim)
                local targetColor = mainState and Palette.Green or Palette.InputHdr
                local knobColor = mainState and Color3.fromRGB(255, 255, 255) or Palette.TextSecondary
                local knobPos = mainState and UDim2.new(1, -18, 0.5, -7) or UDim2.new(0, 4, 0.5, -7)
                if noAnim then
                    ToggleBg.BackgroundColor3 = targetColor
                    Knob.BackgroundColor3 = knobColor
                    Knob.Position = knobPos
                else
                    TweenService:Create(ToggleBg, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
                    TweenService:Create(Knob, TweenInfo.new(0.2), {BackgroundColor3 = knobColor, Position = knobPos}):Play()
                end
            end

            ToggleBg.MouseButton1Click:Connect(function()
                mainState = not mainState
                UpdateMainToggle(false)
                pcall(tcb, mainState)
            end)
            
            local DropLabel = Instance.new("TextLabel", RightContainer)
            DropLabel.Size = UDim2.new(0, 110, 0, 24)
            DropLabel.BackgroundColor3 = Palette.InputHdr
            DropLabel.Text = "Select v"
            DropLabel.TextColor3 = Palette.TextSecondary
            DropLabel.Font = Enum.Font.Gotham
            DropLabel.TextSize = 12
            Instance.new("UICorner", DropLabel).CornerRadius = UDim.new(0, 4)
            ApplyGlassEffect(DropLabel, "subtle") -- glass effect for input
            
            local ExpandBtn = Instance.new("TextButton", DropLabel)
            ExpandBtn.Size = UDim2.new(1, 0, 1, 0)
            ExpandBtn.BackgroundTransparency = 1
            ExpandBtn.Text = ""
            
            ExpandBtn.MouseEnter:Connect(function() TweenService:Create(DropLabel, TweenInfo.new(0.2), {BackgroundColor3 = Palette.RowHover}):Play() end)
            ExpandBtn.MouseLeave:Connect(function() TweenService:Create(DropLabel, TweenInfo.new(0.2), {BackgroundColor3 = Palette.InputHdr}):Play() end)

            local DropFrame = Instance.new("Frame", Row)
            DropFrame.Size = UDim2.new(1, 0, 0, 0)
            DropFrame.Position = UDim2.new(0, 0, 0, 44)
            DropFrame.BackgroundTransparency = 1
            DropFrame.ClipsDescendants = true
            
            local Scroll = Instance.new("ScrollingFrame", DropFrame)
            Scroll.Size = UDim2.new(1, -16, 1, -8)
            Scroll.Position = UDim2.new(0, 8, 0, 0)
            Scroll.BackgroundTransparency = 1
            Scroll.ScrollBarThickness = 3
            Scroll.ScrollBarImageColor3 = Palette.Accent
            Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
            Scroll.BorderSizePixel = 0
            
            local itemCount = 0
            local expandedHeight = 155
            
            if columns > 1 then
                local SGrid = Instance.new("UIGridLayout", Scroll)
                SGrid.CellSize = UDim2.new(1 / columns, -(gridGap * 2), 0, itemH)
                SGrid.CellPadding = UDim2.new(0, gridGap, 0, gridGap)
                SGrid.SortOrder = Enum.SortOrder.LayoutOrder
                SGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
            else
                local SList = Instance.new("UIListLayout", Scroll)
                SList.Padding = UDim.new(0, gridGap)
                SList.SortOrder = Enum.SortOrder.LayoutOrder
            end
            
            local isExpanded = false
            ExpandBtn.MouseButton1Click:Connect(function()
                isExpanded = not isExpanded
                TweenService:Create(DropFrame, TweenInfo.new(0.25, Enum.EasingStyle.Cubic), {Size = isExpanded and UDim2.new(1, 0, 0, expandedHeight) or UDim2.new(1, 0, 0, 0)}):Play()
            end)

            local out = {}
            out.Items = {}
            function out:AddItem(itemStr, isDefault)
                itemCount = itemCount + 1
                local Itm = Instance.new("TextButton", Scroll)
                if columns > 1 then
                    Itm.Size = UDim2.new(1 / columns, -(gridGap * 2), 0, itemH)
                else
                    Itm.Size = UDim2.new(1, -8, 0, itemH)
                end
                Itm.BackgroundColor3 = isDefault and Palette.AccentDark or Palette.InputHdr
                Itm.Text = columns > 1 and itemStr or ("  " .. itemStr)
                Itm.TextXAlignment = columns > 1 and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
                Itm.TextColor3 = isDefault and Color3.new(1,1,1) or Palette.TextSecondary
                Itm.Font = Enum.Font.Gotham
                Itm.TextSize = columns > 1 and 11 or 12
                Itm.AutoButtonColor = false
                Instance.new("UICorner", Itm).CornerRadius = UDim.new(0,4)
                
                if isDefault then
                    DropLabel.Text = itemStr .. " v"
                    task.spawn(function() pcall(cb, itemStr) end)
                end
                
                table.insert(out.Items, {Btn = Itm, Str = itemStr})
                
                Itm.MouseButton1Click:Connect(function()
                    for _, data in ipairs(out.Items) do
                        data.Btn.BackgroundColor3 = Palette.InputHdr
                        data.Btn.TextColor3 = Palette.TextSecondary
                    end
                    Itm.BackgroundColor3 = Palette.AccentDark
                    Itm.TextColor3 = Color3.new(1,1,1)
                    DropLabel.Text = itemStr .. " v"
                    
                    if not keepOpen then
                        isExpanded = false
                        TweenService:Create(DropFrame, TweenInfo.new(0.15), {Size = UDim2.new(1, 0, 0, 0)}):Play()
                    end
                    pcall(cb, itemStr)
                end)
                
                local rows = math.ceil(itemCount / columns)
                expandedHeight = (rows * (itemH + gridGap)) + gridGap + 4
                Scroll.CanvasSize = UDim2.new(0, 0, 0, expandedHeight)
            end

            function out:ClearItems()
                for _, data in ipairs(out.Items) do
                    pcall(function() data.Btn:Destroy() end)
                end
                out.Items = {}
                itemCount = 0
                expandedHeight = 155
                Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
                DropLabel.Text = "Select v"
            end
            
            return out
        end

        function TabData:CreateDropdownButton(Options)
            local Title = Options.Name or "Dropdown"
            local cb = Options.Callback or function() end
            local bcb = Options.OnButton or function() end
            local btnText = Options.ButtonText or "Action"
            local columns = Options.Columns or 1
            local keepOpen = Options.KeepOpen or false
            local itemH = 26
            local gridGap = 4
            
            local Row = Instance.new("Frame", Page)
            Row.Size = UDim2.new(1, 0, 0, 0)
            Row.AutomaticSize = Enum.AutomaticSize.Y
            Row.BackgroundColor3 = Palette.RowItem
            Row.BorderSizePixel = 0
            Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 12)
            
            local Header = Instance.new("Frame", Row)
            Header.Size = UDim2.new(1, 0, 0, 44)
            Header.BackgroundTransparency = 1
            
            -- Left side: Title
            local Txt = Instance.new("TextLabel", Header)
            Txt.Size = UDim2.new(0.4, 0, 1, 0)
            Txt.Position = UDim2.new(0, 12, 0, 0)
            Txt.BackgroundTransparency = 1
            Txt.Text = Title
            Txt.Font = Enum.Font.Gotham
            Txt.TextSize = 13
            Txt.TextColor3 = Palette.TextPrimary
            Txt.TextXAlignment = Enum.TextXAlignment.Left

            -- Right: Container
            local RightContainer = Instance.new("Frame", Header)
            RightContainer.Size = UDim2.new(0.6, -12, 1, 0)
            RightContainer.Position = UDim2.new(0.4, 0, 0, 0)
            RightContainer.BackgroundTransparency = 1
            local RCLayout = Instance.new("UIListLayout", RightContainer)
            RCLayout.FillDirection = Enum.FillDirection.Horizontal
            RCLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
            RCLayout.VerticalAlignment = Enum.VerticalAlignment.Center
            RCLayout.Padding = UDim.new(0, 12)
            
            -- Right side: Button
            local ActionBtn = Instance.new("TextButton", RightContainer)
            ActionBtn.Size = UDim2.new(0, 50, 0, 24)
            ActionBtn.BackgroundColor3 = Palette.InputHdr
            ActionBtn.Text = btnText
            ActionBtn.TextColor3 = Palette.TextSecondary
            ActionBtn.Font = Enum.Font.Gotham
            ActionBtn.TextSize = 12
            ActionBtn.AutoButtonColor = false
            Instance.new("UICorner", ActionBtn).CornerRadius = UDim.new(0, 4)

            ActionBtn.MouseEnter:Connect(function() TweenService:Create(ActionBtn, TweenInfo.new(0.2), {BackgroundColor3 = Palette.RowHover}):Play() end)
            ActionBtn.MouseLeave:Connect(function() TweenService:Create(ActionBtn, TweenInfo.new(0.2), {BackgroundColor3 = Palette.InputHdr}):Play() end)
            ActionBtn.MouseButton1Click:Connect(function() pcall(bcb) end)
            
            local DropLabel = Instance.new("TextLabel", RightContainer)
            DropLabel.Size = UDim2.new(0, 110, 0, 24)
            DropLabel.BackgroundColor3 = Palette.InputHdr
            DropLabel.Text = "Select v"
            DropLabel.TextColor3 = Palette.TextSecondary
            DropLabel.Font = Enum.Font.Gotham
            DropLabel.TextSize = 12
            Instance.new("UICorner", DropLabel).CornerRadius = UDim.new(0, 4)
            ApplyGlassEffect(DropLabel, "subtle") -- glass effect for input
            
            local ExpandBtn = Instance.new("TextButton", DropLabel)
            ExpandBtn.Size = UDim2.new(1, 0, 1, 0)
            ExpandBtn.BackgroundTransparency = 1
            ExpandBtn.Text = ""
            
            ExpandBtn.MouseEnter:Connect(function() TweenService:Create(DropLabel, TweenInfo.new(0.2), {BackgroundColor3 = Palette.RowHover}):Play() end)
            ExpandBtn.MouseLeave:Connect(function() TweenService:Create(DropLabel, TweenInfo.new(0.2), {BackgroundColor3 = Palette.InputHdr}):Play() end)

            local DropFrame = Instance.new("Frame", Row)
            DropFrame.Size = UDim2.new(1, 0, 0, 0)
            DropFrame.Position = UDim2.new(0, 0, 0, 44)
            DropFrame.BackgroundTransparency = 1
            DropFrame.ClipsDescendants = true
            
            local Scroll = Instance.new("ScrollingFrame", DropFrame)
            Scroll.Size = UDim2.new(1, -16, 1, -8)
            Scroll.Position = UDim2.new(0, 8, 0, 0)
            Scroll.BackgroundTransparency = 1
            Scroll.ScrollBarThickness = 3
            Scroll.ScrollBarImageColor3 = Palette.Accent
            Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
            Scroll.BorderSizePixel = 0
            
            local itemCount = 0
            local expandedHeight = 155
            
            if columns > 1 then
                local SGrid = Instance.new("UIGridLayout", Scroll)
                SGrid.CellSize = UDim2.new(1 / columns, -(gridGap * 2), 0, itemH)
                SGrid.CellPadding = UDim2.new(0, gridGap, 0, gridGap)
                SGrid.SortOrder = Enum.SortOrder.LayoutOrder
                SGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
            else
                local SList = Instance.new("UIListLayout", Scroll)
                SList.Padding = UDim.new(0, gridGap)
                SList.SortOrder = Enum.SortOrder.LayoutOrder
            end
            
            local isExpanded = false
            ExpandBtn.MouseButton1Click:Connect(function()
                isExpanded = not isExpanded
                TweenService:Create(DropFrame, TweenInfo.new(0.25, Enum.EasingStyle.Cubic), {Size = isExpanded and UDim2.new(1, 0, 0, expandedHeight) or UDim2.new(1, 0, 0, 0)}):Play()
            end)

            local out = {}
            out.Items = {}
            function out:AddItem(itemStr, isDefault)
                itemCount = itemCount + 1
                local Itm = Instance.new("TextButton", Scroll)
                if columns > 1 then
                    Itm.Size = UDim2.new(1 / columns, -(gridGap * 2), 0, itemH)
                else
                    Itm.Size = UDim2.new(1, -8, 0, itemH)
                end
                Itm.BackgroundColor3 = isDefault and Palette.AccentDark or Palette.InputHdr
                Itm.Text = columns > 1 and itemStr or ("  " .. itemStr)
                Itm.TextXAlignment = columns > 1 and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
                Itm.TextColor3 = isDefault and Color3.new(1,1,1) or Palette.TextSecondary
                Itm.Font = Enum.Font.Gotham
                Itm.TextSize = columns > 1 and 11 or 12
                Itm.AutoButtonColor = false
                Instance.new("UICorner", Itm).CornerRadius = UDim.new(0,4)
                
                if isDefault then
                    DropLabel.Text = itemStr .. " v"
                    task.spawn(function() pcall(cb, itemStr) end)
                end
                
                table.insert(out.Items, {Btn = Itm, Str = itemStr})
                
                Itm.MouseButton1Click:Connect(function()
                    for _, data in ipairs(out.Items) do
                        data.Btn.BackgroundColor3 = Palette.InputHdr
                        data.Btn.TextColor3 = Palette.TextSecondary
                    end
                    Itm.BackgroundColor3 = Palette.AccentDark
                    Itm.TextColor3 = Color3.new(1,1,1)
                    DropLabel.Text = itemStr .. " v"
                    
                    if not keepOpen then
                        isExpanded = false
                        TweenService:Create(DropFrame, TweenInfo.new(0.15), {Size = UDim2.new(1, 0, 0, 0)}):Play()
                    end
                    pcall(cb, itemStr)
                end)
                
                local rows = math.ceil(itemCount / columns)
                expandedHeight = (rows * (itemH + gridGap)) + gridGap + 4
                Scroll.CanvasSize = UDim2.new(0, 0, 0, expandedHeight)
            end

            function out:ClearItems()
                for _, data in ipairs(out.Items) do
                    pcall(function() data.Btn:Destroy() end)
                end
                out.Items = {}
                itemCount = 0
                expandedHeight = 155
                Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
                DropLabel.Text = "Select v"
            end
            
            return out
        end

        function TabData:CreateMultiSelectDropdown(Options)
            local Title = Options.Name or "Dropdown"
            
            local Row = Instance.new("Frame", Page)
            Row.Size = UDim2.new(1, 0, 0, 0)
            Row.AutomaticSize = Enum.AutomaticSize.Y
            Row.BackgroundColor3 = Palette.RowItem
            Row.BorderSizePixel = 0
            Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 12)
            
            local Header = Instance.new("Frame", Row)
            Header.Size = UDim2.new(1, 0, 0, 44)
            Header.BackgroundTransparency = 1
            
            local Txt = Instance.new("TextLabel", Header)
            Txt.Size = UDim2.new(0.4, 0, 1, 0)
            Txt.Position = UDim2.new(0, 12, 0, 0)
            Txt.BackgroundTransparency = 1
            Txt.Text = Title
            Txt.Font = Enum.Font.Gotham
            Txt.TextSize = 13
            Txt.TextColor3 = Palette.TextPrimary
            Txt.TextXAlignment = Enum.TextXAlignment.Left

            local RightContainer = Instance.new("Frame", Header)
            RightContainer.Size = UDim2.new(0.6, -12, 1, 0)
            RightContainer.Position = UDim2.new(0.4, 0, 0, 0)
            RightContainer.BackgroundTransparency = 1
            local RCLayout = Instance.new("UIListLayout", RightContainer)
            RCLayout.FillDirection = Enum.FillDirection.Horizontal
            RCLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
            RCLayout.VerticalAlignment = Enum.VerticalAlignment.Center
            RCLayout.Padding = UDim.new(0, 12)
            
            local ToggleBg, Knob, mainState
            if Options.HasMainToggle then
                ToggleBg = Instance.new("TextButton", RightContainer)
                ToggleBg.Size = UDim2.new(0, 44, 0, 22)
                ToggleBg.BackgroundColor3 = Palette.InputHdr
                ToggleBg.Text = ""
                ToggleBg.AutoButtonColor = false
                Instance.new("UICorner", ToggleBg).CornerRadius = UDim.new(1, 0)
                ApplyGlassEffect(ToggleBg, "subtle") -- glass effect for input

                Knob = Instance.new("Frame", ToggleBg)
                Knob.Size = UDim2.new(0, 14, 0, 14)
                Knob.Position = UDim2.new(0, 4, 0.5, -7)
                Knob.BackgroundColor3 = Palette.TextSecondary
                Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

                mainState = false
                local function UpdateMainToggle(noAnim)
                    local targetColor = mainState and Palette.Green or Palette.InputHdr
                    local knobColor = mainState and Color3.fromRGB(255, 255, 255) or Palette.TextSecondary
                    local knobPos = mainState and UDim2.new(1, -18, 0.5, -7) or UDim2.new(0, 4, 0.5, -7)
                    if noAnim then
                        ToggleBg.BackgroundColor3 = targetColor
                        Knob.BackgroundColor3 = knobColor
                        Knob.Position = knobPos
                    else
                        TweenService:Create(ToggleBg, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
                        TweenService:Create(Knob, TweenInfo.new(0.2), {BackgroundColor3 = knobColor, Position = knobPos}):Play()
                    end
                end

                ToggleBg.MouseButton1Click:Connect(function()
                    mainState = not mainState
                    UpdateMainToggle(false)
                    if Options.OnMainToggle then pcall(Options.OnMainToggle, mainState) end
                end)
            end

            local ExpandBtn = Instance.new("TextButton", RightContainer)
            ExpandBtn.Size = UDim2.new(0, 100, 0, 24)
            ExpandBtn.BackgroundColor3 = Palette.InputHdr
            ExpandBtn.Text = "Filter v"
            ExpandBtn.TextColor3 = Palette.TextSecondary
            ExpandBtn.Font = Enum.Font.Gotham
            ExpandBtn.TextSize = 12
            ExpandBtn.AutoButtonColor = false
            Instance.new("UICorner", ExpandBtn).CornerRadius = UDim.new(0, 4)
            ExpandBtn.MouseEnter:Connect(function() TweenService:Create(ExpandBtn, TweenInfo.new(0.2), {BackgroundColor3 = Palette.RowHover}):Play() end)
            ExpandBtn.MouseLeave:Connect(function() TweenService:Create(ExpandBtn, TweenInfo.new(0.2), {BackgroundColor3 = Palette.InputHdr}):Play() end)

            local DropFrame = Instance.new("Frame", Row)
            DropFrame.Size = UDim2.new(1, 0, 0, 0)
            DropFrame.Position = UDim2.new(0, 0, 0, 44)
            DropFrame.BackgroundTransparency = 1
            DropFrame.ClipsDescendants = true
            
            local Scroll = Instance.new("ScrollingFrame", DropFrame)
            Scroll.Size = UDim2.new(1, -16, 1, -8)
            Scroll.Position = UDim2.new(0, 8, 0, 0)
            Scroll.BackgroundTransparency = 1
            Scroll.ScrollBarThickness = 3
            Scroll.ScrollBarImageColor3 = Palette.Accent
            Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
            Scroll.BorderSizePixel = 0
            
            local SList = Instance.new("UIListLayout", Scroll)
            SList.Padding = UDim.new(0, 4)
            SList.SortOrder = Enum.SortOrder.LayoutOrder
            
            local isExpanded = false
            ExpandBtn.MouseButton1Click:Connect(function()
                isExpanded = not isExpanded
                ExpandBtn.Text = isExpanded and "Filter ^" or "Filter v"
                TweenService:Create(DropFrame, TweenInfo.new(0.25, Enum.EasingStyle.Cubic), {Size = isExpanded and UDim2.new(1, 0, 0, 120) or UDim2.new(1, 0, 0, 0)}):Play()
            end)

            local out = {}
            local addedItems = {}
            function out:AddItem(itemStr, defaultState, callback)
                if addedItems[itemStr] then return end
                addedItems[itemStr] = true
                
                local Itm = Instance.new("TextButton", Scroll)
                Itm.Size = UDim2.new(1, -8, 0, 26)
                Itm.BackgroundColor3 = defaultState and Palette.AccentDark or Palette.InputHdr
                Itm.Text = "  " .. itemStr
                Itm.TextXAlignment = Enum.TextXAlignment.Left
                Itm.TextColor3 = defaultState and Color3.new(1,1,1) or Palette.TextSecondary
                Itm.Font = Enum.Font.Gotham
                Itm.TextSize = 12
                Itm.AutoButtonColor = false
                Instance.new("UICorner", Itm).CornerRadius = UDim.new(0,4)
                
                local currState = defaultState
                Itm.MouseButton1Click:Connect(function()
                    currState = not currState
                    Itm.BackgroundColor3 = currState and Palette.AccentDark or Palette.InputHdr
                    Itm.TextColor3 = currState and Color3.new(1,1,1) or Palette.TextSecondary
                    pcall(callback, currState)
                end)
                
                Scroll.CanvasSize = UDim2.new(0,0,0, SList.AbsoluteContentSize.Y + 10)
            end
            
            return out
        end

        function TabData:CreateInputRow(Options)
            local Title = Options.Name or "Input"
            local Placeholder = Options.Placeholder or ""
            local Default = Options.Default or ""
            local cb = Options.Callback or function() end

            local Row = AddRowContainer()

            local Txt = Instance.new("TextLabel", Row)
            Txt.Size = UDim2.new(0.6, 0, 1, 0)
            Txt.Position = UDim2.new(0, 12, 0, 0)
            Txt.BackgroundTransparency = 1
            Txt.Text = Title
            Txt.Font = Enum.Font.Gotham
            Txt.TextSize = 13
            Txt.TextColor3 = Palette.TextPrimary
            Txt.TextXAlignment = Enum.TextXAlignment.Left

            local Box = Instance.new("TextBox", Row)
            Box.Size = UDim2.new(0, 80, 0, 24)
            Box.Position = UDim2.new(1, -92, 0.5, -12)
            Box.BackgroundColor3 = Palette.InputHdr
            Box.Text = tostring(Default)
            Box.PlaceholderText = Placeholder
            Box.TextColor3 = Palette.TextPrimary
            Box.Font = Enum.Font.Gotham
            Box.TextSize = 12
            Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 4)

            Box.FocusLost:Connect(function()
                pcall(cb, Box.Text)
            end)
        end

        function TabData:CreateInputButtonRow(Options)
            local Title = Options.Name or "Input Action"
            local Placeholder = Options.Placeholder or ""
            local Default = Options.Default or ""
            local BtnText = Options.ButtonText or "Run"
            local cb = Options.Callback or function() end

            local Row = AddRowContainer()

            local Txt = Instance.new("TextLabel", Row)
            Txt.Size = UDim2.new(0.4, 0, 1, 0)
            Txt.Position = UDim2.new(0, 12, 0, 0)
            Txt.BackgroundTransparency = 1
            Txt.Text = Title
            Txt.Font = Enum.Font.Gotham
            Txt.TextSize = 13
            Txt.TextColor3 = Palette.TextPrimary
            Txt.TextXAlignment = Enum.TextXAlignment.Left

            local ExecBtn = Instance.new("TextButton", Row)
            ExecBtn.Size = UDim2.new(0, 50, 0, 24)
            ExecBtn.Position = UDim2.new(1, -62, 0.5, -12)
            ExecBtn.BackgroundColor3 = Palette.Accent
            ExecBtn.Text = BtnText
            ExecBtn.Font = Enum.Font.Gotham
            ExecBtn.TextSize = 12
            ExecBtn.TextColor3 = Color3.new(1, 1, 1)
            Instance.new("UICorner", ExecBtn).CornerRadius = UDim.new(0, 4)

            local Box = Instance.new("TextBox", Row)
            Box.Size = UDim2.new(0, 40, 0, 24)
            Box.Position = UDim2.new(1, -108, 0.5, -12)
            Box.BackgroundColor3 = Palette.InputHdr
            Box.Text = tostring(Default)
            Box.PlaceholderText = Placeholder
            Box.TextColor3 = Palette.TextPrimary
            Box.Font = Enum.Font.Gotham
            Box.TextSize = 12
            Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 4)

            ExecBtn.MouseEnter:Connect(function() ExecBtn.BackgroundColor3 = Palette.AccentDark end)
            ExecBtn.MouseLeave:Connect(function() ExecBtn.BackgroundColor3 = Palette.Accent end)

            ExecBtn.MouseButton1Click:Connect(function()
                pcall(function() cb(Box.Text) end)
            end)
        end

        return TabData
    end
    
    function WindowObj:SelectTab(TabName)
        if WindowObj.CurrentTab == TabName then return end
        WindowObj.CurrentTab = TabName
        for name, data in pairs(WindowObj.Tabs) do
            if name == TabName then
                data.Page.Visible = true
                data.Page.GroupTransparency = 1
                TweenService:Create(data.Page, TweenInfo.new(0.35, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {GroupTransparency = 0}):Play()

                data.Indicator.Visible = true
                data.Icon.ImageColor3 = Palette.Accent
                -- Highlight label text for active tab
                local lbl = data.Button:FindFirstChild("Label")
                if lbl then lbl.TextColor3 = Palette.Accent end
                data.Button.BackgroundTransparency = 0
                data.Button.BackgroundColor3 = Palette.RowHover
            else
                data.Page.Visible = false
                data.Page.GroupTransparency = 1
                data.Indicator.Visible = false
                data.Icon.ImageColor3 = Palette.TextSecondary
                local lbl = data.Button:FindFirstChild("Label")
                if lbl then lbl.TextColor3 = Palette.TextSecondary end
                data.Button.BackgroundTransparency = 1
            end
        end
    end

    function WindowObj:SetToggleKey(KeycodeStr)
        local kc = Enum.KeyCode[string.upper(KeycodeStr)]
        if kc then WindowObj.ToggleKey = kc end
    end

    function WindowObj:SetTitle(NewTitle)
        if WindowObj.TitleText then
            WindowObj.TitleText.Text = tostring(NewTitle)
        end
    end

    function WindowObj:UpdateCooldown(skillName, duration)
        local HUD = parentUI:FindFirstChild("SkenaHUD")
        if not HUD then
            HUD = Instance.new("ScreenGui", parentUI)
            HUD.Name = "SkenaHUD"
            
            local Container = Instance.new("Frame", HUD)
            Container.Name = "Container"
            Container.Size = UDim2.new(0, 200, 0, 0)
            Container.Position = UDim2.new(1, -210, 1, -20)
            Container.AnchorPoint = Vector2.new(0, 1)
            Container.BackgroundTransparency = 1
            Container.AutomaticSize = Enum.AutomaticSize.Y
            
            local Layout = Instance.new("UIListLayout", Container)
            Layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
            Layout.SortOrder = Enum.SortOrder.LayoutOrder
            Layout.Padding = UDim.new(0, 5)
        end
        
        local Container = HUD.Container
        local Item = Container:FindFirstChild(skillName)
        
        if duration <= 0 then
            if Item then
                TweenService:Create(Item, TweenInfo.new(0.3), {GroupTransparency = 1}):Play()
                task.delay(0.3, function() Item:Destroy() end)
            end
            WindowObj.Cooldowns[skillName] = nil
            return
        end
        
        if not Item then
            Item = Instance.new("CanvasGroup", Container)
            Item.Name = skillName
            Item.Size = UDim2.new(1, 0, 0, 30)
            Item.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            Item.GroupTransparency = 1
            Instance.new("UICorner", Item).CornerRadius = UDim.new(0, 10)
            
            local Label = Instance.new("TextLabel", Item)
            Label.Name = "Label"
            Label.Size = UDim2.new(1, -60, 1, 0)
            Label.Position = UDim2.new(0, 8, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = skillName
            Label.TextColor3 = Palette.TextPrimary
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 11
            Label.TextXAlignment = Enum.TextXAlignment.Left
            
            local Time = Instance.new("TextLabel", Item)
            Time.Name = "Time"
            Time.Size = UDim2.new(0, 50, 1, 0)
            Time.Position = UDim2.new(1, -55, 0, 0)
            Time.BackgroundTransparency = 1
            Time.Text = string.format("%.1fs", duration)
            Time.TextColor3 = Palette.Accent
            Time.Font = Enum.Font.Gotham
            Time.TextSize = 11
            Time.TextXAlignment = Enum.TextXAlignment.Right
            
            TweenService:Create(Item, TweenInfo.new(0.3), {GroupTransparency = 0}):Play()
        end
        
        Item.Time.Text = string.format("%.1fs", duration)
        WindowObj.Cooldowns[skillName] = duration
    end
    
    return WindowObj
end

return SkenaUI
