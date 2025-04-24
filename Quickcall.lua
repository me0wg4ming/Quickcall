-- QuickCall Header for the Bindings
BINDING_HEADER_QUICKCALL = "Quick Call"

-- Valid AB base locations for determining valid call zones
local baseNames = {
    ["Farm"] = true,
    ["Stables"] = true,
    ["Lumber Mill"] = true,
    ["Blacksmith"] = true,
    ["Gold Mine"] = true,
}

-- Initialize and set defaults for saved variables
QuickCallDB = QuickCallDB or {}
QuickCallDB.locked = QuickCallDB.locked ~= false  -- default locked = true
QuickCallDB.posX = QuickCallDB.posX or 400        -- default x position
QuickCallDB.posY = QuickCallDB.posY or 300        -- default y position

-- Clamp frame position within screen bounds
local function ClampToScreen(x, y)
    local screenW = UIParent:GetWidth()
    local screenH = UIParent:GetHeight()
    x = math.max(0, math.min(x or 0, screenW - 220))
    y = math.max(0, math.min(y or 0, screenH - 160))
    return x, y
end

-- Simple modulo implementation (Lua 5.0 compatibility)
local function mod(a, b)
    return a - math.floor(a / b) * b
end

-- Returns the current call location based on minimap or last known valid base
local lastKnownBase = nil
local function GetCallLocation()
    local zoneText = GetMinimapZoneText() or "Unknown"
    if baseNames[zoneText] then lastKnownBase = zoneText end
    return lastKnownBase or zoneText
end

-- Executes callback only if player is in Arathi Basin or a valid base zone
local function NotInAB(callback)
    local zone = GetRealZoneText()
    local base = GetMinimapZoneText()
    if not (zone == "Arathi Basin" or baseNames[base]) then
        DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffQuickCall:|r |cffff0000You are not in Arathi Basin.|r")
        return
    end
    callback()
end

-- Frame size and layout constants
local buttonW, buttonH, spacing = 25, 26, 10
local buttonsPerRow = 4
local totalW = buttonsPerRow * buttonW + (buttonsPerRow - 1) * spacing
local frameW = totalW + 40
local frameH = 3 * buttonH + 3 * spacing + 70

-- Create main addon UI frame
local QuickCallFrame = CreateFrame("Frame", "QuickCallFrame", UIParent)
QuickCallFrame:SetWidth(frameW)
QuickCallFrame:SetHeight(frameH)
QuickCallFrame:SetClampedToScreen(true)

-- Position frame using saved position
QuickCallFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", QuickCallDB.posX, QuickCallDB.posY)
QuickCallFrame:SetMovable(true)
QuickCallFrame:RegisterForDrag("LeftButton")
QuickCallFrame:SetScript("OnDragStart", function()
    if not QuickCallDB.locked then QuickCallFrame:StartMoving() end
end)
QuickCallFrame:SetScript("OnDragStop", function()
    QuickCallFrame:StopMovingOrSizing()
    local x = QuickCallFrame:GetLeft() or 400
    local y = QuickCallFrame:GetBottom() or 300
    x, y = ClampToScreen(x, y)
    QuickCallDB.posX = x
    QuickCallDB.posY = y
end)

