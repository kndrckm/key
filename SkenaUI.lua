-- Anti-AFK (Global untuk semua game)
pcall(function()
    local VirtualUser = game:GetService("VirtualUser")
    game.Players.LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
    getgenv()._SKENA_ANTI_AFK = true
end)

local PlaceId = game.PlaceId
local SkenaHub_CoreURL = ""

if PlaceId == 114272390738102 then
    SkenaHub_CoreURL = "https://raw.githubusercontent.com/kndrckm/kndrckm.github.io/refs/heads/main/key/SurvivetheLoop.lua"
elseif PlaceId == 134750290201751 then
    SkenaHub_CoreURL = "https://raw.githubusercontent.com/kndrckm/kndrckm.github.io/refs/heads/main/key/SurvivetheCold.lua"
elseif PlaceId == 83369512629707 then
    SkenaHub_CoreURL = "https://raw.githubusercontent.com/kndrckm/kndrckm.github.io/refs/heads/main/key/SawahIndo.lua"
elseif PlaceId == 91764591674792 then
    SkenaHub_CoreURL = "https://raw.githubusercontent.com/kndrckm/kndrckm.github.io/refs/heads/main/key/StopBrainrots.lua"
elseif PlaceId == 135668295983945 then
    SkenaHub_CoreURL = "https://raw.githubusercontent.com/kndrckm/kndrckm.github.io/refs/heads/main/key/SkillPointLegend.lua"
elseif PlaceId == 99248392277037 then
    SkenaHub_CoreURL = "https://raw.githubusercontent.com/kndrckm/kndrckm.github.io/refs/heads/main/key/UntitledMeleeRNG.lua"
elseif PlaceId == 135707546762730 then
    SkenaHub_CoreURL = "https://raw.githubusercontent.com/kndrckm/kndrckm.github.io/refs/heads/main/key/UnboxYourTank.lua"
elseif PlaceId == 102669100769936 or PlaceId == 97689234675651 then
    SkenaHub_CoreURL = "https://raw.githubusercontent.com/kndrckm/kndrckm.github.io/refs/heads/main/key/DefendYourBase67.lua"
elseif PlaceId == 74848159470277 or PlaceId == 128981447330754 then
    SkenaHub_CoreURL = "https://raw.githubusercontent.com/kndrckm/kndrckm.github.io/refs/heads/main/key/levelbound.lua"
elseif PlaceId == 118433033586507 then
    SkenaHub_CoreURL = "https://raw.githubusercontent.com/kndrckm/kndrckm.github.io/refs/heads/main/key/SimpleSpells.lua"
else
    -- Game tidak disupport: Load Fallback Admin (untuk di-test / bypass oleh admin)
    SkenaHub_CoreURL = "https://raw.githubusercontent.com/kndrckm/kndrckm.github.io/refs/heads/main/key/FallbackAdmin.lua"
end

-- Eksekusi script spesifik game (dengan cache buster)1
local cacheBuster = "?t=" .. tostring(os.time())
local success, err = pcall(function()
    local scriptBody = game:HttpGet(SkenaHub_CoreURL .. cacheBuster, true)
    local func, compileErr = loadstring(scriptBody)
    if not func then
        error("Syntax Error: " .. tostring(compileErr))
    end
    func()
end)

if not success then
    warn("[SkenaUI] Gagal memuat UI untuk game ini: ", err)
    -- Tampilkan error di layar agar tidak silent-fail
    pcall(function()
        local sg = Instance.new("ScreenGui")
        sg.Name = "SkenaErrorDisplay"
        local ok = pcall(function() sg.Parent = game:GetService("CoreGui") end)
        if not ok then sg.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui") end
        local lbl = Instance.new("TextLabel", sg)
        lbl.Size = UDim2.new(0, 500, 0, 60)
        lbl.Position = UDim2.new(0.5, -250, 0, 10)
        lbl.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
        lbl.TextColor3 = Color3.new(1,1,1)
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 12
        lbl.TextWrapped = true
        lbl.Text = "[SkenaUI Error] " .. tostring(err)
        Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 6)
        task.delay(15, function() if sg then sg:Destroy() end end)
    end)
end
