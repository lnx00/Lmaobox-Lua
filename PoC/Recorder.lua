---@type boolean, lnxLib
local libLoaded, lnxLib = pcall(require, "lnxLib")
assert(libLoaded, "lnxLib not found, please install it!")
assert(lnxLib.GetVersion() >= 0.965, "lnxLib version is too old, please update it!")

local Fonts = lnxLib.UI.Fonts

---@type boolean, ImMenu
local menuLoaded, ImMenu = pcall(require, "ImMenu")
assert(menuLoaded, "ImMenu not found, please install it!")
assert(ImMenu.GetVersion() >= 0.66, "ImMenu version is too old, please update it!")

local currentTick = 0
local currentData = {}
local currentSize = 1

local isRecording = false
local isPlaying = false

local doRepeat = false
local doViewAngles = true

---@param userCmd UserCmd
local function OnCreateMove(userCmd)
    if isRecording then
        local yaw, pitch, roll = userCmd:GetViewAngles()
        currentData[currentTick] = {
            viewAngles = EulerAngles(yaw, pitch, roll),
            forwardMove = userCmd:GetForwardMove(),
            sideMove = userCmd:GetSideMove(),
            buttons = userCmd:GetButtons()
        }

        currentSize = currentSize + 1
        currentTick = currentTick + 1
    elseif isPlaying then
        if currentTick >= currentSize then
            if doRepeat then
                currentTick = 0
            else
                isPlaying = false
            end
        end

        if currentData[currentTick] ~= nil then
            local data = currentData[currentTick]
            userCmd:SetViewAngles(data.viewAngles:Unpack())
            userCmd:SetForwardMove(data.forwardMove)
            userCmd:SetSideMove(data.sideMove)
            userCmd:SetButtons(data.buttons)

            if doViewAngles then
                engine.SetViewAngles(data.viewAngles)
            end
        end

        currentTick = currentTick + 1
    end
end

local function OnDraw()
    draw.SetFont(Fonts.Verdana)
    draw.Color(255, 255, 255, 255)

    if isRecording then
        draw.Text(20, 150, string.format("Recording... (%d)", currentTick, currentSize))
    elseif isPlaying then
        draw.Text(20, 150, string.format("Playing... (%d / %d)", currentTick, currentSize))
    end

    if not engine.IsGameUIVisible() and not (isPlaying or isRecording) then return end

    if ImMenu.Begin("Movement Recorder", true) then

        -- Progress bar
        ImMenu.BeginFrame(1)
        ImMenu.PushStyle("ItemSize", { 385, 30 })

        currentTick = ImMenu.Slider("Tick", currentTick, 0, currentSize)

        ImMenu.PopStyle()
        ImMenu.EndFrame()

        -- Buttons
        ImMenu.BeginFrame(1)
        ImMenu.PushStyle("ItemSize", { 125, 30 })

            if ImMenu.Button("Record") then
                isRecording = not isRecording
                if isRecording then
                    currentData = {}
                    currentSize = 1
                end
            end

            if ImMenu.Button("Play / Pause") then
                isPlaying = not isPlaying
                if isPlaying then
                    currentTick = 0
                end
            end
            
            if ImMenu.Button("Reset") then
                isRecording = false
                isPlaying = false
                currentTick = 0
                currentData = {}
                currentSize = 1
            end

        ImMenu.PopStyle()
        ImMenu.EndFrame()

        -- Options
        ImMenu.BeginFrame(1)

            doRepeat = ImMenu.Checkbox("Auto Repeat", doRepeat)
            doViewAngles = ImMenu.Checkbox("Apply View Angles", doViewAngles)

        ImMenu.EndFrame()

        ImMenu.End()
    end
end

callbacks.Unregister("CreateMove", "LNX.Recorder.CreateMove")
callbacks.Register("CreateMove", "LNX.Recorder.CreateMove", OnCreateMove)

callbacks.Unregister("Draw", "LNX.Recorder.Draw")
callbacks.Register("Draw", "LNX.Recorder.Draw", OnDraw)