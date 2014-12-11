local modName = "Tracking"
local parent = HudMap
local L = LibStub("AceLocale-3.0"):GetLocale("HudMap")
local mod = HudMap:NewModule(modName, "AceEvent-3.0")
local trackingSpells = {[2383] = true, [2580] = true, [43308] = true}
local playerGUID = UnitGUID("player")

local db
local options = {
	type = "group",
	name = L["Tracking"],
	args = {
		enable = {
			type = "toggle",
			name = L["Enable Gathering Mode"],
			order = 100,
			get = function()
				return db.enable
			end,
			set = function(info, v)
				db.enable = v
				mod:UpdateGatherMode()
			end
		},
		gathermatedesc = {
			type = "description",
			name = L["GatherMate is a resource gathering helper mod. Installing it allows you to have resource pins on your HudMap."],
			order = 104
		},
		gathermate = {
			type = "toggle",
			order = 105,
			name = L["Use GatherMate pins"],
			disabled = function()
				return GatherMate == nil
			end,
			get = function()
				return db.useGatherMate
			end,
			set = function(info, v)
				db.useGatherMate = v
				if HudMapStandaloneCluster:IsVisible() then
					onHide(HudMapStandaloneCluster, true)
					onShow(HudMapStandaloneCluster)
				end
			end
		},
		questhelper = {
			type = "toggle",
			order = 106,
			name = L["Use QuestHelper pins"],
			disabled = function()
				return QuestHelper == nil or QuestHelper.SetMinimapObject == nil
			end,
			get = function()
				return db.useQuestHelper
			end,
			set = function(info, v)
				db.useQuestHelper = v
				if HudMapStandaloneCluster:IsVisible() then
					onHide(HudMapStandaloneCluster, true)
					onShow(HudMapStandaloneCluster)
				end
			end			
		},
		routesdesc = {
			type = "description",
			name = L["Routes plots the shortest distance between resource nodes. Install it to show farming routes on your HudMap."],
			order = 109,
		},		
		routes = {
			type = "toggle",
			name = L["Use Routes"],
			order = 110,
			disabled = function()
				return Routes == nil or Routes.ReparentMinimap == nil
			end,
			get = function()
				return db.useRoutes
			end,
			set = function(info, v)
				db.useRoutes = v
				if HudMapStandaloneCluster:IsVisible() then
					onHide(HudMapStandaloneCluster, true)
					onShow(HudMapStandaloneCluster)
				end
			end
		}
	}
}

local defaults = {
	profile = {
		enable = true,
		useGatherMate = true,
		useQuestHelper = true,
		useRoutes = true
	}
}

function mod:OnInitialize()
	self.db = parent.db:RegisterNamespace(modName, defaults)
	db = self.db.profile
	parent:RegisterModuleOptions(modName, options, modName)
end

function mod:OnEnable()
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("PLAYER_UPDATE_RESTING", "UpdateGatherMode")
	self:RegisterEvent("UPDATE_STEALTH", "UpdateGatherMode")
	self:RegisterEvent("ZONE_CHANGED", "UpdateGatherMode")
	self:UpdateGatherMode()	
end

function mod:UpdateGatherMode()
	local flag
	
	if IsInInstance() or IsResting() or IsStealthed() or GetNumRaidMembers() > 0 or not db.enable then
		flag = false
	else
		for k, v in pairs(trackingSpells) do
			local name, _, tex = GetSpellInfo(k)
			if tex == GetTrackingTexture() then
				flag = true
				break
			end
		end
	end
	if flag ~= nil then self:ToggleGatherMode(flag) end
end

function mod:ToggleGatherMode(flag)	
	if flag == true and not self.trackingMarker then
		HudMapMinimap:SetZoom(0)
		self.trackingMarker = HudMap:PlaceRangeMarkerOnPartyMember([[SPELLS\CIRCLE.BLP]], "player", 100, nil, 0, 0.7, 0, 0.6, "ADD"):Appear()
	elseif flag == false and self.trackingMarker then
		self.trackingMarker:Free()
		self.trackingMarker = nil
	end
end

function mod:COMBAT_LOG_EVENT_UNFILTERED(ev, timestamp, event, hideCaster, srcGUID, srcName, srcFlags, srcRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, ...)
	if srcGUID == playerGUID and trackingSpells[spellID] then
		if event ==  "SPELL_AURA_REMOVED" then
			self:ToggleGatherMode(false)
		elseif event == "SPELL_AURA_APPLIED" then
			self:ToggleGatherMode(true)
		end			
	end
end
