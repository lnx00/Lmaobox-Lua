--[[
    Misc Tools for Lmaobox
    Author: LNX (github.com/lnx00)
]]

local menuLoaded, MenuLib = pcall(require, "Menu")
if menuLoaded == false then
    print("[Tools] MenuLib not found, please install it!")
    do return end
end

local ltExtendFreeze = 0

-- Menu
local menu = MenuLib.Create("Misc Tools", MenuFlags.AutoSize)
local mLegJitter = menu:AddComponent(MenuLib.Checkbox("Leg Jitter", false))
local mRageRetry = menu:AddComponent(MenuLib.Checkbox("Rage Retry", false))
local mRageHealth = menu:AddComponent(MenuLib.Slider("Min Health", 0, 100, 30))
local mNCName = menu:AddComponent(MenuLib.Textbox("Custom name..."))
menu:AddComponent(MenuLib.Button("Set name", function()
    client.Command('name "' .. mNCName:GetValue() .. '"', true)
end, ItemFlags.FullWidth))
local mExtendFreeze = menu:AddComponent(MenuLib.Checkbox("Infinite Respawn", false))
local mWeaponSway = menu:AddComponent(MenuLib.Checkbox("Weapon Sway", false))

local function CreateMove(pCmd)
    local pLocal = entities.GetLocalPlayer()
    if not pLocal then return end

    local vVelocity = pLocal:EstimateAbsVelocity()

    -- Leg Jitter
    if mLegJitter:GetValue() == true then
        if (pCmd.forwardmove == 0) and (pCmd.sidemove == 0) and (vVelocity:Length2D() < 10) then
            if pCmd.command_number % 2 == 0 then
                pCmd:SetForwardMove(2)
                pCmd:SetSideMove(2)
            else
                pCmd:SetForwardMove(-2)
                pCmd:SetSideMove(-2)
            end
        end
    end

    -- Rage Retry
    if mRageRetry:GetValue() == true then
        if (pLocal:IsAlive()) and (pLocal:GetHealth() > 0 and (pLocal:GetHealth()) <= mRageHealth:GetValue()) then
            client.Command("retry", true)
        end
    end

    -- Infinite Respawn
    if mExtendFreeze:GetValue() == true then
        if (pLocal:IsAlive() == false) and (globals.RealTime() > (ltExtendFreeze + 2)) then
            client.Command("extendfreeze", true)
            ltExtendFreeze = globals.RealTime()
        end
    end

    -- Weapon Sway
    if mWeaponSway:GetValue() == true then
        client.SetConVar("cl_wpn_sway_interp", 0.05)
    elseif client.GetConVar("cl_wpn_sway_interp") > 0 then
        client.SetConVar("cl_wpn_sway_interp", 0.01)
    end
end

local function Unload()
    MenuLib.RemoveMenu(menu)

    client.Command('play "ui/buttonclickrelease"', true)
end

callbacks.Unregister("CreateMove", "MT_CreateMove") 
callbacks.Register("CreateMove", "MT_CreateMove", CreateMove)

callbacks.Unregister("Unload", "MT_Unload") 
callbacks.Register("Unload", "MT_Unload", Unload)

client.Command('play "ui/buttonclick"', true)