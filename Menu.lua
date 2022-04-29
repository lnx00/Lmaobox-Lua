--[[
    Menu Library for Lmaobox
    Author: LNX (github.com/lnx00)
]]

local MenuManager = {
    CurrentID = 1,
    Menus = {},
    Font = draw.CreateFont("Verdana", 14, 510),
    Version = 1.40,
    DebugInfo = false
}

MenuFlags = {
    None = 0,
    NoTitle = 1 << 0, -- No title bar
    NoBackground = 1 << 1, -- No window background
    NoDrag = 1 << 2, -- Disable dragging
    AutoSize = 1 << 3, -- Auto size height to contents
    ShowAlways = 1 << 4, -- Show menu when ingame
    Child = 1 << 5 -- Child window
}

ItemFlags = {
    None = 0,
    FullWidth = 1 << 0, -- Fill width of menu
    Active = 1 << 1 -- Item is always active
}

local LastMouseState = false
local MouseReleased = false
local DragID = 0
local DragOffset = { 0, 0 }
local IsInteracting = false -- Is interacting with a child menu

local InputMap = {}
for i = 0, 9 do InputMap[i + 1] = tostring(i) end
for i = 65, 90 do InputMap[i - 54] = string.char(i) end

local function GetCurrentKey()
    for i, keyText in ipairs(InputMap) do
        if input.IsButtonDown(i) then
            return keyText
        end
    end

    if input.IsButtonDown(KEY_SPACE) then return "SPACE" end
    if input.IsButtonDown(KEY_BACKSPACE) then return "BACKSPACE" end
    if input.IsButtonDown(KEY_COMMA) then return "," end
    if input.IsButtonDown(KEY_PERIOD) then return "." end
    if input.IsButtonDown(KEY_MINUS) then return "-" end
    return nil
end

local function MouseInBounds(pX, pY, pX2, pY2)
    local mX = input.GetMousePos()[1]
    local mY = input.GetMousePos()[2]
    return (mX > pX and mX < pX2 and mY > pY and mY < pY2)
end

local function UpdateMouseState()
    local mouseState = input.IsButtonDown(MOUSE_LEFT)
    MouseReleased = (mouseState == false and LastMouseState == true)
    LastMouseState = mouseState
end

local function Clamp(n, low, high) return math.min(math.max(n, low), high) end

local function SetColorStyle(color)
    local alpha = color[4] or 255
    draw.Color(color[1], color[2], color[3], alpha)
end

--[[ Component Class ]]
local Component = {
    ID = 0,
    Visible = true,
    Flags = ItemFlags.None
}
Component.__index = Component

function Component.New()
    local self = setmetatable({}, Component)
    self.Visible = true
    self.Flags = ItemFlags.None

    return self
end

function Component:SetVisible(state)
    self.Visible = state
end

--[[ Label Component ]]
local Label = {
    Text = "New Label"
}
Label.__index = Label
setmetatable(Label, Component)

function Label.New(label, flags)
    flags = flags or ItemFlags.None

    local self = setmetatable({}, Label)
    self.ID = MenuManager.CurrentID
    self.Text = label
    self.Flags = flags

    MenuManager.CurrentID = MenuManager.CurrentID + 1
    return self
end

function Label:Render(menu)
    SetColorStyle(menu.Style.Text)
    draw.SetFont(MenuManager.Font)
    draw.Text(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, self.Text)
    local textWidth, textHeight = draw.GetTextSize(self.Text)

    menu.Cursor.Y = menu.Cursor.Y + textHeight + menu.Style.Space
end

--[[ Checkbox Component ]]
local Checkbox = {
    Label = "New Checkbox",
    Value = false
}
Checkbox.__index = Checkbox
setmetatable(Checkbox, Component)

function Checkbox.New(label, value, flags)
    assert(type(value) == "boolean", "Checkbox value must be a boolean")
    flags = flags or ItemFlags.None

    local self = setmetatable({}, Checkbox)
    self.ID = MenuManager.CurrentID
    self.Label = label
    self.Value = value
    self.Flags = flags

    MenuManager.CurrentID = MenuManager.CurrentID + 1
    return self
