--[[
    Indicators for Lmaobox
    Author: LNX (github.com/lnx00)
]]

local options = {
    Font = draw.CreateFont("Roboto", 22, 400)
}

local features = {
    "Anti Aim",
    "Anti Backstab",
    "Chat Spammer",
    "Fake Latency",
    "Fake Lag",
    "Duck Speed",
    "Ping Reducer",
    "Name Stealer"
}

function RGBRainbow(offset)
    local r,g,b
    r = math.floor(math.sin(offset + 0) * 127 + 128)
    g = math.floor(math.sin(offset + 2) * 127 + 128)
    b = math.floor(math.sin(offset + 4) * 127 + 128)
  
    return r, g, b
end

local function IsActive(feature)
    local guiValue = gui.GetValue(string.lower(feature))
    if (type(guiValue) == "number") and (guiValue == 1) then
        return true
    elseif (type(guiValue) == "string") and (guiValue ~= "off") then
        return true
    end

    return false
end

local function Draw()
    local sWidth, sHeight = draw.GetScreenSize()
    local currentY = 220

    draw.SetFont(options.Font)
    for i, feature in ipairs(features) do
        local r, g, b = RGBRainbow(i)
        draw.Color(r, g, b, 225)

        if IsActive(feature) then
            local tWidth, tHeight = draw.GetTextSize(feature)
            draw.Text(sWidth - (tWidth + 15), currentY, feature, options.Font)
            currentY = currentY + tHeight
        end
    end
end

callbacks.Unregister("Draw", "Indicators_Draw");
callbacks.Register("Draw", "Indicators_Draw", Draw)