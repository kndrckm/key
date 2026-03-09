-- Pretty much just a bunch of know detection bypasses. (Big thanks to Lego Hacker, Modulus, Bluwu, and I guess Iris or something)

-- GCInfo/CollectGarbage Bypass (Realistic by Lego - Amazing work!)
task.spawn(function()
    repeat task.wait() until game:IsLoaded()

    local Amplitude = 200
    local RandomValue = {-200,200}
    local RandomTime = {.1, 1}

    local floor = math.floor
    local cos = math.cos
    local sin = math.sin
    local acos = math.acos
    local pi = math.pi

    local Maxima = 0

    --Waiting for gcinfo to decrease
    while task.wait() do
        if gcinfo() >= Maxima then
            Maxima = gcinfo()
        else
            break
        end
    end

    task.wait(0.30)

    local OldGcInfo = gcinfo()+Amplitude
    local tick = 0

    --Spoofing gcinfo
    local function getreturn()
        local Formula = ((acos(cos(pi * (tick)))/pi * (Amplitude * 2)) + -Amplitude )
        return floor(OldGcInfo + Formula);
    end

    local Old; Old = hookfunction(getfenv().gcinfo, function(...)
        return getreturn();
    end)
    local Old2; Old2 = hookfunction(getfenv().collectgarbage, function(arg, ...)
        local suc, err = pcall(Old2, arg, ...)
        if suc and arg == "count" then
            return getreturn();
        end
        return Old2(arg, ...);
    end)


    game:GetService("RunService").Stepped:Connect(function()
        local Formula = ((acos(cos(pi * (tick)))/pi * (Amplitude * 2)) + -Amplitude )
        if Formula > ((acos(cos(pi * (tick)+.01))/pi * (Amplitude * 2)) + -Amplitude ) then
            tick = tick + .07
        else
            tick = tick + 0.01
        end
    end)

    local old1 = Amplitude
    for i,v in next, RandomTime do
        RandomTime[i] = v * 10000
    end

    local RandomTimeValue = math.random(RandomTime[1],RandomTime[2])/10000

    --I can make it 0.003 seconds faster, yea, sure
    while wait(RandomTime) do
        Amplitude = math.random(old1+RandomValue[1], old1+RandomValue[2])
        RandomTimeValue = math.random(RandomTime[1],RandomTime[2])/10000
    end
end)

-- Memory Bypass
task.spawn(function()
    repeat task.wait() until game:IsLoaded()

    local RunService = cloneref(game:GetService("RunService"))
    local Stats = cloneref(game:GetService("Stats"))

    local CurrMem = Stats:GetTotalMemoryUsageMb();
    local Rand = 0

    RunService.Stepped:Connect(function()
        local random = Random.new()
    	Rand = random:NextNumber(-10, 10);
    end)

    local function GetReturn()
        return CurrMem + Rand;
    end

    local _MemBypass
    _MemBypass = hookmetamethod(game, "__namecall", function(self,...)
        local method = getnamecallmethod();

        if not checkcaller() then
            if typeof(self) == "Instance" and (method == "GetTotalMemoryUsageMb" or method == "getTotalMemoryUsageMb") and self.ClassName == "Stats" then
                return GetReturn();
            end
        end

        return _MemBypass(self, ...);
    end)
end)

-- FPS Bypass
task.spawn(function()
    repeat task.wait() until game:IsLoaded()

    local RunService = cloneref(game:GetService("RunService"))

    local FPS = 0
    local Rand = 0

    RunService.Heartbeat:Connect(function(dt)
        local random = Random.new()
        FPS = 1/dt
        Rand = random:NextNumber(-10, 10)
    end)

    local function GetReturn()
        return FPS + Rand
    end

    local OldStats
    OldStats = hookmetamethod(game, "__index", function(self, index)
        if not checkcaller() then
            if typeof(self) == "Instance" and self.ClassName == "Stats" and index == "HeartbeatTimeMs" then
                return GetReturn()
            end
        end
        return OldStats(self, index)
    end)
end)

-- Ping Bypass
task.spawn(function()
    repeat task.wait() until game:IsLoaded()

    local Players = cloneref(game:GetService("Players"))
    local LocalPlayer = Players.LocalPlayer

    local Rand = 0
    local CurrPing = 0

    game:GetService("RunService").Heartbeat:Connect(function()
        local random = Random.new()
        Rand = random:NextNumber(-20, 20)
    end)

    local function GetReturn()
        return CurrPing + Rand
    end

    local OldPing
    OldPing = hookmetamethod(game, "__index", function(self, index)
        if not checkcaller() then
            if typeof(self) == "Instance" and self == LocalPlayer and index == "NetworkPing" then
                return GetReturn()
            end
        end
        return OldPing(self, index)
    end)
end)

-- Script Count Bypass (Prevents exploits from having too many loaded scripts)
task.spawn(function()
    repeat task.wait() until game:IsLoaded()

    local ScriptCount = #getloadedmodules()

    local _ScriptBypass
    _ScriptBypass = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()

        if not checkcaller() then
            if typeof(self) == "Instance" and method == "GetDescendants" and self == game then
                local result = _ScriptBypass(self, ...)
                local filtered = {}
                for _, v in ipairs(result) do
                    if not (v:IsA("LocalScript") or v:IsA("ModuleScript")) then
                        table.insert(filtered, v)
                    end
                end
                return filtered
            end
        end

        return _ScriptBypass(self, ...)
    end)
end)
