local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local FontBold = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
local FontSemiBold = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold)
local FontRegular = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular)
local FontLight = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Light)

-- // Anti-AFK (Global) // --
pcall(function()
    local VirtualUser = game:GetService("VirtualUser")
    Players.LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
    getgenv()._SKENA_ANTI_AFK = true
end)

-- // Security & Interception Hooks // --
local OriginalRequest = (request or http_request or (syn and syn.request))
local OriginalSetClipboard = setclipboard

-- // Remote Spy Setup // --
getgenv().SkenaHub_Spy_Hooks = getgenv().SkenaHub_Spy_Hooks or false
if not getgenv().SkenaHub_Spy_Hooks then
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if SkenaHub.Admin.IsSpying and (method == "FireServer" or method == "InvokeServer") then
            local args = {...}
            task.spawn(function()
                local log = string.format("[%s] %s:%s(...)\nArgs: %s", os.date("%X"), self:GetFullName(), method, SkenaHub.Core.Serialize(args, 1))
                table.insert(SkenaHub.Admin.SpyLogs, log)
            end)
        end
        return oldNamecall(self, ...)
    end)

    local dummyEvent = Instance.new("RemoteEvent")
    local oldFireServer
    oldFireServer = hookfunction(dummyEvent.FireServer, function(self, ...)
        if SkenaHub.Admin.IsSpying then
            local args = {...}
            task.spawn(function()
                local log = string.format("[%s] %s:FireServer(...)\nArgs: %s", os.date("%X"), self:GetFullName(), SkenaHub.Core.Serialize(args, 1))
                table.insert(SkenaHub.Admin.SpyLogs, log)
            end)
        end
        return oldFireServer(self, ...)
    end)
    getgenv().SkenaHub_Spy_Hooks = true
end

-- // UI Theme & Configuration // --
local Theme = {
    -- Backgrounds
    MainColor = Color3.fromRGB(33, 37, 43),    -- #21252b
    TopBarColor = Color3.fromRGB(40, 44, 52),   -- #282c34
    ElementColor = Color3.fromRGB(44, 49, 60),  -- #2c313c
    HoverColor = Color3.fromRGB(62, 68, 81),    -- #3e4451
    
    -- Borders
    BorderColor = Color3.fromRGB(62, 68, 81),   -- #3e4451
    BorderGlow = Color3.fromRGB(224, 108, 117), -- #e06c75
    
    -- Text
    TextPrimary = Color3.fromRGB(255, 255, 255), -- White
    TextMuted = Color3.fromRGB(200, 200, 200),   -- Light Grey
    TextSubtle = Color3.fromRGB(150, 150, 150),  -- Muted Grey
    
    -- Accents & Status
    AccentRed = Color3.fromRGB(224, 108, 117),  -- #e06c75
    StatusGreen = Color3.fromRGB(152, 195, 121),-- #98c379
    StatusYellow = Color3.fromRGB(229, 192, 123),-- #e5c07b
    StatusRed = Color3.fromRGB(224, 108, 117),  -- #e06c75
    StatusBlue = Color3.fromRGB(97, 175, 239),  -- #61afef
    
    -- Gradients (Topbar only)
    GradientStart = Color3.fromRGB(224, 108, 117), -- #e06c75
    GradientMid = Color3.fromRGB(198, 120, 221),   -- #c678dd
    GradientEnd = Color3.fromRGB(97, 175, 239),    -- #61afef

    -- Layout
    Margin = 15,
    SectionGap = 6,
    ElementHeight = 30,
    InnerCorner = UDim.new(0, 9),
    Gap = 9,
    SmallGap = 9,
    StrokeThickness = 1,

    -- Standardized Dimensions
    Dimensions = {
        PanelWidth = 393,
        PanelHeight = 410,
        PanelYOffset = 32,
        ToggleTrack = Vector2.new(36, 18),
        ToggleKnob = 12,
        PromptWidth = 300,
        PromptHeight = 160,
        IndicatorSize = 18,
        TabReserve = 150,
        GridSize = 36,
    }
}

-- Backward compatibility for logic
Theme.TextColor = Theme.TextPrimary
Theme.SubElementColor = Theme.MainColor
Theme.AccentColor = Theme.AccentRed -- Legacy fallback

Theme.OuterCorner = UDim.new(0, Theme.Margin + Theme.InnerCorner.Offset)
Theme.TopBarHeight = Theme.ElementHeight + Theme.Margin + Theme.Gap

Theme.Fonts = {
    Bold = FontBold,
    SemiBold = FontSemiBold,
    Regular = FontRegular,
    Light = FontLight
}

-- // Global Hub Initialization // --
getgenv().SkenaHub = getgenv().SkenaHub or {
    Config = {
        DevMode = true,
        BaseURL = ""
    },
    Core = {},
    State = {
        Movers = {},
        OriginalVolume = UserSettings():GetService("UserGameSettings").MasterVolume,
        FlightSpeed = 3,
        Noclip = false,
        Flight = false,
        Fling = false
    },
    Admin = {
        ESPConnection = nil,
        SpyLogs = {},
        IsSpying = false,
        InteractLogs = {},
        SafeMode = true -- Intercept HTTP/Clipboard by default
    }
}

local function getBrighterColor(color)
    local hue, sat, val = Color3.toHSV(color)
    return Color3.fromHSV(hue, math.clamp(sat - 0.2, 0, 1), math.clamp(val + 0.4, 0, 1))
end

local function getDarkerColor(color)
    local hue, sat, val = Color3.toHSV(color)
    return Color3.fromHSV(hue, sat, math.clamp(val - 0.3, 0, 1))
end

local Admins = {
    4871650676, 
    72548092,
    LocalPlayer.UserId
}

local GITHUB_URL = "https://raw.githubusercontent.com/kndrckm/key/refs/heads/main/"
local LOCAL_URL = "http://192.168.100.40:8000/test/"

if getgenv()._SKENA_DEV_MODE ~= nil then SkenaHub.Config.DevMode = getgenv()._SKENA_DEV_MODE end
SkenaHub.Config.BaseURL = SkenaHub.Config.DevMode and LOCAL_URL or GITHUB_URL

SkenaHub.Core.Load = function(fileName)
    local url = SkenaHub.Config.BaseURL .. fileName .. "?t=" .. os.time()
    local success, body = pcall(game.HttpGet, game, url, true)
    if success and body and #body > 0 then
        local func, err = loadstring(body)
        if func then return func() else warn("[SkenaHub] Syntax Error: " .. tostring(err)) end
    else
        warn("[SkenaHub] Gagal mengunduh: " .. fileName)
    end
end
getgenv().SkenaLoad = SkenaHub.Core.Load -- Support legacy scripts
getgenv()._SKENA_BASE_URL = SkenaHub.Config.BaseURL

local existingUI = CoreGui:FindFirstChild("SkenaTopNavUI")
if existingUI then existingUI:Destroy() end

-- // Globals &  Utils // --
local ESPContainer = Instance.new("Folder", CoreGui)
ESPContainer.Name = "SkenaESP"

