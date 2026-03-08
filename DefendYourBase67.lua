-- ==========================================
-- SKENA HUB : Defend Your Base From 67
-- Game ID: 102669100769936, 97689234675651
-- ==========================================
local SkenaUI_LibURL = "http://192.168.100.40:8000/SkenaUI_Library.lua"
local cacheBuster = "?t=" .. tostring(os.time())
local libBody = game:HttpGet(SkenaUI_LibURL .. cacheBuster, true)
local libFunc, libErr = loadstring(libBody)
if not libFunc then error("SkenaUI Library Syntax Error: " .. tostring(libErr)) end
local SkenaUI = libFunc()

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local Window = SkenaUI.CreateWindow("SkenaHub", "Defend Your Base 67", false)
local TabMain = Window:CreateTab("DefendYourBase67", "shield", false)
local TabSettings = Window:CreateTab("Settings", "settings", true)

-- Kill phantom loops
pcall(function()
    if getgenv()._SKENA_DYB67_LOOPS then
        for _, flag in pairs(getgenv()._SKENA_DYB67_LOOPS) do
            getgenv()[flag] = false
        end
    end
end)
getgenv()._SKENA_DYB67_LOOPS = {}

local function RegisterLoop(flagName)
    getgenv()[flagName] = false
    table.insert(getgenv()._SKENA_DYB67_LOOPS, flagName)
end

-- ==========================================
-- AUTO REPAIR SYSTEM
-- ==========================================
getgenv().AutoRepairThreshold = 50
RegisterLoop("_SKENA_AUTO_REPAIR")

local function GetBaseHPPercentage()
    local hpValue = nil
    local maxHpValue = nil

    -- [1] Cari di Workspace (Prioritas: Model bernama Door/Base atau HP Value)
    for _, obj in ipairs(workspace:GetDescendants()) do
        -- Cari Humanoid di Model "Door" atau "Base"
        if obj:IsA("Humanoid") and obj.Parent then
            local pName = obj.Parent.Name:lower()
            if pName:match("door") or pName:match("base") or pName:match("gate") then
                hpValue = obj.Health
                maxHpValue = obj.MaxHealth
                break
            end
        end
        
        -- Cari IntValue/NumberValue (Lebih spesifik)
        if obj:IsA("IntValue") or obj:IsA("NumberValue") then
            local name = obj.Name:lower()
            if name == "doorhealth" or name == "basehealth" or (name:match("hp") and obj.Parent and obj.Parent.Name:lower():match("door")) then
                hpValue = obj.Value
                local parent = obj.Parent
                local maxObj = parent:FindFirstChild("MaxHealth") or parent:FindFirstChild("MaxHP") or parent:FindFirstChild("Max" .. obj.Name)
                if maxObj and (maxObj:IsA("IntValue") or maxObj:IsA("NumberValue")) then
                    maxHpValue = maxObj.Value
                end
                break
            end
        end
    end

    -- [2] Cek Attributes (Beberapa game modern pakai ini)
    if not hpValue then
        local door = workspace:FindFirstChild("Door", true) or workspace:FindFirstChild("Base", true)
        if door then
            hpValue = door:GetAttribute("Health") or door:GetAttribute("HP")
            maxHpValue = door:GetAttribute("MaxHealth") or door:GetAttribute("MaxHP")
        end
    end

    -- [3] Cek PlayerGui (Jika HP ditampilkan di TextLabel)
    if not hpValue then
        local pg = player:FindFirstChild("PlayerGui")
        if pg then
            -- Cari TextLabel yang isinya "/" (biasanya format 100/100)
            for _, v in ipairs(pg:GetDescendants()) do
                if v:IsA("TextLabel") and v.Visible and v.Text:match("/") then
                    local current, max = v.Text:match("(%d+%.?%d*)%s*/%s*(%d+%.?%d*)")
                    if current and max then
                        -- Pastikan bukan HP player (biasanya TextLabel HP player ada di bar bawah/kiri)
                        -- Kita asumsikan HP door adalah yang angkanya paling besar atau di lokasi tertentu
                        local cNum = tonumber(current:gsub(",", ""))
                        local mNum = tonumber(max:gsub(",", ""))
                        if mNum and mNum > 0 then
                            -- Game ini HP Base biasanya ribuan (seperti 10,000 di screenshot)
                            hpValue = cNum
                            maxHpValue = mNum
                        end
                    end
                end
            end
        end
    end

    if hpValue and maxHpValue and maxHpValue > 0 then
        return (hpValue / maxHpValue) * 100
    elseif hpValue then
        return hpValue 
    end
    
    return nil 
