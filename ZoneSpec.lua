local NAME, db = ...
ZoneSpec = db

local ZSVersion = GetAddOnMetadata(NAME, "Version")
local debug = false

local curZone
local curSpec
local maxTalents

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
                    ["id"] = talentID,
                    ["icon"] = "icon\\path"
                }, -- ["1"]
            },
            ["glyphs"] = {

            }
        },
    },
}
]]
function ZoneSpec:printDebug(...)
    --if debug then
        print("|cff22dd22ZS|r: ", ...)
    --end
end

function ZoneSpec:CreateSaveButton()
    local btn = CreateFrame("Button", "ZoneSpecSaveButton", PlayerTalentFrame, "UIPanelButtonTemplate")
    btn:SetPoint("BOTTOMRIGHT", -4, 4)
    btn:SetSize(80, 22)
    btn:SetText(SAVE)
    if Aurora then
        Aurora[1].Reskin(btn)
    end

    btn:SetScript("OnClick", function()
        if not ZSChar[curSpec][curZone] then
            ZSChar[curSpec][curZone] = {}
        end

        -- ZoneSpec:printDebug("Save the current talent config")
        local talents = {}
        local activeSpec = GetActiveSpecGroup()
        for tier = 1, MAX_TALENT_TIERS do
            for column = 1, NUM_TALENT_COLUMNS do
                local id, name, texture, selected = GetTalentInfo(tier, column, activeSpec)
                if selected then
                    -- ZoneSpec:printDebug("Talent", i, "; Texture:", texture) --ZSChar
                    talents[tier] = {
                        id = id,
                        texture = texture,
                    }
                end
            end
        end
        ZSChar[curSpec][curZone]["talents"] = talents

        --[[  Glyph layout
           2
          3 1
         4 5 6
        ]]

        local glyphs = {}
        -- ZoneSpec:printDebug("Save the current glyph config")
        for i = 1, NUM_GLYPH_SLOTS do
            local _, glyphType, _, glyphSpell, texture = GetGlyphSocketInfo(i)
            -- ZoneSpec:printDebug("Glyph:", i, "; Texture:", texture) --ZSChar
            glyphs[i] = {
                glyphType = glyphType,
                icon = texture,
                spell = glyphSpell,
            }
        end
        ZSChar[curSpec][curZone]["glyphs"] = glyphs

        self:UpdateIcons()
        ZoneSpec:printDebug("Talent and Glyph data has been saved for", curZone, ".")
    end)
    hooksecurefunc("PlayerTalentFrameActivateButton_Update", function(numTalentGroups)
        local activeSpec = "spec"..GetActiveSpecGroup()
        if (activeSpec == PlayerTalentFrame.selectedPlayerSpec) then
            btn:Show()
        else
            btn:Hide()
        end
    end)
end

function ZoneSpec:showTalents(show)
    local numTalents = GetMaxTalentTier()
    for i = 1, 7 do
        --ZoneSpec:printDebug("talent"..i)
        self.frame.talents[i]:Hide()
    end
    if show then
        for i = 1, numTalents do
            self.frame.talents[i]:Show()
        end
    end
end

function ZoneSpec:showGlyphs(show)
    for i = 2, 6, 2 do
        --ZoneSpec:printDebug("showGlyphs", self.frame.glyphs, i)
        self.frame.glyphs[i]:Hide()
    end
    if show then
        for i = 2, 6, 2 do
            self.frame.glyphs[i]:Show()
        end
    end
end