end

function Checkbox:GetValue()
    return self.Value
end

function Checkbox:Render(menu)
    local lblWidth, lblHeight = draw.GetTextSize(self.Label)
    local chkSize = math.floor(lblHeight * 1.4)

    -- Interaction
    if IsInteracting == false and MouseReleased and MouseInBounds(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + chkSize + menu.Style.Space + lblWidth, menu.Y + menu.Cursor.Y + chkSize) then
        self.Value = not self.Value
    end

    if self.Value == true then
        draw.Color(68, 189, 50, 255) -- Checked
    else
        draw.Color(120, 50, 35, 255) -- Unchecked
    end

    -- Drawing
    draw.FilledRect(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + chkSize, menu.Y + menu.Cursor.Y + chkSize)
    draw.SetFont(MenuManager.Font)
    SetColorStyle(menu.Style.Text)
    draw.Text(menu.X + menu.Cursor.X + chkSize + menu.Style.Space, math.floor(menu.Y + menu.Cursor.Y + (chkSize / 2) - (lblHeight / 2)), self.Label)

    if self.Value == true then
        SetColorStyle(menu.Style.Highlight)
        draw.FilledRect(menu.X + menu.Cursor.X + menu.Style.Space, menu.Y + menu.Cursor.Y + menu.Style.Space, menu.X + menu.Cursor.X + chkSize - menu.Style.Space, menu.Y + menu.Cursor.Y + chkSize - menu.Style.Space)
    end

    menu.Cursor.Y = menu.Cursor.Y + chkSize + menu.Style.Space
end

--[[ Button Component ]]
local Button = {
    Label = "New Button",
    Callback = nil
}
Button.__index = Button
setmetatable(Button, Component)

function Button.New(label, callback, flags)
    assert(type(callback) == "function", "Button callback must be a function")
    flags = flags or ItemFlags.None

    local self = setmetatable({}, Button)
    self.ID = MenuManager.CurrentID
    self.Label = label
    self.Callback = callback
    self.Flags = flags

    MenuManager.CurrentID = MenuManager.CurrentID + 1
    return self
end

function Button:Render(menu)
    local lblWidth, lblHeight = draw.GetTextSize(self.Label)
    local btnWidth = lblWidth + (menu.Style.Space * 4)
    if self.Flags & ItemFlags.FullWidth ~= 0 then
        btnWidth = menu.Width - (menu.Style.Space * 2)
    end

    local btnHeight = lblHeight + (menu.Style.Space * 2)

    -- Interaction
    if self.Flags & ItemFlags.Active == 0 then
        SetColorStyle(menu.Style.Item)
    else
        SetColorStyle(menu.Style.ItemActive)
    end

    if not(menu.Flags & MenuFlags.Child == 0 and IsInteracting == true) and MouseInBounds(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + btnWidth, menu.Y + menu.Cursor.Y + btnHeight) then
        if input.IsButtonDown(MOUSE_LEFT) then
            SetColorStyle(menu.Style.ItemActive)
        else
            SetColorStyle(menu.Style.ItemHover)
        end
        if MouseReleased then
            self:Callback()
        end
    end

    -- Drawing
    draw.FilledRect(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + btnWidth, menu.Y + menu.Cursor.Y + btnHeight)
    SetColorStyle(menu.Style.Text)
    draw.Text(math.floor(menu.X + menu.Cursor.X + (btnWidth / 2) - (lblWidth / 2)), math.floor(menu.Y + menu.Cursor.Y + (btnHeight / 2) - (lblHeight / 2)), self.Label)

    menu.Cursor.Y = menu.Cursor.Y + btnHeight + menu.Style.Space
end

--[[ Slider Component ]]
local Slider = {
    Label = "New Slider",
    Min = 0,
    Max = 100,
    Value = 0
}
Slider.__index = Slider
setmetatable(Slider, Component)

