-- Anti-AFK (Global untuk semua game)
pcall(function()
    local VirtualUser = game:GetService("VirtualUser")
    game.Players.LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
    getgenv()._SKENA_ANTI_AFK = true
end)

local GITHUB_URL = "https://raw.githubusercontent.com/kndrckm/key/refs/heads/main/onedark/"
local LOCAL_URL = "http://192.168.100.40:8000/onedark/"

local PlaceId = game.PlaceId

-- Set to true for local testing, false to use GitHub
if getgenv()._SKENA_DEV_MODE == nil then
    getgenv()._SKENA_DEV_MODE = true 
end

local SkenaHub_BaseURL = getgenv()._SKENA_DEV_MODE and LOCAL_URL or GITHUB_URL
getgenv()._SKENA_BASE_URL = SkenaHub_BaseURL

-- Helper untuk memuat script lain secara lokal / remote
getgenv().SkenaLoad = function(fileName)
    local url = SkenaHub_BaseURL .. fileName .. "?t=" .. os.time()
    local success, body = pcall(game.HttpGet, game, url, true)
    if success then
        local func, err = loadstring(body)
        if func then
            return func()
        else
            warn("[SkenaUI] Syntax Error in " .. fileName .. ": " .. tostring(err))
        end
    else
        warn("[SkenaUI] Gagal mengunduh: " .. fileName)
    end
end

local SkenaHub_CoreURL = SkenaHub_BaseURL

if PlaceId == 114272390738102 then
    SkenaHub_CoreURL = SkenaHub_CoreURL .. "SurvivetheLoop.lua"
elseif PlaceId == 134750290201751 then
    SkenaHub_CoreURL = SkenaHub_CoreURL .. "SurvivetheCold.lua"
elseif PlaceId == 83369512629707 then
    SkenaHub_CoreURL = SkenaHub_CoreURL .. "SawahIndo.lua"
elseif PlaceId == 91764591674792 then
    SkenaHub_CoreURL = SkenaHub_CoreURL .. "StopBrainrots.lua"
elseif PlaceId == 135668295983945 then
    SkenaHub_CoreURL = SkenaHub_CoreURL .. "SkillPointLegend.lua"
elseif PlaceId == 99248392277037 then
    SkenaHub_CoreURL = SkenaHub_CoreURL .. "UntitledMeleeRNG.lua"
elseif PlaceId == 135707546762730 then
    SkenaHub_CoreURL = SkenaHub_CoreURL .. "UnboxYourTank.lua"
elseif PlaceId == 102669100769936 or PlaceId == 97689234675651 then
    SkenaHub_CoreURL = SkenaHub_CoreURL .. "DefendYourBase67.lua"
elseif PlaceId == 74848159470277 or PlaceId == 128981447330754 then
    SkenaHub_CoreURL = SkenaHub_CoreURL .. "levelbound.lua"
elseif PlaceId == 118433033586507 then
    SkenaHub_CoreURL = SkenaHub_CoreURL .. "SimpleSpells.lua"
else
    -- Game tidak disupport: Load Fallback Admin (untuk di-test / bypass oleh admin)
    SkenaHub_CoreURL = SkenaHub_CoreURL .. "FallbackAdmin.lua"
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
    warn("[SkenaUI] Gagal membaca script: " .. tostring(err))
end
