--[[
    WinUI 3 Concept for Lmaobox
    Author: LNX (github.com/lnx00)
    Credits: Microsoft WinUI 3 (https://learn.microsoft.com/en-us/windows/apps/winui/winui3/)
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
        Primary = { 255, 255, 255 },   -- Rest or Hover
        Secondary = { 204, 204, 204 }, -- Rest or Hover
        Tertiary = { 150, 150, 150 },  -- Pressed only
        Disabled = { 113, 113, 113 }   -- Disabled only
    },

    -- Recommended for links
    AccentText = {
        Primary = { 166, 216, 255 },   -- Rest or Hover
        Secondary = { 166, 216, 255 }, -- Rest or Hover
        Tertiary = { 118, 185, 237 },  -- Pressed only
        Disabled = { 113, 113, 113 }   -- Disabled only
    },

    -- Used for text on accent colored controls or fills
    TextOnAccent = {
        Primary = { 0, 0, 0 },        -- Rest or Hover
        Secondary = { 16, 16, 16 },   -- Pressed only
        Disabled = { 150, 150, 150 }, -- Disabled only
    },

    -- Fill used for standard controls
    ControlFill = {
        Default = { 45, 45, 45 },   -- Rest
        Secondary = { 50, 50, 50 }, -- Hover
        Tertiary = { 39, 39, 39 },  -- Pressed
        Disabled = { 42, 42, 42 },  -- Disabled
    },

    -- Fill used for the 'off' states of toggle controls
    ControlAltFill = {
        Transparent = { 32, 32, 32 },
        Secondary = { 29, 29, 29 },   -- Rest
        Tertiary = { 42, 42, 42 },    -- Hover
        Quarternary = { 48, 48, 48 }, -- Pressed
        Disabled = { 32, 32, 32 },    -- Disabled
    },

    -- Used for accent fills on controls
    AccentFill = {
        Default = { 118, 185, 237 },   -- Rest
        Secondary = { 109, 169, 216 }, -- Hover
        Tertiary = { 100, 154, 195 },  -- Pressed
        Disabled = { 67, 67, 67 },     -- Disabled
    },

    -- USed for gradient stops in elevation borders, and for control states.
    ControlStroke = {
        Default = { 48, 48, 48 },           -- Used in Control Elevation Brushes. Pressed or Disabled
        Secondary = { 53, 53, 53 },         -- Used in Control Elevation Brushes
        OnAccentDefault = { 49, 49, 49 },   -- Used in Control Elevation Brushes. Pressed or Disabled
        OnAccentSecondary = { 28, 28, 28 }, -- Used in Control Elevation Brushes
    },

    -- Used for control strokes that must meet contrast ratio requirements of 3:1
    ControlStrongStroke = {
        Default = { 154, 154, 154 },
        Disabled = { 67, 67, 67 },
    },

    -- Used to create 'cards' - content blocks that live on page and layer background
    CardBackground = {
        Default = { 43, 43, 43 },   -- Default card color
        Secondary = { 39, 39, 39 }, -- Alternate card color
    },

    -- Solid background colors to place layers, card or controls on
    SolidBackground = {
        Base = { 32, 32, 32 },       -- Used for the bottom most layer of an experience
        BaseAlt = { 10, 10, 10 },    -- Used for the bottom most layer of an experience
        Secondary = { 28, 28, 28 },  -- Alternate base color for those who need a darker background color
        Tertiary = { 40, 40, 40 },   -- Content layer color
        Quaternary = { 44, 44, 44 }, -- Alt content layer color
    }
}

local Flags = {
    None = 0,           -- Default
    Accent = 1 << 0,    -- Accent color
    Strong = 1 << 1,    -- Bold text
    LeftAlign = 1 << 2, -- Left text align
    Plain = 1 << 3,     -- No background
}

--[[ Vars ]]

local mouseHelper = KeyHelper.new(MOUSE_LEFT)
local currentId = 0
local activeId = nil
local dragPos = nil

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

---@return boolean hovered, boolean clicked, boolean active
local function GetInteraction(x1, y1, x2, y2, id)
    -- Is a different element active?
    if activeId ~= nil and activeId ~= id then
        return false, false, false
    end

    local hovered = Input.MouseInBounds(x1, y1, x2, y2) or id == activeId
    local clicked = hovered and (mouseHelper:Released())
    local active = hovered and (mouseHelper:Down())

    -- Should this element be active?
    if active and activeId == nil then
        activeId = id
    end

    -- Is this element no longer active?
    if activeId == id and not active then
        activeId = nil
    end

    return hovered, clicked, active
end

---@param color number[]
local function SetColor(color)
    draw.Color(color[1], color[2], color[3], color[4] or 255)
end

local function DrawCircle(x, y, r)
    draw.TexturedRect(circle, x - r, y - r, x + r, y + r)
end

local function RoundedRect(x1, y1, x2, y2, r)
    if not Style.Circles then
        draw.FilledRect(x1, y1, x2, y2)
        return
    end

    DrawCircle(x1 + r, y1 + r, r)
    DrawCircle(x2 - r, y1 + r, r)
    DrawCircle(x1 + r, y2 - r, r)
    DrawCircle(x2 - r, y2 - r, r)

    draw.FilledRect(x1 + r, y1, x2 - r, y2)
    draw.FilledRect(x1, y1 + r, x2, y2 - r)
end

-- Draw a horizontal rectangle with rounded corners left and right
local function RoundedRectH(x1, y1, x2, y2)
    if not Style.Circles then
        draw.FilledRect(x1, y1, x2, y2)
        return
    end

    local r = (y2 - y1) // 2
    DrawCircle(x1 + r, y1 + r, r)
    DrawCircle(x2 - r, y1 + r, r)
    draw.FilledRect(x1 + r, y1, x2 - r, y2)
end

--[[ Components ]]

---@class CFrame
---@field ID integer
---@field Visible boolean
---@field Components table
local CFrame = {
    ID = 0,
    Visible = true,
    Components = {}
}
CFrame.__index = CFrame
setmetatable(CFrame, CFrame)

function CFrame.new()
    local self = setmetatable({}, CFrame)
    self.ID = GetUniqueId()
    self.Visible = true
    self.Components = {}

    return self
end

function CFrame:AddComponent(component)
    table.insert(self.Components, component)
end

---@param ctx Context
function CFrame:Draw(ctx)
    local rect = ctx.Rect
    local x1, y1, x2, y2 = rect[1], rect[2], rect[3], rect[4]

    -- Background
    draw.Color(255, 0, 0, 2)
    draw.FilledRect(x1, y1, x2, y2)

    -- Draw components
    local childCtx = { Rect = { x1 + Style.FramePadding, y1 + Style.FramePadding, x2, y2 } }
    for _, component in ipairs(self.Components) do
        component:Draw(childCtx)
    end
end

---@class CCard : CFrame
---@field ID integer
---@field Visible boolean
---@field Pos table<integer, integer>
---@field Size table<integer, integer>
---@field Name string?
---@field Flags integer
local CCard = {
    ID = 0,
    Visible = true,
    Pos = { 300, 500 },
    Size = { 160, 32 },
    Name = nil,
    Flags = Flags.None
}
CCard.__index = CCard
setmetatable(CCard, CFrame)

function CCard.new(pos, size, name, flags)
    local self = setmetatable({}, CCard)
    -- TODO: Call super constructor

    self.ID = GetUniqueId()
    self.Visible = true
    self.Pos = pos or { 300, 500 }
    self.Size = size or { 160, 32 }
    self.Name = name or nil
    self.Flags = flags or Flags.None
    self.Components = {}

    return self
end

---@param ctx Context
function CCard:Draw(ctx)
    local rect = ctx.Rect
    local x1, y1, x2, y2 = rect[1], rect[2], rect[3], rect[4]

    -- Background
    local bgColor = Colors.CardBackground.Secondary
    SetColor(bgColor)
    RoundedRect(x1, y1, x2, y2, 10)

    -- Title
    local yOffset = 0
    if self.Name then
        draw.SetFont(Fonts.Subtitle)
        local tw, th = draw.GetTextSize(self.Name)

        SetColor(Colors.Text.Primary)
        draw.Text(x1 + Style.FramePadding, y1 + Style.FramePadding, self.Name)

        yOffset = th + Style.FramePadding
    end

    local frameCtx = { Rect = { x1, y1 + yOffset, x2, y2 } }
    CFrame.Draw(self, frameCtx)
end

local CLabel = {
    ID = 0,
    Visible = true,
    Pos = { 0, 0 },
    Text = "Label",
    Font = Fonts.Body,
    Flags = Flags.None
}
CLabel.__index = CLabel

function CLabel.new(pos, text, font, flags)
    local self = setmetatable({}, CLabel)
    self.ID = GetUniqueId()
    self.Visible = true
    self.Pos = pos or { 0, 0 }
    self.Text = text or "Label"
    self.Font = font or Fonts.Body
    self.Flags = flags or Flags.None

    return self
end

---@param ctx Context
function CLabel:Draw(ctx)
    local rect = ctx.Rect
    local x1, y1 = rect[1] + self.Pos[1], rect[2] + self.Pos[2]

    draw.SetFont(self.Font)
    SetColor(Colors.Text.Primary)
    draw.Text(x1, y1, self.Text)
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

---@param ctx Context
function CButton:Draw(ctx)
    local rect = ctx.Rect
    local x1, y1 = rect[1] + self.Pos[1], rect[2] + self.Pos[2]
    local w, h = self.Size[1], self.Size[2]
    local x2, y2 = x1 + w, y1 + h
    local hovered, clicked, active = GetInteraction(x1, y1, x2, y2, self.ID)

    -- Options
    local accent = self.Flags & Flags.Accent ~= 0
    local strong = self.Flags & Flags.Strong ~= 0
    local leftA = self.Flags & Flags.LeftAlign ~= 0
    local plain = self.Flags & Flags.Plain ~= 0

    -- Interaction
    if clicked then
        self.OnClick()
    end

    -- Background
    local bgColor = accent and Colors.AccentFill.Default or Colors.ControlFill.Default
    if active then
        bgColor = accent and Colors.AccentFill.Tertiary or Colors.ControlFill.Tertiary
    elseif hovered then
        bgColor = accent and Colors.AccentFill.Secondary or Colors.ControlFill.Secondary
    end

    if not plain then
        SetColor(Colors.ControlStroke.Secondary)
        RoundedRect(x1, y1, x2, y2, 6)
    end

    SetColor(bgColor)
    if plain and not hovered then
        SetColor(Colors.ControlAltFill.Transparent)
    end
    RoundedRect(x1 + 1, y1 + 1, x2 - 1, y2 - 1, 6)

    -- Text
    draw.SetFont(strong and Fonts.BodyStrong or Fonts.Body)
    SetColor(accent and Colors.TextOnAccent.Primary or Colors.Text.Primary)
    local tw, th = draw.GetTextSize(self.Text)
    if leftA then
        draw.Text(x1 + h, y1 + h // 2 - th // 2, self.Text)
    else
        draw.Text(x1 + w // 2 - tw // 2, y1 + h // 2 - th // 2, self.Text)
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

---@param ctx Context
function CCheckbox:Draw(ctx)
    local rect = ctx.Rect
    local x1, y1 = rect[1] + self.Pos[1], rect[2] + self.Pos[2]
    local w, h = 20, 20
    local x2, y2 = x1 + w, y1 + h

    draw.SetFont(Fonts.Body)
    local tw, th = draw.GetTextSize(self.Text)
    local hovered, clicked, active = GetInteraction(x1, y1, x2 + tw + 2 * Style.ItemPadding, y2, self.ID)

    -- Interaction
    if clicked then
        self.Checked = not self.Checked
        self.OnChange(self.Checked)
    end

    -- Checkmark
    local bgColor = self.Checked and Colors.AccentFill.Default or Colors.ControlAltFill.Secondary
    if active then
        bgColor = self.Checked and Colors.AccentFill.Tertiary or Colors.ControlAltFill.Quarternary
    elseif hovered then
        bgColor = self.Checked and Colors.AccentFill.Secondary or Colors.ControlAltFill.Tertiary
    end

    if self.Checked then
        -- No border
        SetColor(bgColor)
        RoundedRect(x1, y1, x2, y2, 6)
    else
        -- Border
        SetColor(Colors.ControlStrongStroke.Default)
        RoundedRect(x1, y1, x2, y2, 6)
        SetColor(bgColor)
        RoundedRect(x1 + 1, y1 + 1, x2 - 1, y2 - 1, 6)
    end

    -- Text
    SetColor(Colors.Text.Primary)
    draw.Text(x1 + w + Style.ItemPadding, y1 + h // 2 - th // 2, self.Text)
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

---@param ctx Context
function CSwitch:Draw(ctx)
    local rect = ctx.Rect
    local x1, y1 = rect[1] + self.Pos[1], rect[2] + self.Pos[2]
    local w, h = 40, 20
    local x2, y2 = x1 + w, y1 + h

    draw.SetFont(Fonts.Body)
    local tw, th = draw.GetTextSize(self.Text)
    local hovered, clicked, active = GetInteraction(x1, y1, x2 + tw + 2 * Style.ItemPadding, y2, self.ID)

    -- Interaction
    if clicked then
        self.Checked = not self.Checked
        self.OnChange(self.Checked)
    end

    -- Background
    local bgColor = self.Checked and Colors.AccentFill.Default or Colors.ControlAltFill.Secondary
    if active then
        bgColor = self.Checked and Colors.AccentFill.Tertiary or Colors.ControlAltFill.Tertiary
    elseif hovered then
        bgColor = self.Checked and Colors.AccentFill.Secondary or Colors.ControlAltFill.Secondary
    end

    -- Switch
    if self.Checked then
        -- No border
        SetColor(bgColor)
        RoundedRectH(x1, y1, x2, y2)

        -- Knob
        draw.Color(0, 0, 0, 255)
        DrawCircle(x2 - 10, y1 + 10, 6)
    else
        -- Border
        SetColor(Colors.ControlStrongStroke.Default)
        RoundedRectH(x1, y1, x2, y2)
        SetColor(bgColor)
        RoundedRectH(x1 + 1, y1 + 1, x2 - 1, y2 - 1)

        -- Knob
        draw.Color(204, 204, 204, 255)
        DrawCircle(x1 + 10, y1 + 10, 6)
    end

    -- Text
    SetColor(Colors.Text.Primary)
    draw.Text(x1 + w + Style.ItemPadding, y1 + h // 2 - th // 2, self.Text)
end

local CNavView = {
    ID = 0,
    Visible = true,
    Flags = Flags.None,
    Views = {},
    CurrentView = nil,
    _Buttons = {},
    _Frame = nil,
    _CurrentY = Style.FramePadding, -- TODO: This is a hack
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
    self._CurrentY = Style.FramePadding

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

    local btn = CButton.new({ 0, self._CurrentY }, { 190, 32 }, view.Name, function() self:Show(view) end,
        Flags.LeftAlign | Flags.Plain)
    table.insert(self._Buttons, btn)

    self._CurrentY = self._CurrentY + 32 + Style.ItemPadding
    --table.insert(self.Views, view)
end

---@param ctx Context
function CNavView:Draw(ctx)
    local rect = ctx.Rect
    local x1, y1, x2, y2 = rect[1], rect[2], rect[3], rect[4]

    -- Buttons
    for _, btn in ipairs(self._Buttons) do
        -- TODO: Button offset
        btn:Draw(ctx)
    end

    -- View
    if self.CurrentView then
        local viewCtx = { Rect = { x1 + 190 + Style.FramePadding, y1, x2, y2 } }
        self.CurrentView:Draw(viewCtx)
    end
end

local CWindow = {
    ID = 0,
    Visible = true,
    Pos = { 50, 50 },
    Size = { 400, 250 },
    Title = "",
    Frame = nil
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
    self.Frame = CFrame.new()

    return self
end

function CWindow:AddComponent(component)
    self.Frame:AddComponent(component)
end

function CWindow:Draw()
    local x1, y1 = self.Pos[1], self.Pos[2]
    local w, h = self.Size[1], self.Size[2]
    local x2, y2 = x1 + w, y1 + h

    -- Mouse drag
    local hovered, clicked, active = GetInteraction(x1, y1, x2, y1 + Style.HeaderSize - Style.FramePadding, self.ID)
    if active then
        local mX, mY = table.unpack(input.GetMousePos())

        if dragPos ~= nil then
            self.Pos[1] = mX - dragPos[1]
            self.Pos[2] = mY - dragPos[2]
        else
            dragPos = { mX - self.Pos[1], mY - self.Pos[2] }
        end
    else
        dragPos = nil
    end

    -- Background
    SetColor(Colors.SolidBackground.Base)
    RoundedRect(x1, y1, x2, y2, 15)
    --draw.FilledRect(x1, y1, x2, y2)

    -- Title
    draw.SetFont(Fonts.Title)
    SetColor(Colors.Text.Secondary)
    draw.Text(x1 + 2 * Style.FramePadding, y1 + Style.FramePadding, self.Title)

    -- Draw components
    local ctx = { Rect = { x1, y1 + Style.HeaderSize, x2, y2 } }
    self.Frame:Draw(ctx)
end

--[[ Callbacks ]]

local window = CWindow.new({ 450, 120 }, { 900, 500 }, "WinUi Demo")
local card1 = CCard.new({ 0, 0 }, { 0, 0 }, "Aimbot")
local card2 = CCard.new({ 0, 0 }, { 0, 0 }, "Visuals")
local navView = CNavView.new({ card1, card2 })

window:AddComponent(navView)

local button1 = CButton.new({ 0, 405 }, { 190, 32 }, "Reload", function() LoadScript(GetScriptName()) end, Flags.Accent)
local button2 = CButton.new({ 0, 100 }, { 190, 32 }, "Click me", function() print("Button 2 clicked") end)

window:AddComponent(button1)
card2:AddComponent(button2)

local check1 = CCheckbox.new({ 0, 0 }, "Checkbox 1", false,
    function(value) print("Checkbox 1 changed to " .. tostring(value)) end)
local check2 = CCheckbox.new({ 0, 30 }, "Checkbox 2", true,
    function(value) print("Checkbox 2 changed to " .. tostring(value)) end)

card1:AddComponent(check1)
card1:AddComponent(check2)

local switch1 = CSwitch.new({ 0, 60 }, "Enable input", input.IsMouseInputEnabled(),
    function(value) input.SetMouseInputEnabled(value) end)
local switch2 = CSwitch.new({ 0, 0 }, "Allow circles", Style.Circles, function(value) Style.Circles = value end)

card1:AddComponent(switch1)
card2:AddComponent(switch2)

local label1 = CLabel.new({ 0, 30 }, "This is a caption.", Fonts.Caption)
local label2 = CLabel.new({ 0, 50 }, "This is a body.", Fonts.Body)
local label3 = CLabel.new({ 0, 70 }, "This is a subtitle.", Fonts.Subtitle)

card2:AddComponent(label1)
card2:AddComponent(label2)
card2:AddComponent(label3)

local function OnDraw()
    window:Draw()

    -- Capture interaction
    local w, h = draw.GetScreenSize()
    GetInteraction(0, 0, w, h, -1)
end

local function OnUnload()
    draw.DeleteTexture(circle)
end

callbacks.Unregister("Draw", "LNX.WinUI.Draw")
callbacks.Register("Draw", "LNX.WinUI.Draw", OnDraw)

callbacks.Unregister("Unload", "LNX.WinUI.Unload")
callbacks.Register("Unload", "LNX.WinUI.Unload", OnUnload)
