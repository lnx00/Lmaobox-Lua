UnloadLib()

---@type boolean, lnxLib
local libLoaded, lnxLib = pcall(require, "lnxLib")
assert(libLoaded, "lnxLib not found, please install it!")
assert(lnxLib.GetVersion() >= 0.965, "LNXlib version is too old, please update it!")

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
    AimKey = KEY_R,
    AutoShoot = true,
    Silent = true,
    AimPos = Hitbox.Head
}

---@return Entity? target
local function GetBestTarget()
    local players = entities.FindByClass("CTFPlayer")
    local target = nil
    local lastFov = math.huge

    for _, entity in pairs(players) do
        if not entity then goto continue end
        if not entity:IsAlive() then goto continue end
        if entity:GetTeamNumber() == entities.GetLocalPlayer():GetTeamNumber() then goto continue end

        local angle = Math.PositionAngles(entities.GetLocalPlayer():GetAbsOrigin(), entity:GetAbsOrigin())
        local fov = Math.AngleFov(angle, engine.GetViewAngles())

        -- TODO: Visibility check

        if fov < lastFov then
            lastFov = fov
            target = entity
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
    local target = GetBestTarget()
    if not target then return end
    local wTarget = WPlayer.FromEntity(target)

    -- Aim at the target
    local aimPos = wTarget:GetHitboxPos(options.AimPos)
    local angles = Math.PositionAngles(me:GetEyePos(), aimPos)
    angles:Normalize()

    userCmd:SetViewAngles(angles:Unpack())
    if not options.Silent then
        engine.SetViewAngles(angles)
    end

    -- Auto Shoot
    if options.AutoShoot then
        userCmd.buttons = userCmd.buttons | IN_ATTACK
    end
end

callbacks.Unregister("CreateMove", "LNX.Aimbot.CreateMove")
callbacks.Register("CreateMove", "LNX.Aimbot.CreateMove", OnCreateMove)