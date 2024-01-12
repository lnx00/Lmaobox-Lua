--[[
    Custom Aimbot for Lmaobox
    Author: github.com/lnx00
]]

if UnloadLib then UnloadLib() end

---@alias AimTarget { entity : Entity, angles : EulerAngles, factor : number }

---@type boolean, lnxLib
local libLoaded, lnxLib = pcall(require, "lnxLib")
assert(libLoaded, "lnxLib not found, please install it!")
assert(lnxLib.GetVersion() >= 0.987, "lnxLib version is too old, please update it!")

local Math, Conversion = lnxLib.Utils.Math, lnxLib.Utils.Conversion
local WPlayer, WWeapon = lnxLib.TF2.WPlayer, lnxLib.TF2.WWeapon
local Helpers = lnxLib.TF2.Helpers
local Prediction = lnxLib.TF2.Prediction
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
    AimPos = {
        Hitscan = Hitbox.Head,
        Projectile = Hitbox.Head
    },
    AimFov = 40,
    PredTicks = 60,
    StrafePrediction = true,
    StrafeSamples = 1,
    DebugInfo = true
}

local latency = 0
local lerp = 0
local lastAngles = {} ---@type EulerAngles[]
local strafeAngles = {} ---@type number[]

---@param me WPlayer
local function CalcStrafe(me)
    local players = entities.FindByClass("CTFPlayer")
    for idx, entity in ipairs(players) do
        if entity:IsDormant() or not entity:IsAlive() then
            lastAngles[idx] = nil
            strafeAngles[idx] = nil
            goto continue
        end

        -- Ignore teammates (for now)
        if entity:GetTeamNumber() == me:GetTeamNumber() then
            goto continue
        end

        local v = entity:EstimateAbsVelocity()
        local angle = v:Angles()

        -- Play doesn't have a last angle
        if lastAngles[idx] == nil then
            lastAngles[idx] = angle
            goto continue
        end

        -- Calculate the delta angle
        if angle.y ~= lastAngles[idx].y then
            local delta = Math.NormalizeAngle(angle.y - lastAngles[idx].y)
            strafeAngles[idx] = math.clamp(delta, -5, 5)
        end
        lastAngles[idx] = angle

        ::continue::
    end
end

-- Finds the best position for hitscan weapons
---@param me WPlayer
---@param weapon WWeapon
---@param player WPlayer
---@return AimTarget?
local function CheckHitscanTarget(me, weapon, player)
    -- FOV Check
    local aimPos = player:GetHitboxPos(options.AimPos.Hitscan)
    if not aimPos then return nil end
    local angles = Math.PositionAngles(me:GetEyePos(), aimPos)
    local fov = Math.AngleFov(angles, engine.GetViewAngles())

    -- Visiblity Check
    if not Helpers.VisPos(player:Unwrap(), me:GetEyePos(), aimPos) then return nil end

    -- The target is valid
    local target = { entity = player, angles = angles, factor = fov }
    return target
end

-- Finds the best position for projectile weapons
---@param me WPlayer
---@param weapon WWeapon
---@param player WPlayer
---@return AimTarget?
local function CheckProjectileTarget(me, weapon, player)
    local projInfo = weapon:GetProjectileInfo()
    if not projInfo then return nil end

    local speed = projInfo[1]
    local shootPos = me:GetEyePos() -- TODO: Add weapon offset
    local aimPos = player:GetHitboxPos(options.AimPos.Projectile)
    local aimOffset = aimPos - player:GetAbsOrigin()
    --local aimOffset = Vector3()

    -- Distance check
    local maxDistance = options.PredTicks * speed
    if me:DistTo(player) > maxDistance then return nil end

    -- Visiblity Check
    if not Helpers.VisPos(player:Unwrap(), shootPos, player:GetAbsOrigin()) then
        return nil
    end

    -- Predict the player
    local strafeAngle = options.StrafePrediction and strafeAngles[player:GetIndex()] or nil
    local predData = Prediction.Player(player, options.PredTicks, strafeAngle)
    if not predData then return nil end

    -- Find a valid prediction
    local targetAngles = nil
    for i = 0, options.PredTicks do
        local pos = predData.pos[i] + aimOffset
        local solution = Math.SolveProjectile(shootPos, pos, projInfo[1], projInfo[2])
        if not solution then goto continue end

        -- Time check
        local time = solution.time + latency + lerp
        local ticks = Conversion.Time_to_Ticks(time) + 1
        if ticks > i then goto continue end

        -- Visiblity Check
        if not Helpers.VisPos(player:Unwrap(), shootPos, pos) then
            goto continue
        end

        -- The prediction is valid
        targetAngles = solution.angles
        break

        -- TODO: FOV Check
        ::continue::
    end

    -- We didn't find a valid prediction
    if not targetAngles then return nil end
    
    -- Calculate the fov
    local fov = Math.AngleFov(targetAngles, engine.GetViewAngles())

    -- The target is valid
    local target = { entity = player, angles = targetAngles, factor = fov }
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
    local angles = Math.PositionAngles(me:GetEyePos(), player:GetAbsOrigin())
    local fov = Math.AngleFov(angles, engine.GetViewAngles())
    if fov > options.AimFov then return nil end

    if weapon:IsShootingWeapon() then
        -- TODO: Improve this

        local projType = weapon:GetWeaponProjectileType()
        if projType == 1 then
            -- Hitscan weapon
            return CheckHitscanTarget(me, weapon, player)
        else
            -- Projectile weapon
            return CheckProjectileTarget(me, weapon, player)
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

        -- TODO: Continue searching
        break

        ::continue::
    end

    return bestTarget
