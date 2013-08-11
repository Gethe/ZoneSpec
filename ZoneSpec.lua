local NAME, ZoneSpec = ...
local ZSVersion = 1.5

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

local anchor = CreateFrame("Frame", "ZoneSpecAnchor", UIParent, "ChatConfigTabTemplate")
local function SetAnchor()
	--print("Apply anchor settings")
	anchor:ClearAllPoints()
	anchor:SetPoint(ZoneSpecDB.point, ZoneSpecDB.xOfs, ZoneSpecDB.yOfs)
	anchor:SetFrameStrata("LOW")
	
	-- Make it movable,
	anchor:SetMovable(true)
	anchor:EnableMouse(true)
	anchor:RegisterForDrag("LeftButton")
	anchor:SetScript("OnDragStart", function()
		--but only when we want to.
		if ZoneSpecDB.isMovable then
			anchor:StartMoving()
		end
	end)
	anchor:SetScript("OnDragStop", function() --anchor.StopMovingOrSizing)
		anchor:StopMovingOrSizing()
		local point, relativeTo, relativePoint, xOfs, yOfs = anchor:GetPoint()
		--print(point, relativeTo, relativePoint, xOfs, yOfs)
		ZoneSpecDB.point = point
		ZoneSpecDB.xOfs = xOfs
		ZoneSpecDB.yOfs = yOfs
	end)
	anchor:SetScript("OnHide", anchor.StopMovingOrSizing)
	
	-- Show a helper tooltip
	anchor:SetScript("OnEnter", function()
		--print("OnEnter: Anchor")
		if ZoneSpecDB.isMovable then
			--print("Config tooltip")
			GameTooltip:ClearAllPoints()
			GameTooltip:SetOwner(anchor, "ANCHOR_CURSOR", 0 ,0)
			GameTooltip:SetText( 'Drag to move frame.\nUse "\/zs toggle" to lock placement.' )
			--print("Show tooltip")
			GameTooltip:Show()
		end
	end)
	anchor:SetScript("OnLeave", function()
		--print("OnLeave: Anchor")
		GameTooltip:Hide()
	end)

	--text = _G["ZoneSpecAnchorText"];
	--text:SetText(NAME);

	--print("Show the anchor")
	if ZoneSpecDB.isMovable then
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
		--print("Save the current talent config")
		for i = 1, TOTAL_NUM_TALENTS do
			local name, texture, tier, _, selected = GetTalentInfo(i)
			if selected then
				--print("Talent", i, "; Texture:", texture) --ZSChar
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
		--print("Save the current glyph config")
		for i = 1, NUM_GLYPH_SLOTS do
			local _, glyphType, _, glyphSpell, texture = GetGlyphSocketInfo(i)
			--print("Glyph:", i, "; Texture:", texture) --ZSChar
			glyphs[i] = {
				glyphType = glyphType,
				icon = texture,
				spell = glyphSpell,
			}
		end
		ZSChar[curSpec][zone]["glyphs"] = glyphs

		print("|cff22dd22ZoneSpec|r: Talent and Glyph data has been saved for", zone, ".")
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
	--print("Do updates")
	zone = GetMinimapZoneText()
	curSpec = GetSpecialization()
	if (not zone) or (zone == "") or (not curSpec) then return end

	local showTalents = false
	local showGlyphs = false
	--print("|cff22dd22ZS|r Update; ZSChar:", ZSChar, type(ZSChar), "curSpec:", curSpec, type(curSpec), "zone:", zone, type(zone))
	--print("|cff22dd22ZS|r ", ZSChar[curSpec], type(ZSChar[curSpec]))
	if (ZSChar[curSpec][zone]) then
		local zoneDB = ZSChar[curSpec][zone]
		--print("Type:", type(ZSChar[curSpec][zone]), ";", zoneDB)
		if zoneDB.talents[1] then
			for i = 1, GetMaxTalentTier() do
				local _, talent = GetTalentRowSelectionInfo(i)
				--print("Saved:", zoneDB.talents[i].selected, "Learned:", talent)
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
				--print("spell:", zoneDB.glyphs[i].spell, "glyphSpell:", glyphSpell)
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

	if (ZoneSpecDB.isMovable) or showTalents then
		talentBox:Show()
	else
		talentBox:Hide()
	end
	if (ZoneSpecDB.isMovable) or showGlyphs then
		glyphBox:Show()
	else
		glyphBox:Hide()
	end
