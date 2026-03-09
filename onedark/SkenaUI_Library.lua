-- SkenaUI Library v3.0 | One Dark Theme
-- Reusable UI library for Roblox exploits.
-- Game scripts only call the public API; zero layout code in game files.
--
-- PUBLIC API SUMMARY:
--   local Win  = SkenaUI:CreateWindow({ Name, Width, Height, ToggleKey })
--   local Tab  = Win:CreateTab("TabName", optionalIconId)
--   Tab:AddSection("Title")
--   Tab:AddRow({ cols = {
--     { type="Toggle",   name="", default=false, callback=fn },
--     { type="Button",   name="", callback=fn },
--     { type="Slider",   name="", min=0, max=100, default=50, step=1, callback=fn },
--     { type="Dropdown", name="", options={}, default=nil, multi=false, callback=fn },
--     { type="Input",    name="", placeholder="", callback=fn },
--     { type="Keybind",  name="", default=Enum.KeyCode.F, callback=fn },
--     { type="Label",    text="" },
--   }})

------------------------------------------------------------------------
-- SERVICES
------------------------------------------------------------------------
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")
local CoreGui        = game:GetService("CoreGui")

local LocalPlayer    = Players.LocalPlayer
local Mouse          = LocalPlayer:GetMouse()

------------------------------------------------------------------------
-- PALETTE  (One Dark)
------------------------------------------------------------------------
local P = {
    Background   = Color3.fromRGB(40,  44,  52),   -- #282C34
    Card         = Color3.fromRGB(44,  49,  59),   -- #2C313B
    CardHover    = Color3.fromRGB(50,  56,  66),   -- slightly lighter card
    NavBar       = Color3.fromRGB(33,  37,  43),   -- #21252B
    TitleBar     = Color3.fromRGB(33,  37,  43),
    Border       = Color3.fromRGB(60,  66,  78),
    TextPrimary  = Color3.fromRGB(171, 178, 191),  -- #ABB2BF
    TextSecondary= Color3.fromRGB(92,  99,  112),  -- #5C6370
    TextMuted    = Color3.fromRGB(70,  77,  90),
    Accent       = Color3.fromRGB(97,  175, 239),  -- #61AFEF  (blue)
    AccentDim    = Color3.fromRGB(60,  120, 180),
    Green        = Color3.fromRGB(152, 195, 121),  -- #98C379
    Red          = Color3.fromRGB(224, 108, 117),  -- #E06C75
    Yellow       = Color3.fromRGB(229, 192, 123),  -- #E5C07B
    Purple       = Color3.fromRGB(198, 120, 221),  -- #C678DD
    White        = Color3.fromRGB(255, 255, 255),
    Transparent  = Color3.fromRGB(0,   0,   0),
}

------------------------------------------------------------------------
-- UTILITY
------------------------------------------------------------------------
local function Tween(obj, props, t, style, dir)
    style = style or Enum.EasingStyle.Quart
    dir   = dir   or Enum.EasingDirection.Out
    TweenService:Create(obj, TweenInfo.new(t, style, dir), props):Play()
end

local function MakeCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = parent
    return c
end

local function MakePadding(parent, top, right, bottom, left)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, top    or 0)
    p.PaddingRight  = UDim.new(0, right  or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.PaddingLeft   = UDim.new(0, left   or 0)
    p.Parent = parent
    return p
end

local function MakeListLayout(parent, dir, padding, ha, va)
    local l = Instance.new("UIListLayout")
    l.FillDirection       = dir or Enum.FillDirection.Vertical
    l.Padding             = UDim.new(0, padding or 0)
    l.HorizontalAlignment = ha  or Enum.HorizontalAlignment.Left
    l.VerticalAlignment   = va  or Enum.VerticalAlignment.Top
    l.SortOrder           = Enum.SortOrder.LayoutOrder
    l.Parent = parent
    return l
end

local function MakeStroke(parent, color, thick, trans)
    local s = Instance.new("UIStroke")
    s.Color       = color or P.Border
    s.Thickness   = thick or 1
    s.Transparency = trans or 0.6
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function NewLabel(parent, text, size, color, font, ha)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text or ""
    l.TextSize = size or 13
    l.TextColor3 = color or P.TextPrimary
    l.Font = font or Enum.Font.GothamMedium
    l.TextXAlignment = ha or Enum.TextXAlignment.Left
    l.TextTruncate = Enum.TextTruncate.AtEnd
    l.Parent = parent
    return l
end

local function NewFrame(parent, size, pos, color, trans)
    local f = Instance.new("Frame")
    f.Size = size or UDim2.new(1,0,0,30)
    f.Position = pos or UDim2.new(0,0,0,0)
    f.BackgroundColor3 = color or P.Card
    f.BackgroundTransparency = trans or 0
    f.BorderSizePixel = 0
    f.Parent = parent
    return f
end

local function AutoSize(list, parent)
    -- Connects UIListLayout.AbsoluteContentSizeChanged to auto-resize parent height
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        parent.Size = UDim2.new(parent.Size.X.Scale, parent.Size.X.Offset, 0, list.AbsoluteContentSize.Y)
    end)
end

------------------------------------------------------------------------
-- DRAG HELPER
------------------------------------------------------------------------
local function MakeDraggable(topbar, frame)
    local dragging, dragStart, startPos
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
        end
    end)
    topbar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

