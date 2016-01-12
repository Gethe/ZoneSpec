local ADDON_NAME, ZoneSpec = ...
local ZSVersion = GetAddOnMetadata(ADDON_NAME, "Version")

-- Lua Globals --
local _G = _G
local tostring, select, print = _G.tostring, _G.select, _G.print

-- WoW Globals --
local CreateFrame, hooksecurefunc, GetInstanceLockTimeRemainingEncounter, GetGlyphSocketInfo = _G.CreateFrame, _G.hooksecurefunc, _G.GetInstanceLockTimeRemainingEncounter, _G.GetGlyphSocketInfo
local GetActiveSpecGroup, GetTalentInfo, GetMaxTalentTier, GetGlyphSocketInfo = _G.GetActiveSpecGroup, _G.GetTalentInfo, _G.GetMaxTalentTier, _G.GetGlyphSocketInfo
local MAX_TALENT_TIERS, NUM_TALENT_COLUMNS, NUM_GLYPH_SLOTS = _G.MAX_TALENT_TIERS, _G.NUM_TALENT_COLUMNS, _G.NUM_GLYPH_SLOTS
local PlayerTalentFrame, GameTooltip = _G.PlayerTalentFrame, _G.GameTooltip

-- Libs --
local HBD = LibStub("HereBeDragons-1.0")


local debugger, debug do
    local LTD = true
    function debug(...)
        if not debugger and LTD then
            LTD = _G.LibStub("LibTextDump-1.0")
            if LTD then
                debugger = LTD:New("ZoneSpec Debug Output", 640, 480)
            else
                LTD = false
                return
            end
        end
        local time = _G.date("%H:%M:%S")
        local text = ("[%s]"):format(time)
        for i = 1, select("#", ...) do
            local arg = select(i, ...)
            if (arg ~= nil) then
                arg = tostring(arg)
            else
                arg = "nil"
            end
            text = text .. "     " .. arg
        end
        debugger:AddLine(text)
    end
end
local function zsPrint(...)
    print("|cff22dd22ZoneSpec|r:", ...)
end