function ZoneSpec:UpdateIcons()
    maxTalents = GetMaxTalentTier()
    -- ZoneSpec:printDebug("UpdateIcons;", curZone, curSpec)

    if (not curSpec) or (maxTalents == 0) then
        -- ZoneSpec:printDebug("UpdateIcons;", "nope")
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
    local activeSpec = GetActiveSpecGroup()
    local talents = self.frame.talents
    for row = 1, maxTalents do
        for column = 1, NUM_TALENT_COLUMNS do
            local id, _, texture, selected = GetTalentInfo(row, column, activeSpec)
            --ZoneSpec:printDebug("Row:", row, "Saved:", zone and zone.talents[row].id, "Equipped:", id)
            if (not zone) or (selected and zone.talents[row].id == id) then
                --ZoneSpec:printDebug("Button:", talents[row], "Icon:", talents[row].icon)
                --Set current talent to button
                talents[row].id = id
                talents[row].icon:SetTexture(texture)
                talents[row].icon:SetDesaturated(true)
                talents[row].check:Show()
                --talentsShown = false
                break
            elseif (not selected and zone.talents[row].id == id) then
                --Set saved talent to button
                talents[row].id = zone.talents[row].id
                talents[row].icon:SetTexture(zone.talents[row].texture)
                talents[row].icon:SetDesaturated(false)
                talents[row].check:Hide()
                talentsShown = true
                break
            else
                --ZoneSpec:printDebug("What?", row)
            end
        end
    end

    local glyphs = self.frame.glyphs
    for i = glyphStart, NUM_GLYPH_SLOTS, glyphIncr do
        local enabled, glyphType, _, glyphSpell, path = GetGlyphSocketInfo(i)
        if enabled then
            --ZoneSpec:printDebug("Slot:", i, "Saved:", zone and zone.glyphs[i].spell, "Equipped:", glyphSpell)
            if (not zone) or (zone.glyphs[i].spell == glyphSpell) then
                --Set current glyph to button
                glyphs[i].spellID = glyphSpell
                glyphs[i].icon:SetTexture(path or [[Interface\Icons\INV_Misc_QuestionMark]])
                glyphs[i].icon:SetDesaturated(true)
                glyphs[i].check:Show()
                --glyphsShown = false
            else
                --Set saved glyph to button
                glyphs[i].spellID = zone.glyphs[i].spell
                glyphs[i].icon:SetTexture(zone.glyphs[i].icon)
                glyphs[i].icon:SetDesaturated(false)
                glyphs[i].check:Hide()
                glyphsShown = true
            end
        end
    end

    -- ZoneSpec:printDebug("UpdateIcons;", "Show or Hide")
    self:showTalents((ZoneSpecDB.isMovable) or (talentsShown))
    self:showGlyphs((ZoneSpecDB.isMovable) or (glyphsShown))
end

function ZoneSpec:SetZSChar(isReset)
    -- ZoneSpec:printDebug("|cff22dd22ZS|r ZSChar:", ZSChar, "ZSChar[1]:", ZSChar[1])
    if isReset or (not ZSChar[1]) then
        for i = 1, GetNumSpecializations() do
            -- ZoneSpec:printDebug("ZSChar:", ZSChar, "i:", i)
            ZSChar[i] = {}
            -- ZoneSpec:printDebug("ZSChar:", ZSChar, "ZSChar[i]:", ZSChar[i])
        end
    end
end


