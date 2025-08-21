local ADDON, ns = ...

-- SavedVariables defaults
SecondLifeDB = SecondLifeDB or {}

------------------------------------------------------------
-- Helpers
------------------------------------------------------------
local function Clamp(v, min, max)
    if v < min then return min elseif v > max then return max else return v end
end

local function Trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

-- 0..1 -> RGB (Green at 1, Red at 0)
local function GradientRedYellowGreen(p)
    p = Clamp(p or 0, 0, 1)
    local r, g
    if p < 0.5 then
        r = 1
        g = p * 2
    else
        r = 2 * (1 - p)
        g = 1
    end
    return r, g, 0
end

------------------------------------------------------------
-- Frame (schlicht, wie RealmPhase) + StatusBar
------------------------------------------------------------
local f = CreateFrame("Frame", "SecondLifeFrame", UIParent, "BackdropTemplate")
ns.frame = f

local function EnsureDefaults()
    SecondLifeDB.point         = SecondLifeDB.point or "CENTER"
    SecondLifeDB.relativePoint = SecondLifeDB.relativePoint or "CENTER"
    SecondLifeDB.x             = tonumber(SecondLifeDB.x) or 0
    SecondLifeDB.y             = tonumber(SecondLifeDB.y) or 0
    SecondLifeDB.locked        = (SecondLifeDB.locked == true) -- default false
    SecondLifeDB.scale         = tonumber(SecondLifeDB.scale) or 1.0
end

local function SavePosition()
    local point, anchor, relPoint, x, y = f:GetPoint(1)
    SecondLifeDB.point, SecondLifeDB.relativePoint = point or "CENTER", relPoint or "CENTER"
    SecondLifeDB.x, SecondLifeDB.y = x or 0, y or 0
end

local function RestorePosition()
    f:ClearAllPoints()
    f:SetPoint(SecondLifeDB.point, UIParent, SecondLifeDB.relativePoint, SecondLifeDB.x, SecondLifeDB.y)
end

local function SetLocked(locked)
    SecondLifeDB.locked = not not locked
    f:EnableMouse(not SecondLifeDB.locked)
end
ns.SetLocked = SetLocked

-- Container
f:SetSize(180, 26)
f:SetFrameStrata("MEDIUM")
f:SetMovable(true)
f:SetClampedToScreen(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", function(self) if not SecondLifeDB.locked then self:StartMoving() end end)
f:SetScript("OnDragStop",  function(self) self:StopMovingOrSizing(); SavePosition() end)
f:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
})
f:SetBackdropColor(0, 0, 0, 0.45)
f:SetBackdropBorderColor(0, 0, 0, 1)

-- StatusBar (füllt sich RECHTS -> LINKS dank ReverseFill)
local bar = CreateFrame("StatusBar", nil, f)
bar:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
bar:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
bar:SetMinMaxValues(0, 1)
bar:SetValue(1)
bar:SetOrientation("HORIZONTAL")
-- Richtung sicherstellen: rechts -> links
if bar.SetReverseFill then
    bar:SetReverseFill(true)
else
    -- Fallback für Clients ohne ReverseFill:
    local tex = bar:GetStatusBarTexture()
    tex:ClearAllPoints()
    tex:SetPoint("RIGHT", bar, "RIGHT")
    tex:SetPoint("TOP",   bar, "TOP")
    tex:SetPoint("BOTTOM",bar, "BOTTOM")
end

-- dunkler Hintergrund hinter der Füllung
local barBG = bar:CreateTexture(nil, "BACKGROUND")
barBG:SetAllPoints(true)
barBG:SetColorTexture(0, 0, 0, 0.25)

-- Prozent-Text
local text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
text:SetPoint("CENTER", bar, "CENTER", 0, 0)
text:SetJustifyH("CENTER")
text:SetJustifyV("MIDDLE")
text:SetText("100%")
text:SetShadowColor(0, 0, 0, 0.8)
text:SetShadowOffset(1, -1)

