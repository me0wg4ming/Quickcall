-- QuickCall Header for the Bindings
BINDING_HEADER_QUICKCALL = "Quick Call"

-- SavedVariables setup
if not QuickCallDB then QuickCallDB = {} end
QuickCallDB.locked_AB = QuickCallDB.locked_AB ~= false
QuickCallDB.posX_AB = QuickCallDB.posX_AB or 400
QuickCallDB.posY_AB = QuickCallDB.posY_AB or 300
QuickCallDB.locked_WSG = QuickCallDB.locked_WSG ~= false
QuickCallDB.posX_WSG = QuickCallDB.posX_WSG or 400
QuickCallDB.posY_WSG = QuickCallDB.posY_WSG or 300
QuickCallDB.enabled_AB  = QuickCallDB.enabled_AB ~= false
QuickCallDB.enabled_WSG = QuickCallDB.enabled_WSG ~= false
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

local baseNames = { ["Farm"]=true, ["Stables"]=true, ["Lumber Mill"]=true, ["Blacksmith"]=true, ["Gold Mine"]=true }
local baseShortNames = { ["Lumber Mill"]="LM", ["Blacksmith"]="BS", ["Gold Mine"]="GM", ["Farm"]="FM", ["Stables"]="ST" }

local lastKnownBase = nil
local function UpdateLastKnownBaseDynamic()
    local zone = GetRealZoneText()
    local base = GetMinimapZoneText()
    if zone == "Arathi Basin" and baseNames[base] then
        lastKnownBase = base
    end
end

local function HandleCallAB(index)
    if GetRealZoneText() ~= "Arathi Basin" then
        lastKnownBase = nil
        DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffQuickCall:|r |cffff0000You are not in Arathi Basin!|r")
        return
    end
    UpdateLastKnownBaseDynamic()
    if not lastKnownBase then
        DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffQuickCall:|r |cffff0000No valid base known yet!|r")
        return
    end
    local baseName = QuickCallDB.useShortNames and (baseShortNames[lastKnownBase] or lastKnownBase) or lastKnownBase
    local msg = (index == 8 and "8 or more at " or index.." at ") .. baseName
    SendChatMessage(msg, "BATTLEGROUND")
end

local function HandleClearAB()
    if GetRealZoneText() ~= "Arathi Basin" then
        lastKnownBase = nil
        DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffQuickCall:|r |cffff0000You are not in Arathi Basin!|r")
        return
    end
    UpdateLastKnownBaseDynamic()
    if not lastKnownBase then
        DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffQuickCall:|r |cffff0000No valid base known yet!|r")
        return
    end
    local baseName = QuickCallDB.useShortNames and (baseShortNames[lastKnownBase] or lastKnownBase) or lastKnownBase
    SendChatMessage(baseName .. " CLEAR", "BATTLEGROUND")
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

local clearBtn = CreateFrame("Button",QuickCallFrameAB:GetName().."Clear",QuickCallFrameAB,"UIPanelButtonTemplate")
clearBtn:SetWidth(totalWidth_AB)
clearBtn:SetHeight(buttonHeight_AB)
clearBtn:SetText("BASE CLEAR")
clearBtn:SetPoint("TOP",QuickCallFrameAB,"TOP",0,-2*(buttonHeight_AB+spacing_AB)-40)
clearBtn:SetScript("OnClick",HandleClearAB)
local fs = _G[clearBtn:GetName().."Text"]
fs:SetFont("Fonts\\ARIALN.TTF", 13, "OUTLINE")

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

-- ==================== WSG Frame for WoW 1.12.1 (round Buttons) ====================
local wsgTexts = {
    "afr",
    "atunnel",
    "agy",
    "aroof",
    "aramp",
    "ewest",
    "emid",
    "eeast",
    "hfr",
    "htunnel",
    "hgy",
    "hroof",
    "hramp"
}

local wsgChatTexts = {
    "EFC = our flag room",
    "EFC = our tunnel",
    "EFC = our graveyard",
    "EFC = banana/roof",
    "EFC = our ramp",
    "EFC = west",
    "EFC = mid",
    "EFC = east",
    "EFC = enemy flag room",
    "EFC = enemy tunnel",
    "EFC = enemy graveyard",
    "EFC = enemy banana/roof",
    "EFC = enemy ramp"
}

local QuickCallFrameWSG = CreateFrame("Frame","QuickCallFrameWSG",UIParent)
QuickCallFrameWSG:SetClampedToScreen(true)

