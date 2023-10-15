--[[
    WinUI 3 Concept for Lmaobox
    Author: LNX (github.com/lnx00)
]]

---@type lnxLib
local lnxLib = require("lnxLib")

--[[ Constants ]]

local FontWeight = {
    Thin = 100,
    ExtraLight = 200,
    Light = 300,
    Regular = 400,
    Medium = 500,
    SemiBold = 600,
    Bold = 700,
    Black = 900
}

local Fonts = {
    Caption = draw.CreateFont("Segoe UI Variable Small", 16, FontWeight.Regular),
    Body = draw.CreateFont("Segoe UI Variable Text", 20, FontWeight.Regular),
    Subtitle = draw.CreateFont("Segoe UI Variable Display", 28, FontWeight.SemiBold),
    Title = draw.CreateFont("Segoe UI Variable Display", 36, FontWeight.SemiBold),
    Display = draw.CreateFont("Segoe UI Variable Display", 92, FontWeight.SemiBold),
}

-- Dark Theme
local Colors = {
    -- For UI labels and static text
    Text = {
        Primary = { 255, 255, 255 }, -- Rest or Hover
        Secondary = { 204, 204, 204 }, -- Rest or Hover
        Tertiary = { 150, 150, 150 }, -- Pressed only
        Disabled = { 113, 113, 113 } -- Disabled only
    },

    -- Recommended for links
    AccentText = {
        Primary = { 166, 216, 255 }, -- Rest or Hover
        Secondary = { 166, 216, 255 }, -- Rest or Hover
        Tertiary = { 118, 185, 237 }, -- Pressed only
        Disabled = { 113, 113, 113 } -- Disabled only
    },

    -- Fill used for standard controls
    ControlFill = {
        Default = { 45, 45, 45 }, -- Rest
        Secondary = { 50, 50, 50 }, -- Hover
        Tertiary = { 39, 39, 39 }, -- Pressed
        Disabled = { 42, 42, 42 }, -- Disabled
    },

    -- Fill used for the 'off' states of toggle controls
    ControlAltFill = {
        Transparent = { 32, 32, 32 },
        Secondary = { 29, 29, 29 }, -- Rest
        Tertiary = { 42, 42, 42 }, -- Hover
        Quarternary = { 48, 48, 48 }, -- Pressed
        Disabled = { 32, 32, 32 }, -- Disabled
    },

    -- Used for accent fills on controls
    AccentFill = {
        Default = { 118, 185, 237 }, -- Rest
        Secondary = { 109, 169, 216 }, -- Hover
        Tertiary = { 100, 154, 195 }, -- Pressed
        Disabled = { 67, 67, 67 }, -- Disabled
    },

    -- Used to create 'cards' - content blocks that live on page and layer background
    CardBackground = {
        Default = { 43, 43, 43 }, -- Default card color
        Secondary = { 39, 39, 39 }, -- Alternate card color
    },

    -- Solid background colors to place layers, card or controls on
    SolidBackground = {
        Base = { 32, 32, 32 }, -- Used for the bottom most layer of an experience
        BaseAlt = { 10, 10, 10 }, -- Used for the bottom most layer of an experience
        Secondary = { 28, 28, 28 }, -- Alternate base color for those who need a darker background color
        Tertiary = { 40, 40, 40 }, -- Content layer color
        Quaternary = { 44, 44, 44 }, -- Alt content layer color
    }
}

--[[ Vars ]]

local currentId = 0

--[[ Utils ]]

local function GetUniqueId()
    currentId = currentId + 1
    return currentId
end

---@param color number[]
local function SetColor(color)
    draw.Color(color[1], color[2], color[3], color[4] or 255)
end

local function RoundedRect(x, y, w, h, r, color)
    SetColor(color)
    draw.ColoredCircle(x + r, y + r, r, color[1], color[2], color[3], color[4] or 255)
    draw.ColoredCircle(x + w - r, y + r, r, color[1], color[2], color[3], color[4] or 255)
    draw.ColoredCircle(x + w - r, y + h - r, r, color[1], color[2], color[3], color[4] or 255)
    draw.ColoredCircle(x + r, y + h - r, r, color[1], color[2], color[3], color[4] or 255)

    draw.FilledRect(x + r, y, x + w - r, y + h)
    draw.FilledRect(x, y + r, x + w, y + h - r)
end

--[[ Components ]]

local CWindow = {
    ID = 0,
    Visible = true,
    Pos = { 50, 50 },
    Size = { 400, 250 },
    Title = "",
    Components = {}
}
CWindow.__index = CWindow

-- Create a new window
function CWindow.new(pos, size, title)
    local self = setmetatable({}, CWindow)
    self.ID = GetUniqueId()
    self.Visible = true
    self.Pos = pos or { 50, 50 }
    self.Size = size or { 400, 250 }
    self.Title = title or "New Window"
    self.Components = {}

    return self
end

function CWindow:Draw()
    -- Background
    --RoundedRect(self.Pos[1], self.Pos[2], self.Size[1], self.Size[2], 15, Colors.SolidBackground.Base)
    SetColor(Colors.SolidBackground.Base)
    draw.FilledRect(self.Pos[1], self.Pos[2], self.Pos[1] + self.Size[1], self.Pos[2] + self.Size[2])

    RoundedRect(self.Pos[1] + 200, self.Pos[2] + 55, self.Size[1] - 210, self.Size[2] - 65, 15, Colors.CardBackground.Secondary)

    -- Text
    draw.SetFont(Fonts.Title)
    SetColor(Colors.Text.Secondary)
    draw.Text(self.Pos[1] + 20, self.Pos[2] + 10, "System >")
    SetColor(Colors.Text.Primary)
    draw.Text(self.Pos[1] + 145, self.Pos[2] + 10, "Power & battery")

    draw.SetFont(Fonts.Display)
    SetColor(Colors.Text.Primary)
    draw.Text(self.Pos[1] + 30, self.Pos[2] + 100, "23%")
    draw.SetFont(Fonts.Body)
    SetColor(Colors.Text.Secondary)
    draw.Text(self.Pos[1] + 30, self.Pos[2] + 180, "Average Time to charge:")
    SetColor(Colors.Text.Primary)
    draw.Text(self.Pos[1] + 200, self.Pos[2] + 180, "5h 23min")
end

--[[ Callbacks ]]

local window = CWindow.new({ 100, 120 }, { 900, 500 }, "WinUi Demo")

local function OnDraw()
    window:Draw()
end

callbacks.Unregister("Draw", "LNX.ModernUI.Draw")
callbacks.Register("Draw", "LNX.ModernUI.Draw", OnDraw)