end

---@param userCmd UserCmd
local function OnCreateMove(userCmd)
    if not input.IsButtonDown(options.AimKey) then return end

    local me = WPlayer.GetLocal()
    if not me or not me:IsAlive() then return end

    local weapon = me:GetActiveWeapon()
    if not weapon then return end

    -- Calculate strafe angles (optional)
    if options.StrafePrediction then
        CalcStrafe(me)
    end

    -- Check if we can shoot
    --[[local flCurTime = globals.CurTime()
    local canShoot = weapon:GetNextPrimaryAttack() <= flCurTime and me:GetNextAttack() <= flCurTime
    if not canShoot then return end]]

    -- Get current latency
    local latIn, latOut = clientstate.GetLatencyIn(), clientstate.GetLatencyOut()
    latency = (latIn or 0) + (latOut or 0)

    -- Get current lerp
    lerp = client.GetConVar("cl_interp") or 0

    -- Get the best target
    local currentTarget = GetBestTarget(me, weapon)
    if not currentTarget then return end

    -- Aim at the target
    userCmd:SetViewAngles(currentTarget.angles:Unpack())
    if not options.Silent then
        engine.SetViewAngles(currentTarget.angles)
    end

    -- Auto Shoot
    if options.AutoShoot then
        if weapon:GetWeaponID() == TF_WEAPON_COMPOUND_BOW
        or weapon:GetWeaponID() == TF_WEAPON_PIPEBOMBLAUNCHER then
            -- Huntsman
            if weapon:GetChargeBeginTime() > 0 then
                userCmd.buttons = userCmd.buttons & ~IN_ATTACK
            else
                userCmd.buttons = userCmd.buttons | IN_ATTACK
            end
        else
            -- Normal weapon
            userCmd.buttons = userCmd.buttons | IN_ATTACK
        end
    end
end

local function OnDraw()
    if not options.DebugInfo then return end

    draw.SetFont(Fonts.Verdana)
    draw.Color(255, 255, 255, 255)

    -- Draw current latency and lerp
    draw.Text(20, 140, string.format("Latency: %.2f", latency))
    draw.Text(20, 160, string.format("Lerp: %.2f", lerp))

    local me = WPlayer.GetLocal()
    if not me or not me:IsAlive() then return end

    local weapon = me:GetActiveWeapon()
    if not weapon then return end

    -- Draw current weapon
    draw.Text(20, 180, string.format("Weapon: %s", weapon:GetName()))
    draw.Text(20, 200, string.format("Weapon ID: %d", weapon:GetWeaponID()))
    draw.Text(20, 220, string.format("Weapon DefIndex: %d", weapon:GetDefIndex()))
end

callbacks.Unregister("CreateMove", "LNX.Aimbot.CreateMove")
callbacks.Register("CreateMove", "LNX.Aimbot.CreateMove", OnCreateMove)

callbacks.Unregister("Draw", "LNX.Aimbot.Draw")
callbacks.Register("Draw", "LNX.Aimbot.Draw", OnDraw)