RunService.Stepped:Connect(function()
    if SkenaHub.State.Noclip or SkenaHub.State.Fling then
        if LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if SkenaHub.State.Flight and LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then
        local primaryPart = LocalPlayer.Character.PrimaryPart
        local bodyVelocity, bodyGyro = unpack(SkenaHub.State.Movers)
        
        if not bodyVelocity then
            bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.MaxForce = Vector3.one * 9e9
            bodyGyro = Instance.new("BodyGyro")
            bodyGyro.MaxTorque = Vector3.one * 9e9
            bodyGyro.P = 9e4
            SkenaHub.State.Movers = {bodyVelocity, bodyGyro}
        end

        local camCFrame = Camera.CFrame
        local velocity = Vector3.zero
        local rotation = camCFrame.Rotation

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then velocity += camCFrame.LookVector; rotation *= CFrame.Angles(math.rad(-40), 0, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then velocity -= camCFrame.LookVector; rotation *= CFrame.Angles(math.rad(40), 0, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then velocity += camCFrame.RightVector; rotation *= CFrame.Angles(0, 0, math.rad(-40)) end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then velocity -= camCFrame.RightVector; rotation *= CFrame.Angles(0, 0, math.rad(40)) end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then velocity += Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then velocity -= Vector3.yAxis end

        TweenService:Create(bodyVelocity, TweenInfo.new(0.5), {Velocity = velocity * SkenaHub.State.FlightSpeed * 45}):Play()
        bodyVelocity.Parent = primaryPart
        if not SkenaHub.State.Fling then
            TweenService:Create(bodyGyro, TweenInfo.new(0.5), {CFrame = rotation}):Play()
            bodyGyro.Parent = primaryPart
        end
    else
        if SkenaHub.State.Movers[1] then SkenaHub.State.Movers[1].Parent = nil end
        if SkenaHub.State.Movers[2] then SkenaHub.State.Movers[2].Parent = nil end
    end
end)

local function UpdateESP(state)
    if state then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local hl = Instance.new("Highlight")
                hl.Name = player.Name
                hl.FillTransparency = 1
                hl.OutlineColor = Theme.TextColor
                hl.Parent = ESPContainer
                hl.Adornee = player.Character
            end
        end
    else
        ESPContainer:ClearAllChildren()
    end
end

-- // UI Library (Top Navigation) // --
local SkenaTopNav = {}

function SkenaTopNav:CreateWindow(titleText)
    local SkenaGui = Instance.new("ScreenGui")
    SkenaGui.Name = "SkenaTopNavUI"
    SkenaGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    SkenaGui.Parent = CoreGui
    SkenaGui.ResetOnSpawn = false

    local PanelWidth = Theme.Dimensions.PanelWidth
    local PanelHeight = Theme.Dimensions.PanelHeight
    local PanelYOffset = Theme.Dimensions.PanelYOffset

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, PanelWidth, 0, PanelHeight)
    MainFrame.AnchorPoint = Vector2.new(0, 0) 
    MainFrame.Position = UDim2.new(0, -PanelWidth - 24, 0, PanelYOffset) 
    MainFrame.BackgroundColor3 = Theme.MainColor
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = false
    MainFrame.Parent = SkenaGui
    Instance.new("UICorner", MainFrame).CornerRadius = Theme.OuterCorner

    -- // Toggle Logic // --
    local isPanelOpen = false
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, Theme.ElementHeight, 0, Theme.ElementHeight) 
    ToggleBtn.Position = UDim2.new(0, Theme.Margin, 0, PanelYOffset)
    ToggleBtn.AnchorPoint = Vector2.new(0, 0)
    ToggleBtn.BackgroundTransparency = 1 
    ToggleBtn.Text = ""
    ToggleBtn.Parent = SkenaGui

    local ToggleIcon = Instance.new("ImageLabel")
    ToggleIcon.Size = UDim2.new(0, 24, 0, 24)
    ToggleIcon.Position = UDim2.new(0.5, -12, 0.5, -12)
    ToggleIcon.BackgroundTransparency = 1
    ToggleIcon.Image = "rbxassetid://10709791437" -- chevron-right
    ToggleIcon.ImageColor3 = Theme.TextPrimary
    ToggleIcon.Rotation = 0
    ToggleIcon.Parent = ToggleBtn

    local function toggleUI()
        isPanelOpen = not isPanelOpen
        if isPanelOpen then
            TweenService:Create(ToggleIcon, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Rotation = -180}):Play()
            TweenService:Create(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0, Theme.Margin, 0, PanelYOffset)}):Play()
            TweenService:Create(ToggleBtn, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0, Theme.Margin + PanelWidth + Theme.Gap, 0, PanelYOffset)}):Play()
        else
            local t = TweenService:Create(ToggleIcon, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Rotation = -360})
            t:Play()
            t.Completed:Connect(function() if not isPanelOpen then ToggleIcon.Rotation = 0 end end)
            
            TweenService:Create(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0, -PanelWidth - (Theme.Margin * 2), 0, PanelYOffset)}):Play()
            TweenService:Create(ToggleBtn, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0, Theme.Margin, 0, PanelYOffset)}):Play()
        end
    end

    ToggleBtn.MouseButton1Click:Connect(toggleUI)

    -- // Security Prompt (Modal) // --
    local currentPrompt = nil
    function SkenaTopNav:CreatePrompt(titleText, descText, callback)
        if currentPrompt then currentPrompt:Destroy() end
        
        local Overlay = Instance.new("TextButton")
        Overlay.Size = UDim2.new(1, 40, 1, 40)
        Overlay.Position = UDim2.new(0, -20, 0, -20)
        Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Overlay.BackgroundTransparency = 1
        Overlay.Text = ""
        Overlay.AutoButtonColor = false
        Overlay.ZIndex = 100
        Overlay.Parent = MainFrame
        Instance.new("UICorner", Overlay).CornerRadius = Theme.OuterCorner
        
        local PromptFrame = Instance.new("Frame")
        PromptFrame.Size = UDim2.new(0, Theme.Dimensions.PromptWidth, 0, Theme.Dimensions.PromptHeight)
        PromptFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        PromptFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        PromptFrame.BackgroundColor3 = Theme.TopBarColor
        PromptFrame.BorderSizePixel = 0
        PromptFrame.ZIndex = 101
        PromptFrame.Parent = Overlay
        Instance.new("UICorner", PromptFrame).CornerRadius = Theme.InnerCorner
        Instance.new("UIStroke", PromptFrame).Color = Theme.AccentRed
        
        local PTitle = Instance.new("TextLabel")
        PTitle.Size = UDim2.new(1, -20, 0, 20)
        PTitle.Position = UDim2.new(0, 10, 0, 15)
        PTitle.BackgroundTransparency = 1
        PTitle.Text = titleText
        PTitle.TextColor3 = Theme.AccentRed
        PTitle.FontFace = Theme.Fonts.Bold
        PTitle.TextSize = 14
        PTitle.ZIndex = 102
        PTitle.Parent = PromptFrame
        
        local PDesc = Instance.new("TextLabel")
        PDesc.Size = UDim2.new(1, -30, 0, 60)
        PDesc.Position = UDim2.new(0, 15, 0, 40)
        PDesc.BackgroundTransparency = 1
        PDesc.Text = descText
        PDesc.TextColor3 = Theme.TextMuted
        PDesc.FontFace = Theme.Fonts.Regular
        PDesc.TextSize = 12
        PDesc.TextWrapped = true
        PDesc.ZIndex = 102
        PDesc.Parent = PromptFrame

        local ButtonContainer = Instance.new("Frame")
        ButtonContainer.Size = UDim2.new(1, -20, 0, 36)
        ButtonContainer.Position = UDim2.new(0, 10, 1, -46)
        ButtonContainer.BackgroundTransparency = 1
        ButtonContainer.ZIndex = 102
        ButtonContainer.Parent = PromptFrame
        
        local function createPromptBtn(text, color, pos)
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(0.48, 0, 1, 0)
            b.Position = pos
            b.BackgroundColor3 = color
            b.BackgroundTransparency = 0.8
            b.Text = text
            b.TextColor3 = color
            b.FontFace = Theme.Fonts.SemiBold
            b.TextSize = 13
            b.ZIndex = 103
            b.Parent = ButtonContainer
            Instance.new("UICorner", b).CornerRadius = Theme.InnerCorner
            Instance.new("UIStroke", b).Color = color
            
            b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.3), {BackgroundTransparency = 0.6}):Play() end)
            b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.3), {BackgroundTransparency = 0.8}):Play() end)
            return b
        end

        local AllowBtn = createPromptBtn("Allow", Theme.StatusGreen, UDim2.new(0, 0, 0, 0))
        local DenyBtn = createPromptBtn("Deny", Theme.StatusRed, UDim2.new(0.52, 0, 0, 0))
        
        TweenService:Create(Overlay, TweenInfo.new(0.4), {BackgroundTransparency = 0.4}):Play()
        PromptFrame.Size = UDim2.new(0, Theme.Dimensions.PromptWidth - 20, 0, Theme.Dimensions.PromptHeight - 20)
        TweenService:Create(PromptFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back), {Size = UDim2.new(0, Theme.Dimensions.PromptWidth, 0, Theme.Dimensions.PromptHeight)}):Play()
        
        currentPrompt = Overlay
        
        AllowBtn.MouseButton1Click:Connect(function()
            Overlay:Destroy()
            currentPrompt = nil
            callback(true)
        end)
        
        DenyBtn.MouseButton1Click:Connect(function()
            Overlay:Destroy()
            currentPrompt = nil
            callback(false)
        end)
    end

    -- // Global Intercept Logic // --
    if OriginalRequest then
        getgenv().request = function(options)
            if SkenaHub.Admin.SafeMode then
                local decision = nil
                SkenaTopNav:CreatePrompt("HTTP Request Detected", "A script is attempting to send data to:\n" .. (options.Url or "Unknown URL"), function(res)
                    decision = res
                end)
                repeat task.wait() until decision ~= nil
                if not decision then return {StatusCode = 403, Body = "Blocked by SkenaHub Safe Mode"} end
            end
            return OriginalRequest(options)
        end
        getgenv().http_request = getgenv().request
    end

    if OriginalSetClipboard then
        getgenv().setclipboard = function(data)
            if SkenaHub.Admin.SafeMode then
                local decision = nil
                local preview = #data > 50 and (string.sub(data, 1, 47) .. "...") or data
                SkenaTopNav:CreatePrompt("Clipboard Access", "A script is attempting to set your clipboard to:\n\"" .. preview .. "\"", function(res)
                    decision = res
                end)
                repeat task.wait() until decision ~= nil
                if not decision then return end
            end
            return OriginalSetClipboard(data)
        end
        getgenv().toclipboard = getgenv().setclipboard
    end

    -- // Top Bar // --
    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, Theme.TopBarHeight) 
    TopBar.BackgroundColor3 = Theme.TopBarColor
    TopBar.BorderSizePixel = 0
    TopBar.ClipsDescendants = false -- Allow filler to mask rounded corners
    TopBar.ZIndex = 1 -- Below the BodyFiller mask logic
    TopBar.Parent = MainFrame
    Instance.new("UICorner", TopBar).CornerRadius = Theme.OuterCorner
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(0, 150, 0, 16)
    Title.Position = UDim2.new(0, Theme.Margin + 3, 0, Theme.Margin) 
    Title.BackgroundTransparency = 1
    Title.Text = titleText
    Title.TextColor3 = Theme.AccentRed
    Title.FontFace = Theme.Fonts.Bold
    Title.TextSize = 15 
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.ZIndex = 10 
    Title.Parent = TopBar

    local SubTitle = Instance.new("TextLabel")
    SubTitle.Size = UDim2.new(0, 150, 0, 12)
    SubTitle.Position = UDim2.new(0, Theme.Margin + 3, 0, Theme.Margin + 16) 
    SubTitle.BackgroundTransparency = 1
    local gameName = "Unknown Game"
    pcall(function() gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name end)
    SubTitle.Text = gameName
    SubTitle.TextColor3 = Theme.TextMuted
    SubTitle.FontFace = Theme.Fonts.SemiBold
    SubTitle.TextSize = 9
    SubTitle.TextXAlignment = Enum.TextXAlignment.Left
    SubTitle.ZIndex = 10
    SubTitle.Parent = TopBar

    -- TopBar Corner Filler (Masks the bottom rounded corners)
    local BodyFiller = Instance.new("Frame")
    BodyFiller.Name = "BodyFiller"
    BodyFiller.Size = UDim2.new(1, 0, 0, Theme.OuterCorner.Offset)
    BodyFiller.Position = UDim2.new(0, 0, 1, -Theme.OuterCorner.Offset) 
    BodyFiller.BackgroundColor3 = Theme.TopBarColor
    BodyFiller.BackgroundTransparency = 0
    BodyFiller.BorderSizePixel = 0
    BodyFiller.ZIndex = 1 -- Sits just above TopBar background, below content
    BodyFiller.Parent = TopBar

    -- TopBar Accent Line (Seamless Animated)
    local AccentHolder = Instance.new("Frame")
    AccentHolder.Size = UDim2.new(1, 0, 0, 1.5)
    AccentHolder.Position = UDim2.new(0, 0, 1, -1.5)
    AccentHolder.BackgroundTransparency = 1
    AccentHolder.ClipsDescendants = true
    AccentHolder.ZIndex = 3
    AccentHolder.Parent = TopBar

    local AccentLine = Instance.new("Frame")
    AccentLine.Size = UDim2.new(2, 0, 1, 0)
    AccentLine.Position = UDim2.new(0, 0, 0, 0)
    AccentLine.BorderSizePixel = 0
    AccentLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    AccentLine.Parent = AccentHolder

    local AccentGradient = Instance.new("UIGradient")
    AccentGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Theme.GradientStart),
        ColorSequenceKeypoint.new(0.16, Theme.GradientMid),
        ColorSequenceKeypoint.new(0.33, Theme.GradientEnd),
        ColorSequenceKeypoint.new(0.5, Theme.GradientStart),
        ColorSequenceKeypoint.new(0.66, Theme.GradientMid),
        ColorSequenceKeypoint.new(0.83, Theme.GradientEnd),
        ColorSequenceKeypoint.new(1, Theme.GradientStart)
    }
    AccentGradient.Parent = AccentLine

    local flowPos = 0
    RunService.RenderStepped:Connect(function(dt)
        flowPos = flowPos - (dt * 0.15)
        if flowPos <= -1 then
            flowPos = 0
        end
        AccentLine.Position = UDim2.new(flowPos, 0, 0, 0)
    end)


    local TabContainer = Instance.new("Frame")
    local tabReserve = Theme.Dimensions.TabReserve
    TabContainer.Size = UDim2.new(1, -tabReserve, 0, Theme.ElementHeight)
    TabContainer.Position = UDim2.new(0, tabReserve, 0, Theme.Margin) 
    TabContainer.BackgroundTransparency = 1
    TabContainer.ClipsDescendants = false
    TabContainer.ZIndex = 5
    TabContainer.Parent = TopBar

    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.FillDirection = Enum.FillDirection.Horizontal
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding = UDim.new(0, Theme.Gap) 
    TabListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right 
    TabListLayout.Parent = TabContainer
    
    local RightPadding = Instance.new("UIPadding", TabContainer)
    RightPadding.PaddingRight = UDim.new(0, Theme.Gap + 8)

    local WindowPadding = Theme.Margin + Theme.StrokeThickness
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Size = UDim2.new(1, -(WindowPadding * 2), 1, -(Theme.TopBarHeight + Theme.Gap + Theme.Margin))
    ContentContainer.Position = UDim2.new(0, WindowPadding + 1, 0, Theme.TopBarHeight + Theme.Gap)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.ClipsDescendants = false -- Set to false to prevent stroke cropping
    ContentContainer.Parent = MainFrame

    local Window = { CurrentTab = nil, Tabs = {} }
    function Window:Toggle()
        toggleUI()
    end

    -- // Tab Creation // --
    function Window:CreateTab(tabName, iconId, tabColor, activeIconId)
        activeIconId = activeIconId or iconId
        local TabBtn = Instance.new("TextButton")
        TabBtn.Size = UDim2.new(0, Theme.ElementHeight, 0, Theme.ElementHeight)
        TabBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255) 
        TabBtn.BackgroundTransparency = 0.6 
        TabBtn.Text = ""
        TabBtn.AutoButtonColor = false
        TabBtn.Parent = TabContainer
        Instance.new("UICorner", TabBtn).CornerRadius = Theme.InnerCorner

        local BtnGradient = Instance.new("UIGradient")
        BtnGradient.Rotation = 50
        BtnGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, getDarkerColor(tabColor)),
            ColorSequenceKeypoint.new(1, tabColor)
        }
        BtnGradient.Parent = TabBtn

        local Stroke = Instance.new("UIStroke")
        Stroke.Thickness = 1.5
        Stroke.Transparency = 0.6 
        Stroke.Color = getBrighterColor(Theme.ElementColor)
        Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        Stroke.Parent = TabBtn

        local brightColor = getBrighterColor(tabColor)
        local StrokeGradient = Instance.new("UIGradient")
        StrokeGradient.Rotation = 50
        StrokeGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, tabColor),
            ColorSequenceKeypoint.new(1, brightColor) 
        }
        StrokeGradient.Parent = Stroke

        local Icon = Instance.new("ImageLabel")
        Icon.Name = "Icon"
        Icon.Size = UDim2.new(0, 20, 0, 20)
        Icon.Position = UDim2.new(0.5, -10, 0.5, -10)
        Icon.BackgroundTransparency = 1
        Icon.Image = "rbxassetid://" .. tostring(iconId)
        Icon.ImageTransparency = 0.5 
        Icon.Parent = TabBtn

        local TabPage = Instance.new("ScrollingFrame")
        TabPage.Size = UDim2.new(1, 0, 1, 0)
        TabPage.BackgroundTransparency = 1
        TabPage.ScrollBarThickness = 2
        TabPage.Visible = false
        TabPage.Parent = ContentContainer

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        PageLayout.Padding = UDim.new(0, Theme.Gap) 
        PageLayout.Parent = TabPage

        local PagePadding = Instance.new("UIPadding", TabPage)
        PagePadding.PaddingTop = UDim.new(0, 2)
        PagePadding.PaddingBottom = UDim.new(0, 4)
        PagePadding.PaddingLeft = UDim.new(0, 1)
        PagePadding.PaddingRight = UDim.new(0, 4)

        local tabData = { Page = TabPage, Btn = TabBtn, Stroke = Stroke, Icon = Icon, BtnGradient = BtnGradient, StrokeGradient = StrokeGradient, NormalIcon = iconId, ActiveIcon = activeIconId }
        table.insert(Window.Tabs, tabData)

        if not Window.CurrentTab then
            Window.CurrentTab = TabPage
            TabPage.Visible = true
            TabBtn.BackgroundTransparency = 0
            Stroke.Transparency = 0
            Icon.Image = "rbxassetid://" .. tostring(activeIconId)
            Icon.ImageTransparency = 0.02
        end

        TabBtn.MouseButton1Click:Connect(function()
            if TabPage.Visible then return end
            
            for _, t in pairs(Window.Tabs) do 
                t.Page.Visible = false 
                TweenService:Create(t.Btn, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.6}):Play()
                TweenService:Create(t.Stroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 0.6, Color = getBrighterColor(Theme.ElementColor)}):Play()
                TweenService:Create(t.Icon, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {ImageTransparency = 0.5}):Play()
                t.Icon.Image = "rbxassetid://" .. tostring(t.NormalIcon)
            end
            
            TabPage.Visible = true
            TweenService:Create(TabBtn, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
            TweenService:Create(Stroke, TweenInfo.new(0.3), {Transparency = 0, Color = Color3.fromRGB(255, 255, 255)}):Play()
            TweenService:Create(Icon, TweenInfo.new(0.3), {ImageTransparency = 0.02}):Play()
            Icon.Image = "rbxassetid://" .. tostring(activeIconId)

            TweenService:Create(TabBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Size = UDim2.new(0, Theme.ElementHeight - 2, 0, Theme.ElementHeight - 2)}):Play()
            task.wait(0.15)
            TweenService:Create(TabBtn, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size = UDim2.new(0, Theme.ElementHeight, 0, Theme.ElementHeight)}):Play()
        end)

        TabBtn.MouseEnter:Connect(function()
            if not TabPage.Visible then 
                TweenService:Create(TabBtn, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.2}):Play()
            end
            TweenService:Create(Stroke, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {Transparency = 0}):Play() 
            TweenService:Create(Icon, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {ImageTransparency = 0}):Play()
            
            TweenService:Create(BtnGradient, TweenInfo.new(1.4, Enum.EasingStyle.Quint), {Rotation = 360}):Play()
            TweenService:Create(StrokeGradient, TweenInfo.new(1.4, Enum.EasingStyle.Quint), {Rotation = 360}):Play()
            TweenService:Create(BtnGradient, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {Offset = Vector2.new(0,-0.5)}):Play()
        end)

        TabBtn.MouseLeave:Connect(function()
            if not TabPage.Visible then
                TweenService:Create(TabBtn, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.6}):Play()
                TweenService:Create(Stroke, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Transparency = 0.6}):Play() 
                TweenService:Create(Icon, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {ImageTransparency = 0.5}):Play()
            else
                TweenService:Create(Stroke, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Transparency = 0}):Play() 
            end
            
            TweenService:Create(StrokeGradient, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Rotation = 50}):Play()
            TweenService:Create(BtnGradient, TweenInfo.new(0.9, Enum.EasingStyle.Quint), {Rotation = 50}):Play()
            TweenService:Create(BtnGradient, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {Offset = Vector2.new(0,0)}):Play()
        end)

        local Elements = {}
        
        function Elements:CreateButton(text, callback, parent, customSize)
            local ParentFrame = parent or TabPage
            local Btn = Instance.new("TextButton")
            
            if customSize then
                Btn.Size = customSize
            elseif parent then
                Btn.Size = UDim2.new(1, 0, 1, 0) -- Fill the reserved subframe
            else
                Btn.Size = UDim2.new(1, 0, 0, Theme.ElementHeight)
            end
            
            Btn.BackgroundColor3 = Theme.ElementColor
            Btn.BackgroundTransparency = 0
            Btn.Text = "" 
            Btn.AutoButtonColor = false
            Btn.Parent = ParentFrame
            Instance.new("UICorner", Btn).CornerRadius = Theme.InnerCorner
            
            local Strk = Instance.new("UIStroke", Btn)
            Strk.Color = getBrighterColor(Theme.ElementColor)
            Strk.Transparency = 0
            Strk.Thickness = Theme.StrokeThickness
            Strk.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, 0, 1, 0)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = Theme.TextMuted
            Label.FontFace = Theme.Fonts.SemiBold
            Label.TextSize = 12
            Label.ZIndex = 2
            Label.Parent = Btn
            
            if parent then
                Label.TextWrapped = true
                Label.TextTruncate = Enum.TextTruncate.AtEnd
            end

            local isExecuting = false
            Btn.MouseButton1Click:Connect(function()
                if isExecuting then return end
                isExecuting = true
                
                local oldTxt = Label.Text
                local ok, result = pcall(callback)
                
                local feedbackText = "Success"
                local feedbackColor = Theme.StatusGreen
                
                if ok then
                    if typeof(result) == "string" then
                        feedbackText = result
                    elseif result == false then
                        feedbackText = "Failed"
                        feedbackColor = Theme.StatusRed
                    end
                else
                    feedbackText = "Failed"
                    feedbackColor = Theme.StatusRed
                end

                Label.Text = feedbackText
                Label.TextColor3 = Theme.TextPrimary
                
                local feedbackGradient = Instance.new("UIGradient")
                feedbackGradient.Rotation = 45
                feedbackGradient.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, getBrighterColor(feedbackColor)),
                    ColorSequenceKeypoint.new(1, feedbackColor)
                }
                feedbackGradient.Parent = Btn
                
                local flash = TweenService:Create(Btn, TweenInfo.new(0.3, Enum.EasingStyle.Back), {BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.5})
                local strokeFlash = TweenService:Create(Strk, TweenInfo.new(0.3), {Color = getDarkerColor(feedbackColor)})
                flash:Play()
                strokeFlash:Play()
                
                task.delay(1.5, function()
                    Label.Text = oldTxt
                    Label.TextColor3 = Theme.TextMuted
                    local reset = TweenService:Create(Btn, TweenInfo.new(0.6), {BackgroundColor3 = Theme.ElementColor, BackgroundTransparency = 0})
                    local strokeReset = TweenService:Create(Strk, TweenInfo.new(0.6), {Color = getBrighterColor(Theme.ElementColor)})
                    reset:Play()
                    strokeReset:Play()
                    reset.Completed:Connect(function()
                        feedbackGradient:Destroy()
                    end)
                    isExecuting = false
                end)
            end)

            Btn.MouseEnter:Connect(function()
                if not isExecuting then
                    TweenService:Create(Btn, TweenInfo.new(0.3), {BackgroundColor3 = Theme.HoverColor}):Play()
                    TweenService:Create(Strk, TweenInfo.new(0.3), {Color = Theme.BorderGlow}):Play()
                    TweenService:Create(Label, TweenInfo.new(0.3), {TextColor3 = Theme.TextPrimary}):Play()
                end
            end)
            Btn.MouseLeave:Connect(function()
                if not isExecuting then
                    TweenService:Create(Btn, TweenInfo.new(0.3), {BackgroundColor3 = Theme.ElementColor}):Play()
                    TweenService:Create(Strk, TweenInfo.new(0.3), {Color = getBrighterColor(Theme.ElementColor)}):Play()
                    TweenService:Create(Label, TweenInfo.new(0.3), {TextColor3 = Theme.TextMuted}):Play()
                end
            end)

            TabPage.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + Theme.SmallGap)
        end
        function Elements:CreateToggle(callback_or_text, default_or_callback, parent_or_default)
            local isModular = typeof(parent_or_default) == "Instance"
            local text = isModular and "" or callback_or_text
            local callback = isModular and callback_or_text or default_or_callback
            local default = isModular and default_or_callback or parent_or_default or false
            local ParentFrame = isModular and parent_or_default or TabPage

            local ToggleFrame = Instance.new("Frame")
            ToggleFrame.Size = UDim2.new(1, 0, 0, isModular and ParentFrame.AbsoluteSize.Y or Theme.ElementHeight)
            ToggleFrame.BackgroundTransparency = 1
            ToggleFrame.Parent = ParentFrame
            
                local Label = Instance.new("TextLabel")
                Label.Size = UDim2.new(1, -54, 1, 0)
                Label.Position = UDim2.new(0, Theme.Gap, 0, 0)
                Label.BackgroundTransparency = 1
                Label.Text = text
                Label.TextColor3 = Theme.TextPrimary
                Label.FontFace = Theme.Fonts.Bold
                Label.TextSize = 12
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.Parent = ToggleFrame

            local toggled = default
            local TrackSize = Theme.Dimensions.ToggleTrack
            local KnobSize = Theme.Dimensions.ToggleKnob

            local Track = Instance.new("TextButton")
            Track.Size = UDim2.new(0, TrackSize.X, 0, TrackSize.Y)
            Track.Position = isModular and UDim2.new(0, 0, 0.5, -TrackSize.Y/2) or UDim2.new(1, -TrackSize.X - Theme.Gap, 0.5, -TrackSize.Y/2)
            Track.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Track.Text = ""
            Track.AutoButtonColor = false
            Track.Parent = ToggleFrame
            Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)
            
            local TrackGradient = Instance.new("UIGradient", Track)
            TrackGradient.Rotation = 90
            
            local TrackStroke = Instance.new("UIStroke", Track)
            TrackStroke.Color = Theme.BorderColor
            TrackStroke.Thickness = Theme.StrokeThickness
            TrackStroke.Transparency = 0.5

            local function updateVisuals(isOn)
                if isOn then
                    TrackGradient.Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Theme.StatusGreen),
                        ColorSequenceKeypoint.new(1, getDarkerColor(Theme.StatusGreen))
                    }
                    TrackStroke.Color = getBrighterColor(Theme.StatusGreen)
                    TrackStroke.Transparency = 0
                else
                    TrackGradient.Color = ColorSequence.new(Theme.TopBarColor)
                    TrackStroke.Color = Theme.BorderColor
                    TrackStroke.Transparency = 0.5
                end
            end
            updateVisuals(toggled)

            local Knob = Instance.new("Frame")
            Knob.Size = UDim2.new(0, KnobSize, 0, KnobSize)
            Knob.Position = toggled and UDim2.new(1, -KnobSize - 3, 0.5, -KnobSize/2) or UDim2.new(0, 3, 0.5, -KnobSize/2)
            Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Knob.Parent = Track
            Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

            Track.MouseButton1Click:Connect(function()
                toggled = not toggled
                local targetPos = toggled and UDim2.new(1, -KnobSize - 3, 0.5, -KnobSize/2) or UDim2.new(0, 3, 0.5, -KnobSize/2)
                TweenService:Create(Knob, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Position = targetPos}):Play()
                updateVisuals(toggled)
                callback(toggled)
            end)
            
            TabPage.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + Theme.Gap)
        end
        function Elements:CreateTextBox(text, title, placeholder, callback, parent)
            local ParentFrame = parent or TabPage
            local BoxFrame = Instance.new("Frame")
            
            if parent then
                 BoxFrame.Size = UDim2.new(1, 0, 1, 0)
            else
                 BoxFrame.Size = UDim2.new(1, 0, 0, Theme.ElementHeight)
            end
            
            BoxFrame.BackgroundTransparency = 1
            BoxFrame.Parent = ParentFrame
            
            local Label
            if title and title ~= "" then
                Label = Instance.new("TextLabel")
                Label.Size = UDim2.new(1, -44, 1, 0)
                Label.Position = UDim2.new(0, 0, 0, 0)
                Label.BackgroundTransparency = 1
                Label.Text = title
                Label.TextColor3 = Theme.TextPrimary
                Label.FontFace = Theme.Fonts.Bold
                Label.TextSize = 12
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.Parent = BoxFrame
            end

            local InputContainer = Instance.new("Frame")
            local inputHeight = Theme.Dimensions.ToggleTrack.Y
            InputContainer.Size = Label and UDim2.new(0, 36, 0, inputHeight) or UDim2.new(1, 0, 1, 0)
            InputContainer.Position = Label and UDim2.new(1, -36, 0.5, -inputHeight/2) or UDim2.new(0, 0, 0.5, -inputHeight/2)
            if not Label then InputContainer.Size = UDim2.new(1, 0, 0, inputHeight) end
            InputContainer.BackgroundColor3 = Theme.ElementColor
            InputContainer.Parent = BoxFrame
            Instance.new("UICorner", InputContainer).CornerRadius = UDim.new(0, 4)
            
            local Strk = Instance.new("UIStroke", InputContainer)
            Strk.Color = getBrighterColor(Theme.ElementColor)
            Strk.Transparency = 0.5
            Strk.Thickness = 1
            Strk.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

            local Input = Instance.new("TextBox")
            Input.Size = UDim2.new(1, 0, 1, 0)
            Input.BackgroundTransparency = 1
            Input.Text = text
            Input.PlaceholderText = placeholder
            Input.TextColor3 = Theme.TextPrimary
            Input.PlaceholderColor3 = Theme.TextSubtle
            Input.FontFace = Theme.Fonts.SemiBold
            Input.TextSize = 11
            Input.TextXAlignment = Enum.TextXAlignment.Center
            Input.Parent = InputContainer
            Input.FocusLost:Connect(function(enter)
                callback(Input.Text, enter)
            end)

            Input.MouseEnter:Connect(function()
                TweenService:Create(InputContainer, TweenInfo.new(0.3), {BackgroundColor3 = Theme.HoverColor}):Play()
                TweenService:Create(Strk, TweenInfo.new(0.3), {Color = Theme.BorderGlow, Transparency = 0}):Play()
            end)
            Input.MouseLeave:Connect(function()
                TweenService:Create(InputContainer, TweenInfo.new(0.3), {BackgroundColor3 = Theme.ElementColor}):Play()
                TweenService:Create(Strk, TweenInfo.new(0.3), {Color = getBrighterColor(Theme.ElementColor), Transparency = 0.5}):Play()
            end)

            TabPage.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + Theme.SmallGap)
        end

        function Elements:CreateRow(count, height)
            count = count or 2
            height = height or Theme.ElementHeight
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, height)
            Row.BackgroundTransparency = 1
            Row.Parent = TabPage
            
            local List = Instance.new("UIListLayout", Row)
            List.FillDirection = Enum.FillDirection.Horizontal
            List.Padding = UDim.new(0, Theme.Gap)
            List.SortOrder = Enum.SortOrder.LayoutOrder
            
            local subFrames = {}
            local itemWidth = (1 / count)
            local totalGap = Theme.Gap * (count - 1)
            local offset = totalGap / count

            for i = 1, count do
                local sf = Instance.new("Frame")
                sf.Size = UDim2.new(itemWidth, -offset, 1, 0)
                sf.BackgroundTransparency = 1
                sf.Parent = Row
                table.insert(subFrames, sf)
            end
            
            TabPage.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + Theme.SmallGap)
            return table.unpack(subFrames)
        end
        function Elements:CreateLabel(text, parent)
            local ParentFrame = parent or TabPage
            local Label = Instance.new("TextLabel")
            Label.Size = parent and UDim2.new(1, 0, 1, 0) or UDim2.new(1, 0, 0, 15)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = Theme.TextPrimary
            Label.FontFace = Theme.Fonts.Bold
            Label.TextSize = 12
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = ParentFrame
            return Label
        end

        function Elements:CreateGap(size)
            local G = Instance.new("Frame", TabPage)
            G.Size = UDim2.new(1, 0, 0, size or Theme.Gap)
            G.BackgroundTransparency = 1
        end

        function Elements:CreateSection(text)
            local isFirst = #TabPage:GetChildren() <= 2 -- Only Layout and Padding exist initially
            if not isFirst then
                Elements:CreateGap(9)
            end
            local L = Elements:CreateLabel(text)
            L.TextColor3 = Theme.TextPrimary
            L.FontFace = Theme.Fonts.Bold
            L.TextSize = 12
            L.TextTransparency = 0.1
            Elements:CreateGap(-5)
        end

        function Elements:CreateSlider(name, color, min, max, def, callback)
            local SliderBg = Instance.new("Frame")
            SliderBg.Size = UDim2.new(1, 0, 0, Theme.ElementHeight)
            SliderBg.BackgroundColor3 = color
            SliderBg.BackgroundTransparency = 0.85
            SliderBg.Parent = TabPage
            Instance.new("UICorner", SliderBg).CornerRadius = Theme.InnerCorner
            
            local Shadow = Instance.new("ImageLabel")
            Shadow.Name = "Shadow"
            Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
            Shadow.BackgroundTransparency = 1
            Shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
            Shadow.Size = UDim2.new(1, 10, 1, 10)
            Shadow.Image = "rbxassetid://6014261734"
            Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
            Shadow.ImageTransparency = 0.6
            Shadow.Parent = SliderBg

            local Strk = Instance.new("UIStroke", SliderBg)
            Strk.Color = getBrighterColor(color)
            Strk.Transparency = 0.2
            Strk.Thickness = Theme.StrokeThickness
            Strk.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new((def - min) / (max - min), 0, 1, 0)
            Fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Fill.BackgroundTransparency = 0
            Fill.Parent = SliderBg
            Instance.new("UICorner", Fill).CornerRadius = Theme.InnerCorner

            local FillGradient = Instance.new("UIGradient")
            FillGradient.Rotation = 90
            FillGradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, color),
                ColorSequenceKeypoint.new(1, getDarkerColor(color))
            }
            FillGradient.Parent = Fill

            local Info = Instance.new("TextLabel")
            Info.Size = UDim2.new(1, -24, 1, 0)
            Info.Position = UDim2.new(0, Theme.Gap, 0, 0)
            Info.BackgroundTransparency = 1
            Info.Text = def .. " " .. name
            Info.TextColor3 = Theme.TextPrimary
            Info.TextTransparency = 0.4
            Info.FontFace = Theme.Fonts.Bold
            Info.TextSize = 14
            Info.TextXAlignment = Enum.TextXAlignment.Left
            Info.Parent = SliderBg

            local Hitbox = Instance.new("TextButton")
            Hitbox.Size = UDim2.new(1, 0, 1, 0)
            Hitbox.BackgroundTransparency = 1
            Hitbox.Text = ""
            Hitbox.Parent = SliderBg

            local data = {Fill = Fill, Info = Info, Min = min, Max = max, Def = def, Name = name, Callback = callback}

            local dragging = false
            Hitbox.MouseButton1Down:Connect(function() dragging = true end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local percent = math.clamp((UserInputService:GetMouseLocation().X - SliderBg.AbsolutePosition.X) / SliderBg.AbsoluteSize.X, 0, 1)
                    TweenService:Create(Fill, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Size = UDim2.new(percent, 0, 1, 0)}):Play()
                    local val = math.floor(min + (max - min) * percent)
                    Info.Text = val .. " " .. name
                    callback(val)
                end
            end)

            Hitbox.MouseEnter:Connect(function()
                TweenService:Create(SliderBg, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.8, BackgroundColor3 = getDarkerColor(color)}):Play()
                TweenService:Create(Strk, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {Transparency = 0}):Play()
                TweenService:Create(Info, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
            end)
            Hitbox.MouseLeave:Connect(function()
                TweenService:Create(SliderBg, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.85, BackgroundColor3 = color}):Play()
                TweenService:Create(Strk, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 0.2}):Play()
                TweenService:Create(Info, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 0.4}):Play()
            end)

            TabPage.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + Theme.Gap)
            return data
        end
        function Elements:CreateDropdown(name, options, callback, parent)
            local ParentFrame = parent or TabPage
            local isModular = parent ~= nil
            
            local DropFrame = Instance.new("Frame")
            DropFrame.Size = UDim2.new(1, 0, 0, Theme.ElementHeight)
            DropFrame.BackgroundColor3 = Theme.ElementColor
            DropFrame.Parent = ParentFrame
            Instance.new("UICorner", DropFrame).CornerRadius = Theme.InnerCorner
            
            local Strk = Instance.new("UIStroke", DropFrame)
            Strk.Color = getBrighterColor(Theme.ElementColor)
            Strk.Thickness = Theme.StrokeThickness
            Strk.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -30, 1, 0)
            Label.Position = UDim2.new(0, Theme.Gap, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = name
            Label.TextColor3 = Theme.TextMuted
            Label.FontFace = Theme.Fonts.SemiBold
            Label.TextSize = 12
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = DropFrame

            local Arrow = Instance.new("ImageLabel")
            Arrow.Size = UDim2.new(0, 16, 0, 16)
            Arrow.Position = UDim2.new(1, -24, 0.5, -8)
            Arrow.BackgroundTransparency = 1
            Arrow.Image = "rbxassetid://10709795175"
            Arrow.ImageColor3 = Theme.TextSubtle
            Arrow.Parent = DropFrame

            local Content = Instance.new("ScrollingFrame")
            Content.Size = UDim2.new(1, 0, 0, 0)
            Content.Position = UDim2.new(0, 0, 1, 0)
            Content.BackgroundTransparency = 1
            Content.ScrollBarThickness = 2
            Content.Visible = false
            Content.ClipsDescendants = true
            Content.Parent = DropFrame
            
            local ContentLayout = Instance.new("UIListLayout", Content)
            ContentLayout.Padding = UDim.new(0, 2)

            local expanded = false
            local function toggle(state)
                expanded = state
                Content.Visible = true
                local targetSize = expanded and 120 or 0
                TweenService:Create(Content, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, targetSize)}):Play()
                TweenService:Create(Arrow, TweenInfo.new(0.4), {Rotation = expanded and 180 or 0}):Play()
                
                if not expanded then
                    task.delay(0.4, function() if not expanded then Content.Visible = false end end)
                end
                
                -- Update Tab Canvas
                task.wait(0.45)
                TabPage.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + Theme.Gap)
            end

            local Hitbox = Instance.new("TextButton")
            Hitbox.Size = UDim2.new(1, 0, 1, 0)
            Hitbox.BackgroundTransparency = 1
            Hitbox.Text = ""
            Hitbox.Parent = DropFrame
            Hitbox.MouseButton1Click:Connect(function() toggle(not expanded) end)

            local drop = {Options = {}}
            function drop:AddItem(txt, isDefault)
                local Opt = Instance.new("TextButton")
                Opt.Size = UDim2.new(1, -4, 0, 26)
                Opt.BackgroundColor3 = Theme.TopBarColor
                Opt.BackgroundTransparency = 0.5
                Opt.Text = txt
                Opt.TextColor3 = Theme.TextMuted
                Opt.FontFace = Theme.Fonts.SemiBold
                Opt.TextSize = 11
                Opt.Parent = Content
                Instance.new("UICorner", Opt).CornerRadius = UDim.new(0, 4)
                
                Opt.MouseButton1Click:Connect(function()
                    Label.Text = txt
                    callback(txt)
                    toggle(false)
                end)
                
                Opt.MouseEnter:Connect(function() TweenService:Create(Opt, TweenInfo.new(0.2), {BackgroundTransparency = 0, TextColor3 = Theme.TextPrimary}):Play() end)
                Opt.MouseLeave:Connect(function() TweenService:Create(Opt, TweenInfo.new(0.2), {BackgroundTransparency = 0.5, TextColor3 = Theme.TextMuted}):Play() end)
                
                if isDefault then Label.Text = txt end
                Content.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y)
            end

            for _, opt in ipairs(options or {}) do drop:AddItem(opt) end
            
            TabPage.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + Theme.Gap)
            return drop
        end

        function Elements:CreateCircleButton(text, callback, parent, transparent)
            local ParentFrame = parent or TabPage
            local btnSize = Theme.Dimensions.IndicatorSize + 6 
            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(0, btnSize, 0, btnSize)
            Btn.Position = UDim2.new(0.5, -btnSize/2, 0.5, -btnSize/2)
            Btn.BackgroundColor3 = Theme.ElementColor
            Btn.BackgroundTransparency = transparent and 1 or 0
            Btn.AutoButtonColor = false
            Btn.Text = ""
            Btn.Parent = ParentFrame
            Instance.new("UICorner", Btn).CornerRadius = UDim.new(1, 0)
            
            local Strk = Instance.new("UIStroke", Btn)
            Strk.Color = getBrighterColor(Theme.ElementColor)
            Strk.Thickness = 1
            Strk.Transparency = transparent and 1 or 0.5

            local isIcon = string.match(tostring(text), "rbxassetid://")
            local Content
            if isIcon then
                Content = Instance.new("ImageLabel")
                Content.Size = UDim2.new(0, 20, 0, 20)
                Content.Position = UDim2.new(0.5, -10, 0.5, -10)
                Content.BackgroundTransparency = 1
                Content.Image = text
                Content.ImageColor3 = Theme.TextPrimary
                Content.ImageTransparency = 0.3
            else
                Content = Instance.new("TextLabel")
                Content.Size = UDim2.new(1, 0, 1, 0)
                Content.BackgroundTransparency = 1
                Content.Text = text
                Content.TextColor3 = Theme.TextPrimary
                Content.FontFace = Theme.Fonts.SemiBold
                Content.TextSize = 14
            end
            Content.Parent = Btn
            
            Btn.MouseButton1Click:Connect(callback)
            
            Btn.MouseEnter:Connect(function()
                if not transparent then TweenService:Create(Btn, TweenInfo.new(0.3), {BackgroundColor3 = Theme.HoverColor}):Play() end
                if not transparent then TweenService:Create(Strk, TweenInfo.new(0.3), {Color = Theme.BorderGlow, Transparency = 0}):Play() end
                if isIcon then TweenService:Create(Content, TweenInfo.new(0.3), {ImageTransparency = 0}):Play() else TweenService:Create(Content, TweenInfo.new(0.3), {TextTransparency = 0}):Play() end
            end)
            Btn.MouseLeave:Connect(function()
                if not transparent then TweenService:Create(Btn, TweenInfo.new(0.3), {BackgroundColor3 = Theme.ElementColor}):Play() end
                if not transparent then TweenService:Create(Strk, TweenInfo.new(0.3), {Color = getBrighterColor(Theme.ElementColor), Transparency = 0.5}):Play() end
                if isIcon then TweenService:Create(Content, TweenInfo.new(0.3), {ImageTransparency = 0.3}):Play() else TweenService:Create(Content, TweenInfo.new(0.3), {TextTransparency = 0}):Play() end
            end)
        end
        task.spawn(function()
            task.wait(0.2)
            toggleUI()
        end)
        return Elements, TabPage, PageLayout
    end
    return Window
