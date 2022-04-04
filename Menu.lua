--[[
    Menu Library for Lmaobox
    Author: LNX (github.com/lnx00)
]]
local MenuManager = {
    CurrentID = 1,
    Menus = {},
    Font = draw.CreateFont("Verdana", 14, 510),
    Version = 1.0,
    DebugInfo = false
}

MenuFlags = {
    None = 0,
    NoTitle = 1 << 0, -- No title bar
    NoBackground = 1 << 1, -- No window background
    NoDrag = 1 << 2, -- Disable dragging
    AutoSize = 1 << 3 -- Auto size height to contents
}

local lastMouseState = false
local mouseUp = false
local dragID = 0
local dragOffset = {0, 0}

local function MouseInBounds(pX, pY, pX2, pY2)
    local mX = input.GetMousePos()[1]
    local mY = input.GetMousePos()[2]
    return (mX > pX and mX < pX2 and mY > pY and mY < pY2)
end

local function UpdateMouseState()
    local mouseState = input.IsButtonDown(MOUSE_LEFT)
    mouseUp = (mouseState == false and lastMouseState == true)
    lastMouseState = mouseState
end

--[[ Component Class ]]
Component = {
    ID = 0,
    Visible = true
}
Component.__index = Component

function Component.New()
    local self = setmetatable({}, Component)
    self.Visible = true

    return self
end

function Component:SetVisible(state)
    self.Visible = state
end

--[[ Label Component ]]
Label = {
    Text = "New Label"
}
Label.__index = Label
setmetatable(Label, Component)

function Label.New(label)
    local self = setmetatable({}, Label)
    self.ID = MenuManager.CurrentID
    self.Text = label

    MenuManager.CurrentID = MenuManager.CurrentID + 1
    return self
end

function Label:Render(menu)
    draw.Color(255, 255, 255, 255)
    draw.SetFont(MenuManager.Font)
    draw.Text(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, self.Text)
    local textWidth, textHeight = draw.GetTextSize(self.Text)

    menu.Cursor.Y = menu.Cursor.Y + textHeight + menu.Space
end

--[[ Checkbox Component ]]
Checkbox = {
    Label = "New Checkbox",
    Value = false
}
Checkbox.__index = Checkbox
setmetatable(Checkbox, Component)

function Checkbox.New(label, value)
    assert(type(value) == "boolean", "Checkbox value must be a boolean")

    local self = setmetatable({}, Checkbox)
    self.ID = MenuManager.CurrentID
    self.Label = label
    self.Value = value

    MenuManager.CurrentID = MenuManager.CurrentID + 1
    return self
end

function Checkbox:Render(menu)
    local lblWidth, lblHeight = draw.GetTextSize(self.Label)
    local chkSize = math.floor(lblHeight * 1.4)

    -- Interaction
    if mouseUp and MouseInBounds(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + chkSize, menu.Y + menu.Cursor.Y + chkSize) then
        self.Value = not self.Value
    end

    if self.Value == true then
        draw.Color(68, 189, 50, 255) -- Checked
    else
        draw.Color(179, 57, 57, 255) -- Unchecked
    end

    -- Drawing
    draw.FilledRect(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + chkSize, menu.Y + menu.Cursor.Y + chkSize)
    draw.SetFont(MenuManager.Font)
    draw.Color(255, 255, 255, 255)
    draw.Text(menu.X + menu.Cursor.X + chkSize + menu.Space, math.floor(menu.Y + menu.Cursor.Y + (chkSize / 2) - (lblHeight / 2)), self.Label)

    if self.Value == true then
        draw.Color(255, 255, 255, 120)
        draw.FilledRect(math.floor(menu.X + menu.Cursor.X + menu.Space), math.floor(menu.Y + menu.Cursor.Y + menu.Space), math.ceil(menu.X + menu.Cursor.X + chkSize - menu.Space), math.ceil(menu.Y + menu.Cursor.Y + chkSize - menu.Space))
    end

    menu.Cursor.Y = menu.Cursor.Y + chkSize + menu.Space
end

--[[ Button Component ]]
Button = {
    Label = "New Button",
    Callback = nil
}
Button.__index = Button
setmetatable(Button, Component)

