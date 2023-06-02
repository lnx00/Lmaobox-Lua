--[[
    Cheater Detection for Lmaobox
    Author: LNX (github.com/lnx00)
]]

---@alias PlayerData { Angle : EulerAngles[], Position : Vector3[], SimTime : number[] }

---@type boolean, lnxLib
local libLoaded, lnxLib = pcall(require, "lnxLib")
assert(libLoaded, "lnxLib not found, please install it!")
assert(lnxLib.GetVersion() >= 0.981, "lnxLib version is too old, please update it!")

local WPlayer = lnxLib.TF2.WPlayer

local options = {
    StrikeLimit = 3,
    MaxAngleDelta = 50,
    AutoMark = true
}

local prevData = {} ---@type PlayerData
local playerStrikes = {} ---@type table<number, number>

local function StrikePlayer(idx, reason)
    if not playerStrikes[idx] then
        playerStrikes[idx] = 0
    end

    playerStrikes[idx] = playerStrikes[idx] + 1

    if playerStrikes[idx] < options.StrikeLimit then
        client.ChatPrintf(string.format("\x04[CD] \x01Player \x05%d \x01has been striked for \x05%s", idx, reason))
    elseif playerStrikes[idx] == options.StrikeLimit then
        client.ChatPrintf(string.format("\x04[CD] \x01Player \x05%d \x01is cheating!", idx))
    end
end

---@param player WPlayer
local function CheckPitch(player)
    local angles = player:GetEyeAngles()

    if angles.pitch >= 90 or angles.pitch <= -90 then
        StrikePlayer(player:GetIndex(), "Invalid pitch")
    end
end

---@param userCmd UserCmd
local function OnCreateMove(userCmd)
    local me = WPlayer.GetLocal()
    if not me then return end

    -- Get current data
    local currentData = {
        Angle = {},
        Position = {},
        SimTime = {}
    }
    local players = entities.FindByClass("CTFPlayer")
    for idx, entity in pairs(players) do
        if idx ~= me:GetIndex() then goto continue end
        if entity:IsDormant() or not entity:IsAlive() then goto continue end
        local player = WPlayer.FromEntity(entity)

        currentData.Angle[idx] = player:GetEyeAngles()
        currentData.Position[idx] = player:GetAbsOrigin()
        currentData.SimTime[idx] = player:GetSimulationTime()

        CheckPitch(player)

        ::continue::
    end

    prevData = currentData
end

callbacks.Register("CreateMove", OnCreateMove)