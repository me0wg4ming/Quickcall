-- QuickCall Header for the Bindings
BINDING_HEADER_QUICKCALL = "Quick Call"

-- SavedVariables setup
if not QuickCallDB then QuickCallDB = {} end
QuickCallDB.locked_AB = QuickCallDB.locked_AB ~= false -- default true
QuickCallDB.posX_AB = QuickCallDB.posX_AB or 400
QuickCallDB.posY_AB = QuickCallDB.posY_AB or 300
QuickCallDB.locked_WSG = QuickCallDB.locked_WSG ~= false
QuickCallDB.posX_WSG = QuickCallDB.posX_WSG or 400
QuickCallDB.posY_WSG = QuickCallDB.posY_WSG or 300

-- Toggle for long or short calls
QuickCallDB.useShortNames = QuickCallDB.useShortNames ~= false

-- Clamp helper
local function ClampToScreen(x, y, frameWidth, frameHeight)
    local screenW = UIParent:GetWidth()
    local screenH = UIParent:GetHeight()
    x = math.max(0, math.min(x or 0, screenW - (frameWidth or 220)))
    y = math.max(0, math.min(y or 0, screenH - (frameHeight or 160)))
    return x, y
end

-- Toggle lock
local function ToggleLock(frame, isAB)
    if isAB then
        QuickCallDB.locked_AB = not QuickCallDB.locked_AB
        frame:EnableMouse(not QuickCallDB.locked_AB)
        local lockBtn = _G[frame:GetName().."LockToggle"]
        if lockBtn then
            lockBtn:SetText(QuickCallDB.locked_AB and "Unlock" or "Lock")
        end
        if QuickCallDB.locked_AB then
            DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffQuickCall Arathi:|r |cffff0000Position locked!|r")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffQuickCall Arathi:|r |cff00ff00Position unlocked!|r")
        end
    else
        QuickCallDB.locked_WSG = not QuickCallDB.locked_WSG
        frame:EnableMouse(not QuickCallDB.locked_WSG)
        local lockBtn = _G[frame:GetName().."LockToggle"]
        if lockBtn then
            lockBtn:SetText(QuickCallDB.locked_WSG and "Unlock" or "Lock")
        end
        if QuickCallDB.locked_WSG then
            DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffQuickCall Warsong:|r |cffff0000Position locked!|r")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffQuickCall Warsong:|r |cff00ff00Position unlocked!|r")
        end
    end
end

-- ==================== Arathi Basin Frame ====================
local buttonWidth_AB = 25
local buttonHeight_AB = 26
local spacing_AB = 10
local buttonsPerRow_AB = 4

local QuickCallFrameAB = CreateFrame("Frame", "QuickCallFrameAB", UIParent)
QuickCallFrameAB:SetClampedToScreen(true)
local totalWidth_AB = buttonsPerRow_AB * buttonWidth_AB + (buttonsPerRow_AB-1) * spacing_AB
QuickCallFrameAB:SetWidth(totalWidth_AB + 40)
QuickCallFrameAB:SetHeight(3 * buttonHeight_AB + 3*spacing_AB + 70)
QuickCallFrameAB:EnableMouse(not QuickCallDB.locked_AB)

QuickCallFrameAB:SetBackdrop({bgFile="Interface\\AddOns\\QuickCall\\Quickcall.tga", edgeFile="Interface/Tooltips/UI-Tooltip-Border", tile=false, edgeSize=16, insets={left=4,right=4,top=4,bottom=4}})
QuickCallFrameAB:SetBackdropColor(1,1,1,0.9)

local x, y = ClampToScreen(QuickCallDB.posX_AB, QuickCallDB.posY_AB, QuickCallFrameAB:GetWidth(), QuickCallFrameAB:GetHeight())
QuickCallFrameAB:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
QuickCallFrameAB:SetMovable(true)
QuickCallFrameAB:RegisterForDrag("LeftButton")
QuickCallFrameAB:SetScript("OnDragStart", function()
    if not QuickCallDB.locked_AB then QuickCallFrameAB:StartMoving() end
end)
QuickCallFrameAB:SetScript("OnDragStop", function()
    QuickCallFrameAB:StopMovingOrSizing()
    local _, _, _, x, y = QuickCallFrameAB:GetPoint()
    x, y = ClampToScreen(x, y, QuickCallFrameAB:GetWidth(), QuickCallFrameAB:GetHeight())
    QuickCallDB.posX_AB = x
    QuickCallDB.posY_AB = y
end)

local titleAB = QuickCallFrameAB:CreateFontString(nil,"OVERLAY","GameFontNormal")
titleAB:SetPoint("TOP", QuickCallFrameAB,"TOP",0,-12)
titleAB:SetText("Call Arathi Basin Enemies")
titleAB:SetTextColor(1,1,0)
titleAB:SetFont("Fonts\\ARIALN.TTF",13, "OUTLINE")

