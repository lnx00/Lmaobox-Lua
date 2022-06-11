--[[                                ]]--
--[[     Misc Tools for Lmaobox     ]]--
--[[                                ]]--
--[[          --Authors--           ]]--
--[[     LNX (github.com/lnx00)     ]]--
--[[         SylveonBottle          ]]--
--[[                                ]]--

local menuLoaded, MenuLib = pcall(require, "Menu")                                -- Load MenuLib
assert(menuLoaded, "MenuLib not found, please install it!")                       -- If not found, throw error
assert(MenuLib.Version >= 1.44, "MenuLib version is too old, please update it!")  -- If version is too old, throw error



--[[ Menu Sub-categories ]]--
local   ObserverMode    = {  -- Observer Mode
        None            = 0, -- No observer mode
        Deathcam        = 1, -- Deathcam
        FreezeCam       = 2, -- FreezeCam (Frozen)
        Fixed           = 3, -- Fixed Camera (fixed position)
        FirstPerson     = 4, -- First Person (Watching your screen)
        ThirdPerson     = 5, -- Third Person (Default)
        PointOfInterest = 6, -- Point of Interest Camera
        FreeRoaming     = 7  -- Free Roaming Camera
    }
local Removals = {           -- May be removed in the future
    ["RTD Effects"] = false, -- Button to remove RTD effects
    ["HUD Texts"] = false    -- Button to remove HUD Texts
    }
local Callouts = {                   -- Callouts are not yet fully implemented
    ["Battle Cry Melee"] = false,    -- C2 when using melee and looking at enemy
    -- ["Medic!"] = false,           -- Call for medic when low on health (or spam it if there is no medic?)
    -- ["Yes"] = false,              -- Say "Yes" if someone nearby says No (lmao)
    -- ["No"] = false,               -- Say "No" at certain responses ("You are a spy", etc)
    -- ["Spy"] = false,              -- Callout Spies
    -- ["Teleporter Here"] = false,  -- If we respawn, but there's no teleporters nearby, request a teleporter
    -- ["Activate Charge"] = false,  -- If the medic ubering us has full charge, replace our "Medic!" callout with this
    -- ["Help!"] = false,            -- If there's no medic on our team, call for help at low health when there's a teammate nearby
    -- ["Positive"] = false,         -- When we do anything to get points (assists, sap buildings, etc)
    -- ["Negative"] = false,         -- idk bad things? enemy caps points, our medic dies, etc
    -- ["Nice Shot"] = false,        -- If a sniper nearby gets a headshot
    -- ["Good Job"] = false,         -- If a someone nearby gets a kill
}

--[[ Varibles used for looping ]]--
local LastExtenFreeze = 0  -- Spectator Mode
local prTimer = 0          -- Timer for Random Ping
local flTimer = 0          -- Timer for Fake Latency
local c2Timer = 0          -- Timer for Battle Cry Melee raytracing
local c2Timer2 = 0         -- Timer for ^ to prevent spamming


--[[ Menu ]]--
local menu = MenuLib.Create("Misc Tools", MenuFlags.AutoSize)
menu.Style.TitleBg = { 205, 95, 50, 255 } -- Title Background Color (Flame Pea)
menu.Style.Outline = true                 -- Outline around the menu