------------------------------------------------------------------------
-- ROOT SCREENGUI
------------------------------------------------------------------------
local RootGui = Instance.new("ScreenGui")
RootGui.Name            = "SkenaUI_v3"
RootGui.ResetOnSpawn    = false
RootGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
RootGui.IgnoreGuiInset  = true
pcall(function() RootGui.Parent = CoreGui end)
if not RootGui.Parent then RootGui.Parent = LocalPlayer.PlayerGui end

-- Separate overlay gui for floating dropdowns (always renders on top)
local OverlayGui = Instance.new("ScreenGui")
OverlayGui.Name           = "SkenaUI_Overlay"
OverlayGui.ResetOnSpawn   = false
OverlayGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
OverlayGui.DisplayOrder   = 999
pcall(function() OverlayGui.Parent = CoreGui end)
if not OverlayGui.Parent then OverlayGui.Parent = LocalPlayer.PlayerGui end

------------------------------------------------------------------------
-- LIBRARY TABLE
------------------------------------------------------------------------
local SkenaUI = {}
SkenaUI.__index = SkenaUI

------------------------------------------------------------------------
-- CreateWindow
------------------------------------------------------------------------
function SkenaUI:CreateWindow(cfg)
    cfg = cfg or {}
    local winName   = cfg.Name      or "SkenaUI"
    local winW      = cfg.Width     or 560
    local winH      = cfg.Height    or 420
    local toggleKey = cfg.ToggleKey or Enum.KeyCode.RightControl

    -- Blur background
    local blur = Instance.new("BlurEffect")
    blur.Size   = 0
    blur.Parent = game:GetService("Lighting")

    -- Main window frame
    local WinFrame = NewFrame(RootGui,
        UDim2.new(0, winW, 0, winH),
        UDim2.new(0.5, -winW/2, 0.5, -winH/2),
        P.Background
    )
    WinFrame.Name        = "SkenaWindow"
    WinFrame.ClipsDescendants = true
    MakeCorner(WinFrame, 10)
    MakeStroke(WinFrame, P.Border, 1, 0.5)

    -- Entry animation
    WinFrame.Size = UDim2.new(0, winW, 0, 0)
    WinFrame.BackgroundTransparency = 1
    Tween(WinFrame, { Size = UDim2.new(0,winW,0,winH), BackgroundTransparency=0 }, 0.35)
    Tween(blur, { Size = 8 }, 0.35)

    -- Title bar
    local TitleBar = NewFrame(WinFrame,
        UDim2.new(1, 0, 0, 36),
        UDim2.new(0,0,0,0),
        P.TitleBar
    )
    TitleBar.Name = "TitleBar"
    MakeDraggable(TitleBar, WinFrame)

    local TitleLabel = NewLabel(TitleBar, winName, 14, P.TextPrimary, Enum.Font.GothamBold)
    TitleLabel.Size = UDim2.new(1,-80,1,0)
    TitleLabel.Position = UDim2.new(0,12,0,0)

    -- Close button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0,28,0,28)
    CloseBtn.Position = UDim2.new(1,-34,0.5,-14)
    CloseBtn.BackgroundColor3 = P.Red
    CloseBtn.BackgroundTransparency = 0.5
    CloseBtn.Text = "×"
    CloseBtn.TextColor3 = P.White
    CloseBtn.TextSize = 16
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Parent = TitleBar
    MakeCorner(CloseBtn, 6)
    CloseBtn.MouseEnter:Connect(function() Tween(CloseBtn,{BackgroundTransparency=0.1},0.15) end)
    CloseBtn.MouseLeave:Connect(function() Tween(CloseBtn,{BackgroundTransparency=0.5},0.15) end)
    CloseBtn.MouseButton1Click:Connect(function()
        Tween(WinFrame, {Size=UDim2.new(0,winW,0,0), BackgroundTransparency=1}, 0.25)
        Tween(blur, {Size=0}, 0.25)
        task.delay(0.3, function() WinFrame:Destroy() blur:Destroy() end)
    end)

    -- Toggle visibility
    UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and input.KeyCode == toggleKey then
            WinFrame.Visible = not WinFrame.Visible
            Tween(blur, {Size = WinFrame.Visible and 8 or 0}, 0.2)
        end
    end)

    -- NavBar (horizontal tabs strip)
    local NavBar = NewFrame(WinFrame,
        UDim2.new(1, 0, 0, 38),
        UDim2.new(0, 0, 0, 36),
        P.NavBar
    )
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

    local NavLayout = MakeListLayout(NavScroll, Enum.FillDirection.Horizontal, 2)
    NavLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        NavScroll.CanvasSize = UDim2.new(0, NavLayout.AbsoluteContentSize.X + 8, 1, 0)
    end)

    -- Bottom divider under NavBar
    local NavDivider = NewFrame(WinFrame, UDim2.new(1,0,0,1), UDim2.new(0,0,0,74), P.Border)
    NavDivider.BackgroundTransparency = 0.6

    -- Body (scrollable content area below navbar)
    local BodyScroll = Instance.new("ScrollingFrame")
    BodyScroll.Name = "BodyScroll"
    BodyScroll.Size = UDim2.new(1,-4, 1, -76)
    BodyScroll.Position = UDim2.new(0,0,0,76)
    BodyScroll.BackgroundTransparency = 1
    BodyScroll.BorderSizePixel = 0
    BodyScroll.ScrollBarThickness = 3
    BodyScroll.ScrollBarImageColor3 = P.Accent
    BodyScroll.CanvasSize = UDim2.new(0,0,0,0)
    BodyScroll.Parent = WinFrame

    -- Window object
    local Win = {
        Frame       = WinFrame,
        NavScroll   = NavScroll,
        BodyScroll  = BodyScroll,
        _tabs       = {},
        _activeTab  = nil,
    }

    ------------------------------------------------------------------------
    -- CreateTab
    ------------------------------------------------------------------------
    function Win:CreateTab(tabName, iconId)
        -- Tab content container
        local TabContent = NewFrame(BodyScroll,
            UDim2.new(1,-16, 0, 0),
            UDim2.new(0,8,0,8),
            P.Transparent, 1
        )
        TabContent.Name    = "Tab_"..tabName
        TabContent.Visible = false
        local TabList = MakeListLayout(TabContent, Enum.FillDirection.Vertical, 6)
        AutoSize(TabList, TabContent)

        -- NavBar button
        local NavBtn = Instance.new("TextButton")
        NavBtn.Size = UDim2.new(0, 0, 1, -8)
        NavBtn.AutomaticSize = Enum.AutomaticSize.X
        NavBtn.BackgroundColor3 = P.CardHover
        NavBtn.BackgroundTransparency = 1
        NavBtn.BorderSizePixel = 0
        NavBtn.Text = ""
        NavBtn.Parent = NavScroll
        MakeCorner(NavBtn, 5)
        MakePadding(NavBtn, 0, 10, 0, 10)

        local NavBtnLayout = MakeListLayout(NavBtn, Enum.FillDirection.Horizontal, 5,
            Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)

        if iconId then
            local ico = Instance.new("ImageLabel")
            ico.Size = UDim2.new(0,14,0,14)
            ico.BackgroundTransparency = 1
            ico.Image = "rbxassetid://"..tostring(iconId)
            ico.ImageColor3 = P.TextSecondary
            ico.LayoutOrder = 0
            ico.Parent = NavBtn
        end

        local NavLabel = NewLabel(NavBtn, tabName, 13, P.TextSecondary, Enum.Font.GothamMedium, Enum.TextXAlignment.Center)
        NavLabel.Size = UDim2.new(0,0,0,14)
        NavLabel.AutomaticSize = Enum.AutomaticSize.X
        NavLabel.LayoutOrder = 1

        -- Underline indicator
        local Underline = NewFrame(NavBtn, UDim2.new(0,0,0,2), UDim2.new(0.5,0,1,-2), P.Accent, 1)
        Underline.AnchorPoint = Vector2.new(0.5,1)
        MakeCorner(Underline, 2)

        local Tab = {
            Name       = tabName,
            Content    = TabContent,
            NavBtn     = NavBtn,
            NavLabel   = NavLabel,
            Underline  = Underline,
            _win       = Win,
        }
        table.insert(Win._tabs, Tab)

        -- Activate logic
        local function Activate()
            -- Deactivate all
            for _, t in ipairs(Win._tabs) do
                t.Content.Visible = false
                Tween(t.NavLabel,   {TextColor3=P.TextSecondary}, 0.15)
                Tween(t.Underline,  {BackgroundTransparency=1, Size=UDim2.new(0,0,0,2)}, 0.15)
                Tween(t.NavBtn,     {BackgroundTransparency=1}, 0.15)
            end
            -- Activate this
            TabContent.Visible = true
            Win._activeTab = Tab
            Tween(NavLabel,   {TextColor3=P.Accent}, 0.15)
            Tween(Underline,  {BackgroundTransparency=0, Size=UDim2.new(1,0,0,2)}, 0.2)
            Tween(NavBtn,     {BackgroundTransparency=0.85}, 0.15)
            -- Update body canvas
            BodyScroll.CanvasSize = UDim2.new(0,0,0, TabContent.AbsoluteSize.Y + 16)
        end
        TabList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            if Win._activeTab == Tab then
                BodyScroll.CanvasSize = UDim2.new(0,0,0, TabList.AbsoluteContentSize.Y + 16)
            end
        end)

        NavBtn.MouseButton1Click:Connect(Activate)
        NavBtn.MouseEnter:Connect(function()
            if Win._activeTab ~= Tab then Tween(NavBtn,{BackgroundTransparency=0.92},0.1) end
        end)
        NavBtn.MouseLeave:Connect(function()
            if Win._activeTab ~= Tab then Tween(NavBtn,{BackgroundTransparency=1},0.1) end
        end)

        -- Auto-activate first tab
        if #Win._tabs == 1 then Activate() end

        -- ----------------------------------------------------------------
        -- AddSection
        -- ----------------------------------------------------------------
        function Tab:AddSection(title)
            local Sec = NewFrame(TabContent, UDim2.new(1,0,0,22), nil, P.Transparent, 1)
            Sec.LayoutOrder = #TabContent:GetChildren()

            local line = NewFrame(Sec, UDim2.new(1,0,0,1), UDim2.new(0,0,0.5,0), P.Border)
            line.BackgroundTransparency = 0.6
            line.AnchorPoint = Vector2.new(0,0.5)

            local bg = NewFrame(Sec, UDim2.new(0,0,1,0), UDim2.new(0,0,0,0), P.Background)
            bg.AutomaticSize = Enum.AutomaticSize.X
            MakePadding(bg, 0, 6, 0, 6)

            local lbl = NewLabel(bg, title:upper(), 10, P.TextMuted, Enum.Font.GothamBold)
            lbl.Size = UDim2.new(0,0,1,0)
            lbl.AutomaticSize = Enum.AutomaticSize.X
            lbl.TextXAlignment = Enum.TextXAlignment.Center
        end

        -- ----------------------------------------------------------------
        -- AddRow  (flexible multi-column layout)
        -- ----------------------------------------------------------------
        function Tab:AddRow(cfg2)
            cfg2 = cfg2 or {}
            local cols = cfg2.cols or {}
            if #cols == 0 then return end

            local RowFrame = NewFrame(TabContent, UDim2.new(1,0,0,36), nil, P.Card)
            RowFrame.LayoutOrder = #TabContent:GetChildren()
            MakeCorner(RowFrame, 6)
            MakeStroke(RowFrame, P.Border, 1, 0.7)
            MakePadding(RowFrame, 0, 8, 0, 8)

            -- Each column gets equal horizontal space
            local colW = 1/#cols
            local refs = {} -- widget references returned

            for i, colCfg in ipairs(cols) do
                local ColFrame = NewFrame(RowFrame,
                    UDim2.new(colW, i==#cols and 0 or -4, 1, 0),
                    UDim2.new(colW*(i-1), 0, 0, 0),
                    P.Transparent, 1
                )
                ColFrame.Name = "Col"..i

                local t = colCfg.type or "Label"
                local ref = {}

                -----------------------------------------------------------
                -- LABEL
                -----------------------------------------------------------
                if t == "Label" then
                    local lbl = NewLabel(ColFrame, colCfg.text or "", 13, P.TextSecondary)
                    lbl.Size = UDim2.new(1,0,1,0)
                    ref.Label = lbl

                -----------------------------------------------------------
                -- BUTTON
                -----------------------------------------------------------
                elseif t == "Button" then
                    local Btn = Instance.new("TextButton")
                    Btn.Size = UDim2.new(1,0,1,-8)
                    Btn.Position = UDim2.new(0,0,0.5,-((1-8)/2))
                    Btn.AnchorPoint = Vector2.new(0,0.5)
                    Btn.BackgroundColor3 = P.Accent
                    Btn.BackgroundTransparency = 0.7
                    Btn.Text = colCfg.name or "Button"
                    Btn.TextColor3 = P.Accent
                    Btn.TextSize = 12
                    Btn.Font = Enum.Font.GothamMedium
                    Btn.BorderSizePixel = 0
                    Btn.AutoButtonColor = false
                    Btn.Parent = ColFrame
                    MakeCorner(Btn, 5)
                    MakeStroke(Btn, P.Accent, 1, 0.6)

                    Btn.MouseEnter:Connect(function()
                        Tween(Btn,{BackgroundTransparency=0.4,TextColor3=P.White},0.12)
                    end)
                    Btn.MouseLeave:Connect(function()
                        Tween(Btn,{BackgroundTransparency=0.7,TextColor3=P.Accent},0.12)
                    end)
                    Btn.MouseButton1Click:Connect(function()
                        Tween(Btn,{BackgroundTransparency=0.2},0.08)
                        task.delay(0.1,function() Tween(Btn,{BackgroundTransparency=0.7},0.12) end)
                        if colCfg.callback then colCfg.callback() end
                    end)
                    ref.Button = Btn

                -----------------------------------------------------------
                -- TOGGLE
                -----------------------------------------------------------
                elseif t == "Toggle" then
                    local state = colCfg.default == true

                    -- Label
                    local lbl = NewLabel(ColFrame, colCfg.name or "Toggle", 13, P.TextPrimary)
                    lbl.Size = UDim2.new(1,-46,1,0)
                    lbl.Position = UDim2.new(0,0,0,0)

                    -- Track
                    local Track = NewFrame(ColFrame, UDim2.new(0,36,0,18), UDim2.new(1,-38,0.5,-9), P.Border)
                    Track.BackgroundTransparency = 0.4
                    MakeCorner(Track, 9)

                    -- Thumb
                    local Thumb = NewFrame(Track, UDim2.new(0,14,0,14), UDim2.new(0,2,0.5,-7), P.TextSecondary)
                    MakeCorner(Thumb, 7)

                    local function SetToggle(v, cb)
                        state = v
                        local tx = v and UDim2.new(0,20,0.5,-7) or UDim2.new(0,2,0.5,-7)
                        local tc = v and P.Accent or P.TextSecondary
                        local bc = v and P.Accent or P.Border
                        local btr = v and 0.6 or 0.4
                        Tween(Thumb, {Position=tx, BackgroundColor3=tc}, 0.18)
                        Tween(Track, {BackgroundColor3=bc, BackgroundTransparency=btr}, 0.18)
                        if cb and colCfg.callback then colCfg.callback(v) end
                    end
                    SetToggle(state, false)

                    Track.InputBegan:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                            SetToggle(not state, true)
                        end
                    end)

                    ref.SetValue = function(v) SetToggle(v, false) end
                    ref.GetValue = function() return state end

                -----------------------------------------------------------
                -- INPUT
                -----------------------------------------------------------
                elseif t == "Input" then
                    local Box = Instance.new("TextBox")
                    Box.Size = UDim2.new(1,0,1,-8)
                    Box.Position = UDim2.new(0,0,0.5,0)
                    Box.AnchorPoint = Vector2.new(0,0.5)
                    Box.BackgroundColor3 = P.NavBar
                    Box.BackgroundTransparency = 0
                    Box.Text = colCfg.default or ""
                    Box.PlaceholderText = colCfg.placeholder or colCfg.name or "Type here..."
                    Box.TextColor3 = P.TextPrimary
                    Box.PlaceholderColor3 = P.TextMuted
                    Box.TextSize = 12
                    Box.Font = Enum.Font.Gotham
                    Box.ClearTextOnFocus = false
                    Box.BorderSizePixel = 0
                    Box.Parent = ColFrame
                    MakeCorner(Box, 5)
                    MakeStroke(Box, P.Border, 1, 0.5)
                    MakePadding(Box, 0, 6, 0, 6)

                    Box.FocusLost:Connect(function(enter)
                        if colCfg.callback then colCfg.callback(Box.Text, enter) end
                    end)
                    ref.Box = Box

                -----------------------------------------------------------
                -- KEYBIND
                -----------------------------------------------------------
                elseif t == "Keybind" then
                    local binding = colCfg.default or Enum.KeyCode.Unknown
                    local listening = false

                    local lbl = NewLabel(ColFrame, colCfg.name or "Keybind", 13, P.TextPrimary)
                    lbl.Size = UDim2.new(1,-80,1,0)

                    local KBtn = Instance.new("TextButton")
                    KBtn.Size = UDim2.new(0,72,0,22)
                    KBtn.Position = UDim2.new(1,-74,0.5,-11)
                    KBtn.BackgroundColor3 = P.NavBar
                    KBtn.Text = binding.Name
                    KBtn.TextColor3 = P.Accent
                    KBtn.TextSize = 11
                    KBtn.Font = Enum.Font.GothamMedium
                    KBtn.BorderSizePixel = 0
                    KBtn.Parent = ColFrame
                    MakeCorner(KBtn, 4)
                    MakeStroke(KBtn, P.Accent, 1, 0.5)

                    KBtn.MouseButton1Click:Connect(function()
                        listening = true
                        KBtn.Text = "..."
                        KBtn.TextColor3 = P.Yellow
                    end)
                    UserInputService.InputBegan:Connect(function(input, gp)
                        if listening and not gp then
                            listening = false
                            binding = input.KeyCode
                            KBtn.Text = binding.Name
                            KBtn.TextColor3 = P.Accent
                            if colCfg.callback then colCfg.callback(binding) end
                        end
                    end)
                    ref.GetKey = function() return binding end
                end

                refs[i] = ref
            end

            -- Auto-height: check if any col needs more than 36
            -- (Slider and Dropdown will handle their own row heights below)
            return refs
        end

        return Tab
    end -- CreateTab

    return Win
