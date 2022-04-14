--[[
    Minecraft Healthbar for Lmaobox
    Author: LNX (github.com/lnx00)
    Credits: cathook
]]

local options = {
    X = 0.25,
    Y = 0.7,
    Size = 32
}

local function ReadFileBinary(path)
    local file = io.open(path, "rb")
    if not file then
        print("File not found!")
        return nil
     end
    local content = file:read("*all")
    file:close()
    return content
end

-- Load the textures
local texGoldFull = draw.CreateTexturePNG(ReadFileBinary("Textures/Gold_Full.png"))
local texGoldHalf = draw.CreateTexturePNG(ReadFileBinary("Textures/Gold_Half.png"))
local texHeartFull = draw.CreateTexturePNG(ReadFileBinary("Textures/Heart_Full.png"))
local texHeartHalf = draw.CreateTexturePNG(ReadFileBinary("Textures/Heart_Half.png"))
local texHeartNone = draw.CreateTexturePNG(ReadFileBinary("Textures/Heart_None.png"))

local function Draw()
    local pLocal = entities.GetLocalPlayer()
    if not pLocal then return end

    local sWidth, sHeight = draw.GetScreenSize()
    local xPos = math.floor(sWidth * options.X)
    local yPos = math.floor(sHeight * options.Y)

    local halfHeart = pLocal:GetMaxHealth() / 20
    local halfHearts = pLocal:GetHealth() / halfHeart
    local fullHearts = (halfHearts / 20) * 10

    local maxBuffHealth = (math.floor((pLocal:GetMaxHealth() * 1.5) / 10) * 10) - 10
    local maxAdditionalHealth = maxBuffHealth - pLocal:GetMaxHealth()
    local absorptionHealth = pLocal:GetHealth() - pLocal:GetMaxHealth()
    local absorbHalfs = (absorptionHealth / maxAdditionalHealth) * 20
    local absorbFulls = (absorbHalfs - 1) / 2
    draw.Color(255, 255, 255, 255)

    -- Draw Hearts
    for i = 0, 9 do
        local cX = xPos + (i * options.Size)

        if i + 1 <= fullHearts then
            -- Full Heart
            draw.TexturedRect(texHeartFull, cX, yPos, cX + options.Size, yPos + options.Size)
        elseif (fullHearts + 1 == i + 1) and not (math.floor(halfHearts) % 2 == 0) then
            -- Half Heart
            draw.TexturedRect(texHeartHalf, cX, yPos, cX + options.Size, yPos + options.Size)
        else
            -- Empty Heart
            draw.TexturedRect(texHeartNone, cX, yPos, cX + options.Size, yPos + options.Size)
        end
    end

    -- Draw Absorption
    if absorbHalfs >= 1 then
        for i = 0, 9 do
            local cX = xPos + (i * options.Size)

            if absorbFulls >= i + 1 then
                draw.TexturedRect(texGoldFull, cX, yPos, cX + options.Size, yPos + options.Size)
            elseif absorbHalfs / 2 >= i + 1 then
                draw.TexturedRect(texGoldHalf, cX, yPos, cX + options.Size, yPos + options.Size)
            end
        end
    end
end

-- Unload the textures
local function Unload()
    draw.DeleteTexture(texGoldFull)
    draw.DeleteTexture(texGoldHalf)
    draw.DeleteTexture(texHeartFull)
    draw.DeleteTexture(texHeartHalf)
    draw.DeleteTexture(texHeartNone)
end

callbacks.Unregister("Draw", "MCHB_Draw");
callbacks.Register("Draw", "MCHB_Draw", Draw)

callbacks.Unregister("Unload", "MCHB_Unload");
callbacks.Register("Unload", "MCHB_Unload", Unload)