-- Quadratischer Frame
local frameSize = 230
QuickCallFrameWSG:SetWidth(frameSize)
QuickCallFrameWSG:SetHeight(frameSize)
QuickCallFrameWSG:EnableMouse(not QuickCallDB.locked_WSG)
QuickCallFrameWSG:SetBackdrop({bgFile="Interface\\AddOns\\QuickCall\\Warsong.tga", edgeFile="Interface/Tooltips/UI-Tooltip-Border", tile=false, edgeSize=16, insets={left=4,right=4,top=4,bottom=4}})
QuickCallFrameWSG:SetBackdropColor(1, 1, 1, 0.75)

-- Position & Drag
local x, y = ClampToScreen(QuickCallDB.posX_WSG, QuickCallDB.posY_WSG, QuickCallFrameWSG:GetWidth(), QuickCallFrameWSG:GetHeight())
QuickCallFrameWSG:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",x,y)
QuickCallFrameWSG:SetMovable(true)
QuickCallFrameWSG:RegisterForDrag("LeftButton")
QuickCallFrameWSG:SetScript("OnDragStart",function() if not QuickCallDB.locked_WSG then QuickCallFrameWSG:StartMoving() end end)
QuickCallFrameWSG:SetScript("OnDragStop",function()
    QuickCallFrameWSG:StopMovingOrSizing()
    local _, _, _, x, y = QuickCallFrameWSG:GetPoint()
    x, y = ClampToScreen(x, y, QuickCallFrameWSG:GetWidth(), QuickCallFrameWSG:GetHeight())
    QuickCallDB.posX_WSG = x
    QuickCallDB.posY_WSG = y
end)

-- Titel
local titleWSG = QuickCallFrameWSG:CreateFontString(nil,"OVERLAY","GameFontNormal")
titleWSG:SetPoint("TOP",QuickCallFrameWSG,"TOP",0,-12)
titleWSG:SetText("")
titleWSG:SetTextColor(1,1,0)
titleWSG:SetFont("Fonts\\ARIALN.TTF",15, "OUTLINE")

local btnSize = 12

-- Relative Positionen (0-1) statt feste Pixel
local buttonPositions = {
    [1] = {x = 101.3/220,  y = -28/220},  -- Flag Room Alliance
    [2] = {x = 106.5/220, y = -78/220},  -- Tunnel Alliance
    [3] = {x = 78/220, y = -60/220},  -- Graveyard Alliance
    [4] = {x = 122/220,  y = -35/220},  -- Banana/Roof Alliance
    [5] = {x = 120/220, y = -60/220},  -- Ramp Alliance
    [6] = {x = 80/220,  y = -110/220},  -- West
    [7] = {x = 110/220,  y = -110/220},  -- Mid
    [8] = {x = 140/220, y = -110/220},  -- East
    [9] = {x = 115/220, y = -193.5/220}, -- Flag Room Horde
    [10] = {x = 106.5/220, y = -140/220},  -- Tunnel Horde
    [11] = {x = 132/220, y = -160.4/220},  -- Graveyard Horde
    [12] = {x = 97/220, y = -187/220}, -- Banana/Roof Horde
    [13] = {x = 84/220, y = -160/220},  -- Ramp Horde
}

for i=1,table.getn(wsgChatTexts) do
    local btn = CreateFrame("Button", QuickCallFrameWSG:GetName().."Button"..i, QuickCallFrameWSG)
    btn:SetWidth(btnSize)
    btn:SetHeight(btnSize)
    btn:EnableMouse(true)

    -- Runde Textur
    btn.texture = btn:CreateTexture(nil, "ARTWORK")
    btn.texture:SetTexture("Interface\\AddOns\\QuickCall\\circleR.tga")
    btn.texture:SetAllPoints()
    btn.texture:SetAlpha(1)

    -- Highlight Textur für Mouseover
    btn.highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    btn.highlight:SetAllPoints()
    btn.highlight:SetTexture("Interface\\AddOns\\QuickCall\\circleG.tga")
    btn.highlight:SetVertexColor(0,1,0,0.6)

    -- Proportionale Position
    local pos = buttonPositions[i] or {x = 0.05, y = -0.15} 
    btn:SetPoint("TOPLEFT", QuickCallFrameWSG, "TOPLEFT",
        pos.x * QuickCallFrameWSG:GetWidth(),
        pos.y * QuickCallFrameWSG:GetHeight()
    )

    -- Klickfunktion MUSS innerhalb der Schleife sein
    btn:SetScript("OnClick", (function(idx)
        return function()
            if GetRealZoneText() ~= "Warsong Gulch" then
                DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffQuickCall:|r |cffff0000You are not in Warsong Gulch!|r")
            else
                SendChatMessage(wsgChatTexts[idx], "BATTLEGROUND")
            end
        end
    end)(i))
end

