-- Quickcall for WoW 1.12.1 by Meow
local function mod(a, b)
    return a - math.floor(a / b) * b
end

-- Valid AB base locations
local baseNames = {
    ["Farm"] = true,
    ["Stables"] = true,
    ["Lumber Mill"] = true,
    ["Blacksmith"] = true,
    ["Gold Mine"] = true,
}

-- Default saved position fallback
QuickCallSavedPosition = QuickCallSavedPosition or {
    point = "CENTER",
    relativeTo = "UIParent",
    relativePoint = "CENTER",
    xOfs = 0,
    yOfs = 0,
}

local lastKnownBase = nil

-- Layout constants
local buttonWidth = 22
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
QuickCallFrame:SetPoint(
    QuickCallSavedPosition.point,
    QuickCallSavedPosition.relativeTo or UIParent,
    QuickCallSavedPosition.relativePoint,
    QuickCallSavedPosition.xOfs,
    QuickCallSavedPosition.yOfs
)
QuickCallFrame:SetMovable(true)
QuickCallFrame:EnableMouse(true)
QuickCallFrame:RegisterForDrag("LeftButton")
QuickCallFrame:SetScript("OnDragStart", function() QuickCallFrame:StartMoving() end)
QuickCallFrame:SetScript("OnDragStop", function()
    QuickCallFrame:StopMovingOrSizing()
    local point, _, relativePoint, xOfs, yOfs = QuickCallFrame:GetPoint()
    QuickCallSavedPosition = {
        point = point,
        relativeTo = "UIParent",
        relativePoint = relativePoint,
        xOfs = xOfs,
        yOfs = yOfs,
    }
end)

-- Background
QuickCallFrame:SetBackdrop({
    bgFile = "Interface\\AddOns\\QuickCall\\Quickcall.tga",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = false,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
QuickCallFrame:SetBackdropColor(1, 1, 1, 0.5)

-- Title
local title = QuickCallFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOP", QuickCallFrame, "TOP", 0, -10)
title:SetText("Call Battleground Incomes")
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
        SendChatMessage("CLEAR at " .. locationToCall, "BATTLEGROUND")
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
    btn:SetScript("OnClick", function() HandleCall(i) end)
end

-- CLEAR button
local clearBtn = CreateFrame("Button", "QuickCallClear", QuickCallFrame, "UIPanelButtonTemplate")
clearBtn:SetWidth(totalWidth)
clearBtn:SetHeight(buttonHeight)
clearBtn:SetText("CLEAR")
clearBtn:SetPoint("TOP", QuickCallFrame, "TOP", 0, -2 * (buttonHeight + spacing) - 40)
clearBtn:SetScript("OnClick", HandleClear)

-- Lock/unlock toggle button
local isLocked = false
local lockBtn = CreateFrame("Button", "QuickCallLockToggle", QuickCallFrame, "UIPanelButtonTemplate")
lockBtn:SetWidth(60)
lockBtn:SetHeight(20)
lockBtn:SetText("Lock")
lockBtn:SetPoint("BOTTOM", QuickCallFrame, "BOTTOM", 0, 8)
lockBtn:SetScript("OnClick", function()
    isLocked = not isLocked
    QuickCallFrame:EnableMouse(not isLocked)
    lockBtn:SetText(isLocked and "Unlock" or "Lock")
end)

-- Keybinding functions
for i = 1, 8 do
    setglobal("CALL_" .. i, function() HandleCall(i) end)
end
setglobal("CALL_CLEAR", HandleClear)

-- Auto show/hide in Arathi Basin
local function UpdateVisibility()
    local zoneName = GetRealZoneText()
    if zoneName == "Arathi Basin" then
        QuickCallFrame:Show()
    else
        QuickCallFrame:Hide()
    end
end

QuickCallFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
QuickCallFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
QuickCallFrame:SetScript("OnEvent", function() UpdateVisibility() end)

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

QuickCallFrame:Hide()