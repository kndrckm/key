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

-- One Dark Palette
local Palette = {
    Background  = Color3.fromRGB(40, 44, 52),
    Sidebar     = Color3.fromRGB(40, 44, 52),
    Card        = Color3.fromRGB(44, 49, 59),
    RowItem     = Color3.fromRGB(44, 49, 59),
    RowHover    = Color3.fromRGB(53, 59, 69),
    TextPrimary = Color3.fromRGB(171, 178, 191),
    TextSecondary = Color3.fromRGB(92, 99, 112),
    Accent      = Color3.fromRGB(97, 175, 239),
    AccentDark  = Color3.fromRGB(78, 150, 210),
    Border      = Color3.fromRGB(60, 65, 75),
    RedHover    = Color3.fromRGB(224, 108, 117),
    InputHdr    = Color3.fromRGB(33, 37, 43),
    Green       = Color3.fromRGB(152, 195, 121),
    Yellow      = Color3.fromRGB(229, 192, 123),
    Purple      = Color3.fromRGB(198, 120, 221),
    Cyan        = Color3.fromRGB(86, 182, 194),
    GlassBorder = Color3.fromRGB(255, 255, 255),
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
    MainCorner.CornerRadius = UDim.new(0, 8)
    
    local MainStroke = Instance.new("UIStroke", Main)
    MainStroke.Color = Palette.Border
    MainStroke.Thickness = 1

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
    Instance.new("UICorner", ScaleBtn).CornerRadius = UDim.new(0, 6)

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
    Instance.new("UICorner", Minibtn).CornerRadius = UDim.new(0, 6)

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
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

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

    CloseBtn.MouseButton1Click:Connect(function() SG:Destroy() end)

    -- Under Title Bar
    local BodyFrame = Instance.new("Frame", Main)
    BodyFrame.Size = UDim2.new(1, 0, 1, -32)
    BodyFrame.Position = UDim2.new(0, 0, 0, 32)
    BodyFrame.BackgroundTransparency = 1
    
    local BodyPadding = Instance.new("UIPadding", BodyFrame)
    BodyPadding.PaddingBottom = UDim.new(0, 8)

    -- Sidebar (Left)
    local Sidebar = Instance.new("Frame", BodyFrame)
    Sidebar.Size = UDim2.new(0, 45, 1, 0)
    Sidebar.Position = UDim2.new(0, 5, 0, 0)
    Sidebar.BackgroundTransparency = 1

    local SidebarTop = Instance.new("Frame", Sidebar)
    SidebarTop.Size = UDim2.new(1, 0, 0, 0)
    SidebarTop.AutomaticSize = Enum.AutomaticSize.Y
    SidebarTop.BackgroundTransparency = 1
    local STLayout = Instance.new("UIListLayout", SidebarTop)
    STLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    STLayout.SortOrder = Enum.SortOrder.LayoutOrder
    STLayout.Padding = UDim.new(0, 8)

    local SidebarBottom = Instance.new("Frame", Sidebar)
    SidebarBottom.Size = UDim2.new(1, 0, 1, 0)
    SidebarBottom.BackgroundTransparency = 1
    local SBLayout = Instance.new("UIListLayout", SidebarBottom)
    SBLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    SBLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    SBLayout.SortOrder = Enum.SortOrder.LayoutOrder
    SBLayout.Padding = UDim.new(0, 8)

    -- Inner Card (Right)
    local Card = Instance.new("Frame", BodyFrame)
    Card.Size = UDim2.new(1, -60, 1, -8)
    Card.Position = UDim2.new(0, 55, 0, 0)
    Card.BackgroundColor3 = Palette.Card
    Card.BorderSizePixel = 0
    Card.ClipsDescendants = true

    local CardCorner = Instance.new("UICorner", Card)
    CardCorner.CornerRadius = UDim.new(0, 8)
    
    local CardStroke = Instance.new("UIStroke", Card)
    CardStroke.Color = Palette.Border
    CardStroke.Thickness = 1

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
    ScrollPadding.PaddingTop = UDim.new(0, 8)
    ScrollPadding.PaddingBottom = UDim.new(0, 8)
    ScrollPadding.PaddingLeft = UDim.new(0, 8)
    ScrollPadding.PaddingRight = UDim.new(0, 16)

    local TabContainer = Instance.new("Folder", CardScroll)
    TabContainer.Name = "Tabs"
    return WindowObj
end

return SkenaUI
