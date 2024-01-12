--[[
    Utils for Lmaobox
    Author: LNX (github.com/lnx00)
]]

local Utils = {}

-- Converts a given SteamID 3 to a SteamID 64
function Utils.ID3toID64(pID3)
    local id = string.sub(pID3, 6, #pID3 - 1)
    return tonumber(id) + 0x110000100000000
end

-- Converts a given SteamID 64 to a SteamID 3
function Utils.ID64toID3(pID64)
    return "[U:1:" .. (tonumber(pID64) ^ 0x110000100000000) .. "]"
end

-- Returns a deep copy of the given table
function Utils.CopyTable(pTable)
    local newTable = {}
    for k, v in pairs(pTable) do
        if type(v) == "table" then
            newTable[k] = Utils.CopyTable(v)
        else
            newTable[k] = v
        end
    end
    return newTable
end

-- Converts a given EulerAngle to a directional Vector3
function Utils.EulerToVector(pEuler)
    local pitch, yaw, roll = pEuler:Unpack()
    local x = math.cos(yaw) * math.cos(pitch)
    local y = math.sin(yaw) * math.cos(pitch)
    local z = math.sin(pitch)
    return Vector3(x, y, z)
end

-- Sanitizes a given string
function Utils.Sanitize(pString)
    pString:gsub("\"", "'")
    return pString
end

-- Finds an Element in a table by ID
function Utils.FindElementByID(pTable, pID)
    for k, v in pairs(pTable) do
        if v.ID == pID then
            return v
        end
    end
    return nil
end

-- Converts a given Hex Color to RGB
function Utils.HexToRGB(pHex)
    local r = tonumber(string.sub(pHex, 1, 2), 16)
    local g = tonumber(string.sub(pHex, 3, 4), 16)
    local b = tonumber(string.sub(pHex, 5, 6), 16)
    return { r, g, b }
end

-- Scale a given rect (x, y, width, height) to a given width and height but keep its aspect ratio
function Utils.ScaleRect(pRect, pWidth, pHeight)
    local x, y, w, h = pRect:Unpack()
    local aspectRatio = w / h
    local newWidth = pWidth
    local newHeight = pHeight
    if aspectRatio > 1 then
        newHeight = pWidth / aspectRatio
    else
        newWidth = pHeight * aspectRatio
    end
    return { x, y, newWidth, newHeight }
end

-- Reads the given file and returns its content
function Utils.ReadFile(path)
    local file = io.open(path, "rb") -- r read mode and b binary mode
    if not file then return nil end
    local content = file:read "*a" -- *a or *all reads the whole file
    file:close()
    return content
end

return Utils