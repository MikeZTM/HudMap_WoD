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

local imperator= {
	name = L["Imperator Mar'gok"],
	startEncounterIDs = 87818,
	endEncounterIDs = 87818,
	options = {
		spikeRadius = {
			name = L["Mark of Chaos Radius"],
			type = "range",
			min = 1,
			max = 35,
			step = 1,
			bigStep = 1
		},
		spikes = SN[164178],
	},
	defaults = {
		spikeRadius = 35,
		spikesColor = {r = 1, g = 0, b = 0, a = 0.6}
	},
	spikes = {},
	-- Bone Spikes
	SPELL_AURA_APPLIED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if self:Option("spikesEnabled") and (spellID == 164178 or spellID == 158605 or spellID == 164176 or spellID == 164191) then
			local radius = self:Option("spikeRadius")
			local r, g, b, a = self:Option("spikesColor")
			self.spikes[destName] = register(HudMap:PlaceRangeMarkerOnPartyMember("highlight", destName, radius, 8, r, g, b, a):Rotate(360, 2):SetLabel(destName))
		end
	end,
	SPELL_AURA_REMOVED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if (spellID == 164178 or spellID == 158605 or spellID == 164176 or spellID == 164191) then
			self.spikes[destName] = free(self.spikes[destName])
		end
	end
}

encounters:RegisterModule(L["Highmaul"], imperator)