end

-- // Initialize UI // --
local Window = SkenaTopNav:CreateWindow("SkenaHub")
SkenaHub.UI = Window -- Expose to game scripts

-- // Tab 1: General (Red) // --
local GeneralElements, GeneralPage, GeneralLayout = Window:CreateTab("General Tab", 10723407389, Color3.fromRGB(200, 70, 70), 10723407389)

local PropsCard = Instance.new("Frame")
PropsCard.Size = UDim2.new(1, 0, 0, 240)
PropsCard.BackgroundTransparency = 1 
PropsCard.Parent = GeneralPage

local PropsTitle = Instance.new("TextLabel")
PropsTitle.Size = UDim2.new(1, 0, 0, Theme.ElementHeight) -- Changed to full width
PropsTitle.Position = UDim2.new(0, 0, 0, 0)
PropsTitle.BackgroundTransparency = 1
PropsTitle.Text = "PLAYER PROPERTIES"
PropsTitle.TextColor3 = Theme.TextPrimary
PropsTitle.FontFace = Theme.Fonts.Bold
PropsTitle.TextSize = 12
PropsTitle.TextXAlignment = Enum.TextXAlignment.Left
PropsTitle.Parent = PropsCard

local ResetBtn = Instance.new("ImageButton")
local indicatorSize = Theme.Dimensions.IndicatorSize
ResetBtn.Size = UDim2.new(0, indicatorSize, 0, indicatorSize)
ResetBtn.Position = UDim2.new(1, -indicatorSize - 6, 0.5, -indicatorSize/2)
ResetBtn.BackgroundTransparency = 1
ResetBtn.Image = "rbxassetid://9134761478"
ResetBtn.ImageTransparency = 0.5
ResetBtn.Parent = PropsTitle

