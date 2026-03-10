-- SkenaUI Library v3.1 | One Dark Theme
-- API:
--   local SkenaUI = getgenv().SkenaLoad("SkenaUI_Library.lua")
--   local Win = SkenaUI.CreateWindow(hubName, gameTitle, bool)
--   local Tab = Win:CreateTab(tabName, iconName, bool)
--   Tab:CreateTextRow({ Text })
--   Tab:CreateToggleRow({ Name, Default, OnToggle })
--   Tab:CreateButtonRow({ Name, ButtonText, Callback })
--   local dd = Tab:CreateDropdownButton({ Name, ButtonText, Callback, OnButton })
--     dd:AddItem(name, isDefault)

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer

local P = {
    Background    = Color3.fromRGB(40,44,52),
    Card          = Color3.fromRGB(44,49,59),
    CardHover     = Color3.fromRGB(52,58,70),
    NavBar        = Color3.fromRGB(33,37,43),
    TitleBar      = Color3.fromRGB(33,37,43),
    Border        = Color3.fromRGB(60,66,78),
    TextPrimary   = Color3.fromRGB(171,178,191),
    TextSecondary = Color3.fromRGB(92,99,112),
    TextMuted     = Color3.fromRGB(70,77,90),
    Accent        = Color3.fromRGB(97,175,239),
    Green         = Color3.fromRGB(152,195,121),
    Red           = Color3.fromRGB(224,108,117),
    Yellow        = Color3.fromRGB(229,192,123),
    White         = Color3.fromRGB(255,255,255),
    Transparent   = Color3.fromRGB(0,0,0),
}

local function Tween(obj, props, t)
    TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play()
end

local function MakeCorner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = p
    return c
end

local function MakePadding(p, t, r, b, l)
    local u = Instance.new("UIPadding")
    u.PaddingTop    = UDim.new(0, t or 0)
    u.PaddingRight  = UDim.new(0, r or 0)
    u.PaddingBottom = UDim.new(0, b or 0)
    u.PaddingLeft   = UDim.new(0, l or 0)
    u.Parent = p
    return u
end

local function MakeList(p, dir, pad, ha, va)
    local l = Instance.new("UIListLayout")
    l.FillDirection       = dir or Enum.FillDirection.Vertical
    l.Padding             = UDim.new(0, pad or 0)
    l.HorizontalAlignment = ha  or Enum.HorizontalAlignment.Left
    l.VerticalAlignment   = va  or Enum.VerticalAlignment.Top
    l.SortOrder           = Enum.SortOrder.LayoutOrder
    l.Parent = p
    return l
end

local function MakeStroke(p, color, thick, trans)
    local s = Instance.new("UIStroke")
    s.Color           = color or P.Border
    s.Thickness       = thick or 1
    s.Transparency    = trans or 0.6
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p
    return s
end

local function NewLabel(p, text, size, color, font, ha)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text           = tostring(text or "")
    l.TextSize       = size  or 13
    l.TextColor3     = color or P.TextPrimary
    l.Font           = font  or Enum.Font.GothamMedium
    l.TextXAlignment = ha    or Enum.TextXAlignment.Left
    l.TextTruncate   = Enum.TextTruncate.AtEnd
    l.Parent = p
    return l
end

local function NewFrame(p, size, pos, color, trans)
    local f = Instance.new("Frame")
    f.Size                   = size  or UDim2.new(1,0,0,30)
    f.Position               = pos   or UDim2.new(0,0,0,0)
    f.BackgroundColor3       = color or P.Card
    f.BackgroundTransparency = trans or 0
    f.BorderSizePixel        = 0
    f.Parent = p
    return f
end

local function AutoSize(list, parent)
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        parent.Size = UDim2.new(parent.Size.X.Scale, parent.Size.X.Offset, 0, list.AbsoluteContentSize.Y)
    end)
end

local function MakeDraggable(handle, frame)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = i.Position
            startPos = frame.Position
        end
    end)
    handle.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
end

local RootGui = Instance.new("ScreenGui")
RootGui.Name = "SkenaUI_v3"
RootGui.ResetOnSpawn = false
RootGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
RootGui.IgnoreGuiInset = true
pcall(function() RootGui.Parent = CoreGui end)
if not RootGui.Parent then RootGui.Parent = LocalPlayer.PlayerGui end

local OverlayGui = Instance.new("ScreenGui")
OverlayGui.Name = "SkenaUI_Overlay"
OverlayGui.ResetOnSpawn = false
OverlayGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
OverlayGui.DisplayOrder = 999
pcall(function() OverlayGui.Parent = CoreGui end)
if not OverlayGui.Parent then OverlayGui.Parent = LocalPlayer.PlayerGui end

local SkenaUI = {}

