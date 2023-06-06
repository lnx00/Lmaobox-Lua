local values = {
    ["currentmap"] = "Lmaobox",
    ["connect"] = nil,
    ["steam_player_group"] = nil,
    ["steam_player_group_size"] = "123",
    ["state"] = "PlayingMatchGroup",
    ["matchgrouploc"] = "BootCamp",
    ["steam_display"] = "#TF_RichPresence_Display",
    ["status"] = nil
}

---@param key RichPresenceKey
---@param value string
---@return string?
local function OnSetRichPresence(key, value)
    return values[key]
end

callbacks.Register("SetRichPresence", OnSetRichPresence)