function Slider.New(label, min, max, value, flags)
    assert(max > min, "Slider max must be greater than min")
    flags = flags or ItemFlags.None

    local self = setmetatable({}, Slider)
    self.ID = MenuManager.CurrentID
    self.Label = label
    self.Min = min
    self.Max = max
    self.Value = value
    self.Flags = flags

    MenuManager.CurrentID = MenuManager.CurrentID + 1
    return self
end

function Slider:GetValue()
    return self.Value
end

function Slider:Render(menu)
    local lblWidth, lblHeight = draw.GetTextSize(self.Label .. ": " .. self.Value)
    local sliderWidth = menu.Width - (menu.Style.Space * 2)
    local sliderHeight = lblHeight + (menu.Style.Space * 2)
    local dragX = math.floor(((self.Value - self.Min) / math.abs(self.Max - self.Min)) * sliderWidth)

    -- Interaction
    SetColorStyle(menu.Style.Item)
    if IsInteracting == false and DragID == 0 and MouseInBounds(menu.X + menu.Cursor.X - 5, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + sliderWidth + 10, menu.Y + menu.Cursor.Y + sliderHeight) then
        SetColorStyle(menu.Style.ItemHover)
        
        if input.IsButtonDown(MOUSE_LEFT) then
            dragX = Clamp(input.GetMousePos()[1] - (menu.X + menu.Cursor.X), 0, sliderWidth)
            self.Value = (math.floor((dragX / sliderWidth) * math.abs(self.Max - self.Min))) + self.Min
        end
    end

    -- Drawing
    draw.FilledRect(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + sliderWidth, menu.Y + menu.Cursor.Y + sliderHeight)
    SetColorStyle(menu.Style.Highlight)
    draw.FilledRect(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + dragX, menu.Y + menu.Cursor.Y + sliderHeight)

    draw.SetFont(MenuManager.Font)
    SetColorStyle(menu.Style.Text)
    draw.Text(math.floor(menu.X + menu.Cursor.X + (sliderWidth / 2) - (lblWidth / 2)), math.floor(menu.Y + menu.Cursor.Y + (sliderHeight / 2) - (lblHeight / 2)), self.Label .. ": " .. self.Value)

    menu.Cursor.Y = menu.Cursor.Y + sliderHeight + menu.Style.Space
end

--[[ Textbox Component ]]
local Textbox = {
    Label = "New Textbox",
    Value = "",
    _LastKey = nil
}
Textbox.__index = Textbox
setmetatable(Textbox, Component)

function Textbox.New(label, value, flags)
    flags = flags or ItemFlags.None

    local self = setmetatable({}, Textbox)
    self.ID = MenuManager.CurrentID
    self.Label = label
    self.Value = value
    self.Flags = flags

    MenuManager.CurrentID = MenuManager.CurrentID + 1
    return self
end

function Textbox:GetValue()
    return self.Value
end

function Textbox:Render(menu)
    local lblWidth, lblHeight = draw.GetTextSize(self.Value)
    local boxWidth = menu.Width - (menu.Style.Space * 2)
    local boxHeight = 20

    -- Interaction
    SetColorStyle(menu.Style.Item)
    if IsInteracting == false and MouseInBounds(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + boxWidth, menu.Y + menu.Cursor.Y + boxHeight) then
        SetColorStyle(menu.Style.ItemHover)

        local key = GetCurrentKey()
        if not key and self._LastKey then
            if self._LastKey == "SPACE" then
                self.Value = self.Value .. " "
            elseif self._LastKey == "BACKSPACE" then
                self.Value = self.Value:sub(1, -2)
            else
                if input.IsButtonDown(KEY_LSHIFT) then
                    self.Value = self.Value .. string.upper(self._LastKey)
                else
                    self.Value = self.Value .. string.lower(self._LastKey)
                end
            end
            self._LastKey = nil
        end
        self._LastKey = key
    end

    -- Drawing
    draw.FilledRect(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + boxWidth, menu.Y + menu.Cursor.Y + boxHeight)

    draw.SetFont(MenuManager.Font)
    if self.Value == "" then
        draw.Color(180, 180, 180, 255)
        draw.Text(menu.X + menu.Cursor.X + menu.Style.Space, math.floor(menu.Y + menu.Cursor.Y + (boxHeight / 2) - (lblHeight / 2)), self.Label)
    else
        SetColorStyle(menu.Style.Text)
        draw.Text(menu.X + menu.Cursor.X + menu.Style.Space, math.floor(menu.Y + menu.Cursor.Y + (boxHeight / 2) - (lblHeight / 2)), self.Value)
    end

    menu.Cursor.Y = menu.Cursor.Y + boxHeight + menu.Style.Space
