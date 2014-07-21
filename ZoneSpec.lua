local NAME, db = ...
ZoneSpec = db

local ZSVersion = tonumber(GetAddOnMetadata(NAME, "Version"))

local curZone
local curSpec

--Constants
local TOTAL_NUM_TALENTS = GetNumTalents()

local glyphIncr = 2
local glyphStart = 2

local defaults = {
    version = ZSVersion,
    point = "CENTER",
    yOfs = 0,
    xOfs = 0,
    isMovable = true,
    trackMinor = false,
}

--[[
ZSChar = {
    { -- first spec
        [curZone] = { --This will be the curZone name
            ["talents"] = {
                {
                    ["selected"] = 2,
                    ["icon"] = "icon\\path"
                }, -- ["1"]
            },
            ["glyphs"] = {
                
            }
        },
    },
}
]]
local function printDebug(...)
    print("|cff22dd22ZS|r", ...)
end

function ZoneSpec:CreateSaveButton()
    local btn = CreateFrame("Button", "ZoneSpecSaveButton", PlayerTalentFrame, "UIPanelButtonTemplate")
    btn:SetPoint("BOTTOMRIGHT", -4, 4)
    btn:SetSize(80, 22)
    btn:SetText(SAVE)

    btn:SetScript("OnClick", function()
        if not ZSChar[curSpec][curZone] then
            ZSChar[curSpec][curZone] = {}
        end

        local talents = {}
        -- printDebug("Save the current talent config")
        for i = 1, TOTAL_NUM_TALENTS do
            local name, texture, tier, _, selected = GetTalentInfo(i)
            if selected then
                -- printDebug("Talent", i, "; Texture:", texture) --ZSChar
                talents[tier] = {
                    selected = i,
                    icon = texture,
                }
            end
        end
        ZSChar[curSpec][curZone]["talents"] = talents

        --[[  Glyph layout
           2
          3 1
         4 5 6
        ]]

        local glyphs = {}
        -- printDebug("Save the current glyph config")
        for i = 1, NUM_GLYPH_SLOTS do
            local _, glyphType, _, glyphSpell, texture = GetGlyphSocketInfo(i)
            -- printDebug("Glyph:", i, "; Texture:", texture) --ZSChar
            glyphs[i] = {
                glyphType = glyphType,
                icon = texture,
                spell = glyphSpell,
            }
        end
        ZSChar[curSpec][curZone]["glyphs"] = glyphs

        self:UpdateIcons()
        print("|cff22dd22ZoneSpec|r: Talent and Glyph data has been saved for", curZone, ".")
    end)
    hooksecurefunc("PlayerTalentFrameActivateButton_Update", function(numTalentGroups)
        local activeTalentGroup = "spec"..GetActiveSpecGroup()
        if (activeTalentGroup == PlayerTalentFrame.selectedPlayerSpec) then
            btn:Show()
        else
            btn:Hide()
        end
    end)
end

function ZoneSpec:showTalents(show, maxTalents)
    for i = 1, MAX_NUM_TALENT_TIERS do
        --printDebug("talent"..i)
        self.frame["talent"..i]:Hide()
    end
    if show then 
        for i = 1, (maxTalents or MAX_NUM_TALENT_TIERS) do
            self.frame["talent"..i]:Show()
        end
    end
end

function ZoneSpec:showGlyphs(show)
    for i = glyphStart, NUM_GLYPH_SLOTS, glyphIncr do
        --printDebug("glyph"..i)
        self.frame["glyph"..i]:Hide()
    end
    if show then 
        for i = glyphStart, NUM_GLYPH_SLOTS, glyphIncr do
            self.frame["glyph"..i]:Show()
        end
    end
end

