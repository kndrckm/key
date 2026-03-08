--Remote spy Fixed & Updated
local G2L = {};
local ignoredRemotes = {} 
local currentSelectedRemoteName = ""

_G.Code = ""

-- StarterGui.Remote Spy
G2L["1"] = Instance.new("ScreenGui", game.CoreGui);
G2L["1"]["Name"] = [[Remote Spy]];
G2L["1"]["ResetOnSpawn"] = false
G2L["1"]["ZIndexBehavior"] = Enum.ZIndexBehavior.Sibling;

-- StarterGui.Remote Spy.Frame
G2L["2"] = Instance.new("Frame", G2L["1"]);
G2L["2"]["BorderSizePixel"] = 0;
G2L["2"]["BackgroundColor3"] = Color3.fromRGB(38, 36, 39); -- Darker background
G2L["2"]["Size"] = UDim2.new(0, 425, 0, 253);
G2L["2"]["Position"] = UDim2.new(0.02067, 0, 0.17804, 0);

-- StarterGui.Remote Spy.Frame.TopBar
G2L["3"] = Instance.new("Frame", G2L["2"]);
G2L["3"]["BorderSizePixel"] = 0;
G2L["3"]["BackgroundColor3"] = Color3.fromRGB(30, 30, 30);
G2L["3"]["Size"] = UDim2.new(1, 0, 0, 18);
G2L["3"]["Name"] = [[TopBar]];

