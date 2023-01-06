--[[
    Infinite Food automation
    Credits: Baan
    Author: LNX (github.com/lnx00)
    Dependencies: LNXlib (github.com/lnx00/Lmaobox-Library)
]]

---@type boolean, LNXlib
local libLoaded, Lib = pcall(require, "LNXlib")
assert(libLoaded, "LNXlib not found, please install it!")
assert(Lib.GetVersion() >= 0.89, "LNXlib version is too old, please update it!")

local KeyHelper, Timer, WPlayer = Lib.Utils.KeyHelper, Lib.Utils.Timer, Lib.TF2.WPlayer

local key = KeyHelper.new(KEY_J)
local tauntTimer = Timer.new()

---@param userCmd UserCmd
local function OnUserCmd(userCmd)
    local localPlayer = WPlayer.GetLocal()
    if not localPlayer:IsAlive()
        or not key:Down()
        or engine.IsGameUIVisible()
        then return end

    local weapon = localPlayer:GetActiveWeapon()
    if weapon:IsShootingWeapon() or weapon:IsMeleeWeapon() then return end

    userCmd:SetButtons(userCmd:GetButtons() | IN_ATTACK)

    if tauntTimer:Run(0.5) then
        client.Command("taunt", true)
    end
end

callbacks.Unregister("CreateMove", "LNX_IF_UserCmd")
callbacks.Register("CreateMove", "LNX_IF_UserCmd", OnUserCmd)