---------------------------------
do
    local frame = CreateFrame("Frame", "ZSFrame", UIParent)
    frame:SetSize(200, 64)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")

    local anchor = CreateFrame("Button", nil, frame, "ChatConfigTabTemplate")
    anchor:SetScript("OnEnter", function(self, ...)
        --ZoneSpec:printDebug("OnEnter: Anchor")
        if ZoneSpecDB and ZoneSpecDB.isMovable then
            --ZoneSpec:printDebug("Config tooltip")
            GameTooltip:ClearAllPoints()
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR", 0 ,0)
            GameTooltip:SetText( 'Drag to move frame.\nUse "\/zs toggle" to lock placement.' )
            --ZoneSpec:printDebug("Show tooltip")
            GameTooltip:Show()
        end
    end)
    anchor:SetScript("OnLeave", function(self, ...)
        --ZoneSpec:printDebug("OnLeave: Anchor")
        GameTooltip:Hide()
    end)
    anchor:SetScript("OnMouseDown", function(self, ...)
        if ZoneSpecDB and ZoneSpecDB.isMovable then
            self:GetParent():StartMoving()
        end
    end)
    anchor:SetScript("OnMouseUp", function(self, ...)
        self:GetParent():StopMovingOrSizing()
        local point, relativeTo, relativePoint, xOfs, yOfs = self:GetParent():GetPoint()
        -- ZoneSpec:printDebug(point, relativeTo, relativePoint, xOfs, yOfs)
        ZoneSpecDB.point = point
        ZoneSpecDB.xOfs = xOfs
        ZoneSpecDB.yOfs = yOfs
    end)
    anchor:SetScript("OnHide", function(self, ...)
        self:GetParent():StopMovingOrSizing()
    end)
    frame.anchor = anchor

    frame.talents = {}
    for i = 1, 7 do
        local talent = CreateFrame("Button", nil, frame)
        talent:SetSize(32, 32)
        if i == 1 then
            talent:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 4, -1)
        else
            talent:SetPoint("TOPLEFT", frame.talents[i - 1], "TOPRIGHT", 1, 0)
        end
        local icon = talent:CreateTexture(nil, "BACKGROUND")
        icon:SetAllPoints()
        icon:SetTexture([[Interface\Icons\INV_Misc_QuestionMark]])
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        talent.icon = icon
        local check = talent:CreateTexture(nil, "BACKGROUND")
        check:SetPoint("BOTTOMRIGHT")
        check:SetAtlas("Tracker-Check", true)
        talent.check = check
        talent:SetScript("OnEnter", function(self, ...)
            --ZoneSpec:printDebug("OnEnter: Talent", i)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if self.id then
                GameTooltip:SetTalent(self.id)
            else
                GameTooltip:AddLine(GLYPH_EMPTY)
                GameTooltip:AddLine(GLYPH_EMPTY_DESC)
            end
            if ( self.extraTooltip ) then
                GameTooltip:AddLine(self.extraTooltip)
            end
            GameTooltip:Show()
        end)
        talent:SetScript("OnLeave", function(self, ...)
            --ZoneSpec:printDebug("OnLeave: Talent", i)
            GameTooltip:Hide()
        end)
        frame.talents[i] = talent
    end

    frame.glyphs = {}
    for i = 2, 6, 2 do
        local glyph = CreateFrame("Button", nil, frame)
        glyph:SetSize(32, 32)
        glyph:SetPoint("TOPLEFT", frame.talents[i/2], "BOTTOMLEFT", 0, -1)
        local icon = glyph:CreateTexture(nil, "BACKGROUND")
        icon:SetAllPoints()
        icon:SetTexture([[Interface\Icons\INV_Misc_QuestionMark]])
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        glyph.icon = icon
        local check = glyph:CreateTexture(nil, "BACKGROUND")
        check:SetPoint("BOTTOMRIGHT")
        check:SetAtlas("Tracker-Check", true)
        glyph.check = check
        glyph:SetScript("OnEnter", function(self, ...)
            --ZoneSpec:printDebug("OnEnter: Glyph", i)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetGlyph(i)
            if ( self.extraTooltip ) then
                GameTooltip:AddLine(self.extraTooltip)
            end
            GameTooltip:Show()
        end)
        glyph:SetScript("OnLeave", function(self, ...)
            --ZoneSpec:printDebug("OnLeave: Glyph", i)
            GameTooltip:Hide()
        end)
        frame.glyphs[i] = glyph
    end

    local reagent = CreateFrame("Button", nil, frame)
    reagent:SetSize(32, 32)
    reagent:SetPoint("TOPRIGHT", frame.talents[i], "TOPLEFT", -1, 0)
    local icon = reagent:CreateTexture(nil, "BACKGROUND")
    icon:SetAllPoints()
    icon:SetTexture([[Interface\Icons\INV_Misc_QuestionMark]])
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    reagent.icon = icon
    reagent:SetScript("OnEnter", function(self, ...)
        --ZoneSpec:printDebug("OnEnter: Glyph", i)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if self.spellID then
            GameTooltip:SetSpellByID(self.spellID, false, false, true)
        else
            GameTooltip:AddLine(GLYPH_EMPTY)
            GameTooltip:AddLine(GLYPH_EMPTY_DESC)
        end
        if ( self.extraTooltip ) then
            GameTooltip:AddLine(self.extraTooltip)
        end
        GameTooltip:Show()
    end)
    frame.reagent = reagent

    frame:RegisterEvent("ADDON_LOADED")
    frame:RegisterEvent("BAG_UPDATE_DELAYED")
    frame:RegisterEvent("PLAYER_LOGIN")
    frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    frame:RegisterEvent("ZONE_CHANGED")
    frame:RegisterEvent("ZONE_CHANGED_INDOORS")
    frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    frame:SetScript("OnEvent", function(self, event, ...)
        --ZoneSpec:printDebug("Event", event)
        if (event == "ADDON_LOADED") then
            local name = ...
            if name == NAME then
                -- ZoneSpec:printDebug(name, "loaded")
                ZoneSpecDB = ZoneSpecDB or defaults
                ZSChar = ZSChar or {}
                self:SetPoint(ZoneSpecDB.point, ZoneSpecDB.xOfs, ZoneSpecDB.yOfs)
            elseif name == "Blizzard_TalentUI" then
                -- ZoneSpec:printDebug(name, "loaded")
                self:UnregisterEvent("ADDON_LOADED")
                ZoneSpec:CreateSaveButton()
            end
        elseif (event == "BAG_UPDATE_DELAYED") then
            local name, count, icon, id = GetTalentClearInfo()
            --self.reagent.text:SetText(count)
            if (ZoneSpecDB.isMovable) or (count and count <= 6) then
                self.reagent:Show()
                -- ZoneSpec:printDebug(self.icon:GetTexture())
                self.reagent.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_Dust_02")
                self.reagent:SetText(count or 0)
                self.reagent.spellID = id
            else
                self.reagent:Hide()
            end
        elseif (event == "PLAYER_LOGIN") then
            curZone = GetMinimapZoneText()
            curSpec = GetSpecialization()
            -- ZoneSpec:printDebug("PLAYER_LOGIN;", "curZone:", curZone, "curSpec:", curSpec)

            -- ZoneSpec:printDebug("Create character saved vars")
            ZoneSpec:SetZSChar()

            ZoneSpec:UpdateIcons()

            if ZoneSpecDB and ZoneSpecDB.isMovable then
                self.anchor:Show()
                self.reagent:Show()
            end
        else
            curZone = GetMinimapZoneText()
            curSpec = GetSpecialization()
            -- ZoneSpec:printDebug(event, ";", curZone, ";", ...)
            ZoneSpec:UpdateIcons()
        end
        --self[event](self, ...)
    end)
    ZoneSpec.frame = frame
