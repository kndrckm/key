-- Midnight Neon Refined Demo (Auto-Reload Enabled)
local LOCAL_URL = "http://192.168.100.40:8000/"
local SCRIPT_PATH = "test/MinimalTest.lua"

local lib = loadstring(game:HttpGet(LOCAL_URL .. "test/SkenaUI_Library.lua"))()

local Window = lib:CreateWindow({
    Name = "Codite",
    ReloadURL = LOCAL_URL .. SCRIPT_PATH -- PASSING OWN URL FOR AUTO-RELOAD
})

-- Build Navigation
Window:CreateTab("Items", "package", "G")
Window:CreateTab("Stats", "bar-chart-2", "Ctrl S")
Window:CreateTab("Shop", "shopping-cart", "Ctrl Q")
Window:CreateTab("Friends", "users", "Ctrl I")

print("[SkenaUI] Midnight Neon Refined loaded.")
print("-> Auto-Reload target: " .. SCRIPT_PATH)