end

--[[ Combobox Compnent ]]
local Combobox = {
    Label = "New Combobox",
    Options = nil,
    Selected = nil,
    SelectedIndex = 1,
    _MaxSize = 0,
    _Child = nil
}
Combobox.__index = Combobox
setmetatable(Combobox, Component)

function Combobox.New(label, options, flags)
    assert(type(options) == "table", "Combobox options must be a table")
    flags = flags or ItemFlags.None

    local self = setmetatable({}, Combobox)
    self.ID = MenuManager.CurrentID
    self.Label = label .. " | V"
    self.Options = options
    self.Selected = options[1]
    self.Flags = flags

    self._Child = MenuManager.Create("Combobox Child #" .. self.ID, MenuFlags.Child |  MenuFlags.NoTitle | MenuFlags.NoDrag | MenuFlags.AutoSize)
    self._Child:SetVisible(false)
    self._Child.Style.Space = 3
    for i, vLabel in ipairs(self.Options) do
        self._Child:AddComponent(Button.New(vLabel, function()
            self.Selected = vLabel
            self.SelectedIndex = i
            self:UpdateButtons()
            self:SetOpen(false)
        end, ItemFlags.FullWidth))
    end

    MenuManager.CurrentID = MenuManager.CurrentID + 1
    return self
end

function Combobox:UpdateButtons()
    for i, vComponent in ipairs(self._Child.Components) do
        if vComponent.Label == self.Selected then
            vComponent.Flags = ItemFlags.FullWidth | ItemFlags.Active
        else
            vComponent.Flags = ItemFlags.FullWidth
        end
    end
end

function Combobox:GetSelectedIndex()
    return self.SelectedIndex
end

function Combobox:Select(index)
    self.SelectedIndex = index
    self.Selected = self.Options[index]
end

function Combobox:IsOpen()
    return self._Child.Visible
end

function Combobox:SetOpen(state)
    if state == false and self:IsOpen() == false then return end

    self._Child:SetVisible(state)
    IsInteracting = state
end

function Combobox:Render(menu)
    local lblWidth, lblHeight = draw.GetTextSize(self.Label)
    local cmbWidth = lblWidth + (menu.Style.Space * 4)
    if self.Flags & ItemFlags.FullWidth ~= 0 then
        cmbWidth = menu.Width - (menu.Style.Space * 2)
    end
    local cmbHeight = lblHeight + (menu.Style.Space * 2)

    -- Interaction
    SetColorStyle(menu.Style.Item)
    if (self:IsOpen() or IsInteracting == false) and MouseInBounds(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + cmbWidth, menu.Y + menu.Cursor.Y + cmbHeight) then
        if input.IsButtonDown(MOUSE_LEFT) then
            SetColorStyle(menu.Style.ItemActive)
        else
            SetColorStyle(menu.Style.ItemHover)
        end
        if MouseReleased then
            self:SetOpen(not self:IsOpen())
        end
    end

    if self:IsOpen() then
        self._Child.Width = cmbWidth
        self._Child.X = menu.X + menu.Cursor.X
        self._Child.Y = menu.Y + menu.Cursor.Y + cmbHeight
        SetColorStyle(menu.Style.ItemActive)
    end

    -- Drawing
    draw.FilledRect(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + cmbWidth, menu.Y + menu.Cursor.Y + cmbHeight)
    SetColorStyle(menu.Style.Text)
    draw.Text(math.floor(menu.X + menu.Cursor.X + (cmbWidth / 2) - (lblWidth / 2)), math.floor(menu.Y + menu.Cursor.Y + (cmbHeight / 2) - (lblHeight / 2)), self.Label)

    menu.Cursor.Y = menu.Cursor.Y + cmbHeight + menu.Style.Space
