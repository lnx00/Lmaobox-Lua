local chatMessage = "?\nServer:\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n" ..
"\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n" ..
"\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n" ..
"\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n" ..
"\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n" ..
"\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n" ..
"\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"

local function DispatchUserMessage( msg )
    if msg:GetID() == SayText2 then
        msg:SetCurBit(8)

        local chatType = msg:ReadString(256)
        local playerName = msg:ReadString(256)
        local message = msg:ReadString(256)

        if string.find(message, "cheat") or
         string.find(message, "hack") or
          string.find(message, "bot") or
          string.find(message, "aim") or
          string.find(message, "esp") or
          string.find(message, "kick") or
          string.find(message, "hax") then
            client.ChatTeamSay(chatMessage)
            print("[ChatCensor] " .. playerName .. " wrote " .. message)
        end
    end
end

callbacks.Unregister( "DispatchUserMessage", "ChatCensor_DispatchUserMessage" );
callbacks.Register("DispatchUserMessage", "ChatCensor_DispatchUserMessage", DispatchUserMessage)