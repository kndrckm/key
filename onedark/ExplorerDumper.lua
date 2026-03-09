local Dump = {}
local lines = {}
local count = 0

local function processNode(node, indentLevel)
    if not node then return end
    
    local indent = string.rep("  ", indentLevel)
    
    -- Try to safely get the name and class
    local ok, name = pcall(function() return node.Name end)
    local ok2, className = pcall(function() return node.ClassName end)
    
    if not ok then name = "[Restricted Name]" end
    if not ok2 then className = "[Restricted Class]" end

    count = count + 1
    table.insert(lines, string.format("%s[%s] %s", indent, className, name))
    
    -- Recursively scan children
    local ok3, children = pcall(function() return node:GetChildren() end)
    if ok3 and children then
        -- Sort alphabetically for easier reading
        table.sort(children, function(a, b)
            local aName = pcall(function() return a.Name end) and a.Name or "Z"
            local bName = pcall(function() return b.Name end) and b.Name or "Z"
            return aName < bName
        end)
        
        for _, child in ipairs(children) do
            processNode(child, indentLevel + 1)
        end
    end
end

warn("Starting Full Game Explorer Dump...")

-- Start the dump from the most important game services
local servicesToDump = {
    game:GetService("Workspace"),
    game:GetService("ReplicatedStorage"),
    game:GetService("Players"),
    game:GetService("Lighting"),
    game:GetService("StarterGui"),
    game:GetService("StarterPack"),
    game:GetService("StarterPlayer")
}

table.insert(lines, "=== FULL GAME EXPLORER DUMP ===")

for _, service in ipairs(servicesToDump) do
    processNode(service, 0)
    table.insert(lines, "") -- Empty line between major services
end

table.insert(lines, string.format("=== END OF DUMP | TOTAL OBJS: %d ===", count))

local finalDumpStr = table.concat(lines, "\n")

if setclipboard then
    setclipboard(finalDumpStr)
    warn(string.format("Perfect! Successfully copied %d instances to your clipboard.", count))
else
    warn("Executor does not support setclipboard! Printing to console instead (Warning: Might be truncated by Roblox Studio limits).")
    print(finalDumpStr)
end
