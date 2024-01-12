---@type boolean, lnxLib
local libLoaded, lnxLib = pcall(require, "lnxLib")
assert(libLoaded, "lnxLib not found, please install it!")
assert(lnxLib.GetVersion() >= 0.965, "lnxLib version is too old, please update it!")

local Notify = lnxLib.UI.Notify

---@type boolean, ImMenu
local menuLoaded, ImMenu = pcall(require, "ImMenu")
assert(menuLoaded, "ImMenu not found, please install it!")
assert(ImMenu.GetVersion() >= 0.67, "ImMenu version is too old, please update it!")

local theEntity = nil
local entityProps = {}

---@param userCmd UserCmd
local function OnCreateMove(userCmd)

end

-- Menu values
local className = "player"
local propName = ""
local propValue = ""

local function OnDraw()
    local me = entities.GetLocalPlayer()
    if not me then return end

    if ImMenu.Begin("Entity Factory") then
        if theEntity then
            -- Edit the entity
            ImMenu.Text("Editing Entity...")

            local prop = ImMenu.List("Active Props", entityProps)

            ImMenu.Separator()

            propName = ImMenu.TextInput("Prop Name", propName)
            propValue = ImMenu.TextInput("Prop Value", propValue)
            --ImMenu.Combo("Prop Type", {"String", "Number", "Boolean"})
            if ImMenu.Button("Add prop") then
                
            end

            ImMenu.Separator()

            if ImMenu.Button("Teleport to me") then
                theEntity:SetAbsOrigin(me:GetAbsOrigin())
            end

            if ImMenu.Button("Remove Entity") then
                theEntity:Release()
                theEntity = nil
                entityProps = {}
            end

        else
            -- Create the entity
            className = ImMenu.TextInput("Class Name", className)

            if ImMenu.Button("Create Entity") then
                theEntity = entities.CreateEntityByName(className)
                if theEntity then
                    Notify.Alert("Entity created")
                    theEntity:SetAbsOrigin(me:GetAbsOrigin())
                else
                    Notify.Alert("Failed to create entity")
                end
            end
        end

        ImMenu.End()
    end
end

local function OnUnload()
    if theEntity then
        theEntity:Release()
    end
end

callbacks.Register("CreateMove", OnCreateMove)
callbacks.Register("Draw", OnDraw)
callbacks.Register("Unload", OnUnload)