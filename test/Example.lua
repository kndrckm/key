-- Example Script for SkenaUI Revamp (Textured Sidebar)
local SkenaUI = loadstring(game:HttpGet("http://localhost:8000/test/SkenaUI_Library.lua"))()

local Window = SkenaUI:CreateWindow({
    Name = "Skena Glass Revamp Test",
    -- The new Glassmorphic style is now the default for Sidebar
})


local Tab1 = Window:CreateTab("Home", "home")
Tab1:CreateInputRow({
    Name = "Test Input",
    Placeholder = "Type something...",
    Callback = function(val)
        print("Input: " .. val)
    end
})

local Tab2 = Window:CreateTab("Settings", "settings", true)
print("SkenaUI Revamp Loaded with Textured Sidebar!")
