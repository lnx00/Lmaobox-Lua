--[[
    Minecraft Healthbar for Lmaobox
    Author: LNX (github.com/lnx00)
    Credits: cathook
]]

local options = {
    X = 0.35,
    Y = 0.75,
    Size = 32
}

-- Load the textures
local texArmorFull = draw.CreateTexture("Textures/Armor_Full.png")
local texArmorHalf = draw.CreateTexture("Textures/Armor_Half.png")
local texArmorNone = draw.CreateTexture("Textures/Armor_None.png")
local texGoldFull = draw.CreateTexture("Textures/Gold_Full.png")
local texGoldHalf = draw.CreateTexture("Textures/Gold_Half.png")
local texHeartFull = draw.CreateTexture("Textures/Heart_Full.png")
local texHeartHalf = draw.CreateTexture("Textures/Heart_Half.png")
local texHeartNone = draw.CreateTexture("Textures/Heart_None.png")

local function Draw()
    local pLocal = entities.GetLocalPlayer()
    if not pLocal or engine.IsGameUIVisible() or not pLocal:IsAlive() then return end

    local sWidth, sHeight = draw.GetScreenSize()
    local xPos = math.floor(sWidth * options.X)
    local yPos = math.floor(sHeight * options.Y)

    local halfHeart = pLocal:GetMaxHealth() / 20
    local halfHearts = pLocal:GetHealth() / halfHeart
    local fullHearts = math.floor((halfHearts / 20) * 10)

    local maxBuffHealth = (math.floor((pLocal:GetMaxHealth() * 1.5) / 10) * 10) - 10
    local maxAdditionalHealth = maxBuffHealth - pLocal:GetMaxHealth()
    local absorptionHealth = pLocal:GetHealth() - pLocal:GetMaxHealth()
    local absorbHalfs = math.floor((absorptionHealth / maxAdditionalHealth) * 20)
    local absorbFulls = math.floor((absorbHalfs - 1) / 2)
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

    -- Armor (Medic only)
    local pWeapon = pLocal:GetPropEntity("m_hActiveWeapon")
    if pWeapon and pWeapon:IsMedigun() then
        local chargeLevel = pWeapon:GetPropFloat("LocalTFWeaponMedigunData", "m_flChargeLevel")
        if chargeLevel then
            local fullArmors = math.floor(4 * chargeLevel)
            local halfArmors = math.floor(8 * chargeLevel)

            for i = 0, 3 do
                local cX = xPos + (i * options.Size)
                local cY = yPos - options.Size - 1

                if i + 1 <= fullArmors then
                    draw.TexturedRect(texArmorFull, cX, cY, cX + options.Size, cY + options.Size)
                elseif (fullArmors + 1 == i + 1) and not (math.floor(halfArmors) % 2 == 0) then
                    draw.TexturedRect(texArmorHalf, cX, cY, cX + options.Size, cY + options.Size)
                else
                    draw.TexturedRect(texArmorNone, cX, cY, cX + options.Size, cY + options.Size)
                end
            end
        end
    end
end

-- Unload the textures
local function Unload()
    draw.DeleteTexture(texArmorFull)
    draw.DeleteTexture(texArmorHalf)
    draw.DeleteTexture(texArmorNone)
    draw.DeleteTexture(texGoldFull)
    draw.DeleteTexture(texGoldHalf)
    draw.DeleteTexture(texHeartFull)
    draw.DeleteTexture(texHeartHalf)
    draw.DeleteTexture(texHeartNone)

    client.Command('play "ui/buttonclickrelease"', true)
end

callbacks.Unregister("Draw", "MCHB_Draw");
callbacks.Register("Draw", "MCHB_Draw", Draw)

callbacks.Unregister("Unload", "MCHB_Unload");
callbacks.Register("Unload", "MCHB_Unload", Unload)

client.Command('play "ui/buttonclick"', true)