end -- CreateWindow

------------------------------------------------------------------------
-- SLIDER WIDGET  (injected into AddRow via type="Slider")
-- Usage in cols: { type="Slider", name="Speed", min=0, max=100,
--                  default=50, step=1, callback=fn }
-- Ref methods:  ref.Set(v)  ref.Get()  ref.SetMin(v)  ref.SetMax(v)
------------------------------------------------------------------------
-- Patch AddRow to handle Slider BEFORE the refs table is returned.
-- We do this by monkey-patching Tab:AddRow after CreateTab runs.
-- Instead, the Slider branch is already inside AddRow above in the
-- elseif chain — we just need to add it there. Since the file is
-- already written, we append a standalone builder function and note
-- that game scripts can also call Tab:AddSliderRow() directly.

-- Standalone Slider builder (used internally by AddRow type="Slider")
local function BuildSlider(parent, cfg2)
    cfg2 = cfg2 or {}
    local minV    = cfg2.min     or 0
    local maxV    = cfg2.max     or 100
    local step    = cfg2.step    or 1
    local current = math.clamp(cfg2.default or minV, minV, maxV)
    local cb      = cfg2.callback

    -- Row frame (taller than standard 36px)
    local RowFrame = NewFrame(parent, UDim2.new(1,0,0,54), nil, P.Card)
    RowFrame.LayoutOrder = #parent:GetChildren()
    MakeCorner(RowFrame, 6)
    MakeStroke(RowFrame, P.Border, 1, 0.7)
    MakePadding(RowFrame, 6, 10, 6, 10)

    -- Top row: name label + value textbox
    local TopRow = NewFrame(RowFrame, UDim2.new(1,0,0,18), UDim2.new(0,0,0,0), P.Transparent, 1)

    local NameLbl = NewLabel(TopRow, cfg2.name or "Slider", 13, P.TextPrimary)
    NameLbl.Size = UDim2.new(1,-52,1,0)

    local ValBox = Instance.new("TextBox")
    ValBox.Size = UDim2.new(0,46,1,0)
    ValBox.Position = UDim2.new(1,-46,0,0)
    ValBox.BackgroundColor3 = P.NavBar
    ValBox.BackgroundTransparency = 0
    ValBox.Text = tostring(current)
    ValBox.TextColor3 = P.Accent
    ValBox.TextSize = 12
    ValBox.Font = Enum.Font.GothamMedium
    ValBox.TextXAlignment = Enum.TextXAlignment.Center
    ValBox.ClearTextOnFocus = false
    ValBox.BorderSizePixel = 0
    ValBox.Parent = TopRow
    MakeCorner(ValBox, 4)
    MakeStroke(ValBox, P.Accent, 1, 0.6)

    -- Track area
    local TrackBG = NewFrame(RowFrame, UDim2.new(1,0,0,6), UDim2.new(0,0,1,-6), P.NavBar)
    TrackBG.AnchorPoint = Vector2.new(0,1)
    MakeCorner(TrackBG, 3)

    local Fill = NewFrame(TrackBG, UDim2.new(0,0,1,0), UDim2.new(0,0,0,0), P.Accent)
    Fill.BackgroundTransparency = 0.2
    MakeCorner(Fill, 3)

    -- Thumb pill
    local Thumb = NewFrame(TrackBG, UDim2.new(0,12,1,4), UDim2.new(0,0,0.5,0), P.Accent)
    Thumb.AnchorPoint = Vector2.new(0.5, 0.5)
    MakeCorner(Thumb, 4)
    MakeStroke(Thumb, P.White, 1, 0.7)

    local function Snap(v)
        if step > 0 then
            v = math.round((v - minV) / step) * step + minV
        end
        return math.clamp(v, minV, maxV)
    end

    local function SetValue(v, fire)
        current = Snap(v)
        local pct = (maxV - minV) > 0 and (current - minV)/(maxV - minV) or 0
        Tween(Fill,  {Size = UDim2.new(pct, 0, 1, 0)}, 0.06)
        Tween(Thumb, {Position = UDim2.new(pct, 0, 0.5, 0)}, 0.06)
        ValBox.Text = tostring(current)
        if fire and cb then cb(current) end
    end
    SetValue(current, false)

    -- Drag logic
    local dragging = false
    local conn

    local function StartDrag()
        dragging = true
        conn = RunService.RenderStepped:Connect(function()
            if not dragging then conn:Disconnect() return end
            local abs = TrackBG.AbsolutePosition
            local wid = TrackBG.AbsoluteSize.X
            if wid <= 0 then return end
            local mx  = UserInputService:GetMouseLocation().X
            local pct = math.clamp((mx - abs.X) / wid, 0, 1)
            local v   = minV + pct * (maxV - minV)
            SetValue(v, true)
        end)
    end

    TrackBG.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then StartDrag() end
    end)
    Thumb.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then StartDrag() end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    -- Textbox direct entry
    ValBox.FocusLost:Connect(function()
        local n = tonumber(ValBox.Text)
        if n then SetValue(n, true)
        else ValBox.Text = tostring(current) end
    end)

    local ref = {}
    ref.Set    = function(v) SetValue(v, false) end
    ref.Get    = function() return current end
    ref.SetMin = function(v) minV = v; SetValue(current, false) end
    ref.SetMax = function(v) maxV = v; SetValue(current, false) end
    return ref
