local NAME, db = ...
ZoneSpec = db

local ZSVersion = tonumber(GetAddOnMetadata(NAME, "Version"))
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
    if debug then
        print("|cff22dd22ZS|r: ", ...)
    end
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
    local numTalents = #self.frame.talents
    for i = 1, numTalents do
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
    local numGlyphs = (#self.frame.glyphs - 1) * 2
    for i = glyphStart, numGlyphs, glyphIncr do
        --ZoneSpec:printDebug("showGlyphs", self.frame.glyphs, i)
        self.frame.glyphs[i]:Hide()
    end
    if show then 
        for i = glyphStart, numGlyphs, glyphIncr do
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
            if not talents[row] then
                --ZoneSpec:printDebug("create talent", row)
                talents[row] = CreateFrame("Button", nil, self.frame, "ZSIconTemplate")
                talents[row]:SetPoint("TOPLEFT", talents[row-1], "TOPRIGHT", 1, 0)
            end
            --ZoneSpec:printDebug("Row:", row, "Saved:", zone and zone.talents[row].id, "Equipped:", id)
            if (not zone) or (selected and zone.talents[row].id == id) then
                --Set current talent to button
                talents[row].id = id
                talents[row].texture:SetDesaturated(true)
                talents[row].texture:SetTexture(texture)
                talents[row].check:Show()
                --talentsShown = false
                break
            elseif (not selected and zone.talents[row].id == id) then
                --Set saved talent to button
                talents[row].id = zone.talents[row].id
                talents[row].texture:SetTexture(zone.talents[row].texture)
                talents[row].texture:SetDesaturated(false)
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
            if not glyphs[i] then
                --ZoneSpec:printDebug("create glyph", i)
                glyphs[i] = CreateFrame("Button", nil, self.frame, "ZSIconTemplate")
                glyphs[i]:SetPoint("TOPLEFT", glyphs[i-2], "TOPRIGHT", 1, 0)
            end
            --ZoneSpec:printDebug("Slot:", i, "Saved:", zone and zone.glyphs[i].spell, "Equipped:", glyphSpell)
            if (not zone) or (zone.glyphs[i].spell == glyphSpell) then
                --Set current glyph to button
                glyphs[i].spellID = glyphSpell
                glyphs[i].texture:SetTexture(path or [[Interface\Icons\INV_Misc_QuestionMark]])
                glyphs[i].texture:SetDesaturated(true)
                glyphs[i].check:Show()
                --glyphsShown = false
            else
                --Set saved glyph to button
                glyphs[i].spellID = zone.glyphs[i].spell
                glyphs[i].texture:SetTexture(zone.glyphs[i].icon)
                glyphs[i].texture:SetDesaturated(false)
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
function ZoneSpec:OnEvent(frame, event, ...)
    --ZoneSpec:printDebug("Event", event)
    if (event == "ADDON_LOADED") then
        local name = ...
        if name == NAME then
            -- ZoneSpec:printDebug(name, "loaded")
            ZoneSpecDB = ZoneSpecDB or defaults
            ZSChar = ZSChar or {}
            frame:SetPoint(ZoneSpecDB.point, ZoneSpecDB.xOfs, ZoneSpecDB.yOfs)
        elseif name == "Blizzard_TalentUI" then
            -- ZoneSpec:printDebug(name, "loaded")
            frame:UnregisterEvent("ADDON_LOADED")
            self:CreateSaveButton()
        end
    elseif (event == "BAG_UPDATE_DELAYED") then
        local name, count, icon, id = GetTalentClearInfo()
        --frame.reagent.text:SetText(count)
        if (ZoneSpecDB.isMovable) or (count and count <= 6) then
            frame.reagent:Show()
            -- ZoneSpec:printDebug(frame.texture:GetTexture())
            frame.reagent.texture:SetTexture(icon or "Interface\\Icons\\INV_Misc_Dust_02")
            frame.reagent.text:SetText(count or 0)
            frame.reagent.spellID = id
        else
            frame.reagent:Hide()
        end
    elseif (event == "PLAYER_LOGIN") then
        curZone = GetMinimapZoneText()
        curSpec = GetSpecialization()
        -- ZoneSpec:printDebug("PLAYER_LOGIN;", "curZone:", curZone, "curSpec:", curSpec)
        
        -- ZoneSpec:printDebug("Create character saved vars")
        self:SetZSChar()

        self:UpdateIcons()

        if ZoneSpecDB and ZoneSpecDB.isMovable then
            frame.anchor:Show()
            frame.reagent:Show()
        end
    else
        curZone = GetMinimapZoneText()
        curSpec = GetSpecialization()
        -- ZoneSpec:printDebug(event, ";", curZone, ";", ...)
        self:UpdateIcons()
    end
    --self[event](frame, ...)
end

function ZoneSpec_OnLoad(self)
    -- ZoneSpec:printDebug("Load")
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

    ZoneSpec.frame = self
end

-- Slash Commands
SLASH_ZONESPEC1, SLASH_ZONESPEC2 = "/zonespec", "/zs";
function SlashCmdList.ZONESPEC(msg, editBox)
    -- ZoneSpec:printDebug("msg:", msg)
    if msg == "toggle" then
        if ZoneSpecDB.isMovable then
            ZoneSpecDB.isMovable = false
            ZoneSpec:UpdateIcons()
            ZoneSpec:OnEvent(ZoneSpec.frame, "BAG_UPDATE_DELAYED")
            ZoneSpec.frame.anchor:Hide()
            -- ZoneSpec:printDebug("ZoneSpec is locked");
        else
            ZoneSpecDB.isMovable = true
            ZoneSpec:UpdateIcons()
            ZoneSpec:OnEvent(ZoneSpec.frame, "BAG_UPDATE_DELAYED")
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