local SlidersContainer = Instance.new("Frame")
SlidersContainer.Size = UDim2.new(1, 0, 1, -42)
SlidersContainer.Position = UDim2.new(0, 0, 0, Theme.ElementHeight)
SlidersContainer.BackgroundTransparency = 1
SlidersContainer.Parent = PropsCard
local SlidersLayout = Instance.new("UIListLayout", SlidersContainer)
SlidersLayout.Padding = UDim.new(0, Theme.Gap)

local Sliders = {}
local WalkSliderData = GeneralElements:CreateSlider("walk speed", Color3.fromRGB(61, 164, 165), 0, 300, 16, function(v)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.WalkSpeed = v end
end)
WalkSliderData.Fill.Parent.Parent = SlidersContainer -- Reparent to organized container
table.insert(Sliders, WalkSliderData)

local Speedometer = Instance.new("TextLabel")
Speedometer.Size = UDim2.new(0, 60, 1, 0)
Speedometer.Position = UDim2.new(1, -66, 0, 0)
Speedometer.BackgroundTransparency = 1
Speedometer.Text = "0.0"
Speedometer.TextColor3 = Theme.TextPrimary
Speedometer.TextTransparency = 0.4
Speedometer.FontFace = Theme.Fonts.Bold
Speedometer.TextSize = 13
Speedometer.TextXAlignment = Enum.TextXAlignment.Right
Speedometer.Parent = WalkSliderData.Fill.Parent

RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and Speedometer and Speedometer.Parent then
        local vel = hrp.Velocity * Vector3.new(1, 0, 1)
        Speedometer.Text = string.format("%.1f", vel.Magnitude)
    end
end)

local JumpData = GeneralElements:CreateSlider("jump power", Color3.fromRGB(59, 126, 184), 0, 350, 50, function(v)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.UseJumpPower = true; LocalPlayer.Character.Humanoid.JumpPower = v end
end)
JumpData.Fill.Parent.Parent = SlidersContainer
table.insert(Sliders, JumpData)

local FlightData = GeneralElements:CreateSlider("flight speed", Color3.fromRGB(177, 45, 45), 1, 25, 3, function(v) SkenaHub.State.FlightSpeed = v end)
FlightData.Fill.Parent.Parent = SlidersContainer
table.insert(Sliders, FlightData)

local FovData = GeneralElements:CreateSlider("field of view", Color3.fromRGB(198, 178, 75), 45, 120, 70, function(v)
    TweenService:Create(Camera, TweenInfo.new(0.6), {FieldOfView = v}):Play()
end)
FovData.Fill.Parent.Parent = SlidersContainer
table.insert(Sliders, FovData)

PropsCard.Size = UDim2.new(1, 0, 0, Theme.ElementHeight + ((Theme.ElementHeight + Theme.Gap) * 4))

