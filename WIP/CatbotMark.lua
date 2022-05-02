local function FireGameEvent(event)
    if(event:GetName( ) ~= "achievement_earned") then
        return
    end

    local player = entities.GetByIndex(event:GetInt("entityid"));
    local achievement  = event:GetInt("achievement");
    if (achievement == 0xCA7 or achievement == 0xCA8) then
        local playerInfo = client.GetPlayerInfo(player)
        print("[CatbotMark] The player '" .. playerInfo.Name .. "' is a bot!")
        local kv = [[
            "AchievementEarned"
            {
                "$achievementID" "0xCA8"
            }
        ]]
        if engine.SendKeyValues(kv) then
            print("[CatbotMark] Marked us as a catbot")
        else
            print("[CatbotMark] Failed to mark as catbot")
        end
    end
end

client.AllowListener("achievement_earned");

callbacks.Unregister("FireGameEvent", "CatbotMark_FireGameEvent");
callbacks.Register("FireGameEvent", "CatbotMark_FireGameEvent", FireGameEvent);