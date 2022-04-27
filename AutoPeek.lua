--[[
    Auto Peek for Lmaobox
    Author: LNX (github.com/lnx00)
]]

local options = {
    Key = KEY_LSHIFT, -- Hold this key to start peeking
    FreeMove = false, -- Allows you to move freely
    Distance = 200, -- Max peek distance
    Segments = 5, -- Higher values = more precise but worse performance
    Font = draw.CreateFont("Roboto", 20, 400)
}

local PosPlaced = false -- Did we start peeking?
local IsReturning = false -- Are we returning?
local HasDirection = false -- Do we have a peek direction?
local PeekStartVec = Vector3(0, 0, 0)
local PeekDirectionVec = Vector3(0, 0, 0)
local PeekReturnVec = Vector3(0, 0, 0)

local SegmentSize = math.floor(100 / options.Segments)
local LineDrawList = {}

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
        if VisPos(vPlayer, pPos, vPlayer:GetAbsOrigin()) then
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
    pCmd:SetUpMove(result.z)
end

local function DrawLine(startPos, endPos)
    table.insert(LineDrawList, {
        start = startPos,
        endPos = endPos
    })
end

local function OnCreateMove(pCmd)
    local pLocal = entities.GetLocalPlayer()
    if not pLocal then return end

    if pLocal:IsAlive() and input.IsButtonDown(options.Key) then
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
        if options.FreeMove == false and HasDirection == false and OnGround(pLocal) then
            local viewAngles = engine.GetViewAngles()
            local vDirection = Vector3(0, 0, 0)

            if input.IsButtonDown(KEY_A) or input.IsButtonDown(KEY_W) or input.IsButtonDown(KEY_D) or input.IsButtonDown(KEY_S) then
                local eyePos = localPos + pLocal:GetPropVector("localdata", "m_vecViewOffset[0]")

                if input.IsButtonDown(KEY_A) or input.IsButtonDown(KEY_W) then
                    vDirection = vDirection - (viewAngles:Right() * options.Distance) -- Left
                elseif input.IsButtonDown(KEY_D) or input.IsButtonDown(KEY_S) then
                    vDirection = vDirection + (viewAngles:Right() * options.Distance) -- Right
                end

                local traceDest = eyePos + vDirection
                local trace = engine.TraceLine(eyePos, traceDest, MASK_SOLID)

                if trace then
                    PeekStartVec = eyePos
                    PeekDirectionVec = vDirection * trace.fraction
                    HasDirection = true
                end
            end
        end

        -- Should we peek?
        if options.FreeMove == false and HasDirection == true then
            local targetFound = false
            LineDrawList = {}
            for i = 1, options.Segments do
                local step = (i * SegmentSize) / 100
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
    if PosPlaced == false or HasDirection == false then return end

    draw.SetFont(options.Font)
    draw.Color(255, 255, 255, 255)

    -- Draw the peek return position
    local screenPos = client.WorldToScreen(PeekReturnVec)
    if screenPos ~= nil then
        draw.Text(screenPos[1], screenPos[2], "Start Pos")
    end

    -- Draw the lines
    draw.Color(200, 200, 200, 230)
    for k, v in pairs(LineDrawList) do
        local start = client.WorldToScreen(v.start)
        local endPos = client.WorldToScreen(v.endPos)
        if start ~= nil and endPos ~= nil then
            draw.Line(start[1], start[2], endPos[1], endPos[2])
        end
    end
end

callbacks.Unregister("CreateMove", "AP_CreateMove")
callbacks.Unregister("Draw", "AP_Draw")

callbacks.Register("CreateMove", "AP_CreateMove", OnCreateMove)
callbacks.Register("Draw", "AP_Draw", OnDraw)

client.Command('play "ui/buttonclick"', true)