end

TabMain:CreateToggleRow({
    Name = " [ Auto Repair Base ]",
    Callback = function(state) end,
    OnToggle = function(state)
        getgenv()._SKENA_AUTO_REPAIR = state
        if state then
            task.spawn(function()
                while getgenv()._SKENA_AUTO_REPAIR do
                    task.wait(0.5)
                    local success, hpPercent = pcall(GetBaseHPPercentage)
                    
                    if not success or hpPercent == nil then
                         local args = { [1] = "repair" }
                         pcall(function()
                             game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Base"):FireServer(unpack(args))
                         end)
                         task.wait(1.5)
                    else
                         if hpPercent <= getgenv().AutoRepairThreshold then
                             local args = { [1] = "repair" }
                             pcall(function()
                                 game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Base"):FireServer(unpack(args))
                             end)
                             task.wait(2)
                         end
                    end
                end
            end)
        end
    end
})

TabMain:CreateSliderRow({
    Name = "HP Threshold (%)",
    Min = 10,
    Max = 95,
    Default = 50,
    Suffix = "%",
    Callback = function(val)
        getgenv().AutoRepairThreshold = tonumber(val) or 50
    end
})

TabMain:CreateButtonRow({
    Name = "Spam Repair (10x)",
    ButtonText = "Execute",
    Callback = function()
        warn("[Repair] Sending 10x repair requests...")
        for i = 1, 10 do
            local args = { [1] = "repair" }
            pcall(function()
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Base"):FireServer(unpack(args))
            end)
            task.wait(0.1)
        end
    end
})


-- ==========================================
-- AUTO UPGRADE DOOR
-- ==========================================
RegisterLoop("_SKENA_AUTO_UPGRADE_DOOR")
TabMain:CreateToggleRow({
    Name = " [ Auto Upgrade Door ]",
    OnToggle = function(state)
        getgenv()._SKENA_AUTO_UPGRADE_DOOR = state
        if state then
            task.spawn(function()
                while getgenv()._SKENA_AUTO_UPGRADE_DOOR do
                    pcall(function()
                        local event = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Upgrade")
                        local bases = workspace:WaitForChild("Bases"):GetChildren()
                        for i = 1, 7 do
                            local base = bases[i]
                            if base and base:FindFirstChild("Door") then
                                event:FireServer("upgrade", base.Door)
                            end
                        end
                    end)
                    task.wait(1)
                end
            end)
        end
    end
})

-- ==========================================
-- TAB SETTINGS
-- ==========================================
TabSettings:CreateInputRow({
    Name = "UI Toggle Key",
    Placeholder = "Z",
    Default = "Z",
    Callback = function(keyStr)
        Window:SetToggleKey(keyStr)
    end
})

-- ==========================================
-- ATTACH ADMIN MODULE
-- ==========================================
task.spawn(function()
    local succ, SkenaAdmin = pcall(function()
        local adminCacheBuster = "?t=" .. tostring(os.time())
        return loadstring(game:HttpGet("http://192.168.100.40:8000/SkenaUI_Admin.lua" .. adminCacheBuster))()
    end)
    if succ and SkenaAdmin then
        SkenaAdmin.Attach(Window, {})
    end
end)
