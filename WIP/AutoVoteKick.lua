--[[
    Auto Votekick for Lmaobox
    Author: lnx00 (github.com/lnx00)
]]

---@type boolean, lnxLib
local libLoaded, lnxLib = pcall(require, "lnxLib")
assert(libLoaded, "lnxLib not found, please install it!")
assert(lnxLib.GetVersion() >= 0.90, "lnxLib version is too old, please update it!")

local Timer, WPlayer, WPR = lnxLib.Utils.Timer, lnxLib.TF2.WPlayer, lnxLib.TF2.WPlayerResource

local options = {
    RandomVotes = false,    -- Kicks random player
    AutoRetry = true,       -- Retries if the vote fails
    AutoVote = false,       -- Kicks risky players
    MinBetrayals = 3,       -- Minimum betrayals to kick
    BetrayalPoints = 2,     -- Point increase for betraying
    LoyalPoints = 1,        -- Point reduction for not betraying
}

local voteTimer = Timer.new()
local kickList = {} ---@type table<SteamID, integer>
local currentVote = {} ---@type { caller : integer, target : integer, votes : table<integer, boolean> }

local function PrintLine(msg)
    client.ChatPrintf("[AutoVote] " .. msg)
end

local function IsFriend(idx)
    if idx == client.GetLocalPlayerIndex() then return true end

    local playerInfo = client.GetPlayerInfo(idx)
    if steam.IsFriend(playerInfo.SteamID) then return true end
    if playerlist.GetPriority(playerInfo.UserID) < 0 then return true end

    return false
end

-- Starts a votekick according to the options
local function StartVote()
    if not gamerules.IsMatchTypeCasual() then return end
    -- TODO: This
end

-- Processes the vote results
local function ProcessVote()
    local myIndex = client.GetLocalPlayerIndex()
    local myVote = currentVote.votes[myIndex]
    if myVote == nil then
        if IsFriend(currentVote.caller) then
            myVote = true
        elseif IsFriend(currentVote.target) then
            myVote = false
        else
            PrintLine("Vote will not be processed.")
            return
        end
    end

    -- Find all betrayals
    for entIdx, vote in pairs(currentVote) do
        if IsFriend(entIdx) then goto continue end
        local playerInfo = client.GetPlayerInfo(entIdx)
        local steamID = playerInfo.SteamID

        if vote == myVote then
            -- Not a betrayal
            local score = kickList[steamID] or 0
            kickList[steamID] = score + options.BetrayalPoints
        else
            -- Betrayal
            local score = kickList[steamID] or 0
            kickList[steamID] = score - options.LoyalPoints
        end

        ::continue::
    end
end

local function OnCreateMove(userCmd)
    if not voteTimer:Run(5) then return end
    if not gamerules.IsMatchTypeCasual() then return end

    local me = WPlayer.GetLocal()
    local pr = WPR.Get()
    if not me:IsValid() or not pr:IsValid() then return end

    local entities = entities.FindByClass("CTFPlayer")
    local partyMembers = party.GetMembers()

    for i, entity in ipairs(entities) do
        local player = WPlayer.FromEntity(entity)

        -- Check if the target is a teammate
        if me:GetTeamNumber() == player:GetTeamNumber() then goto continue end
        if i == me:GetIndex() then goto continue end

        local userID = pr:GetUserID(i)
        local steamID = tostring(pr:GetAccountID(i))

        -- Check if the target is a friend
        if playerlist.GetPriority(userID) < 0 then goto continue end
        if steam.IsFriend(steamID) then goto continue end

        -- Check if the target is a party member
        if partyMembers ~= nil then
            for _, member in ipairs(partyMembers) do
                if string.match(member, steamID) then goto continue end
            end
        end

        print(string.format("[AutoVote] Kicking target %s (%d)", player:GetName(), userID))
        client.Command(string.format("callvote kick %d", userID), true)
        ::continue::
    end
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
        currentVote = {}
        DelayedCall(10, StartVote) -- TODO: This can cause issues if the map changes during a vote
    end
end

---@param msg UserMessage
local function OnDispatchUserMessage(msg)
    if msg:GetID() == CallVoteFailed then
        -- We can't call a vote yet
        local reason = msg:ReadByte()
        local cooldown = msg:ReadInt(16)

        -- Retry in a few seconds
        DelayedCall(cooldown + 1, StartVote)
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
    elseif msg:GetID() == VotePass then
        -- A vote has passed
        local team = msg:ReadByte()
        local voteIdx = msg:ReadInt(32)
        local disp_str = msg:ReadString(256)
        local details_str = msg:ReadString(256)

        -- Process the vote
        ProcessVote()
        DelayedCall(5, StartVote)
    elseif msg:GetID() == VoteFailed then
        -- A vote has failed
        local team = msg:ReadByte()
        local voteIdx = msg:ReadInt(32)
        local reason = msg:ReadByte()

        -- Process the vote
        ProcessVote()
        DelayedCall(5, StartVote)
    end
end

callbacks.Register("CreateMove", OnCreateMove)
callbacks.Register("FireGameEvent", OnGameEvent)
callbacks.Register("DispatchUserMessage", OnDispatchUserMessage)