local ZSChar, ZoneSpecDB
local talentIcons, glyphIcons = {}, {}
local curZone, curSpec
local multiBossArea
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
local multiBossAreas = {
    [886] = { -- Terrace of Endless Spring
        [0] = {
            ["left"] = 0,
            1409, -- Protectors of the Endless
            --1505 -- Tsulong
        }
    },
    [1026] = { -- Hellfire Citadel
        [1] = { -- Floor 1: The Iron Bulwark
            1778, -- Hellfire Assault
            --1785 -- Iron Reaver
        }
    },
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

function ZoneSpec:CreateSaveButton()
    local btn = CreateFrame("Button", "ZoneSpecSaveButton", PlayerTalentFrame, "UIPanelButtonTemplate")
    btn:SetPoint("BOTTOMRIGHT", -4, 4)
    btn:SetSize(80, 22)
    btn:SetText(_G.SAVE)
    if _G.Aurora then
        _G.Aurora[1].Reskin(btn)
    end

    btn:SetScript("OnClick", function()
        if not ZSChar[curSpec][curZone] then
            ZSChar[curSpec][curZone] = {}
        end

        debug("Save the current talent config")
        local talents = {}
        local activeSpec = GetActiveSpecGroup()
        for tier = 1, MAX_TALENT_TIERS do
            for column = 1, NUM_TALENT_COLUMNS do
                local id, name, texture, selected = GetTalentInfo(tier, column, activeSpec)
                if selected then
                    debug("Talent", id, "; Texture:", texture) --ZSChar
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
        debug("Save the current glyph config")
        for i = 1, NUM_GLYPH_SLOTS do
            local _, glyphType, _, glyphSpell, texture = GetGlyphSocketInfo(i)
            debug("Glyph:", i, "; Texture:", texture) --ZSChar
            glyphs[i] = {
                glyphType = glyphType,
                icon = texture,
                spell = glyphSpell,
            }
        end
        ZSChar[curSpec][curZone]["glyphs"] = glyphs

        self:UpdateIcons()
        zsPrint("Talent and Glyph data has been saved for", curZone, ".")
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
        debug("talent"..i)
        talentIcons[i]:Hide()
    end
    if show then
        for i = 1, numTalents do
            talentIcons[i]:Show()
        end
    end
end

function ZoneSpec:showGlyphs(show)
    for i = 2, 6, 2 do
        debug("showGlyphs", glyphIcons, i)
        glyphIcons[i]:Hide()
    end
    if show then
        for i = 2, 6, 2 do
            glyphIcons[i]:Show()
        end
    end
end

function ZoneSpec:UpdateIcons()
    maxTalents = GetMaxTalentTier()
    debug("UpdateIcons;", curZone, curSpec)

    local talentsShown = false
    local glyphsShown = false
    if (not curSpec) or (maxTalents == 0) then
        debug("UpdateIcons;", "nope")
        self:showTalents((ZoneSpecDB.isMovable) or (talentsShown))
        self:showGlyphs((ZoneSpecDB.isMovable) or (glyphsShown))
        return
    end

    local zone = ZSChar[curSpec][curZone] --or false

    if zone then
        if (not zone.talents[1]) or (not zone.glyphs[1]) then
            zone = nil
        end
    end

    --show when new talent tier is available
    local activeSpec = GetActiveSpecGroup()
    for row = 1, maxTalents do
        if zone and not zone.talents[row] then
            debug("Missing Row:", row)
            zone.talents[row] = {}
        end
        for column = 1, NUM_TALENT_COLUMNS do
            local id, _, texture, selected = GetTalentInfo(row, column, activeSpec)
            debug("Row:", row, "Saved:", zone and zone.talents[row].id, "Selected:", selected and id)
            if (not zone) or selected and (zone and zone.talents[row].id == id) then
                debug("Selected Button:", talentIcons[row], "Icon:", talentIcons[row].icon)
                --Set current talent to button
                talentIcons[row]:SetID(id)
                talentIcons[row].icon:SetTexture(texture or [[Interface\Icons\INV_Misc_QuestionMark]])
                talentIcons[row].icon:SetDesaturated(true)
                talentIcons[row].check:Show()
                break
            elseif (not selected) and (zone and zone.talents[row].id == id) then
                debug("Not Selected Button:", talentIcons[row], "Icon:", talentIcons[row].icon)
                --Set saved talent to button
                talentIcons[row]:SetID(zone.talents[row].id)
                talentIcons[row].icon:SetTexture(zone.talents[row].texture)
                talentIcons[row].icon:SetDesaturated(false)
                talentIcons[row].check:Hide()
                talentsShown = true
                break
            end
        end
    end

    for i = glyphStart, NUM_GLYPH_SLOTS, glyphIncr do
        local enabled, glyphType, _, glyphSpell, path = GetGlyphSocketInfo(i)
        if enabled then
            debug("Slot:", i, "Saved:", zone and zone.glyphs[i].spell, "Equipped:", glyphSpell)
            if (not zone) or (zone and zone.glyphs[i].spell == glyphSpell) then
                --Set current glyph to button
                glyphIcons[i]:SetID(glyphSpell or 112105)
                glyphIcons[i].icon:SetTexture(path or [[Interface\Icons\INV_Misc_QuestionMark]])
                glyphIcons[i].icon:SetDesaturated(true)
                glyphIcons[i].check:Show()
            else
                --Set saved glyph to button
                glyphIcons[i]:SetID(zone.glyphs[i].spell)
                glyphIcons[i].icon:SetTexture(zone.glyphs[i].icon)
                glyphIcons[i].icon:SetDesaturated(false)
                glyphIcons[i].check:Hide()
                glyphsShown = true
            end
        end
    end

    debug("UpdateIcons;", "Show or Hide")
    self:showTalents((ZoneSpecDB.isMovable) or (talentsShown))
    self:showGlyphs((ZoneSpecDB.isMovable) or (glyphsShown))
end

function ZoneSpec:SetZSChar(isReset)
    debug("|cff22dd22ZS|r ZSChar:", ZSChar, "ZSChar[1]:", ZSChar[1])
    if isReset or (not ZSChar[1]) then
        for i = 1, _G.GetNumSpecializations() do
            debug("ZSChar:", ZSChar, "i:", i)
            ZSChar[i] = {}
            debug("ZSChar:", ZSChar, "ZSChar[i]:", ZSChar[i])
        end
    end
end

function ZoneSpec:IsInMultiBossArea(arg, event, currentMapID, currentMapLevel, currentMapFile)
    debug(event, arg, currentMapID, currentMapLevel, currentMapFile)
    multiBossArea = multiBossAreas[currentMapID]
    if multiBossArea then
        local multiBossArea = multiBossArea[currentMapLevel]
        local _, isKilled
        if multiBossArea and not multiBossArea.left then
            for i = 1, #multiBossArea do
                _, _, isKilled = GetInstanceLockTimeRemainingEncounter(multiBossArea[1])
                if isKilled then
                    break
                end
            end
        else
        end
        if isKilled then
            self.frame:UnregisterEvent("BOSS_KILL")
        else
            self.frame:RegisterEvent("BOSS_KILL")
        end
    else
        self.frame:UnregisterEvent("BOSS_KILL")
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
        debug("OnEnter: Anchor")
        if ZoneSpecDB and ZoneSpecDB.isMovable then
            debug("Config tooltip")
            GameTooltip:ClearAllPoints()
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR", 0 ,0)
            GameTooltip:SetText( 'Drag to move frame.\nUse "\/zs toggle" to lock placement.' )
            debug("Show tooltip")
            GameTooltip:Show()
        end
    end)
    anchor:SetScript("OnLeave", function(self, ...)
        debug("OnLeave: Anchor")
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
        debug(point, relativeTo, relativePoint, xOfs, yOfs)
        ZoneSpecDB.point = point
        ZoneSpecDB.xOfs = xOfs
        ZoneSpecDB.yOfs = yOfs
    end)
    anchor:SetScript("OnHide", function(self, ...)
        self:GetParent():StopMovingOrSizing()
    end)
    frame.anchor = anchor

    local function CreateIcon(parent, isTalent)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetSize(32, 32)

        local icon = btn:CreateTexture(nil, "BACKGROUND")
        icon:SetAllPoints()
        icon:SetTexture([[Interface\Icons\INV_Misc_QuestionMark]])
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        btn.icon = icon

        local check = btn:CreateTexture(nil, "BACKGROUND")
        check:SetPoint("BOTTOMRIGHT")
        check:SetAtlas("Tracker-Check", true)
        btn.check = check

        btn:SetScript("OnEnter", function(self, ...)
            debug("OnEnter", isTalent, self:GetID())
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if self:GetID() then
                if isTalent then
                    GameTooltip:SetTalent(self:GetID())
                else
                    GameTooltip:SetSpellByID(self:GetID())
                end
            else
                GameTooltip:AddLine(_G.EMPTY)
            end
            if ( self.extraTooltip ) then
                GameTooltip:AddLine(self.extraTooltip)
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function(self, ...)
            debug("OnLeave", isTalent, self:GetID())
            GameTooltip:Hide()
        end)
        return btn
    end

    for i = 1, 7 do
        local talent = CreateIcon(frame, true)
        if i == 1 then
            talent:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 4, -1)
        else
            talent:SetPoint("TOPLEFT", talentIcons[i - 1], "TOPRIGHT", 1, 0)
        end
        frame["talent"..i] = talent
        talentIcons[i] = talent
    end

    for i = 2, 6, 2 do
        local glyph = CreateIcon(frame)
        glyph:SetPoint("TOPLEFT", talentIcons[i/2], "BOTTOMLEFT", 0, -1)
        frame["glyph"..i] = glyph
        glyphIcons[i] = glyph
    end

    local reagent = CreateIcon(frame)
    reagent:SetNormalFontObject("SystemFont_Huge1_Outline")
    reagent:SetPoint("TOPRIGHT", frame.talent1, "TOPLEFT", -1, 0)
    frame.reagent = reagent

    frame:RegisterEvent("ADDON_LOADED")
    frame:RegisterEvent("BAG_UPDATE_DELAYED")
    frame:RegisterEvent("PLAYER_LOGIN")
    frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    frame:RegisterEvent("ZONE_CHANGED")
    frame:RegisterEvent("ZONE_CHANGED_INDOORS")
    frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    frame:SetScript("OnEvent", function(self, event, ...)
        debug("Event", event, ...)
        if (event == "ADDON_LOADED") then
            local name = ...
            if name == ADDON_NAME then
                debug(name, "loaded")
                ZoneSpecDB = _G.ZoneSpecDB or defaults
                ZSChar = _G.ZSChar or {}
                self:SetPoint(ZoneSpecDB.point, ZoneSpecDB.xOfs, ZoneSpecDB.yOfs)
            elseif name == "Blizzard_TalentUI" then
                debug(name, "loaded")
                self:UnregisterEvent("ADDON_LOADED")
                ZoneSpec:CreateSaveButton()
            end
        elseif (event == "BAG_UPDATE_DELAYED") then
            local name, count, icon, id = _G.GetTalentClearInfo()
            debug("Talent Clear Info", name, count)
            --self.reagent.text:SetText(count)
            if (ZoneSpecDB.isMovable) or (count and count <= 6) then
                self.reagent:Show()
                self.reagent.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_Dust_02")
                self.reagent:SetText(count or 0)
                self.reagent:SetID(id)
            else
                self.reagent:Hide()
            end
        elseif (event == "PLAYER_LOGIN") then
            curZone = _G.GetMinimapZoneText()
            curSpec = _G.GetSpecialization()
            debug("PLAYER_LOGIN;", "curZone:", curZone, "curSpec:", curSpec)

            debug("Create character saved vars")
            ZoneSpec:SetZSChar()

            ZoneSpec:UpdateIcons()

            if ZoneSpecDB and ZoneSpecDB.isMovable then
                self.anchor:Show()
                self.reagent:Show()
            end
        elseif (event == "PLAYER_SPECIALIZATION_CHANGED") then
            if ... ~= "player" then return end
            ZoneSpec:UpdateIcons()
        elseif (event == "BOSS_KILL") then
            local encounterID, name = ...
            ZoneSpec:UpdateIcons(encounterID)
        else
            curZone = _G.GetMinimapZoneText()
            curSpec = _G.GetSpecialization()

            ZoneSpec:IsInMultiBossArea("test2", event, HBD:GetPlayerZone())
            debug(event, ";", curZone, ";", ...)
            ZoneSpec:UpdateIcons()
        end
        --self[event](self, ...)
    end)

    HBD.RegisterCallback(ZoneSpec, "PlayerZoneChanged", "IsInMultiBossArea", "test")

    ZoneSpec.frame = frame