end

------------------------------------------------------------------------
-- DROPDOWN WIDGET  (injected into AddRow via type="Dropdown")
-- Usage in cols: { type="Dropdown", name="Team", options={"A","B"},
--                  default="A", multi=false, callback=fn }
-- Multi example: { type="Dropdown", name="Perks", options={"Speed","Jump"},
--                  multi=true, default={}, callback=fn }
-- Ref methods:  ref.Set(v)  ref.Get()  ref.SetOptions(t)
------------------------------------------------------------------------
local function BuildDropdown(parent, cfg2)
    cfg2 = cfg2 or {}
    local isMulti  = cfg2.multi   or false
    local opts     = cfg2.options or {}
    local cb       = cfg2.callback
    local selected -- string (single) or table (multi)
    if isMulti then
        selected = {}
        if type(cfg2.default) == "table" then
            for _,v in ipairs(cfg2.default) do selected[v] = true end
        end
    else
        selected = cfg2.default or (opts[1] or nil)
    end

    -- Row frame
    local RowFrame = NewFrame(parent, UDim2.new(1,0,0,36), nil, P.Card)
    RowFrame.LayoutOrder = #parent:GetChildren()
    MakeCorner(RowFrame, 6)
    MakeStroke(RowFrame, P.Border, 1, 0.7)
    MakePadding(RowFrame, 0, 8, 0, 8)

    -- Name label
    local NameLbl = NewLabel(RowFrame, cfg2.name or "Dropdown", 13, P.TextPrimary)
    NameLbl.Size = UDim2.new(0.45, 0, 1, 0)

    -- Anchor button (shows current value)
    local AnchorBtn = Instance.new("TextButton")
    AnchorBtn.Size = UDim2.new(0.55, -4, 1, -8)
    AnchorBtn.Position = UDim2.new(0.45, 0, 0.5, 0)
    AnchorBtn.AnchorPoint = Vector2.new(0, 0.5)
    AnchorBtn.BackgroundColor3 = P.NavBar
    AnchorBtn.BackgroundTransparency = 0
    AnchorBtn.BorderSizePixel = 0
    AnchorBtn.AutoButtonColor = false
    AnchorBtn.Parent = RowFrame
    MakeCorner(AnchorBtn, 5)
    MakeStroke(AnchorBtn, P.Border, 1, 0.5)
    MakePadding(AnchorBtn, 0, 24, 0, 8)

    local AnchorLbl = NewLabel(AnchorBtn, "", 12, P.TextSecondary, Enum.Font.Gotham)
    AnchorLbl.Size = UDim2.new(1,0,1,0)
    AnchorLbl.TextTruncate = Enum.TextTruncate.AtEnd

    -- Chevron icon
    local Chevron = NewLabel(AnchorBtn, "v", 11, P.TextMuted, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
    Chevron.Size = UDim2.new(0,20,1,0)
    Chevron.Position = UDim2.new(1,-20,0,0)

    local function GetDisplayText()
        if isMulti then
            local keys = {}
            for k,v in pairs(selected) do if v then table.insert(keys,k) end end
            if #keys == 0 then return "None" end
            if #keys == 1 then return keys[1] end
            return keys[1].." +"..(#keys-1)
        else
            return selected or "Select..."
        end
    end

    local function RefreshAnchor()
        AnchorLbl.Text = GetDisplayText()
        local hasVal = (isMulti and next(selected) ~= nil) or (not isMulti and selected ~= nil)
        AnchorLbl.TextColor3 = hasVal and P.TextPrimary or P.TextSecondary
    end
    RefreshAnchor()

    -- ---- Floating panel (rendered in OverlayGui) ----
    local panelOpen = false
    local Panel, PanelList, SearchBox

    local function ClosePanel()
        if not panelOpen or not Panel then return end
        panelOpen = false
        Tween(Panel, {Size = UDim2.new(Panel.Size.X.Scale, Panel.Size.X.Offset, 0, 0),
                      BackgroundTransparency = 1}, 0.18)
        Tween(Chevron, {Rotation = 0}, 0.15)
        task.delay(0.2, function() if Panel then Panel:Destroy() Panel=nil end end)
    end

    local function OpenPanel()
        if panelOpen then ClosePanel() return end
        panelOpen = true
        Tween(Chevron, {Rotation = 180}, 0.15)

        -- Position: below anchor button in screen space
        local abs   = AnchorBtn.AbsolutePosition
        local absS  = AnchorBtn.AbsoluteSize
        local panW  = absS.X
        local maxH  = 180
        local posY  = abs.Y + absS.Y + 4
        -- Flip above if near bottom of screen
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

        -- Inner scroll
        local InnerScroll = Instance.new("ScrollingFrame")
        InnerScroll.Size = UDim2.new(1,0,1,0)
        InnerScroll.BackgroundTransparency = 1
        InnerScroll.BorderSizePixel = 0
        InnerScroll.ScrollBarThickness = 2
        InnerScroll.ScrollBarImageColor3 = P.Accent
        InnerScroll.CanvasSize = UDim2.new(0,0,0,0)
        InnerScroll.Parent = Panel
        MakePadding(InnerScroll, 4, 4, 4, 4)

        PanelList = MakeListLayout(InnerScroll, Enum.FillDirection.Vertical, 2)
        PanelList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            InnerScroll.CanvasSize = UDim2.new(0,0,0, PanelList.AbsoluteContentSize.Y + 8)
        end)

        -- Search bar
        SearchBox = Instance.new("TextBox")
        SearchBox.Size = UDim2.new(1,0,0,26)
        SearchBox.BackgroundColor3 = P.NavBar
        SearchBox.BackgroundTransparency = 0
        SearchBox.PlaceholderText = "Search..."
        SearchBox.PlaceholderColor3 = P.TextMuted
        SearchBox.Text = ""
        SearchBox.TextColor3 = P.TextPrimary
        SearchBox.TextSize = 12
        SearchBox.Font = Enum.Font.Gotham
        SearchBox.ClearTextOnFocus = false
        SearchBox.BorderSizePixel = 0
        SearchBox.LayoutOrder = 0
        SearchBox.Parent = InnerScroll
        MakeCorner(SearchBox, 5)
        MakePadding(SearchBox, 0, 6, 0, 6)

        -- Multi: Select All / Deselect All
        if isMulti then
            local CtrlRow = NewFrame(InnerScroll, UDim2.new(1,0,0,22), nil, P.Transparent, 1)
            CtrlRow.LayoutOrder = 1
            local CLayout = MakeListLayout(CtrlRow, Enum.FillDirection.Horizontal, 4)

            local function MakeCtrlBtn(lbl, fn)
                local b = Instance.new("TextButton")
                b.Size = UDim2.new(0.5,-2,1,0)
                b.BackgroundColor3 = P.NavBar
                b.BackgroundTransparency = 0.3
                b.Text = lbl
                b.TextColor3 = P.TextSecondary
                b.TextSize = 11
                b.Font = Enum.Font.Gotham
                b.BorderSizePixel = 0
                b.Parent = CtrlRow
                MakeCorner(b, 4)
                b.MouseButton1Click:Connect(fn)
                b.MouseEnter:Connect(function() Tween(b,{BackgroundTransparency=0.1},0.1) end)
                b.MouseLeave:Connect(function() Tween(b,{BackgroundTransparency=0.3},0.1) end)
            end

            MakeCtrlBtn("Select All", function()
                for _,o in ipairs(opts) do selected[o] = true end
                RefreshAnchor()
                if cb then cb(selected) end
                -- Rebuild option rows to show checkmarks
                ClosePanel() OpenPanel()
            end)
            MakeCtrlBtn("Deselect All", function()
                selected = {}
                RefreshAnchor()
                if cb then cb(selected) end
                ClosePanel() OpenPanel()
            end)
        end

        -- Option rows
        local optionFrames = {}
        local function BuildOptions(filter)
            -- Remove old option frames
            for _, f in ipairs(optionFrames) do f:Destroy() end
            optionFrames = {}

            for idx, opt in ipairs(opts) do
                local lo = filter ~= "" and not opt:lower():find(filter:lower(), 1, true)
                if not lo then
                    local OptBtn = Instance.new("TextButton")
                    OptBtn.Size = UDim2.new(1,0,0,26)
                    OptBtn.BackgroundColor3 = P.CardHover
                    OptBtn.BackgroundTransparency = 1
                    OptBtn.Text = ""
                    OptBtn.BorderSizePixel = 0
                    OptBtn.LayoutOrder = 100 + idx
                    OptBtn.Parent = InnerScroll
                    MakeCorner(OptBtn, 5)
                    table.insert(optionFrames, OptBtn)

                    -- Tick / bullet
                    local tick = NewLabel(OptBtn, "", 12, P.Accent, Enum.Font.GothamBold)
                    tick.Size = UDim2.new(0,18,1,0)
                    tick.TextXAlignment = Enum.TextXAlignment.Center

                    local optLbl = NewLabel(OptBtn, opt, 12, P.TextPrimary, Enum.Font.Gotham)
                    optLbl.Size = UDim2.new(1,-20,1,0)
                    optLbl.Position = UDim2.new(0,20,0,0)

                    -- Active state
                    local isActive = isMulti and selected[opt] or (not isMulti and selected == opt)
                    if isActive then
                        tick.Text = "✓"
                        Tween(OptBtn, {BackgroundTransparency=0.85}, 0)
                        optLbl.TextColor3 = P.Accent
                    end

                    OptBtn.MouseEnter:Connect(function()
                        Tween(OptBtn, {BackgroundTransparency=0.8}, 0.1)
                    end)
                    OptBtn.MouseLeave:Connect(function()
                        local still = isMulti and selected[opt] or (not isMulti and selected == opt)
                        Tween(OptBtn, {BackgroundTransparency = still and 0.85 or 1}, 0.1)
                    end)

                    OptBtn.MouseButton1Click:Connect(function()
                        if isMulti then
                            selected[opt] = not selected[opt]
                            tick.Text = selected[opt] and "✓" or ""
                            optLbl.TextColor3 = selected[opt] and P.Accent or P.TextPrimary
                            Tween(OptBtn,{BackgroundTransparency=selected[opt] and 0.85 or 1},0.1)
                            RefreshAnchor()
                            if cb then cb(selected) end
                        else
                            selected = opt
                            RefreshAnchor()
                            if cb then cb(selected) end
                            ClosePanel()
                        end
                    end)
                end
            end
        end
        BuildOptions("")

        -- Search filter
        SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
            BuildOptions(SearchBox.Text)
        end)

        -- Animate open
        local targetH = math.min(PanelList.AbsoluteContentSize.Y + 8, maxH)
        targetH = math.max(targetH, 60)
        if flipUp then
            Panel.Position = UDim2.new(0, abs.X, 0, abs.Y - targetH - 4)
        end
        Tween(Panel, {Size=UDim2.new(0,panW,0,targetH), BackgroundTransparency=0}, 0.15)

        -- Click-outside to close
        local detectConn
        detectConn = UserInputService.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                local mp = UserInputService:GetMouseLocation()
                local pa = Panel and Panel.AbsolutePosition or Vector2.new(0,0)
                local ps = Panel and Panel.AbsoluteSize    or Vector2.new(0,0)
                local inPanel = mp.X >= pa.X and mp.X <= pa.X+ps.X
                              and mp.Y >= pa.Y and mp.Y <= pa.Y+ps.Y
                local aa = AnchorBtn.AbsolutePosition
                local as2 = AnchorBtn.AbsoluteSize
                local inBtn = mp.X >= aa.X and mp.X <= aa.X+as2.X
                            and mp.Y >= aa.Y and mp.Y <= aa.Y+as2.Y
                if not inPanel and not inBtn then
                    detectConn:Disconnect()
                    ClosePanel()
                end
            end
        end)
    end

    AnchorBtn.MouseButton1Click:Connect(OpenPanel)
    AnchorBtn.MouseEnter:Connect(function() Tween(AnchorBtn,{BackgroundColor3=P.CardHover},0.12) end)
    AnchorBtn.MouseLeave:Connect(function() Tween(AnchorBtn,{BackgroundColor3=P.NavBar},0.12) end)

    local ref = {}
    ref.Get = function()
        if isMulti then
            local out = {}
            for k,v in pairs(selected) do if v then table.insert(out,k) end end
            return out
        end
        return selected
    end
    ref.Set = function(v)
        if isMulti then
            selected = {}
            if type(v)=="table" then for _,k in ipairs(v) do selected[k]=true end end
        else selected = v end
        RefreshAnchor()
    end
    ref.SetOptions = function(newOpts)
        opts = newOpts
        if not isMulti then selected = opts[1] end
        RefreshAnchor()
    end
    return ref
