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
local currentTarget = 0 ---@type integer
local currentRecord = nil ---@type table<Vector3, Vector3, integer, integer, integer>[]?
local localPlayer = nil ---@type Entity
local isPlaying = false

-- Starts the replay
---@param targetId integer
local function StartReplay(targetId)
    currentTarget = targetId
    isPlaying = true
end

-- Stops the replay
local function StopReplay()
    isPlaying = false
    currentRecord = nil
    currentTarget = 0
    replayData:clear()
end

-- Records the current tick for all enemies
---@param me Entity
local function DoRecord(me)
    local players = entities.FindByClass("CTFPlayer")
    local record = {}

    -- Record all players
    for idx, ent in pairs(players) do
        local positon = ent:GetAbsOrigin()
        local viewAngles = ent:GetPropVector("tfnonlocaldata", "m_angEyeAngles[0]")
        local flags = ent:GetPropInt("m_fFlags")
        local health = ent:GetHealth()
        local lifeState = ent:GetPropInt("m_lifeState")

        record[idx] = { positon, viewAngles, flags, health, lifeState }

        ::continue::
    end

    replayData:pushBack(record)

    -- Pop the oldest tick record
    if replayData:size() > options.Ticks then
        replayData:popFront()
    end
end

-- Replays the recorded ticks
---@param me Entity
local function DoReplay(me)
    if not isPlaying then return end

    -- Stop the replay if the data is empty
    if replayData:empty() then
        StopReplay()
        return
    end

    -- Pop the current tick record
    currentRecord = replayData:popFront()
end

---@param userCmd UserCmd
local function OnCreateMove(userCmd)
    local me = entities.GetLocalPlayer()
    if me then
        localPlayer = me
    else
        return
    end

    -- Stop the replay if we're alive
    if me:IsAlive() and isPlaying then
        StopReplay()
    end

    if isPlaying then
        DoReplay(me)
    else
        DoRecord(me)
    end
end

-- Sets the player's position and angles
local function OnPostPropUpdate()
    if not isPlaying then return end

    local me = localPlayer
    if not me or not me:IsValid() then return end

    local players = entities.FindByClass("CTFPlayer")

    --[[ Apply the current tick record ]]

    local record = currentRecord
    if not record then return end

    for idx, ent in pairs(players) do
        local playerRecord = record[idx]
        if not playerRecord then goto continue end

        ent:SetPropVector(playerRecord[1], "tfnonlocaldata", "m_vecOrigin")
        ent:SetAbsOrigin(playerRecord[1])
        ent:SetPropVector(playerRecord[2], "tfnonlocaldata", "m_angEyeAngles[0]")
        ent:SetPropInt(playerRecord[3], "m_fFlags")
        ent:SetPropInt(playerRecord[4], "m_iHealth")
        ent:SetPropInt(playerRecord[5], "m_lifeState")

        ::continue::
    end

    --[[ Apply observer mode ]]

    -- Retrive the current target
    local target = entities.GetByUserID(currentTarget)
    if not target then return end

    -- Set the observer mode and target
    me:SetPropInt(options.ObserverMode, "m_iObserverMode") -- Set observer mode to first person
    me:SetPropEntity(target, "m_hObserverTarget") -- Set observer target
    me:SetPropInt(target:GetTeamNumber(), "m_iTeamNum")

    local wTarget = WPlayer.FromEntity(target)
    engine.SetViewAngles(wTarget:GetEyeAngles())
end

-- Starts the replay when we die
---@param event GameEvent
local function OnGameEvent(event)
    if event:GetName() == "player_death" then
        local attacker = event:GetInt("attacker")
        local target = event:GetInt("userid")

        local me = entities.GetLocalPlayer()
        if not me then return end
        local playerInfo = client.GetPlayerInfo(me:GetIndex())
        if not playerInfo then return end

        -- Check if we're the target
        if attacker ~= playerInfo.UserID and target == playerInfo.UserID then
            -- Start the replay after 2 seconds
            DelayedCall(2, function ()
                StartReplay(attacker)
            end)
        end
    end
end

local function OnDraw()
    draw.SetFont(Fonts.Verdana)
    draw.Color(255, 255, 255, 255)

    draw.Text(20, 150, string.format("Replay size: %d", replayData:size()))

    if isPlaying then
        draw.SetFont(Fonts.SegoeTitle)
        local w, h = draw.GetScreenSize()
        draw.Text(w // 2, h // 4, "Viewing Replay")
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