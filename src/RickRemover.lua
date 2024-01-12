materials.Enumerate(function (material)
    local name = material:GetName()
    if name:find("models/soldier_statue") then
        print("Hiding: " .. name)
        material:SetMaterialVarFlag(MATERIAL_VAR_NO_DRAW, true)
    end
end)