-- StarterGui.Remote Spy.Frame.TopBar.Name
G2L["4"] = Instance.new("TextLabel", G2L["3"]);
G2L["4"]["BackgroundTransparency"] = 1;
G2L["4"]["TextSize"] = 14;
G2L["4"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
G2L["4"]["Size"] = UDim2.new(0, 100, 1, 0);
G2L["4"]["Text"] = [[ Remote Spy (P to hide)]];
G2L["4"]["TextXAlignment"] = Enum.TextXAlignment.Left;

-- StarterGui.Remote Spy.Frame.TopBar.X
G2L["5"] = Instance.new("TextButton", G2L["3"]);
G2L["5"]["BackgroundColor3"] = Color3.fromRGB(30, 30, 30);
G2L["5"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
G2L["5"]["Size"] = UDim2.new(0, 24, 1, 0);
G2L["5"]["Position"] = UDim2.new(1, -24, 0, 0);
G2L["5"]["Text"] = [[X]];

-- Buttons Container
G2L["6"] = Instance.new("Frame", G2L["2"]);
G2L["6"]["BackgroundColor3"] = Color3.fromRGB(50, 50, 50);
G2L["6"]["Size"] = UDim2.new(0, 273, 0, 106);
G2L["6"]["Position"] = UDim2.new(0.35765, 0, 0.58103, 0);

-- Copy Code Button
G2L["9"] = Instance.new("TextButton", G2L["6"]);
G2L["9"]["Size"] = UDim2.new(0, 83, 0, 25);
G2L["9"]["BackgroundColor3"] = Color3.fromRGB(27, 27, 29);
G2L["9"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
G2L["9"]["Text"] = [[Copy Code]];

-- NEW: Block Button
G2L["block"] = Instance.new("TextButton", G2L["6"]);
G2L["block"]["Size"] = UDim2.new(0, 83, 0, 25);
G2L["block"]["Position"] = UDim2.new(0.35, 0, 0, 0);
G2L["block"]["BackgroundColor3"] = Color3.fromRGB(27, 27, 29);
G2L["block"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
G2L["block"]["Text"] = [[Block]];

-- Clear Button
G2L["d2"] = Instance.new("TextButton", G2L["6"]);
G2L["d2"]["Size"] = UDim2.new(0, 83, 0, 25);
G2L["d2"]["Position"] = UDim2.new(0.7, 0, 0, 0);
G2L["d2"]["BackgroundColor3"] = Color3.fromRGB(27, 27, 29);
G2L["d2"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
G2L["d2"]["Text"] = [[Clear]];

-- Scrolling Frame for Remotes
G2L["d"] = Instance.new("ScrollingFrame", G2L["2"]);
G2L["d"]["BackgroundColor3"] = Color3.fromRGB(54, 54, 56);
G2L["d"]["Size"] = UDim2.new(0, 152, 0, 236);
G2L["d"]["Position"] = UDim2.new(0, 0, 0.06719, 0);
G2L["d"]["CanvasSize"] = UDim2.new(0, 0, 0, 0);
G2L["d"]["AutomaticCanvasSize"] = Enum.AutomaticSize.Y;
G2L["d"]["ScrollBarThickness"] = 4;

G2L["10"] = Instance.new("UIListLayout", G2L["d"]);
G2L["10"]["Padding"] = UDim.new(0, 2);

-- Remote Button Template
G2L["e"] = Instance.new("TextButton");
G2L["e"]["Size"] = UDim2.new(1, -5, 0, 22);
G2L["e"]["BackgroundColor3"] = Color3.fromRGB(70, 70, 70);
G2L["e"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
G2L["e"]["TextSize"] = 12;

-- Code Box (Description)
G2L["11"] = Instance.new("TextBox", G2L["2"]);
G2L["11"]["TextColor3"] = Color3.fromRGB(255, 255, 255); -- WHITE TEXT
G2L["11"]["BackgroundColor3"] = Color3.fromRGB(30, 30, 30);
G2L["11"]["Size"] = UDim2.new(0, 272, 0, 130);
G2L["11"]["Position"] = UDim2.new(0.35784, 0, 0.06719, 0);
G2L["11"]["TextXAlignment"] = Enum.TextXAlignment.Left;
G2L["11"]["TextYAlignment"] = Enum.TextYAlignment.Top;
G2L["11"]["MultiLine"] = true;
G2L["11"]["ClearTextOnFocus"] = false;
G2L["11"]["Text"] = "-- Select a remote to see code";

-- Logic
local UIS = game:GetService("UserInputService")

-- Minimize Shortcut (P)
UIS.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.P then
        G2L["2"].Visible = not G2L["2"].Visible
    end
end)

-- Dragging logic
local dragging, dragInput, dragStart, startPos
G2L["3"].InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = G2L["2"].Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        G2L["2"].Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

G2L["5"].MouseButton1Click:Connect(function() G2L["1"]:Destroy() end)
G2L["d2"].MouseButton1Click:Connect(function()
    for _, v in pairs(G2L["d"]:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
end)

G2L["9"].MouseButton1Click:Connect(function()
    if setclipboard then setclipboard(_G.Code) end
end)

-- Block logic
G2L["block"].MouseButton1Click:Connect(function()
    if currentSelectedRemoteName ~= "" then
        ignoredRemotes[currentSelectedRemoteName] = true
        for _, v in pairs(G2L["d"]:GetChildren()) do
            if v:IsA("TextButton") and v.Text == currentSelectedRemoteName then v:Destroy() end
        end
        G2L["11"].Text = "-- Blocked: " .. currentSelectedRemoteName
    end
end)

-- Hooking Engine (Original Style)
local function getPathToInstance(instance)
    local path = {}
    local current = instance
    while current and current ~= game do
        table.insert(path, 1, current.Name)
        current = current.Parent
    end
    return "game." .. table.concat(path, ".")
end

local function handleRemote(remote)
    local function logCall(...)
        if ignoredRemotes[remote.Name] then return end
        
        local args = {...}
        local formatted = {}
        for i, v in ipairs(args) do 
            formatted[i] = string.format("[%d] = %s", i, typeof(v) == "string" and '"'..v..'"' or tostring(v)) 
        end
        local argsString = table.concat(formatted, ",\n    ")
        
        local btn = G2L["e"]:Clone()
        btn.Text = remote.Name
        btn.Parent = G2L["d"]
        btn.MouseButton1Click:Connect(function()
            currentSelectedRemoteName = remote.Name
            local callType = remote:IsA("RemoteEvent") and "FireServer" or "InvokeServer"
            _G.Code = string.format("local args = {\n    %s\n}\n%s:%s(unpack(args))", argsString, getPathToInstance(remote), callType)
            G2L["11"].Text = _G.Code
        end)
    end

    if remote:IsA("RemoteEvent") then
        remote.OnClientEvent:Connect(logCall)
    elseif remote:IsA("RemoteFunction") then
        -- We log but don't overwrite OnClientInvoke to prevent breaking the game
        -- This style is safer for spotting "packs"
        task.spawn(function()
            while remote.Parent do
                remote.OnClientInvoke = function(...) logCall(...) return ... end
                task.wait(1)
            end
        end)
    end
end

local function wrapRemotes(folder)
    for _, obj in ipairs(folder:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then handleRemote(obj) end
    end
    folder.DescendantAdded:Connect(function(d)
        if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then handleRemote(d) end
    end)
end

local folders = {game.ReplicatedStorage, game.StarterGui, game.StarterPack, game.Players.LocalPlayer:WaitForChild("PlayerGui")}
for _, f in ipairs(folders) do wrapRemotes(f) end

return G2L["1"], require;
