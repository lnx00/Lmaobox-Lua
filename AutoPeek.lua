--[[
    Auto Peek for Lmaobox
    Author: LNX (github.com/lnx00)
]]

local options = {
    Key = KEY_LSHIFT,
    FreeMove = false,
    Distance = 200
}

local posPlaced = false
local isReturning = false
local hasDirection = false
local peekStart = Vector3(0, 0, 0)
local peekVector = Vector3(0, 0, 0)
local peekReturnPos = Vector3(0, 0, 0)

local function OnGround(player)
    -- TODO: This
    return true
end

local function CreateMove(pCmd)
    local pLocal = entities.GetLocalPlayer()
    if not pLocal then return end

    if pLocal:IsAlive() and input.IsButtonDown(options.Key) then
        local localPos = pLocal:GetAbsOrigin()

        -- We just started peeking. Save the return position!
        if posPlaced == false then
            if OnGround(pLocal) then
                peekStart = localPos
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
                    vDirection = eyePos - vRight * options.Distance
                elseif input.IsButtonDown(KEY_D) or input.IsButtonDown(KEY_S) then
                    vDirection = eyePos + vRight * options.Distance
                end

                local trace = engine.TraceLine(eyePos, vDirection, MASK_SOLID)
                if trace then
                    peekStart = eyePos
                    peekVector = vDirection * trace.fraction
                    hasDirection = true
                end
            end
        end

        -- Should we peek?
        if options.FreeMove == false and hasDirection == true then
            local targetFound = false
            for i = 1, 10 do
                local step = (i * 10) / 100
                local currentPos = peekStart + (peekVector * step)
                -- Check if we can attack

                if targetFound then
                    -- TODO: Draw a line to the target
                end

                -- TODO: Draw visualization
            end

            if targetFound == false then isReturning = true end
        end
    
        -- We've just attacked. Let's return!
        if pCmd.buttons & IN_ATTACK == 1 then
            -- TODO: This is always true?
            isReturning = true
        end

        if isReturning then
            local distVector = peekReturnPos - localPos
            local dist = distVector:Length()
            if dist < 7 then
                isReturning = false
                return
            end

            -- TODO: Walk to destination
            print("Walking to desitination...")
        end
    else
        posPlaced = false
        peekReturnPos = Vector3(0, 0, 0)
    end
end

callbacks.Unregister("CreateMove", "AutoPeek_CreateMove") 
callbacks.Register("CreateMove", "AutoPeek_CreateMove", CreateMove)

client.Command('play "ui/buttonclick"', true)