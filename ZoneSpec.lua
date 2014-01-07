local NAME = "ZoneSpec"
ZoneSpec = select(2, ...)

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

local anchor = CreateFrame("Frame", "ZoneSpecAnchor", UIParent, "ChatConfigTabTemplate")
local function SetAnchor()
	--printDebug("Apply anchor settings")
	anchor:ClearAllPoints()
	anchor:SetPoint(ZoneSpec.db.point, ZoneSpec.db.xOfs, ZoneSpec.db.yOfs)
	anchor:SetFrameStrata("LOW")
	
	-- Make it movable,
	anchor:SetMovable(true)
	anchor:EnableMouse(true)
	anchor:RegisterForDrag("LeftButton")
	anchor:SetScript("OnDragStart", function()
		--but only when we want to.
		if ZoneSpec.db.isMovable then
			anchor:StartMoving()
		end
	end)
	anchor:SetScript("OnDragStop", function() --anchor.StopMovingOrSizing)
		anchor:StopMovingOrSizing()
		local point, relativeTo, relativePoint, xOfs, yOfs = anchor:GetPoint()
		--printDebug(point, relativeTo, relativePoint, xOfs, yOfs)
		ZoneSpec.db.point = point
		ZoneSpec.db.xOfs = xOfs
		ZoneSpec.db.yOfs = yOfs
	end)
	anchor:SetScript("OnHide", anchor.StopMovingOrSizing)
	
	-- Show a helper tooltip
	anchor:SetScript("OnEnter", function()
		--printDebug("OnEnter: Anchor")
		if ZoneSpec.db.isMovable then
			--printDebug("Config tooltip")
			GameTooltip:ClearAllPoints()
			GameTooltip:SetOwner(anchor, "ANCHOR_CURSOR", 0 ,0)
			GameTooltip:SetText( 'Drag to move frame.\nUse "\/zs toggle" to lock placement.' )
			--printDebug("Show tooltip")
			GameTooltip:Show()
		end
	end)
	anchor:SetScript("OnLeave", function()
		--printDebug("OnLeave: Anchor")
		GameTooltip:Hide()
	end)

	--text = _G["ZoneSpecAnchorText"];
	--text:SetText(NAME);

	--printDebug("Show the anchor")
	if ZoneSpec.db.isMovable then
		anchor:Show()
	end
end

local talentBox = CreateFrame("Frame", nil, UIParent)
local glyphBox = CreateFrame("Frame", nil, UIParent)
local function CreateTextures()
	local tex
	--Talent Textures
	for i = 1, 6 do
		tex = talentBox:CreateTexture("ZSTalent"..i, "ARTWORK")
		tex:SetSize(32, 32)

		if i == 1 then
			tex:SetPoint("TOPLEFT", ZoneSpecAnchor, "BOTTOMLEFT", 3, -1)
		else
			tex:SetPoint("TOPLEFT", "ZSTalent"..i-1, "TOPRIGHT", 1, 0)
		end
	end
	-- Glyph Textures
	for i = glyphStart, NUM_GLYPH_SLOTS, glyphIncr do
		tex = glyphBox:CreateTexture("ZSGlyph"..i, "ARTWORK")
		tex:SetSize(32, 32)

		if i == glyphStart
		then
			tex:SetPoint("TOPLEFT", "ZSTalent1", "BOTTOMLEFT", 0, -1)
		else
			tex:SetPoint("TOPLEFT", "ZSGlyph"..i-glyphIncr, "TOPRIGHT", 1, 0)
		end
	end
end

local function CreateReagent()
	--Reagent Texture
	local frame = CreateFrame("Frame", "ZSReagent", UIParent)
	frame:SetPoint("TOPRIGHT", ZoneSpecAnchor, "BOTTOMLEFT", 2, -1)
	frame:SetSize(32, 32)

	local texture = frame:CreateTexture(nil, "BACKGROUND")
	texture:SetAllPoints(frame)
	frame.BG = texture

	local text = frame:CreateFontString(nil, "ARTWORK", "NumberFontNormal")
	text:SetPoint("BOTTOMRIGHT", -2. -2)
	frame.Text = text

	--frame:Show()
