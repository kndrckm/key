-- ==========================================
-- SKENA HUB : Simple Spells!
-- Place ID: 118433033586507
-- ==========================================

local SkenaUI_LibURL = "https://raw.githubusercontent.com/kndrckm/kndrckm.github.io/refs/heads/main/key/SkenaUI_Library.lua"
local SkenaUI = loadstring(game:HttpGet(SkenaUI_LibURL .. "?t=" .. tostring(os.time()), true))()

-- 1. Buat Window
local Window = SkenaUI.CreateWindow("SkenaHub", "Skena Hub | Simple Spells!", false)

-- 2. Buat Tab
local TabMain = Window:CreateTab("Main", "zap", false)

-- HELPER: Kill phantom loops
pcall(function()
    if getgenv()._SKENA_SS_LOOPS then
        for _, flag in pairs(getgenv()._SKENA_SS_LOOPS) do
            getgenv()[flag] = false
        end
    end
end)
getgenv()._SKENA_SS_LOOPS = {}

local function RegisterLoop(flagName)
    getgenv()[flagName] = false
    table.insert(getgenv()._SKENA_SS_LOOPS, flagName)
end

-- ==========================================
-- 1. MAIN FEATURES
-- ==========================================

local selectedSpell = "Common Spell [50 Gold]"

local spellMap = {
    ["Common Spell [50 Gold]"] = workspace:FindFirstChild("CrystallBall_1"),
    ["Desert Spell [300 Gold]"] = workspace:FindFirstChild("CrystallBall_2"),
    ["??? [3,500 Gold]"] = workspace:FindFirstChild("CrystallBall_3"),
    ["??? [25,000 Gold]"] = workspace:FindFirstChild("CrystallBall_4"),
    ["??? [100,000 Gold]"] = workspace:FindFirstChild("CrystallBall_5")
}

local buyDrop = TabMain:CreateDropdownButton({
    Name = "Buy Spell",
    ButtonText = "Buy!",
    Callback = function(item)
        selectedSpell = item
    end,
    OnButton = function()
        local ball = spellMap[selectedSpell]
        local event = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteEvent_3")
        if ball and event then
            event:FireServer("BuyCrystalBall", ball, 1)
            warn("[Skena] Membeli 1x " .. selectedSpell)
        else
            warn("[Skena] Gagal membeli: CrystalBall atau Remote tidak ditemukan!")
        end
    end
})

buyDrop:AddItem("Common Spell [50 Gold]", true)
buyDrop:AddItem("Desert Spell [300 Gold]")
buyDrop:AddItem("??? [3,500 Gold]")
buyDrop:AddItem("??? [25,000 Gold]")
buyDrop:AddItem("??? [100,000 Gold]")

TabMain:CreateTextRow({
    Text = "Simple Spells! script. Use the dropdown above to select a spell and click Buy! to purchase."
})

-- ==========================================
-- ATTACH ADMIN MODULE
-- ==========================================
task.spawn(function()
    local succ, SkenaAdmin = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/kndrckm/kndrckm.github.io/refs/heads/main/key/SkenaUI_Admin.lua?t=" .. tostring(os.time())))()
    end)
    if succ and SkenaAdmin then
        SkenaAdmin.Attach(Window, {})
    end
end)