ResetBtn.MouseButton1Click:Connect(function()
    TweenService:Create(ResetBtn, TweenInfo.new(0.5), {Rotation = 360}):Play()
    for _, sl in pairs(Sliders) do
        TweenService:Create(sl.Fill, TweenInfo.new(0.5), {Size = UDim2.new((sl.Def - sl.Min) / (sl.Max - sl.Min), 0, 1, 0)}):Play()
        sl.Info.Text = sl.Def .. " " .. sl.Name
        sl.Callback(sl.Def)
    end
    task.wait(0.5)
    ResetBtn.Rotation = 0
end)


-- // Player Actions Container // --
local ActionsCard = Instance.new("Frame")
ActionsCard.Size = UDim2.new(1, 0, 0, 200)
ActionsCard.BackgroundTransparency = 1 
ActionsCard.Parent = GeneralPage

local ActionsTitle = Instance.new("TextLabel")
ActionsTitle.Size = UDim2.new(1, -42, 0, Theme.ElementHeight)
ActionsTitle.Position = UDim2.new(0, 0, 0, 0)
ActionsTitle.BackgroundTransparency = 1
ActionsTitle.Text = "PLAYER ACTIONS"
ActionsTitle.TextColor3 = Theme.TextPrimary
ActionsTitle.FontFace = Theme.Fonts.Bold
ActionsTitle.TextSize = 12
ActionsTitle.TextXAlignment = Enum.TextXAlignment.Left
ActionsTitle.Parent = ActionsCard

