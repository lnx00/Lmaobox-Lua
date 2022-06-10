--[[
    Misc Tools for Lmaobox
    Author: LNX (github.com/lnx00)
]]

local menuLoaded, MenuLib = pcall(require, "Menu")
assert(menuLoaded, "MenuLib not found, please install it!")
assert(MenuLib.Version >= 1.44, "MenuLib version is too old, please update it!")



--[[ Menu Sub-categories ]]--
local ObserverMode = {
    None = 0,
    Deathcam = 1,
    FreezeCam = 2,
    Fixed = 3,
    FirstPerson = 4,
    ThirdPerson = 5,
    PointOfInterest = 6,
    FreeRoaming = 7
    }
local Removals = {
    ["RTD Effects"] = false,
    ["HUD Texts"] = false
    }
local Callouts = {
    ["Battle Cry Melee"] = false,   -- C2
    -- ["Medic!"] = false,             -- Call for medic when low on health (or spam it if there is no medic?)
    -- ["Yes"] = false,                -- Say "Yes" if someone nearby says No (lmao)
    -- ["No"] = false,                 -- Say "No" at certain responses ("You are a spy", etc)
    -- ["Spy"] = false,                -- Callout Spies
    -- ["Teleporter Here"] = false,    -- If we respawn, but there's no teleporters nearby, request a teleporter
    -- ["Activate Charge"] = false,    -- If the medic ubering us has full charge, replace our "Medic!" callout with this
    -- ["Help!"] = false,              -- If there's no medic on our team, call for help at low health
    -- ["Positive"] = false,           -- When we do anything to get points (assists, sap buildings, etc)
    -- ["Negative"] = false,           -- idk bad things? enemy caps points, our medic dies, etc
    -- ["Nice Shot"] = false,          -- If a sniper nearby gets a headshot, callout that
    -- ["Good Job"] = false,           -- If a someone nearby gets a kill, callout that
}

--[[Varibles used for looping]]
local LastExtenFreeze = 0
local prTimer = 0
local flTimer = 0
local ttTimer = 0
local c2Timer = 0
local c2Timer2 = 0


--[[ Menu ]]
local menu = MenuLib.Create("Misc Tools", MenuFlags.AutoSize)
menu.Style.TitleBg = { 205, 95, 50, 255 }
menu.Style.Outline = true


local mCallouts = menu:AddComponent(MenuLib.MultiCombo("Auto Voicemenu WIP", Callouts, ItemFlags.FullWidth))
local mLegJitter = menu:AddComponent(MenuLib.Checkbox("Leg Jitter", false))
local mFastStop = menu:AddComponent(MenuLib.Checkbox("FastStop (Debug!)", false))
local mJazzHands = menu:AddComponent(MenuLib.Checkbox("Jazz Hands", false))
menu:AddComponent(MenuLib.Button("Disable Weapon Sway", function()
    client.SetConVar("cl_wpn_sway_interp", 0)
    client.SetConVar("cl_jiggle_bone_framerate_cutoff", 0)
    client.SetConVar("cl_bobcycle", 10000)
end, ItemFlags.FullWidth))
local mRetryStunned = menu:AddComponent(MenuLib.Checkbox("Retry When Stunned", false))
local mRetryLowHP = menu:AddComponent(MenuLib.Checkbox("Retry When Low HP", false))
local mRetryLowHPValue = menu:AddComponent(MenuLib.Slider("Retry HP", 1, 299, 30))
local mLegitSpec = menu:AddComponent(MenuLib.Checkbox("Legit when Spectated", false))
local mLegitSpecFP = menu:AddComponent(MenuLib.Checkbox("^Firstperson Only", false))
local mAutoMelee = menu:AddComponent(MenuLib.Checkbox("Auto Melee Switch", false))
local mMeleeDist = menu:AddComponent(MenuLib.Slider("Melee Switch Distance", 100, 700, 200))
local mAutoFL = menu:AddComponent(MenuLib.Checkbox("Auto Fake Latency", false))
local mAutoFLDist = menu:AddComponent(MenuLib.Slider("Auto Latency Distance", 100, 700, 350))
local mRandPing = menu:AddComponent(MenuLib.Checkbox("Random Ping", false))
local mRandPingValue = menu:AddComponent(MenuLib.Slider("Ping Randomness", 1, 15, 8))
local mRandLag = menu:AddComponent(MenuLib.Checkbox("Random Fakelag", false))
local mRandLagValue = menu:AddComponent(MenuLib.Slider("Fakelag Randomness", 1, 200, 21))
local mRandLagMin = menu:AddComponent(MenuLib.Slider("Fakelag Min", 1, 314, 120))
local mRandLagMax = menu:AddComponent(MenuLib.Slider("Fakelag Max", 2, 315, 315))
local mChatNL = menu:AddComponent(MenuLib.Checkbox("Allow \\n in chat", false))
local mExtendFreeze = menu:AddComponent(MenuLib.Checkbox("Infinite Respawn Timer", false))
--local mRageSpecKill = menu:AddComponent(MenuLib.Checkbox("Rage Spectator Killbind", false)) -- fuck you "pizza pasta", stop spectating me
local mRemovals = menu:AddComponent(MenuLib.MultiCombo("Removals", Removals, ItemFlags.FullWidth))

