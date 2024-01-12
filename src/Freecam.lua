--[[
    Freecam for Lmaobox
    Author: LNX (github.com/lnx00)
]]

local options = {
    Key = KEY_LSHIFT,
    Speed = 10
}

local vFreecamPos = Vector3(0, 0, 0)
local bFreecamActive = false

local function CreateMove(pCmd)
    local pLocal = entities.GetLocalPlayer()
    if input.IsButtonDown(options.Key) then
        if not bFreecamActive then
            vFreecamPos = pLocal:GetAbsOrigin()
            bFreecamActive = true
        end

        local x, y, z = engine.GetViewAngles():Unpack()
        local viewAngles = Vector3(x, y, z)
        local vForward = viewAngles:Forward()
        local vRight = viewAngles:Right()
        local moveVector = Vector3(0, 0, 0)

        if input.IsButtonDown(KEY_W) then
            moveVector = moveVector + vForward
        end

        if input.IsButtonDown(KEY_S) then
            moveVector = moveVector - vForward
        end

        if input.IsButtonDown(KEY_A) then
            moveVector = moveVector - vRight
        end

        if input.IsButtonDown(KEY_D) then
            moveVector = moveVector + vRight
        end

        moveVector:Normalize()
        moveVector = moveVector * options.Speed
        vFreecamPos = vFreecamPos + moveVector

        pCmd:SetButtons(0)
        pCmd:SetForwardMove(0)
        pCmd:SetSideMove(0)
        pCmd:SetUpMove(0)
    else
        bFreecamActive = false
    end
end

local function PostPropUpdate()
    if input.IsButtonDown(options.Key) and bFreecamActive then
        local pLocal = entities.GetLocalPlayer()
        pLocal:SetPropVector(vFreecamPos, "tfnonlocaldata", "m_vecOrigin")
        --pLocal:SetAbsOrigin(vFreecamPos)
    end
end

callbacks.Unregister("CreateMove", "CreateMove_Freecam")
callbacks.Unregister("PostPropUpdate", "FSN_Freecam")

callbacks.Register("CreateMove", "CreateMove_Freecam", CreateMove)
callbacks.Register("PostPropUpdate", "FSN_Freecam", PostPropUpdate)

client.Command('play "ui/buttonclick"', true)