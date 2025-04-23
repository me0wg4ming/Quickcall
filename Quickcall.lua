-- QuickCall Header for the Bindings
BINDING_HEADER_QUICKCALL = "Quick Call"

-- Valid AB base locations
local baseNames = {
    ["Farm"] = true,
    ["Stables"] = true,
    ["Lumber Mill"] = true,
    ["Blacksmith"] = true,
    ["Gold Mine"] = true,
}

-- SavedVariables setup
if not QuickCallDB then QuickCallDB = {} end
QuickCallDB.locked = QuickCallDB.locked ~= false -- default true
QuickCallDB.posX = QuickCallDB.posX or 400
QuickCallDB.posY = QuickCallDB.posY or 300

-- Custom mod
local function mod(a, b)
    return a - math.floor(a / b) * b
end

-- Clamp helper
local function ClampToScreen(x, y)
    local screenW = UIParent:GetWidth()
    local screenH = UIParent:GetHeight()

    x = math.max(0, math.min(x or 0, screenW - 220))
    y = math.max(0, math.min(y or 0, screenH - 160))

    return x, y
end

local function SaveFramePosition()
    local _, _, _, x, y = QuickCallFrame:GetPoint()
    x, y = ClampToScreen(x, y)
    QuickCallDB.posX = x
    QuickCallDB.posY = y
end

local function UpdateLockButton()
    QuickCallFrame:EnableMouse(not QuickCallDB.locked)
    if lockBtn then
        lockBtn:SetText(QuickCallDB.locked and "Unlock" or "Lock")
    end
end

local function ToggleLock()
    QuickCallDB.locked = not QuickCallDB.locked
    UpdateLockButton()
    DEFAULT_CHAT_FRAME:AddMessage("Lock toggled: " .. tostring(QuickCallDB.locked), 0.8, 0.8, 1.0)
end

-- Layout constants
local buttonWidth = 25
local buttonHeight = 26
local spacing = 10
local buttonsPerRow = 4
local totalWidth = buttonsPerRow * buttonWidth + (buttonsPerRow - 1) * spacing
local frameWidth = totalWidth + 40
local frameHeight = 3 * buttonHeight + 3 * spacing + 70

-- Create main frame
local QuickCallFrame = CreateFrame("Frame", "QuickCallFrame", UIParent)
QuickCallFrame:SetClampedToScreen(true)
QuickCallFrame:SetWidth(frameWidth)
QuickCallFrame:SetHeight(frameHeight)

local x, y = ClampToScreen(QuickCallDB.posX, QuickCallDB.posY)
QuickCallFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)

QuickCallFrame:SetMovable(true)
QuickCallFrame:RegisterForDrag("LeftButton")
QuickCallFrame:SetScript("OnDragStart", function()
    if not QuickCallDB.locked then QuickCallFrame:StartMoving() end
end)
QuickCallFrame:SetScript("OnDragStop", function()
    QuickCallFrame:StopMovingOrSizing()
    SaveFramePosition()
end)

QuickCallFrame:SetBackdrop({
    bgFile = "Interface\\AddOns\\QuickCall\\Quickcall.tga",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = false,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
QuickCallFrame:SetBackdropColor(1, 1, 1, 0.90)

-- Title
local title = QuickCallFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOP", QuickCallFrame, "TOP", 0, -10)
title:SetText("Call Battleground Enemys")
title:SetTextColor(1, 1, 0)

-- Shared zone check logic
local function NotInAB(callback)
    local zone = GetRealZoneText()
    local base = GetMinimapZoneText()
    if zone == "Arathi Basin" or baseNames[base] then
        callback()
        return
    end
    DEFAULT_CHAT_FRAME:AddMessage("You are not in Arathi Basin.", 1, 0, 0)
end

-- Shared action handlers
local lastKnownBase = nil
local function HandleCall(index)
    NotInAB(function()
        local zoneText = GetMinimapZoneText() or "Unknown"
        if baseNames[zoneText] then lastKnownBase = zoneText end
        local locationToCall = lastKnownBase or zoneText
        local msg = (index == 8 and "8 or more at " or index .. " at ") .. locationToCall
        SendChatMessage(msg, "BATTLEGROUND")
    end)
end

local function HandleClear()
    NotInAB(function()
        local zoneText = GetMinimapZoneText() or "Unknown"
        if baseNames[zoneText] then lastKnownBase = zoneText end
        local locationToCall = lastKnownBase or zoneText
        SendChatMessage(locationToCall.." CLEAR", "BATTLEGROUND")
    end)
end

-- Buttons 1–8
local framePaddingX = (frameWidth - totalWidth) / 2
for i = 1, 8 do
    local btn = CreateFrame("Button", "QuickCallButton"..i, QuickCallFrame, "UIPanelButtonTemplate")
    btn:SetWidth(buttonWidth)
    btn:SetHeight(buttonHeight)
    btn:SetText(i == 8 and "8+" or tostring(i))
    btn:GetFontString():SetPoint("LEFT", 4, 0)
    btn:GetFontString():SetPoint("RIGHT", -4, 0)
    local row = math.floor((i - 1) / buttonsPerRow)
    local col = mod(i - 1, buttonsPerRow)
    local x = framePaddingX + col * (buttonWidth + spacing)
    local y = -30 - row * (buttonHeight + spacing)
    btn:SetPoint("TOPLEFT", QuickCallFrame, "TOPLEFT", x, y)
    btn:SetScript("OnClick", (function(index)
    return function() HandleCall(index) end
end)(i))
end

-- CLEAR button
local clearBtn = CreateFrame("Button", "QuickCallClear", QuickCallFrame, "UIPanelButtonTemplate")
clearBtn:SetWidth(totalWidth)
clearBtn:SetHeight(buttonHeight)
clearBtn:SetText("BASE CLEAR")
clearBtn:SetPoint("TOP", QuickCallFrame, "TOP", 0, -2 * (buttonHeight + spacing) - 40)
clearBtn:SetScript("OnClick", HandleClear)

-- Lock/unlock toggle button
lockBtn = CreateFrame("Button", "QuickCallLockToggle", QuickCallFrame, "UIPanelButtonTemplate")
lockBtn:SetWidth(60)
lockBtn:SetHeight(20)
lockBtn:SetText("Lock")
lockBtn:SetPoint("BOTTOM", QuickCallFrame, "BOTTOM", 0, 8)
lockBtn:SetScript("OnClick", ToggleLock)
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function()
    UpdateLockButton()
	DEFAULT_CHAT_FRAME:AddMessage("QuickCall: Lock/Unlock button loaded.")
end)

-- Keybinding functions
-- Set up keybindings CALL_1 through CALL_8 with closure fix
for i = 1, 8 do
    local idx = i
    setglobal("CALL_" .. idx, function() HandleCall(idx) end)
end

-- Add the CALL_CLEAR binding
setglobal("CALL_CLEAR", function() HandleClear() end)



--Show/hide in Arathi Basin
local function UpdateVisibility()
    local zoneName = GetRealZoneText()
    if zoneName == "Arathi Basin" then
        QuickCallFrame:Show()
    else
        QuickCallFrame:Hide()
    end
end

--Event handling (no more lock logic here — handled above)
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function()
    UpdateVisibility()
end)

-- Slash command
SLASH_QUICKCALL1 = "/quickcall"
SLASH_QUICKCALL2 = "/qc"
SlashCmdList["QUICKCALL"] = function()
    if QuickCallFrame:IsShown() then
        QuickCallFrame:Hide()
    else
        QuickCallFrame:Show()
    end
end

QuickCallFrame:Show()