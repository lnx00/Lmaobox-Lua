--[[
    Auto Queue for Lmaobox
    Author: LNX (github.com/lnx00)
]]

AutoQueue = true
local lastTime = 0

local function Draw_AutoQueue()
    if not AutoQueue or gamecoordinator.HasLiveMatch() or gamecoordinator.IsConnectedToMatchServer() or gamecoordinator.GetNumMatchInvites() > 0 then
        return
    end

    if globals.RealTime() - lastTime < 4 then
        return
    end

    lastTime = globals.RealTime()
    if #party.GetQueuedMatchGroups() == 0 and not party.IsInStandbyQueue() then
        party.QueueUp(7)
    end
end

-- Can't use CreateMove, because it's not called in main menu
callbacks.Unregister("Draw", "Draw_AutoQueue")
callbacks.Register("Draw", "Draw_AutoQueue", Draw_AutoQueue)

engine.Notification("AutoQueue info", "You have just executed the AutoQueue script.\nIf you want to stop it, simply type this into the console:\nlua AutoQueue = false\n\nYou can re-enable AutoQueue again by running the script again or by typing:\nlua AutoQueue = true")
