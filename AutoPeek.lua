--[[
    Auto Peek for Lmaobox
    Author: LNX (github.com/lnx00)
]]

local options = {
    Key = KEY_LSHIFT,
    FreeMove = false,
    Distance = 200,
    Font = draw.CreateFont("Roboto", 20, 400)
}

local posPlaced = false
local isReturning = false
local hasDirection = false
local peekStart = Vector3(0, 0, 0)
local peekVector = Vector3(0, 0, 0)
local peekReturnPos = Vector3(0, 0, 0)

-- Drawing
local lineList = {}

local function OnGround(player)
    local pFlags = player:GetPropInt("m_fFlags")
    return (pFlags & FL_ONGROUND) == 1
end

local function VisPos(target, vFrom, vTo)
    local trace = engine.TraceLine(vFrom, vTo, MASK_SHOT | CONTENTS_GRATE)
    return ((trace.entity and trace.entity == target) or (trace.fraction > 0.99))
end

local function CanAttack(pLocal, pPos)
    local pWeapon = pLocal:GetPropEntity("m_hActiveWeapon")
    if not pWeapon then return end

    local players = entities.FindByClass("CTFPlayer")
    for k, vPlayer in pairs(players) do
        if vPlayer:IsValid() == false then goto continue end
        if vPlayer:IsAlive() == false then goto continue end
        if vPlayer:GetTeamNumber() == pLocal:GetTeamNumber() then goto continue end
        -- TODO: Check friends etc.

        -- TODO: Check for hitbox and not abs
        if VisPos(vPlayer, pPos, vPlayer:GetAbsOrigin()) then
            return true
        end

        ::continue::
    end

    return false
end

local function ComputeMove(pCmd, pLocal, a, b)
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

    -- TODO: Apply upmove in water
    return move
end

local function WalkTo(pCmd, pLocal, a, b, scale)
    local result = ComputeMove(pCmd, pLocal, a, b)

    pCmd:SetForwardMove(result.x * scale)
    pCmd:SetSideMove(result.y * scale)
    pCmd:SetUpMove(result.z * scale)
end

local function WalkToVec(pCmd, pLocal, pDestination)
    local localPos = pLocal:GetAbsOrigin()
    WalkTo(pCmd, pLocal, localPos, pDestination, 1)
end

local function OnCreateMove(pCmd)
    local pLocal = entities.GetLocalPlayer()
    if not pLocal then return end

    if pLocal:IsAlive() and input.IsButtonDown(options.Key) then
        local localPos = pLocal:GetAbsOrigin()

        -- We just started peeking. Save the return position!
        if posPlaced == false then
            if OnGround(pLocal) then
                peekReturnPos = localPos
                posPlaced = true
            end
        else
            -- TODO: Particle effect
        end

        -- We need a peek direction (A / D)
        if options.FreeMove == false and hasDirection == false and OnGround(pLocal) then
            local viewAngles = engine.GetViewAngles()
            local vForward = viewAngles:Forward()
            local vRight = viewAngles:Right()
            local vUp = viewAngles:Up()
            local vDirection = Vector3(0, 0, 0)

            if input.IsButtonDown(KEY_A) or input.IsButtonDown(KEY_W) or input.IsButtonDown(KEY_D) or input.IsButtonDown(KEY_S) then
                local viewOffset = pLocal:GetPropVector("localdata", "m_vecViewOffset[0]")
                local eyePos = viewOffset + localPos
                
                if input.IsButtonDown(KEY_A) or input.IsButtonDown(KEY_W) then
                    vDirection = eyePos - (vRight * options.Distance) -- Left
                elseif input.IsButtonDown(KEY_D) or input.IsButtonDown(KEY_S) then
                    vDirection = eyePos + (vRight * options.Distance) -- Right
                end

                print("Data:")
                print(eyePos)
                print(vDirection)

                local trace = engine.TraceLine(eyePos, vDirection, MASK_SOLID)
                if trace then
                    peekStart = eyePos
                    peekVector = vDirection
                    hasDirection = true
                end
            end
        end

        -- Should we peek?
        if options.FreeMove == false and hasDirection == true then
            local targetFound = false
            lineList = {}
            for i = 1, 10 do
                local step = (i * 10) / 100
                local currentPos = peekStart + (peekVector * step)
                if CanAttack(pLocal, currentPos) then
                    WalkToVec(pCmd, pLocal, currentPos)
                    targetFound = true
                end

                if targetFound then
                    -- TODO: Draw a line to the target
                    
                end

                -- TODO: Draw visualization
                table.insert(lineList, {
                    start = peekReturnPos,
                    endPos = currentPos
                })
            end

            if targetFound == false then isReturning = true end
        end
    
        -- We've just attacked. Let's return!
        if pCmd:GetButtons() & IN_ATTACK == 1 then
            isReturning = true
        end

        if isReturning == true then
            local distVector = peekReturnPos - localPos
            local dist = distVector:Length()
            if dist < 7 then
                isReturning = false
                return
            end

            WalkToVec(pCmd, pLocal, peekReturnPos)
        end
    else
        posPlaced = false
        isReturning = false
        hasDirection = false
        peekReturnPos = Vector3(0, 0, 0)
    end
end

local function OnDraw()
    if posPlaced == false then return end

    draw.SetFont(options.Font)
    draw.Color(255, 255, 255, 255)

    -- Draw the peek return position
    local screenPos = client.WorldToScreen(peekReturnPos)
    if screenPos ~= nil then
        draw.Text(screenPos[1], screenPos[2], "Peek Return")
    end

    -- Draw the lines
    for k, v in pairs(lineList) do
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