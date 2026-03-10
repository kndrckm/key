-- Anti-AFK (Global untuk semua game)
pcall(function()
    local VirtualUser = game:GetService("VirtualUser")
    game.Players.LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
    getgenv()._SKENA_ANTI_AFK = true
end)

local GITHUB_URL = "https://raw.githubusercontent.com/kndrckm/key/refs/heads/main/"
local LOCAL_URL = "http://192.168.100.40:8000/"

local PlaceId = game.PlaceId

-- Set to true for local testing, false to use GitHub
if getgenv()._SKENA_DEV_MODE == nil then
    getgenv()._SKENA_DEV_MODE = true 
end

local SkenaHub_BaseURL = getgenv()._SKENA_DEV_MODE and (LOCAL_URL .. "test/") or GITHUB_URL
getgenv()._SKENA_BASE_URL = SkenaHub_BaseURL

-- Helper untuk memuat script lain secara lokal / remote
getgenv().SkenaLoad = function(fileName)
    local url = SkenaHub_BaseURL .. fileName .. "?t=" .. os.time()
    print("[SkenaUI] Fetching: " .. url)
    local success, body = pcall(game.HttpGet, game, url, true)
    
    if success and body and #body > 0 then
        local func, err = loadstring(body)
        if func then
            return func()
        else
            warn("[SkenaUI] Syntax Error in " .. fileName .. ": " .. tostring(err))
        end
    else
        local reason = not success and "Network Error" or (not body and "Nil Body" or "Empty Body")
        warn("[SkenaUI] Gagal mengunduh: " .. fileName .. " (" .. reason .. ")")
        if getgenv()._SKENA_DEV_MODE then
            warn("[SkenaUI] Dev Mode aktif. Pastikan server lokal di 192.168.100.40:8000 jalan.")
        end
    end
end

local SkenaHub_CoreURL = SkenaHub_BaseURL

-- Load Library directly for revamping
SkenaHub_CoreURL = SkenaHub_BaseURL .. "SkenaUI_Library.lua"


-- Eksekusi script spesifik game (dengan cache buster)
local cacheBuster = "?t=" .. tostring(os.time())
print("[SkenaUI] Main Load: " .. SkenaHub_CoreURL .. cacheBuster)
local success, err = pcall(function()
    local scriptBody = game:HttpGet(SkenaHub_CoreURL .. cacheBuster, true)
    if not scriptBody or #scriptBody == 0 then
        error("Gagal mengunduh scriptBody (Nil/Empty). URL: " .. SkenaHub_CoreURL)
    end
    local func, compileErr = loadstring(scriptBody)
    if not func then
        error("Syntax Error: " .. tostring(compileErr))
    end
    local lib = func()
    
    -- If we are in test mode and just loading the library, show a demo window
    if getgenv()._SKENA_DEV_MODE and lib and type(lib) == "table" and lib.CreateWindow then
        print("[SkenaUI] Creating Demo Window for Revamp...")
        local Window = lib:CreateWindow({
            Name = "Skena Revamp (Glass)",
            Title = "UI Revamp Phase 1"
        })
        local MainTab = Window:CreateTab("Revamp", "glass")
        MainTab:CreateInputRow({
            Name = "Status",
            Placeholder = "Glassmorphic Sidebar Active!",
            Callback = function() end
        })
        print("[SkenaUI] Demo Window Created.")
    end
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