function Button.New(label, callback)
    assert(type(callback) == "function", "Button callback must be a function")

    local self = setmetatable({}, Button)
    self.ID = MenuManager.CurrentID
    self.Label = label
    self.Callback = callback

    MenuManager.CurrentID = MenuManager.CurrentID + 1
    return self
end

function Button:Render(menu)
    local lblWidth, lblHeight = draw.GetTextSize(self.Label)
    local btnWidth = lblWidth + (menu.Space * 4)
    local btnHeight = lblHeight + (menu.Space * 2)
    
    -- Interaction
    draw.Color(55, 55, 55, 255)
    if MouseInBounds(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + btnWidth, menu.Y + menu.Cursor.Y + btnHeight) then
        if input.IsButtonDown(MOUSE_LEFT) then
            draw.Color(70, 70, 70, 255)
        end
        if mouseUp then
            self:Callback()
        end
    end

    -- Drawing
    draw.FilledRect(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + btnWidth, menu.Y + menu.Cursor.Y + btnHeight)
    draw.Color(255, 255, 255, 255)
    draw.Text(math.floor(menu.X + menu.Cursor.X + (btnWidth / 2) - (lblWidth / 2)), math.floor(menu.Y + menu.Cursor.Y + (btnHeight / 2) - (lblHeight / 2)), self.Label)

    menu.Cursor.Y = menu.Cursor.Y + btnHeight + menu.Space
end

--[[ Combobox Compnent ]]
Combobox = {
    Label = "New Combobox",
    Options = nil,
    Selected = nil,
    SelectedIndex = 1,
    Open = false,
    _MaxSize = 0
}
Combobox.__index = Combobox
setmetatable(Combobox, Component)

function Combobox.New(label, options)
    assert(type(options) == "table", "Combobox options must be a table")

    local self = setmetatable({}, Combobox)
    self.ID = MenuManager.CurrentID
    self.Label = label
    self.Options = options

    MenuManager.CurrentID = MenuManager.CurrentID + 1
    return self
end

function Combobox:Select(index)
    self.SelectedIndex = index
    self.Selected = self.Options[index]
end

function Combobox:Render(menu)
    local lblWidth, lblHeight = draw.GetTextSize(self.Label)
    local cmbWidth = lblWidth + (menu.Space * 4)
    local cmbHeight = lblHeight + (menu.Space * 2)

    -- Interaction
    draw.Color(55, 55, 55, 255)
    if MouseInBounds(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + cmbWidth, menu.Y + menu.Cursor.Y + cmbHeight) then
        if input.IsButtonDown(MOUSE_LEFT) then
            draw.Color(70, 70, 70, 255)
        end
        if mouseUp then
            self.Open = not self.Open
        end
    end

    if self.Open then
        draw.Color(75, 75, 75, 255)
    end

    -- Drawing
    draw.FilledRect(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + cmbWidth, menu.Y + menu.Cursor.Y + cmbHeight)
    draw.Color(255, 255, 255, 255)
    draw.Text(math.floor(menu.X + menu.Cursor.X + (cmbWidth / 2) - (lblWidth / 2)), math.floor(menu.Y + menu.Cursor.Y + (cmbHeight / 2) - (lblHeight / 2)), self.Label)

    if self.Open then
        menu.Cursor.Y = menu.Cursor.Y + cmbHeight
        for i, vOption in ipairs(self.Options) do
            local olWidth, olHeight = draw.GetTextSize(vOption)
            if self._MaxSize > olWidth then
                olWidth = self._MaxSize
            end
            local optActive = (i == self.SelectedIndex)

            -- Interaction
            if optActive then
                draw.Color(90, 100, 90, 255)
            else
                draw.Color(65, 65, 65, 250)
            end
            if MouseInBounds(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + olWidth + (menu.Space * 2), menu.Y + menu.Cursor.Y + olHeight + (menu.Space * 2)) then
                if input.IsButtonDown(MOUSE_LEFT) then
                    draw.Color(70, 70, 70, 255)
                end
                if mouseUp then
                    self.Selected = vOption
                    self.SelectedIndex = i
                    self.Open = false
                end
            end

            -- Drawing
            draw.FilledRect(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + olWidth + (menu.Space * 2), menu.Y + menu.Cursor.Y + olHeight + (menu.Space * 2))
            draw.Color(255, 255, 255, 255)
            draw.Text(menu.X + menu.Cursor.X + menu.Space, menu.Y + menu.Cursor.Y + menu.Space, vOption)
            
            if olWidth > self._MaxSize then
                self._MaxSize = olWidth
            elseif cmbWidth > self._MaxSize then
                self._MaxSize = cmbWidth
            end

            menu.Cursor.Y = menu.Cursor.Y + olHeight + (menu.Space * 2)
        end
    end

    menu.Cursor.Y = menu.Cursor.Y + cmbHeight + menu.Space