local GridContainer = Instance.new("Frame")
local gridTopOffset = Theme.ElementHeight + Theme.SmallGap
GridContainer.Size = UDim2.new(1, 0, 1, -gridTopOffset)
GridContainer.Position = UDim2.new(0, 0, 0, Theme.ElementHeight)
GridContainer.BackgroundTransparency = 1
GridContainer.Parent = ActionsCard
local GridLayout = Instance.new("UIGridLayout", GridContainer)
local gridSize = Theme.Dimensions.GridSize
GridLayout.CellSize = UDim2.new(0, gridSize, 0, gridSize) 
GridLayout.CellPadding = UDim2.new(0, Theme.Gap, 0, Theme.Gap) 
GridLayout.SortOrder = Enum.SortOrder.LayoutOrder

local Actions = {
    {name = "Noclip", imgOn = 14385986465, imgOff = 9134787693, col = Color3.fromRGB(0, 170, 127), call = function(s) SkenaHub.State.Noclip = s end},
    {name = "Flight", imgOn = 9134755504, imgOff = 14385992605, col = Color3.fromRGB(170, 37, 46), call = function(s) SkenaHub.State.Flight = s end},
    {name = "Refresh", imgOn = 9134761478, imgOff = 9134761478, col = Color3.fromRGB(61, 179, 98), reset = true, call = function()
        local char = LocalPlayer.Character
        if char then
            local cf = char:GetPivot()
            if char:FindFirstChild("Humanoid") then char.Humanoid:ChangeState(Enum.HumanoidStateType.Dead) end
            LocalPlayer.CharacterAdded:Wait():PivotTo(cf)
        end
    end},
    {name = "Respawn", imgOn = 9134762943, imgOff = 9134762943, col = Color3.fromRGB(49, 88, 193), reset = true, call = function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.Health = 0 end
    end},
    {name = "Fling", imgOn = 9134785384, imgOff = 14386226155, col = Color3.fromRGB(184, 85, 61), call = function(s) SkenaHub.State.Fling = s end},
    {name = "ESP", imgOn = 9134780101, imgOff = 14386232387, col = Color3.fromRGB(214, 182, 19), call = function(s) UpdateESP(s) end},
    {name = "Night and Day", imgOn = 9134778004, imgOff = 10137794784, col = Color3.fromRGB(102, 75, 190), call = function(s) Lighting.ClockTime = s and 12 or 24 end},
    {name = "Global Audio", imgOn = 9134774810, imgOff = 14386246782, col = Color3.fromRGB(202, 103, 58), call = function(s) UserSettings():GetService("UserGameSettings").MasterVolume = s and 0 or SkenaHub.State.OriginalVolume end},
}

for _, act in pairs(Actions) do
    local Btn = Instance.new("TextButton")
    Btn.BackgroundColor3 = Theme.ElementColor
    Btn.BackgroundTransparency = 0
    Btn.Text = ""
    Btn.Parent = GridContainer
    Instance.new("UICorner", Btn).CornerRadius = Theme.InnerCorner
    
    local Strk = Instance.new("UIStroke", Btn)
    Strk.Color = getBrighterColor(Theme.ElementColor)
    Strk.Transparency = 0
    Strk.Thickness = Theme.StrokeThickness
    Strk.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local Ico = Instance.new("ImageLabel")
    local icoSize = 20
    Ico.Size = UDim2.new(0, icoSize, 0, icoSize) 
    Ico.Position = UDim2.new(0.5, -icoSize/2, 0.5, -icoSize/2)
    Ico.BackgroundTransparency = 1
    Ico.Image = "rbxassetid://" .. act.imgOff
    Ico.ImageTransparency = 0.5 
    Ico.Parent = Btn

    local enabled = false
    Btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        if act.reset then enabled = false end
        act.call(enabled)
        
        if enabled then
            Ico.Image = "rbxassetid://" .. act.imgOn
            TweenService:Create(Btn, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {BackgroundColor3 = Theme.AccentRed, BackgroundTransparency = 0.85}):Play()
            TweenService:Create(Strk, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Color = Theme.AccentRed, Transparency = 0}):Play()
            TweenService:Create(Ico, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {ImageTransparency = 0}):Play()
        else
            Ico.Image = "rbxassetid://" .. act.imgOff
            TweenService:Create(Btn, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundColor3 = Theme.ElementColor, BackgroundTransparency = 0}):Play()
            TweenService:Create(Strk, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Color = getBrighterColor(Theme.ElementColor), Transparency = 0}):Play()
            TweenService:Create(Ico, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {ImageTransparency = 0.5}):Play()
        end
    end)
    
    Btn.MouseEnter:Connect(function()
        ActionsTitle.Text = string.upper(act.name)
        ActionsTitle.TextColor3 = Theme.TextPrimary
        if not enabled then 
            TweenService:Create(Btn, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {BackgroundColor3 = Theme.HoverColor}):Play() 
            TweenService:Create(Strk, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {Color = Theme.BorderGlow}):Play() 
            TweenService:Create(Ico, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {ImageTransparency = 0.1}):Play()
        end
    end)
    
    Btn.MouseLeave:Connect(function()
        ActionsTitle.Text = "PLAYER ACTIONS"
        ActionsTitle.TextColor3 = Theme.TextSubtle
        if not enabled then 
            TweenService:Create(Btn, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundColor3 = Theme.ElementColor}):Play() 
            TweenService:Create(Strk, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Color = getBrighterColor(Theme.ElementColor)}):Play() 
            TweenService:Create(Ico, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {ImageTransparency = 0.5}):Play()
        end
    end)
end

task.delay(0.1, function()
    ActionsCard.Size = UDim2.new(1, 0, 0, GridLayout.AbsoluteContentSize.Y + Theme.ElementHeight + Theme.Gap)
    GeneralPage.CanvasSize = UDim2.new(0, 0, 0, GeneralLayout.AbsoluteContentSize.Y + 24)
end)


-- // Game-Specific Loader // --
local function LoadGameScript()
    local PlaceId = game.PlaceId
    local fileName = nil

    if PlaceId == 114272390738102 then
        fileName = "SurvivetheLoop.lua"
    elseif PlaceId == 134750290201751 then
        fileName = "SurvivetheCold.lua"
    elseif PlaceId == 83369512629707 then
        fileName = "SawahIndo.lua"
    elseif PlaceId == 91764591674792 then
        fileName = "StopBrainrots.lua"
    elseif PlaceId == 135668295983945 then
        fileName = "SkillPointLegend.lua"
    elseif PlaceId == 99248392277037 then
        fileName = "UntitledMeleeRNG.lua"
    elseif PlaceId == 135707546762730 then
        fileName = "UnboxYourTank.lua"
    elseif PlaceId == 102669100769936 or PlaceId == 97689234675651 then
        fileName = "DefendYourBase67.lua"
    elseif PlaceId == 74848159470277 or PlaceId == 128981447330754 then
        fileName = "levelbound.lua"
    elseif PlaceId == 118433033586507 then
        fileName = "SimpleSpells.lua"
    else
        fileName = "FallbackAdmin.lua"
    end

    if fileName then
        local success, err = pcall(function() SkenaHub.Core.Load(fileName) end)
        if not success then
            warn("[SkenaHub] Gagal memuat script game: " .. fileName .. " | " .. tostring(err))
        end
    end
end

