--[[
    Cheater Detection for Lmaobox
    Author: LNX (github.com/lnx00)
]]

local options = {
    StrikeLimit = 3,
    MaxAngleDelta = 50
}

local playerStrikes = {}
local oldSimTimes = {}
local oldEyeAngles = {}

local function StrikePlayer(index, reason)
    if playerStrikes[index] == nil then
        playerStrikes[index] = 1
    elseif playerStrikes[index] >= 0 then
        playerStrikes[index] = playerStrikes[index] + 1
        client.ChatPrintf("\x04[CD] \x02Player\x05 " .. index .. " \x02striked for:\x05 " .. reason)
    end
end

-- Check if a player is choking packets (Fakelag, Doubletap)
local function CheckChoke(player)
    local simTime = player:GetPropFloat("m_flSimulationTime")
    if not simTime then return end

    if not oldSimTimes[player:GetIndex()] then
        oldSimTimes[player:GetIndex()] = simTime
        return
    end

    local delta = simTime - oldSimTimes[player:GetIndex()]
    if delta > 1 then
        StrikePlayer(player:GetIndex(), "Packet was choked")
    end

    oldSimTimes[player:GetIndex()] = simTime
end

-- Check for invalid pitch (Fake pitch)
local function CheckPitch(player)
    local eyeAnglesX = player:GetPropFloat("tfnonlocaldata", "m_angEyeAngles[0]")
    if not eyeAnglesX then return end

    if (eyeAnglesX ~= 0) and (eyeAnglesX >= 90 and eyeAnglesX <= -90) then
        StrikePlayer(player:GetIndex(), "Invalid Pitch")
    end
end

-- Check angle delta (Silent Aim)
local function CheckAngleDelta(player)
    local eyeAngles = player:GetPropVector("tfnonlocaldata", "m_angEyeAngles")
    if not eyeAngles then return end

    if not oldEyeAngles[player:GetIndex()] then
        oldEyeAngles[player:GetIndex()] = eyeAngles
        return
    end

    local delta = eyeAngles - oldEyeAngles[player:GetIndex()]
    if delta:Length() > options.MaxAngleDelta then
        StrikePlayer(player:GetIndex(), "Invalid Angle Delta")
    end

    oldEyeAngles[player:GetIndex()] = eyeAngles
end

local function OnCreateMove(pCmd)
    local players = entities.FindByClass("CTFPlayer")
    for k, vPlayer in pairs(players) do
        if vPlayer:IsValid() == false or vPlayer:IsAlive() == false then
            oldEyeAngles[vPlayer:GetIndex()] = nil
            goto continue
        end

        CheckChoke(vPlayer)
        CheckPitch(vPlayer)
        CheckAngleDelta(vPlayer)

        ::continue::
    end

    for kIndex, vStrikes in pairs(playerStrikes) do
        if vStrikes == options.StrikeLimit then
            client.ChatPrintf("\x04[CD] \x02Cheater detected:\x05 " .. entities.GetByIndex(kIndex):GetName())
            playerStrikes[kIndex] = -1
        end
    end
end

callbacks.Unregister("CreateMove", "CD_CreateMove")
callbacks.Register("CreateMove", "CD_CreateMove", OnCreateMove)

client.Command('play "ui/buttonclick"', true)