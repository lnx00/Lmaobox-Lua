--[[
    Menu Library for Lmaobox (WIP)
    Author: LNX (github.com/lnx00)
]]

--[[ Utils ]]--
function MouseInBounds(pX, pY, pX2, pY2)
    local mX = input.GetMousePos()[1]
    local mY = input.GetMousePos()[2]
    if mX > pX and mX < pX2 and mY > pY and mY < pY2 then
        return true
    end
    return false
end

--[[ Components ]]--
local Component = {
    Name = "",
    Value = nil
}

local MetaComponent = {}
MetaComponent.__index = Component

--[[ Menu ]]--
local Menu = {
    IsOpen = false,
    IsDragging = false,
    Title = "My Menu",
    X = 100,
    Y = 100,
    Width = 200,
    Height = 200,
    Components = {}
}

local MetaMenu = {}
MetaMenu.__index = Menu
local MenuTable = {}

local font_Verdana = draw.CreateFont("verdana", 14, 510)
local anyDragging = false

function Menu.Create(pTitle, pOpen)
    local instance = setmetatable({}, MetaMenu)
    instance.Title = pTitle
    instance.IsOpen = pOpen

    table.insert(MenuTable, instance)
    return instance
end

-- FIXME: Components get added to all windows for some reason
function Menu:AddComponent(pName, pValue)
    local instance = setmetatable({}, MetaComponent)
    instance.Name = pName
    instance.Value = pValue

    table.insert(self.Components, instance)
    return instance
end

function Menu.DrawMenus()
    anyDragging = false

    -- Iterate through all menus
    draw.SetFont(font_Verdana)
    for key, m in pairs(MenuTable) do   -- TODO: Is this correct?
        if m.IsOpen then
            if m.IsDragging then
                local mX = input.GetMousePos()[1]
                local mY = input.GetMousePos()[2]
                m.X = mX - (m.Width / 2)
                m.Y = mY - 5
                m.IsDragging = false
            end

            -- Window background
            draw.Color(40, 40, 50, 210)
            draw.FilledRect(m.X, m.Y, m.X + m.Width, m.Y + m.Height + 20)

            -- Window title
            draw.Color(40, 130, 185, 255)
            draw.FilledRect(m.X, m.Y, m.X + m.Width, m.Y + 20)
            draw.Color(255, 255, 255, 255)
            draw.TextShadow(m.X + 4, m.Y + 2, m.Title)

            -- Window component
            local currentY = m.Y + 23
            for cKey, c in pairs(m.Components) do
                local cType = type(c.Value)
                if cType == "string" then
                    -- Draw String
                    draw.Color(255, 255, 255, 255)
                    draw.Text(m.X + 4, currentY + 5, c.Value)
                elseif cType == "boolean" then
                    -- Draw Checkbox
                    if c.Value then
                        draw.Color(70, 190, 50, 255)
                    else
                        draw.Color(190, 50, 20, 255)
                    end
                    draw.FilledRect(m.X + 4, currentY + 2, m.X + 24, currentY + 22)
                    draw.Color(255, 255, 255, 255)
                    draw.Text(m.X + 28, currentY + 5, c.Name)

                    -- Toggle on Click
                    if not anyDragging and input.IsButtonDown(MOUSE_LEFT) then
                        if MouseInBounds(m.X + 4, currentY + 2, m.X + 24, currentY + 22) then
                            c.Value = not c.Value
                        end
                    end
                end

                currentY = currentY + 24
                if currentY > (m.Y + m.Height) then
                    goto continue
                end
            end

            -- Mouse interaction
            if not anyDragging and input.IsButtonDown(MOUSE_LEFT) then
                -- Window title
                if MouseInBounds(m.X, m.Y, m.X + m.Width, m.Y + 30) then
                    m.IsDragging = true
                    anyDragging = true
                end
            end
        end

        ::continue::
    end
end

callbacks.Unregister("Draw", "Draw_Menu");
callbacks.Register("Draw", "Draw_Menu", Menu.DrawMenus)

return Menu