-- For validation
local baseNames = {
    ["Farm"]        = true,
    ["Stables"]     = true,
    ["Lumber Mill"] = true,
    ["Blacksmith"]  = true,
    ["Gold Mine"]   = true
}

-- Short names of bases
local baseShortNames = {
    ["Lumber Mill"] = "LM",
    ["Blacksmith"]  = "BS",
    ["Gold Mine"]   = "GM",
    ["Farm"]        = "FM",
    ["Stables"]     = "ST"
}

local lastKnownBase = nil

local function HandleCallAB(index)
    local zone = GetRealZoneText()
    local base = GetMinimapZoneText()
    if zone == "Arathi Basin" and baseNames[base] then
        lastKnownBase = base
    end
    if lastKnownBase and baseNames[lastKnownBase] then
        local baseName
        if QuickCallDB.useShortNames then
            baseName = baseShortNames[lastKnownBase] or lastKnownBase
        else
            baseName = lastKnownBase
        end
        local msg = (index==8 and "8 or more at " or index.." at ")..baseName
        SendChatMessage(msg,"BATTLEGROUND")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffQuickCall:|r |cffff0000You are not at a valid base in Arathi Basin!|r")
    end
end

local function HandleClearAB()
    local zone = GetRealZoneText() or ""
    local base = GetMinimapZoneText() or ""
    if zone=="Arathi Basin" and baseNames[base] then
        lastKnownBase = base
    end
    if lastKnownBase and baseNames[lastKnownBase] then
        local baseName
        if QuickCallDB.useShortNames then
            baseName = baseShortNames[lastKnownBase] or lastKnownBase
        else
            baseName = lastKnownBase
        end
        SendChatMessage(baseName.." CLEAR","BATTLEGROUND")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffQuickCall:|r |cffff0000You are not at a valid base in Arathi Basin!|r")
    end
end

-- AB buttons
local framePaddingX_AB = 20
for i=1,8 do
    local btn = CreateFrame("Button", QuickCallFrameAB:GetName().."Button"..i, QuickCallFrameAB,"UIPanelButtonTemplate")
    btn:SetWidth(buttonWidth_AB)
    btn:SetHeight(buttonHeight_AB)
    btn:SetText(i==8 and "8+" or tostring(i))
    local fs = _G[btn:GetName().."Text"]
    fs:SetFont("Fonts\\ARIALN.TTF",11, "OUTLINE")
    
    local row = math.floor((i-1)/buttonsPerRow_AB)
    local col = (i-1) - row*buttonsPerRow_AB
    local x = framePaddingX_AB + col*(buttonWidth_AB+spacing_AB)
    local y = -30 - row*(buttonHeight_AB+spacing_AB)
    btn:SetPoint("TOPLEFT", QuickCallFrameAB, "TOPLEFT", x, y)
    btn:SetScript("OnClick", (function(idx) return function() HandleCallAB(idx) end end)(i))
end

-- CLEAR Button
local clearBtn = CreateFrame("Button",QuickCallFrameAB:GetName().."Clear",QuickCallFrameAB,"UIPanelButtonTemplate")
clearBtn:SetWidth(totalWidth_AB)
clearBtn:SetHeight(buttonHeight_AB)
clearBtn:SetText("BASE CLEAR")
clearBtn:SetPoint("TOP",QuickCallFrameAB,"TOP",0,-2*(buttonHeight_AB+spacing_AB)-40)
clearBtn:SetScript("OnClick",HandleClearAB)
local fs = _G[clearBtn:GetName().."Text"]
fs:SetFont("Fonts\\ARIALN.TTF", 13, "OUTLINE")

-- Lock Button AB
local lockBtnAB = CreateFrame("Button",QuickCallFrameAB:GetName().."LockToggle",QuickCallFrameAB,"UIPanelButtonTemplate")
lockBtnAB:SetWidth(60)
lockBtnAB:SetHeight(20)
lockBtnAB:SetText(QuickCallDB.locked_AB and "Unlock" or "Lock")
lockBtnAB:SetPoint("BOTTOM",QuickCallFrameAB,"BOTTOM",0,8)
lockBtnAB:SetScript("OnClick",function() ToggleLock(QuickCallFrameAB,true) end)
lockBtnAB:SetFont("Fonts\\ARIALN.TTF",13, "OUTLINE")

-- Keybindings AB
for i=1,8 do
    local idx = i
    setglobal("CALL_"..i, function() HandleCallAB(idx) end)
end
setglobal("CALL_CLEAR", HandleClearAB)

QuickCallFrameAB:Hide()