end



-- Slash Commands
SLASH_ZONESPEC1, SLASH_ZONESPEC2 = "/zonespec", "/zs";
function SlashCmdList.ZONESPEC(msg, editBox)
    -- ZoneSpec:printDebug("msg:", msg)
    if msg == "toggle" then
        if ZoneSpecDB.isMovable then
            ZoneSpecDB.isMovable = false
            ZoneSpec:UpdateIcons()
            ZoneSpec.frame:GetScript("OnEvent")(ZoneSpec.frame, "BAG_UPDATE_DELAYED")
            ZoneSpec.frame.anchor:Hide()
            -- ZoneSpec:printDebug("ZoneSpec is locked");
        else
            ZoneSpecDB.isMovable = true
            ZoneSpec:UpdateIcons()
            ZoneSpec.frame:GetScript("OnEvent")(ZoneSpec.frame, "BAG_UPDATE_DELAYED")
            ZoneSpec.frame.anchor:Show()
            -- ZoneSpec:printDebug("ZoneSpec is unlocked");
        end
    elseif msg == "clear" then
        -- Clear the talent and glyph data for the current location.
        ZSChar[curSpec][curZone] = nil
        ZoneSpec:UpdateIcons()
        print("|cff22dd22ZoneSpec|r: Data for", curZone, "has been cleared.");
    elseif msg == "reset" then
        -- ZoneSpec:printDebug("Reset character saved vars")
        ZoneSpec:SetZSChar(true)
        print("|cff22dd22ZoneSpec|r: Data for this character has been reset.");
    elseif msg == "debug" then
        -- ZoneSpec:printDebug("defaults.isMovable:", defaults.isMovable);
        -- ZoneSpec:printDebug("ZoneSpecDB.isMovable:", ZoneSpecDB.isMovable);
    else
        print("Usage: /zs |cff22dd22command|r");
        print("|cff22dd22toggle|r - Show/Hide the anchor frame to move it or lock it in place.")
        print("|cff22dd22clear|r - Clear saved talents and glyphs for the current area.")
        print("|cff22dd22reset|r - Reset all data for the current character.")
    end
end