function ZoneSpec:UpdateIcons()
    maxTalents = GetMaxTalentTier()
    -- printDebug("UpdateIcons;", curZone, curSpec)

    if (not curSpec) or (maxTalents == 0) then 
        -- printDebug("UpdateIcons;", "nope")
        self:showTalents((ZoneSpecDB.isMovable) or (talentsShown))
        self:showGlyphs((ZoneSpecDB.isMovable) or (glyphsShown))
        return
    end

    local talentsShown = false
    local glyphsShown = false
    local zone = ZSChar[curSpec][curZone] --or false

    if zone then
        if (not zone.talents[1]) or (not zone.glyphs[1]) then
            zone = nil
        end
    end

    --show when new talent tier is available
    for i = 1, maxTalents do
        local _, talent = GetTalentRowSelectionInfo(i)
        local icon = self.frame["talent"..i]
        icon:Show()
        if (not zone) or (zone.talents[i].selected == talent) then
            --set the ID for the tooltip
            icon.ID = talent
            if talent then
                icon.texture:SetTexture(select(2, GetTalentInfo(talent)))
            else
                icon.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            end
            icon.texture:SetDesaturated(1)
        else
            icon.ID = zone.talents[i].selected
            icon.texture:SetTexture(zone.talents[i].icon)
            icon.texture:SetDesaturated(0)
            talentsShown = true
        end
    end

    for i = glyphStart, NUM_GLYPH_SLOTS, glyphIncr do
        local _, glyphType, _, glyphSpell, path = GetGlyphSocketInfo(i)
        -- printDebug("spell:", zone.glyphs[i].spell, "glyphSpell:", glyphSpell)
        local icon = self.frame["glyph"..i]
        icon:Show()
        if (not zone) or (zone.glyphs[i].spell == glyphSpell) then
            --set the ID for the tooltip
            icon.spellID = glyphSpell
            icon.texture:SetTexture(path)
            icon.texture:SetDesaturated(1)
        else
            icon.spellID = zone.glyphs[i].spell
            icon.texture:SetTexture(zone.glyphs[i].icon)
            icon.texture:SetDesaturated(0)
            glyphsShown = true
        end
    end

    -- printDebug("UpdateIcons;", "Show or Hide")
    self:showTalents((ZoneSpecDB.isMovable) or (talentsShown), maxTalents)
    self:showGlyphs((ZoneSpecDB.isMovable) or (glyphsShown))
end

function ZoneSpec:SetZSChar(isReset)
    -- printDebug("|cff22dd22ZS|r ZSChar:", ZSChar, "ZSChar[1]:", ZSChar[1])
    if isReset or (not ZSChar[1]) then
        for i = 1, GetNumSpecializations() do
            -- printDebug("ZSChar:", ZSChar, "i:", i)
            ZSChar[i] = {}
            -- printDebug("ZSChar:", ZSChar, "ZSChar[i]:", ZSChar[i])
        end
    end
end



function ZoneSpec:OnEvent(frame, event, ...)
    -- printDebug("Event", event)
    if (event == "ADDON_LOADED") then
        name = ...
        if name == NAME then
            -- printDebug(name, "loaded")
            ZoneSpecDB = ZoneSpecDB or defaults
            ZSChar = ZSChar or {}
            frame:SetPoint(ZoneSpecDB.point, ZoneSpecDB.xOfs, ZoneSpecDB.yOfs)
        elseif name == "Blizzard_TalentUI" then
            -- printDebug(name, "loaded")
            frame:UnregisterEvent("ADDON_LOADED")
            self:CreateSaveButton()
        end
    elseif (event == "BAG_UPDATE_DELAYED") then
        local name, count, icon = GetTalentClearInfo()
        --frame.reagent.text:SetText(count)
        if (ZoneSpecDB.isMovable) or (count and count <= 6) then
            frame.reagent:Show()
            -- printDebug(frame.texture:GetTexture())
            frame.reagent.texture:SetTexture(icon or "Interface\\Icons\\INV_Misc_Dust_02")
            frame.reagent.text:SetText(count or 0)
        else
            frame.reagent:Hide()
        end
    elseif (event == "PLAYER_LOGIN") then
        curZone = GetMinimapZoneText()
        curSpec = GetSpecialization()
        -- printDebug("PLAYER_LOGIN;", "curZone:", curZone, "curSpec:", curSpec)
        
        -- printDebug("Create character saved vars")
        self:SetZSChar()

        self:UpdateIcons()

        if ZoneSpecDB and ZoneSpecDB.isMovable then
            frame.anchor:Show()
            frame.reagent:Show()
        end
    else
        curZone = GetMinimapZoneText()
        curSpec = GetSpecialization()
        -- printDebug(event, ";", curZone, ";", ...)
        self:UpdateIcons()
    end
    --self[event](frame, ...)