--[[ Options management ]]
local TempOptions = {}

local function ResetTempOptions()
    for k, v in pairs(TempOptions) do
        TempOptions[k].WasUsed = false
    end
end

local function SetOptionTemp(option, value)
    local guiValue = gui.GetValue(option)
    if guiValue ~= value then
        gui.SetValue(option, value)
        TempOptions[option] = { Value = guiValue, WasUsed = true }
    end

    if TempOptions[option] ~= nil then
        TempOptions[option].WasUsed = true
    end
end

local function CheckTempOptions()
    for k, v in pairs(TempOptions) do
        if not v.WasUsed then
            gui.SetValue(k, v.Value)
            TempOptions[k] = nil
        end
    end
end

local function OnCreateMove(pCmd)
    ResetTempOptions()
    local pLocal = entities.GetLocalPlayer()
    if not pLocal then return end

    local vVelocity = pLocal:EstimateAbsVelocity()
    local cmdButtons = pCmd:GetButtons()

    -- Leg Jitter
    if mLegJitter:GetValue() == true then
        if (pCmd.forwardmove == 0) and (pCmd.sidemove == 0) and (vVelocity:Length2D() < 10) then
            if pCmd.command_number % 2 == 0 then
                pCmd:SetSideMove(9)
            else
                pCmd:SetSideMove(-9)
            end
        end
    end

    -- Fast Stop
    if mFastStop:GetValue() == true then
        if (pLocal:IsAlive()) and (pCmd.forwardmove == 0) and (pCmd.sidemove == 0) and (vVelocity:Length2D() > 10) then
            local fsx, fsy, fsz = vVelocity:Unpack()
            print(fsx, fsy, fsz)
            if (fsz < 0.01) then -- vertical velocity doesn't seem to change when walking on/off a teleporter or on ramps/slopes.
                --     pCmd:SetForwardMove(fsx) -- Need to figure out how to turn absolute velocity into relative velocity. I'm not sure how to do it.
                --     pCmd:SetSideMove(fsy)
                print("Fast Stop would run right now.. if it worked. X: " .. math.floor(fsx) .. " Y: " .. math.floor(fsy) .. " Z: " .. math.floor(fsz))
            end
        end
    end


    -- Jazz Hands (lmao)
    if mJazzHands:GetValue() == true then
        if pCmd.command_number % 2 == 0 then
            client.SetConVar("cl_flipviewmodels", 1 )
        else
            client.SetConVar("cl_flipviewmodels", 0)
        end
    end

    -- Retry when low hp
    if mRetryLowHP:GetValue() == true then
        if (pLocal:IsAlive()) and (pLocal:GetHealth() > 0 and (pLocal:GetHealth()) <= mRetryLowHPValue:GetValue()) then
            client.Command("retry", true)
        end
    end

    -- Infinite Respawn
    if mExtendFreeze:GetValue() == true then
        if (pLocal:IsAlive() == false) and (globals.RealTime() > (LastExtenFreeze + 2)) then
            client.Command("extendfreeze", true)
            LastExtenFreeze = globals.RealTime()
        end
    end

    -- Random Fakelag
    if mRandLag:GetValue() == true then
        flTimer = flTimer +1
        if (flTimer >= mRandLagValue:GetValue()) then
            flTimer = 0
            local randValue = math.random(mRandLagMin:GetValue(), mRandLagMax:GetValue())
            gui.SetValue("fake lag value", randValue)
        end
    end

    -- Random Ping
    if mRandPing:GetValue() == true then
        prTimer = prTimer +1
        if (prTimer >= mRandPingValue:GetValue() * 66) then
            prTimer = 0
            local prActive = gui.GetValue("ping reducer")
            if (prActive == 0) then
                gui.SetValue("ping reducer", 1)
            elseif (prActive == 1) then
                gui.SetValue("ping reducer", 0) 
            end
        end
    end

    -- Anti RTD
    if mRemovals:IsSelected("RTD Effects") then
        if CurrentRTD == "Cursed" then
            pCmd:SetForwardMove(pCmd:GetForwardMove() * (-1))
            pCmd:SetSideMove(pCmd:GetSideMove() * (-1))
        elseif CurrentRTD == "Drugged" or CurrentRTD == "Bad Sauce" then
            --SetOptionTemp("norecoil", 1) --can get you banned in community servers 🤔
        end
    end


    --[[ Features that require access to the weapon ]]
    local pWeapon = pLocal:GetPropEntity("m_hActiveWeapon")
    if not pWeapon then return end


    -- [[ Features that need to iterate through all players ]]
    local players = entities.FindByClass("CTFPlayer")
    for k, vPlayer in pairs(players) do
        if vPlayer:IsValid() == false then goto continue end
    local vWeapon = vPlayer:GetPropEntity("m_hActiveWeapon")
    local vWeaponitemDefinitionIndex = vWeapon:GetPropInt( "m_iItemDefinitionIndex" )
    local vWeaponitemDefinition = itemschema.GetItemDefinitionByID( vWeaponitemDefinitionIndex )
    local vWeaponName = vWeaponitemDefinition:GetName()

        -- Smooth on spectate
        if mLegitSpec:GetValue() == true then
            local obsMode = pLocal:GetPropInt("m_iObserverMode")
            local obsTarget = pLocal:GetPropEntity("m_hObserverTarget")
            if obsMode and obsTarget then
                if (obsMode == ObserverMode.ThirdPerson) and (mLegitSpecFP:GetValue() == true) then -- Untested
                    return
                elseif (obsTarget:GetIndex() == pLocal:GetIndex()) then
                    SetOptionTemp("aim method", "assistance")
                    SetOptionTemp("auto backstab", "legit")
                    SetOptionTemp("auto sapper", "legit")
                    SetOptionTemp("melee aimbot", "legit")
                    SetOptionTemp("auto detonate sticky", "legit")
                    SetOptionTemp("auto airblast", "legit")
                    SetOptionTemp("sniper: shoot through teammates", "off") -- no clue if this works
                    SetOptionTemp("fake latency", "off")
                    SetOptionTemp("fake lag", "off")
                    SetOptionTemp("ping reducer", "off") -- this stuff probably doesn't work with smart/auto fake latency / randomize ping
                end
            end
        end

        -- -- Spectator Killbind (Rage)
        -- if mRageSpecKill:GetValue() == true then
        --     local obsRTarget = pLocal:GetPropEntity("m_hObserverTarget")
        --     if obsRMode and obsRTarget then
        --         if (obsRTarget:GetIndex() == pLocal:GetIndex()) then
        --             if (obsRTarget:GetIndex() == -- if target has priority >= 1
        --                 client.command("explode", true) -- kill ourselves. explode so they can't see our cosmetics, because fuck whoever this guy is.
        --         end
        --     end
        -- end

        if vPlayer:IsAlive() == false then goto continue end
        if vPlayer:GetIndex() == pLocal:GetIndex() then goto continue end

        local distVector = vPlayer:GetAbsOrigin() - pLocal:GetAbsOrigin()
        local distance = distVector:Length()

        if vPlayer:GetTeamNumber() == pLocal:GetTeamNumber() then goto continue end
        if pLocal:IsAlive() == false and (mAutoFL:GetValue() == true) then gui.SetValue("fake latency", 0) end
        if pLocal:IsAlive() == false then goto continue end

        -- Retry when stunned
        if (mRetryStunned:GetValue() == true) and (pLocal:IsAlive()) then
            if (pLocal:InCond(15)) then
                client.command("retry", true) -- hopefully this doesn't spam console too fast
            elseif (pLocal:InCond(7)) and (distance <= 200) and (vWeaponName:GetValue() == TF_WEAPON_FISTS) then -- probably works?
                 client.command("retry", true)
            end
        end

        local sneakyboy = false
        if pLocal:InCond(4) or pLocal:InCond(3) or pLocal:InCond(2) or pLocal:InCond(13) or pLocal:InCond(9) then
            sneakyboy = true
        end

        -- Auto Melee Switch
        if (mAutoMelee:GetValue() == true) and (distance <= mMeleeDist:GetValue()) and (pWeapon:IsMeleeWeapon() == false) and (sneakyboy == false) then
            print(distance)
            client.Command("slot3", true) -- We don't have access to pCmd.weaponselect :(
        end
        
        -- Auto Fake Latency
        if (mAutoFL:GetValue() == true) and (pLocal:IsAlive() == true) and (distance <= mAutoFLDist:GetValue()) and (pWeapon:IsMeleeWeapon() == true) and (sneakyboy == false) then
            gui.SetValue("fake latency", 1)
            return
        elseif (mAutoFL:GetValue() == true) then
            gui.SetValue("fake latency", 0)
        end

        -- Auto C2
        if mCallouts:IsSelected("Battle Cry Melee") and (pLocal:IsAlive()) and (pWeapon:IsMeleeWeapon() == true) and (sneakyboy == false) then
            c2Timer = c2Timer + 1 -- trace every 0.5 seconds
            c2Timer2 = c2Timer2 + 1 -- attempt C2 every 2 seconds
            if (c2Timer >= 0.5 * 66) then
                c2Timer = 0
                local mC2Source = pLocal:GetAbsOrigin() + pLocal:GetPropVector( "localdata", "m_vecViewOffset[0]" )
                local mC2Destination = mC2Source + engine.GetViewAngles():Forward() * 500;
                local mC2Trace = engine.TraceLine(mC2Source, mC2Destination, MASK_SHOT_HULL)
                if (mC2Trace.entity ~= nil) and (mC2Trace.entity:GetClass() == "CTFPlayer") and (mC2Trace.entity:GetTeamNumber() ~= pLocal:GetTeamNumber()) and ((c2Timer2 >= 2 * 66)) then
                    c2Timer2 = 0
                    client.Command("voicemenu 2 1", true)
                    print("Successfully triggered C2")
                end
            end
        end
        ::continue::
    end
    CheckTempOptions()
end

local function OnStringCmd(stringCmd)
    local cmd = stringCmd:Get()
    local blockCmd = false

    -- Allow \n in chat (This method is scuffed, but it works)
    if mChatNL:GetValue() == true then
        cmd = cmd:gsub("\\n", "\n")
        if cmd:find("say_team", 1, true) == 1 then
            cmd = cmd:sub(11, -2)
            client.ChatTeamSay(cmd)
            blockCmd = true
        elseif cmd:find("say", 1, true) == 1 then
            cmd = cmd:sub(6, -2)
            client.ChatSay(cmd)
            blockCmd = true
        end
    end

    if blockCmd then
        stringCmd:Set("")
    end
end

local function OnUserMessage(userMsg)
    local blockMessage = false

    if mRemovals:IsSelected("RTD Effects") then
        if userMsg:GetID() == Shake then blockMessage = true end
        if userMsg:GetID() == Fade then blockMessage = true end

        if userMsg:GetID() == TextMsg then
            userMsg:Reset()
            local msgDest = userMsg:ReadByte()
            local msgName = userMsg:ReadString(256)

            if string.find(msgName, "[RTD]") then
                if string.find(msgName, "Your perk has worn off") or string.find(msgName, "You have died during your roll") then
                    CurrentRTD = ""
                elseif string.find(msgName, "Cursed") then CurrentRTD = "Cursed"
                elseif string.find(msgName, "Drugged") then CurrentRTD = "Drugged"
                elseif string.find(msgName, "Bad Sauce") then CurrentRTD = "Bad Sauce"
                end
            end
        end
    else
        CurrentRTD = ""
    end

    if mRemovals:IsSelected("HUD Texts") then
        if userMsg:GetID() == HudText or userMsg:GetID() == HudMsg then blockMessage = true end
    end

    if blockMessage then
        local msgLength = userMsg:GetDataBits()
        userMsg:Reset()
        for i = 1, msgLength do
            userMsg:WriteBit(0)
        end
    end
end

local function OnUnload()
    MenuLib.RemoveMenu(menu)

    client.Command('play "ui/buttonclickrelease"', true)
end

callbacks.Unregister("CreateMove", "MCT_CreateMove")
callbacks.Unregister("SendStringCmd", "MCT_StringCmd")
callbacks.Unregister("DispatchUserMessage", "MCT_UserMessage")
callbacks.Unregister("Unload", "MCT_Unload")

callbacks.Register("CreateMove", "MCT_CreateMove", OnCreateMove)
callbacks.Register("SendStringCmd", "MCT_StringCmd", OnStringCmd)
callbacks.Register("DispatchUserMessage", "MCT_UserMessage", OnUserMessage)
callbacks.Register("Unload", "MCT_Unload", OnUnload)

client.Command('play "ui/buttonclick"', true)