-- Lock Button am unteren Rand
local lockBtnWSG = CreateFrame("Button",QuickCallFrameWSG:GetName().."LockToggle",QuickCallFrameWSG,"UIPanelButtonTemplate")
lockBtnWSG:SetWidth(60)
lockBtnWSG:SetHeight(20)
lockBtnWSG:SetText(QuickCallDB.locked_WSG and "Unlock" or "Lock")
lockBtnWSG:SetPoint("BOTTOM",QuickCallFrameWSG,"BOTTOM",80,8)
lockBtnWSG:SetScript("OnClick",function() ToggleLock(QuickCallFrameWSG,false) end)
lockBtnWSG:SetFont("Fonts\\ARIALN.TTF",10, "OUTLINE")

QuickCallFrameWSG:Hide()

-- Slash Command für Maus-Debug am WSG-Frame
SLASH_WSGDEBUG1 = "/debug"
SlashCmdList["WSGDEBUG"] = function()
    local x, y = GetCursorPosition()       -- Bildschirmkoordinaten
    local scale = UIParent:GetEffectiveScale()
    x = x / scale
    y = y / scale
    local fx, fy = QuickCallFrameWSG:GetLeft(), QuickCallFrameWSG:GetBottom()
    local relX, relY = x - fx, y - fy
    DEFAULT_CHAT_FRAME:AddMessage(string.format("Mouse relative to WSG frame: %.1f / %.1f", relX, relY))
end


-- Visibility handler
local function UpdateVisibility()
    local zoneName = GetRealZoneText()
    QuickCallFrameAB:Hide()
    QuickCallFrameWSG:Hide()
    if zoneName=="Arathi Basin" and QuickCallDB.enabled_AB then
        QuickCallFrameAB:Show()
    elseif zoneName=="Warsong Gulch" and QuickCallDB.enabled_WSG then
        QuickCallFrameWSG:Show()
    end
end

local visEventFrame = CreateFrame("Frame")
visEventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
visEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
visEventFrame:SetScript("OnEvent",UpdateVisibility)

-- Update lastKnownBase on zone events
local function UpdateLastKnownBase()
    local zone = GetRealZoneText()
    local base = GetMinimapZoneText()
    if zone == "Arathi Basin" and baseNames[base] then
        lastKnownBase = base
    end
end

local baseEventFrame = CreateFrame("Frame")
baseEventFrame:RegisterEvent("ZONE_CHANGED")
baseEventFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
baseEventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
baseEventFrame:SetScript("OnEvent", UpdateLastKnownBase)

-- ==================== Slash Commands ====================
SLASH_QUICKCALL1 = "/qca"
SlashCmdList["QUICKCALL"] = function() if QuickCallFrameAB:IsShown() then QuickCallFrameAB:Hide() else QuickCallFrameAB:Show() end end

SLASH_QUICKCALLWSG1 = "/qcw"
SlashCmdList["QUICKCALLWSG"] = function() if QuickCallFrameWSG:IsShown() then QuickCallFrameWSG:Hide() else QuickCallFrameWSG:Show() end end

SLASH_QUICKCALLALL1 = "/qc"
SlashCmdList["QUICKCALLALL"] = function()
    local anyShown = QuickCallFrameAB:IsShown() or QuickCallFrameWSG:IsShown()
    if anyShown then QuickCallFrameAB:Hide() QuickCallFrameWSG:Hide() else QuickCallFrameAB:Show() QuickCallFrameWSG:Show() end
end

SLASH_QCSHORT1 = "/qcshort"
SlashCmdList["QCSHORT"] = function()
    QuickCallDB.useShortNames = true
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffQuickCall:|r Using |cff00ff00SHORT|r base names.")
end

SLASH_QCLONG1 = "/qclong"
SlashCmdList["QCLONG"] = function()
    QuickCallDB.useShortNames = false
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffQuickCall:|r Using |cffffff00LONG|r base names.")
end

SLASH_QCATOGGLE1 = "/qcatoggle"
SlashCmdList["QCATOGGLE"] = function()
    QuickCallDB.enabled_AB = not QuickCallDB.enabled_AB
    if QuickCallDB.enabled_AB then
        DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffQuickCall:|r Arathi Basin frame |cff00ff00ENABLED|r.")
        UpdateVisibility()
    else
        QuickCallFrameAB:Hide()
        DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffQuickCall:|r Arathi Basin frame |cffff0000DISABLED|r.")
    end
end

SLASH_QCWTOGGLE1 = "/qcwtoggle"
SlashCmdList["QCWTOGGLE"] = function()
    QuickCallDB.enabled_WSG = not QuickCallDB.enabled_WSG
    if QuickCallDB.enabled_WSG then
        DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffQuickCall:|r Warsong Gulch frame |cff00ff00ENABLED|r.")
        UpdateVisibility()
    else
        QuickCallFrameWSG:Hide()
        DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffQuickCall:|r Warsong Gulch frame |cffff0000DISABLED|r.")
    end
end
