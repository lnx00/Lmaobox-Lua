--[[
    WinUI 3 Concept for Lmaobox
    Author: LNX (github.com/lnx00)
]]

---@type lnxLib
local lnxLib = require("lnxLib")
local Input, KeyHelper = lnxLib.Utils.Input, lnxLib.Utils.KeyHelper
local Textures = lnxLib.UI.Textures

---@alias Context { Rect: number[] }

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
    BodyStrong = draw.CreateFont("Segoe UI Variable Text", 20, FontWeight.SemiBold),
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

    -- Used for text on accent colored controls or fills
    TextOnAccent = {
        Primary = { 0, 0, 0 }, -- Rest or Hover
        Secondary = { 16, 16, 16 }, -- Pressed only
        Disabled = { 150, 150, 150 }, -- Disabled only
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

    -- Used for control strokes that must meet contrast ratio requirements of 3:1
    ControlStrongStroke = {
        Default = { 154, 154, 154 },
        Disabled = { 67, 67, 67 },
    },

    -- Used to create 'cards' - content blocks that live on page and layer background
    CardBackground = {
        Default = { 43, 43, 43 }, -- Default card color
        Secondary = { 39, 39, 39 }, -- Alternate card color
    },

    -- Solid background colors to place layers, card or controls on
    SolidBackground = {
        Base = { 32, 32, 32, 254 }, -- Used for the bottom most layer of an experience
        BaseAlt = { 10, 10, 10 }, -- Used for the bottom most layer of an experience
        Secondary = { 28, 28, 28 }, -- Alternate base color for those who need a darker background color
        Tertiary = { 40, 40, 40 }, -- Content layer color
        Quaternary = { 44, 44, 44 }, -- Alt content layer color
    }
}

local Flags = {
    None = 0,
    Accent = 1 << 0,
    Strong = 1 << 1,
    LeftAlign = 1 << 2,
}

--[[ Vars ]]

local mouseHelper = KeyHelper.new(MOUSE_LEFT)
local currentId = 0

local circle = Textures.Circle(16, { 255, 255, 255, 255 })

local Style = {
    HeaderSize = 50,
    FramePadding = 10,
    ItemPadding = 5,
    Circles = true
}

--[[ Utils ]]

local function GetUniqueId()
    currentId = currentId + 1
    return currentId
end

---@param color number[]
local function SetColor(color)
    draw.Color(color[1], color[2], color[3], color[4] or 255)
end

local function DrawCircle(x, y, r)
    draw.TexturedRect(circle, x - r, y - r, x + r, y + r)
end

local function RoundedRect(x1, y1, x2, y2, r, color)
    local _r, _g, _b, _a = color[1], color[2], color[3], color[4] or 255
    draw.Color(_r, _g, _b, _a)

    if Style.Circles then
        DrawCircle(x1 + r, y1 + r, r)
        DrawCircle(x2 - r, y1 + r, r)
        DrawCircle(x1 + r, y2 - r, r)
        DrawCircle(x2 - r, y2 - r, r)
    
        draw.FilledRect(x1 + r, y1, x2 - r, y2)
        draw.FilledRect(x1, y1 + r, x2, y2 - r)
    else
        draw.FilledRect(x1, y1, x2, y2)
    end
end

--[[ Components ]]

local CCard = {
    ID = 0,
    Visible = true,
    Pos = { 300, 500 },
    Size = { 160, 32 },
    Name = nil,
    Flags = Flags.None,
    Components = {}
}
CCard.__index = CCard

function CCard.new(pos, size, name, flags)
    local self = setmetatable({}, CCard)
    self.ID = GetUniqueId()
    self.Visible = true
    self.Pos = pos or { 300, 500 }
    self.Size = size or { 160, 32 }
    self.Name = name or nil
    self.Flags = flags or Flags.None
    self.Components = {}

    return self
end

function CCard:AddComponent(component)
    table.insert(self.Components, component)
end

