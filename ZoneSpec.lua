local NAME, db = ...
ZoneSpec = db

local ZSVersion = tonumber(GetAddOnMetadata(NAME, "Version"))

local zone
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
        [zone] = { --This will be the zone name
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
        if not ZSChar[curSpec][zone] then
            ZSChar[curSpec][zone] = {}
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
        ZSChar[curSpec][zone]["talents"] = talents

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
        ZSChar[curSpec][zone]["glyphs"] = glyphs

        print("|cff22dd22ZoneSpec|r: Talent and Glyph data has been saved for", zone, ".")
        self:UpdateInfo()
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

function ZoneSpec:showTalents(show)
    if show then 
        ZSFrame.talent1:Show()
        ZSFrame.talent2:Show()
        ZSFrame.talent3:Show()
        ZSFrame.talent4:Show()
        ZSFrame.talent5:Show()
        ZSFrame.talent6:Show()
    else
        ZSFrame.talent1:Hide()
        ZSFrame.talent2:Hide()
        ZSFrame.talent3:Hide()
        ZSFrame.talent4:Hide()
        ZSFrame.talent5:Hide()
        ZSFrame.talent6:Hide()
    end
end

function ZoneSpec:showGlyphs(show)
    if show then 
        ZSFrame.glyph2:Show()
        ZSFrame.glyph4:Show()
        ZSFrame.glyph6:Show()
    else
        ZSFrame.glyph2:Hide()
        ZSFrame.glyph4:Hide()
        ZSFrame.glyph6:Hide()
    end
end

function ZoneSpec:UpdateInfo()
    zone = GetMinimapZoneText()
    curSpec = GetSpecialization()
    -- printDebug("UpdateInfo;", zone, curSpec)

    local talentsShown = false
    local glyphsShown = false
    local spec = ZSChar[curSpec] --or false

    if (not curSpec) or (GetMaxTalentTier() == 0) then 
        -- printDebug("UpdateInfo;", "nope")
        self:showTalents((ZoneSpec.db.isMovable) or (talentsShown))
        self:showGlyphs((ZoneSpec.db.isMovable) or (glyphsShown))
        return
    end

    --show when new talent tier is available
    for i = 1, GetMaxTalentTier() do
        local _, talent = GetTalentRowSelectionInfo(i)
        local icon = _G["ZSFrame"]["talent"..i]
        icon:Show()
        if (not spec[zone]) or (spec[zone].talents[i].selected == talent) then
            icon.ID = talent
            icon.texture:SetTexture(select(2, GetTalentInfo(talent)))
            icon.texture:SetDesaturated(1)
        else
            icon.ID = spec[zone].talents[i].selected
            icon.texture:SetTexture(spec[zone].talents[i].icon)
            icon.texture:SetDesaturated(0)
            talentsShown = true
        end
    end

    for i = glyphStart, NUM_GLYPH_SLOTS, glyphIncr do
        local _, glyphType, _, glyphSpell, path = GetGlyphSocketInfo(i)
        -- printDebug("spell:", spec[zone].glyphs[i].spell, "glyphSpell:", glyphSpell)
        local icon = _G["ZSFrame"]["glyph"..i]
        icon:Show()
        if (not spec[zone]) or (spec[zone].glyphs[i].spell == glyphSpell) then
            icon.spellID = glyphSpell
            icon.texture:SetTexture(path)
            icon.texture:SetDesaturated(1)
        else
            icon.spellID = spec[zone].glyphs[i].spell
            icon.texture:SetTexture(spec[zone].glyphs[i].icon)
            icon.texture:SetDesaturated(0)
            glyphsShown = true
        end
    end

    -- printDebug("UpdateInfo;", "Show or Hide")
    self:showTalents((ZoneSpec.db.isMovable) or (talentsShown))
    self:showGlyphs((ZoneSpec.db.isMovable) or (glyphsShown))
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



function ZoneSpec:OnEvent(self, event, ...)
    -- printDebug("Event", event)
    if (event == "ADDON_LOADED") then
        name = ...
        if name == NAME then
            -- printDebug(name, "loaded")

            ZoneSpec.db = ZoneSpecDB or defaults
            if tonumber(ZoneSpec.db.version) < 1.5 then
                ZoneSpec.db.point = ZoneSpec.db.anchor
                ZoneSpec.db.anchor = nil
                ZoneSpec.db.version = ZSVersion
            else
                ZoneSpec.db.version = ZSVersion
            end
            
            ZSChar = ZSChar or {}
            self:SetPoint(ZoneSpec.db.point, ZoneSpec.db.xOfs, ZoneSpec.db.yOfs)
        elseif name == "Blizzard_TalentUI" then
            -- printDebug(name, "loaded")
            self:UnregisterEvent("ADDON_LOADED")
            CreateSaveButton()
        end
    elseif (event == "BAG_UPDATE_DELAYED") then
        local name, count, icon = GetTalentClearInfo()
        --self.reagent.text:SetText(count)
        if (ZoneSpec.db.isMovable) or (count and count <= 6) then
            self.reagent:Show()
            -- printDebug(self.texture:GetTexture())
            self.reagent.texture:SetTexture(icon or "Interface\\Icons\\INV_Misc_Dust_02")
            self.reagent.text:SetText(count or 0)
        else
            self.reagent:Hide()
        end
    elseif (event == "PLAYER_LOGIN") then
        zone = GetMinimapZoneText()
        curSpec = GetSpecialization()
        -- printDebug("PLAYER_LOGIN;", "zone:", zone, "curSpec:", curSpec)
        
        -- printDebug("Create character saved vars")
        ZoneSpec:SetZSChar()

        ZoneSpec:UpdateInfo()

        if ZoneSpec.db and ZoneSpec.db.isMovable then
            self.anchor:Show()
            self.reagent:Show()
        end
    else
        zone = GetMinimapZoneText()
        -- printDebug(event, ";", zone, ";", ...)
        ZoneSpec:UpdateInfo()
    end
    --ZoneSpec[event](self, ...)
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
        if ZoneSpec.db and ZoneSpec.db.isMovable then
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
        if ZoneSpec.db and ZoneSpec.db.isMovable then
            self:GetParent():StartMoving()
        end
    end)
    self.anchor:SetScript("OnMouseUp", function(self)
        self:GetParent():StopMovingOrSizing()
        local point, relativeTo, relativePoint, xOfs, yOfs = self:GetParent():GetPoint()
        -- printDebug(point, relativeTo, relativePoint, xOfs, yOfs)
        ZoneSpec.db.point = point
        ZoneSpec.db.xOfs = xOfs
        ZoneSpec.db.yOfs = yOfs
    end)
    self.anchor:SetScript("OnHide", function(self)
        self:GetParent():StopMovingOrSizing()
    end)
