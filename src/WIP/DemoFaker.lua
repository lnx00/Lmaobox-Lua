--[[
    Demo faker/manipulator for Lmaobox
    Author: LNX (github.com/lnx00)
]]

if UnloadLib then UnloadLib() end

---@type boolean, lnxLib
local libLoaded, lnxLib = pcall(require, "lnxLib")
assert(libLoaded, "lnxLib not found, please install it!")
assert(lnxLib.GetVersion() >= 0.993, "lnxLib version is too old, please update it!")

---@type boolean, ImMenu
local menuLoaded, ImMenu = pcall(require, "ImMenu")
assert(menuLoaded, "ImMenu not found, please install it!")
assert(ImMenu.GetVersion() >= 0.66, "ImMenu version is too old, please update it!")

local WPlayer, Helpers, Math = lnxLib.TF2.WPlayer, lnxLib.TF2.Helpers, lnxLib.Utils.Math

local options = {
    Target = 2,
    Spinbot = false,
    SpinSpeed = 10,
    SpinPitch = true,
    Aimbot = false,
    Fakelag = false
}

local spinAngle = Vector3(0, 0, 0)
local lagPos = Vector3()
local lagTicks = 0

---@param target WPlayer
local function ApplySpinbot(target)
    spinAngle.y = spinAngle.y + options.SpinSpeed
    if options.SpinPitch then
        spinAngle.x = math.random(-89, 89)
    end

    target:SetPropVector(spinAngle, "tfnonlocaldata", "m_angEyeAngles[0]")
end

---@param target WPlayer
local function ApplyAimbot(target)
    -- Find an aim target
    local players = entities.FindByClass("CTFPlayer")
    local aimTarget = nil
    for idx, player in pairs(players) do
        if not player:IsAlive() or player:IsDormant() then goto continue end
        if player:GetTeamNumber() == target:GetTeamNumber() then goto continue end

        aimTarget = player

        ::continue::
    end

    if not aimTarget then return end

    -- Get the aim angle
    local angles = Math.PositionAngles(target:GetEyePos(), aimTarget:GetAbsOrigin())
    target:SetPropVector(Vector3(angles.x, angles.y, angles.z), "tfnonlocaldata", "m_angEyeAngles[0]")
end

local function ApplyFakeProps()
    if options.Target == nil then return end

    local entity = entities.GetByIndex(options.Target)
    if not entity then return end
    if not entity:IsAlive() or entity:IsDormant() then return end

    local target = WPlayer.FromEntity(entity)

    if options.Spinbot then
        ApplySpinbot(target)
    end

    if options.Aimbot then
        ApplyAimbot(target)
    end
end

---@param userCmd UserCmd
local function OnCreateMove(userCmd)
end

local function OnPropUpdate()
    ApplyFakeProps()
end

local function OnDraw()
    if ImMenu.Begin("Demo Faker", true) then
        ImMenu.Text("Target: " .. (options.Target and options.Target or "None"))
        ImMenu.Separator()

        -- Spinbot
        options.Spinbot = ImMenu.Checkbox("Spinbot", options.Spinbot)
        if options.Spinbot then
            options.SpinSpeed = ImMenu.Slider("Spin speed", options.SpinSpeed, 1, 20)
            options.SpinPitch = ImMenu.Checkbox("Random pitch", options.SpinPitch)
        end

        -- Aimbot
        options.Aimbot = ImMenu.Checkbox("Aimbot", options.Aimbot)

        ImMenu.End()
    end
end

callbacks.Register("CreateMove", OnCreateMove)
callbacks.Register("PostPropUpdate", OnPropUpdate)
callbacks.Register("Draw", OnDraw)