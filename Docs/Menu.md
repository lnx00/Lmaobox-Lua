# Menu Library
Menu.lua is an easy-to-use Menu Library for Lmaobox. It allows you to create interactive menus for your scripts to configure and customize your features. Please note that you only have to create the menus and components **once** (when initializing your script for example) and do not need to call it in the *Draw* or *CreateMove* callback.

![](https://i.imgur.com/E6CjsAr.png)

## Components
The Menu Library allows you to use various UI components that are already fully implemented and working. But you can also create your own components if you want.

### Label
Simple label with a given text.
```
MenuLib.Label("Text")
```

### Checkbox
Allows you to toggle between on/off.
```
MenuLib.Checkbox("Label", value)
[Checkbox].Value
```

### Button
Runs a given callback when the button is being pressed.
```
MenuLib.Button("Label", callback)
```

### Combobox
Allows you to select one of many given options in a dropdown.
```
local combo = {
  "Option 1",
  "Option 2",
  [...]
}
MenuLib.Combo("Label", combo)
```

### Multi Combobox
Allows you to select multiple options in a dropdown.
```
local multiCombo = {
  { "Option 1", true },
  { "Option 2", false },
  [...]
}
```

### Menu
A window that contains components
```
[Menu]:SetTitle(title) -- Sets the window title
[Menu]:SetPosition(x, y) -- Sets the window position
[Menu]:SetSize(width, height) -- Sets the window size
[Menu]:AddComponent(component) -- Adds the given component to the menu
[Menu]:RemoveComponent(component) -- Removes a given component from the menu
[Menu]:Remove() -- Removes the menu
```

Properties for all components and menus:
```
[Element].Visible
[Element]:SetVisible(state)
[Element].ID
```

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

After you've loaded the Menu module, you can create a new Menu (flags are optional):
```
local menu = Menu.Create("Title", flags)
```

...and add your components:
```
[Menu]:AddComponent(<Component>)
```

## Flags
Flags allow you to modify the drawing of windows. Here's an example on using flags:
```
Menus.Create("Flag Menu", MenuFlags.NoTitle | MenuFlags.NoDrag)
```

**Available flags:**
```
MenuFlags.NoTitle - No title bar
MenuFlags.NoBackground - No window background
MenuFlags.NoDrag - Disable dragging
MenuFlags.AutoSize - Auto size height to contents
MenuFlags.ShowAlways - Show menu when ingame
```

Have fun creating menus!
