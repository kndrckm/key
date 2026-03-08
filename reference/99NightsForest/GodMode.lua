local rs = game:GetService("ReplicatedStorage")
local dmgEvent = rs:FindFirstChild("RemoteEvents") and rs.RemoteEvents:FindFirstChild("DamagePlayer")

if dmgEvent then
    dmgEvent:FireServer(-math.huge)
else
    warn("load in first m8")
end
