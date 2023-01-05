--[[
    Simple ESP for Lmaobox
    Dependencies: LNXlib (github.com/lnx00/Lmaobox-Library)
    Author: LNX (github.com/lnx00)
]]

---@type boolean, LNXlib
local libLoaded, Lib = pcall(require, "LNXlib")
assert(libLoaded, "LNXlib not found, please install it!")
assert(Lib.GetVersion() >= 0.75, "LNXlib version is too old, please update it!")

local TF2, Helpers = Lib.TF2, Lib.TF2.Helpers

local espFont = draw.CreateFont("Verdana", 16, 800)

local function OnDraw()
    if engine.IsGameUIVisible() then return end
    draw.SetFont(espFont)

    local localPlayer = entities.GetLocalPlayer()
    local players = entities.FindByClass("CTFPlayer")

    for _, entity in ipairs(players) do
        if entity == localPlayer or not entity:IsAlive() or entity:IsDormant() then goto continue end

        local player = TF2.WPlayer.FromEntity(entity)
        local bEnemy = player:GetTeamNumber() ~= localPlayer:GetTeamNumber()

        -- Get the bounding box
        local bbox = Helpers.GetBBox(player)
        if bbox == nil then goto continue end

        -- Draw the box
        draw.Color(bEnemy and 255 or 0, bEnemy and 0 or 255, 0, 255)
        draw.OutlinedRect(bbox.x, bbox.y, bbox.x + bbox.w, bbox.y + bbox.h)

        -- Draw the name
        local name = player:GetName()
        local nameWidth, nameHeight = draw.GetTextSize(name)
        draw.Text(math.floor(bbox.x + bbox.w * 0.5 - nameWidth * 0.5), bbox.y - nameHeight - 10, name)

        -- Draw the health bar
        local health = player:GetHealth()
        local maxHealth = player:GetMaxHealth()
        local healthBarSize = math.floor(bbox.w * (health / maxHealth))
        draw.Color(255 - math.floor(health / maxHealth * 255), math.floor(health / maxHealth * 255), 0, 255)
        draw.FilledRect(bbox.x, bbox.y - 5, bbox.x + healthBarSize, bbox.y - 2)

        ::continue::
    end
end

callbacks.Unregister("Draw", "SESP_Draw")
callbacks.Register("Draw", "SESP_Draw", OnDraw)