-- ==========================================
-- SKENA HUB : Defend Your Base From 67
-- Game ID: 102669100769936, 97689234675651
-- ==========================================
local SkenaUI = getgenv().SkenaLoad("SkenaUI_Library.lua")

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local Window = SkenaUI.CreateWindow("SkenaHub", "Defend Your Base 67", false)
local TabMain = Window:CreateTab("DefendYourBase67", "shield", false)
local TabSettings = Window:CreateTab("Settings", "settings", true)