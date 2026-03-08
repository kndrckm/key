local Player = game:GetService("Players")
local LocalPlayer = Player.LocalPlayer
local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local camera = workspace.CurrentCamera
local TreesFolder = workspace:WaitForChild("Map"):WaitForChild("Foliage")

local valueAxe = "1_" .. LocalPlayer.UserId

for _, v in ipairs(workspace.Map.Foliage:GetChildren()) do
	local char = char:FindFirstChild("HumanoidRootPart")
	if v.Name == "Small Tree" and v:FindFirstChild("Trunk")then
		if (char.Position - v.Trunk.Position).Magnitude < 20 then
			ReplicatedStorage.RemoteEvents.ToolDamageObject:InvokeServer(v,
				game:GetService("Players").LocalPlayer:WaitForChild("Inventory"):WaitForChild("Old Axe"),
				valueAxe,
				CFrame.new(23.124, 3.939, -36.213))
		end
	end
end
local ESPs = {}

local function createESP(tree)
	if ESPs[tree] then return end

	local trunk = tree:FindFirstChild("Trunk") or tree.PrimaryPart
	if not trunk then return end

	local bb = Instance.new("BillboardGui")
	bb.Name = "TreeESP"
	bb.Size = UDim2.fromScale(4, 1)
	bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.AlwaysOnTop = true
	bb.Parent = trunk

	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.TextScaled = true
	text.Font = Enum.Font.GothamBold
	text.TextStrokeTransparency = 0
	text.TextColor3 = Color3.fromRGB(0, 255, 0)
	text.Parent = bb

	ESPs[tree] = {
		gui = bb,
		label = text
	}
end

local function updateESP(tree)
	local esp = ESPs[tree]
	if not esp then return end

	local hp = tree:GetAttribute("Health")
	if not hp then
		esp.gui:Destroy()
		ESPs[tree] = nil
		return
	end

	esp.label.Text = ("HP: %d"):format(hp)

	-- เปลี่ยนสีตามเลือด
	if hp > 5 then
		esp.label.TextColor3 = Color3.fromRGB(0, 255, 0)
	elseif hp > 2 then
		esp.label.TextColor3 = Color3.fromRGB(255, 170, 0)
	else
		esp.label.TextColor3 = Color3.fromRGB(255, 0, 0)
	end
end

-- 🔄 Loop
task.spawn(function()
	while task.wait(0.2) do
		for _, tree in ipairs(TreesFolder:GetChildren()) do
			if tree.Name == "Small Tree" then
				createESP(tree)
				updateESP(tree)
			end
		end
	end
end)
