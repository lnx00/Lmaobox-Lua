--[[
    Doubletap Bar for Lmaobox
    Author: LNX (github.com/lnx00)
]]

local options = {
    X = 0.5,
    Y = 0.6,
    Size = 5,
    Colors = {
        Background = { 45, 50, 55, 100 },
        Recharge = { 75, 120, 235, 255 },
        Ready = { 70, 190, 50, 255 },
        Outline = { 15, 15, 15, 255 }
    }
}

local MAX_TICKS = 23

local function DT_Enabled()
    local dtMode = gui.GetValue("double tap (beta)")
    local dashKey = gui.GetValue("dash move key")

    return dtMode ~= "off" or dashKey ~= 0
end

local function OnDraw()
    if not DT_Enabled() then return end

    local pLocal = entities.GetLocalPlayer()
    if not pLocal or engine.IsGameUIVisible() then return end

    local pWeapon = pLocal:GetPropEntity("m_hActiveWeapon")
    if not pWeapon then return end

    local ratio = warp.GetChargedTicks() / MAX_TICKS
    local boxWidth = 24 * options.Size
    local boxHeight = math.floor(4 * options.Size)
    local barWidth = math.floor(boxWidth * ratio)

    local sWidth, sHeight = draw.GetScreenSize()
    local xPos = math.floor(sWidth * options.X - boxWidth * 0.5)
    local yPos = math.floor(sHeight * options.Y - boxHeight * 0.5)

    draw.Color(table.unpack(options.Colors.Background))
    draw.FilledRect(xPos, yPos, xPos + boxWidth, yPos + boxHeight)

    if warp.IsWarping() or warp.GetChargedTicks() < MAX_TICKS then
        draw.Color(table.unpack(options.Colors.Recharge))
    elseif warp.CanDoubleTap(pWeapon) then
        draw.Color(table.unpack(options.Colors.Ready))
    else
        draw.Color(205, 95, 50, 255)
    end

    draw.FilledRect(xPos, yPos, xPos + barWidth, yPos + boxHeight)

    draw.Color(table.unpack(options.Colors.Outline))
    draw.OutlinedRect(xPos, yPos, xPos + boxWidth, yPos + boxHeight)
end

callbacks.Unregister("Draw", "lnx_DT-Bar_Draw")
callbacks.Register("Draw", "lnx_DT-Bar_Draw", OnDraw)