--[[
    Custom Aimbot for Lmaobox
    Author: github.com/lnx00
]]

if UnloadLib then UnloadLib() end

---@alias AimTarget { entity : Entity, pos : Vector3, angles : EulerAngles, factor : number }

---@type boolean, lnxLib
local libLoaded, lnxLib = pcall(require, "lnxLib")
assert(libLoaded, "lnxLib not found, please install it!")
assert(lnxLib.GetVersion() >= 0.967, "LNXlib version is too old, please update it!")

local Math, Conversion = lnxLib.Utils.Math, lnxLib.Utils.Conversion
local WPlayer, WWeapon = lnxLib.TF2.WPlayer, lnxLib.TF2.WWeapon
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
    AimFov = 90,
    PredTicks = 64
}

local currentTarget = nil

---@param me WPlayer
---@param weapon WWeapon
---@param player WPlayer
---@return AimTarget?
local function CheckHitscanTarget(me, weapon, player)
    -- FOV Check
    local aimPos = player:GetHitboxPos(options.AimPos)
    local angles = Math.PositionAngles(me:GetEyePos(), aimPos)
    local fov = Math.AngleFov(angles, engine.GetViewAngles())
    if fov > options.AimFov then return nil end

    -- Visiblity Check
    if not Helpers.VisPos(player:Unwrap(), me:GetEyePos(), aimPos) then return nil end

    -- The target is valid
    local target = { entity = player, pos = aimPos, angles = angles, factor = fov }
    return target
end

---@param me WPlayer
---@param weapon WWeapon
---@param player WPlayer
---@return AimTarget?
local function CheckProjectileTarget(me, weapon, player)
    local predList = Helpers.Predict(player, options.PredTicks)
    if not predList then return nil end

    local data = weapon:GetWeaponData()
    --local speed = data.projectileSpeed
    local speed = 1980 -- Direct hit speed
    local shootPos = me:GetEyePos()

    -- TODO: Do we really need to check all predictions?
    local pred = nil
    for i = 0, #predList do
        local current = predList[i]

        -- Time check
        local pos = current.p
        local dist = (pos - shootPos):Length()
        local time = dist / speed
        local ticks = Conversion.Time_to_Ticks(time)
        if ticks ~= i then
            -- We can't hit this prediction
            goto continue
        end

        -- Visiblity Check
        if not Helpers.VisPos(player:Unwrap(), me:GetEyePos(), current.p) then
            goto continue
        end

        -- The prediction is valid
        pred = current
        break

        -- TODO: FOV Check
        ::continue::
    end

    -- We didn't find a valid prediction
    if not pred then return nil end

    local angles = Math.PositionAngles(me:GetEyePos(), pred.p)
    local fov = Math.AngleFov(angles, engine.GetViewAngles())

    -- The target is valid
    local target = { entity = player, pos = pred.p, angles = angles, factor = fov }
    return target
end

---@param me WPlayer
---@param weapon WWeapon
---@param entity Entity
---@return AimTarget?
local function CheckTarget(me, weapon, entity)
    if not entity then return nil end
    if not entity:IsAlive() then return nil end
    if entity:GetTeamNumber() == entities.GetLocalPlayer():GetTeamNumber() then return nil end

    local player = WPlayer.FromEntity(entity)

    if weapon:IsShootingWeapon() then
        -- TODO: Improve this

        local projType = weapon:GetWeaponProjectileType()
        if projType == 1 then
            -- Hitscan weapon
            return CheckHitscanTarget(me, weapon, player)
        elseif projType == 2 then
            -- Projectile weapon
            return CheckProjectileTarget(me, weapon, player)
        else
            
        end
    elseif weapon:IsMeleeWeapon() then
        -- TODO: Melee Aimbot
    end

    return nil
end

-- Returns the best target (lowest fov)
---@param me WPlayer
---@param weapon WWeapon
---@return AimTarget? target
local function GetBestTarget(me, weapon)
    local players = entities.FindByClass("CTFPlayer")
    local bestTarget = nil
    local bestFactor = math.huge

    for _, entity in pairs(players) do
        local target = CheckTarget(me, weapon, entity)
        if not target then goto continue end

        -- Add valid target
        if target.factor < bestFactor then
            bestFactor = target.factor
            bestTarget = target
        end

        ::continue::
    end

    return bestTarget
end

---@param userCmd UserCmd
local function OnCreateMove(userCmd)
    if not input.IsButtonDown(options.AimKey) then return end

    local me = WPlayer.GetLocal()
    if not me then return end

    local weapon = me:GetActiveWeapon()
    if not weapon then return end

    -- Get the best target
    currentTarget = GetBestTarget(me, weapon)
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