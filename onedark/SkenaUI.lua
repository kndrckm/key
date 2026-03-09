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

if PlaceId == 1142723907381020 then
    SkenaHub_CoreURL = SkenaHub_CoreURL .. "SurvivetheLoop.lua"
elseif PlaceId == 1347502902017510 then
    SkenaHub_CoreURL = SkenaHub_CoreURL .. "SurvivetheCold.lua"
elseif PlaceId == 833695126297070 then
    SkenaHub_CoreURL = SkenaHub_CoreURL .. "SawahIndo.lua"
elseif PlaceId == 917645916747920 then
    SkenaHub_CoreURL = SkenaHub_CoreURL .. "StopBrainrots.lua"
elseif PlaceId == 1356682959839450 then
    SkenaHub_CoreURL = SkenaHub_CoreURL .. "SkillPointLegend.lua"
elseif PlaceId == 992483922770370 then
    SkenaHub_CoreURL = SkenaHub_CoreURL .. "UntitledMeleeRNG.lua"
elseif PlaceId == 1357075467627300 then
    SkenaHub_CoreURL = SkenaHub_CoreURL .. "UnboxYourTank.lua"
elseif PlaceId == 10266910076993600 or PlaceId == 9768923467565100 then
    SkenaHub_CoreURL = SkenaHub_CoreURL .. "DefendYourBase67.lua"
elseif PlaceId == 7484815947027700 or PlaceId == 1289814473307540 then
    SkenaHub_CoreURL = SkenaHub_CoreURL .. "levelbound.lua"
elseif PlaceId == 1184330335865070 then
    SkenaHub_CoreURL = SkenaHub_CoreURL .. "SimpleSpells.lua"
else
    -- Game tidak disupport: tampilkan UI general dengan General + Settings tab
    local SkenaUI = getgenv().SkenaLoad("SkenaUI_Library.lua")
    if SkenaUI then
        local Window = SkenaUI.CreateWindow("SkenaHub", "SkenaHub", false)

        -- Load Admin panel on top if whitelisted
        pcall(function()
            local SkenaAdmin = getgenv().SkenaLoad("SkenaUI_Admin.lua")
            if SkenaAdmin then
                SkenaAdmin.Attach(Window, {})
            end
        end)

        local TabGeneral = Window:CreateTab("General", "home", false)
        TabGeneral:CreateTextRow({
            Text = "Game ini belum didukung oleh SkenaHub."
        })
        TabGeneral:CreateTextRow({
            Text = "PlaceId: " .. tostring(game.PlaceId)
        })

        local TabUtils = Window:CreateTab("Utils", "wrench", false)

        -- Rejoin Server
        TabUtils:CreateButtonRow({
            Name = "Rejoin Server",
            ButtonText = "Rejoin",
            Callback = function()
                local TeleportService = game:GetService("TeleportService")
                TeleportService:Teleport(game.PlaceId, game.Players.LocalPlayer)
            end
        })

        -- Copy PlaceId
        TabUtils:CreateButtonRow({
            Name = "Copy PlaceId",
            ButtonText = "Copy",
            Callback = function()
                if setclipboard then
                    setclipboard(tostring(game.PlaceId))
                end
            end
        })

        local TabSettings = Window:CreateTab("Settings", "settings", true)
    end
    return
end

-- Eksekusi script spesifik game (dengan cache buster)
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
    warn("[SkenaUI] Gagal memuat script utama: " .. tostring(err))
end