--==================== WSG Frame ====================
local wsgTexts = {
    "efc fr",
    "efc balcony",
    "efc tunnel",
    "efc gy",
    "efc roof",
    "efc ramp",
    "efc west",
    "efc mid",
    "efc east",
    "efc efr",
    "efc ebalcony",
    "efc etunnel",
    "efc egy",
    "efc eroof",
    "efc eramp"
}

local wsgChatTexts = {
    "Enemy flag carrier is in our flag room",
    "Enemy flag carrier is on our balcony",
    "Enemy flag carrier is in our tunnel",
    "Enemy flag carrier is at our graveyard",
    "Enemy flag carrier is on our roof",
    "Enemy flag carrier is at our ramp",
    "Enemy flag carrier is west",
    "Enemy flag carrier is mid",
    "Enemy flag carrier is east",
    "Enemy flag carrier is at enemy flag room",
    "Enemy flag carrier is at enemy balcony",
    "Enemy flag carrier is at enemy tunnel",
    "Enemy flag carrier is at enemy graveyard",
    "Enemy flag carrier is on enemy roof",
    "Enemy flag carrier is at enemy ramp"
}

local buttonWidth_WSG = 65
local buttonHeight_WSG = 26
local spacing_WSG = 5
local wsgButtonsPerRow = 3
local totalWSGWidth = wsgButtonsPerRow*buttonWidth_WSG + (wsgButtonsPerRow-1)*spacing_WSG + 20
local totalWSGHeight = 2*buttonHeight_WSG + 2*spacing_WSG + 150

local QuickCallFrameWSG = CreateFrame("Frame","QuickCallFrameWSG",UIParent)
QuickCallFrameWSG:SetClampedToScreen(true)
QuickCallFrameWSG:SetWidth(totalWSGWidth)
QuickCallFrameWSG:SetHeight(totalWSGHeight)
QuickCallFrameWSG:EnableMouse(not QuickCallDB.locked_WSG)

QuickCallFrameWSG:SetBackdrop({bgFile="Interface\\AddOns\\QuickCall\\Quickcall.tga", edgeFile="Interface/Tooltips/UI-Tooltip-Border", tile=false, edgeSize=16, insets={left=4,right=4,top=4,bottom=4}})
QuickCallFrameWSG:SetBackdropColor(1,1,1,0.9)

local x, y = ClampToScreen(QuickCallDB.posX_WSG, QuickCallDB.posY_WSG, QuickCallFrameWSG:GetWidth(), QuickCallFrameWSG:GetHeight())
QuickCallFrameWSG:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",x,y)
QuickCallFrameWSG:SetMovable(true)
QuickCallFrameWSG:RegisterForDrag("LeftButton")
QuickCallFrameWSG:SetScript("OnDragStart",function()
    if not QuickCallDB.locked_WSG then QuickCallFrameWSG:StartMoving() end
end)
QuickCallFrameWSG:SetScript("OnDragStop",function()
    QuickCallFrameWSG:StopMovingOrSizing()
    local _, _, _, x, y = QuickCallFrameWSG:GetPoint()
    x, y = ClampToScreen(x, y, QuickCallFrameWSG:GetWidth(), QuickCallFrameWSG:GetHeight())
    QuickCallDB.posX_WSG = x
    QuickCallDB.posY_WSG = y
end)

local titleWSG = QuickCallFrameWSG:CreateFontString(nil,"OVERLAY","GameFontNormal")
titleWSG:SetPoint("TOP",QuickCallFrameWSG,"TOP",0,-12)
titleWSG:SetText("Call enemy Flag Carrier")
titleWSG:SetTextColor(1,1,0)
titleWSG:SetFont("Fonts\\ARIALN.TTF",15, "OUTLINE")

--==================== WSG Buttons ====================
local framePaddingX_WSG = 20
local row = 0
local currentRowCount = 0
local rowButtonsVisible = {}

