--[[
    Auto Votekick for Lmaobox
    Author: lnx00 (github.com/lnx00)
]]

---@type boolean, lnxLib
local libLoaded, lnxLib = pcall(require, "lnxLib")
assert(libLoaded, "lnxLib not found, please install it!")
assert(lnxLib.GetVersion() >= 0.994, "lnxLib version is too old, please update it!")

local TF2 = lnxLib.TF2
local WPlayer, WPR = TF2.WPlayer, TF2.WPlayerResource

local options = {
    Reason = "cheating",    -- Reason for the votekick
    RandomVotes = false,    -- Kicks random player
    AutoRetry = true,       -- Retries if the vote fails
    AutoVote = false,       -- Kicks risky players
    MinBetrayals = 5,       -- Minimum betrayals to kick
    BetrayalPoints = 2,     -- Point increase for betraying
    LoyalPoints = 1,        -- Point reduction for not betraying
    CritMult = 3,           -- Critical vote multiplier
}

local kickList = {} ---@type table<SteamID, integer>
local currentVote = {} ---@type { caller : integer, target : integer, votes : table<integer, boolean> }
local nextVote = 0

local function PrintLine(msg)
    client.ChatPrintf("\x04[AutoVote] \x01" .. msg)
end

local function CallVote(userId)
    client.Command(string.format("callvote kick %d %s", userId, options.Reason), true)
end

local function UpdateScore(idx, score)
    local playerInfo = client.GetPlayerInfo(idx)
    local steamID = playerInfo.SteamID
    local oldScore = kickList[steamID] or 0
    kickList[steamID] = oldScore + score
end

-- Starts a votekick according to the options
local function StartVote()
    local me = WPlayer.GetLocal()
    local pr = WPR.Get()
    if not me or not pr then return end

    local myTeam = me:GetTeamNumber()
    local teams = pr:GetTeam()
    for i = 1, globals.MaxClients() do
        if teams[i + 1] ~= myTeam then goto continue end
        local playerInfo = client.GetPlayerInfo(i)

        -- Kick betrayers
        if options.AutoVote then
            if kickList[playerInfo.SteamID] >= options.MinBetrayals then
                CallVote(playerInfo.UserID)
                return
            end
        end

        -- Kick random players
        if options.RandomVotes then
            CallVote(playerInfo.UserID)
            return
        end

        ::continue::
    end
end

-- Processes the vote results
local function ProcessVote()
    local myIndex = client.GetLocalPlayerIndex()
    local callerFriend = TF2.IsFriend(currentVote.caller)
    local targetFriend = TF2.IsFriend(currentVote.target)

    -- Friend voted against friend
    if callerFriend and targetFriend then
        PrintLine("Friend voted against friend, vote will not be processed.")
        return
    end

    -- Enemy voted against enemy
    if not callerFriend and not targetFriend then
        PrintLine("Enemy voted against enemy, vote will not be processed.")
        return
    end

    -- Friend voted against enemy
    if callerFriend and not targetFriend then
        UpdateScore(currentVote.target, options.BetrayalPoints)
    end

    -- Enemy voted against friend
    if not callerFriend and targetFriend then
        UpdateScore(currentVote.caller, options.BetrayalPoints * options.CritMult)
    end

    local myVote = callerFriend or currentVote.votes[myIndex]

    -- Find all betrayals
    for idx, vote in pairs(currentVote) do
        if TF2.IsFriend(idx) then goto continue end

        if vote == myVote then
            -- Not a betrayal
            UpdateScore(idx, options.LoyalPoints)
        else
            -- Betrayal
            UpdateScore(idx, options.BetrayalPoints)
        end

        ::continue::
    end
end

---@param userCmd UserCmd
local function OnCreateMove(userCmd)
    if globals.CurTime() < nextVote then return end
    nextVote = globals.CurTime() + 5

    -- Are we even able to call a vote?
    if not gamerules.IsMatchTypeCasual() then return end
    if clientstate.GetClientSignonState() ~= SIGNONSTATE_FULL then return end
    if clientstate.GetConnectTime() < 30 then return end

    StartVote()
end

---@param event GameEvent
local function OnGameEvent(event)
    if event:GetName() == "vote_cast" then
        -- A vote has been cast
        local option = event:GetInt("vote_option")
        local team = event:GetInt("team")
        local entIdx = event:GetInt("entityid")
        local voteIdx = event:GetInt("voteidx")

        currentVote.votes[entIdx] = (option == 0)
    elseif event:GetName() == "game_newmap" then
        -- New map, reset everything
        currentVote = {}
        nextVote = 0
    end
end

---@param msg UserMessage
local function OnDispatchUserMessage(msg)
    if msg:GetID() == CallVoteFailed then
        -- We can't call a vote yet
        local reason = msg:ReadByte()
        local cooldown = msg:ReadInt(16) or 0

        -- Retry in a few seconds
        nextVote = globals.CurTime() + cooldown + 1
        PrintLine(string.format("Cannot call a vote yet! Retrying in %d seconds...", cooldown))
    elseif msg:GetID() == VoteStart then
        -- A vote has started
        local team = msg:ReadByte()
        local voteIdx = msg:ReadInt(32)
        local entIdx = msg:ReadByte()
        local disp_str = msg:ReadString(64)
        local details_str = msg:ReadString(64)
        local targetIdx = msg:ReadByte() >> 1

        currentVote = {
            caller = entIdx,
            target = targetIdx,
            votes = {}
        }
    elseif msg:GetID() == VotePass or msg:GetID() == VoteFailed then
        -- Process the vote
        ProcessVote()
        nextVote = globals.CurTime() + 5
    end
end

callbacks.Register("CreateMove", OnCreateMove)
callbacks.Register("FireGameEvent", OnGameEvent)
callbacks.Register("DispatchUserMessage", OnDispatchUserMessage)