end

function ZoneSpec_OnLoad(self)
    -- printDebug("Load")

    self.anchor:ClearAllPoints()
    self.anchor:SetPoint("TOPLEFT", 0, 0)

    self:RegisterForDrag("LeftButton")

    self:RegisterEvent("ADDON_LOADED")
    self:RegisterEvent("BAG_UPDATE_DELAYED")
    self:RegisterEvent("PLAYER_LOGIN")
    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    self:RegisterEvent("ZONE_CHANGED")
    self:RegisterEvent("ZONE_CHANGED_INDOORS")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")


    self:SetScript("OnEvent", function(self, event, ...)
        ZoneSpec:OnEvent(self, event, ...)
    end)

    self.anchor:SetScript("OnEnter", function(self, motion)
        -- printDebug("OnEnter: Anchor")
        if ZoneSpecDB and ZoneSpecDB.isMovable then
            -- printDebug("Config tooltip")
            GameTooltip:ClearAllPoints()
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR", 0 ,0)
            GameTooltip:SetText( 'Drag to move frame.\nUse "\/zs toggle" to lock placement.' )
            -- printDebug("Show tooltip")
            GameTooltip:Show()
        end
    end)
    self.anchor:SetScript("OnLeave", function(self, motion)
        -- printDebug("OnLeave: Anchor")
        GameTooltip:Hide()
    end)
    self.anchor:SetScript("OnMouseDown", function(self, button)
        if ZoneSpecDB and ZoneSpecDB.isMovable then
            self:GetParent():StartMoving()
        end
    end)
    self.anchor:SetScript("OnMouseUp", function(self)
        self:GetParent():StopMovingOrSizing()
        local point, relativeTo, relativePoint, xOfs, yOfs = self:GetParent():GetPoint()
        -- printDebug(point, relativeTo, relativePoint, xOfs, yOfs)
        ZoneSpecDB.point = point
        ZoneSpecDB.xOfs = xOfs
        ZoneSpecDB.yOfs = yOfs
    end)
    self.anchor:SetScript("OnHide", function(self)
        self:GetParent():StopMovingOrSizing()
    end)

    ZoneSpec.frame = self
end

-- Slash Commands
SLASH_ZONESPEC1, SLASH_ZONESPEC2 = "/zonespec", "/zs";
function SlashCmdList.ZONESPEC(msg, editBox)
    -- printDebug("msg:", msg)
    if msg == "toggle" then
        if ZoneSpecDB.isMovable then
            ZoneSpecDB.isMovable = false
            ZoneSpec:UpdateIcons()
            ZoneSpec:OnEvent(ZoneSpec.frame, "BAG_UPDATE_DELAYED")
            ZoneSpec.frame.anchor:Hide()
            -- printDebug("ZoneSpec is locked");
        else
            ZoneSpecDB.isMovable = true
            ZoneSpec:UpdateIcons()
            ZoneSpec:OnEvent(ZoneSpec.frame, "BAG_UPDATE_DELAYED")
            ZoneSpec.frame.anchor:Show()
            -- printDebug("ZoneSpec is unlocked");
        end
    elseif msg == "clear" then
        -- Clear the talent and glyph data for the current location.
        ZSChar[curSpec][curZone] = nil
        ZoneSpec:UpdateIcons()
        print("|cff22dd22ZoneSpec|r: Data for", curZone, "has been cleared.");
    elseif msg == "reset" then
        -- printDebug("Reset character saved vars")
        ZoneSpec:SetZSChar(true)
        print("|cff22dd22ZoneSpec|r: Data for this character has been reset.");
    elseif msg == "debug" then
        -- printDebug("defaults.isMovable:", defaults.isMovable);
        -- printDebug("ZoneSpecDB.isMovable:", ZoneSpecDB.isMovable);
    else
        print("Usage: /zs |cff22dd22command|r");
        print("|cff22dd22toggle|r - Show/Hide the anchor frame to move it or lock it in place.")
        print("|cff22dd22clear|r - Clear saved talents and glyphs for the current area.")
        print("|cff22dd22reset|r - Reset all data for the current character.")
    end
end

