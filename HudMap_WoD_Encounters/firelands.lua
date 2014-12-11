local encounters = HudMap:GetModule("Encounters")
local HudMap = _G.HudMap
local UnitName, UnitIsDead = _G.UnitName, _G.UnitIsDead
local parent = HudMap
local L = LibStub("AceLocale-3.0"):GetLocale("HudMap")
local SN = parent.SN

local function register(e)	
	encounters:RegisterEncounterMarker(e)
	return e
end

local free = parent.free

local shannox = {
	name = L["Shannox"],
	startEncounterIDs = 53691,
	endEncounterIDs = 53691,
	options = {
		crystal = SN[99836],
		immo = SN[99839],
		crystalTime = {
			name = L["Crystal Trap Duration"],
			type = "range",
			min = 1,
			max = 60,
			step = 1,
			bigStep = 10,
		},
		immoTime = {
			name = L["Immolation Trap Duration"],
			type = "range",
			min = 1,
			max = 60,
			step = 1,
			bigStep = 10,
		},
	},
	defaults = {
		crystalColor = {r = 1, g = 0.4, b = 1, a = 0.5},
		immoColor = {r = 1, g = 0.35, b = 0, a = 0.5},
		crystalTime = 30,
		immoTime = 30,
	},
	trapHandler = function(self, scans, isTank)
		if UnitExists("boss1target") then
			local targetname = UnitName("boss1target")
			if UnitDetailedThreatSituation("boss1target", "boss1") and not isTank then -- Check if his target is highest thread
				if scans < 12 then
					self.invoker = function() self:trapHandler(scans + 1) end
					encounters:Delay(self.invoker, 0.05)
				else
					self:trapHandler(scans + 1, true)
				end
			else
				return targetname
			end
		else
			if scans < 12 then
				self.invoker = function() self:trapHandler(scans + 1) end
				encounters:Delay(self.invoker, 0.05)
			end
		end
	end,
	SPELL_SUMMON = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if self:Option("crystalEnabled") and spellID == 99836 then
			local target = self:trapHandler(0)
			local crystalTime = self:Option("crystalTime")
			local r, g, b, a = self:Option("crystalColor")
			register(HudMap:PlaceStaticMarkerOnPartyMember("highlight", target, 3, crystalTime, r, g, b, a):Rotate(360,4):Appear():RegisterForAlerts())
		elseif self:Option("immoEnabled") and spellID == 99839 then
			local target = self:trapHandler(0)
			local immoTime = self:Option("immoTime")
			local r, g, b, a = self:Option("immoColor")
			register(HudMap:PlaceStaticMarkerOnPartyMember("highlight", target, 3, immoTime, r, g, b, a):Rotate(360,4):Appear():RegisterForAlerts())
		end
	end,
}

local bethtilac = {
	name = L["Beth'tilac"],
	startEncounterIDs = 52498,
	endEncounterIDs = 52498,
	options = {
		kiss = SN[99476],
	},
	defaults = {
		kissColor = {r = 1, g = 0, b = .2, a = .6},
	},
	kiss = {},
	SPELL_AURA_APPLIED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if self:Option("kissEnabled") and (spellID == 99476 or spellID == 99506) then
			local r, g, b, a = self:Option("kissColor")
			self.kiss[destName] = free(kiss[destName])
			self.kiss[destName] = register(HudMap:PlaceStaticMarkerOnPartyMember("highlight", destName, 10, 20, r, g, b, a):Rotate(360,4):Appear():RegisterForAlerts())
		end
	end,
}

local staghelm = {
	name = L["Majordomo Staghelm"],
	startEncounterIDs = 52571,
	endEncounterIDs = 52571,
	options = {
		leap = SN[98476],
	},
	defaults = {
		leapColor = {r = 1, g = .3, b = 0, a = .7},
	},
	leapTarget = function(self)
		local target = nil
		target = encounters:GetMobTarget(52571)
		if target then
			local r, g, b, a = self:Option("leapColor")
			register(HudMap:PlaceStaticMarkerOnPartyMember("highlight", target, 10, 60, r, g, b, a):Rotate(360,4):Appear():RegisterForAlerts())
		end
	end,
	SPELL_CAST_SUCCESS = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if self:Option("leapEnabled") and spellID == 98476 then
			self.invoker = function() self:leapTarget() end
			encounters:Delay(self.invoker, 0.2)
		end
	end,
}

encounters:RegisterModule(L["Firelands"], shannox, bethtilac, staghelm)