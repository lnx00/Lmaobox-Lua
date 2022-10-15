--[[
    Ping Reducer for Lmaobox
    Author: LNX (github.com/lnx00)
]]

local menuLoaded, MenuLib = pcall(require, "Menu")
assert(menuLoaded, "MenuLib not found, please install it!")
assert(MenuLib.Version >= 1.43, "MenuLib version is too old, please update it!")

--[[ Menu ]]
local Menu = MenuLib.Create("Ping Reducer", MenuFlags.AutoSize)
Menu.Style.TitleBg = { 10, 200, 100, 255 }
Menu.Style.Outline = true

local Options = {
    Enabled = Menu:AddComponent(MenuLib.Checkbox("Enable", true)),
    TargetPing = Menu:AddComponent(MenuLib.Slider("Target Ping", 0, 100, 15))
}

local function OnCreateMove()
    if not Options.Enabled:GetValue() then return end

    local localIndex = entities.GetLocalPlayer():GetIndex()
    local ping = entities.GetPlayerResources():GetPropDataTableInt("m_iPing")[localIndex + 1]
    if ping <= Options.TargetPing:GetValue() then
        gui.SetValue("ping reducer", 0)
    else
        gui.SetValue("ping reducer", 1)
    end
end

local function OnUnload()
    MenuLib.RemoveMenu(Menu)

    client.Command('play "ui/buttonclickrelease"', true)
end

callbacks.Unregister("CreateMove", "PR_CreateMove")
callbacks.Unregister("Unload", "PR_Unload")

callbacks.Register("CreateMove", "PR_CreateMove", OnCreateMove)
callbacks.Register("Unload", "PR_Unload", OnUnload)

client.Command('play "ui/buttonclick"', true)