end

-- Slash Commands
SLASH_ZONESPEC1, SLASH_ZONESPEC2 = "/zonespec", "/zs";
function SlashCmdList.ZONESPEC(msg, editBox)
    -- printDebug("msg:", msg)
    if msg == "toggle" then
        if ZoneSpec.db.isMovable then
            ZoneSpec.db.isMovable = false
            ZoneSpec:UpdateInfo()
            ZoneSpec:OnEvent(ZSFrame, "BAG_UPDATE_DELAYED")
            ZSFrame.anchor:Hide()
            -- printDebug("ZoneSpec is locked");
        else
            ZoneSpec.db.isMovable = true
            ZoneSpec:UpdateInfo()
            ZoneSpec:OnEvent(ZSFrame, "BAG_UPDATE_DELAYED")
            ZSFrame.anchor:Show()
            -- printDebug("ZoneSpec is unlocked");
        end
    elseif msg == "clear" then
        -- Clear the talent and glyph data for the current location.
        ZSChar[curSpec][zone] = nil
        ZoneSpec:UpdateInfo()
        print("|cff22dd22ZoneSpec|r: Data for", zone, "has been cleared.");
    elseif msg == "reset" then
        -- printDebug("Reset character saved vars")
        ZoneSpec:SetZSChar(true)
        print("|cff22dd22ZoneSpec|r: Data for this character has been reset.");
    elseif msg == "debug" then
        -- printDebug("defaults.isMovable:", defaults.isMovable);
        -- printDebug("ZoneSpec.db.isMovable:", ZoneSpec.db.isMovable);
    else
        print("Usage: /zs |cff22dd22command|r");
        print("|cff22dd22toggle|r - Show/Hide the anchor frame to move it or lock it in place.")
        print("|cff22dd22clear|r - Clear saved talents and glyphs for the current area.")
        print("|cff22dd22reset|r - Reset all data for the current character.")
    end
end