-- Frame backdrop appearance
QuickCallFrame:SetBackdrop({
    bgFile = "Interface\\AddOns\\QuickCall\\Quickcall.tga",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = false, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
QuickCallFrame:SetBackdropColor(1, 1, 1, 0.90)

-- Title text
local title = QuickCallFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOP", QuickCallFrame, "TOP", 0, -10)
title:SetText("Call Battleground Enemies")
title:SetTextColor(1, 1, 0)

-- Create 8 number buttons for calling enemy counts
local framePaddingX = (frameW - totalW) / 2
for i = 1, 8 do
    local btn = CreateFrame("Button", "QuickCallButton"..i, QuickCallFrame, "UIPanelButtonTemplate")
    btn:SetWidth(buttonW)
    btn:SetHeight(buttonH)
    btn:SetText(i == 8 and "8+" or tostring(i))
    local row = math.floor((i - 1) / buttonsPerRow)
    local col = mod(i - 1, buttonsPerRow)
    local x = framePaddingX + col * (buttonW + spacing)
    local y = -30 - row * (buttonH + spacing)
    btn:SetPoint("TOPLEFT", QuickCallFrame, "TOPLEFT", x, y)
    btn:SetScript("OnClick", (function(index)
        return function()
            NotInAB(function()
                SendChatMessage((index == 8 and "8 or more at " or index .. " at ") .. GetCallLocation(), "BATTLEGROUND")
            end)
        end
    end)(i))
end

-- CLEAR button for announcing a base is clear
local clearBtn = CreateFrame("Button", "QuickCallClear", QuickCallFrame, "UIPanelButtonTemplate")
clearBtn:SetWidth(totalW)
clearBtn:SetHeight(buttonH)
clearBtn:SetText("BASE CLEAR")
clearBtn:SetPoint("TOP", QuickCallFrame, "TOP", 0, -2 * (buttonH + spacing) - 40)
clearBtn:SetScript("OnClick", function()
    NotInAB(function()
        SendChatMessage(GetCallLocation() .. " CLEAR", "BATTLEGROUND")
    end)
end)

-- Lock toggle button for frame dragging
local lockBtn = CreateFrame("Button", "QuickCallLockToggle", QuickCallFrame, "UIPanelButtonTemplate")
lockBtn:SetWidth(60)
lockBtn:SetHeight(20)
lockBtn:SetText("Lock")
lockBtn:SetPoint("BOTTOM", QuickCallFrame, "BOTTOM", 0, 8)
lockBtn:SetScript("OnClick", function()
    QuickCallDB.locked = not QuickCallDB.locked
    lockBtn:SetText(QuickCallDB.locked and "Unlock" or "Lock")
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffQuickCall:|r " .. (QuickCallDB.locked and "|cffff0000Position locked!|r" or "|cff00ff00Position unlocked!|r"))
    QuickCallFrame:EnableMouse(not QuickCallDB.locked)
end)

-- Set lock state on login
local lockEventFrame = CreateFrame("Frame")
lockEventFrame:RegisterEvent("PLAYER_LOGIN")
lockEventFrame:SetScript("OnEvent", function()
    lockBtn:SetText(QuickCallDB.locked and "Unlock" or "Lock")
    QuickCallFrame:EnableMouse(not QuickCallDB.locked)
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffQuickCall:|r |cff00ff00addon loaded.|r")
end)

-- Create callable keybinds for 1–8 and CLEAR
for i = 1, 8 do
    setglobal("CALL_" .. i, function()
        NotInAB(function()
            SendChatMessage((i == 8 and "8 or more at " or i .. " at ") .. GetCallLocation(), "BATTLEGROUND")
        end)
    end)
end
setglobal("CALL_CLEAR", function()
    NotInAB(function()
        SendChatMessage(GetCallLocation() .. " CLEAR", "BATTLEGROUND")
    end)
end)

-- Auto-show/hide frame depending on zone
local visibilityEventFrame = CreateFrame("Frame")
visibilityEventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
visibilityEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
visibilityEventFrame:SetScript("OnEvent", function()
    if GetRealZoneText() == "Arathi Basin" then
        QuickCallFrame:Show()
    else
        QuickCallFrame:Hide()
    end
end)

-- Slash command to toggle visibility manually
SLASH_QUICKCALL1 = "/quickcall"
SLASH_QUICKCALL2 = "/qc"
SlashCmdList["QUICKCALL"] = function()
    if QuickCallFrame:IsShown() then
        QuickCallFrame:Hide()
    else
        QuickCallFrame:Show()
    end
end

-- Hide frame by default
QuickCallFrame:Hide()