end

--[[ Multi Combobox Component ]]
local MultiCombobox = {
    Label = "New Multibox",
    Options = nil,
    _MaxSize = 0,
    _Child = nil
}
MultiCombobox.__index = MultiCombobox
setmetatable(MultiCombobox, Component)

function MultiCombobox.New(label, options, flags)
    assert(type(options) == "table", "Combobox options must be a table")
    flags = flags or ItemFlags.None

    local self = setmetatable({}, MultiCombobox)
    self.ID = MenuManager.CurrentID
    self.Label = label .. " | V"
    self.Options = options
    self.Flags = flags

    self._Child = MenuManager.Create("Multibox Child #" .. self.ID, MenuFlags.Child |  MenuFlags.NoTitle | MenuFlags.NoDrag | MenuFlags.AutoSize)
    self._Child:SetVisible(false)
    self._Child.Style.Space = 3
    for kOption, vActive in pairs(self.Options) do
        self._Child:AddComponent(Button.New(kOption, function()
            self.Options[kOption] = not self.Options[kOption]
            self:UpdateButtons()
            self:SetOpen(false)
        end, ItemFlags.FullWidth))
    end

    MenuManager.CurrentID = MenuManager.CurrentID + 1
    return self
end

function MultiCombobox:UpdateButtons()
    for i, vComponent in ipairs(self._Child.Components) do
        if self.Options[vComponent.Label] == true then
            vComponent.Flags = ItemFlags.FullWidth | ItemFlags.Active
        else
            vComponent.Flags = ItemFlags.FullWidth
        end
    end
end

function MultiCombobox:Select(index)
    self.Options[index][2] = true
end

function MultiCombobox:IsOpen()
    return self._Child.Visible
end

function MultiCombobox:SetOpen(state)
    if state == false and self:IsOpen() == false then return end

    self._Child:SetVisible(state)
    IsInteracting = state
end

function MultiCombobox:Render(menu)
    local lblWidth, lblHeight = draw.GetTextSize(self.Label)
    local cmbWidth = lblWidth + (menu.Style.Space * 4)
    if self.Flags & ItemFlags.FullWidth ~= 0 then
        cmbWidth = menu.Width - (menu.Style.Space * 2)
    end
    local cmbHeight = lblHeight + (menu.Style.Space * 2)

    -- Interaction
    SetColorStyle(menu.Style.Item)
    if (self:IsOpen() or IsInteracting == false) and MouseInBounds(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + cmbWidth, menu.Y + menu.Cursor.Y + cmbHeight) then
        if input.IsButtonDown(MOUSE_LEFT) then
            SetColorStyle(menu.Style.ItemActive)
        else
            SetColorStyle(menu.Style.ItemHover)
        end
        if MouseReleased then
            self:SetOpen(not self:IsOpen())
        end
    end

    if self:IsOpen() then
        self._Child.Width = cmbWidth
        self._Child.X = menu.X + menu.Cursor.X
        self._Child.Y = menu.Y + menu.Cursor.Y + cmbHeight
        SetColorStyle(menu.Style.ItemActive)
    end

    -- Drawing
    draw.FilledRect(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + cmbWidth, menu.Y + menu.Cursor.Y + cmbHeight)
    SetColorStyle(menu.Style.Text)
    draw.Text(math.floor(menu.X + menu.Cursor.X + (cmbWidth / 2) - (lblWidth / 2)), math.floor(menu.Y + menu.Cursor.Y + (cmbHeight / 2) - (lblHeight / 2)), self.Label)

    menu.Cursor.Y = menu.Cursor.Y + cmbHeight + menu.Style.Space
