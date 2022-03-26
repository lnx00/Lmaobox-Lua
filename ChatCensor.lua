--[[
    Chat Censor for Lmaobox
    Author: LNX (github.com/lnx00)
]]

local options = {
    PrintToChat = true,
    PrintToConsole = false
}

local voteTarget = -1

local function GetClearMessage(pVictim)
    local chatMessage = "?\n" .. pVictim .. ":\n\n" ..
    "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n" ..
    "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n" ..
    "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n" ..
    "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n" ..
    "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n" ..
    "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"

    return chatMessage
end

local function GetRandomPlayerName()
    local players = entities.FindByClass("CTFPlayer")
    local randomPlayer = players[math.random(1, #players)]
    local me = entities.GetLocalPlayer()
    if me:GetIndex() ~= randomPlayer:GetIndex() then
        return randomPlayer:GetName()
    end
    return nil
end

local function DispatchUserMessage( msg )
    if msg:GetID() == SayText2 then
        msg:SetCurBit(8)
        local me = entities.GetLocalPlayer()

        local chatType = msg:ReadString(256)
        local playerName = msg:ReadString(256)
        local message = msg:ReadString(256)

        -- clean the message
        message = message:lower()
        message = message:gsub("%s+", "")
        message = message:gsub("4", "a")
        message = message:gsub("0", "o")
        message = message:gsub("1", "i")
        message = message:gsub("3", "e")
        message = message:gsub("[^%w ]", "")

        if string.find(message, "cheat") or string.find(message, "hack") or 
        string.find(message, "bot") or string.find(message, "aim") or
        string.find(message, "esp") or string.find(message, "kick") or
        string.find(message, "hax") or (voteTarget == me:GetIndex() and string.find(message, "f1")) then
            local victimName = GetRandomPlayerName() or "Server"

            client.ChatTeamSay(GetClearMessage(victimName))
            if options.PrintToChat then
                client.ChatPrintf("\x06[\x07FF1122CC\x06] \x05" .. playerName .. " \x01wrote \x05" .. message)
            end
            if options.PrintToConsole then
                print("[ChatCensor] " .. playerName .. " wrote " .. message)
            end
        end
    elseif msg:GetID() == VoteStart then
        local team = msg:ReadByte()
        local caller = msg:ReadByte()
        local reason = msg:ReadString(64)
        local voteTarget = msg:ReadString(64)
        local target = msg:ReadByte() >> 1
        voteTarget = target
    elseif msg:GetID() == VotePass or msg:GetID() == VoteFailed then
        voteTarget = -1
    end
end

callbacks.Unregister( "DispatchUserMessage", "ChatCensor_DispatchUserMessage" );
callbacks.Register("DispatchUserMessage", "ChatCensor_DispatchUserMessage", DispatchUserMessage)
