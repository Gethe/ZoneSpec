local ADDON_NAME, ZoneSpec = ...

-- Lua Globals --
local _G = _G
local tostring, select, print = _G.tostring, _G.select, _G.print

-- Libs --
local HBD = _G.LibStub("HereBeDragons-1.0")

local ZSVersion = _G.GetAddOnMetadata(ADDON_NAME, "Version")
local debugger, debug do
    local LTD = true
    function debug(...)
        if not debugger and LTD then
            LTD = _G.LibStub("RealUI_LibTextDump-1.0", true)
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
local curBossArea
local maxTalents
local BOSS_KILL = {}

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
            {
                left = 0.67,
                right = 1,
                top = 0,
                bottom = 1,
                key = "886-0-1",
                { -- Protectors of the Endless
                    index = 1,
                    ejID = 683,
                    encID = 1409,
                    npcID = {60583, 60586, 60585}, -- Protector Kaolan, Elder Asani, Elder Regail
                },
                { -- Tsulong
                    index = 2,
                    ejID = 742,
                    encID = 1505,
                    npcID = {62442},
                    isLastBossforArea = true,
                },
            },
            {
                left = 0.51,
                right = 0.67,
                top = 0,
                bottom = 1,
                key = "886-0-2",
                { -- Lei Shi
                    index = 3,
                    ejID = 729,
                    encID = 1506,
                    isLastBossforArea = true,
                },
            },
            {
                left = 0,
                right = 0.51,
                top = 0,
                bottom = 1,
                key = "886-0-3",
                { -- Sha of Fear
                    index = 4,
                    ejID = 709,
                    encID = 1431,
                    isLastBossforArea = true,
                },
            },
        }
    },
    [1026] = { -- Hellfire Citadel
        [1] = { -- Floor 1: The Iron Bulwark
            {
                left = 0,
                right = 1,
                top = 0,
                bottom = 1,
                key = "1026-1-1",
                { -- Hellfire Assault
                    index = 1,
                    ejID = 1426,
                    encID = 1778,
                    npcID = {95068},
                },
                { -- Iron Reaver
                    index = 2,
                    ejID = 1425,
                    encID = 1785,
                    npcID = {90284},
                    isLastBossforArea = true,
                },
            }
        }
    },
}

--[[
ZSChar = {
    { -- first spec
        ["Some Zone"] = {
            ["talents"] = {
                {
                    ["id"] = talentID,
                    ["icon"] = "icon\\path"
                }, -- ["1"]
            },
            ["glyphs"] = {

            }
        },
        ["Some Other Zone"] = {
            [table#532532] = { -- multi-boss area
                {
                    ["talents"] = {
                        {
                            ["id"] = talentID,
                            ["icon"] = "icon\\path"
                        }, -- ["1"]
                    },
                    ["glyphs"] = {

                    }
                }
            }
        },
    },
}
]]

function ZoneSpec:CreateSaveButton()
    local btn = _G.CreateFrame("Button", "ZoneSpecSaveButton", _G.PlayerTalentFrame, "UIPanelButtonTemplate")
    btn:SetPoint("BOTTOMRIGHT", -4, 4)
    btn:SetSize(80, 22)
    btn:SetText(_G.SAVE)
    if _G.Aurora then
        _G.Aurora[1].Reskin(btn)
    end

    btn:SetScript("OnClick", function()
        local zone = {}

        debug("Save the current talent config")
        local talents = {}
        local activeSpec = _G.GetActiveSpecGroup()
        for tier = 1, _G.MAX_TALENT_TIERS do
            for column = 1, _G.NUM_TALENT_COLUMNS do
                local id, _, texture, selected = _G.GetTalentInfo(tier, column, activeSpec)
                if selected then
                    debug("Talent", id, "; Texture:", texture) --ZSChar
                    talents[tier] = {
                        id = id,
                        texture = texture,
                    }
                end
            end
        end
        zone.talents = talents

        --[[  Glyph layout
           2
          3 1
         4 5 6
        ]]

        local glyphs = {}
        debug("Save the current glyph config")
        for i = 1, _G.NUM_GLYPH_SLOTS do
            local _, glyphType, _, glyphSpell, texture = _G.GetGlyphSocketInfo(i)
            debug("Glyph:", i, "; Texture:", texture) --ZSChar
            glyphs[i] = {
                glyphType = glyphType,
                icon = texture,
                spell = glyphSpell,
            }
        end
        zone.glyphs = glyphs


        local boss, bossName
        if curBossArea then
            boss, bossName = self:GetBossForArea()
            local key = curBossArea.key
            if not ZSChar[curSpec][curZone] or ZSChar[curSpec][curZone].talents then
                ZSChar[curSpec][curZone] = {[key] = {}}
            end
            ZSChar[curSpec][curZone][key][boss.index] = zone
        else
            ZSChar[curSpec][curZone] = zone
        end

        self:UpdateIcons()
        if boss.index then
            zsPrint(("Talent and Glyph data has been saved for %s (%s)."):format(curZone, bossName))
        else
            zsPrint(("Talent and Glyph data has been saved for %s."):format(curZone))
        end
    end)
    _G.hooksecurefunc("PlayerTalentFrameActivateButton_Update", function()
        local activeSpec = "spec".._G.GetActiveSpecGroup()
        if (activeSpec == _G.PlayerTalentFrame.selectedPlayerSpec) then
            btn:Show()
        else
            btn:Hide()
        end
    end)
