--[[
    Chat Censor for Lmaobox
    Author: LNX (github.com/lnx00)
]]

ClearChat = true

local options = {
    PrintToChat = true,
    PrintToConsole = false
}

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
    if not ClearChat then return end

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
        string.find(message, "hax") or string.find(message, "exploit") then
            local victimName = GetRandomPlayerName() or "Server"

            client.ChatTeamSay(GetClearMessage(victimName))
            if options.PrintToChat then
                client.ChatPrintf("\x06[\x07FF1122CC\x06] \x05" .. playerName .. " \x01wrote \x05" .. message)
            end
            if options.PrintToConsole then
                print("[ChatCensor] " .. playerName .. " wrote " .. message)
            end
        end
    end
end

callbacks.Unregister( "DispatchUserMessage", "ChatCensor_DispatchUserMessage" );
callbacks.Register("DispatchUserMessage", "ChatCensor_DispatchUserMessage", DispatchUserMessage)