for i=1, table.getn(wsgTexts) do
    local btn = CreateFrame("Button", QuickCallFrameWSG:GetName().."Button"..i, QuickCallFrameWSG, "UIPanelButtonTemplate")
    btn:SetWidth(buttonWidth_WSG)
    btn:SetHeight(buttonHeight_WSG)
    if wsgTexts[i] ~= "" then
        btn:SetText(wsgTexts[i])
        local fs = _G[btn:GetName().."Text"]
        fs:SetFont("Fonts\\ARIALN.TTF",10.5, "OUTLINE")
        -- Colors
        if i <=6 then fs:SetTextColor(0,1,0) -- grün
        elseif i <=9 then fs:SetTextColor(0.4,0.6,1) -- hellblau
        else fs:SetTextColor(1,1,0) end -- gelb
        btn:SetScript("OnClick", (function(idx) return function() 
            if GetRealZoneText() ~= "Warsong Gulch" then
                DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffQuickCall:|r |cffff0000You are not in Warsong Gulch!|r")
            else
                SendChatMessage(wsgChatTexts[idx],"BATTLEGROUND")
            end
        end end)(i))
        table.insert(rowButtonsVisible, btn)
    else
        btn:Hide()
    end
    currentRowCount = currentRowCount +1
    if currentRowCount >= wsgButtonsPerRow then
        -- Center row
        local totalWidth = table.getn(rowButtonsVisible)*buttonWidth_WSG + (table.getn(rowButtonsVisible)-1)*spacing_WSG
        for j=1,table.getn(rowButtonsVisible) do
            local x = (QuickCallFrameWSG:GetWidth()-totalWidth)/2 + (j-1)*(buttonWidth_WSG+spacing_WSG)
            local y = -30 - row*(buttonHeight_WSG+spacing_WSG)
            rowButtonsVisible[j]:SetPoint("TOPLEFT", QuickCallFrameWSG, "TOPLEFT", x, y)
        end
        row = row +1
        currentRowCount = 0
        rowButtonsVisible = {}
    end
end
-- Center last row
if table.getn(rowButtonsVisible) >0 then
    local totalWidth = table.getn(rowButtonsVisible)*buttonWidth_WSG + (table.getn(rowButtonsVisible)-1)*spacing_WSG
    for j=1,table.getn(rowButtonsVisible) do
        local x = (QuickCallFrameWSG:GetWidth()-totalWidth)/2 + (j-1)*(buttonWidth_WSG+spacing_WSG)
        local y = -30 - row*(buttonHeight_WSG+spacing_WSG)
        rowButtonsVisible[j]:SetPoint("TOPLEFT", QuickCallFrameWSG, "TOPLEFT", x, y)
    end
end

-- Lock button WSG
local lockBtnWSG = CreateFrame("Button",QuickCallFrameWSG:GetName().."LockToggle",QuickCallFrameWSG,"UIPanelButtonTemplate")
lockBtnWSG:SetWidth(60)
lockBtnWSG:SetHeight(20)
lockBtnWSG:SetText(QuickCallDB.locked_WSG and "Unlock" or "Lock")
lockBtnWSG:SetPoint("BOTTOM",QuickCallFrameWSG,"BOTTOM",0,8)
lockBtnWSG:SetScript("OnClick",function() ToggleLock(QuickCallFrameWSG,false) end)
lockBtnWSG:SetFont("Fonts\\ARIALN.TTF",10, "OUTLINE")

QuickCallFrameWSG:Hide()

-- ==================== Visibility handler ====================
local function UpdateVisibility()
    local zoneName = GetRealZoneText()
    QuickCallFrameAB:Hide()
    QuickCallFrameWSG:Hide()
    if zoneName=="Arathi Basin" then
        QuickCallFrameAB:Show()
    elseif zoneName=="Warsong Gulch" then
        QuickCallFrameWSG:Show()
    end
end

local visEventFrame = CreateFrame("Frame")
visEventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
visEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
visEventFrame:SetScript("OnEvent",UpdateVisibility)

-- ==================== Slash Commands ====================
SLASH_QUICKCALL1 = "/qca"
SlashCmdList["QUICKCALL"] = function()
    if QuickCallFrameAB:IsShown() then QuickCallFrameAB:Hide() else QuickCallFrameAB:Show() end
end

SLASH_QUICKCALLWSG1 = "/qcw"
SlashCmdList["QUICKCALLWSG"] = function()
    if QuickCallFrameWSG:IsShown() then QuickCallFrameWSG:Hide() else QuickCallFrameWSG:Show() end
end

SLASH_QUICKCALLALL1 = "/qc"
SlashCmdList["QUICKCALLALL"] = function()
    local anyShown = QuickCallFrameAB:IsShown() or QuickCallFrameWSG:IsShown()
    if anyShown then
        QuickCallFrameAB:Hide()
        QuickCallFrameWSG:Hide()
    else
        QuickCallFrameAB:Show()
        QuickCallFrameWSG:Show()
    end
end

SLASH_QCSHORT1 = "/qcshort"
SlashCmdList["QCSHORT"] = function()
    QuickCallDB.useShortNames = true
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffQuickCall:|r Using |cff00ff00SHORT|r base names (LM, BS, GM, FM, ST).")
end

SLASH_QCLONG1 = "/qclong"
SlashCmdList["QCLONG"] = function()
    QuickCallDB.useShortNames = false
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffQuickCall:|r Using |cffffff00LONG|r base names (Lumber Mill, Blacksmith, Gold Mine, Farm, Stables).")
end
