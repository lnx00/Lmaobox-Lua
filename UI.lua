--[[

UI Library for Lmaobox
Author: LNX

]]--

local UI = {}

UI.Enabled = true
UI.DefaultFont = draw.CreateFont("verdana", 14, 510)
UI.DefaultColor = { R = 200, G = 200, B = 200, A = 255 }
UI.DefaultSpeed = 400
UI._currentID = 1
UI._rectTable = {}
UI._lineTable = {}
UI._textTable = {}

TextAlign = {
    LEFT = 1,
    CENTER = 2,
    RIGHT = 3
}

local ANIM_NONE <const> = 0
local ANIM_FADEIN <const> = 1
local ANIM_FADEOUT <const> = 2

function CopyColor(pColor)
    return { R = pColor.R, G = pColor.G, B = pColor.B, A = pColor.A }
end

--[[ Rect Element ]]--
local Rect = {
    ID = 0,
    Visible = true,
    Position = { X = 100, Y = 100 },
    Width = 200,
    Height = 200,
    Filled = true,
    Color = CopyColor(UI.DefaultColor),
    Speed = 400,

    _animation = ANIM_NONE,
    _color = CopyColor(UI.DefaultColor), -- Color to restore after animations
}

local MetaRect = {}
MetaRect.__index = Rect

function Rect.Create(pPosition, pWidth, pHeight, pFilled, pColor, pVisible, pSpeed)
    pColor = pColor or CopyColor(UI.DefaultColor)
    pVisible = (pVisible ~= false)
    pSpeed = pSpeed or UI.DefaultSpeed

    local iRect = setmetatable({}, MetaRect)
    iRect.ID = UI._currentID
    iRect.Position = pPosition
    iRect.Width = pWidth
    iRect.Height = pHeight
    iRect.Filled = pFilled
    iRect.Color = pColor
    iRect.Speed = pSpeed

    -- We don't want a reference of these tables
    iRect._color = CopyColor(pColor)
    iRect:SetVisible(pVisible)

    table.insert(UI._rectTable, iRect)
    UI._currentID = UI._currentID + 1
    return iRect
end

function Rect:SetColor(pColor)
    self.Color = pColor
    self._color = CopyColor(pColor)
end

function Rect:SetVisible(pState)
    self.Visible = pState
    if self.Visible then
        self.Color.A = self._color.A
    else
        self.Color.A = 0
    end
end

function Rect:SetCoordinated(pX, pY, pX2, pY2)
    self.Position = { X = pX, Y = pY }
    self.Width = pX + pX2
    self.Height = pY + pY2
end

function Rect:FadeIn(pSpeed)
    self.Speed = pSpeed or self.Speed
    if self.Color.A < self._color.A then
        self.Visible = true
        self._animation = ANIM_FADEIN
    end
end

function Rect:FadeOut(pSpeed)
    self.Speed = pSpeed or self.Speed
    if self.Color.A > 0 then
        self._animation = ANIM_FADEOUT
    end
end

function Rect:Cancel()
    self._animation = ANIM_NONE
    self.Color = self._color
    self.Position = self._position
end

--[[ Line Element ]]--
local Line = {
    ID = 0,
    Visible = true,
    Points = { X = 100, Y = 100, X2 = 200, Y2 = 200 },
    Color = CopyColor(UI.DefaultColor),
    Speed = 400,
    _animation = ANIM_NONE,
    _color = CopyColor(UI.DefaultColor), -- Color to restore after animations
}

local MetaLine = {}
MetaLine.__index = Line

function Line.Create(pPoints, pColor, pVisible, pSpeed)
    pColor = pColor or CopyColor(UI.DefaultColor)
    pVisible = (pVisible ~= false)
    pSpeed = pSpeed or 400

    local iLine = setmetatable({}, MetaLine)
    iLine.ID = UI._currentID
    iLine.Points = pPoints
    iLine.Color = pColor
    iLine.Speed = pSpeed

    -- We don't want a reference of these tables
    iLine._color = CopyColor(pColor)
    iLine:SetVisible(pVisible)

    table.insert(UI._lineTable, iLine)
    UI._currentID = UI._currentID + 1
    return iLine
end

function Line:SetColor(pColor)
    self.Color = pColor
    self._color = CopyColor(pColor)
end

function Line:SetVisible(pState)
    self.Visible = pState
    if self.Visible then
        self.Color.A = self._color.A
    else
        self.Color.A = 0
    end
end

function Line:FadeIn(pSpeed)
    self.Speed = pSpeed or self.Speed
    if self.Color.A < self._color.A then
        self.Visible = true
        self._animation = ANIM_FADEIN
    end
end

function Line:FadeOut(pSpeed)
    self.Speed = pSpeed or self.Speed
    if self.Color.A > 0 then
        self._animation = ANIM_FADEOUT
    end
end

function Line:Cancel()
    self._animation = ANIM_NONE
    self.Color = self._color
    self.Position = self._position
end

--[[ Text Element ]]--
local Text = {
    ID = 0,
    Visible = true,
    Position = { X = 100, Y = 100 },
    Color = CopyColor(UI.DefaultColor),
    Shadow = false,
    Font = UI.DefaultFont,
    Align = TextAlign.LEFT,
    Speed = 400,
    _animation = ANIM_NONE,
    _color = CopyColor(UI.DefaultColor), -- Color to restore after animations
}

local MetaText = {}
MetaText.__index = Text

