# Menu Library
Menu.lua is an easy-to-use Menu Library for Lmaobox. It allows you to create interactive menus for your scripts to configure various things.

## Components
- Label: `MenuLib.Label("Text")`
- Checkbox: `MenuLib.Checkbox("Checkbox Label", option)`
- Button: `MenuLib.Button("Button Label", callback)`
- Combobox: `MenuLib.Combo("Combo Label", options)`
- Multi Combobox: `MenuLib.MultiCombo("Combo Label", options)`

## Usage
Place the `Menu.lua` in the same folder as your script and load the Menu module at the beginning of you script using:
```
local MenuLib = require("Menu")
```

If you want to make your Menus optional, independant from Menu.lua, then you can do this:
```
local menuLoaded, MenuLib = pcall(require, "Menu")
if (menuLoaded) then
  -- Your menu code here
end
```

## Auto Menu
If you don't want to mess around with the menu components, then you can automatically generate a config menu for your script.
To do this, you have to format your options like this:
```
local options = {
  Option_1 = true,
  Option_2 = false,
  Text_1 = "My Text",
  ...
}
MenuLib.Auto("Menu Title", options)
```