end
function ZoneSpec:SetZSChar(isReset)
	--print("|cff22dd22ZS|r ZSChar:", ZSChar, "ZSChar[1]:", ZSChar[1])
	if isReset or (not ZSChar[1]) then
		for i = 1, GetNumSpecializations() do
			--print("ZSChar:", ZSChar, "i:", i)
			ZSChar[i] = {}
			--print("ZSChar:", ZSChar, "ZSChar[i]:", ZSChar[i])
		end
	end
end

-- Event Functions
local events = CreateFrame("Frame")

events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("BAG_UPDATE_DELAYED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
events:RegisterEvent("ZONE_CHANGED")
events:RegisterEvent("ZONE_CHANGED_INDOORS")
events:RegisterEvent("ZONE_CHANGED_NEW_AREA")

function events:ADDON_LOADED(name)
	if name == NAME then
		--print(name, "loaded")

		ZoneSpecDB = ZoneSpecDB or defaults
		if ZoneSpecDB.version < 1.5 then
			ZoneSpecDB.point = ZoneSpecDB.anchor
			ZoneSpecDB.anchor = nil
			ZoneSpecDB.version = ZSVersion
		else
			ZoneSpecDB.version = ZSVersion
		end
		
		ZSChar = ZSChar or {}
	elseif name == "Blizzard_TalentUI" then
		--print(name, "loaded")
		self:UnregisterEvent("ADDON_LOADED")
		CreateSaveButton()
	end
end

function events:BAG_UPDATE_DELAYED(...)
	--print("BAG_UPDATE_DELAYED")
	local name, count, icon = GetTalentClearInfo()
	--ZSReagent.Text:SetText(count)
	if (ZoneSpecDB.isMovable) or (count and count <= 6) then
		ZSReagent:Show()
		ZSReagent.BG:SetTexture(icon)
		ZSReagent.Text:SetText(count)
	else
		ZSReagent:Hide()
	end
end

function events:PLAYER_LOGIN()
	zone = GetMinimapZoneText()
	curSpec = GetSpecialization()
	--print("|cff22dd22ZS|r PLAYER_LOGIN;  zone:", zone, "curSpec:", curSpec)
	
	--print("Create character saved vars")
	ZoneSpec:SetZSChar()
	--print("Create an anchor")
	SetAnchor()
	--print("Create talent icons")
	CreateTextures()
	--print("Create reagent icon")
	CreateReagent()

	ZoneSpec:UpdateInfo()
end

events:SetScript("OnEvent", function(self, event, ...)
	if (event == "ADDON_LOADED") or (event == "BAG_UPDATE_DELAYED") or (event == "PLAYER_LOGIN") then
		--print(event, ";", ...)
		events[event](self, ...)
	else
		zone = GetMinimapZoneText()
		--print("|cff22dd22ZS|r", event, ";", zone, ";", ...)
		ZoneSpec:UpdateInfo()
	end
	--events[event](self, ...)
end)

-- Slash Commands
SLASH_ZONESPEC1, SLASH_ZONESPEC2 = "/zonespec", "/zs";
function SlashCmdList.ZONESPEC(msg, editBox)
	--print("msg:", msg)
	if msg == "toggle" then
		if ZoneSpecDB.isMovable then
			ZoneSpecDB.isMovable = false
			ZoneSpec:UpdateInfo()
			events:BAG_UPDATE_DELAYED()
			anchor:Hide()
			--print("ZoneSpec is locked");
		else
			ZoneSpecDB.isMovable = true
			ZoneSpec:UpdateInfo()
			events:BAG_UPDATE_DELAYED()
			anchor:Show()
			--print("ZoneSpec is unlocked");
		end
	elseif msg == "clear" then
		-- Clear the talent and glyph data for the current location.
		ZSChar[curSpec][zone] = nil
		ZoneSpec:UpdateInfo()
		print("|cff22dd22ZoneSpec|r: Data for", zone, "has been cleared.");
	elseif msg == "reset" then
		--print("Reset character saved vars")
		ZoneSpec:SetZSChar(true)
		print("|cff22dd22ZoneSpec|r: Data for this character has been reset.");
	elseif msg == "debug" then
		--print("defaults.isMovable:", defaults.isMovable);
		--print("ZoneSpecDB.isMovable:", ZoneSpecDB.isMovable);
	else
		print("Usage: /zs |cff22dd22command|r");
		print("|cff22dd22toggle|r - Show/Hide the anchor frame to move it or lock it in place.")
		print("|cff22dd22clear|r - Clear saved talents and glyphs for the current area.")
		print("|cff22dd22reset|r - Reset all data for the current character.")
	end
end

