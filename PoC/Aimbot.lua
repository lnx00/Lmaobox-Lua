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
local Helpers, Prediction = lnxLib.TF2.Helpers, lnxLib.TF2.Prediction
local Fonts = lnxLib.UI.Fonts

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
    PredTicks = 32,
    Debug = true
}

---@type AimTarget?
local currentTarget = nil

local pred = Prediction.new()
local latency = 0
local lerp = 0

-- Finds the best position for hitscan weapons
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

-- Finds the best position for projectile weapons
---@param me WPlayer
---@param weapon WWeapon
---@param player WPlayer
---@return AimTarget?
local function CheckProjectileTarget(me, weapon, player)
    local predData = pred:Perform(player, options.PredTicks)
    if not predData then return nil end

    local speed = 1980 -- Direct hit speed | TODO: Get the real speed
    local shootPos = me:GetEyePos()

    -- Distance check
    local maxDistance = options.PredTicks * speed
    if me:DistTo(player) > maxDistance then return nil end

    -- Visiblity Check
    if not Helpers.VisPos(player:Unwrap(), shootPos, player:GetAbsOrigin()) then
        return nil
    end

    -- Find a valid prediction
    local targetPos = nil
    for i = 0, options.PredTicks do
        local cPos = predData.pos[i]

        -- Time check
        local pos = cPos
        local dist = (pos - shootPos):Length()
        local time = (dist / speed) + latency + lerp
        local ticks = Conversion.Time_to_Ticks(time)
        if ticks ~= i then
            -- We can't hit this prediction
            goto continue
        end

        -- Visiblity Check
        --[[if not Helpers.VisPos(player:Unwrap(), me:GetEyePos(), cPos) then
            goto continue
        end]]

        -- The prediction is valid
        targetPos = cPos
        break

        -- TODO: FOV Check
        ::continue::
    end

    -- We didn't find a valid prediction
    if not targetPos then return nil end

    -- Calculate the fov
    local angles = Math.PositionAngles(me:GetEyePos(), targetPos)
    local fov = Math.AngleFov(angles, engine.GetViewAngles())

    -- The target is valid
    local target = { entity = player, pos = targetPos, angles = angles, factor = fov }
    return target
end

-- Checks the given target for the given weapon
---@param me WPlayer
---@param weapon WWeapon
---@param entity Entity
---@return AimTarget?
local function CheckTarget(me, weapon, entity)
    if not entity then return nil end
    if not entity:IsAlive() then return nil end
    if entity:GetTeamNumber() == me:GetTeamNumber() then return nil end

    local player = WPlayer.FromEntity(entity)

    -- FOV check
    --local angles = Math.PositionAngles(me:GetEyePos(), player:GetAbsOrigin())
    --local fov = Math.AngleFov(angles, engine.GetViewAngles())
    --if fov > options.AimFov then return nil end

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

-- Returns the best target for the given weapon
---@param me WPlayer
---@param weapon WWeapon
---@return AimTarget? target
local function GetBestTarget(me, weapon)
    local players = entities.FindByClass("CTFPlayer")
    local bestTarget = nil
    local bestFactor = math.huge

    -- Check all players
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

    --if not Helpers.CanShoot(weapon) then return end

    -- Get current latency
    local latIn, latOut = clientstate.GetLatencyIn(), clientstate.GetLatencyOut()
    if latIn and latOut then
        latency = latIn + latOut
    else
        latency = 0
    end

    -- Get current lerp
    _, lerp = client.GetConVar("cl_interp")

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

    currentTarget = nil
end

local function OnDraw()
    draw.SetFont(Fonts.Verdana)
    draw.Color(255, 255, 255, 255)

    -- Draw current latency and lerp
    draw.Text(20, 140, string.format("Latency: %.2f", latency))
    draw.Text(20, 160, string.format("Lerp: %.2f", lerp))

    local me = WPlayer.GetLocal()
    if not me or not currentTarget then return end

    -- Draw the current target
    local screenPos = client.WorldToScreen(currentTarget.pos)
    if screenPos then
        draw.Color(255, 255, 255, 255)
        draw.Text(screenPos[1], screenPos[2], "X")
    end
end

callbacks.Unregister("CreateMove", "LNX.Aimbot.CreateMove")
callbacks.Register("CreateMove", "LNX.Aimbot.CreateMove", OnCreateMove)

callbacks.Unregister("Draw", "LNX.Aimbot.Draw")
callbacks.Register("Draw", "LNX.Aimbot.Draw", OnDraw)