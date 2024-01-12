--[[
    Crit Indicator for Lmaobox
    Author: LNX (github.com/lnx00)
]]

local Options = {
    X = 100,
    Y = 100,
    Width = 200,
    Height = 50,
    Font = draw.CreateFont("Roboto", 16, 400)
}

local function OnDraw()
    draw.Color(255, 255, 255, 255)
    draw.SetFont(Options.Font)

    local pLocal = entities.GetLocalPlayer()
    if not pLocal then return end
    local pWeapon = pLocal:GetPropEntity("m_hActiveWeapon")
    if not pWeapon then return end
    local critChance = pWeapon:GetCritChance()
    if not critChance then return end

    local currentY = Options.Y

    local bucketCap = client.GetConVar("tf_weapon_criticals_bucket_cap")
    local critBucket = pWeapon:GetCritTokenBucket()
    local dmgStats = pWeapon:GetWeaponDamageStats()
    local cmpCritChance = critChance + 0.1

    -- Draw crit info
    draw.Text(Options.X, currentY, "Bucket: " .. math.floor(critBucket) .. "/" .. math.floor(bucketCap))
    currentY = currentY + 20

    -- Are we crit banned?
    if cmpCritChance <= pWeapon:CalcObservedCritChance() then
        local requiredTotalDamage = (dmgStats["critical"] * (2.0 * cmpCritChance + 1.0)) / cmpCritChance / 3.0
        local requiredDamage = requiredTotalDamage - dmgStats["total"]

        draw.Color(235, 59, 90, 255)
        draw.Text(Options.X, currentY, "Damage until crit: " .. math.floor(requiredDamage))
    else
        draw.Color(235, 59, 90, 255)
        draw.Text(Options.X, currentY, "ok")
    end
end

callbacks.Unregister("Draw", "CI_Draw")
callbacks.Register("Draw", "CI_Draw", OnDraw)
