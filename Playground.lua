--[[
    Playground for my LUA scripts
]]

local Utils = require("Utils")
local UI = require("UI")

-- Utils
print(Utils.ID3toID64("[U:1:347654006]"))
print(Utils.ID64toID3("76561198307919734"))

-- UI
UI.AddText(50, 50, "[ LmaoBox ]", Colors.YELLOW, true)