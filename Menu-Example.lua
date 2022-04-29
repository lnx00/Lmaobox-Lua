local MenuLib = require("Menu")

-- Check the menu version to prevent errors due to changes in the library
assert(MenuLib.Version >= 1.35, "MenuLib version is too old, please update to 1.35 or newer! Current version: " .. MenuLib.Version)

-- Create a menu
local menu = MenuLib.Create("Example Menu", MenuFlags.AutoSize)
menu:AddComponent(MenuLib.Label("This is our first menu."))

-- Add a checkbox
local checkbox = menu:AddComponent(MenuLib.Checkbox("Enable Feature", true))

-- Add a button with callback that fills the width of the window
function OnButtonPress() 
    print("Button pressed!")
end
menu:AddComponent(MenuLib.Button("Press Me!", OnButtonPress, ItemFlags.FullWidth))

-- Add a slider with minimum and maximum
menu:AddComponent(MenuLib.Slider("Text Size", 20, 100, 60))
menu:AddComponent(MenuLib.Seperator())

-- Add a textbox
local textBox = menu:AddComponent(MenuLib.Textbox("Write something..."))
menu:AddComponent(MenuLib.Seperator())

-- Add a combobox
local itemCombo = {
    "Label",
    "Checkbox"
}
local combo = menu:AddComponent(MenuLib.Combo("Combo", itemCombo))

-- Add a button to add the previously selected element
function AddElement()
    if combo.Selected == "Label" then
        menu:AddComponent(MenuLib.Label("You wrote: " .. textBox:GetValue()))
    elseif combo.Selected == "Checkbox" then
        menu:AddComponent(MenuLib.Checkbox("This is a checkbox.", checkbox:GetValue()))
    end
end
menu:AddComponent(MenuLib.Button("Add Element!", AddElement))

-- Add a multi combobox
local multiCombo = {
    ["Head"] = true,
    ["Body"] = false,
    ["Legs"] = false
}
menu:AddComponent(MenuLib.MultiCombo("Targets", multiCombo))

local function OnUnload()
    -- Remove our menu before unloading the script
    MenuLib.RemoveMenu(menu)
end

callbacks.Register("Unload", OnUnload)