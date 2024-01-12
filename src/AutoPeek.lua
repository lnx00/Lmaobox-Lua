--[[
    Auto Peek for Lmaobox
    Author: LNX (github.com/lnx00)
]]
local menuLoaded, MenuLib = pcall(require, "Menu")
assert(menuLoaded, "MenuLib not found, please install it!")
assert(MenuLib.Version >= 1.43, "MenuLib version is too old, please update it!")

local options = {
    Font = draw.CreateFont("Roboto", 20, 400)
}

--[[ Menu ]]
local menu = MenuLib.Create("Auto Peek", MenuFlags.AutoSize)
menu.Style.TitleBg = { 0, 100, 100, 255 }
menu.Style.Outline = true

local mEnabled = menu:AddComponent(MenuLib.Checkbox("Enable", true))
local mKey = menu:AddComponent(MenuLib.Keybind("Peek Key", KEY_LSHIFT, ItemFlags.FullWidth)) -- Hold this key to start peeking
local mFreeMove = menu:AddComponent(MenuLib.Checkbox("Free Move", false)) -- Allows you to move freely
local mDistance = menu:AddComponent(MenuLib.Slider("Distance", 20, 400, 100)) -- Max peek distance
local mSegments = menu:AddComponent(MenuLib.Slider("Segments", 2, 15, 5)) -- Higher values = more precise but worse performance

local PosPlaced = false -- Did we start peeking?
local IsReturning = false -- Are we returning?
local HasDirection = false -- Do we have a peek direction?
local PeekStartVec = Vector3(0, 0, 0)
local PeekDirectionVec = Vector3(0, 0, 0)
local PeekReturnVec = Vector3(0, 0, 0)

local LineDrawList = {}

local Hitboxes = {
    HEAD = 1,
    NECK = 2,
    PELVIS = 4,
    BODY = 5,
    CHEST = 7
}

local function OnGround(player)
    local pFlags = player:GetPropInt("m_fFlags")
    return (pFlags & FL_ONGROUND) == 1
end

local function VisPos(target, vFrom, vTo)
    local trace = engine.TraceLine(vFrom, vTo, MASK_SHOT | CONTENTS_GRATE)
    return ((trace.entity and trace.entity == target) or (trace.fraction > 0.99))
end

local function CanShoot(pLocal)
    local pWeapon = pLocal:GetPropEntity("m_hActiveWeapon")
    if (not pWeapon) or (pWeapon:IsMeleeWeapon()) then return false end

    local nextPrimaryAttack = pWeapon:GetPropFloat("LocalActiveWeaponData", "m_flNextPrimaryAttack")
    local nextAttack = pLocal:GetPropFloat("bcc_localdata", "m_flNextAttack")
    if (not nextPrimaryAttack) or (not nextAttack) then return false end

    return (nextPrimaryAttack <= globals.CurTime()) and (nextAttack <= globals.CurTime())
end

local function GetHitboxPos(entity, hitbox)
    local hitbox = entity:GetHitboxes()[hitbox]
    if not hitbox then return end

    return (hitbox[1] + hitbox[2]) * 0.5
end

local function CanAttackFromPos(pLocal, pPos)
    if CanShoot(pLocal) == false then return false end
    local ignoreFriends = gui.GetValue("ignore steam friends")

    local players = entities.FindByClass("CTFPlayer")
    for k, vPlayer in pairs(players) do
        if vPlayer:IsValid() == false then goto continue end
        if vPlayer:IsAlive() == false then goto continue end
        if vPlayer:GetTeamNumber() == pLocal:GetTeamNumber() then goto continue end

        local playerInfo = client.GetPlayerInfo(vPlayer:GetIndex())
        if steam.IsFriend(playerInfo.SteamID) and ignoreFriends == 1 then goto continue end

        -- TODO: Check for hitbox and not abs
        if VisPos(vPlayer, pPos, GetHitboxPos(vPlayer, Hitboxes.HEAD)) then
            return true
        end

        ::continue::
    end

    return false
end

local function ComputeMove(pCmd, a, b)
    local diff = (b - a)
    if diff:Length() == 0 then return Vector3(0, 0, 0) end

    local x = diff.x
    local y = diff.y
    local vSilent = Vector3(x, y, 0)

    local ang = vSilent:Angles()
    local cPitch, cYaw, cRoll = pCmd:GetViewAngles()
    local yaw = math.rad(ang.y - cYaw)
    local pitch = math.rad(ang.x - cPitch)
    local move = Vector3(math.cos(yaw) * 450, -math.sin(yaw) * 450, -math.cos(pitch) * 450)

    return move
end

-- Walks to a given destination vector
local function WalkTo(pCmd, pLocal, pDestination)
    local localPos = pLocal:GetAbsOrigin()
    local result = ComputeMove(pCmd, localPos, pDestination)

    pCmd:SetForwardMove(result.x)
    pCmd:SetSideMove(result.y)