end


-- Slash Commands
_G.SLASH_ZONESPEC1, _G.SLASH_ZONESPEC2 = "/zonespec", "/zs";
function SlashCmdList.ZONESPEC(msg, editBox)
    debug("msg:", msg)
    if msg == "toggle" then
        if ZoneSpecDB.isMovable then
            ZoneSpecDB.isMovable = false
            ZoneSpec:UpdateIcons()
            ZoneSpec.frame:GetScript("OnEvent")(ZoneSpec.frame, "BAG_UPDATE_DELAYED")
            ZoneSpec.frame.anchor:Hide()
            zsPrint("ZoneSpec is locked");
        else
            ZoneSpecDB.isMovable = true
            ZoneSpec:UpdateIcons()
            ZoneSpec.frame:GetScript("OnEvent")(ZoneSpec.frame, "BAG_UPDATE_DELAYED")
            ZoneSpec.frame.anchor:Show()
            zsPrint("ZoneSpec is unlocked");
        end
    elseif msg == "clear" then
        -- Clear the talent and glyph data for the current location.
        ZSChar[curSpec][curZone] = nil
        ZoneSpec:UpdateIcons()
        zsPrint("Data for", curZone, "has been cleared.");
    elseif msg == "reset" then
        debug("Reset character saved vars")
        ZoneSpec:SetZSChar(true)
        zsPrint("Data for this character has been reset.");
    elseif msg == "debug" then
        if debugger then
            if debugger:Lines() == 0 then
                debugger:AddLine("Nothing to report.")
                debugger:Display()
                debugger:Clear()
                return
            end
            debugger:Display()
        end
    else
        print("Usage: /zs |cff22dd22command|r");
        print("|cff22dd22toggle|r - Show/Hide the anchor frame to move it or lock it in place.")
        print("|cff22dd22clear|r - Clear saved talents and glyphs for the current area.")
        print("|cff22dd22reset|r - Reset all data for the current character.")
    end
end
