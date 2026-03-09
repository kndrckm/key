local Players = game:GetService("Players")
local player = Players.LocalPlayer
local WHITELISTED_ADMINS = {
    [4871650676] = true, -- UserId User (Akses Admin Utama)
    [72548092] = true,
}
local SkenaAdmin = {}

local function animateBtn(btn, success)
    if not btn or typeof(btn) ~= "Instance" then return end
    local oldText = btn.Text
    local oldColor = btn.BackgroundColor3
    -- Efek Pop!
    btn.Text = success and "Copied!" or "Gagal"
    btn.BackgroundColor3 = success and Color3.fromRGB(40, 200, 80) or Color3.fromRGB(200, 60, 60)
    task.delay(1.5, function()
        if btn and btn.Parent then
            btn.Text = oldText
            btn.BackgroundColor3 = oldColor
        end
    end)
end

function SkenaAdmin.Attach(Window, DebugData)
    -- === GENERAL PANEL (Available to everyone) ===
    local TabGeneral = Window:CreateTab("General", "home")

    local isFlying = false
    local flySpeed = 50
    local flyKey = "f"

    local function handleFlyToggle(state)
        isFlying = state
        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end

        if isFlying then
            -- Cleanup any existing fly objects
            for _, v in ipairs(hrp:GetChildren()) do
                if v.Name == "SkenaFlyBG" or v.Name == "SkenaFlyBV" then v:Destroy() end
            end

            local bg = Instance.new("BodyGyro")
            bg.Name = "SkenaFlyBG"
            bg.P = 9e4
            bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            bg.CFrame = hrp.CFrame
            bg.Parent = hrp

            local bv = Instance.new("BodyVelocity")
            bv.Name = "SkenaFlyBV"
            bv.Velocity = Vector3.new(0, 0, 0)
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.Parent = hrp

            hum.PlatformStand = true

            local cam = workspace.CurrentCamera
            local uis = game:GetService("UserInputService")

            if getgenv()._SKENA_FLY_CONN then getgenv()._SKENA_FLY_CONN:Disconnect() end
            getgenv()._SKENA_FLY_CONN = game:GetService("RunService").RenderStepped:Connect(function()
                if not isFlying or not hrp or not hrp:FindFirstChild("SkenaFlyBG") or not hrp:FindFirstChild("SkenaFlyBV") then
                    if getgenv()._SKENA_FLY_CONN then getgenv()._SKENA_FLY_CONN:Disconnect() end
                    return
                end

                bg.CFrame = cam.CFrame
                local moveDir = Vector3.new()

                if uis:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
                if uis:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
                if uis:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
                if uis:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
                if uis:IsKeyDown(Enum.KeyCode.Space) or uis:IsKeyDown(Enum.KeyCode.E) then moveDir = moveDir + Vector3.new(0, 1, 0) end
                if uis:IsKeyDown(Enum.KeyCode.LeftShift) or uis:IsKeyDown(Enum.KeyCode.Q) then moveDir = moveDir - Vector3.new(0, 1, 0) end

                if moveDir.Magnitude > 0 then
                    moveDir = moveDir.Unit
                end
                bv.Velocity = moveDir * flySpeed
            end)
        else
            if getgenv()._SKENA_FLY_CONN then getgenv()._SKENA_FLY_CONN:Disconnect() end
            local bg = hrp:FindFirstChild("SkenaFlyBG")
            local bv = hrp:FindFirstChild("SkenaFlyBV")
            if bg then bg:Destroy() end
            if bv then bv:Destroy() end
            hum.PlatformStand = false
        end
    end

    local flyRow = TabGeneral:CreateToggleRow({
        Name = "Fly Toggle",
        HasSpeed = true,
        HasKey = true,
        DefaultKey = flyKey,
        DefaultSpeed = "50",
        OnKeyChange = function(val)
            flyKey = val:lower()
        end,
        OnSpeedChange = function(val)
            local s = tonumber(val)
            if s then flySpeed = s end
        end,
        OnToggle = handleFlyToggle
    })

    local speedChangerEnabled = false
    local targetWalkSpeed = 16
    local walkKey = "g"

    local function handleSpeedToggle(state)
        speedChangerEnabled = state
        if speedChangerEnabled then
            if getgenv()._SKENA_SPEED_CONN then getgenv()._SKENA_SPEED_CONN:Disconnect() end
            getgenv()._SKENA_SPEED_CONN = game:GetService("RunService").Stepped:Connect(function()
                local char = player.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum and speedChangerEnabled then
                    if hum.WalkSpeed ~= targetWalkSpeed then
                        hum.WalkSpeed = targetWalkSpeed
                    end
                end
            end)
        else
            if getgenv()._SKENA_SPEED_CONN then getgenv()._SKENA_SPEED_CONN:Disconnect() end
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = 16
            end
        end
    end

    local speedRow = TabGeneral:CreateToggleRow({
        Name = "Speed Changer",
        HasSpeed = true,
        HasKey = true,
        HasSpeedometer = true,
        DefaultKey = walkKey,
        DefaultSpeed = "16",
        OnKeyChange = function(val)
            walkKey = val:lower()
        end,
        OnSpeedChange = function(val)
            local num = tonumber(val)
            if num then targetWalkSpeed = num end
        end,
        OnToggle = handleSpeedToggle
    })

    if speedRow and speedRow.Speedometer then
        if getgenv()._SKENA_SPEEDOMETER_CONN then getgenv()._SKENA_SPEEDOMETER_CONN:Disconnect() end
        getgenv()._SKENA_SPEEDOMETER_CONN = game:GetService("RunService").RenderStepped:Connect(function()
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and speedRow.Speedometer and speedRow.Speedometer.Parent then
                local vel = hrp.Velocity or hrp.AssemblyLinearVelocity
                local speed = Vector3.new(vel.X, 0, vel.Z).Magnitude
                speedRow.Speedometer.Text = string.format("%.1f s/s", speed)
            end
        end)
    end

    local noclipEnabled = false
    local noclipKey = "n"
    local function handleNoclipToggle(state)
        noclipEnabled = state
        if noclipEnabled then
            if getgenv()._SKENA_NOCLIP_CONN then getgenv()._SKENA_NOCLIP_CONN:Disconnect() end
            getgenv()._SKENA_NOCLIP_CONN = game:GetService("RunService").Stepped:Connect(function()
                if not noclipEnabled then
                    if getgenv()._SKENA_NOCLIP_CONN then getgenv()._SKENA_NOCLIP_CONN:Disconnect() end
                    return
                end
                local char = player.Character
                if char then
                    for _, v in ipairs(char:GetDescendants()) do
                        if v:IsA("BasePart") and v.CanCollide then
                            v.CanCollide = false
                        end
                    end
                end
            end)
        else
            if getgenv()._SKENA_NOCLIP_CONN then getgenv()._SKENA_NOCLIP_CONN:Disconnect() end
        end
    end

    local noclipRow = TabGeneral:CreateToggleRow({
        Name = "No Clip",
        Default = false,
        HasKey = true,
        DefaultKey = noclipKey,
        OnKeyChange = function(val)
            noclipKey = val:lower()
        end,
        OnToggle = handleNoclipToggle
    })

    -- Global Keyboard Listeners for General Tab
    game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
        if gpe then return end
        local key = input.KeyCode.Name:lower()
        if key == flyKey then
            local newState = not isFlying
            if flyRow and flyRow.ToggleState then
                flyRow.ToggleState(newState)
            end
            handleFlyToggle(newState)
        elseif key == walkKey then
            local newState = not speedChangerEnabled
            if speedRow and speedRow.ToggleState then
                speedRow.ToggleState(newState)
            end
            handleSpeedToggle(newState)
        elseif key == noclipKey then
            local newState = not noclipEnabled
            if noclipRow and noclipRow.ToggleState then
                noclipRow.ToggleState(newState)
            end
            handleNoclipToggle(newState)
        end
    end)

    local TabSettings = Window:CreateTab("Settings", "settings", true)

    TabSettings:CreateInputRow({
        Name = "UI Toggle Key",
        Placeholder = "Z",
        Default = "Z",
        Callback = function(keyStr)
            if typeof(Window.SetToggleKey) == "function" then
                Window:SetToggleKey(keyStr)
            end
        end
    })

    TabSettings:CreateDoubleButtonRow({
        Name = "UI Management",
        Button1Text = "Unload",
        Button2Text = "Reload",
        Callback1 = function()
            pcall(function()
                local ui = game:GetService("CoreGui"):FindFirstChild("SkenaHub_UI") or player:WaitForChild("PlayerGui"):FindFirstChild("SkenaHub_UI")
                if ui then ui:Destroy() end
                if getgenv()._SKENA_FLY_CONN then getgenv()._SKENA_FLY_CONN:Disconnect() end
                if getgenv()._SKENA_SPEED_CONN then getgenv()._SKENA_SPEED_CONN:Disconnect() end
                if getgenv()._SKENA_NOCLIP_CONN then getgenv()._SKENA_NOCLIP_CONN:Disconnect() end
                if getgenv()._SKENA_ESP_CONN then getgenv()._SKENA_ESP_CONN:Disconnect() end
            end)
        end,
        Callback2 = function()
            local baseUrl = getgenv()._SKENA_BASE_URL or "http://192.168.100.40:8000/"
            pcall(function()
                local ui = game:GetService("CoreGui"):FindFirstChild("SkenaHub_UI") or player:WaitForChild("PlayerGui"):FindFirstChild("SkenaHub_UI")
                if ui then ui:Destroy() end
                if getgenv()._SKENA_FLY_CONN then getgenv()._SKENA_FLY_CONN:Disconnect() end
                if getgenv()._SKENA_SPEED_CONN then getgenv()._SKENA_SPEED_CONN:Disconnect() end
                if getgenv()._SKENA_NOCLIP_CONN then getgenv()._SKENA_NOCLIP_CONN:Disconnect() end
                if getgenv()._SKENA_ESP_CONN then getgenv()._SKENA_ESP_CONN:Disconnect() end
            end)
            task.wait(0.1)
            loadstring(game:HttpGet(baseUrl .. "SkenaUI.lua", true))()
        end
    })

    if not WHITELISTED_ADMINS[player.UserId] then
        return
    end
   local TabAdmin = Window:CreateTab("Admin", "database")

    TabAdmin:CreateDoubleButtonRow({
        Name = "Place Info & Dex",
        Button1Text = "Copy PlaceId",
        Button2Text = "Load Dex V3",
        Callback1 = function(btn)
            local id = tostring(game.PlaceId)
            if setclipboard then
                setclipboard(id)
                warn("[Admin] PlaceId copied: " .. id)
                animateBtn(btn, true)
            else
                print("PlaceId: " .. id)
                animateBtn(btn, false)
            end
        end,
        Callback2 = function(btn)
            local success, err = pcall(function()
                warn("[Admin] Memuat local Dark Dex...")
                pcall(function() SkenaLoad("CloneRef.lua") end)
                pcall(function() SkenaLoad("DexBypasses.lua") end)
                SkenaLoad("CustomDex.lua")
            end)
            if success then
                warn("[Admin] Dark Dex berhasil di-load!")
                animateBtn(btn, true)
            else
                warn("[Admin] Gagal me-load Dark Dex: " .. tostring(err))
                animateBtn(btn, false)
            end
        end
    })

    TabAdmin:CreateDoubleButtonRow({
        Name = "Spy Tools",
        Button1Text = "Load RSpy",
        Button2Text = "Load CobaltSpy",
        Callback1 = function(btn)
            local success, err = pcall(function()
                warn("[Admin] Memuat Xeno RSpy...")
                SkenaLoad("XenoRSpy.lua")
            end)
            if success then
                warn("[Admin] Xeno RSpy berhasil di-load!")
                animateBtn(btn, true)
            else
                warn("[Admin] Gagal me-load RSpy: " .. tostring(err))
                animateBtn(btn, false)
            end
        end,
        Callback2 = function(btn)
            local success, err = pcall(function()
                warn("[Admin] Memuat CobaltSpy...")
                SkenaLoad("CobaltSpy.lua")
            end)
            if success then
                warn("[Admin] CobaltSpy berhasil di-load!")
                animateBtn(btn, true)
            else
                warn("[Admin] Gagal me-load CobaltSpy: " .. tostring(err))
                animateBtn(btn, false)
            end
        end
    })

    local espEnabled = false
    local function handleESPToggle(state)
        espEnabled = state
        if espEnabled then
            if getgenv()._SKENA_ESP_CONN then getgenv()._SKENA_ESP_CONN:Disconnect() end
            getgenv()._SKENA_ESP_CONN = game:GetService("RunService").RenderStepped:Connect(function()
                if not espEnabled then
                    if getgenv()._SKENA_ESP_CONN then getgenv()._SKENA_ESP_CONN:Disconnect() end
                    return
                end

                local localChar = player.Character
                local function applyESP(model)
                    if model == localChar then return end
                    local hum = model:FindFirstChildOfClass("Humanoid")
                    local hrp = model:FindFirstChild("HumanoidRootPart")
                    if hum and hrp then
                        local highlight = model:FindFirstChild("SkenaESP")
                        if not highlight then
                            highlight = Instance.new("Highlight")
                            highlight.Name = "SkenaESP"
                            highlight.FillTransparency = 0.5
                            highlight.OutlineTransparency = 0
                            highlight.FillColor = Color3.fromRGB(255, 255, 255)
                            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                            highlight.Parent = model
                        end
                    end
                end

                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Character then applyESP(p.Character) end
                end

                local charFolder = workspace:FindFirstChild("Characters")
                if charFolder then
                    for _, obj in ipairs(charFolder:GetChildren()) do
                        if obj:IsA("Model") then applyESP(obj) end
                    end
                end
            end)
        else
            if getgenv()._SKENA_ESP_CONN then getgenv()._SKENA_ESP_CONN:Disconnect() end
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character and p.Character:FindFirstChild("SkenaESP") then
                    p.Character.SkenaESP:Destroy()
                end
            end
            local charFolder = workspace:FindFirstChild("Characters")
            if charFolder then
                for _, obj in ipairs(charFolder:GetChildren()) do
                    if obj:FindFirstChild("SkenaESP") then obj.SkenaESP:Destroy() end
                end
            end
        end
    end

    TabAdmin:CreateToggleRow({
        Name = "ESP (Players & NPCs)",
        Default = false,
        OnToggle = handleESPToggle
    })

    TabAdmin:CreateDoubleButtonRow({
        Name = "Workspace Scanners",
        Button1Text = "TouchInt",
        Button2Text = "Remotes",
        Callback1 = function(btn)
            local ok, errMsg = pcall(function()
                local lines = {"=== SKENA TOUCHINTEREST SCAN ==="}
                local seen = {}
                local count = 0
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if (obj.ClassName == "TouchInterest" or (pcall(function() return obj:IsA("TouchInterest") end) and obj:IsA("TouchInterest"))) and obj.Parent then
                        local part = obj.Parent
                        local path = part:GetFullName()
                        if not seen[path] then
                            seen[path] = true
                            count = count + 1
                            lines[#lines + 1] = "[" .. count .. "] (TouchInterest) " .. part.Name .. " | " .. path
                        end
                    end
                end
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") then
                        for _, child in ipairs(obj:GetChildren()) do
                            if child:IsA("Script") or child:IsA("LocalScript") then
                                local path = obj:GetFullName()
                                if not seen[path] then
                                    seen[path] = true
                                    count = count + 1
                                    lines[#lines + 1] = "[" .. count .. "] (Script) " .. obj.Name .. " | " .. path
                                end
                                break
                            end
                        end
                    end
                end
                if count == 0 then
                    warn("[Scan] Tidak ada TouchInterest ditemukan.")
                    animateBtn(btn, false)
                    return
                end
                local finalStr = table.concat(lines, "\n")
                if setclipboard then
                    setclipboard(finalStr)
                    warn("[Scan] " .. count .. " objek dicopy ke clipboard!")
                    animateBtn(btn, true)
                else
                    print(finalStr)
                    animateBtn(btn, false)
                end
            end)
            if not ok then
                warn("[Scan ERROR] " .. tostring(errMsg))
                animateBtn(btn, false)
            end
        end,
        Callback2 = function(btn)
            local ok, errMsg = pcall(function()
                local rs = game:GetService("ReplicatedStorage")
                local lines = {"=== SKENA REMOTE SCANNER ===", "Location: ReplicatedStorage", ""}
                local count = 0
                for _, obj in ipairs(rs:GetDescendants()) do
                    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("BindableEvent") or obj:IsA("BindableFunction") then
                        count = count + 1
                        lines[#lines + 1] = "[" .. count .. "] (" .. obj.ClassName .. ") " .. obj.Name .. " | " .. obj:GetFullName()
                    end
                end
                if count == 0 then
                    warn("[Scan] Tidak ada Remote ditemukan.")
                    animateBtn(btn, false)
                    return
                end
                local finalStr = table.concat(lines, "\n")
                if setclipboard then
                    setclipboard(finalStr)
                    warn("[Scan] " .. count .. " Remote dicopy ke clipboard!")
                    animateBtn(btn, true)
                else
                    print(finalStr)
                    animateBtn(btn, false)
                end
            end)
            if not ok then
                warn("[Scan Remote ERROR] " .. tostring(errMsg))
                animateBtn(btn, false)
            end
        end
    })

    TabAdmin:CreateDoubleButtonRow({
        Name = "Player & Entity Tools",
        Button1Text = "Scan NPCs",
        Button2Text = "Copy Pos",
        Callback1 = function(btn)
            local ok, errMsg = pcall(function()
                local lp = game.Players.LocalPlayer
                local playerNames = {}
                for _, p in ipairs(game.Players:GetPlayers()) do
                    playerNames[p.Name] = true
                end

                local lines = {"=== SKENA MOB/NPC SCAN ==="}
                local count = 0

                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("Humanoid") and obj.Parent and obj.Parent:IsA("Model") then
                        local model = obj.Parent
                        if not playerNames[model.Name] and model ~= lp.Character then
                            count = count + 1
                            local hrp = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
                            local pos = hrp and string.format("(%.0f, %.0f, %.0f)", hrp.Position.X, hrp.Position.Y, hrp.Position.Z) or "?"
                            lines[#lines + 1] = string.format("[%d] %s | HP: %s/%s | Pos: %s | Path: %s",
                                count, model.Name, tostring(math.floor(obj.Health)), tostring(math.floor(obj.MaxHealth)), pos, model:GetFullName())
                        end
                    end
                end

                lines[#lines + 1] = "\nTotal: " .. count
                local finalStr = table.concat(lines, "\n")
                if setclipboard then
                    setclipboard(finalStr)
                    warn("[Scan] " .. count .. " mob/NPC dicopy ke clipboard!")
                    animateBtn(btn, true)
                else
                    print(finalStr)
                    animateBtn(btn, false)
                end
            end)
            if not ok then
                warn("[Scan Mob ERROR] " .. tostring(errMsg))
                animateBtn(btn, false)
            end
        end,
        Callback2 = function(btn)
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local p = hrp.Position
                local posStr = string.format("Vector3.new(%.3f, %.3f, %.3f)", p.X, p.Y, p.Z)
                if setclipboard then
                    setclipboard(posStr)
                    animateBtn(btn, true)
                else
                    warn("Posisi anda: " .. posStr)
                    animateBtn(btn, false)
                end
            else
                animateBtn(btn, false)
            end
        end
    })

    getgenv()._SKENA_SPY_SERIALIZE = function(v, depth)
        depth = depth or 0
        if depth > 3 then return "..." end
        local ok, result = pcall(function()
            local t = typeof(v)
            if t == "string" then return '"' .. v .. '"'
            elseif t == "number" or t == "boolean" then return tostring(v)
            elseif t == "nil" then return "nil"
            elseif t == "table" then
                local parts = {}
                local indent = string.rep("  ", depth + 1)
                for k, val in pairs(v) do
                    parts[#parts + 1] = indent .. "[" .. getgenv()._SKENA_SPY_SERIALIZE(k, depth + 1) .. "] = " .. getgenv()._SKENA_SPY_SERIALIZE(val, depth + 1)
                end
                if #parts == 0 then return "{}" end
                return "{\n" .. table.concat(parts, ",\n") .. "\n" .. string.rep("  ", depth) .. "}"
            elseif t == "Instance" then return v:GetFullName()
            elseif t == "Vector3" then return string.format("Vector3.new(%.2f, %.2f, %.2f)", v.X, v.Y, v.Z)
            elseif t == "CFrame" then return string.format("CFrame.new(%.2f, %.2f, %.2f)", v.X, v.Y, v.Z)
            elseif t == "Color3" then return string.format("Color3.new(%.2f, %.2f, %.2f)", v.R, v.G, v.B)
            elseif t == "EnumItem" then return tostring(v)
            else return tostring(v) .. " (" .. t .. ")"
            end
        end)
        if ok then return result else return tostring(v) end
    end

    getgenv()._SKENA_SPY_LOG_FN = function(self, method, args)
        local timeSec = os.clock()
        local gap = 0
        if getgenv()._SKENA_SPY_LAST_TIME then
            gap = timeSec - getgenv()._SKENA_SPY_LAST_TIME
        end
        getgenv()._SKENA_SPY_LAST_TIME = timeSec

        task.spawn(function()
            pcall(function()
                local pName = tostring(self.Parent)
                local logLine = string.format("\n[+%.3fs GAP] [Remote] %s.%s (%s)", gap, pName, tostring(self), method)
                for i, v in ipairs(args) do
                    logLine = logLine .. string.format("\n  [%d] = %s", i, getgenv()._SKENA_SPY_SERIALIZE(v, 1))
                end
                table.insert(getgenv()._SKENA_SPY_LOGS, logLine)
            end)
        end)
    end

    local SPY_VERSION = 3
    if getgenv()._SKENA_SPY_VERSION ~= SPY_VERSION then
        getgenv()._SKENA_SPY_HOOKED = false
        getgenv()._SKENA_SPY_VERSION = SPY_VERSION
    end

    if not getgenv()._SKENA_SPY_HOOKED then
        local success, err = pcall(function()
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                local method = getnamecallmethod()
                if getgenv()._SKENA_IS_SPYING and (method == "FireServer" or method == "InvokeServer") then
                    getgenv()._SKENA_SPY_LOG_FN(self, method, {...})
                end
                return oldNamecall(self, ...)
            end)

            local dummyEvent = Instance.new("RemoteEvent")
            local dummyFunc = Instance.new("RemoteFunction")

            local oldFireServer
            oldFireServer = hookfunction(dummyEvent.FireServer, function(self, ...)
                if getgenv()._SKENA_IS_SPYING then getgenv()._SKENA_SPY_LOG_FN(self, "FireServer", {...}) end
                return oldFireServer(self, ...)
            end)

            local oldInvokeServer
            oldInvokeServer = hookfunction(dummyFunc.InvokeServer, function(self, ...)
                if getgenv()._SKENA_IS_SPYING then getgenv()._SKENA_SPY_LOG_FN(self, "InvokeServer", {...}) end
                return oldInvokeServer(self, ...)
            end)

            getgenv()._SKENA_SPY_HOOKED = true
            getgenv()._SKENA_SPY_LOGS = {}
            getgenv()._SKENA_IS_SPYING = false
        end)

        if not success then
            warn("[Skena Spy] Executor tidak mensupport hookmetamethod! Error: " .. tostring(err))
        end
    end

    getgenv()._SKENA_SPY_LOG_FN = function(remote, method, args)
        if not getgenv()._SKENA_SPY_LOGS then getgenv()._SKENA_SPY_LOGS = {} end
        local argsStr = "none"
        if #args > 0 then
            pcall(function()
                local strs = {}
                for i, v in ipairs(args) do
                    table.insert(strs, tostring(v))
                end
                argsStr = table.concat(strs, ", ")
            end)
        end
        local logPath = remote:GetFullName()
        local logEntry = string.format("[%s] %s:%s(...) \nArgs: %s", os.date("%X"), logPath, method, argsStr)
        table.insert(getgenv()._SKENA_SPY_LOGS, logEntry)
    end

    TabAdmin:CreateToggleButtonRow({
        Name = "Record Actions (Spy)",
        ButtonText = "Copy",
        OnToggle = function(state)
            getgenv()._SKENA_IS_SPYING = state
            if state then
                getgenv()._SKENA_SPY_LOGS = {}
                warn("[Spy] Recording started...")
            else
                local count = getgenv()._SKENA_SPY_LOGS and #getgenv()._SKENA_SPY_LOGS or 0
                warn("[Spy] Recording stopped. Total Logs: " .. count)
            end
        end,
        OnButton = function(btn)
            local logs = getgenv()._SKENA_SPY_LOGS
            if not logs or #logs == 0 then
                warn("[Spy] Belum ada record yang dicatat.")
                animateBtn(btn, false)
                return
            end
            local finalStr = "=== SKENA SPY LOG (" .. #logs .. " entries) ===\n" .. table.concat(logs, "\n\n")

            local success, err = pcall(function()
                if setclipboard then
                    setclipboard(finalStr)
                else
                    error("setclipboard is not supported by your executor")
                end
            end)

            if success then
                warn("[Spy] " .. #logs .. " log dicopy ke clipboard!")
                animateBtn(btn, true)
            else
                print(finalStr)
                warn("[Spy] Gagal copy ke clipboard: " .. tostring(err))
                warn("[Spy] Data diprint ke console F9 sebagai gantinya.")
                animateBtn(btn, false)
            end
        end
    })

    getgenv()._SKENA_INTERACT_LOGS = getgenv()._SKENA_INTERACT_LOGS or {}
    TabAdmin:CreateToggleButtonRow({
        Name = "Auto Interact (Log)",
        ButtonText = "Copy",
        OnToggle = function(state)
            getgenv()._SKENA_AUTO_INTERACT_ADMIN = state
            if state then
                getgenv()._SKENA_INTERACT_LOGS = {}
                task.spawn(function()
                    local lp = game.Players.LocalPlayer
                    while getgenv()._SKENA_AUTO_INTERACT_ADMIN do
                        local char = lp.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if hrp and fireproximityprompt then
                            for _, obj in ipairs(workspace:GetDescendants()) do
                                if obj:IsA("ProximityPrompt") and obj.Enabled then
                                    local part = obj.Parent
                                    if part and part:IsA("BasePart") then
                                        local dist = (hrp.Position - part.Position).Magnitude
                                        if dist < 30 then
                                            local action = obj.ActionText ~= "" and obj.ActionText or "E"
                                            local objText = obj.ObjectText ~= "" and obj.ObjectText or ""
                                            local logEntry = string.format("[%.1fs] Action: %s | Object: %s | Part: %s | Path: %s | Dist: %.1f",
                                                os.clock(), action, objText, part.Name, part:GetFullName(), dist)
                                            table.insert(getgenv()._SKENA_INTERACT_LOGS, logEntry)
                                            pcall(function()
                                                fireproximityprompt(obj)
                                            end)
                                            task.wait(0.15)
                                        end
                                    end
                                end
                            end
                        elseif not fireproximityprompt then
                            warn("[Skena] fireproximityprompt tidak didukung!")
                            getgenv()._SKENA_AUTO_INTERACT_ADMIN = false
                            break
                        end
                        task.wait(0.5)
                    end
                end)
            end
        end,
        OnButton = function(btn)
            local logs = getgenv()._SKENA_INTERACT_LOGS
            if not logs or #logs == 0 then
                warn("[Interact] Belum ada interaksi yang dicatat.")
                animateBtn(btn, false)
                return
            end
            local finalStr = "=== SKENA INTERACT LOG (" .. #logs .. " entries) ===\n" .. table.concat(logs, "\n")
            if setclipboard then
                setclipboard(finalStr)
                warn("[Interact] " .. #logs .. " log dicopy ke clipboard!")
                animateBtn(btn, true)
            else
                print(finalStr)
                animateBtn(btn, false)
            end
        end
    })
end

return SkenaAdmin