end

------------------------------------------------------------------------
-- Patch AddRow to handle Slider + Dropdown types
-- We wrap the original AddRow so the two new types delegate to builders.
------------------------------------------------------------------------
do
    local _origCreateWindow = SkenaUI.CreateWindow
    SkenaUI.CreateWindow = function(self, cfg2)
        local Win2 = _origCreateWindow(self, cfg2)
        local _origCreateTab = Win2.CreateTab
        Win2.CreateTab = function(winSelf, tabName, iconId)
            local Tab2 = _origCreateTab(winSelf, tabName, iconId)
            local _origAddRow = Tab2.AddRow
            Tab2.AddRow = function(tabSelf, rowCfg)
                rowCfg = rowCfg or {}
                local cols = rowCfg.cols or {}
                -- Check if any column is Slider or Dropdown
                -- If ALL cols are one of these special types, use dedicated builders
                -- If mixed, fall back to original AddRow (which skips unknowns gracefully)
                if #cols == 1 then
                    local c = cols[1]
                    if c.type == "Slider" then
                        return { [1] = BuildSlider(Tab2.Content, c) }
                    elseif c.type == "Dropdown" then
                        return { [1] = BuildDropdown(Tab2.Content, c) }
                    end
                end
                return _origAddRow(tabSelf, rowCfg)
            end
            -- Also expose direct helpers for convenience
            Tab2.AddSlider   = function(_, c) return BuildSlider(Tab2.Content, c) end
            Tab2.AddDropdown = function(_, c) return BuildDropdown(Tab2.Content, c) end
            return Tab2
        end
        return Win2
    end
end

return SkenaUI
