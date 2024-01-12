--[[
    UI Library for Lmaobox
    Author: LNX (github.com/lnx00)
]]

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

Colors = {
    WHITE = { R = 255, G = 255, B = 255, A = 255 },
    BLACK = { R = 0, G = 0, B = 0, A = 255 },
    RED = { R = 255, G = 0, B = 0, A = 255 },
    GREEN = { R = 0, G = 255, B = 0, A = 255 },
    BLUE = { R = 0, G = 0, B = 255, A = 255 },
    YELLOW = { R = 255, G = 255, B = 0, A = 255 },
    ORANGE = { R = 255, G = 128, B = 0, A = 255 },
    PURPLE = { R = 255, G = 0, B = 255, A = 255 },
    CYAN = { R = 0, G = 255, B = 255, A = 255 }
}

local ANIM_NONE <const> = 0
local ANIM_FADEIN <const> = 1
local ANIM_FADEOUT <const> = 2

function CopyColor(pColor)
    return { R = pColor.R, G = pColor.G, B = pColor.B, A = pColor.A }
end

function CopyPos(pPos)
    return { X = pPos.X, Y = pPos.Y }
end

function CopySize(pSize)
    return { Width = pSize.Width, Height = pSize.Height }
end

--[[ Rect Element ]]--
local Rect = {
    ID = 0,
    Visible = true,
    Position = { X = 100, Y = 100 },
    Size = { Width = 200, Height = 200 },
    Filled = true,
    Color = CopyColor(UI.DefaultColor),
    Speed = 400,

    _animation = ANIM_NONE,
    _color = CopyColor(UI.DefaultColor), -- Color to restore after animations
    _position = { X = 100, Y = 100 },
    _size = { Width = 200, Height = 200 }
}

local MetaRect = {}
MetaRect.__index = Rect

function Rect.Create(pPosition, pSize, pFilled, pColor, pVisible, pSpeed)
    pColor = pColor or CopyColor(UI.DefaultColor)
    pVisible = (pVisible ~= false)
    pSpeed = pSpeed or UI.DefaultSpeed

    local iRect = setmetatable({}, MetaRect)
    iRect.ID = UI._currentID
    iRect.Position = pPosition
    iRect.Size = pSize
    iRect.Filled = pFilled
    iRect.Color = pColor
    iRect.Speed = pSpeed

    -- We don't want a reference of these tables
    iRect._color = CopyColor(pColor)
    iRect._position = CopyPos(pPosition)
    iRect._size = CopySize(pSize)
    iRect:SetVisible(pVisible)

    table.insert(UI._rectTable, iRect)
    UI._currentID = UI._currentID + 1
    return iRect
end

function Rect:SetColor(pColor)
    self.Color = pColor
    self._color = CopyColor(pColor)
end

function Rect:SetPosition(pPosition)
    self.Position = pPosition
    self._position = CopyPos(pPosition)
end

function Rect:SetSize(pSize)
    self.Size = pSize
    self._size = CopySize(pSize)
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

function Rect:Transform(pPosition, pSize, pSpeed)
    self._position = pPosition or self._position
    self._size = pSize or self._size
    self.Speed = pSpeed or self.Speed
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
    _position = { X = 100, Y = 100 }
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
    iText._position = CopyPos(pPosition)
    iText:SetVisible(pVisible)

    table.insert(UI._textTable, iText)
    UI._currentID = UI._currentID + 1
    return iText
end

function Text:SetColor(pColor)
    self.Color = pColor
    self._color = CopyColor(pColor)
end

function Text:SetPosition(pPosition)
    self.Position = pPosition
    self._position = CopyPos(pPosition)
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

function Text:Transform(pPosition, pSpeed)
    self._position = pPosition or self._position
    self.Speed = pSpeed or self.Speed
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

    if self.Position and self._position then
        if self.Position.X < self._position.X or self.Position.Y < self._position.Y then
            self.Position.X = math.min(self.Position.X + globals.FrameTime() * self.Speed, self._position.X)
            self.Position.Y = math.min(self.Position.Y + globals.FrameTime() * self.Speed, self._position.Y)
        end
        if  self.Position.X > self._position.X or self.Position.Y > self._position.Y then
            self.Position.X = math.max(self.Position.X - globals.FrameTime() * self.Speed, self._position.X)
            self.Position.Y = math.max(self.Position.Y - globals.FrameTime() * self.Speed, self._position.Y)
        end
    end

    if self.Size and self._size then
        if self.Size.Width < self._size.Width or self.Size.Height < self._size.Height then
            self.Size.Width = math.min(self.Size.Width + globals.FrameTime() * self.Speed, self._size.Width)
            self.Size.Height = math.min(self.Size.Height + globals.FrameTime() * self.Speed, self._size.Height)
        end
        if self.Size.Width > self._size.Width or self.Size.Height > self._size.Height then
            self.Size.Width = math.max(self.Size.Width - globals.FrameTime() * self.Speed, self._size.Width)
            self.Size.Height = math.max(self.Size.Height - globals.FrameTime() * self.Speed, self._size.Height)
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
                draw.FilledRect(math.floor(r.Position.X), math.floor(r.Position.Y), math.floor(r.Position.X + r.Size.Width), math.floor(r.Position.Y + r.Size.Height))
            else
                draw.OutlinedRect(math.floor(r.Position.X), math.floor(r.Position.Y), math.floor(r.Position.X + r.Size.Width), math.floor(r.Position.Y + r.Size.Height))
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

function UI.AddRect(pX, pY, pWidth, pHeight, pFilled, pColor, pVisible)
    return Rect.Create({ X = pX, Y = pY }, { Width = pWidth, Height = pHeight }, pFilled, pColor, pVisible)
end

function UI.RemoveRect(pElement)
    table.remove(UI._rectTable, pElement)
end

function UI.AddLine(pX, pY, pX2, pY2, pColor, pVisible)
    return Line.Create({ X = pX, Y = pY, X2 = pX2, Y2 = pY2 }, pColor, pVisible)
end

function UI.RemoveLine(pElement)
    table.remove(UI._lineTable, pElement)
end

function UI.AddText(pX, pY, pText, pColor, pShadow, pAlign, pFont, pVisible)
    return Text.Create({ X = pX, Y = pY }, pText, pColor, pShadow, pAlign, pFont, pVisible)
end

function UI.RemoveText(pElement)
    table.remove(UI._textTable, pElement)
end

callbacks.Unregister("Draw", "Draw_UI");
callbacks.Register("Draw", "Draw_UI", UI.Draw)

return UI