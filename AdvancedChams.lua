--[[
    Advanced Chams for Lmaobox
    Author: LNX (github.com/lnx00)
]]
local menuLoaded, MenuLib = pcall(require, "Menu")
if not menuLoaded then
    print("The Menu library could not be found!")
    do return end
end

MenuLib.DebugInfo = true

local chamMaterials = {
    materials.Create("AC_Simple", [["VertexLitGeneric" 
    {
      $basetexture "vgui/white_additive"
      $bumpmap "vgui/white_additive"
      $envmap "cubemaps/cubemap_sheen001"
      $phong "1"
      $selfillum "1"
      $selfillumfresnel "1"
      $selfillumfresnelminmaxexp "[-0.25 1 1]"
    }
    ]]),
    
    materials.Create("AC_Fresnel", [["VertexLitGeneric"
    {
      $basetexture "vgui/white_additive"
      $bumpmap "models/player/shared/shared_normal"
      $envmap "skybox/sky_dustbowl_01"
      $envmapfresnel "1"
      $phong "1"
      $phongfresnelranges "[0 0.05 0.1]"
      $selfillum "1"
      $selfillumfresnel "1"
      $selfillumfresnelminmaxexp "[0.5 0.5 0]"
      $selfillumtint "[0 0 0]"
      $envmaptint "[0 1 0]"
    }
    ]]),

    materials.Create("AC_Flat", [["UnlitGeneric"
    {
        $basetexture "vgui/white_additive"
    }
    ]]),

    materials.Create("AC_Plastic", [["VertexLitGeneric"
    {
        $basetexture "models/player/shared/ice_player"
        $bumpmap "models/player/shared/shared_normal"
        $phong "1"
		$phongexponent "10"
		$phongboost "1"
		$phongfresnelranges "[0 0 0]"
		$basemapalphaphongmask "1"
		$phongwarptexture "models/player/shared/ice_player_warp"
    }
    ]]),
}

local menu = MenuLib.Create("Advanced Chams", MenuFlags.AutoSize)
local enabled = menu:AddComponent(MenuLib.Checkbox("Enable Chams", true))
local ignoreZ = menu:AddComponent(MenuLib.Checkbox("Ignore Z", false))

local chamNames = { "Simple", "Fresnel", "Flat", "Plastic" }
local teamCombo = menu:AddComponent(MenuLib.Combo("Team Material", chamNames))
local enemyCombo = menu:AddComponent(MenuLib.Combo("Enemy Material", chamNames))

local function DrawModel(dmContext)
    local entity = dmContext:GetEntity()
    local pLocal = entities.GetLocalPlayer()

    if not (entity and entity:IsValid() and entity:IsPlayer() and pLocal and enabled:GetValue()) then return end

    if entity:GetTeamNumber() == pLocal:GetTeamNumber() then
        local material = chamMaterials[teamCombo:GetSelectedIndex()]
        material:ColorModulate(0, 200, 0)
        material:SetMaterialVarFlag(MATERIAL_VAR_IGNOREZ, ignoreZ:GetValue())
        dmContext:ForcedMaterialOverride(material)
    else
        local material = chamMaterials[enemyCombo:GetSelectedIndex()]
        material:ColorModulate(200, 0, 0)
        material:SetMaterialVarFlag(MATERIAL_VAR_IGNOREZ, ignoreZ:GetValue())
        dmContext:ForcedMaterialOverride(material)
    end
end

local function Unload()
    MenuLib:RemoveMenu(menu)

    client.Command('play "ui/buttonclickrelease"', true)
end

callbacks.Unregister("DrawModel", "AC_DrawModel")
callbacks.Register("DrawModel", "AC_DrawModel", DrawModel)

callbacks.Unregister("Unload", "AC_Unload")
callbacks.Register("Unload", "AC_Unload", Unload)

client.Command('play "ui/buttonclick"', true)