function CCard:Draw(ctx)
    local x1, y1 = ctx.Pos[1] + self.Pos[1], ctx.Pos[2] + self.Pos[2]
    local w = (self.Size[1] <= 0) and (ctx.Size[1] - self.Pos[1] + self.Size[1]) or self.Size[1]
    local h = (self.Size[2] <= 0) and (ctx.Size[2] - self.Pos[2] + self.Size[2]) or self.Size[2]
    local x2, y2 = x1 + w, y1 + h

    -- Background
    local bgColor = Colors.CardBackground.Secondary
    RoundedRect(x1, y1, x2, y2, 10, bgColor)

    -- Title
    local yOffset = 0
    if self.Name then
        draw.SetFont(Fonts.Subtitle)
        SetColor(Colors.Text.Primary)
        local tw, th = draw.GetTextSize(self.Name)
        draw.Text(x1 + Style.FramePadding, y1 + Style.FramePadding, self.Name)
        yOffset = th + Style.FramePadding
    end

    -- Draw components
    local ctx2 = { Pos = { x1 + Style.FramePadding, y1 + yOffset + Style.FramePadding } }
    for _, component in ipairs(self.Components) do
        component:Draw(ctx2)
    end
end

local CButton = {
    ID = 0,
    Visible = true,
    Pos = { 300, 500 },
    Size = { 160, 32 },
    Text = "Button",
    OnClick = function() end,
    Flags = Flags.None
}
CButton.__index = CButton

function CButton.new(pos, size, text, onClick, flags)
    local self = setmetatable({}, CButton)
    self.ID = GetUniqueId()
    self.Visible = true
    self.Pos = pos or { 300, 500 }
    self.Size = size or { 160, 32 }
    self.Text = text or "Button"
    self.OnClick = onClick or function() end
    self.Flags = flags or Flags.None

    return self
end