function SkenaUI.CreateWindow(Arg1, Arg2, Arg3)
    local Options = Arg1
    -- Handle SkenaUI:CreateWindow(...) where Arg1 is the SkenaUI table
    if type(Arg1) == "table" and Arg1.CreateWindow == SkenaUI.CreateWindow then
        Options = Arg2
    end

    local hubName, gameTitle
    if type(Options) == "table" then
        hubName   = tostring(Options.Name or Options.HubName or "SkenaHub")
        gameTitle = tostring(Options.Title or Options.GameTitle or "SkenaUI")
    else
        hubName   = Options or "SkenaHub"
        gameTitle = (type(Arg1) == "table" and Arg1.CreateWindow) and Arg3 or Arg2 or "SkenaUI"
    end
    hubName = tostring(hubName)
    gameTitle = tostring(gameTitle)

    local blur = Instance.new("BlurEffect")
    blur.Size = 0
    blur.Parent = game:GetService("Lighting")

    local winW, winH = 560, 420
    local WinFrame = NewFrame(RootGui,
        UDim2.new(0, winW, 0, winH),
        UDim2.new(0.5, -winW/2, 0.5, -winH/2),
        P.Background
    )
    WinFrame.Name = "SkenaWindow"
    WinFrame.ClipsDescendants = true
    MakeCorner(WinFrame, 10)
    MakeStroke(WinFrame, P.Border, 1, 0.5)
    WinFrame.Size = UDim2.new(0, winW, 0, 0)
    WinFrame.BackgroundTransparency = 1
    Tween(WinFrame, {Size=UDim2.new(0,winW,0,winH), BackgroundTransparency=0}, 0.35)
    Tween(blur, {Size=8}, 0.35)

    local TitleBar = NewFrame(WinFrame, UDim2.new(1,0,0,36), UDim2.new(0,0,0,0), P.TitleBar)
    TitleBar.Name = "TitleBar"
    MakeDraggable(TitleBar, WinFrame)

    local HubLbl = NewLabel(TitleBar, hubName, 13, P.Accent, Enum.Font.GothamBold)
    HubLbl.Size = UDim2.new(0,0,1,0)
    HubLbl.AutomaticSize = Enum.AutomaticSize.X
    HubLbl.Position = UDim2.new(0,12,0,0)

    local TitleLbl = NewLabel(TitleBar, gameTitle, 13, P.TextPrimary, Enum.Font.GothamMedium, Enum.TextXAlignment.Center)
    TitleLbl.Size = UDim2.new(0,0,1,0)
    TitleLbl.AutomaticSize = Enum.AutomaticSize.X
    TitleLbl.Position = UDim2.new(0.5,0,0,0)
    TitleLbl.AnchorPoint = Vector2.new(0.5,0)

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0,24,0,24)
    CloseBtn.Position = UDim2.new(1,-32,0.5,0)
    CloseBtn.AnchorPoint = Vector2.new(0,0.5)
    CloseBtn.BackgroundColor3 = P.Red
    CloseBtn.BackgroundTransparency = 0.5
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = P.White
    CloseBtn.TextSize = 14
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Parent = TitleBar
    MakeCorner(CloseBtn, 5)
    CloseBtn.MouseEnter:Connect(function() Tween(CloseBtn,{BackgroundTransparency=0.2},0.15) end)
    CloseBtn.MouseLeave:Connect(function() Tween(CloseBtn,{BackgroundTransparency=0.5},0.15) end)
    CloseBtn.MouseButton1Click:Connect(function()
        Tween(WinFrame, {Size=UDim2.new(0,winW,0,0), BackgroundTransparency=1}, 0.25)
        Tween(blur, {Size=0}, 0.25)
        task.delay(0.3, function() WinFrame:Destroy() blur:Destroy() end)
    end)

    local uiToggleConn
    uiToggleConn = UserInputService.InputBegan:Connect(function(inp, gp)
        local key = (Win and Win.ToggleKey) or Enum.KeyCode.RightControl
        if not gp and inp.KeyCode == key then
            WinFrame.Visible = not WinFrame.Visible
            Tween(blur, {Size = WinFrame.Visible and 8 or 0}, 0.2)
        end
    end)
    WinFrame.Destroying:Connect(function() if uiToggleConn then uiToggleConn:Disconnect() end end)

    local NavBar = NewFrame(WinFrame, UDim2.new(1,0,0,38), UDim2.new(0,0,0,36), P.NavBar)
    NavBar.Name = "NavBar"
    NavBar.ClipsDescendants = true

    local NavScroll = Instance.new("ScrollingFrame")
    NavScroll.Size = UDim2.new(1,-8,1,0)
    NavScroll.Position = UDim2.new(0,4,0,0)
    NavScroll.BackgroundTransparency = 1
    NavScroll.BorderSizePixel = 0
    NavScroll.ScrollBarThickness = 0
    NavScroll.CanvasSize = UDim2.new(0,0,1,0)
    NavScroll.ScrollingDirection = Enum.ScrollingDirection.X
    NavScroll.Parent = NavBar

    local NavLayout = MakeList(NavScroll, Enum.FillDirection.Horizontal, 2)
    NavLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        NavScroll.CanvasSize = UDim2.new(0, NavLayout.AbsoluteContentSize.X+8, 1, 0)
    end)

    local NavDiv = NewFrame(WinFrame, UDim2.new(1,0,0,1), UDim2.new(0,0,0,74), P.Border)
    NavDiv.BackgroundTransparency = 0.6

    local BodyScroll = Instance.new("ScrollingFrame")
    BodyScroll.Name = "BodyScroll"
    BodyScroll.Size = UDim2.new(1,-4,1,-76)
    BodyScroll.Position = UDim2.new(0,0,0,76)
    BodyScroll.BackgroundTransparency = 1
    BodyScroll.BorderSizePixel = 0
    BodyScroll.ScrollBarThickness = 3
    BodyScroll.ScrollBarImageColor3 = P.Accent
    BodyScroll.CanvasSize = UDim2.new(0,0,0,0)
    BodyScroll.Parent = WinFrame

    local Win = { Frame=WinFrame, _tabs={}, _activeTab=nil, ToggleKey = Enum.KeyCode.RightControl }

    function Win:CreateTab(tabName, _icon, _bool)
        tabName = tabName or "Tab"

        local TabContent = NewFrame(BodyScroll,
            UDim2.new(1,-16,0,0), UDim2.new(0,8,0,8), P.Transparent, 1)
        TabContent.Name = "Tab_"..tabName
        TabContent.Visible = false
        local TabList = MakeList(TabContent, Enum.FillDirection.Vertical, 6)
        AutoSize(TabList, TabContent)

        local NavBtn = Instance.new("TextButton")
        NavBtn.Size = UDim2.new(0,0,1,-8)
        NavBtn.AutomaticSize = Enum.AutomaticSize.X
        NavBtn.BackgroundColor3 = P.CardHover
        NavBtn.BackgroundTransparency = 1
        NavBtn.BorderSizePixel = 0
        NavBtn.Text = ""
        NavBtn.Parent = NavScroll
        MakeCorner(NavBtn, 5)

        local NavContent = NewFrame(NavBtn, UDim2.new(1,0,1,0), nil, P.Transparent, 1)
        MakePadding(NavContent, 0, 12, 0, 12)
        MakeList(NavContent, Enum.FillDirection.Horizontal, 5,
            Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)

        local NavLabel = NewLabel(NavContent, tabName, 13, P.TextSecondary,
            Enum.Font.GothamMedium, Enum.TextXAlignment.Center)
        NavLabel.Size = UDim2.new(0,0,0,14)
        NavLabel.AutomaticSize = Enum.AutomaticSize.X
        NavLabel.LayoutOrder = 1

        local Underline = NewFrame(NavBtn, UDim2.new(0,0,0,2), UDim2.new(0.5,0,1,-2), P.Accent, 1)
        Underline.AnchorPoint = Vector2.new(0.5,1)
        MakeCorner(Underline, 2)

        local Tab = {
            Name=tabName, Content=TabContent,
            NavBtn=NavBtn, NavLabel=NavLabel, Underline=Underline
        }
        table.insert(Win._tabs, Tab)

        local function Activate()
            for _, t in ipairs(Win._tabs) do
                t.Content.Visible = false
                Tween(t.NavLabel,  {TextColor3=P.TextSecondary}, 0.15)
                Tween(t.Underline, {BackgroundTransparency=1, Size=UDim2.new(0,0,0,2)}, 0.15)
                Tween(t.NavBtn,    {BackgroundTransparency=1}, 0.15)
            end
            TabContent.Visible = true
            Win._activeTab = Tab
            Tween(NavLabel,  {TextColor3=P.Accent}, 0.15)
            Tween(Underline, {BackgroundTransparency=0, Size=UDim2.new(1,0,0,2)}, 0.2)
            Tween(NavBtn,    {BackgroundTransparency=0.85}, 0.15)
            BodyScroll.CanvasSize = UDim2.new(0,0,0, TabContent.AbsoluteSize.Y+16)
        end

        TabList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            if Win._activeTab == Tab then
                BodyScroll.CanvasSize = UDim2.new(0,0,0, TabList.AbsoluteContentSize.Y+16)
            end
        end)

        NavBtn.MouseButton1Click:Connect(Activate)
        NavBtn.MouseEnter:Connect(function()
            if Win._activeTab ~= Tab then Tween(NavBtn,{BackgroundTransparency=0.92},0.1) end
        end)
        NavBtn.MouseLeave:Connect(function()
            if Win._activeTab ~= Tab then Tween(NavBtn,{BackgroundTransparency=1},0.1) end
        end)
        if #Win._tabs == 1 then Activate() end

        local function MakeRow(h)
            local r = NewFrame(TabContent, UDim2.new(1,0,0,h or 38), nil, P.Card)
            r.LayoutOrder = #TabContent:GetChildren()
            MakeCorner(r,6)
            MakeStroke(r, P.Border, 1, 0.7)
            MakePadding(r, 0, 10, 0, 10)
            return r
        end

        function Tab:CreateTextRow(cfg)
            local txt = type(cfg) == "table" and cfg.Text or tostring(cfg or "")
            local r = NewFrame(TabContent, UDim2.new(1,0,0,26), nil, P.Transparent, 1)
            r.LayoutOrder = #TabContent:GetChildren()
            local l = NewLabel(r, txt, 12, P.TextMuted,
                Enum.Font.GothamMedium, Enum.TextXAlignment.Center)
            l.Size = UDim2.new(1,0,1,0)
        end

        function Tab:CreateToggleRow(cfg)
            if type(cfg) == "string" then cfg = {Name = cfg} end
            cfg = cfg or {}
            local name  = cfg.Name    or "Toggle"
            local state = cfg.Default == true
            local cb    = cfg.OnToggle
            local Row   = MakeRow(38)

            local lbl = NewLabel(Row, name, 13, P.TextPrimary)
            lbl.Size = UDim2.new(1,-50,1,0)

            local Track = NewFrame(Row, UDim2.new(0,38,0,20), UDim2.new(1,-40,0.5,-10), P.Border)
            Track.BackgroundTransparency = 0.4
            MakeCorner(Track, 10)

            local Thumb = NewFrame(Track, UDim2.new(0,14,0,14), UDim2.new(0,3,0.5,-7), P.TextSecondary)
            MakeCorner(Thumb, 7)

            local function SetState(v, fire)
                state = v
                local tx = v and UDim2.new(0,21,0.5,-7) or UDim2.new(0,3,0.5,-7)
                local tc = v and P.Accent or P.TextSecondary
                local bc = v and P.Accent or P.Border
                local bt = v and 0.55 or 0.4
                Tween(Thumb, {Position=tx, BackgroundColor3=tc}, 0.18)
                Tween(Track, {BackgroundColor3=bc, BackgroundTransparency=bt}, 0.18)
                if fire and cb then cb(v) end
            end
            SetState(state, false)

            Track.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    SetState(not state, true)
                end
            end)

            return {
                SetValue = function(v) SetState(v, false) end,
                GetValue = function() return state end
            }
        end

        function Tab:CreateButtonRow(cfg)
            if type(cfg) == "string" then cfg = {Name = cfg} end
            cfg = cfg or {}
            local name    = cfg.Name       or ""
            local btnText = cfg.ButtonText or "Run"
            local cb      = cfg.Callback
            local Row     = MakeRow(38)

            if name ~= "" then
                local l = NewLabel(Row, name, 13, P.TextPrimary)
                l.Size = UDim2.new(1,-100,1,0)
            end

            local Btn = Instance.new("TextButton")
            if name ~= "" then
                Btn.Size     = UDim2.new(0,90,1,-10)
                Btn.Position = UDim2.new(1,-92,0.5,0)
            else
                Btn.Size     = UDim2.new(1,0,1,-10)
                Btn.Position = UDim2.new(0,0,0.5,0)
            end
            Btn.AnchorPoint            = Vector2.new(0,0.5)
            Btn.BackgroundColor3       = P.Accent
            Btn.BackgroundTransparency = 0.7
            Btn.Text                   = btnText
            Btn.TextColor3             = P.Accent
            Btn.TextSize               = 12
            Btn.Font                   = Enum.Font.GothamMedium
            Btn.BorderSizePixel        = 0
            Btn.AutoButtonColor        = false
            Btn.Parent = Row
            MakeCorner(Btn, 5)
            MakeStroke(Btn, P.Accent, 1, 0.6)
            Btn.MouseEnter:Connect(function()
                Tween(Btn, {BackgroundTransparency=0.4, TextColor3=P.White}, 0.12)
            end)
            Btn.MouseLeave:Connect(function()
                Tween(Btn, {BackgroundTransparency=0.7, TextColor3=P.Accent}, 0.12)
            end)
            Btn.MouseButton1Click:Connect(function()
                Tween(Btn, {BackgroundTransparency=0.2}, 0.08)
                task.delay(0.1, function() Tween(Btn, {BackgroundTransparency=0.7}, 0.12) end)
                if cb then cb() end
            end)
            return {Button=Btn}
        end

        function Tab:CreateDropdownButton(cfg)
            if type(cfg) == "string" then cfg = {Name = cfg} end
            cfg = cfg or {}
            local name     = cfg.Name       or "Select"
            local btnText  = cfg.ButtonText or "Go"
            local onSelect = cfg.Callback
            local onButton = cfg.OnButton
            local items    = {}
            local selected = nil
            local Row      = MakeRow(38)

            local lbl = NewLabel(Row, name, 13, P.TextPrimary)
            lbl.Size = UDim2.new(0.35,0,1,0)

            local AnchorBtn = Instance.new("TextButton")
            AnchorBtn.Size                   = UDim2.new(0.42,-4,1,-10)
            AnchorBtn.Position               = UDim2.new(0.35,2,0.5,0)
            AnchorBtn.AnchorPoint            = Vector2.new(0,0.5)
            AnchorBtn.BackgroundColor3       = P.NavBar
            AnchorBtn.BackgroundTransparency = 0
            AnchorBtn.BorderSizePixel        = 0
            AnchorBtn.Text                   = ""
            AnchorBtn.AutoButtonColor        = false
            AnchorBtn.Parent = Row
            MakeCorner(AnchorBtn, 5)
            MakeStroke(AnchorBtn, P.Border, 1, 0.5)
            MakePadding(AnchorBtn, 0, 20, 0, 6)

            local AnchorLbl = NewLabel(AnchorBtn, "Select...", 12, P.TextSecondary, Enum.Font.Gotham)
            AnchorLbl.Size = UDim2.new(1,0,1,0)
            AnchorLbl.TextTruncate = Enum.TextTruncate.AtEnd

            local Chev = NewLabel(AnchorBtn, "v", 10, P.TextMuted, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
            Chev.Size = UDim2.new(0,18,1,0)
            Chev.Position = UDim2.new(1,-18,0,0)

            local ActBtn = Instance.new("TextButton")
            ActBtn.Size                   = UDim2.new(0.23,-4,1,-10)
            ActBtn.Position               = UDim2.new(0.77,2,0.5,0)
            ActBtn.AnchorPoint            = Vector2.new(0,0.5)
            ActBtn.BackgroundColor3       = P.Accent
            ActBtn.BackgroundTransparency = 0.7
            ActBtn.Text                   = btnText
            ActBtn.TextColor3             = P.Accent
            ActBtn.TextSize               = 12
            ActBtn.Font                   = Enum.Font.GothamMedium
            ActBtn.BorderSizePixel        = 0
            ActBtn.AutoButtonColor        = false
            ActBtn.Parent = Row
            MakeCorner(ActBtn, 5)
            MakeStroke(ActBtn, P.Accent, 1, 0.6)
            ActBtn.MouseEnter:Connect(function()
                Tween(ActBtn, {BackgroundTransparency=0.4, TextColor3=P.White}, 0.12)
            end)
            ActBtn.MouseLeave:Connect(function()
                Tween(ActBtn, {BackgroundTransparency=0.7, TextColor3=P.Accent}, 0.12)
            end)
            ActBtn.MouseButton1Click:Connect(function()
                Tween(ActBtn, {BackgroundTransparency=0.2}, 0.08)
                task.delay(0.1, function() Tween(ActBtn, {BackgroundTransparency=0.7}, 0.12) end)
                if onButton then onButton() end
            end)

            local panelOpen = false
            local Panel

            local function ClosePanel()
                if not panelOpen or not Panel then return end
                panelOpen = false
                Tween(Panel, {
                    Size = UDim2.new(Panel.Size.X.Scale, Panel.Size.X.Offset, 0, 0),
                    BackgroundTransparency = 1
                }, 0.15)
                Tween(Chev, {Rotation=0}, 0.15)
                task.delay(0.2, function()
                    if Panel then Panel:Destroy() Panel = nil end
                end)
            end

            local function OpenPanel()
                if panelOpen then ClosePanel() return end
                panelOpen = true
                Tween(Chev, {Rotation=180}, 0.15)

                local abs    = AnchorBtn.AbsolutePosition
                local absS   = AnchorBtn.AbsoluteSize
                local panW   = absS.X
                local maxH   = 160
                local posY   = abs.Y + absS.Y + 4
                local screenH = workspace.CurrentCamera.ViewportSize.Y
                local flipUp  = (posY + maxH) > screenH - 20

                Panel = NewFrame(OverlayGui,
                    UDim2.new(0, panW, 0, 0),
                    UDim2.new(0, abs.X, 0, flipUp and (abs.Y - maxH - 4) or posY),
                    P.Card
                )
                Panel.BackgroundTransparency = 1
                Panel.ClipsDescendants = true
                MakeCorner(Panel, 7)
                MakeStroke(Panel, P.Border, 1, 0.4)

                local IS = Instance.new("ScrollingFrame")
                IS.Size = UDim2.new(1,0,1,0)
                IS.BackgroundTransparency = 1
                IS.BorderSizePixel = 0
                IS.ScrollBarThickness = 2
                IS.ScrollBarImageColor3 = P.Accent
                IS.CanvasSize = UDim2.new(0,0,0,0)
                IS.Parent = Panel
                MakePadding(IS, 4, 4, 4, 4)

                local PL = MakeList(IS, Enum.FillDirection.Vertical, 2)
                PL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    IS.CanvasSize = UDim2.new(0,0,0, PL.AbsoluteContentSize.Y+8)
                end)

                for idx, item in ipairs(items) do
                    local active = selected == item
                    local OB = Instance.new("TextButton")
                    OB.Size = UDim2.new(1,0,0,26)
                    OB.BackgroundColor3 = P.CardHover
                    OB.BackgroundTransparency = active and 0.85 or 1
                    OB.Text = ""
                    OB.BorderSizePixel = 0
                    OB.LayoutOrder = idx
                    OB.Parent = IS
                    MakeCorner(OB, 5)

                    local tick = NewLabel(OB, active and "v" or "", 12, P.Accent, Enum.Font.GothamBold)
                    tick.Size = UDim2.new(0,18,1,0)
                    tick.TextXAlignment = Enum.TextXAlignment.Center

                    local ol = NewLabel(OB, item, 12, active and P.Accent or P.TextPrimary, Enum.Font.Gotham)
                    ol.Size = UDim2.new(1,-20,1,0)
                    ol.Position = UDim2.new(0,20,0,0)

                    OB.MouseEnter:Connect(function()
                        Tween(OB, {BackgroundTransparency=0.8}, 0.1)
                    end)
                    OB.MouseLeave:Connect(function()
                        Tween(OB, {BackgroundTransparency = selected==item and 0.85 or 1}, 0.1)
                    end)
                    OB.MouseButton1Click:Connect(function()
                        selected = item
                        AnchorLbl.Text = tostring(item)
                        AnchorLbl.TextColor3 = P.TextPrimary
                        if onSelect then onSelect(item) end
                        ClosePanel()
                    end)
                end

                local targetH = math.max(math.min(PL.AbsoluteContentSize.Y+8, maxH), 40)
                if flipUp then
                    Panel.Position = UDim2.new(0, abs.X, 0, abs.Y - targetH - 4)
                end
                Tween(Panel, {Size=UDim2.new(0,panW,0,targetH), BackgroundTransparency=0}, 0.15)

                local dc
                dc = UserInputService.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        local mp  = UserInputService:GetMouseLocation()
                        local pa  = Panel and Panel.AbsolutePosition or Vector2.new(0,0)
                        local ps  = Panel and Panel.AbsoluteSize     or Vector2.new(0,0)
                        local ip  = mp.X>=pa.X and mp.X<=pa.X+ps.X and mp.Y>=pa.Y and mp.Y<=pa.Y+ps.Y
                        local aa  = AnchorBtn.AbsolutePosition
                        local as2 = AnchorBtn.AbsoluteSize
                        local ib  = mp.X>=aa.X and mp.X<=aa.X+as2.X and mp.Y>=aa.Y and mp.Y<=aa.Y+as2.Y
                        if not ip and not ib then
                            dc:Disconnect()
                            ClosePanel()
                        end
                    end
                end)
            end

            AnchorBtn.MouseButton1Click:Connect(OpenPanel)
            AnchorBtn.MouseEnter:Connect(function()
                Tween(AnchorBtn, {BackgroundColor3=P.CardHover}, 0.12)
            end)
            AnchorBtn.MouseLeave:Connect(function()
                Tween(AnchorBtn, {BackgroundColor3=P.NavBar}, 0.12)
            end)

            local ddRef = {}

            function ddRef:AddItem(itemName, isDefault)
                table.insert(items, itemName)
                if isDefault or #items == 1 then
                    selected = itemName
                    AnchorLbl.Text = tostring(itemName)
                    AnchorLbl.TextColor3 = P.TextPrimary
                    if onSelect then onSelect(itemName) end
                end
            end

            function ddRef:GetSelected()
                return selected
            end

            function ddRef:SetSelected(v)
                selected = v
                AnchorLbl.Text = tostring(v or "Select...")
                AnchorLbl.TextColor3 = v and P.TextPrimary or P.TextSecondary
            end

            return ddRef
        end

        function Tab:CreateSection(title)
            local Sec = NewFrame(TabContent, UDim2.new(1,0,0,22), nil, P.Transparent, 1)
            Sec.LayoutOrder = #TabContent:GetChildren()
            local line = NewFrame(Sec, UDim2.new(1,0,0,1), UDim2.new(0,0,0.5,0), P.Border)
            line.BackgroundTransparency = 0.6
            line.AnchorPoint = Vector2.new(0,0.5)
            local bg = NewFrame(Sec, UDim2.new(0,0,1,0), UDim2.new(0.5,0,0,0), P.Background)
            bg.AnchorPoint = Vector2.new(0.5,0)
            bg.AutomaticSize = Enum.AutomaticSize.X
            MakePadding(bg, 0, 6, 0, 6)
            local l = NewLabel(bg, tostring(title or ""):upper(), 10, P.TextMuted, Enum.Font.GothamBold)
            l.Size = UDim2.new(0,0,1,0)
            l.AutomaticSize = Enum.AutomaticSize.X
            l.TextXAlignment = Enum.TextXAlignment.Center
        end

        function Tab:CreateInputRow(cfg)
            cfg = cfg or {}
            local Row = MakeRow(38)
            local lbl = NewLabel(Row, cfg.Name or "Input", 13, P.TextPrimary)
            lbl.Size = UDim2.new(1,-100,1,0)
            local Box = Instance.new("TextBox", Row)
            Box.Size = UDim2.new(0,90,1,-12)
            Box.Position = UDim2.new(1,-92,0.5,0)
            Box.AnchorPoint = Vector2.new(0,0.5)
            Box.BackgroundColor3 = P.NavBar
            Box.Text = tostring(cfg.Default or "")
            Box.PlaceholderText = cfg.Placeholder or ""
            Box.TextColor3 = P.TextPrimary
            Box.Font = Enum.Font.GothamMedium
            Box.TextSize = 12
            Box.BorderSizePixel = 0
            MakeCorner(Box, 5)
            MakeStroke(Box, P.Border, 1, 0.5)
            Box.FocusLost:Connect(function()
                if cfg.Callback then cfg.Callback(Box.Text) end
            end)
            return {Box = Box}
        end

        function Tab:CreateDoubleButtonRow(cfg)
            cfg = cfg or {}
            local Row = MakeRow(38)
            local lbl = NewLabel(Row, cfg.Name or "Actions", 13, P.TextPrimary)
            lbl.Size = UDim2.new(0.4,0,1,0)
            local Cont = NewFrame(Row, UDim2.new(0.6,-4,1,0), UDim2.new(0.4,2,0,0), P.Transparent, 1)
            local Layout = MakeList(Cont, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)
            local function MakeBtn(txt, cb)
                local b = Instance.new("TextButton", Cont)
                b.Size = UDim2.new(0,70,1,-10)
                b.BackgroundColor3 = P.Accent
                b.BackgroundTransparency = 0.7
                b.Text = txt
                b.TextColor3 = P.Accent
                b.Font = Enum.Font.GothamMedium
                b.TextSize = 11
                b.BorderSizePixel = 0
                MakeCorner(b, 5)
                MakeStroke(b, P.Accent, 1, 0.6)
                b.MouseButton1Click:Connect(function()
                    if cb then cb() end
                end)
                return b
            end
            MakeBtn(cfg.Button1Text or "Btn1", cfg.Callback1)
            MakeBtn(cfg.Button2Text or "Btn2", cfg.Callback2)
        end

        function Tab:CreateToggleButtonRow(cfg)
            cfg = cfg or {}
            local Row   = MakeRow(38)
            local state = cfg.Default == true
            local lbl   = NewLabel(Row, cfg.Name or "Toggle", 13, P.TextPrimary)
            lbl.Size    = UDim2.new(0.35,0,1,0)

            local Cont = NewFrame(Row, UDim2.new(0.65,-10,1,0), UDim2.new(0.35,10,0,0), P.Transparent, 1)
            local Layout = MakeList(Cont, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)

            local Track = NewFrame(Cont, UDim2.new(0,34,0,18), nil, P.Border)
            Track.LayoutOrder = 10
            Track.BackgroundTransparency = 0.4
            MakeCorner(Track, 10)
            local Thumb = NewFrame(Track, UDim2.new(0,12,0,12), UDim2.new(0,3,0.5,-6), P.TextSecondary)
            MakeCorner(Thumb, 6)

            local function SetState(v, fire)
                state = v
                local tx = v and UDim2.new(1,-15,0.5,-6) or UDim2.new(0,3,0.5,-6)
                local tc = v and P.Accent or P.TextSecondary
                local bc = v and P.Accent or P.Border
                Tween(Thumb, {Position=tx, BackgroundColor3=tc}, 0.15)
                Tween(Track, {BackgroundColor3=bc}, 0.15)
                if fire and cfg.OnToggle then cfg.OnToggle(v) end
            end
            SetState(state, false)
            Track.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then SetState(not state, true) end
            end)

            if cfg.HasSubToggle then
                local subState = cfg.SubToggleDefault == true
                local SubBtn = Instance.new("TextButton", Cont)
                SubBtn.Size = UDim2.new(0,70,0,22)
                SubBtn.LayoutOrder = 5
                SubBtn.BackgroundColor3 = P.Accent
                SubBtn.BackgroundTransparency = subState and 0.7 or 0.95
                SubBtn.Text = cfg.SubToggleName or "Sub"
                SubBtn.TextColor3 = subState and P.White or P.TextSecondary
                SubBtn.Font = Enum.Font.Gotham
                SubBtn.TextSize = 10
                SubBtn.BorderSizePixel = 0
                MakeCorner(SubBtn, 5)
                MakeStroke(SubBtn, P.Accent, 1, subState and 0.6 or 0.3)
                
                SubBtn.MouseButton1Click:Connect(function()
                    subState = not subState
                    SubBtn.BackgroundTransparency = subState and 0.7 or 0.95
                    SubBtn.TextColor3 = subState and P.White or P.TextSecondary
                    Tween(SubBtn, {BackgroundTransparency = subState and 0.7 or 0.95}, 0.1)
                    if cfg.OnSubToggle then cfg.OnSubToggle(subState) end
                end)
            end

            local Btn = Instance.new("TextButton", Cont)
            Btn.Size     = UDim2.new(0,60,0,22)
            Btn.LayoutOrder = 1
            Btn.BackgroundColor3 = P.Accent
            Btn.BackgroundTransparency = 0.7
            Btn.Text = cfg.ButtonText or "Run"
            Btn.TextColor3 = P.Accent
            Btn.Font = Enum.Font.GothamMedium
            Btn.TextSize = 11
            Btn.BorderSizePixel = 0
            Btn.Text = tostring(cfg.ButtonText or "Run")
            MakeCorner(Btn, 5)
            MakeStroke(Btn, P.Accent, 1, 0.6)
            Btn.MouseButton1Click:Connect(function()
                if cfg.OnButton then cfg.OnButton() end
            end)
            
            return {
                ToggleState = function(v) SetState(v, false) end,
                Button = Btn
            }
        end

        function Tab:CreateInputButtonRow(cfg)
            cfg = cfg or {}
            local Row = MakeRow(38)
            local lbl = NewLabel(Row, cfg.Name or "Input Action", 13, P.TextPrimary)
            lbl.Size = UDim2.new(1,-160,1,0)
            local Box = Instance.new("TextBox", Row)
            Box.Size = UDim2.new(0,70,1,-12)
            Box.Position = UDim2.new(1,-134,0.5,0)
            Box.AnchorPoint = Vector2.new(0,0.5)
            Box.BackgroundColor3 = P.NavBar
            Box.Text = tostring(cfg.Default or "")
            Box.PlaceholderText = cfg.Placeholder or ""
            Box.TextColor3 = P.TextPrimary
            Box.Font = Enum.Font.GothamMedium
            Box.TextSize = 12
            Box.BorderSizePixel = 0
            MakeCorner(Box, 5)
            MakeStroke(Box, P.Border, 1, 0.5)
            local Btn = Instance.new("TextButton", Row)
            Btn.Size = UDim2.new(0,60,1,-12)
            Btn.Position = UDim2.new(1,-62,0.5,0)
            Btn.AnchorPoint = Vector2.new(0,0.5)
            Btn.BackgroundColor3 = P.Accent
            Btn.BackgroundTransparency = 0.7
            Btn.Text = cfg.ButtonText or "Run"
            Btn.TextColor3 = P.Accent
            Btn.Font = Enum.Font.GothamMedium
            Btn.TextSize = 11
            Btn.BorderSizePixel = 0
            MakeCorner(Btn, 5)
            MakeStroke(Btn, P.Accent, 1, 0.6)
            Btn.MouseButton1Click:Connect(function()
                if cfg.Callback then cfg.Callback(Box.Text) end
            end)
        end

        function Tab:CreateAutoFarmGroup(cfg)
            cfg = cfg or {}
            local Group = NewFrame(TabContent, UDim2.new(1,0,0,0), nil, P.Card)
            Group.AutomaticSize = Enum.AutomaticSize.Y
            Group.LayoutOrder = #TabContent:GetChildren()
            MakeCorner(Group, 8)
            MakeStroke(Group, P.Border, 1, 0.6)
            local GList = MakeList(Group, Enum.FillDirection.Vertical, 0)
            local Header = NewFrame(Group, UDim2.new(1,0,0,36), nil, P.NavBar)
            MakeCorner(Header, 8)
            local Hlbl = NewLabel(Header, cfg.Name or "Automation", 12, P.Accent, Enum.Font.GothamBold)
            Hlbl.Position = UDim2.new(0,12,0,0)
            Hlbl.Size = UDim2.new(1,-60,1,0)
            local masterState = false
            if cfg.HasMasterToggle then
                local track = NewFrame(Header, UDim2.new(0,34,0,18), UDim2.new(1,-44,0.5,-9), P.Border)
                track.BackgroundTransparency = 0.4
                MakeCorner(track, 10)
                local thumb = NewFrame(track, UDim2.new(0,12,0,12), UDim2.new(0,3,0.5,-6), P.TextSecondary)
                MakeCorner(thumb, 6)
                local function SetMaster(v, fire)
                    masterState = v
                    local tx = v and UDim2.new(1,-15,0.5,-6) or UDim2.new(0,3,0.5,-6)
                    local tc = v and P.Accent or P.TextSecondary
                    local bc = v and P.Accent or P.Border
                    Tween(thumb, {Position=tx, BackgroundColor3=tc}, 0.15)
                    Tween(track, {BackgroundColor3=bc}, 0.15)
                    if fire and cfg.OnMasterToggle then cfg.OnMasterToggle(v) end
                end
                track.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then SetMaster(not masterState, true) end
                end)
            end
            local SkillObj = {}
            local function AddRow()
                local r = NewFrame(Group, UDim2.new(1,0,0,34), nil, P.Transparent, 1)
                MakePadding(r, 0, 10, 0, 10)
                local div = NewFrame(r, UDim2.new(1,0,0,1), UDim2.new(0,0,0,0), P.Border, 0.8)
                return r
            end
            function SkillObj:AddSkill(name, default, onToggle, onDelay)
                local r = AddRow()
                local lbl = NewLabel(r, name, 12, P.TextPrimary)
                lbl.Size = UDim2.new(0.4,0,1,0)
                local Cont = NewFrame(r, UDim2.new(0.6,0,1,0), UDim2.new(0.4,0,0,0), P.Transparent, 1)
                local Layout = MakeList(Cont, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)
                local state = default == true
                local track = NewFrame(Cont, UDim2.new(0,32,0,16), nil, P.Border)
                track.LayoutOrder = 10
                track.BackgroundTransparency = 0.4
                MakeCorner(track, 8)
                local thumb = NewFrame(track, UDim2.new(0,10,0,10), UDim2.new(0,3,0.5,-5), P.TextSecondary)
                MakeCorner(thumb, 5)
                local function SetS(v, fire)
                    state = v
                    local tx = v and UDim2.new(1,-13,0.5,-5) or UDim2.new(0,3,0.5,-5)
                    local tc = v and P.Accent or P.TextSecondary
                    Tween(thumb, {Position=tx, BackgroundColor3=tc}, 0.1)
                    Tween(track, {BackgroundColor3 = v and P.Accent or P.Border}, 0.1)
                    if fire and onToggle then onToggle(v) end
                end
                SetS(state, false)
                track.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then SetS(not state, true) end
                end)
                local Box = Instance.new("TextBox", Cont)
                Box.Size = UDim2.new(0,40,0,20)
                Box.LayoutOrder = 1
                Box.BackgroundColor3 = P.NavBar
                Box.Text = "0.5"
                Box.TextColor3 = P.TextPrimary
                Box.Font = Enum.Font.Gotham
                Box.TextSize = 10
                MakeCorner(Box, 4)
                MakeStroke(Box, P.Border, 1, 0.6)
                Box.FocusLost:Connect(function()
                    if onDelay then onDelay(tonumber(Box.Text) or 0.5) end
                end)
                return { SetValue = function(v) SetS(v, false) end }
            end
            function SkillObj:AddMultiSkillRow(skillsData)
                local r = AddRow()
                local Layout = MakeList(r, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
                local res = {}
                for _, data in ipairs(skillsData) do
                    local b = Instance.new("TextButton", r)
                    b.Size = UDim2.new(0,60,0,22)
                    b.BackgroundColor3 = P.Accent
                    b.BackgroundTransparency = 0.8
                    b.Text = data.Text or "Skill"
                    b.TextColor3 = P.TextPrimary
                    b.Font = Enum.Font.Gotham
                    b.TextSize = 10
                    MakeCorner(b, 4)
                    MakeStroke(b, P.Accent, 1, 0.7)
                    b.MouseButton1Click:Connect(function()
                        if data.Callback then data.Callback() end
                    end)
                end
            end
            function SkillObj:AddActionInputRow(cfg)
                local r = AddRow()
                local lbl = NewLabel(r, cfg.Name or "Action", 12, P.TextPrimary)
                lbl.Size = UDim2.new(0.5,0,1,0)
                local Cont = NewFrame(r, UDim2.new(0.5,0,1,0), UDim2.new(0.5,0,0,0), P.Transparent, 1)
                local LL = MakeList(Cont, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)
                local Box = Instance.new("TextBox", Cont)
                Box.Size = UDim2.new(0,60,0,22)
                Box.BackgroundColor3 = P.NavBar
                Box.Text = tostring(cfg.Default or "")
                Box.TextColor3 = P.TextPrimary
                Box.Font = Enum.Font.Gotham
                Box.TextSize = 11
                MakeCorner(Box, 4)
                MakeStroke(Box, P.Border, 1, 0.6)
                local b = Instance.new("TextButton", Cont)
                b.Size = UDim2.new(0,50,0,22)
                b.BackgroundColor3 = P.Accent
                b.BackgroundTransparency = 0.7
                b.Text = cfg.ButtonText or "Run"
                b.TextColor3 = P.Accent
                b.Font = Enum.Font.GothamMedium
                b.TextSize = 10
                MakeCorner(b, 4)
                b.MouseButton1Click:Connect(function()
                    if cfg.Callback then cfg.Callback(Box.Text) end
                end)
            end
            function SkillObj:AddUnifiedActionRow(cfg, btns)
                local r = AddRow()
                local lbl = NewLabel(r, cfg.Name or "Actions", 12, P.TextPrimary)
                lbl.Size = UDim2.new(0.3,0,1,0)
                local Cont = NewFrame(r, UDim2.new(0.7,0,1,0), UDim2.new(0.3,0,0,0), P.Transparent, 1)
                MakeList(Cont, Enum.FillDirection.Horizontal, 4, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)
                for _, bdata in ipairs(btns) do
                    local b = Instance.new("TextButton", Cont)
                    b.Size = UDim2.new(0,55,0,22)
                    b.BackgroundColor3 = P.Accent
                    b.BackgroundTransparency = 0.8
                    b.Text = bdata.Text or "Btn"
                    b.TextColor3 = P.Accent
                    b.Font = Enum.Font.Gotham
                    b.TextSize = 10
                    MakeCorner(b, 4)
                    b.MouseButton1Click:Connect(function()
                        if bdata.Callback then bdata.Callback() end
                    end)
                end
            end
            return SkillObj
        end

        function Tab:CreateMultiSelectDropdown(cfg)
            cfg = cfg or {}
            local name = cfg.Name or "Filter"
            local items = {}
            local Row = MakeRow(38)
            local lbl = NewLabel(Row, name, 13, P.TextPrimary)
            lbl.Size = UDim2.new(0.35,0,1,0)
            local Cont = NewFrame(Row, UDim2.new(0.65,-4,1,0), UDim2.new(0.35,2,0,0), P.Transparent, 1)
            local Layout = MakeList(Cont, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)
            local mainState = false
            local mainTrack, mainThumb
            if cfg.HasMainToggle then
                mainTrack = NewFrame(Cont, UDim2.new(0,34,0,18), nil, P.Border)
                mainTrack.BackgroundTransparency = 0.4
                MakeCorner(mainTrack, 10)
                mainThumb = NewFrame(mainTrack, UDim2.new(0,12,0,12), UDim2.new(0,3,0.5,-6), P.TextSecondary)
                MakeCorner(mainThumb, 6)
                local function SetMain(v, fire)
                    mainState = v
                    local tx = v and UDim2.new(1,-15,0.5,-6) or UDim2.new(0,3,0.5,-6)
                    local tc = v and P.Accent or P.TextSecondary
                    local bc = v and P.Accent or P.Border
                    Tween(mainThumb, {Position=tx, BackgroundColor3=tc}, 0.15)
                    Tween(mainTrack, {BackgroundColor3=bc}, 0.15)
                    if fire and cfg.OnMainToggle then cfg.OnMainToggle(v) end
                end
                mainTrack.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then SetMain(not mainState, true) end
                end)
            end
            local FilterBtn = Instance.new("TextButton", Cont)
            FilterBtn.Size = UDim2.new(0,80,1,-10)
            FilterBtn.BackgroundColor3 = P.NavBar
            FilterBtn.Text = "Filter v"
            FilterBtn.TextColor3 = P.TextSecondary
            FilterBtn.Font = Enum.Font.GothamMedium
            FilterBtn.TextSize = 11
            FilterBtn.BorderSizePixel = 0
            MakeCorner(FilterBtn, 5)
            MakeStroke(FilterBtn, P.Border, 1, 0.5)
            
            local panelOpen = false
            local Panel
            local function OpenPanel()
                if panelOpen then
                    panelOpen = false
                    Tween(Panel, {Size=UDim2.new(Panel.Size.X.Scale, Panel.Size.X.Offset, 0, 0), BackgroundTransparency=1}, 0.15)
                    task.delay(0.2, function() if Panel then Panel:Destroy() Panel=nil end end)
                    return
                end
                panelOpen = true
                local abs = FilterBtn.AbsolutePosition
                local size = FilterBtn.AbsoluteSize
                Panel = NewFrame(OverlayGui, UDim2.new(0,size.X+40,0,0), UDim2.new(0,abs.X-40,0,abs.Y+size.Y+4), P.Card)
                Panel.ClipsDescendants = true
                MakeCorner(Panel, 7)
                MakeStroke(Panel, P.Border, 1, 0.4)

                local ScrollSize = UDim2.new(1,0,1,0)
                local ScrollPos  = UDim2.new(0,0,0,0)

                if cfg.HasSearch then
                    local SearchBox = Instance.new("TextBox", Panel)
                    SearchBox.Size = UDim2.new(1,-16,0,24)
                    SearchBox.Position = UDim2.new(0,8,0,8)
                    SearchBox.BackgroundColor3 = P.NavBar
                    SearchBox.Text = ""
                    SearchBox.PlaceholderText = "Search..."
                    SearchBox.TextColor3 = P.TextPrimary
                    SearchBox.PlaceholderColor3 = P.TextSecondary
                    SearchBox.Font = Enum.Font.Gotham
                    SearchBox.TextSize = 11
                    SearchBox.BorderSizePixel = 0
                    MakeCorner(SearchBox, 5)
                    MakeStroke(SearchBox, P.Border, 1, 0.5)

                    ScrollSize = UDim2.new(1,0,1,-40)
                    ScrollPos  = UDim2.new(0,0,0,36)

                    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                        local q = SearchBox.Text:lower()
                        for _, itm in ipairs(items) do
                            if itm.Btn then
                                itm.Btn.Visible = itm.Name:lower():find(q) ~= nil
                            end
                        end
                    end)
                end

                local Scroll = Instance.new("ScrollingFrame", Panel)
                Scroll.Size = ScrollSize
                Scroll.Position = ScrollPos
                Scroll.BackgroundTransparency = 1
                Scroll.BorderSizePixel = 0
                Scroll.ScrollBarThickness = 2
                Scroll.ScrollBarImageColor3 = P.Accent
                local PList = MakeList(Scroll, Enum.FillDirection.Vertical, 2)
                MakePadding(Scroll, 4, 4, 4, 4)
                for _, itm in ipairs(items) do
                    local b = Instance.new("TextButton", Scroll)
                    itm.Btn = b
                    b.Size = UDim2.new(1,0,0,24)
                    b.BackgroundColor3 = itm.State and P.Accent or P.NavBar
                    b.BackgroundTransparency = itm.State and 0.8 or 0
                    b.Text = itm.Name
                    b.TextColor3 = itm.State and P.Accent or P.TextPrimary
                    b.Font = Enum.Font.Gotham
                    b.TextSize = 11
                    b.BorderSizePixel = 0
                    MakeCorner(b, 4)
                    b.MouseButton1Click:Connect(function()
                        itm.State = not itm.State
                        Tween(b, {BackgroundColor3 = itm.State and P.Accent or P.NavBar, BackgroundTransparency = itm.State and 0.8 or 0, TextColor3 = itm.State and P.Accent or P.TextPrimary}, 0.1)
                        if itm.Callback then itm.Callback(itm.State) end
                    end)
                end
                local targetH = math.min(#items * 26 + (cfg.HasSearch and 44 or 8), 200)
                Tween(Panel, {Size=UDim2.new(0,size.X+40,0,targetH), BackgroundTransparency=0}, 0.15)
            end
            FilterBtn.MouseButton1Click:Connect(OpenPanel)
            
            local ddRef = {}
            function ddRef:AddItem(name, default, callback)
                table.insert(items, {Name=name, State=default, Callback=callback})
            end
            return ddRef
        end

        function Tab:CreateSliderRow(cfg)
            cfg = cfg or {}
            local name     = cfg.Name or "Slider"
            local min      = cfg.Min or 0
            local max      = cfg.Max or 100
            local default  = cfg.Default or 50
            local prefix   = cfg.Prefix or ""
            local suffix   = cfg.Suffix or ""
            local callback = cfg.Callback or function() end

            local Row = MakeRow(38)
            local lbl = NewLabel(Row, name, 13, P.TextPrimary)
            lbl.Size = UDim2.new(0.35, 0, 1, 0)

            local Cont = NewFrame(Row, UDim2.new(0.65, -10, 1, 0), UDim2.new(0.35, 10, 0, 0), P.Transparent, 1)
            
            local ValTxt = NewLabel(Cont, prefix .. tostring(default) .. suffix, 11, P.TextSecondary, Enum.Font.GothamMedium, Enum.TextXAlignment.Right)
            ValTxt.Size = UDim2.new(0, 40, 1, 0)
            ValTxt.Position = UDim2.new(1, -40, 0, 0)

            local SlideBg = Instance.new("TextButton", Cont)
            SlideBg.Size = UDim2.new(1, -50, 0, 20)
            SlideBg.Position = UDim2.new(0, 0, 0.5, 0)
            SlideBg.AnchorPoint = Vector2.new(0, 0.5)
            SlideBg.BackgroundTransparency = 1
            SlideBg.Text = ""

            local Track = NewFrame(SlideBg, UDim2.new(1, 0, 0, 4), UDim2.new(0, 0, 0.5, 0), P.NavBar)
            Track.AnchorPoint = Vector2.new(0, 0.5)
            MakeCorner(Track, 2)
            MakeStroke(Track, P.Border, 1, 0.4)

            local Fill = NewFrame(Track, UDim2.new((default - min) / (max - min), 0, 1, 0), nil, P.Accent)
            MakeCorner(Fill, 2)

            local Knob = NewFrame(Fill, UDim2.new(0, 12, 0, 12), UDim2.new(1, 0, 0.5, 0), P.White)
            Knob.AnchorPoint = Vector2.new(0.5, 0.5)
            MakeCorner(Knob, 6)
            MakeStroke(Knob, P.Accent, 1, 0.8)

            local dragging = false
            local function update(input)
                local relX = math.clamp(input.Position.X - SlideBg.AbsolutePosition.X, 0, SlideBg.AbsoluteSize.X)
                local pct = relX / SlideBg.AbsoluteSize.X
                local val = math.floor(min + (pct * (max - min)))
                Fill.Size = UDim2.new(pct, 0, 1, 0)
                ValTxt.Text = prefix .. tostring(val) .. suffix
                pcall(callback, val)
            end

            SlideBg.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true update(i) end
            end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then update(i) end
            end)

            return { SetValue = function(v) 
                local pct = math.clamp((v - min) / (max - min), 0, 1)
                Fill.Size = UDim2.new(pct, 0, 1, 0)
                ValTxt.Text = prefix .. tostring(v) .. suffix
            end }
        end

        -- Aliases for compatibility
        Tab.CreateDropdown = Tab.CreateDropdownButton
        Tab.CreateButton   = Tab.CreateButtonRow
        Tab.CreateToggle   = Tab.CreateToggleButtonRow
        Tab.CreateSlider   = Tab.CreateSliderRow

        return Tab
    end

    function Win:SetToggleKey(keyStr)
        local k = Enum.KeyCode[string.upper(keyStr)]
        if k then self.ToggleKey = k end
    end

    function Win:UpdateCooldown(skillName, duration)
        local HUD = RootGui.Parent:FindFirstChild("SkenaHUD")
        if not HUD then
            HUD = Instance.new("ScreenGui", RootGui.Parent)
            HUD.Name = "SkenaHUD"
            local Container = NewFrame(HUD, UDim2.new(0, 200, 0, 0), UDim2.new(1, -210, 1, -20), P.Transparent, 1)
            Container.Name = "Container"
            Container.AnchorPoint = Vector2.new(0, 1)
            Container.AutomaticSize = Enum.AutomaticSize.Y
            MakeList(Container, Enum.FillDirection.Vertical, 5, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Bottom)
        end
        local Container = HUD.Container
        local Item = Container:FindFirstChild(skillName)
        if duration <= 0 then
            if Item then
                Tween(Item, {GroupTransparency = 1}, 0.3)
                task.delay(0.3, function() Item:Destroy() end)
            end
            return
        end
        if not Item then
            local cg = Instance.new("CanvasGroup", Container)
            cg.Name = skillName
            cg.Size = UDim2.new(1, 0, 0, 30)
            cg.BackgroundColor3 = P.Card
            cg.GroupTransparency = 1
            MakeCorner(cg, 6)
            MakeStroke(cg, P.Border, 1, 0.6)
            local lbl = NewLabel(cg, skillName, 11, P.TextPrimary)
            lbl.Position = UDim2.new(0, 8, 0, 0)
            lbl.Size = UDim2.new(1, -60, 1, 0)
            local tim = NewLabel(cg, string.format("%.1fs", duration), 11, P.Accent, Enum.Font.GothamMedium, Enum.TextXAlignment.Right)
            tim.Name = "Time"
            tim.Position = UDim2.new(1, -55, 0, 0)
            tim.Size = UDim2.new(0, 50, 1, 0)
            Tween(cg, {GroupTransparency = 0}, 0.3)
            Item = cg
        end
        Item.Time.Text = string.format("%.1fs", duration)
    end

    return Win
end

return SkenaUI