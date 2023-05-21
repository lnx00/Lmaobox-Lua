---@type boolean, lnxLib
local libLoaded, lnxLib = pcall(require, "lnxLib")
assert(libLoaded, "lnxLib not found, please install it!")
assert(lnxLib.GetVersion() >= 0.965, "lnxLib version is too old, please update it!")

local Fonts = lnxLib.UI.Fonts
local WPlayer = lnxLib.TF2.WPlayer

local options = {
    Ticks = 300,
    ObserverMode = 5
}

local replayData = Deque.new()
local currentTarget = 0
local currentRecord = nil
local isRecording = false
local isReplaying = false

-- Records the current tick for all enemies
---@param me Entity
local function DoRecord(me)
    local players = entities.FindByClass("CTFPlayer")
    local record = {}

    for idx, ent in pairs(players) do
        if idx == me:GetIndex() then goto continue end
        if ent:GetTeamNumber() == me:GetTeamNumber() then goto continue end

        local player = WPlayer.FromEntity(ent)
        if not player:IsAlive() then goto continue end

        local positon = player:GetAbsOrigin()
        local viewAngles = player:GetEyeAngles()
        local flags = player:GetPropInt("m_fFlags")
        local health = player:GetHealth()

        record[idx] = { positon, viewAngles, flags, health }

        ::continue::
    end

    replayData:pushBack(record)

    if replayData:size() > options.Ticks then
        replayData:popFront()
    end
end

-- Replays the recorded ticks
---@param me Entity
local function DoReplay(me)
    -- Apply the current tick record
    currentRecord = replayData:popFront()

    -- Force the observer mode to the target
    local target = entities.GetByUserID(currentTarget)
    if not target then return end

    me:SetPropInt(options.ObserverMode, "m_iObserverMode") -- Set observer mode to first person
    me:SetPropEntity(target, "m_hObserverTarget") -- Set observer target to null
    me:SetPropInt(target:GetTeamNumber(), "m_iTeamNum")

    local wTarget = WPlayer.FromEntity(target)
    engine.SetViewAngles(wTarget:GetEyeAngles())
end

---@param userCmd UserCmd
local function OnCreateMove(userCmd)
    local me = entities.GetLocalPlayer()
    if not me then return end

    isReplaying = not me:IsAlive() and not replayData:empty()
    isRecording = me:IsAlive()

    if isRecording then
        DoRecord(me)
    elseif isReplaying then
        DoReplay(me)
    end
end

local function OnPostPropUpdate()
    if not isReplaying then return end

    local players = entities.FindByClass("CTFPlayer")

    local record = currentRecord
    if not record then return end

    for idx, ent in pairs(players) do
        local playerRecord = record[idx]
        if not playerRecord then goto continue end

        --print("Forcing for " .. idx)
        ent:SetPropVector(playerRecord[1], "tfnonlocaldata", "m_vecOrigin")
        ent:SetAbsOrigin(playerRecord[1])
        --ent:SetPropVector(playerRecord[2], "tfnonlocaldata", "m_angEyeAngles[0]")
        ent:SetPropInt(playerRecord[3], "m_fFlags")
        ent:SetPropInt(playerRecord[4], "m_iHealth")

        ::continue::
    end
end

---@param event GameEvent
local function OnGameEvent(event)
    if event:GetName() == "player_death" then
        local attacker = event:GetInt("attacker")
        local target = event:GetInt("userid")

        local me = entities.GetLocalPlayer()
        if not me then return end
        local playerInfo = client.GetPlayerInfo(me:GetIndex())
        if not playerInfo then return end

        if attacker ~= playerInfo.UserID and target == playerInfo.UserID then
            currentTarget = attacker
        end
    end
end

local function OnDraw()
    draw.SetFont(Fonts.Verdana)
    draw.Color(255, 255, 255, 255)

    draw.Text(20, 150, string.format("Replay size: %d", replayData:size()))

    if isReplaying then
        draw.Text(20, 170, "Viewing replay...")
    end
end

callbacks.Unregister("CreateMove", "LNX.DeathCam.CreateMove")
callbacks.Register("CreateMove", "LNX.DeathCam.CreateMove", OnCreateMove)

callbacks.Unregister("PostPropUpdate", "LNX.DeathCam.PostPropUpdate")
callbacks.Register("PostPropUpdate", "LNX.DeathCam.PostPropUpdate", OnPostPropUpdate)

callbacks.Unregister("FireGameEvent", "LNX.DeathCam.FireGameEvent")
callbacks.Register("FireGameEvent", "LNX.DeathCam.FireGameEvent", OnGameEvent)

callbacks.Unregister("Draw", "LNX.DeathCam.Draw")
callbacks.Register("Draw", "LNX.DeathCam.Draw", OnDraw)