end

--[[ Multi Combobox Component ]]
MultiCombobox = {
    Label = "New Multibox",
    Options = nil,
    Open = false,
    _MaxSize = 0
}
MultiCombobox.__index = MultiCombobox
setmetatable(MultiCombobox, Component)

function MultiCombobox.New(label, options)
    assert(type(options) == "table", "Combobox options must be a table")

    local self = setmetatable({}, MultiCombobox)
    self.ID = MenuManager.CurrentID
    self.Label = label
    self.Options = options

    MenuManager.CurrentID = MenuManager.CurrentID + 1
    return self
end

function MultiCombobox:Select(index)
    self.Options[index][2] = true
end

function MultiCombobox:Render(menu)
    local lblWidth, lblHeight = draw.GetTextSize(self.Label)
    local cmbWidth = lblWidth + (menu.Space * 4)
    local cmbHeight = lblHeight + (menu.Space * 2)

    -- Interaction
    draw.Color(55, 55, 55, 255)
    if MouseInBounds(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + cmbWidth, menu.Y + menu.Cursor.Y + cmbHeight) then
        if input.IsButtonDown(MOUSE_LEFT) then
            draw.Color(70, 70, 70, 255)
        end
        if mouseUp then
            self.Open = not self.Open
        end
    end

    if self.Open then
        draw.Color(75, 75, 75, 255)
    end

    -- Drawing
    draw.FilledRect(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + cmbWidth, menu.Y + menu.Cursor.Y + cmbHeight)
    draw.Color(255, 255, 255, 255)
    draw.Text(math.floor(menu.X + menu.Cursor.X + (cmbWidth / 2) - (lblWidth / 2)), math.floor(menu.Y + menu.Cursor.Y + (cmbHeight / 2) - (lblHeight / 2)), self.Label)

    if self.Open then
        menu.Cursor.Y = menu.Cursor.Y + cmbHeight
        for i, vOption in ipairs(self.Options) do
            local olWidth, olHeight = draw.GetTextSize(vOption[1])
            if self._MaxSize > olWidth then
                olWidth = self._MaxSize
            end

            -- Interaction
            if vOption[2] == true then
                draw.Color(90, 100, 90, 255)
            else
                draw.Color(65, 65, 65, 250)
            end
            if MouseInBounds(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + olWidth, menu.Y + menu.Cursor.Y + olHeight) then
                if vOption[2] == true == false and input.IsButtonDown(MOUSE_LEFT) then
                    draw.Color(70, 70, 70, 255)
                end
                if mouseUp then
                    self.Options[i][2] = not self.Options[i][2]
                end
            end

            -- Drawing
            draw.FilledRect(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + olWidth + (menu.Space * 2), menu.Y + menu.Cursor.Y + olHeight + (menu.Space * 2))
            draw.Color(255, 255, 255, 255)
            draw.Text(menu.X + menu.Cursor.X + menu.Space, menu.Y + menu.Cursor.Y + menu.Space, vOption[1])
            
            if olWidth > self._MaxSize then
                self._MaxSize = olWidth
            elseif cmbWidth > self._MaxSize then
                self._MaxSize = cmbWidth
            end

            menu.Cursor.Y = menu.Cursor.Y + olHeight + (menu.Space * 2)
        end
    end

    menu.Cursor.Y = menu.Cursor.Y + cmbHeight + menu.Space
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
    Space = 4,
    Flags = 0,
    _AutoH = 0
}

