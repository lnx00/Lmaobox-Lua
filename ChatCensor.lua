--[[
    Chat Censor for Lmaobox
    Author: LNX (github.com/lnx00)
]]

ClearChat = true

local options = {
    PrintToChat = true
}

local lastMessage = nil

local randMsg = {
    "?", "what", "No",
    "true", "IKR", "wtf",
    "lol", "Lmao", "omg",
    "Why", "Bot", "..."
}

local function GetRandomMessage()
    return randMsg[math.random(#randMsg)]
end

local function GetClearMessage(pVictim)
    local chatMessage = GetRandomMessage() .. "\n" .. pVictim .. ":\n\n" ..
    "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n" ..
    "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n" ..
    "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n" ..
    "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n" ..
    "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n" ..
    "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"

    return chatMessage
end

local function GetRandomPlayerName()
    local players = entities.FindByClass("CTFPlayer")
    local randomPlayer = players[math.random(1, #players)]
    local rpInfo = client.GetPlayerInfo(randomPlayer:GetIndex())
    local me = entities.GetLocalPlayer()
    if me:GetIndex() ~= randomPlayer:GetIndex() and not steam.IsFriend(rpInfo.SteamID) then
        return randomPlayer:GetName()
    end
    return nil
end

local function DispatchUserMessage( msg )
    if not ClearChat then return end

    if msg:GetID() == SayText2 then
        msg:SetCurBit(1)
        local entIdx = msg:ReadByte()
        msg:SetCurBit(8)
        local me = entities.GetLocalPlayer()

        local chatEnt = entities.GetByIndex(entIdx)
        local chatType = msg:ReadString(256)
        local playerName = msg:ReadString(256)
        local message = msg:ReadString(256)

        -- Don't clear our or friends messages
        local spInfo = client.GetPlayerInfo(chatEnt:GetIndex())
        if chatEnt:GetIndex() == me:GetIndex() or steam.IsFriend(spInfo.SteamID) then
            return
        end

        -- Print the last message
        if lastMessage and not lastMessage == "" then
            if options.PrintToChat then
                client.ChatPrintf(lastMessage)
                lastMessage = nil
            end
        end

        -- Clean the message
        local origMessage = message
        message = message:lower()
        message = message:gsub("!", "i")
        message = message:gsub("|", "i")
        message = message:gsub("%s+", "")
        message = message:gsub("4", "a")
        message = message:gsub("0", "o")
        message = message:gsub("1", "i")
        message = message:gsub("3", "e")
        message = message:gsub("[^%w ]", "")

        if string.find(message, "cheat") or string.find(message, "hack") or 
        string.find(message, "bot") or string.find(message, "aim") or
        string.find(message, "esp") or string.find(message, "kick") or
        string.find(message, "hax") or string.find(message, "exploit") then
            local victimName = GetRandomPlayerName() or "Server"

            client.ChatTeamSay(GetClearMessage(victimName))
            lastMessage = "\x06[\x07FF1122CC\x06] \x05" .. playerName .. " \x01wrote \x05" .. origMessage
        end
    end
end

callbacks.Unregister("DispatchUserMessage", "ChatCensor_DispatchUserMessage");
callbacks.Register("DispatchUserMessage", "ChatCensor_DispatchUserMessage", DispatchUserMessage)

client.Command('play "ui/buttonclick"', true)