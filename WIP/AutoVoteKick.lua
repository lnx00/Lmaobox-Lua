--[[
    Auto Votekick
    Author: lnx00 (github.com/lnx00)
]]

---@type boolean, LNXlib
local libLoaded, Lib = pcall(require, "LNXlib")
assert(libLoaded, "LNXlib not found, please install it!")
assert(Lib.GetVersion() >= 0.90, "LNXlib version is too old, please update it!")

local Timer, WPlayer, WPR = Lib.Utils.Timer, Lib.TF2.WPlayer, Lib.TF2.WPlayerResource

local voteTimer = Timer.new()

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

callbacks.Unregister("CreateMove", "LNX_AV_CreateMove")
callbacks.Register("CreateMove", "LNX_AV_CreateMove", OnCreateMove)