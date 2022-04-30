# Menu Library
Menu.lua is an easy-to-use Menu Library for Lmaobox. It allows you to create interactive menus for your scripts to configure and customize your features. Please note that you only have to create the menus and components **once** (when initializing your script for example) and do not need to call it in the *Draw* or *CreateMove* callback.
[You can find an example script here](../Menu-Example.lua)

![Screenshot](https://i.imgur.com/k2hyOax.png)

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

## Components
The Menu Library allows you to use various UI components that are already fully implemented and working. But you can also create your own components if you want.

### Label
![Label](https://i.imgur.com/knK7AOk.png)<br/>
Simple label with a given text.
```
MenuLib.Label("Text")
```

### Checkbox
![Label](https://i.imgur.com/ugksbLr.png)<br/>
Allows you to toggle between on/off.
```
MenuLib.Checkbox("Label", value)
[Checkbox]:GetValue() -- Current state (bool)
```

### Button
![Button](https://i.imgur.com/dOVKTG4.png)<br/>
Runs a given callback when the button is being pressed.
```
MenuLib.Button("Label", callback)
```

### Slider
![Slider](https://i.imgur.com/363zFtX.png)<br/>
Allows you to select a value between a given minimum and maximum
```
MenuLib.Slider("Label", min, max, value)
[Slider]:GetValue() -- Current value (number)
```

### Textbox
![Textbox](https://i.imgur.com/vo0j8n5.png)<br/>
Allows you to enter a text. It's very basic though and only allows a small set of characters.
```
MenuLib.Textbox("Label", value)
[Textbox]:GetValue() -- Current text (string)
```

### Keybind
![Keybind](https://i.imgur.com/qr24MrZ.png)<br/>
Allows you to enter a keybind.
```
MenuLib.Keybind("Label", key)
[Keybind]:GetValue() -- Current key (number)
```

### Combobox
![Combobox](https://i.imgur.com/VthXZZp.png)<br/>
Allows you to select one of many given options in a dropdown.
```
local combo = {
  "Option 1",
  "Option 2",
  [...]
}
MenuLib.Combo("Label", combo)
[Combo]:Select(index) -- Selects item at index
[Combo]:GetSelectedIndex() -- Selected item index (number)
[Combo].Selected -- Selected item name (string)
```

### Multi Combobox
![Multibox](https://i.imgur.com/bwPnnaf.png)<br/>
Allows you to select multiple options in a dropdown.
```
local multiCombo = {
  ["Option 1"] = true,
  ["Options 2"] = false,
  ["Options 3"] = true
  [...]
}
MenuLib.MultiCombo("Label", multiCombo)
[MultiCombo]:Select(index) -- Selects item at index
[MultiCombo].Options -- Table of options and their current state (string, bool)
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
[Element].ID
[Element]:SetVisible(state)
```

You can access and change the menu style using [Menu].Style
```
Style.Space = 4,
Style.Font = MenuManager.Font,
Style.WindowBg = { 30, 30, 30, 255 },
Style.TitleBg = { 55, 100, 215, 255 },
Style.Text = { 255, 255, 255, 255 },
Style.Item = { 50, 50, 50, 255 },
Style.ItemHover = { 65, 65, 65, 255 },
Style.ItemActive = { 80, 80, 80, 255 },
Style.Highlight = { 180, 180, 180, 100 }
```

## Flags
Flags allow you to modify the drawing of windows. Here's an example on using flags:
```
Menus.Create("Flag Menu", MenuFlags.NoTitle | MenuFlags.NoDrag)
```

**Available flags:**
Menu Flags:
```
MenuFlags.NoTitle -- No title bar
MenuFlags.NoBackground -- No window background
MenuFlags.NoDrag -- Disable dragging
MenuFlags.AutoSize -- Auto size height to contents
MenuFlags.ShowAlways -- Show menu when ingame
```

Component Flags:
```
ItemFlags.FullWidth -- Fill width of menu
ItemFlags.Active -- Item is always active
```

Have fun creating menus!
