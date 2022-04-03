--[[
    Menu Library for Lmaobox
    Author: LNX (github.com/lnx00)
]]
local MenuManager = {
    CurrentID = 1,
    Menus = {},
    Font = draw.CreateFont("Verdana", 14, 510)
}

local lastMouseState = false
local mouseUp = false
local dragID = 0

local function MouseInBounds(pX, pY, pX2, pY2)
    local mX = input.GetMousePos()[1]
    local mY = input.GetMousePos()[2]
    if mX > pX and mX < pX2 and mY > pY and mY < pY2 then
        return true
    end
    return false
end

local function UpdateMouseState()
    local mouseState = input.IsButtonDown(MOUSE_LEFT)
    if mouseState == false and lastMouseState == true then
        mouseUp = true
    else
        mouseUp = false
    end
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
    if self.Value then
        draw.Color(68, 189, 50, 255)
    else
        draw.Color(194, 54, 22, 255)
    end

    local lblWidth, lblHeight = draw.GetTextSize(self.Label)
    local chkSize = math.floor(lblHeight * 1.4)

    -- Interaction
    if mouseUp and MouseInBounds(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + chkSize, menu.Y + menu.Cursor.Y + chkSize) then
        self.Value = not self.Value
    end

    -- Drawing
    draw.FilledRect(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + chkSize, menu.Y + menu.Cursor.Y + chkSize)
    draw.SetFont(MenuManager.Font)
    draw.Color(255, 255, 255, 255)
    draw.Text(menu.X + menu.Cursor.X + chkSize + menu.Space, math.floor(menu.Y + menu.Cursor.Y + (chkSize / 2) - (lblHeight / 2)), self.Label)
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
end

--[[ Menu Class ]]
local Menu = {
    ID = 0,
    Title = "Menu",
    Components = nil,
    X = 100, Y = 100,
    Width = 200, Height = 200,
    Cursor = { X = 0, Y = 0 },
    Space = 4
}

MetaMenu = {}
MetaMenu.__index = Menu

-- create a constructor for menu that takes a title
function Menu.New(title)
    local self = setmetatable({}, MetaMenu)
    self.ID = MenuManager.CurrentID
    self.Title = title
    self.Components = {}

    MenuManager.CurrentID = MenuManager.CurrentID + 1
    return self
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
end

function Menu:Show()
    self.Visible = true
end

--[[ Menu Manager ]]
function MenuManager.Create(title)
    local menu = Menu.New(title)
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

-- Renders the menus and components
function MenuManager.Draw()
    -- Don't draw if we should ignore screenshots
    if gui.GetValue("clean screenshots") == 1 and engine.IsTakingScreenshot() then
        return
    end

    MenuManager.DrawDebug()
    UpdateMouseState()

    for k, vMenu in pairs(MenuManager.Menus) do
        local titleHeight = 20

        -- Window drag
        if dragID == vMenu.ID then
            if input.IsButtonDown(MOUSE_LEFT) then
                local mX = input.GetMousePos()[1]
                local mY = input.GetMousePos()[2]
                vMenu.X = mX - vMenu.Width / 2
                vMenu.Y = mY - 10
            else
                dragID = 0
            end
        elseif dragID == 0 then
            if input.IsButtonDown(MOUSE_LEFT) and MouseInBounds(vMenu.X, vMenu.Y, vMenu.X + vMenu.Width, vMenu.Y + 20) then
                dragID = vMenu.ID
            end
        end

        -- Menu Title
        draw.Color(30, 30, 30, 250)
        draw.FilledRect(vMenu.X, vMenu.Y, vMenu.X + vMenu.Width, vMenu.Y + vMenu.Height)
        draw.Color(56, 103, 214, 255)
        draw.FilledRect(vMenu.X, vMenu.Y, vMenu.X + vMenu.Width, vMenu.Y + 20)
        draw.Color(255, 255, 255, 255)
        local titleWidth, titleHeight = draw.GetTextSize(vMenu.Title)
        draw.Text(math.floor(vMenu.X + (vMenu.Width / 2) - (titleWidth / 2)), vMenu.Y + math.floor(10 - (titleHeight / 2)), vMenu.Title)

        -- Draw Components
        vMenu.Cursor.Y = vMenu.Cursor.Y + 20 + vMenu.Space
        vMenu.Cursor.X = vMenu.Cursor.X + vMenu.Space
        for k, vComponent in pairs(vMenu.Components) do
            vComponent:Render(vMenu)
        end

        -- Reset Cursor
        vMenu.Cursor = { X = 0, Y = 0 }
    end
end

-- Prints debug info about menus and components
function MenuManager.DrawDebug()
    draw.Color(255, 255, 255, 255)
    draw.SetFont(MenuManager.Font)
    draw.Text(50, 50, "## DEBUG INFO ##")

    local currentY = 70
    local currentX = 50
    for k, vMenu in pairs(MenuManager.Menus) do
        draw.Text(currentX, currentY, "Menu: " .. vMenu.Title)
        currentY = currentY + 20
        currentX = currentX + 20
        for k, vComponent in pairs(vMenu.Components) do
            draw.Text(currentX, currentY, "Component-ID: " .. vComponent.ID .. ", Visible: " .. tostring(vComponent.Visible))
            currentY = currentY + 20
        end
        currentX = currentX - 25
    end
end

-- Callbacks
callbacks.Unregister("Draw", "Draw_MenuManager")
callbacks.Register("Draw", "Draw_MenuManager", MenuManager.Draw)

print("Menu Library by LNX loaded! v0.2")

return MenuManager