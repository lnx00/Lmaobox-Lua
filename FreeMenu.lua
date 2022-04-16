local options = {
    X = 0.15,
    Y = 0.05,
    Width = 260,
    Height = 465,
    Font = draw.CreateFont("TF2 Build", 14, 510, FONTFLAG_OUTLINE)
}

local selectedOption = 1

local optType = {
    BOOL = 1,
    INT = 2,
    KEY = 3
}

local menuOptions = {
    Aim = {
        { Name = "Aim Bot", Option = "aim bot", Type = optType.BOOL },
        { Name = "Aim Key", Option = "aim key", Type = optType.KEY },
        { Name = "Auto Shoot", Option = "auto shoot", Type = optType.BOOL },
        { Name = "Target Lock", Option = "preserve target", Type = optType.BOOL },
        { Name = "Aim Sentry", Option = "aim sentry", Type = optType.BOOL },
        { Name = "Aim Stickies", Option = "aim stickies", Type = optType.BOOL },
        { Name = "Ignore Steam Friends", Option = "ignore steam friends", Type = optType.BOOL },
        { Name = "Ignore Deadringer", Option = "ignore deadringer", Type = optType.BOOL },
        { Name = "Ignore Cloaked", Option = "ignore cloaked", Type = optType.BOOL },
        { Name = "Melee Aim", Option = "melee aimbot", Type = optType.INT },
    },

    Stuff = {
        { Name = "Big Heads", Option = "big heads", Type = optType.BOOL },
        { Name = "Spin Bot", Option = "anti aim", Type = optType.BOOL },
        { Name = "Trigger Bot", Option = "trigger shoot", Type = optType.BOOL },
    },

    ESP = {
        { Name = "Enemy only", Option = "enemy only", Type = optType.BOOL },
        { Name = "Steam Friends", Option = "friends", Type = optType.BOOL },
        { Name = "Name", Option = "name", Type = optType.BOOL },
        { Name = "Health", Option = "health", Type = optType.BOOL },
        { Name = "Weapon", Option = "weapon", Type = optType.BOOL },
        { Name = "Ubercharge", Option = "ubercharge", Type = optType.BOOL },
        { Name = "Distance", Option = "distance", Type = optType.BOOL },
        { Name = "Class", Option = "class", Type = optType.BOOL },
        { Name = "World ESP", Option = "ammo/medkit", Type = optType.BOOL },
        { Name = "Radar", Option = "radar", Type = optType.BOOL },
        { Name = "Radar Size", Option = "radar size", Type = optType.BOOL },
    }
}

local function Draw()
    draw.SetFont(options.Font)
    local sWidth, sHeight = draw.GetScreenSize()
    local xPos = math.floor(sWidth * options.X)
    local yPos = math.floor(sHeight * options.Y)

    -- Draw Menu
    draw.Color(20, 20, 20, 190)
    draw.FilledRect(xPos, yPos, xPos + options.Width, yPos + options.Height)
    draw.Color(0, 125, 220, 255)
    draw.OutlinedRect(xPos, yPos, xPos + options.Width, yPos + options.Height)

    local currentY = yPos + 5
    local currentX = xPos + 5

    -- Title
    currentX = xPos + 10
    local tWidth, tHeight = draw.GetTextSize("LMAOBOX HACK")
    draw.Text(currentX, currentY, "LMAOBOX HACK")
    currentY = currentY + tHeight + 5

    -- Menu
    local currentOption = 1
    for k, vCategory in pairs(menuOptions) do
        -- Draw the category
        currentX = xPos + 10
        local cWidth, cHeight = draw.GetTextSize(k)
        draw.Color(0, 125, 220, 255)
        draw.Text(currentX, currentY, "[+] " .. k)
        currentY = currentY + cHeight

        -- Draw the options
        for k2, vOption in pairs(vCategory) do
            currentX = xPos + 15
            local oWidth, oHeight = draw.GetTextSize(vOption.Name)
            local guiValue = gui.GetValue(vOption.Option)
            if currentOption == selectedOption then
                draw.Color(160, 160, 160, 180)
                draw.FilledRect(xPos, currentY, xPos + options.Width, currentY + oHeight)
                draw.Color(0, 125, 220, 255)
            elseif guiValue and guiValue ~= false and guiValue ~= 0 then
                draw.Color(255, 255, 255, 255)
            else
                draw.Color(140, 140, 140, 255)
            end
            draw.Text(currentX, currentY, string.upper(vOption.Name))

            local valueText = ""
            currentX = xPos + options.Width - 10
            if vOption.Type == optType.BOOL then
                if guiValue == 1 then
                    valueText = "ON"
                else
                    valueText = "OFF"
                end
            elseif vOption.Type == optType.INT then
                valueText = guiValue
            elseif vOption.Type == optType.KEY then
                valueText = guiValue -- TODO: Get Key name
            end
            local vWidth, vHeight = draw.GetTextSize(valueText)
            draw.Text(xPos + options.Width - (vWidth + 30), currentY, valueText)

            currentY = currentY + oHeight
            currentOption = currentOption + 1
        end
    end

    -- Increase of decreate the selected option by the arrow keys
    if input.IsButtonDown(KEY_UP) then
        selectedOption = selectedOption - 1
        if selectedOption < 1 then
            selectedOption = currentOption
        end
    elseif input.IsButtonDown(KEY_DOWN) then
        selectedOption = selectedOption + 1
        if selectedOption > currentOption then
            selectedOption = 1
        end
    end
end

callbacks.Unregister("Draw", "FM_Draw");
callbacks.Register("Draw", "FM_Draw", Draw)