end

function ZoneSpec:showTalents(show)
    local numTalents = _G.GetMaxTalentTier()
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
    maxTalents = _G.GetMaxTalentTier()
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
        if curBossArea then
            if zone[curBossArea.key] then
                debug("Set zone to boss area", curBossArea.key)
                local boss = self:GetBossForArea()
                zone = zone[curBossArea.key][boss.index]
            end
            if zone and not zone.talents then
                zone = nil
            end
        elseif not zone.talents then
            zone = nil
            ZSChar[curSpec][curZone] = nil
        end
    end

    --show when new talent tier is available
    local activeSpec = _G.GetActiveSpecGroup()
    for row = 1, maxTalents do
        if zone and not zone.talents[row] then
            debug("Missing Row:", row)
            zone.talents[row] = {}
        end
        for column = 1, _G.NUM_TALENT_COLUMNS do
            local id, _, texture, selected = _G.GetTalentInfo(row, column, activeSpec)
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

    for i = glyphStart, _G.NUM_GLYPH_SLOTS, glyphIncr do
        local enabled, _, _, glyphSpell, path = _G.GetGlyphSocketInfo(i)
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

function ZoneSpec:IsInBossAreaBounds(x, y)
    return (x > curBossArea.left and x < curBossArea.right) and (y > curBossArea.top and y < curBossArea.bottom)
end


function ZoneSpec:SetBossAsKilled(encounterID)
    debug("SetBossAsKilled", encounterID)
    for i = 1, #curBossArea do
        local boss = curBossArea[i]
        debug("Check boss", i, boss.encID)
        if encounterID == boss.encID then
            boss.isKilled = true
        elseif encounterID < 0 then
            -- reset
            boss.isKilled = nil
        end
    end
end

function ZoneSpec:GetBossForArea(index)
    debug("GetBossForArea", index)
    if index then
        local boss = curBossArea[index]
        return boss, _G.EJ_GetEncounterInfo(boss.ejID)
    else
        for i = 1, #curBossArea do
            debug("Check boss", i)
            local boss = curBossArea[i]
            if not boss.isKilled or i == #curBossArea then
                debug("Current boss", boss.index, boss.ejID, boss.encID)
                return boss, _G.EJ_GetEncounterInfo(boss.ejID), i
            end
        end
    end
end

function ZoneSpec:FindCurrentBossArea(x, y, currentMapID, currentMapLevel, currentMapFile)
    debug("FindCurrentBossArea", x, y, currentMapID, currentMapLevel, currentMapFile)
    --zsPrint("Player map position", x, y)
    local raidLevel = multiBossAreas[currentMapID] and multiBossAreas[currentMapID][currentMapLevel]
    if raidLevel then
        debug("Possible boss area")
        for i = 1, #raidLevel do
            debug("Find current boss area", i)
            curBossArea = raidLevel[i]
            if self:IsInBossAreaBounds(x, y) then
                debug("You are within bounds", curBossArea.key)
                self.frame:RegisterEvent("BOSS_KILL")
                self.frame:RegisterEvent("PLAYER_TARGET_CHANGED")
                self.frame:RegisterEvent("PLAYER_STOPPED_MOVING")
                break
            elseif i == #raidLevel then
                debug("Not in a multi-boss area")
                curBossArea = nil
                self.frame:UnregisterEvent("BOSS_KILL")
                self.frame:UnregisterEvent("PLAYER_TARGET_CHANGED")
                self.frame:UnregisterEvent("PLAYER_STOPPED_MOVING")
            end
        end
    else
        debug("Not in a multi-boss map")
        if curBossArea then
            ZoneSpec:SetBossAsKilled(-1)
            curBossArea = nil
        end
        self.frame:UnregisterEvent("BOSS_KILL")
        self.frame:UnregisterEvent("PLAYER_TARGET_CHANGED")
        self.frame:UnregisterEvent("PLAYER_STOPPED_MOVING")
    end
end

