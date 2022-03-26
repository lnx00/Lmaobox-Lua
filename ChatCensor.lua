--[[
    Chat Censor for Lmaobox
    Author: LNX (github.com/lnx00)
]]

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

local function DispatchUserMessage( msg )
    if msg:GetID() == SayText2 then
        msg:SetCurBit(8)

        local chatType = msg:ReadString(256)
        local playerName = msg:ReadString(256)
        local message = msg:ReadString(256)

        if string.find(message, "cheat") or string.find(message, "hack") or 
        string.find(message, "bot") or string.find(message, "aim") or
        string.find(message, "esp") or string.find(message, "kick") or
        string.find(message, "hax") then
            local players = entities.FindByClass("CTFPlayer")
            -- get random element from players
            local victimName = players[math.random(1, #players)]:GetName() or "Server"

            client.ChatTeamSay(GetClearMessage(victimName))
            if options.PrintToChat then
                client.ChatPrintf("\x06[\x07FF1122CC\x06] \x05" .. playerName .. " \x01wrote \x05This is a message!")
            end
            if options.PrintToConsole then
                print("[ChatCensor] " .. playerName .. " wrote " .. message)
            end
        end
    end
end

callbacks.Unregister( "DispatchUserMessage", "ChatCensor_DispatchUserMessage" );
callbacks.Register("DispatchUserMessage", "ChatCensor_DispatchUserMessage", DispatchUserMessage)
