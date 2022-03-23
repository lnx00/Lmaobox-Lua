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
UI._textTable = {}

TextAlign = {
    LEFT = 1,
    CENTER = 2
}

Direction = {
    HORIZONTAL = 1,
    VERTICAL = 2
}

local ANIM_NONE <const> = 0
local ANIM_FADEIN <const> = 1
local ANIM_FADEOUT <const> = 2
local ANIM_SLIDEIN <const> = 3
local ANIM_SLIDEOUT <const> = 4

function CopyColor(pColor)
    return { R = pColor.R, G = pColor.G, B = pColor.B, A = pColor.A }
end

function CopyPos(pPos)
    return { X = pPos.X, Y = pPos.Y }
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
    _position = { X = 100, Y = 100 } -- Position to restore after animations
}

local MetaRect = {}
MetaRect.__index = Rect

function Rect.Create(pPosition, pWidth, pHeight, pFilled, pColor, pSpeed)
    pColor = pColor or CopyColor(UI.DefaultColor)
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
    iRect._position = CopyPos(pPosition)

    table.insert(UI._rectTable, iRect)
    UI._currentID = UI._currentID + 1
    return iRect
end

function Rect:SetColor(pColor)
    self.Color = pColor
    self._color = CopyColor(pColor)
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

--[[ Text Element ]]--
local Text = {
    ID = 0,
    Visible = true,
    Position = { X = 100, Y = 100 },
    Color = CopyColor(UI.DefaultColor),
    Font = UI.DefaultFont,
    Align = TextAlign.LEFT,
    Speed = 400,
    _animation = ANIM_NONE,
    _color = CopyColor(UI.DefaultColor), -- Color to restore after animations
    _position = { X = 100, Y = 100 }, -- Position to restore after animations
    _direction = Direction.HORIZONTAL
}

local MetaText = {}
MetaText.__index = Text

function Text.Create(pPosition, pText, pColor, pFont, pAlign, pSpeed)
    pColor = pColor or CopyColor(UI.DefaultColor)
    pFont = pFont or UI.DefaultFont
    pAlign = pAlign or TextAlign.LEFT
    pSpeed = pSpeed or UI.DefaultSpeed

    local iText = setmetatable({}, MetaText)
    iText.ID = UI._currentID
    iText.Position = pPosition
    iText.Text = pText
    iText.Color = pColor
    iText.Font = pFont
    iText.Align = pAlign
    iText.Speed = pSpeed

    -- We don't want a reference of these tables
    iText._color = CopyColor(pColor)
    iText._position = CopyPos(pPosition)

    table.insert(UI._textTable, iText)
    UI._currentID = UI._currentID + 1
    return iText
end

function Text:SetColor(pColor)
    self.Color = pColor
    self._color = CopyColor(pColor)
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

function Text:SlideIn(pDirection, pSpeed)
    self._direction = pDirection or Direction.HORIZONTAL
    self.Speed = pSpeed or self.Speed
    if pDirection == Direction.HORIZONTAL then
        self.Position.X = self.Position.X - 50
        self._animation = ANIM_SLIDEIN
    else
        self.Position.Y = self.Position.Y - 50
        self._animation = ANIM_SLIDEIN
    end
end

function Text:SlideOut(pDirection, pSpeed)
    self._direction = pDirection or Direction.HORIZONTAL
    self.Speed = pSpeed or self.Speed
    if pDirection == Direction.HORIZONTAL then
        if self.Position.X <= self._position.X then
            self._animation = ANIM_SLIDEOUT
        end
    else
        if self.Position.Y <= self._position.Y then
            self._animation = ANIM_SLIDEOUT
        end
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
    elseif self._animation == ANIM_SLIDEIN then
        -- Slide in Animation
        if self._direction == Direction.HORIZONTAL then
            if self.Position.X < self._position.X then
                self.Color.A = math.min(self.Color.A + globals.FrameTime() * self.Speed, self._color.A)
                self.Position.X = math.min(self.Position.X + globals.FrameTime() * self.Speed, self._position.X)
            else
                self._animation = ANIM_NONE
            end
        else
            if self.Position.Y < self._position.Y then
                self.Color.A = math.min(self.Color.A + globals.FrameTime() * self.Speed, self._color.A)
                self.Position.Y = math.min(self.Position.Y + globals.FrameTime() * self.Speed, self._position.Y)
            else
                self._animation = ANIM_NONE
            end
        end
    elseif self._animation == ANIM_SLIDEOUT then
        -- Slide out animation
        if self._direction == Direction.HORIZONTAL then
            if self.Position.X < (self._position.X + 50) then
                self.Color.A = math.max(self.Color.A - globals.FrameTime() * self.Speed, 0)
                self.Position.X = math.max(self.Position.X + globals.FrameTime() * self.Speed, self._position.X + 50)
            else
                self._animation = ANIM_NONE
            end
        else
            if self.Position.Y < (self._position.Y + 50) then
                self.Color.A = math.max(self.Color.A - globals.FrameTime() * self.Speed, 0)
                self.Position.Y = math.max(self.Position.Y + globals.FrameTime() * self.Speed, self._position.Y + 50)
            else
                self._animation = ANIM_NONE
            end
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

    -- Draw Texts
    for k, t in pairs(UI._textTable) do
        if t.Visible then
            draw.SetFont(t.Font)
            draw.Color(t.Color.R, t.Color.G, t.Color.B, math.floor(t.Color.A))
            local xPos = t.Position.X
            if t.Align == TextAlign.CENTER then
                local sizeX, sizeY = draw.GetTextSize(t.Text)
                xPos = xPos - (sizeX / 2)
            end
            draw.Text(math.floor(xPos), math.floor(t.Position.Y), t.Text)
        end
        UI._Animate(t)
    end
end

function UI.AddRect(pX, pY, pWidth, pHeight, pFilled, pColor, pSpeed)
    return Rect.Create({ X = pX, Y = pY }, pWidth, pHeight, pFilled, pColor, pSpeed)
end

function UI.RemoveRect(pElement)
    table.remove(UI._rectTable, pElement)
end

function UI.AddText(pX, pY, pText, pColor, pFont, pAlign, pSpeed)
    return Text.Create({ X = pX, Y = pY }, pText, pColor, pFont, pAlign, pSpeed)
end

function UI.RemoveText(pElement)
    table.remove(UI._textTable, pElement)
end

callbacks.Unregister("Draw", "Draw_UI");
callbacks.Register("Draw", "Draw_UI", UI.Draw)

return UI