end

--[[ Menu Class ]]
local Menu = {
    ID = 0,
    Title = "Menu",
    Components = nil,
    Visible = true,
    X = 100, Y = 100,
    Width = 200, Height = 200,
    Cursor = { X = 0, Y = 0 },
    Style = {},
    Flags = 0,
    _AutoH = 0
}

local MetaMenu = {}
MetaMenu.__index = Menu

function Menu.New(title, flags)
    local self = setmetatable({}, MetaMenu)
    self.ID = MenuManager.CurrentID
    self.Title = title
    self.Components = {}
    self.Style = {
        Space = 4,
        Font = MenuManager.Font,
        WindowBg = { 30, 30, 30, 255 },
        TitleBg = { 55, 100, 215, 255 },
        Text = { 255, 255, 255, 255 },
        Item = { 50, 50, 50, 255 },
        ItemHover = { 65, 65, 65, 255 },
        ItemActive = { 80, 80, 80, 255 },
        Highlight = { 180, 180, 180, 100 }
    }
    self.Flags = flags

    MenuManager.CurrentID = MenuManager.CurrentID + 1
    return self
end

function Menu:SetVisible(visible)
    self.Visible = visible
end

function Menu:Toggle()
    self.Visible = not self.Visible
end

function Menu:SetTitle(title)
    self.Title = title
end

function Menu:SetPosition(x, y)
    self.X = x
    self.Y = y
end

function Menu:SetSize(width, height)
    self.Width = width
    self.Height = height
end

function Menu:AddComponent(component)
    table.insert(self.Components, component)
    return component
end

function Menu:RemoveComponent(component)
    for k, vComp in pairs(self.Components) do
        if vComp.ID == component.ID then
            table.remove(self.Components, k)
            return
        end
    end
end

function Menu:Remove()
    MenuManager.RemoveMenu(self)
end

--[[ Menu Manager ]]
function MenuManager.Create(title, flags)
    flags = flags or MenuFlags.None

    local menu = Menu.New(title, flags)
    MenuManager.AddMenu(menu)
    return menu
end

function MenuManager.AddMenu(menu)
    table.insert(MenuManager.Menus, menu)
end

function MenuManager.RemoveMenu(menu)
    for k, vMenu in pairs(MenuManager.Menus) do
        if vMenu.ID == menu.ID then
            vMenu.Components = {}
            table.remove(MenuManager.Menus, k)
            return
        end
    end
end

function MenuManager.Label(text, flags)
    return Label.New(text, flags)
end

function MenuManager.Checkbox(label, value, flags)
    return Checkbox.New(label, value, flags)
end

function MenuManager.Button(label, callback, flags)
    return Button.New(label, callback, flags)
end

function MenuManager.Slider(label, min, max, value, flags)
    value = value or min
    return Slider.New(label, min, max, value, flags)
end

function MenuManager.Textbox(label, value, flags)
    value = value or ""
    return Textbox.New(label, value, flags)
end

function MenuManager.Combo(label, options, flags)
    return Combobox.New(label, options, flags)
end

function MenuManager.MultiCombo(label, options, flags)
    return MultiCombobox.New(label, options, flags)
end

function MenuManager.Seperator(flags)
    return Label.New("", flags)
end