---------------------------------
do
    local frame = _G.CreateFrame("Frame", "ZSFrame", _G.UIParent)
    frame:SetSize(200, 64)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")

    local anchor = _G.CreateFrame("Button", nil, frame, "ChatConfigTabTemplate")
    anchor:SetScript("OnEnter", function(self, ...)
        debug("OnEnter: Anchor", ...)
        if ZoneSpecDB and ZoneSpecDB.isMovable then
            debug("Config tooltip")
            _G.GameTooltip:ClearAllPoints()
            _G.GameTooltip:SetOwner(self, "ANCHOR_CURSOR", 0, 0)
            _G.GameTooltip:SetText( [[Drag to move frame.\nUse "/zs toggle" to lock placement.]] )
            debug("Show tooltip")
            _G.GameTooltip:Show()
        end
    end)
    anchor:SetScript("OnLeave", function(self, ...)
        debug("OnLeave: Anchor", ...)
        _G.GameTooltip:Hide()
    end)
    anchor:SetScript("OnMouseDown", function(self, ...)
        debug("OnMouseDown: Anchor", ...)
        if ZoneSpecDB and ZoneSpecDB.isMovable then
            self:GetParent():StartMoving()
        end
    end)
    anchor:SetScript("OnMouseUp", function(self, ...)
        debug("OnMouseUp: Anchor", ...)
        self:GetParent():StopMovingOrSizing()
        local point, relativeTo, relativePoint, xOfs, yOfs = self:GetParent():GetPoint()
        debug(point, relativeTo, relativePoint, xOfs, yOfs)
        ZoneSpecDB.point = point
        ZoneSpecDB.xOfs = xOfs
        ZoneSpecDB.yOfs = yOfs
    end)
    anchor:SetScript("OnHide", function(self)
        self:GetParent():StopMovingOrSizing()
    end)
    frame.anchor = anchor

    local function CreateIcon(parent, isTalent)
        local btn = _G.CreateFrame("Button", nil, parent)
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
            debug("OnEnter", isTalent, self:GetID(), ...)
            _G.GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if self:GetID() then
                if isTalent then
                    _G.GameTooltip:SetTalent(self:GetID())
                else
                    _G.GameTooltip:SetSpellByID(self:GetID())
                end
            else
                _G.GameTooltip:AddLine(_G.EMPTY)
            end
            if ( self.extraTooltip ) then
                _G.GameTooltip:AddLine(self.extraTooltip)
            end
            _G.GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function(self, ...)
            debug("OnLeave", isTalent, self:GetID(), ...)
            _G.GameTooltip:Hide()
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
    frame:RegisterEvent("PLAYER_LOGOUT")
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
            debug("Create character saved vars")
            ZoneSpec:SetZSChar()

            if ZoneSpecDB and ZoneSpecDB.isMovable then
                self.anchor:Show()
                self.reagent:Show()
            end
        elseif (event == "PLAYER_LOGOUT") then
            debug("Set character saved vars")
            _G.ZoneSpecDB = ZoneSpecDB
            _G.ZSChar = ZSChar
        elseif (event == "PLAYER_SPECIALIZATION_CHANGED") then
            if ... ~= "player" then return end
            ZoneSpec:UpdateIcons()
        elseif (event == "BOSS_KILL") then
            local encounterID = ...
            BOSS_KILL[encounterID] = true
            ZoneSpec:SetBossAsKilled(encounterID)
            ZoneSpec:UpdateIcons()
        elseif (event == "PLAYER_TARGET_CHANGED") then
            if _G.UnitAffectingCombat("player") then return end
            local guid = _G.UnitGUID("target")
            if guid then
                local type, _, _, _, _, npcID = _G.strsplit("-", guid)
                debug("Target", type, npcID)
                if (type == "Creature" or type == "Vehicle") then
                    for idx = 1, #curBossArea do
                        local boss = curBossArea[idx]
                        for i = 1, #boss.npcID do
                            if boss.npcID[i] == _G.tonumber(npcID) and not BOSS_KILL[boss.encID] then
                                debug("At boss", boss.index, boss.encID, idx)
                                boss.isKilled = false
                                idx = idx - 1
                                while idx > 0 do
                                    local prevBoss = curBossArea[idx]
                                    debug("Killed boss", prevBoss.index, prevBoss.encID, idx)
                                    prevBoss.isKilled = true
                                    idx = idx - 1
                                end
                                return ZoneSpec:UpdateIcons()
                            end
                        end
                    end
                end
            end
        elseif (event == "PLAYER_STOPPED_MOVING") then
            local oldBossArea = curBossArea
            ZoneSpec:FindCurrentBossArea(HBD:GetPlayerZonePosition())
            if oldBossArea ~= curBossArea then
                ZoneSpec:UpdateIcons()
            end
        else
            local oldBossArea, oldZone = curBossArea, curZone
            curZone = _G.GetMinimapZoneText()
            curSpec = _G.GetSpecialization()
            debug(event, ";", curZone, ";", ...)

            ZoneSpec:FindCurrentBossArea(HBD:GetPlayerZonePosition())
            if (oldZone ~= curZone) or (oldBossArea ~= curBossArea) then
                ZoneSpec:UpdateIcons()
            end
        end
        --self[event](self, ...)
    end)

    HBD.RegisterCallback(ZoneSpec, "PlayerZoneChanged", function(...)
        frame:GetScript("OnEvent")(...)
    end)

    ZoneSpec.frame = frame
end


-- Slash Commands
_G.SLASH_ZONESPEC1, _G.SLASH_ZONESPEC2 = "/zonespec", "/zs";
function _G.SlashCmdList.ZONESPEC(msg, editBox)
    debug("msg:", msg, editBox)
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
