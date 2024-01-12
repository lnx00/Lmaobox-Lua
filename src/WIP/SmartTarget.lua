--[[
    (Concept)
    Smart target system for Lmaobox
    Author: github.com/lnx00
]]

---@alias Target { player: Entity, factor: number }

---@type LNXlib
local lnxLib = require("LNXlib")
local Math = lnxLib.Utils.Math
local Fonts = lnxLib.UI.Fonts
lnxLib.Utils.UnloadPackages("ImMenu")

---@type ImMenu
local ImMenu = require("ImMenu")

local settings = {
    MinDistance = 200,
    MaxDistance = 600,
    MinHealth = 0,
    MaxHealth = 100,
    MinFOV = 0,
    MaxFOV = 180,
    ShowFactors = false,
    ShowTarget = true,
}

local function OnDraw()
    draw.SetFont(Fonts.Segoe)
    draw.Color(255, 255, 255, 255)

    local players = entities.FindByClass("CTFPlayer")
    local localPlayer = entities.GetLocalPlayer()
    if not localPlayer then return end

    ---@type Target[]
    local targetList = {}

    -- Calculate target factors
    for entIdx, player in pairs(players) do
        if entIdx == localPlayer:GetIndex() then goto continue end

        local distance = (player:GetAbsOrigin() - localPlayer:GetAbsOrigin()):Length()
        local health = player:GetHealth()

        local angles = Math.PositionAngles(localPlayer:GetAbsOrigin(), player:GetAbsOrigin())
        local fov = Math.AngleFov(engine.GetViewAngles(), angles)

        local distanceFactor = Math.RemapValClamped(distance, settings.MinDistance, settings.MaxDistance, 1, 0.1)
        local healthFactor = Math.RemapValClamped(health, settings.MinHealth, settings.MaxHealth, 1, 0.5)
        local fovFactor = Math.RemapValClamped(fov, settings.MinFOV, settings.MaxFOV, 1, 0.5)
        --print("Distance: " .. distance .. " | Health: " .. health .. " | DistanceFactor: " .. distanceFactor .. " | HealthFactor: " .. healthFactor)

        local factor = distanceFactor * healthFactor * fovFactor
        table.insert(targetList, { player = player, factor = factor })

        if settings.ShowFactors then
            local screenPos = client.WorldToScreen(player:GetAbsOrigin())
            if screenPos then
                draw.Text(screenPos[1], screenPos[2] - 15, string.format("Distance: %.2f, Health: %.2f, Fov: %.2f, Total: %.2f", distanceFactor, healthFactor, fovFactor, factor))
                --draw.Text(screenPos[1], screenPos[2] - 15, string.format("Distance: %.2f, Health: %.2f, FOV: %.2f", distance, health, fov))
            end
        end

        ::continue::
    end

    -- Sort target list by factor
    table.sort(targetList, function(a, b)
        return a.factor > b.factor
    end)

    -- Draw main target
    if settings.ShowTarget then
        local mainTarget = targetList[1]
        local screenPos = client.WorldToScreen(mainTarget.player:GetAbsOrigin())
        if screenPos then
            draw.Text(screenPos[1], screenPos[2], string.format("Main Target (%.2f)", mainTarget.factor))
        end
    end

    -- Menu
    if ImMenu.Begin("Smart Target", true) then
        ImMenu.Text("Factors")
        settings.MinDistance = ImMenu.Slider("Min Distance", settings.MinDistance, 0, settings.MaxDistance - 1)
        settings.MaxDistance = ImMenu.Slider("Max Distance", settings.MaxDistance, settings.MinDistance + 1, 1000)
        settings.MinHealth = ImMenu.Slider("Min Health", settings.MinHealth, 0, settings.MaxHealth - 1)
        settings.MaxHealth = ImMenu.Slider("Max Health", settings.MaxHealth, settings.MinHealth + 1, 100)
        settings.MinFOV = ImMenu.Slider("Min FOV", settings.MinFOV, 0, settings.MaxFOV - 1)
        settings.MaxFOV = ImMenu.Slider("Max FOV", settings.MaxFOV, settings.MinFOV + 1, 180)

        ImMenu.Separator()
        ImMenu.Text("Debug")
        settings.ShowFactors = ImMenu.Checkbox("Show Factors", settings.ShowFactors)
        settings.ShowTarget = ImMenu.Checkbox("Show Target", settings.ShowTarget)

        ImMenu.Separator()
        ImMenu.Text("Targets")
        for i, target in pairs(targetList) do
            ImMenu.Text(string.format("%d. %s (%.3f)", i, target.player:GetName(), target.factor))
        end

        ImMenu.End()
    end
end

callbacks.Unregister("Draw", "LNX.SmartTarget.OnDraw")
callbacks.Register("Draw", "LNX.SmartTarget.OnDraw", OnDraw)