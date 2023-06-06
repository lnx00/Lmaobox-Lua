---@type lnxLib
local lnxLib = require("lnxLib")

local posDeque = Deque.new()
local canPlay = true
local maxSize = 120

local myEntity = entities.CreateEntityByName("player")
assert(myEntity, "Failed to create entity")

local function Init()
    local me = entities.GetLocalPlayer()
    assert(me, "Failed to get local player")

    --myEntity:SetAbsOrigin(me:GetAbsOrigin())
    myEntity:SetModel("models/player/heavy.mdl")
    myEntity:SetPropEntity(me, "m_hAutoAimTarget")
end

---@param userCmd UserCmd
local function OnCreateMove(userCmd)
    local me = entities.GetLocalPlayer()
    if not me or not me:IsAlive() then
        canPlay = true
        return
    end

    if posDeque:size() > maxSize then
        local curPos = posDeque:popFront()
        myEntity:SetAbsOrigin(curPos)

        while not posDeque:empty() and posDeque:peekFront() == curPos do
            posDeque:popFront()
            maxSize = maxSize - 1
        end

        local dist = (myEntity:GetAbsOrigin() - me:GetAbsOrigin()):Length()
        if dist < 15 and canPlay then
            canPlay = false
            maxSize = 120
            engine.PlaySound("vo/sandwicheat09.mp3")
            client.Command("explode", true)
        end
    end

    posDeque:pushBack(me:GetAbsOrigin())
end

local function OnUnload()
    myEntity:Release()
end

Init()

callbacks.Register("CreateMove", OnCreateMove)
callbacks.Register("Unload", OnUnload)