MetaMenu = {}
MetaMenu.__index = Menu

function Menu.New(title, flags)
    local self = setmetatable({}, MetaMenu)
    self.ID = MenuManager.CurrentID
    self.Title = title
    self.Components = {}
    self.Flags = flags

    MenuManager.CurrentID = MenuManager.CurrentID + 1
    return self
end

function Menu:SetVisible(visible)
    self.Visible = visible
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

-- remove a given component
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
    print("Title: " .. title .. ", Flags: " .. flags)

    local menu = Menu.New(title, flags)
    MenuManager.AddMenu(menu)
    return menu
end

function MenuManager.AddMenu(menu)
    table.insert(MenuManager.Menus, menu)
end

function MenuManager.RemoveMenu(menu)
    for i, v in ipairs(MenuManager.Menus) do
        if v.ID == menu.ID then
            table.remove(MenuManager.Menus, i)
            break
        end
    end
end

function MenuManager.Label(text)
    return Label.New(text)
end

function MenuManager.Checkbox(label, value)
    return Checkbox.New(label, value)
end

function MenuManager.Button(label, callback)
    return Button.New(label, callback)
end

function MenuManager.Combo(label, options)
    return Combobox.New(label, options)    
end

function MenuManager.MultiCombo(label, options)
    return MultiCombobox.New(label, options)
end

-- Renders the menus and components
function MenuManager.Draw()
    if engine.GetServerIP() ~= "" and engine.IsGameUIVisible() == false then
        return
    end

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

        local tbHeight = 20

        -- Auto Size
        if vMenu.Flags & MenuFlags.AutoSize ~= 0 then
            vMenu.Height = vMenu._AutoH
        end

        -- Window drag
        if vMenu.Flags & MenuFlags.NoDrag == 0 then
            local mX = input.GetMousePos()[1]
            local mY = input.GetMousePos()[2]
            if dragID == vMenu.ID then
                if input.IsButtonDown(MOUSE_LEFT) then
                    vMenu.X = mX - dragOffset[1]
                    vMenu.Y = mY - dragOffset[2]
                else
                    dragID = 0
                end
            elseif dragID == 0 then
                if input.IsButtonDown(MOUSE_LEFT) and MouseInBounds(vMenu.X, vMenu.Y, vMenu.X + vMenu.Width, vMenu.Y + tbHeight) then
                    dragOffset = { mX - vMenu.X, mY - vMenu.Y }
                    dragID = vMenu.ID
                end
            end
        end

        -- Background
        if vMenu.Flags & MenuFlags.NoBackground == 0 then
            draw.Color(30, 30, 30, 250)
            draw.FilledRect(vMenu.X, vMenu.Y, vMenu.X + vMenu.Width, vMenu.Y + vMenu.Height)
        end

        -- Menu Title
        if vMenu.Flags & MenuFlags.NoTitle == 0 then
            draw.Color(56, 103, 214, 255)
            draw.FilledRect(vMenu.X, vMenu.Y, vMenu.X + vMenu.Width, vMenu.Y + tbHeight)
            draw.Color(255, 255, 255, 255)
            local titleWidth, titleHeight = draw.GetTextSize(vMenu.Title)
            draw.Text(math.floor(vMenu.X + (vMenu.Width / 2) - (titleWidth / 2)), vMenu.Y + math.floor((tbHeight / 2) - (titleHeight / 2)), vMenu.Title)
            vMenu.Cursor.Y = vMenu.Cursor.Y + tbHeight
        end

        -- Draw Components
        vMenu.Cursor.Y = vMenu.Cursor.Y + vMenu.Space
        vMenu.Cursor.X = vMenu.Cursor.X + vMenu.Space
        for k, vComponent in pairs(vMenu.Components) do
            if vComponent.Visible == true and vMenu.Cursor.Y < vMenu.Height then
                vComponent:Render(vMenu)
            end
        end

        -- Reset Cursor
        vMenu._AutoH = vMenu.Cursor.Y + vMenu.Space
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

-- Callbacks
callbacks.Unregister("Draw", "Draw_MenuManager")
callbacks.Register("Draw", "Draw_MenuManager", MenuManager.Draw)

print("Menu Library loaded!")

return MenuManager