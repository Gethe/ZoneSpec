local NAME, ZoneSpec = ...
_G.ZoneSpec = ZoneSpec

local HBD = LibStub("HereBeDragons-1.0")
local ZSVersion = GetAddOnMetadata(NAME, "Version")

local debugger, debug do
    local LTD = true
    function debug(...)
        if not debugger and LTD then
            LTD = LibStub("LibTextDump-1.0")
            if LTD then
                debugger = LibStub("LibTextDump-1.0"):New("ZoneSpec Debug Output", 640, 480)
            else
                LTD = false
                return
            end
        end
        local time = date("%H:%M:%S")
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

local curZone
local curSpec
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
    btn:SetText(SAVE)
    if Aurora then
        Aurora[1].Reskin(btn)
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
                    debug("Talent", i, "; Texture:", texture) --ZSChar
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
        debug("Talent and Glyph data has been saved for", curZone, ".")
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
        debug("showGlyphs", self.frame.glyphs, i)
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
    debug("UpdateIcons;", curZone, curSpec)

    if (not curSpec) or (maxTalents == 0) then
        debug("UpdateIcons;", "nope")
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
        if zone and not zone.talents[row] then
            debug("Missing Row:", row)
            zone.talents[row] = {}
        end
        for column = 1, NUM_TALENT_COLUMNS do
            local id, _, texture, selected = GetTalentInfo(row, column, activeSpec)
            debug("Row:", row, "Saved:", zone and zone.talents[row].id, "Selected:", selected and id)
            if (not zone) or selected and (zone and zone.talents[row].id == id) then
                debug("Selected Button:", talents[row], "Icon:", talents[row].icon)
                --Set current talent to button
                talents[row]:SetID(id)
                talents[row].icon:SetTexture(texture or [[Interface\Icons\INV_Misc_QuestionMark]])
                talents[row].icon:SetDesaturated(true)
                talents[row].check:Show()
                break
            elseif (not selected) and (zone and zone.talents[row].id == id) then
                debug("Not Selected Button:", talents[row], "Icon:", talents[row].icon)
                --Set saved talent to button
                talents[row]:SetID(zone.talents[row].id)
                talents[row].icon:SetTexture(zone.talents[row].texture)
                talents[row].icon:SetDesaturated(false)
                talents[row].check:Hide()
                talentsShown = true
                break
            end
        end
    end

    local glyphs = self.frame.glyphs
    for i = glyphStart, NUM_GLYPH_SLOTS, glyphIncr do
        local enabled, glyphType, _, glyphSpell, path = GetGlyphSocketInfo(i)
        if enabled then
            debug("Slot:", i, "Saved:", zone and zone.glyphs[i].spell, "Equipped:", glyphSpell)
            if (not zone) or (zone and zone.glyphs[i].spell == glyphSpell) then
                --Set current glyph to button
                glyphs[i]:SetID(glyphSpell or 112105)
                glyphs[i].icon:SetTexture(path or [[Interface\Icons\INV_Misc_QuestionMark]])
                glyphs[i].icon:SetDesaturated(true)
                glyphs[i].check:Show()
            else
                --Set saved glyph to button
                glyphs[i]:SetID(zone.glyphs[i].spell)
                glyphs[i].icon:SetTexture(zone.glyphs[i].icon)
                glyphs[i].icon:SetDesaturated(false)
                glyphs[i].check:Hide()
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
        for i = 1, GetNumSpecializations() do
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
            debug("OnEnter:", isTalent, self:GetID())
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if self:GetID() then
                if isTalent then
                    GameTooltip:SetTalent(self:GetID())
                else
                    GameTooltip:SetSpellByID(self:GetID())
                end
            else
                GameTooltip:AddLine(EMPTY)
            end
            if ( self.extraTooltip ) then
                GameTooltip:AddLine(self.extraTooltip)
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function(self, ...)
            debug("OnLeave: Talent", i)
            GameTooltip:Hide()
        end)
        return btn
    end

    frame.talents = {}
    for i = 1, 7 do
        local talent = CreateIcon(frame, true)
        if i == 1 then
            talent:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 4, -1)
        else
            talent:SetPoint("TOPLEFT", frame.talents[i - 1], "TOPRIGHT", 1, 0)
        end
        frame.talents[i] = talent
    end

    frame.glyphs = {}
    for i = 2, 6, 2 do
        local glyph = CreateIcon(frame)
        glyph:SetPoint("TOPLEFT", frame.talents[i/2], "BOTTOMLEFT", 0, -1)
        frame.glyphs[i] = glyph
    end

    local reagent = CreateIcon(frame)
    reagent:SetPoint("TOPRIGHT", frame.talents[i], "TOPLEFT", -1, 0)
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
            if name == NAME then
                debug(name, "loaded")
                ZoneSpecDB = ZoneSpecDB or defaults
                ZSChar = ZSChar or {}
                self:SetPoint(ZoneSpecDB.point, ZoneSpecDB.xOfs, ZoneSpecDB.yOfs)
            elseif name == "Blizzard_TalentUI" then
                debug(name, "loaded")
                self:UnregisterEvent("ADDON_LOADED")
                ZoneSpec:CreateSaveButton()
            end
        elseif (event == "BAG_UPDATE_DELAYED") then
            local name, count, icon, id = GetTalentClearInfo()
            --self.reagent.text:SetText(count)
            if (ZoneSpecDB.isMovable) or (count and count <= 6) then
                self.reagent:Show()
                debug(self.reagent.icon:GetTexture())
                self.reagent.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_Dust_02")
                self.reagent:SetText(count or 0)
                self.reagent:SetID(id)
            else
                self.reagent:Hide()
            end
        elseif (event == "PLAYER_LOGIN") then
            curZone = GetMinimapZoneText()
            curSpec = GetSpecialization()
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
            curZone = GetMinimapZoneText()
            curSpec = GetSpecialization()

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
SLASH_ZONESPEC1, SLASH_ZONESPEC2 = "/zonespec", "/zs";
function SlashCmdList.ZONESPEC(msg, editBox)
    debug("msg:", msg)
    if msg == "toggle" then
        if ZoneSpecDB.isMovable then
            ZoneSpecDB.isMovable = false
            ZoneSpec:UpdateIcons()
            ZoneSpec.frame:GetScript("OnEvent")(ZoneSpec.frame, "BAG_UPDATE_DELAYED")
            ZoneSpec.frame.anchor:Hide()
            debug("ZoneSpec is locked");
        else
            ZoneSpecDB.isMovable = true
            ZoneSpec:UpdateIcons()
            ZoneSpec.frame:GetScript("OnEvent")(ZoneSpec.frame, "BAG_UPDATE_DELAYED")
            ZoneSpec.frame.anchor:Show()
            debug("ZoneSpec is unlocked");
        end
    elseif msg == "clear" then
        -- Clear the talent and glyph data for the current location.
        ZSChar[curSpec][curZone] = nil
        ZoneSpec:UpdateIcons()
        print("|cff22dd22ZoneSpec|r: Data for", curZone, "has been cleared.");
    elseif msg == "reset" then
        debug("Reset character saved vars")
        ZoneSpec:SetZSChar(true)
        print("|cff22dd22ZoneSpec|r: Data for this character has been reset.");
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