-- Renders the menus and components
function MenuManager.Draw()
    -- Don't draw if we should ignore screenshots
    if gui.GetValue("clean screenshots") == 1 and engine.IsTakingScreenshot() then
        return
    end

    draw.Color(255, 255, 255, 255)
    draw.SetFont(MenuManager.Font)

    if MenuManager.DebugInfo then
        MenuManager.DrawDebug()
    end

    UpdateMouseState()

    for k, vMenu in pairs(MenuManager.Menus) do
        if not vMenu.Visible then
            goto continue
        end

        if engine.GetServerIP() ~= "" and engine.IsGameUIVisible() == false and (vMenu.Flags & MenuFlags.ShowAlways == 0) then
            return
        end

        local tbHeight = 20

        -- Auto Size
        if vMenu.Flags & MenuFlags.AutoSize ~= 0 then
            vMenu.Height = vMenu._AutoH
        end

        -- Window drag
        if vMenu.Flags & MenuFlags.NoDrag == 0 then
            local mX = input.GetMousePos()[1]
            local mY = input.GetMousePos()[2]
            if DragID == vMenu.ID then
                if input.IsButtonDown(MOUSE_LEFT) then
                    vMenu.X = mX - DragOffset[1]
                    vMenu.Y = mY - DragOffset[2]
                else
                    DragID = 0
                end
            elseif DragID == 0 then
                if input.IsButtonDown(MOUSE_LEFT) and MouseInBounds(vMenu.X, vMenu.Y, vMenu.X + vMenu.Width, vMenu.Y + tbHeight) then
                    DragOffset = { mX - vMenu.X, mY - vMenu.Y }
                    DragID = vMenu.ID
                end
            end
        end

        -- Background
        if vMenu.Flags & MenuFlags.NoBackground == 0 then
            SetColorStyle(vMenu.Style.WindowBg)
            draw.FilledRect(vMenu.X, vMenu.Y, vMenu.X + vMenu.Width, vMenu.Y + vMenu.Height)
        end

        -- Menu Title
        if vMenu.Flags & MenuFlags.NoTitle == 0 then
            SetColorStyle(vMenu.Style.TitleBg)
            draw.FilledRect(vMenu.X, vMenu.Y, vMenu.X + vMenu.Width, vMenu.Y + tbHeight)
            SetColorStyle(vMenu.Style.Text)
            local titleWidth, titleHeight = draw.GetTextSize(vMenu.Title)
            draw.Text(math.floor(vMenu.X + (vMenu.Width / 2) - (titleWidth / 2)), vMenu.Y + math.floor((tbHeight / 2) - (titleHeight / 2)), vMenu.Title)
            vMenu.Cursor.Y = vMenu.Cursor.Y + tbHeight
        end

        -- Draw Components
        vMenu.Cursor.Y = vMenu.Cursor.Y + vMenu.Style.Space
        vMenu.Cursor.X = vMenu.Cursor.X + vMenu.Style.Space
        for k, vComponent in pairs(vMenu.Components) do
            if vComponent.Visible == true and vMenu.Cursor.Y < vMenu.Height then
                vComponent:Render(vMenu)
            end
        end

        -- Reset Cursor
        vMenu._AutoH = vMenu.Cursor.Y + vMenu.Style.Space
        vMenu.Cursor = { X = 0, Y = 0 }
        ::continue::
    end
end

-- Prints debug info about menus and components
function MenuManager.DrawDebug()
    draw.Text(50, 50, "## DEBUG INFO ##")

    local currentY = 70
    local currentX = 50
    for k, vMenu in pairs(MenuManager.Menus) do
        draw.Text(currentX, currentY, "Menu: " .. vMenu.Title .. ", Flags: " .. vMenu.Flags)
        currentY = currentY + 20
        currentX = currentX + 20
        for k, vComponent in pairs(vMenu.Components) do
            draw.Text(currentX, currentY, "Component-ID: " .. vComponent.ID .. ", Visible: " .. tostring(vComponent.Visible))
            currentY = currentY + 20
        end
        currentX = currentX - 20
        currentY = currentY + 10
    end
end

-- Register Callbacks
callbacks.Unregister("Draw", "Draw_MenuManager")
callbacks.Register("Draw", "Draw_MenuManager", MenuManager.Draw)

print("Menu Library loaded! Version: " .. MenuManager.Version)

return MenuManager