local mCallouts         = menu:AddComponent(MenuLib.MultiCombo("Auto Voicemenu WIP",   Callouts, ItemFlags.FullWidth))  -- Callouts
local mLegJitter        = menu:AddComponent(MenuLib.Checkbox("Leg Jitter",             false))                          -- Leg Jitter
local mFastStop         = menu:AddComponent(MenuLib.Checkbox("FastStop (Debug!)",      false))                          -- FastStop (Doesn't work yet)
local mWFlip            = menu:AddComponent(MenuLib.Checkbox("Auto Weapon Flip",       false))                          -- Auto Weapon Flip (Doesn't work yet)
    menu:AddComponent(MenuLib.Button("Disable Weapon Sway", function() -- Disable Weapon Sway (Executes commands)
    client.SetConVar("cl_wpn_sway_interp",              0)             -- Set cl_wpn_sway_interp to 0
    client.SetConVar("cl_jiggle_bone_framerate_cutoff", 0)             -- Set cl_jiggle_bone_framerate_cutoff to 0
    client.SetConVar("cl_bobcycle",                     10000)         -- Set cl_bobcycle to 10000
end, ItemFlags.FullWidth))
local mRetryStunned     = menu:AddComponent(MenuLib.Checkbox("Retry When Stunned",     false))                          -- Retry When Stunned
local mRetryLowHP       = menu:AddComponent(MenuLib.Checkbox("Retry When Low HP",      false))                          -- Retry When Low HP
local mRetryLowHPValue  = menu:AddComponent(MenuLib.Slider("Retry HP",                 1, 299, 30))                     -- Retry When Low HP Value
local mLegitSpec        = menu:AddComponent(MenuLib.Checkbox("Legit when Spectated",   false))                          -- Legit when Spectated
local mLegitSpecFP      = menu:AddComponent(MenuLib.Checkbox("^Firstperson Only",      false))                          -- Legit when Spectated (Firstperson Only Toggle)
local mAutoMelee        = menu:AddComponent(MenuLib.Checkbox("Auto Melee Switch",      false))                          -- Auto Melee Switch
local mMeleeDist        = menu:AddComponent(MenuLib.Slider("Melee Switch Distance",    100, 700, 200))                  -- Auto Melee Switch Distance
local mAutoFL           = menu:AddComponent(MenuLib.Checkbox("Auto Fake Latency",      false))                          -- Auto Fake Latency
local mAutoFLDist       = menu:AddComponent(MenuLib.Slider("Auto Latency Distance",    100, 700, 350))                  -- Auto Fake Latency Distance
local mRandPing         = menu:AddComponent(MenuLib.Checkbox("Random Ping",            false))                          -- Random Ping
local mRandPingValue    = menu:AddComponent(MenuLib.Slider("Ping Randomness",          1, 15, 8))                       -- Random Ping Value
local mRandLag          = menu:AddComponent(MenuLib.Checkbox("Random Fakelag",         false))                          -- Random Fakelag
local mRandLagValue     = menu:AddComponent(MenuLib.Slider("Fakelag Randomness",       1, 200, 21))                     -- Random Fakelag Value
local mRandLagMin       = menu:AddComponent(MenuLib.Slider("Fakelag Min",              1, 314, 120))                    -- Random Fakelag Minimum Value
local mRandLagMax       = menu:AddComponent(MenuLib.Slider("Fakelag Max",              2, 315, 315))                    -- Random Fakelag Maximum Value
local mChatNL           = menu:AddComponent(MenuLib.Checkbox("Allow \\n in chat",      false))                          -- Allow \\n in chat
local mExtendFreeze     = menu:AddComponent(MenuLib.Checkbox("Infinite Respawn Timer", false))                          -- Infinite Respawn Timer
-- local mRageSpecKill     = menu:AddComponent(MenuLib.Checkbox("Rage Spectator Killbind", false))                         -- fuck you "pizza pasta", stop spectating me
local mRemovals         = menu:AddComponent(MenuLib.MultiCombo("Removals",             Removals, ItemFlags.FullWidth))  -- Remove RTD and HUD Texts

--[[ Options management ]]--
local TempOptions = {}                                             -- Temp options

local function ResetTempOptions()                                  -- Reset "TempOptions"
    for k, v in pairs(TempOptions) do                              -- Loop through all options in "TempOptions"
        TempOptions[k].WasUsed = false                             -- Set "WasUsed" to false for each option (so we can check if it was used)
    end
end

local function SetOptionTemp(option, value)                        -- Runs "SetOptionTemp" with the given cheat and setting
    local guiValue = gui.GetValue(option)                          -- Set "guiValue" to the current setting of the given cheat
    if guiValue ~= value then                                      -- Check if "guiValue" is different from the "SetOptionTemp"'s setting
        gui.SetValue(option, value)                                -- Set the cheat to the given setting
        TempOptions[option] = {                                    -- Create a new entry in "TempOptions" for the given cheat
            Value   = guiValue,                                    -- Set the entry's value to the current setting of the cheat
            WasUsed = true    }                                    -- Set the entry's "WasUsed" to true
    end

    if TempOptions[option] ~= nil then                             -- For each option in "TempOptions" (as long as one exists),
        TempOptions[option].WasUsed = true                         -- Set the entry's "WasUsed" to true
    end
end

local function CheckTempOptions()                                  -- When CheckTempOptions is called,
    for k, v in pairs(TempOptions) do                              -- Loop through all options in "TempOptions"
        if not v.WasUsed then                                      -- Check if the entry's "WasUsed" is false.
            gui.SetValue(k, v.Value)                               -- Set the cheat to the entry's value (the value it was set to before) and
            TempOptions[k] = nil                                   -- Remove the entry from "TempOptions" (so it doesn't get checked again)
        end
    end
end


--[[ Code needed to run 66 times a second ]]--
local function OnCreateMove(pCmd)                    -- Everything within this function will run 66 times a second
    ResetTempOptions()                               -- Immediately reset "TempOptions"
    local pLocal = entities.GetLocalPlayer()         -- Immediately set "pLocal" to the local player (entities.GetLocalPlayer)
    if not pLocal then return end                    -- Immediately check if the local player exists. If it doesn't, return.
    local vVelocity  = pLocal:EstimateAbsVelocity()  -- Immediately set "vVelocity" to the local player's absolute velocity (this is used for any code that needs to know the local player's velocity)
    local cmdButtons = pCmd:GetButtons()             -- Immediately set "cmdButtons" to the local player's buttons (this is used for any code that needs to know what buttons we are pressing)




    --[[ Leg Jitter ]]-- (Messes with certain idle animations. See scout with mad milk / spycrab for a good example)
    if mLegJitter:GetValue() == true then                                -- If Leg Jitter is enabled,
        if (pCmd.forwardmove == 0) and (pCmd.sidemove == 0)              -- Check if we are pressing WASD
                                   and (vVelocity:Length2D() < 10) then  -- Check if we not currently moving 
            if pCmd.command_number % 2 == 0 then                         -- Check if the command number is even. (Potentially inconsistent, but it works).
                pCmd:SetSideMove(9)                                      -- Cycle between moving left and right
            else
                pCmd:SetSideMove(-9)
            end
        end
    end

    --[[ Fast Stop ]]-- (Tries to immediately stop the player's momentum when letting go of WASD)
    if mFastStop:GetValue() == true then                                     -- If Fast Stop is enabled
        if (pLocal:IsAlive()) and (pCmd.forwardmove == 0)                    -- Check if we are alive and not moving
                              and (pCmd.sidemove == 0)
                              and (vVelocity:Length2D() > 10) then           -- Check if our velocity is greater than 10hu
            local fsx, fsy, fsz = vVelocity:Unpack()                         -- Set "fsx", "fsy" and "fsz" to the local player's absolute x, y and z velocity
            print(fsx, fsy, fsz)                                             -- Print the local player's x, y and z velocity (for debugging)
            if (fsz < 0.01) then                                             -- Check if the local player's z velocity is less than 0.01 (if they are not jumping or falling).
                pCmd:SetForwardMove(fsx)                                     -- Set the forwardmove to the local player's absolute x velocity (needs to be translated to the local player's view)
                pCmd:SetSideMove(fsy)                                       -- Set the sidemove to the local player's absolute y velocity (needs to be translated to the local player's view)
                print("Success! X:" .. fsx .. " Y:" .. fsy .. " Z:" .. fsz)  -- Print the local player's absolute x, y and z velocity (for debugging)
            end
        end
    end

    --[[ Retry when low hp ]]-- (Rconnects when your hp is below "mRetryHP" (set in the menu) in order to prevent being killed))
    if mRetryLowHP:GetValue() == true then                                                     -- If Retry when low hp is enabled
        if (pLocal:IsAlive()) and (pLocal:GetHealth() > 0                                      -- Check if we are alive and have health
                              and (pLocal:GetHealth()) <= mRetryLowHPValue:GetValue()) then    -- Check if our health is less than "mRetryLowHPValue" (set in the menu)
            client.Command("retry", true)                                                      -- Reconnect to the server
        end
    end

    --[[ Infinite Respawn Timer ]]-- (Increases the respawn timer for yourself, allowing you to infinitely be stuck respawning)
    if mExtendFreeze:GetValue() == true then                                                 -- If Infinite Respawn Timer is enabled
        if (pLocal:IsAlive() == false) and (globals.RealTime() > (LastExtenFreeze + 2)) then -- Check if the player is dead and if it has been more than 2 seconds since the last extendfreeze executed.
            client.Command("extendfreeze", true)                                             -- Extend the respawn timer
            LastExtenFreeze = globals.RealTime()                                             -- Set LastExtenFreeze to the current time
        end
    end

    --[[ Random Fakelag ]]-- (Randomizes FakeLag's value. This can break some cheat's projectile aimbot)
    if mRandLag:GetValue() == true then                                                                    -- If Random Fakelag is enabled
        flTimer = flTimer +1                                                                               -- Increment the fakelag timer
        if (flTimer >= mRandLagValue:GetValue()) then                                                      -- Check if the fakelag timer is greater than "mRandLagValue" (set in the menu)
            flTimer = 0                                                                                    -- Reset the fakelag timer
            local randValue = math.random(mRandLagMin:GetValue(), mRandLagMax:GetValue())                  -- Set "randValue" to a random number between "mRandLagMin" and "mRandLagMax" (set in the menu)
            gui.SetValue("fake lag value", randValue)                                                      -- Set the fakelag value to "randValue"
            -- gui.SetValue("fake lag value", math.random(mRandLagMin:GetValue(), mRandLagMax:GetValue())) -- Untested, but should work.
        end
    end

    --[[ Random Ping ]]-- (Randomly enables Ping Reducer, preventing you from having a steady ping of 341 ping that never increases/descreases (suspicious))
    if mRandPing:GetValue() == true then                     -- If Random Ping is enabled
        prTimer = prTimer +1                                 -- Increment the ping timer
        if (prTimer >= mRandPingValue:GetValue() * 66) then  -- Check if the ping timer is greater than "mRandPingValue" (set in the menu).
            prTimer = 0                                      -- Reset the ping timer
            local prActive = gui.GetValue("ping reducer")    -- Set "prActive" to the current value of ping reducer
            -- if (gui.GetValue("ping reducer") == 0) then   -- Untested. This might work better.
            if (prActive == 0) then                          -- Check if ping reducer is currently disabled
                gui.SetValue("ping reducer", 1)              -- If it is disabled, enable it
            elseif (prActive == 1) then                      -- Check if ping reducer is currently enabled
                gui.SetValue("ping reducer", 0)              -- If it is enabled, disable it
            end
        end
    end

    --[[ Anti RTD ]]-- (Stops certain RTD effects. May be removed in the future)
    if mRemovals:IsSelected("RTD Effects") then                           -- If RTD Effects is selected
        if CurrentRTD == "Cursed" then                                    -- If the current RTD effect is "Cursed"
            pCmd:SetForwardMove(pCmd:GetForwardMove() * (-1))             -- Reverse the local player's W and S movement
            pCmd:SetSideMove(pCmd:GetSideMove() * (-1))                   -- Reverse the local player's A and D movement
        elseif CurrentRTD == "Drugged" or CurrentRTD == "Bad Sauce" then  -- If the current RTD effect is "Drugged" or "Bad Sauce"
            --SetOptionTemp("norecoil", 1)                                -- Activate NoRecoil (bannable in community servers)
        end
    end


    --[[ Features that require access to the weapon ]]--
    local pWeapon         = pLocal:GetPropEntity( "m_hActiveWeapon" )            -- Set "pWeapon" to the local player's active weapon
    local pWeaponDefIndex = pWeapon:GetPropInt( "m_iItemDefinitionIndex" )       -- Set "pWeaponDefIndex" to the "pWeapon"'s item definition index
    local pWeaponDef      = itemschema.GetItemDefinitionByID( pWeaponDefIndex )  -- Set "pWeaponDef" to the local "pWeapon"'s item definition
    local pWeaponName     = pWeaponDef:GetName()                                 -- Set "pWeaponName" to the local "pWeapon"'s actual name
    if not pWeapon then return end                                               -- If "pWeapon" is not set, break



    -- It turns out that LMAOBOX is not compatible with the client convar "cl_flipviewmodels". The client convar works in other cheats (such as Fedoraware) but not in LMAOBOX.
    -- The view models DO flip, however it's only visual. The rocket still fires out of the right side of the player..
    -- In Fedoraware, the rocket fires out of the left side of the player when the cl_viewmodels is set to 1.
    -- So this does not work in LMAOBOX.
    -- However, I am leaving this code here in case someone wants to see how it would have worked.
    -- I also don't want to ask for lbox to fix this in the telegram, because the last time I did that I got banned for 2 months.
    --[[ Auto weapon flip ]]-- (Automatically flips your rocket launcher to the left if it would travel farther)
    if (mWFlip:GetValue() == true) then                                                                             -- If Auto weapon flip is enabled
        if (pWeaponDefIndex == 730) or (pWeaponDefIndex == 141) or (pWeaponDefIndex == 18) 
                                    or (pWeaponDefIndex == 441) or (pWeaponDefIndex == 414) 
                                    or (pWeaponDefIndex == 228) or (pWeaponDefIndex == 1104) 
                                    or (pWeaponDefIndex == 127) or (pWeaponDefIndex == 308) 
                                    or (pWeaponDefIndex == 19)  or (pWeaponDefIndex == 996) then                    -- We could probably check "(pWeapon == TFRocketLauncher) or (pWeapon == TFGrenadeLauncher)" but I'm not sure if that would work
            local source      = pLocal:GetAbsOrigin() + pLocal:GetPropVector( "localdata", "m_vecViewOffset[0]" );  -- Set "source" to the local player's view offset
            local destination = source + engine.GetViewAngles():Forward() * 1000;                                   -- Find where the player is aiming
            local trace       = engine.TraceLine (source, destination, MASK_SHOT_HULL);                             -- Trace a line from the player's view offset to where they are aiming (for debugging)
            local sourceRight = source + engine.GetViewAngles():Right() * 10;                                       -- Right of the player
            local traceRight  = engine.TraceLine (sourceRight, destination, MASK_SHOT_HULL);                        -- Trace a line from the right of the player to where they are aiming
            local sourceLeft  = source + engine.GetViewAngles():Right() * -10;                                      -- Left of the player
            local traceLeft   = engine.TraceLine (sourceLeft, destination, MASK_SHOT_HULL);                         -- Trace a line from the left of the player to where they are aiming
            if (math.floor(traceLeft.fraction * 1000)) > (math.floor(traceRight.fraction * 1000)) then              -- If the left trace is closer than the right trace
                client.SetConVar("cl_flipviewmodels", 1 )                                                           -- Set the client convar to flip the viewmodels
            elseif (math.floor(traceLeft.fraction * 1000)) < (math.floor(traceRight.fraction * 1000)) then          -- If the right trace is closer than the left trace
                client.SetConVar("cl_flipviewmodels", 0 )                                                           -- Revert the client convar to not flip the viewmodels
            end
        end
    end



    --[[ Features that need to iterate through all players ]]
    local players = entities.FindByClass("CTFPlayer")                              -- Create a table of all players in the game
    for k, vPlayer in pairs(players) do                                            -- For each player in the game
        if vPlayer:IsValid() == false then goto continue end                       -- Check if each player is valid
    local vWeapon = vPlayer:GetPropEntity("m_hActiveWeapon")                       -- Set "vWeapon" to the player's active weapon
    if vWeapon ~= nil then                                                         -- If "vWeapon" is not nil
        local vWeaponDefIndex = vWeapon:GetPropInt("m_iItemDefinitionIndex")       -- Set "vWeaponDefIndex" to the "vWeapon"'s item definition index
        local vWeaponDef      = itemschema.GetItemDefinitionByID(vWeaponDefIndex)  -- Set "vWeaponDef" to the local "vWeapon"'s item definition
        local vWeaponName     = vWeaponDef:GetName()                               -- Set "vWeaponName" to the local "vWeapon"'s actual name
    end

        --[[ Legit on spectated players ]]-- (To prevent spectating players from seeing us acting suspiciously)
        if mLegitSpec:GetValue() == true then                                                        -- If Smooth on spectated players is enabled
            local obsMode   = pLocal:GetPropInt("m_iObserverMode")                                   -- Set "obsMode" to the player's observer mode 
            local obsTarget = pLocal:GetPropEntity("m_hObserverTarget")                              -- Set "obsTarget" to the player's observer target
            if obsMode and obsTarget then                                                            -- If "obsMode" and "obsTarget" are set
                if (obsMode == ObserverMode.ThirdPerson) and (mLegitSpecFP:GetValue() == true) then  -- If the player is spectating in third person and Firstperson Only Toggle is enabled
                    return                                                                           -- Stop the code from running
                elseif (obsTarget:GetIndex() == pLocal:GetIndex()) then                              -- If the observer's spectate target is the local player
                    SetOptionTemp("aim method", "assistance")
                    SetOptionTemp("auto backstab", "legit")
                    SetOptionTemp("auto sapper", "legit")
                    SetOptionTemp("melee aimbot", "legit")
                    SetOptionTemp("auto detonate sticky", "legit")
                    SetOptionTemp("auto airblast", "legit")
                    SetOptionTemp("sniper: shoot through teammates", "off")                          -- Might not work
                    SetOptionTemp("fake latency", "off")
                    SetOptionTemp("fake lag", "off")
                    SetOptionTemp("ping reducer", "off")                                             -- Might not work with "Smart Fake Latency"
                end
            end
        end

        --[[ Spectator Killbind (Rage) ]]-- (I hate it when a random spy on my team decides to alway spectate me when I'm dead. I just to play the damn game, stop being suspicious of me.)
        -- if mRageSpecKill:GetValue() == true then                           -- If Spectator Killbind is enabled
        --     local obsRTarget = pLocal:GetPropEntity("m_hObserverTarget")   -- Set "obsRTarget" to the player's observer target
        --     if obsRMode and obsRTarget then                                -- If "obsRMode" and "obsRTarget" are set
        --         if (obsRTarget:GetIndex() == ??????                        -- if target has priority >= 1. gui.getpriority() doesn't exist yet :(
        --                 client.command("explode", true)                    -- kill ourselves. explode so they can't see our cosmetics, because fuck whoever this guy is.
        --         end
        --     end
        -- end

        if vPlayer:IsAlive() == false then goto continue end
        if vPlayer:GetIndex() == pLocal:GetIndex() then goto continue end            --Code below this line doesn't work if you're the only player in the game.

        local distVector = vPlayer:GetAbsOrigin() - pLocal:GetAbsOrigin()            -- Set "distVector" to the distance between us and the player we are iterating through
        local distance   = distVector:Length()                                       -- Set "distance" to the length of "distVector"

        if vPlayer:GetTeamNumber() == pLocal:GetTeamNumber() then goto continue end  -- If we are on the same team as the player we are iterating through, skip the rest of this code
        if pLocal:IsAlive() == false then goto continue end                          -- If we are not alive, skip the rest of this code

        --[[ Retry when stunned ]]-- (To prevent us from getting tauntkilled)
        if (mRetryStunned:GetValue() == true) then                                   -- If Retry when stunned is enabled
            if (pLocal:InCond(15)) then                                              -- If we are stunned (15 is TF_COND_STUNNED)
                client.command("retry", true)                                        -- Reconnect to the server
            elseif (pLocal:InCond(7)) and (distance <= 200)                          -- If we are laughing (7 is TF_COND_TAUNTING), and we're within 200hu of the player we are iterating through
                                      and (vWeaponName == "The Holiday Punch") then  -- and the enemy is using The Holiday Punch (untested)
                client.command("retry", true)                                        -- Reconnect to the server
            end
        end

        local sneakyboy = false                       -- Create a new variable for if we're invisible or not, set it to false
        if pLocal:InCond(4) or pLocal:InCond(3) 
                            or pLocal:InCond(2) 
                            or pLocal:InCond(13) 
                            or pLocal:InCond(9) then  -- If we are in a condition that makes us invisible
            sneakyboy = true                          -- Set "sneakyboy" to true
        end

        --[[ Auto Melee Switch ]]-- (Automatically switches to slot3 when an enemy is in range)
        if (mAutoMelee:GetValue() == true) and (distance <= mMeleeDist:GetValue())  -- If Auto Melee is enabled, and we are within the melee distance
                                           and (pWeapon:IsMeleeWeapon() == false)   -- and we are not using a melee weapon
                                           and (sneakyboy == false) then            -- and we are not invisible
            --print(distance)                                                       -- Print the distance to the console (for debugging)
            client.Command("slot3", true)                                           -- Execute the "slot3" command (We don't have access to pCmd.weaponselect :( )
        end

        --[[ Auto Fake Latency ]]-- (Automatically enables fake latency depending on certain conditions)
        if (mAutoFL:GetValue() == true) and (distance <= mAutoFLDist:GetValue())  -- If Auto Fake Latency is enabled, and we are within "mAutoFLDist" (set in the menu) of the enemy
                                        and (pWeapon:IsMeleeWeapon() == true)     -- and we are using a melee weapon
                                        and (sneakyboy == false) then             -- and we are not invisible
            gui.SetValue("fake latency", 1)                                       -- Set the fake latency to 1
            return -- Does this break AutoC2?
        elseif (mAutoFL:GetValue() == true) then                                  -- Otherwise, if Auto Fake Latency is enabled but no other conditions are met
            gui.SetValue("fake latency", 0)                                       -- Set the fake latency to 0
        end

        --[[ Auto C2 ]]-- (Automatically use "Battle Cry" when looking at an enemy with melee weapon (for special voicelines))
        if mCallouts:IsSelected("Battle Cry Melee") and (pWeapon:IsMeleeWeapon() == true)                                 -- If we are using the Battle Cry Melee callout, and we are using a melee weapon
                                                    and (sneakyboy == false) then                                         -- and we are not invisible
            c2Timer = c2Timer + 1                                                                                         -- Add 1 to the c2Timer
            c2Timer2 = c2Timer2 + 1                                                                                       -- Add 1 to the c2Timer2
            if (c2Timer >= 0.5 * 66) then                                                                                 -- If the c2Timer is greater than or equal to 0.5 seconds
                c2Timer = 0                                                                                               -- Reset the c2Timer
                local mC2Source      = pLocal:GetAbsOrigin() + pLocal:GetPropVector( "localdata", "m_vecViewOffset[0]" )  -- Set "mC2Source" to the player's view offset
                local mC2Destination = mC2Source + engine.GetViewAngles():Forward() * 500;                                -- Set "mC2Destination" 500hu in front of the player's view angle
                local mC2Trace       = engine.TraceLine(mC2Source, mC2Destination, MASK_SHOT_HULL)                        -- Trace a line from "mC2Source" to "mC2Destination"
                if (mC2Trace.entity ~= nil) and (mC2Trace.entity:GetClass() == "CTFPlayer")                               -- If the trace hit a player
                                            and (mC2Trace.entity:GetTeamNumber() ~= pLocal:GetTeamNumber())               -- and the player is on a different team
                                            and ((c2Timer2 >= 2 * 66)) then                                               -- and the c2Timer2 is greater than to 2 seconds
                    client.Command("voicemenu 2 1", true)                                                                 -- Execute "voicemenu 2 1" in the console
                    --print("Successfully triggered C2")                                                                  -- Print to the console that we successfully triggered C2 (for debugging)
                end
            end
        end
        ::continue::
    end
    CheckTempOptions()
end

--[[ Executes upon stringCmd ]]--
local function OnStringCmd(stringCmd)  -- Called when a string command is sent
    local cmd = stringCmd:Get()        -- Set "cmd" to the string command
    local blockCmd = false             -- Set "blockCmd" to false

    --[[ Allow \n in chat ]]-- (This method is scuffed, but it works.)
    if mChatNL:GetValue() == true then              -- If Chat New Line is enabled
        cmd = cmd:gsub("\\n", "\n")                 -- Replace all instances of "\\n" with "\n"
        if cmd:find("say_team", 1, true) == 1 then  -- If the command is "say_team"
            cmd = cmd:sub(11, -2)                   -- Remove the first 11 characters ("say_team ") and the last 2 characters (");")
            client.ChatTeamSay(cmd)                 -- Send the modified command to the server
            blockCmd = true                         -- Execute the "blockCmd" function
        elseif cmd:find("say", 1, true) == 1 then   -- If the command is "say"
            cmd = cmd:sub(6, -2)                    -- Remove the first 6 characters ("say ") and the last 2 characters (");")
            client.ChatSay(cmd)                     -- Send the modified command to the server
            blockCmd = true                         -- Execute the "blockCmd" function
        end
    end

    --[[ Block Commands ]]-- 
    if blockCmd then       -- If "blockCmd" is triggered
        stringCmd:Set("")  -- Set the string command to "", disabling the command
    end
end

--[[ Executes upon receiving a message ]]--
local function OnUserMessage(userMsg)  -- Called when a user message is received
    local blockMessage = false         -- Set "blockMessage" to false (used to keep track of whether or not to block the message)

    --[[ Removals: RTD Effects ]]-- (Attempt to negate bad RTD effects)
    if mRemovals:IsSelected("RTD Effects") then                                                                                    -- If RTD Effects is enabled
        if userMsg:GetID() == Shake then blockMessage = true end                                                                   -- If the message is "Shake", block the message
        if userMsg:GetID() == Fade  then blockMessage = true end                                                                   -- If the message is "Fade", block the message

        if userMsg:GetID() == TextMsg then                                                                                         -- If the message is "TextMsg"
            userMsg:Reset()                                                                                                        -- Reset the message
            local msgDest = userMsg:ReadByte()                                                                                     -- Set "msgDest" to the message destination
            local msgName = userMsg:ReadString(256)                                                                                -- Set "msgName" to the message name

            if string.find(msgName, "[RTD]") then                                                                                  -- If the message name contains "[RTD]"
                if string.find(msgName, "Your perk has worn off") or string.find(msgName, "You have died during your roll") then   -- If the message name contains "Your perk has worn off" or "You have died during your roll"
                    CurrentRTD = ""                                                                                                -- Reset the current RTD, so we can detect when it changes
                elseif string.find(msgName, "Cursed")    then CurrentRTD = "Cursed"                                                -- If the message name contains "Cursed", set the current RTD to "Cursed"
                elseif string.find(msgName, "Drugged")   then CurrentRTD = "Drugged"                                               -- If the message name contains "Drugged", set the current RTD to "Drugged"
                elseif string.find(msgName, "Bad Sauce") then CurrentRTD = "Bad Sauce"                                             -- If the message name contains "Bad Sauce", set the current RTD to "Bad Sauce"
                end
            end
        end
    else
        CurrentRTD = "" -- Reset the current RTD if RTD Effects is disabled
    end

    --[[ Removals: Hud Text ]]-- (Remove the hud text of bad RTD effects)
    if mRemovals:IsSelected("HUD Texts") then                                                    -- If HUD Texts is enabled
        if userMsg:GetID() == HudText or userMsg:GetID() == HudMsg then blockMessage = true end  -- If the message is "HudText" or "HudMsg", block the message
    end

    --[[ Block messages ]]--
    if blockMessage then                        -- If "blockMessage" is triggered
        local msgLength = userMsg:GetDataBits() -- Set "msgLength" to the message length in bits
        userMsg:Reset()                         -- Reset the message
        for i = 1, msgLength do                 -- For each bit in the message, starting at 1
            userMsg:WriteBit(0)                 -- Write a 0, effectively removing the message
        end
    end
end

--[[ Remove the menu when unloaded ]]--
local function OnUnload()                                -- Called when the script is unloaded
    MenuLib.RemoveMenu(menu)                             -- Remove the menu
    client.Command('play "ui/buttonclickrelease"', true) -- Play the "buttonclickrelease" sound
end


--[[ Unregister previous callbacks ]]--
callbacks.Unregister("CreateMove", "MCT_CreateMove")            -- Unregister the "CreateMove" callback
callbacks.Unregister("SendStringCmd", "MCT_StringCmd")          -- Unregister the "SendStringCmd" callback
callbacks.Unregister("DispatchUserMessage", "MCT_UserMessage")  -- Unregister the "DispatchUserMessage" callback
callbacks.Unregister("Unload", "MCT_Unload")                    -- Unregister the "Unload" callback

--[[ Register callbacks ]]--
callbacks.Register("CreateMove", "MCT_CreateMove", OnCreateMove)             -- Register the "CreateMove" callback
callbacks.Register("SendStringCmd", "MCT_StringCmd", OnStringCmd)            -- Register the "SendStringCmd" callback
callbacks.Register("DispatchUserMessage", "MCT_UserMessage", OnUserMessage)  -- Register the "DispatchUserMessage" callback
callbacks.Register("Unload", "MCT_Unload", OnUnload)                         -- Register the "Unload" callback

--[[ Play sound when loaded ]]--
client.Command('play "ui/buttonclick"', true) -- Play the "buttonclick" sound when the script is loaded
