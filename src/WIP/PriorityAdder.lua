--[[
    Priority Adder for Lmaobox
    Author: LNX (github.com/lnx00)
]]

local Options = {
    Priority = 10,              -- The priority for the new entries
    Override = false,           -- Override existing priorities
    File = "playerlist.txt"     -- The file with the priorities
}

local function ReadFile(path)
    local file = io.open(path, "rb") -- r read mode and b binary mode
    if not file then return nil end
    local content = file:read "*a" -- *a or *all reads the whole file
    file:close()
    return content
end

local playerList = ReadFile(Options.File)
for line in playerList:gmatch("[^\r\n]+") do
    local prio = playerlist.GetPriority(line)
    playerlist.SetPriority(line, Options.Priority)
end