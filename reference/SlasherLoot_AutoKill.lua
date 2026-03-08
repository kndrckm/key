local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local ATTACK_RANGE = 50
local AUTO_KILL = false
local ATTACK_DELAY = 0.1

local mobCache = {}
local lastCacheUpdate = 0
local CACHE_INTERVAL = 0.5

local Modal = loadstring(game:HttpGet("https://github.com/BloxCrypto/Modal/releases/download/v1.0-beta/main.lua"))()
local Window = Modal:CreateWindow({
    Title = "Slasher Loot[V7]",
    SubTitle = "Auto Kill Script",
    Size = UDim2.fromOffset(400, 300),
    MinimumSize = Vector2.new(250, 200),
    Transparency = 0.35,
    Icon = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. Players.LocalPlayer.UserId .. "&width=420&height=420&format=png",
})

local function getCharacter()
    return player.Character
end

local function getMobs()
    local currentTime = tick()
    if currentTime - lastCacheUpdate > CACHE_INTERVAL then
        mobCache = {}
        if workspace.Live and workspace.Live:FindFirstChild("MobModel") then
            for _, mob in pairs(workspace.Live.MobModel:GetChildren()) do
                if mob.Name and string.len(mob.Name) > 10 and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") then
                    if mob.Humanoid.Health > 0 then
                        table.insert(mobCache, mob)
                    end
                end
            end
        end
        lastCacheUpdate = currentTime
    end
    return mobCache
end

local function attackMob(mobName)
    spawn(function()
        pcall(function()
            local args = {{mobName}}
            ReplicatedStorage.Remote.Event.Combat.M1:FireServer(unpack(args))
        end)
    end)
end

local function getClosestMob(playerPos)
    local mobs = getMobs()
    local closestMob = nil
    local closestDistance = ATTACK_RANGE
    
    for _, mob in pairs(mobs) do
        if mob and mob.Parent and mob:FindFirstChild("HumanoidRootPart") then
            local distance = (playerPos - mob.HumanoidRootPart.Position).Magnitude
            if distance < closestDistance then
                closestDistance = distance
                closestMob = mob
            end
        end
    end
    
    return closestMob, closestDistance
end

local lastAttack = 0
local connection
local function botLoop()
    if not AUTO_KILL then
        return
    end
    
    local character = getCharacter()
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local playerPos = character.HumanoidRootPart.Position
    local currentTime = tick()
    
    if currentTime - lastAttack > ATTACK_DELAY then
        local closestMob, distance = getClosestMob(playerPos)
        if closestMob then
            attackMob(closestMob.Name)
            print("Attacking:", closestMob.Name:sub(1, 8), "Distance:", math.floor(distance))
            lastAttack = currentTime
        end
    end
end

local MainTab = Window:AddTab("Main")

MainTab:New("Toggle")({
    Title = "Auto Kill",
    Description = "Enable/Disable auto mob killing",
    DefaultValue = false,
    Callback = function(Value)
        AUTO_KILL = Value
        print("Auto Kill:", Value and "ON" or "OFF")
    end,
})

MainTab:New("Slider")({
    Title = "Attack Range",
    Description = "Range to attack mobs",
    Default = 50,
    Minimum = 10,
    Maximum = 100,
    DecimalCount = 0,
    Callback = function(Value)
        ATTACK_RANGE = Value
        print("Attack Range:", Value)
    end,
})

MainTab:New("Slider")({
    Title = "Attack Delay",
    Description = "Delay between attacks (seconds)",
    Default = 0.1,
    Minimum = 0.05,
    Maximum = 1.0,
    DecimalCount = 2,
    Callback = function(Value)
        ATTACK_DELAY = Value
        print("Attack Delay:", Value)
    end,
})

Window:SetTab("Main")
Window:SetTheme("Dark")

connection = RunService.Heartbeat:Connect(botLoop)