function CButton:Draw(ctx)
    local x1, y1 = ctx.Pos[1] + self.Pos[1], ctx.Pos[2] + self.Pos[2]
    local w, h = self.Size[1], self.Size[2]
    local x2, y2 = x1 + w, y1 + h
    local mib = Input.MouseInBounds(x1, y1, x2, y2)

    -- Options
    local accent = self.Flags & Flags.Accent ~= 0
    local strong = self.Flags & Flags.Strong ~= 0

    -- Background
    local bgColor = accent and Colors.AccentFill.Default or Colors.ControlFill.Default
    if mib then
        if mouseHelper:Down() then
            bgColor = accent and Colors.AccentFill.Tertiary or Colors.ControlFill.Tertiary
        else
            bgColor = accent and Colors.AccentFill.Secondary or Colors.ControlFill.Secondary
        end
    end

    RoundedRect(x1, y1, x2, y2, 7, bgColor)

    -- Text
    draw.SetFont(strong and Fonts.BodyStrong or Fonts.Body)
    SetColor(accent and Colors.TextOnAccent.Primary or Colors.Text.Primary)
    local tw, th = draw.GetTextSize(self.Text)
    draw.Text(x1 + w // 2 - tw // 2, y1 + h // 2 - th // 2, self.Text)

    -- Interaction
    if mib and mouseHelper:Released() then
        self.OnClick()
    end
end

local CCheckbox = {
    ID = 0,
    Visible = true,
    Pos = { 300, 500 },
    Text = "Checkbox",
    Value = false,
    Checked = false,
    OnChange = function(v) end,
    Flags = Flags.None
}
CCheckbox.__index = CCheckbox

function CCheckbox.new(pos, text, value, onChange, flags)
    local self = setmetatable({}, CCheckbox)
    self.ID = GetUniqueId()
    self.Visible = true
    self.Pos = pos or { 300, 500 }
    self.Text = text or "Checkbox"
    self.Value = value or false
    self.Checked = value or false
    self.OnChange = onChange or function(v) end
    self.Flags = flags or Flags.None

    return self
end

function CCheckbox:Draw(ctx)
    local x1, y1 = ctx.Pos[1] + self.Pos[1], ctx.Pos[2] + self.Pos[2]
    local w, h = 20, 20
    local x2, y2 = x1 + w, y1 + h

    draw.SetFont(Fonts.Body)
    local tw, th = draw.GetTextSize(self.Text)
    local mib = Input.MouseInBounds(x1, y1, x2 + tw + 2 * Style.ItemPadding, y2)

    -- Checkmark
    local chkColor = self.Checked and Colors.AccentFill.Default or Colors.ControlAltFill.Secondary
    if mib then
        if mouseHelper:Down() then
            chkColor = self.Checked and Colors.AccentFill.Tertiary or Colors.AccentFill.Secondary
        else
            chkColor = self.Checked and Colors.AccentFill.Secondary or Colors.ControlAltFill.Tertiary
        end
    end

    RoundedRect(x1, y1, x2, y2, 7, Colors.ControlStrongStroke.Default)
    RoundedRect(x1 + 1, y1 + 1, x2 - 1, y2 - 1, 7, chkColor)

    -- Text
    SetColor(Colors.Text.Primary)
    draw.Text(x1 + w + Style.ItemPadding, y1 + h // 2 - th // 2, self.Text)

    -- Interaction
    if mib and mouseHelper:Released() then
        self.Checked = not self.Checked
        self.OnChange(self.Checked)
    end
end

local CSwitch = {
    ID = 0,
    Visible = true,
    Pos = { 300, 500 },
    Text = "Switch",
    Value = false,
    Checked = false,
    OnChange = function(v) end,
    Flags = Flags.None
}
CSwitch.__index = CSwitch

function CSwitch.new(pos, text, value, onChange, flags)
    local self = setmetatable({}, CSwitch)
    self.ID = GetUniqueId()
    self.Visible = true
    self.Pos = pos or { 300, 500 }
    self.Text = text or "Switch"
    self.Value = value or false
    self.Checked = value or false
    self.OnChange = onChange or function(v) end
    self.Flags = flags or Flags.None

    return self
end

function CSwitch:Draw(ctx)
    local x1, y1 = ctx.Pos[1] + self.Pos[1], ctx.Pos[2] + self.Pos[2]
    local w, h = 40, 20
    local x2, y2 = x1 + w, y1 + h

    draw.SetFont(Fonts.Body)
    local tw, th = draw.GetTextSize(self.Text)
    local mib = Input.MouseInBounds(x1, y1, x2 + tw + 2 * Style.ItemPadding, y2)

    -- Background
    local bgColor = self.Checked and Colors.AccentFill.Default or Colors.ControlAltFill.Secondary
    if mib then
        if input.IsButtonDown(MOUSE_LEFT) then
            bgColor = self.Checked and Colors.AccentFill.Tertiary or Colors.AccentFill.Secondary
        else
            bgColor = self.Checked and Colors.AccentFill.Secondary or Colors.ControlAltFill.Tertiary
        end
    end

    RoundedRect(x1, y1, x2, y2, 7, Colors.ControlStrongStroke.Default)
    RoundedRect(x1 + 1, y1 + 1, x2 - 1, y2 - 1, 15, bgColor)

    -- Switch
    if self.Checked then
        draw.ColoredCircle(x2 - 10, y1 + 10, 7, 0, 0, 0, 255)
    else
        draw.ColoredCircle(x1 + 10, y1 + 10, 7, 204, 204, 204, 255)
    end

    -- Text
    SetColor(Colors.Text.Primary)
    draw.Text(x1 + w + Style.ItemPadding, y1 + h // 2 - th // 2, self.Text)

    -- Interaction
    if mib then
        if mouseHelper:Released() then
            self.Checked = not self.Checked
            self.OnChange(self.Checked)
        end
    end
end

local CNavView = {
    ID = 0,
    Visible = true,
    Flags = Flags.None,
    Views = {},
    CurrentView = nil,
    _Buttons = {},
    _Frame = nil,
    _CurrentY = 0, -- TODO: This is a hack
}
CNavView.__index = CNavView

function CNavView.new(views, flags)
    local self = setmetatable({}, CNavView)
    self.ID = GetUniqueId()
    self.Visible = true
    self.Flags = flags or Flags.None
    self.Views = views or {}
    self.CurrentView = views and views[1] or nil
    self._Buttons = {}
    self._Frame = CCard.new({ 0, 0 }, { 0, 0 }) -- TODO: Use a frame component

    for _, view in ipairs(self.Views) do
        self:AddView(view)
    end

    return self
end

function CNavView:Show(view)
    print("Switched to: " .. view.Name)
    self.CurrentView = view
end

function CNavView:AddView(view)
    assert(view.Name, "View must have a name")

    local btn = CButton.new({ 0, self._CurrentY }, { 190, 32 }, view.Name, function() self:Show(view) end)
    table.insert(self._Buttons, btn)

    self._CurrentY = self._CurrentY + 32 + Style.ItemPadding
    --table.insert(self.Views, view)
end

function CNavView:Draw(ctx)
    local x1, y1 = ctx.Pos[1], ctx.Pos[2]
    local w, h = ctx.Size[1], ctx.Size[2]
    local x2, y2 = x1 + w, y1 + h

    -- Buttons
    for _, btn in ipairs(self._Buttons) do
        -- TODO: Button offset
        btn:Draw(ctx)
    end

    -- View
    if self.CurrentView then
        local viewCtx = { Pos = { x1 + 200 + Style.FramePadding, y1 }, Size = { w - 200 - Style.FramePadding, h } }
        self.CurrentView:Draw(viewCtx)
    end
end

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

function CWindow:AddComponent(component)
    table.insert(self.Components, component)
end

function CWindow:Draw()
    local x1, y1 = self.Pos[1], self.Pos[2]
    local w, h = self.Size[1], self.Size[2]
    local x2, y2 = x1 + w, y1 + h

    -- Background
    --RoundedRect(x1, y1, x2, y2, 15, Colors.SolidBackground.Base)
    SetColor(Colors.SolidBackground.Base)
    draw.FilledRect(x1, y1, x2, y2)

    -- Content frame (TODO: Move to a component)
    --local lp = 200 + Style.FramePadding
    --RoundedRect(x1 + lp, y1 + Style.HeaderSize, x2 - Style.FramePadding, y2 - Style.FramePadding, 15, Colors.CardBackground.Secondary)

    -- Title
    draw.SetFont(Fonts.Title)
    SetColor(Colors.Text.Secondary)
    draw.Text(x1 + 2 * Style.FramePadding, y1 + Style.FramePadding, self.Title)

    -- Text
    --SetColor(Colors.Text.Primary)
    --draw.SetFont(Fonts.Subtitle)
    --draw.Text(x1 + lp + 2 * Style.FramePadding, y1 + Style.HeaderSize + Style.FramePadding, "Subtitle")

    -- Draw components
    local ctx = { Pos = { x1 + Style.FramePadding, y1 + Style.HeaderSize }, Size = { w - 2 * Style.FramePadding, h - Style.HeaderSize - Style.FramePadding } }
    for _, component in ipairs(self.Components) do
        component:Draw(ctx)
    end
end

--[[ Callbacks ]]

local window = CWindow.new({ 450, 120 }, { 900, 500 }, "WinUi Demo")
local card1 = CCard.new({ 0, 0 }, { 0, 0 }, "Card 1")
local card2 = CCard.new({ 0, 0 }, { 0, 0 }, "Card 2")
local navView = CNavView.new({ card1, card2 })

window:AddComponent(navView)
--window:AddComponent(card1)

local button1 = CButton.new({ 0, 0 }, { 190, 32 }, "Aimbot", function() print("Button 1 clicked") end)
local button2 = CButton.new({ 0, 37 }, { 190, 32 }, "ESP", function() print("Button 2 clicked") end)
local button3 = CButton.new({ 0, 74 }, { 190, 32 }, "Misc", function() print("Button 3 clicked") end)
local button4 = CButton.new({ 0, 405 }, { 190, 32 }, "Reload", function() LoadScript(GetScriptName()) end, Flags.Accent)

--window:AddComponent(button1)
--window:AddComponent(button2)
--window:AddComponent(button3)
window:AddComponent(button4)

local check1 = CCheckbox.new({ 0, 0 }, "Checkbox 1", false, function(value) print("Checkbox 1 changed to " .. tostring(value)) end)
local check2 = CCheckbox.new({ 0, 30 }, "Checkbox 2", true, function(value) print("Checkbox 2 changed to " .. tostring(value)) end)

card1:AddComponent(check1)
card1:AddComponent(check2)

local switch1 = CSwitch.new({ 0, 60 }, "Enable input", input.IsMouseInputEnabled(), function(value) input.SetMouseInputEnabled(value) end)

card1:AddComponent(switch1)

local function OnDraw()
    window:Draw()
end

local function OnUnload()
    draw.DeleteTexture(circle)
end

callbacks.Unregister("Draw", "LNX.ModernUI.Draw")
callbacks.Register("Draw", "LNX.ModernUI.Draw", OnDraw)

callbacks.Unregister("Unload", "LNX.ModernUI.Unload")
callbacks.Register("Unload", "LNX.ModernUI.Unload", OnUnload)