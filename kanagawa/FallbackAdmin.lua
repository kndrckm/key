-- ==========================================
-- SKENA HUB : FALLBACK ADMIN PANEL
-- Script ini berjalan di game yang belum didukung
-- ==========================================

local SkenaHub_LibURL = "http://192.168.100.40:8000/kanagawa/SkenaUI_Library.lua"
local SkenaHub_AdminURL = "http://192.168.100.40:8000/kanagawa/SkenaUI_Admin.lua"
local cacheBuster = "?t=" .. tostring(os.time())

-- 1. Load Library
local SkenaUI
local success, err = pcall(function()
    SkenaUI = loadstring(game:HttpGet(SkenaHub_LibURL .. cacheBuster, true))()
end)

if not success or not SkenaUI then
    warn("[SkenaUI Fallback] Gagal memuat UI Library: ", err)
    return
end

local Window = SkenaUI.CreateWindow("SkenaHub", "Unsupported Game (Admin Only)", false)

-- 3. Load Admin Panel
local adminLoaded, SkenaAdmin = pcall(function()
    return loadstring(game:HttpGet(SkenaHub_AdminURL .. cacheBuster, true))()
end)

if adminLoaded and SkenaAdmin then
    SkenaAdmin.Attach(Window, {})
else
    warn("[SkenaUI Fallback] Gagal memuat Admin Module atau Anda tidak di-whitelist.")
    local TabInfo = Window:CreateTab("Info", "info", false)
    TabInfo:CreateTextRow({
        Text = "Game ini belum didukung oleh SkenaHub. Hubungi developer untuk request dukungan game ini."
    })
end