end

local function DrawLine(startPos, endPos)
    table.insert(LineDrawList, {
        start = startPos,
        endPos = endPos
    })
end

local function OnCreateMove(pCmd)
    local pLocal = entities.GetLocalPlayer()
    if not pLocal or mEnabled:GetValue() == false then return end

    if pLocal:IsAlive() and input.IsButtonDown(mKey:GetValue()) then
        local localPos = pLocal:GetAbsOrigin()

        -- We just started peeking. Save the return position!
        if PosPlaced == false then
            if OnGround(pLocal) then
                PeekReturnVec = localPos
                PosPlaced = true
            end
        else
            -- TODO: Particle effect
        end

        -- We need a peek direction (A / D)
        if mFreeMove:GetValue() == false and HasDirection == false and OnGround(pLocal) then
            local viewAngles = engine.GetViewAngles()
            local vDirection = Vector3(0, 0, 0)

            if input.IsButtonDown(KEY_A) or input.IsButtonDown(KEY_W) or input.IsButtonDown(KEY_D) or input.IsButtonDown(KEY_S) then
                local eyePos = localPos + pLocal:GetPropVector("localdata", "m_vecViewOffset[0]")

                if input.IsButtonDown(KEY_A) or input.IsButtonDown(KEY_W) then
                    vDirection = vDirection - (viewAngles:Right() * mDistance:GetValue()) -- Left
                elseif input.IsButtonDown(KEY_D) or input.IsButtonDown(KEY_S) then
                    vDirection = vDirection + (viewAngles:Right() * mDistance:GetValue()) -- Right
                end

                local traceDest = eyePos + vDirection
                local trace = engine.TraceLine(eyePos, traceDest, MASK_SOLID)

                if trace then
                    PeekStartVec = trace.startpos
                    PeekDirectionVec = trace.endpos - trace.startpos
                    HasDirection = true
                end
            end
        end

        -- Should we peek?
        if mFreeMove:GetValue() == false and HasDirection == true then
            local targetFound = false
            local segmentSize = math.floor(100 / mSegments:GetValue())
            LineDrawList = {}
            for i = 1, mSegments:GetValue() do
                local step = (i * segmentSize) / 100
                local currentPos = PeekStartVec + (PeekDirectionVec * step)
                if CanAttackFromPos(pLocal, currentPos) then
                    WalkTo(pCmd, pLocal, currentPos)
                    targetFound = true
                end

                DrawLine(PeekReturnVec, currentPos)
                if targetFound then
                    break
                end
            end

            if targetFound == false then IsReturning = true end
        end

        -- We've just attacked. Let's return!
        if pCmd:GetButtons() & IN_ATTACK == 1 then
            IsReturning = true
        end

        if IsReturning == true then
            local distVector = PeekReturnVec - localPos
            local dist = distVector:Length()
            if dist < 7 then
                IsReturning = false
                return
            end

            WalkTo(pCmd, pLocal, PeekReturnVec)
        end
    else
        PosPlaced = false
        IsReturning = false
        HasDirection = false
        PeekReturnVec = Vector3(0, 0, 0)
    end
end

local function OnDraw()
    if PosPlaced == false then return end

    draw.SetFont(options.Font)
    draw.Color(255, 255, 255, 255)

    -- Draw the lines
    if HasDirection == true then
        draw.Color(200, 200, 200, 230)
        for k, v in pairs(LineDrawList) do
            local start = client.WorldToScreen(v.start)
            local endPos = client.WorldToScreen(v.endPos)
            if start ~= nil and endPos ~= nil then
                draw.Line(start[1], start[2], endPos[1], endPos[2])
            end
        end
    end

    -- Free move line
    if mFreeMove:GetValue() == true then
        local pLocal = entities.GetLocalPlayer()
        if pLocal then
            draw.Color(255, 255, 255, 255)
            local startPos = client.WorldToScreen(pLocal:GetAbsOrigin())
            local endPos = client.WorldToScreen(PeekReturnVec)
            if startPos ~= nil and endPos ~= nil then
                draw.Line(startPos[1], startPos[2], endPos[1], endPos[2])
            end
        end
    end
end

local function OnUnload()
    MenuLib.RemoveMenu(menu)

    client.Command('play "ui/buttonclickrelease"', true)
end

callbacks.Unregister("CreateMove", "AP_CreateMove")
callbacks.Unregister("Draw", "AP_Draw")
callbacks.Unregister("Unload", "AP_Unload")

callbacks.Register("CreateMove", "AP_CreateMove", OnCreateMove)
callbacks.Register("Draw", "AP_Draw", OnDraw)
callbacks.Register("Unload", "AP_Unload", OnUnload)

client.Command('play "ui/buttonclick"', true)
