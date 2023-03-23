--[[
    Custom Aimbot for Lmaobox
    Author: github.com/lnx00
]]

---@alias AimTarget { entity : Entity, pos : Vector3, angles : EulerAngles, factor : number }

---@type boolean, lnxLib
local libLoaded, lnxLib = pcall(require, "lnxLib")
assert(libLoaded, "lnxLib not found, please install it!")
assert(lnxLib.GetVersion() >= 0.967, "LNXlib version is too old, please update it!")

local Math = lnxLib.Utils.Math
local WPlayer = lnxLib.TF2.WPlayer
local Helpers = lnxLib.TF2.Helpers

local Hitbox = {
    Head = 1,
    Neck = 2,
    Pelvis = 4,
    Body = 5,
    Chest = 7
}

local options = {
    AimKey = KEY_LSHIFT,
    AutoShoot = true,
    Silent = true,
    AimPos = Hitbox.Head,
    AimFov = 90
}

local currentTarget = nil

-- Returns the best target (lowest fov)
---@param me WPlayer
---@return AimTarget? target
local function GetBestTarget(me)
    local players = entities.FindByClass("CTFPlayer")
    local target = nil
    local lastFov = math.huge

    for _, entity in pairs(players) do
        if not entity then goto continue end
        if not entity:IsAlive() then goto continue end
        if entity:GetTeamNumber() == entities.GetLocalPlayer():GetTeamNumber() then goto continue end

        -- FOV Check
        local player = WPlayer.FromEntity(entity)
        local aimPos = player:GetHitboxPos(options.AimPos)
        local angles = Math.PositionAngles(me:GetEyePos(), aimPos)
        local fov = Math.AngleFov(angles, engine.GetViewAngles())
        if fov > options.AimFov then goto continue end

        -- Visiblity Check
        if not Helpers.VisPos(entity, me:GetEyePos(), aimPos) then goto continue end

        -- Add valid target
        if fov < lastFov then
            lastFov = fov
            target = { entity = entity, pos = aimPos, angles = angles, factor = fov }
        end

        ::continue::
    end

    return target
end

---@param userCmd UserCmd
local function OnCreateMove(userCmd)
    if not input.IsButtonDown(options.AimKey) then return end

    local me = WPlayer.GetLocal()
    if not me then return end

    -- Get the best target
    currentTarget = GetBestTarget(me)
    if not currentTarget then return end

    -- Aim at the target
    userCmd:SetViewAngles(currentTarget.angles:Unpack())
    if not options.Silent then
        engine.SetViewAngles(currentTarget.angles)
    end

    -- Auto Shoot
    if options.AutoShoot then
        userCmd.buttons = userCmd.buttons | IN_ATTACK
    end
end

local function OnDraw()
    if not currentTarget then return end

    local me = WPlayer.GetLocal()
    if not me then return end
end

callbacks.Unregister("CreateMove", "LNX.Aimbot.CreateMove")
callbacks.Register("CreateMove", "LNX.Aimbot.CreateMove", OnCreateMove)

callbacks.Unregister("Draw", "LNX.Aimbot.Draw")
callbacks.Register("Draw", "LNX.Aimbot.Draw", OnDraw)