function Text.Create(pPosition, pText, pColor, pShadow, pAlign, pFont, pVisible, pSpeed)
    pColor = pColor or CopyColor(UI.DefaultColor)
    pShadow = pShadow or false
    pFont = pFont or UI.DefaultFont
    pAlign = pAlign or TextAlign.LEFT
    pVisible = (pVisible ~= false)
    pSpeed = pSpeed or UI.DefaultSpeed

    local iText = setmetatable({}, MetaText)
    iText.ID = UI._currentID
    iText.Position = pPosition
    iText.Text = pText
    iText.Color = pColor
    iText.Shadow = pShadow
    iText.Font = pFont
    iText.Align = pAlign
    iText.Speed = pSpeed

    -- We don't want a reference of these tables
    iText._color = CopyColor(pColor)
    iText:SetVisible(pVisible)

    table.insert(UI._textTable, iText)
    UI._currentID = UI._currentID + 1
    return iText
end

function Text:SetColor(pColor)
    self.Color = pColor
    self._color = CopyColor(pColor)
end

function Text:SetVisible(pState)
    self.Visible = pState
    if self.Visible then
        self.Color.A = self._color.A
    else
        self.Color.A = 0
    end
end

function Text:FadeIn(pSpeed)
    self.Speed = pSpeed or self.Speed
    if self.Color.A < self._color.A then
        self.Visible = true
        self._animation = ANIM_FADEIN
    end
end

function Text:FadeOut(pSpeed)
    self.Speed = pSpeed or self.Speed
    if self.Color.A > 0 then
        self._animation = ANIM_FADEOUT
    end
end

function Text:Cancel()
    self._animation = ANIM_NONE
    self.Color = self._color
    self.Position = self._position
end

--[[ UI ]]--
function UI._Animate(self)
    if self._animation == ANIM_FADEIN then
        -- Fade in animation
        if self.Color.A < self._color.A then
            self.Color.A = math.min(self.Color.A + globals.FrameTime() * self.Speed, self._color.A)
        else
            self._animation = ANIM_NONE
            self.Visible = true
        end
    elseif self._animation == ANIM_FADEOUT then
        -- Fade out animation
        if self.Color.A > 0 then
            self.Color.A = math.max(self.Color.A - globals.FrameTime() * self.Speed, 0)
        else
            self._animation = ANIM_NONE
            self.Visible = false
        end
    end
end

-- Draw all UI Elements
function UI.Draw()
    if not UI.Enabled then
        return
    end

    -- Draw Rects
    for k, r in pairs(UI._rectTable) do
        if r.Visible then
            draw.Color(r.Color.R, r.Color.G, r.Color.B,  math.floor(r.Color.A))
            if r.Filled then
                draw.FilledRect(math.floor(r.Position.X), math.floor(r.Position.Y), math.floor(r.Position.X + r.Width), math.floor(r.Position.Y + r.Height))
            else
                draw.OutlinedRect(math.floor(r.Position.X), math.floor(r.Position.Y), math.floor(r.Position.X + r.Width), math.floor(r.Position.Y + r.Height))
            end
        end
        UI._Animate(r)
    end

    -- Draw Lines
    for k, l in pairs(UI._lineTable) do
        if l.Visible then
            draw.Color(l.Color.R, l.Color.G, l.Color.B,  math.floor(l.Color.A))
            draw.Line(math.floor(l.Points.X), math.floor(l.Points.Y), math.floor(l.Points.X2), math.floor(l.Points.Y2))
        end
        UI._Animate(l)
    end

    -- Draw Texts
    for k, t in pairs(UI._textTable) do
        if t.Visible then
            draw.SetFont(t.Font)
            draw.Color(t.Color.R, t.Color.G, t.Color.B, math.floor(t.Color.A))
            local xPos = t.Position.X
            local sizeX, sizeY = draw.GetTextSize(t.Text)

            if t.Align == TextAlign.CENTER then
                xPos = xPos - (sizeX / 2) + 5
            elseif t.Align == TextAlign.RIGHT then
                xPos = xPos - sizeX
            end

            if t.Shadow then
                draw.TextShadow(math.floor(xPos), math.floor(t.Position.Y), t.Text)
            else
                draw.Text(math.floor(xPos), math.floor(t.Position.Y), t.Text)
            end
        end
        UI._Animate(t)
    end
end

function UI.AddRect(pX, pY, pWidth, pHeight, pFilled, pColor, pVisible, pSpeed)
    return Rect.Create({ X = pX, Y = pY }, pWidth, pHeight, pFilled, pColor, pVisible, pSpeed)
end

function UI.RemoveRect(pElement)
    table.remove(UI._rectTable, pElement)
end

function UI.AddLine(pX, pY, pX2, pY2, pColor, pVisible, pSpeed)
    return Line.Create({ X = pX, Y = pY, X2 = pX2, Y2 = pY2 }, pColor, pVisible, pSpeed)
end

function UI.RemoveLine(pElement)
    table.remove(UI._lineTable, pElement)
end

function UI.AddText(pX, pY, pText, pColor, pShadow, pAlign, pFont, pVisible, pSpeed)
    return Text.Create({ X = pX, Y = pY }, pText, pColor, pShadow, pAlign, pFont, pVisible, pSpeed)
end

function UI.RemoveText(pElement)
    table.remove(UI._textTable, pElement)
end

callbacks.Unregister("Draw", "Draw_UI");
callbacks.Register("Draw", "Draw_UI", UI.Draw)

return UI