-- kleiner Hinweis unten, wenn entsperrt
local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
hint:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -4, 4)
hint:SetText("drag")
hint:Hide()

------------------------------------------------------------
-- Health update
------------------------------------------------------------
local function GetPlayerPercent()
    local maxHP = UnitHealthMax("player") or 0
    local hp = UnitHealth("player") or 0
    if maxHP <= 0 then return 0 end
    local p = hp / maxHP
    if UnitIsDeadOrGhost("player") then p = 0 end
    return Clamp(p, 0, 1)
end

local function UpdateUI()
    local p = GetPlayerPercent()
    local r, g, b = GradientRedYellowGreen(p)

    -- StatusBar füllen + färben
    bar:SetValue(p)
    bar:SetStatusBarColor(r, g, b, 0.95)

    -- Prozenttext
    local percent = math.floor(p * 100 + 0.5)
    text:SetText(percent .. "%")

    -- Textkontrast anhand Helligkeit der Bar
    local luma = 0.299 * r + 0.587 * g + 0.114 * b
    if luma > 0.6 then
        text:SetTextColor(0, 0, 0, 1)
    else
        text:SetTextColor(0, 0, 0, 1)
    end
end
ns.Update = UpdateUI

------------------------------------------------------------
-- Events
------------------------------------------------------------
local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterUnitEvent("UNIT_HEALTH", "player")
ev:RegisterUnitEvent("UNIT_MAXHEALTH", "player")

ev:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON then
        EnsureDefaults()
        f:SetScale(SecondLifeDB.scale or 1.0)
        RestorePosition()
        SetLocked(SecondLifeDB.locked)
        if not SecondLifeDB.locked then hint:Show() else hint:Hide() end
        UpdateUI()
    elseif event == "PLAYER_ENTERING_WORLD" then
        UpdateUI()
    else
        UpdateUI()
    end
end)

------------------------------------------------------------
-- Slash commands
------------------------------------------------------------
SLASH_SECONDLIFE1 = "/secondlife"
SLASH_SECONDLIFE2 = "/sl"
SlashCmdList["SECONDLIFE"] = function(msg)
    msg = Trim((msg or ""):lower())
    local cmd, rest = msg:match("^(%S+)%s*(.*)$")
    cmd = cmd or ""

    if cmd == "" or cmd == "help" or cmd == "?" then
        print("|cff00ff98SecondLife|r – Befehle:")
        print("  |cffffffff/sl lock|r   – Fenster sperren")
        print("  |cffffffff/sl unlock|r – Fenster entsperren & verschieben")
        print("  |cffffffff/sl reset|r  – Position auf Mitte zurücksetzen")
        print("  |cffffffff/sl scale <zahl>|r – Größe (z.B. 0.9, 1.2)")
        return
    end

    if cmd == "lock" then
        SetLocked(true);  hint:Hide()
        print("|cff00ff98SecondLife:|r Fenster gesperrt.")
    elseif cmd == "unlock" then
        SetLocked(false); hint:Show()
        print("|cff00ff98SecondLife:|r Fenster entsperrt (mit linker Maustaste ziehen).")
    elseif cmd == "reset" then
        SecondLifeDB.point, SecondLifeDB.relativePoint, SecondLifeDB.x, SecondLifeDB.y = "CENTER", "CENTER", 0, 0
        RestorePosition()
        print("|cff00ff98SecondLife:|r Position zurückgesetzt.")
    elseif cmd == "scale" then
        local n = tonumber(rest)
        if n then
            n = Clamp(n, 0.5, 3.0)
            SecondLifeDB.scale = n
            f:SetScale(n)
            print(string.format("|cff00ff98SecondLife:|r Scale = %.2f", n))
        else
            print("|cff00ff98SecondLife:|r Bitte eine Zahl angeben, z.B. |cffffffff/sl scale 1.1|r")
        end
    else
        print("|cff00ff98SecondLife:|r Unbekannter Befehl. Tippe |cffffffff/sl help|r.")
    end
end