end

local function CreateSaveButton()
	local btn = CreateFrame("Button", "ZoneSpecSaveButton", PlayerTalentFrame, "UIPanelButtonTemplate")
	btn:SetPoint("BOTTOMRIGHT", -4, 4)
	btn:SetSize(80, 22)
	btn:SetText(SAVE)

	btn:SetScript("OnClick", function()
		if not ZSChar[curSpec][zone] then
			ZSChar[curSpec][zone] = {}
		end

		local talents = {}
		--printDebug("Save the current talent config")
		for i = 1, TOTAL_NUM_TALENTS do
			local name, texture, tier, _, selected = GetTalentInfo(i)
			if selected then
				--printDebug("Talent", i, "; Texture:", texture) --ZSChar
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
		--printDebug("Save the current glyph config")
		for i = 1, NUM_GLYPH_SLOTS do
			local _, glyphType, _, glyphSpell, texture = GetGlyphSocketInfo(i)
			--printDebug("Glyph:", i, "; Texture:", texture) --ZSChar
			glyphs[i] = {
				glyphType = glyphType,
				icon = texture,
				spell = glyphSpell,
			}
		end
		ZSChar[curSpec][zone]["glyphs"] = glyphs

		printDebug("|cff22dd22ZoneSpec|r: Talent and Glyph data has been saved for", zone, ".")
		ZoneSpec:UpdateInfo()
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

function ZoneSpec:UpdateInfo()
	--printDebug("Do updates")
	zone = GetMinimapZoneText()
	curSpec = GetSpecialization()
	if (not zone) or (zone == "") or (not curSpec) then return end

	local showTalents = false
	local showGlyphs = false
	--printDebug("Update; ZSChar:", ZSChar, type(ZSChar), "curSpec:", curSpec, type(curSpec), "zone:", zone, type(zone))
	--printDebug(ZSChar[curSpec], type(ZSChar[curSpec]))
	if (ZSChar[curSpec][zone]) then
		local zoneDB = ZSChar[curSpec][zone]
		--printDebug("Type:", type(ZSChar[curSpec][zone]), ";", zoneDB)
		if zoneDB.talents[1] then
			for i = 1, GetMaxTalentTier() do
				local _, talent = GetTalentRowSelectionInfo(i)
				--printDebug("Saved:", zoneDB.talents[i].selected, "Learned:", talent)
				local tex = _G["ZSTalent"..i]
				tex:SetTexture(zoneDB.talents[i].icon)
				tex:Show()
				if zoneDB.talents[i].selected == talent then
					tex:SetDesaturated(1)
				else
					tex:SetDesaturated(0)
					showTalents = true
				end
			end
		end
		
		if zoneDB.glyphs[1] then
			for i = glyphStart, NUM_GLYPH_SLOTS, glyphIncr do
				local _, glyphType, _, glyphSpell = GetGlyphSocketInfo(i)
				--printDebug("spell:", zoneDB.glyphs[i].spell, "glyphSpell:", glyphSpell)
				local tex = _G["ZSGlyph"..i]
				tex:SetTexture(zoneDB.glyphs[i].icon)
				tex:Show()
				if zoneDB.glyphs[i].spell == glyphSpell then
					tex:SetDesaturated(1)
				else
					tex:SetDesaturated(0)
					showGlyphs = true
				end
			end
		end
	end

	if (ZoneSpec.db.isMovable) or showTalents then
		talentBox:Show()
	else
		talentBox:Hide()
	end
	if (ZoneSpec.db.isMovable) or showGlyphs then
		glyphBox:Show()
	else
		glyphBox:Hide()
	end
end
function ZoneSpec:SetZSChar(isReset)
	--printDebug("|cff22dd22ZS|r ZSChar:", ZSChar, "ZSChar[1]:", ZSChar[1])
	if isReset or (not ZSChar[1]) then
		for i = 1, GetNumSpecializations() do
			--printDebug("ZSChar:", ZSChar, "i:", i)
			ZSChar[i] = {}
			--printDebug("ZSChar:", ZSChar, "ZSChar[i]:", ZSChar[i])
		end
	end
end

function ZoneSpec:OnEvent(self, event, ...)
	printDebug("Event", event)
	if (event == "ADDON_LOADED") then
		name = ...
		if name == NAME then
			printDebug(name, "loaded")

			ZoneSpec.db = ZoneSpecDB or defaults
			if tonumber(ZoneSpec.db.version) < 1.5 then
				ZoneSpec.db.point = ZoneSpec.db.anchor
				ZoneSpec.db.anchor = nil
				ZoneSpec.db.version = ZSVersion
			else
				ZoneSpec.db.version = ZSVersion
			end
			
			ZSChar = ZSChar or {}
		elseif name == "Blizzard_TalentUI" then
			--printDebug(name, "loaded")
			self:UnregisterEvent("ADDON_LOADED")
			CreateSaveButton()
		end
	elseif (event == "BAG_UPDATE_DELAYED") then
		local name, count, icon = GetTalentClearInfo()
		--ZSReagent.Text:SetText(count)
		if (ZoneSpec.db.isMovable) or (count and count <= 6) then
			ZSReagent:Show()
			ZSReagent.BG:SetTexture(icon)
			ZSReagent.Text:SetText(count)
		else
			ZSReagent:Hide()
		end
	elseif (event == "PLAYER_LOGIN") then
		zone = GetMinimapZoneText()
		curSpec = GetSpecialization()
		printDebug("PLAYER_LOGIN;  zone:", zone, "curSpec:", curSpec)
		
		--printDebug("Create character saved vars")
		ZoneSpec:SetZSChar()
		--printDebug("Create an anchor")
		SetAnchor()
		--printDebug("Create talent icons")
		CreateTextures()
		--printDebug("Create reagent icon")
		CreateReagent()

		ZoneSpec:UpdateInfo()
	else
		zone = GetMinimapZoneText()
		--printDebug(event, ";", zone, ";", ...)
		ZoneSpec:UpdateInfo()
	end
	--ZoneSpec[event](self, ...)
end

function ZoneSpec_OnLoad(self)
	printDebug("Load")
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
end

-- Slash Commands
SLASH_ZONESPEC1, SLASH_ZONESPEC2 = "/zonespec", "/zs";
function SlashCmdList.ZONESPEC(msg, editBox)
	--printDebug("msg:", msg)
	if msg == "toggle" then
		if ZoneSpec.db.isMovable then
			ZoneSpec.db.isMovable = false
			ZoneSpec:UpdateInfo()
			ZoneSpec:OnEvent(nil, "BAG_UPDATE_DELAYED")
			anchor:Hide()
			--printDebug("ZoneSpec is locked");
		else
			ZoneSpec.db.isMovable = true
			ZoneSpec:UpdateInfo()
			ZoneSpec:OnEvent(nil, "BAG_UPDATE_DELAYED")
			anchor:Show()
			--printDebug("ZoneSpec is unlocked");
		end
	elseif msg == "clear" then
		-- Clear the talent and glyph data for the current location.
		ZSChar[curSpec][zone] = nil
		ZoneSpec:UpdateInfo()
		print("|cff22dd22ZoneSpec|r: Data for", zone, "has been cleared.");
	elseif msg == "reset" then
		--printDebug("Reset character saved vars")
		ZoneSpec:SetZSChar(true)
		print("|cff22dd22ZoneSpec|r: Data for this character has been reset.");
	elseif msg == "debug" then
		--printDebug("defaults.isMovable:", defaults.isMovable);
		--printDebug("ZoneSpec.db.isMovable:", ZoneSpec.db.isMovable);
	else
		print("Usage: /zs |cff22dd22command|r");
		print("|cff22dd22toggle|r - Show/Hide the anchor frame to move it or lock it in place.")
		print("|cff22dd22clear|r - Clear saved talents and glyphs for the current area.")
		print("|cff22dd22reset|r - Reset all data for the current character.")
	end
end