-- // Admin & Settings Tabs (Last) // --
local function InitializeFinalTabs()
    -- // Tab: AdminTools (Blue) // --
    local isAdmin = true -- Logic for admin check
    if isAdmin then
        local AdminElements, AdminPage, AdminLayout = Window:CreateTab("Admin", 10709818996, Color3.fromRGB(100, 100, 255))
        
        -- 1. Place Info & Dex
        local R1L, R1M, R1R = AdminElements:CreateRow(3)
        R1L.Size = UDim2.new(0, 171, 1, 0)
        R1M.Size = UDim2.new(0, 81, 1, 0)
        R1R.Size = UDim2.new(0, 81, 1, 0)
        AdminElements:CreateLabel("Place Info & Dex", R1L)
        AdminElements:CreateButton("Copy PlaceId", function() 
            if setclipboard then 
                setclipboard(tostring(game.PlaceId)) 
                return "Copied!"
            end 
            return false
        end, R1M)
        AdminElements:CreateButton("DexV3", function()
            local success = pcall(function()
                SkenaHub.Core.Load("0CloneRef.lua")
                SkenaHub.Core.Load("0DexBypasses.lua")
                SkenaHub.Core.Load("0CustomDex.lua")
            end)
            return success
        end, R1R)

        -- 2. Spy Tools
        local R2L, R2M, R2R = AdminElements:CreateRow(3)
        R2L.Size = UDim2.new(0, 171, 1, 0)
        R2M.Size = UDim2.new(0, 81, 1, 0)
        R2R.Size = UDim2.new(0, 81, 1, 0)
        AdminElements:CreateLabel("Spy Tools", R2L)
        AdminElements:CreateButton("for Xeno", function() 
            return pcall(function() SkenaHub.Core.Load("0XenoRSpy.lua") end)
        end, R2M)
        AdminElements:CreateButton("CobaltSpy", function() 
            return pcall(function() SkenaHub.Core.Load("0CobaltSpy.lua") end)
        end, R2R)

        -- 3. Workspace Scanners
        local R3L, R3M, R3R = AdminElements:CreateRow(3)
        R3L.Size = UDim2.new(0, 171, 1, 0)
        R3M.Size = UDim2.new(0, 81, 1, 0)
        R3R.Size = UDim2.new(0, 81, 1, 0)
        AdminElements:CreateLabel("Workspace Scanners", R3L)
        AdminElements:CreateButton("TouchInt", function()
            local ok, errMsg = pcall(function()
                local lines = {"=== SKENA TOUCHINTEREST SCAN ==="}
                local seen = {}
                local count = 0
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("TouchInterest") and obj.Parent then
                        local part = obj.Parent
                        local path = part:GetFullName()
                        if not seen[path] then
                            seen[path] = true
                            count = count + 1
                            lines[#lines + 1] = "[" .. count .. "] (TouchInt) " .. part.Name .. " | " .. path
                        end
                    end
                end
                if count == 0 then warn("[Scan] Tidak ada TouchInterest ditemukan.") error("No TouchInt") end
                if setclipboard then setclipboard(table.concat(lines, "\n")) end
            end)
            return ok and "Copied!" or false
        end, R3M)
        AdminElements:CreateButton("Remotes", function()
            local ok, errMsg = pcall(function()
                local rs = game:GetService("ReplicatedStorage")
                local lines = {"=== SKENA REMOTE SCANNER ===", "Location: ReplicatedStorage", ""}
                local count = 0
                for _, obj in ipairs(rs:GetDescendants()) do
                    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                        count = count + 1
                        lines[#lines + 1] = "[" .. count .. "] (" .. obj.ClassName .. ") " .. obj.Name .. " | " .. obj:GetFullName()
                    end
                end
                if count == 0 then warn("[Scan] Tidak ada Remote ditemukan.") error("No Remotes") end
                if setclipboard then setclipboard(table.concat(lines, "\n")) end
            end)
            return ok and "Copied!" or false
        end, R3R)

        -- 4. Player & Entity Tools
        local R4L, R4M, R4R = AdminElements:CreateRow(3)
        R4L.Size = UDim2.new(0, 171, 1, 0)
        R4M.Size = UDim2.new(0, 81, 1, 0)
        R4R.Size = UDim2.new(0, 81, 1, 0)
        AdminElements:CreateLabel("Player & Entity Tools", R4L)
        AdminElements:CreateButton("Scan NPCs", function()
            local ok, errMsg = pcall(function()
                local playerNames = {}
                for _, p in ipairs(Players:GetPlayers()) do playerNames[p.Name] = true end
                local lines = {"=== SKENA MOB/NPC SCAN ==="}
                local count = 0
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("Humanoid") and obj.Parent and obj.Parent:IsA("Model") then
                        local model = obj.Parent
                        if not playerNames[model.Name] and model ~= LocalPlayer.Character then
                            count = count + 1
                            local hrp = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
                            local pos = hrp and string.format("(%.0f, %.0f, %.0f)", hrp.Position.X, hrp.Position.Y, hrp.Position.Z) or "?"
                            lines[#lines + 1] = string.format("[%d] %s | HP: %.0f/%.0f | Pos: %s | Path: %s",
                                count, model.Name, obj.Health, obj.MaxHealth, pos, model:GetFullName())
                        end
                    end
                end
                if count == 0 then warn("[Scan] Tidak ada NPC ditemukan.") error("No NPCs") end
                if setclipboard then setclipboard(table.concat(lines, "\n")) end
            end)
            return ok and "Copied!" or false
        end, R4M)
        AdminElements:CreateButton("Copy Pos", function()
            local p = LocalPlayer.Character:GetPivot().Position
            if setclipboard then 
                setclipboard(string.format("Vector3.new(%.3f, %.3f, %.3f)", p.X, p.Y, p.Z)) 
                return "Copied!"
            end
            return false
        end, R4R)

        -- 5. Record Actions (Spy)
        local R5L, R5M, R5R = AdminElements:CreateRow(3)
        R5L.Size = UDim2.new(0, 216, 1, 0)
        R5M.Size = UDim2.new(0, 36, 1, 0)
        R5R.Size = UDim2.new(0, 81, 1, 0)
        AdminElements:CreateLabel("Record Actions (Spy)", R5L)
        AdminElements:CreateToggle(function(state)
            SkenaHub.Admin.IsSpying = state
            if state then SkenaHub.Admin.SpyLogs = {} end
        end, false, R5M)
        AdminElements:CreateButton("Copy", function()
            if setclipboard and SkenaHub.Admin.SpyLogs and #SkenaHub.Admin.SpyLogs > 0 then 
                setclipboard(table.concat(SkenaHub.Admin.SpyLogs, "\n")) 
                return "Copied!"
            end
            return false
        end, R5R)

        -- 6. Auto Interact (Log)
        local R6L, R6M, R6R = AdminElements:CreateRow(3)
        R6L.Size = UDim2.new(0, 216, 1, 0)
        R6M.Size = UDim2.new(0, 36, 1, 0)
        R6R.Size = UDim2.new(0, 81, 1, 0)
        AdminElements:CreateLabel("Auto Interact (Log)", R6L)
        AdminElements:CreateToggle(function(state)
            SkenaHub.Admin.AutoInteract = state
            if state then
                SkenaHub.Admin.InteractLogs = {}
                task.spawn(function()
                    while SkenaHub.Admin.AutoInteract do
                        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if hrp and fireproximityprompt then
                            for _, obj in ipairs(workspace:GetDescendants()) do
                                if obj:IsA("ProximityPrompt") and obj.Enabled then
                                    local part = obj.Parent
                                    if part and part:IsA("BasePart") and (hrp.Position - part.Position).Magnitude < 30 then
                                        fireproximityprompt(obj)
                                        table.insert(SkenaHub.Admin.InteractLogs, string.format("[%s] Interacted: %s | %s", os.date("%X"), obj.ObjectText, part:GetFullName()))
                                        task.wait(0.1)
                                    end
                                end
                            end
                        end
                        task.wait(0.5)
                    end
                end)
            end
        end, false, R6M)
        AdminElements:CreateButton("Copy", function()
            if setclipboard and SkenaHub.Admin.InteractLogs and #SkenaHub.Admin.InteractLogs > 0 then 
                setclipboard(table.concat(SkenaHub.Admin.InteractLogs, "\n")) 
                return "Copied!"
            end
            return false
        end, R6R) -- Corrected from R5R to R6R

        -- 7. HTTPS Executor
        local C1, C2, C3 = AdminElements:CreateRow(3)
        C1.Size = UDim2.new(0, 171, 1, 0)
        C2.Size = UDim2.new(0, 36, 1, 0)
        C3.Size = UDim2.new(0, 81 + Theme.Gap + 36, 1, 0) -- TextBox (81) + Gap (9) + Button (36)
        AdminElements:CreateLabel("HTTPS Interceptor", C1)
        AdminElements:CreateToggle(function(state)
            SkenaHub.Admin.SafeMode = state
        end, true, C2)

        local ExecFrame = Instance.new("Frame", C3)
        ExecFrame.Size = UDim2.new(1, 0, 1, 0)
        ExecFrame.BackgroundTransparency = 1
        local ExecLayout = Instance.new("UIListLayout", ExecFrame)
        ExecLayout.FillDirection = Enum.FillDirection.Horizontal
        ExecLayout.Padding = UDim.new(0, Theme.Gap) -- Using standard 9px gap
        ExecLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        
        local scriptSource = ""
        AdminElements:CreateTextBox("", nil, "loadstring...", function(val)
            scriptSource = val
        end, ExecFrame)

        -- Adjust the TextBox size to 81px (2 slots + 1 gap)
        for _, child in ipairs(ExecFrame:GetChildren()) do
            if child:IsA("Frame") then child.Size = UDim2.new(0, 81, 0, Theme.Dimensions.ToggleTrack.Y) end
        end

        AdminElements:CreateCircleButton("rbxassetid://10709791437", function()
            if scriptSource ~= "" then
                local success, err = pcall(function() loadstring(scriptSource)() end)
                if not success then warn("[Exec] Error: " .. tostring(err)) end
            end
        end, ExecFrame, true)

        -- Adjust circle button to 1 slot (36px)
        for _, child in ipairs(ExecFrame:GetChildren()) do
            if child:IsA("TextButton") then child.Size = UDim2.new(0, 36, 0, 36) end
        end
    end

    -- // Tab: Settings (Grey/Silver) // --
    local SettingsElements, SettingsPage, SettingsLayout = Window:CreateTab("Settings Tab", 6031280882, Color3.fromRGB(140, 140, 140))
    local C1, C2, C3 = SettingsElements:CreateRow(3)
    C1.Size = UDim2.new(0, 216, 1, 0)
    C2.Size = UDim2.new(0, 36, 1, 0)
    C3.Size = UDim2.new(0, 81, 1, 0)

    local ToggleKey = Enum.KeyCode.Z
    SettingsElements:CreateTextBox("Z", "Toggle UI Key", "Key...", function(val)
        local success, key = pcall(function() return Enum.KeyCode[val] end)
        if success then
            ToggleKey = key
            warn("[SkenaHub] Toggle key set to: " .. tostring(key))
        else
            warn("[SkenaHub] Invalid KeyCode: " .. tostring(val))
        end
    end, C2)
    
    -- Rename/Parent the Label generated by CreateTextBox to C1 for perfect grid alignment
    for _, child in ipairs(C2:GetChildren()) do
        if child:IsA("Frame") then
            local Label = child:FindFirstChild("TextLabel")
            if Label then Label.Parent = C1 Label.Size = UDim2.new(1, 0, 1, 0) end
        end
    end

    SettingsElements:CreateButton("Reload UI", function()
        local ui = CoreGui:FindFirstChild("SkenaTopNavUI")
        if ui then ui:Destroy() end
        
        SkenaHub.State.Noclip = false; SkenaHub.State.Flight = false; SkenaHub.State.Fling = false
        UpdateESP(false)
        if SkenaHub.Admin and SkenaHub.Admin.ESPConnection then SkenaHub.Admin.ESPConnection:Disconnect() end
        
        task.wait(0.1)
        
        local success, err = pcall(function() 
            SkenaHub.Core.Load("new.lua")
        end)
        if not success then warn("[SkenaHub] Gagal melakukan Reload: " .. tostring(err)) end
    end, C3)
end

LoadGameScript()
InitializeFinalTabs()

UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == ToggleKey then
        Window:Toggle()
    end
end)
