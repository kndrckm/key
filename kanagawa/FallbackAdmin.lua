-- ==========================================
-- SKENA HUB : FALLBACK ADMIN PANEL
-- Script ini berjalan di game yang belum didukung
-- ==========================================

local SkenaUI
local success, err = pcall(function()
    SkenaUI = getgenv().SkenaLoad("SkenaUI_Library.lua")
end)

if not success or not SkenaUI then
    warn("[SkenaUI Fallback] Gagal memuat UI Library: ", err)
    return
end

local Window = SkenaUI.CreateWindow("SkenaHub", "Unsupported Game (Admin Only)", false)

-- 3. Load Admin Panel
local adminLoaded, SkenaAdmin = pcall(function()
    return getgenv().SkenaLoad("SkenaUI_Admin.lua")
end)

if adminLoaded and SkenaAdmin then
    -- Attach akan otomatis mengecek whitelist dan membuat Tab Admin
    SkenaAdmin.Attach(Window, {})
else
    warn("[SkenaUI Fallback] Gagal memuat Admin Module atau Anda tidak di-whitelist.")
    -- Buat tab informasi jika bukan admin
    local TabInfo = Window:CreateTab("Info", "info", false)
    TabInfo:CreateTextRow({
        Text = "Game ini belum didukung oleh SkenaHub. Hubungi developer untuk request dukungan game ini."
    })
end
