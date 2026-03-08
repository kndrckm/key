-- ==========================================
-- LOCAL GAMEPASSES BYPASS (Reference Script)
-- Supermarket Simulator
-- Credits: ExploitFin
-- ==========================================
-- Techniques: InvokeServer for gold, FireServer for gamepasses/XP
-- Uses Events.Gold.ChangeGoldRF, Events.Goods.GamePassRE, Events.Exp.ChangeExpRE

local L = loadstring(game:HttpGet("https://raw.githubusercontent.com/Turtle-Brand/Turtle-Lib/main/source.lua"))()
local W = L:Window("Supermarket Simulator")

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local rs = game:GetService("ReplicatedStorage")
local eve = rs:WaitForChild("Events")

local function ir(rempath, ...)
    local remote = rempath:InvokeServer(...)
    return remote
end

local function fr(rempath, ...)
    rempath:FireServer(...)
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

W:Button("Infinite Money", function()
    local goldrem = eve:WaitForChild("Gold"):WaitForChild("ChangeGoldRF")
    ir(goldrem, "ChangeGold", math.huge, false)
end)

W:Button("Get All Gamepasses", function()
    local gprem = eve:WaitForChild("Goods"):WaitForChild("GamePassRE")

    local gamepasses = {
        { "Cashier", 28 },
        { "Quick Check-out", 1 },
        { "Porter", 5 },
        { "Quick Pricing" }
    }
  
    for _, args in ipairs(gamepasses) do
        fr(gprem, unpack(args))
    end
end)

W:Toggle("Infinite XP", true, function(val)
    local xprem = eve:WaitForChild("Exp"):WaitForChild("ChangeExpRE")
    local XP = 10000000

    local function start()
        while val do
            pcall(function()
                fr(xprem, XP)
            end)
            task.wait(0.1)
        end
    end

    if val then
        task.spawn(start)
    end
end)

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--// Credits to ExploitFin //--
