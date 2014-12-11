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

local valiona = {
	name = L["Valiona and Theralion"],
	startEncounterIDs = { 45992, 45993 },
	endEncounterIDs = { 45992, 45993 },
	options = {
		blackout = SN[86788],
		magic = SN[86622],
		meteor = SN[86013],
		blast = SN[86369],
	},
	defaults = {
		blackoutColor = {r = 1, g = 0.4, b = 1, a = 0.4},
		magicColor = {r = 1, g = 1, b = 1, a = 0.6},
		meteorColor = {r = 0.3, g = 0.3, b = 0.7, a = 0.8},
		blastColor = {r = 0.3, g = 0.3, b = 0.5, a = 0.4},
	},
	blackout = {},
	twilightBlast = function(self)
		local target = encounters:GetMobTarget(45993)
		local r, g, b, a = self:Option("blastColor")
		if not target then return end
		register(HudMap:PlaceRangeMarkerOnPartyMember("highlight", target, 8, 10, r, g, b, a):Rotate(360, 12):Appear():SetLabel(destName))
	end,
	SPELL_AURA_APPLIED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if self:Option("blackoutEnabled") and (spellID == 86788 or spellID == 92876 or spellID == 92877 or spellID == 92878) then
			local r, g, b, a = self:Option("blackoutColor")
			self.blackout[destName] = register(HudMap:PlaceRangeMarkerOnPartyMember("highlight", destName, 8, 15, r, g, b, a):Rotate(360, 5):Appear():SetLabel(destName))
		elseif self:Option("magicEnabled") and (spellID == 86622 or spellID == 95639 or spellID == 95640 or spellID == 95641) then
			local r, g, b, a = self:Option("magicColor")
			register(HudMap:PlaceRangeMarkerOnPartyMember("highlight", destName, 10, 20, r, g, b, a):Rotate(360, 5):Appear():SetLabel(destName))
		end
	end,
	SPELL_CAST_START = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if self:Option("blastEnabled") and (spellID == 86369 or spellID == 92898 or spellID == 92899 or spellID == 92900) then
			self.invoker = self.invoker or function() self:twilightBlast() end
			encounters:Delay(self.invoker, 0.1)
		end
	end,
	UNIT_AURA = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if UnitDebuff(sourceName, GetSpellInfo(88518)) and self:Option("meteorEnabled") then
			local r, g, b, a = self:Option("meteorColor")
			register(HudMap:PlaceRangeMarkerOnPartyMember("highlight", destname, 6, 7, r, g, b, a):Rotate(360, 12):Appear():SetLabel(destName):RegisterForAlerts())
		end
	end,
	SPELL_AURA_REMOVED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if spellID == 86788 or spellID == 92876 or spellID == 92877 or spellID == 92878 then
			self.blackout[destName] = free(self.blackout[destName])
		end
	end
}

local council = {
	name = L["Twilight Ascendant Council"],
	startEncounterIDs = { 43686, 43687 },
	endEncounterIDs = 43735,
	options = {
		rod = SN[83099],
	},
	defaults = {
		rodColor = {r = 1, g = 1, b = 1, a = 0.6},
	},
	rod = {},
	SPELL_AURA_APPLIED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if self:Option("rodEnabled") and spellID == 83099 then
			local r, g, b, a = self:Option("rodColor")
			self.rod[destName] = register(HudMap:PlaceRangeMarkerOnPartyMember("highlight", destName, 20, 30, r, g, b, a):Rotate(360, 5):Appear():SetLabel(destName))
		end
	end,
	SPELL_AURA_REMOVED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if spellID == 83099 then
			self.rod[destName] = free(self.rod[destName])
		end
	end
}

-- Thanks to Aetherlight for Corrupting Crash code
local chogall = {
	name = L["Cho'Gall"],
	startEncounterIDs = 43324,
	endEncounterIDs = 43324,
	options = {
		worshipRadius = {
			name = L["Worship Radius"],
			type = "range",
			min = 1,
			max = 5,
			step = 1,
			bigStep = 1
		},
		worship = SN[91317],
		crash = SN[81685],
	},
	defaults = {
		worshipRadius = 2,
		worshipColor = {r = 1, g = 0.4, b = 0.4, a = 0.8},
		crashColor = {r = 0.5, g = 0, b = 0.5, a= 0.6},
	},
	worship = {},
	crash = function(self, sourceGUID)
		local targetname = nil
		for i=1, GetNumRaidMembers() do
			if UnitGUID("raid"..i.."target") == sourceGUID then
				targetname = UnitName("raid"..i.."targettarget")
				break
			end
		end
		if targetname then
			local r, g, b, a = self:Option("crashColor")
			register(HudMap:PlaceStaticMarkerOnPartyMember("highlight", targetname, 10, 5, r, g, b, a):Rotate(360,4):Appear():RegisterForAlerts())
		end
	end,
	SPELL_AURA_APPLIED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if self:Option("worshipEnabled") and (spellID == 91317 or spellID == 93365 or spellID == 93366 or spellID == 93367) then
			local radius = self:Option("worshipRadius")
			local r, g, b, a = self:Option("worshipColor")
			self.worship[destName] = register(HudMap:PlaceRangeMarkerOnPartyMember("highlight", destName, radius, 30, r, g, b, a):Rotate(360, 5):Appear():SetLabel(destName))
		end
	end,
	SPELL_CAST_SUCCESS = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if (spellID == 81685 or spellID == 93178 or spellID == 93179 or spellID == 93180) and self:Option("crashEnabled") then
			
			self.invoker = function() self:crash(sourceGUID) end
			encounters:Delay(self.invoker, 0.2)
		end
	end,
	SPELL_AURA_REMOVED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if spellID == 91317 or spellID == 93365 or spellID == 93366 or spellID == 93367 then
			self.worship[destName] = free(self.worship[destName])
		end
	end
}

local sinestra = {
	name = "|cFFFF4444" .. L["Sinestra"] .. "|r",
	startEncounterIDs = 45213,
	endEncounterIDs = 45213,
	options = {
		wrack = "|cFFFF4444" .. L["Wrack"] .. "|r",
		wrackStart = "|cFFFF4444" .. L["Wrack Start"] .. "|r",
		wrackEnd = "|cFFFF4444" .. L["Wrack End"] .. "|r",
		wrackRadius = {
			name = L["Wrack Radius"],
			type = "range",
			min = 1,
			max = 5,
			step = 1,
			bigStep = 1
		},
	},
	defaults =  {
		wrackStartColor = {r = 0, g = 1, b = 0, a = .7},
		wrackEndColor = {r = 1, g = 0, b = 0, a = .7},
		wrackEnabled = false,
		wrackStartEnabled = false,
		wrackEndEnabled = false,
		wrackRadius = 2,
	},
	wrack = {},
	wrackDuration = {},
	GetDeltas = function(self)
		local r, g, b, a = self:Option("wrackStartColor")
		local r1, g1, b1, a1 = self:Option("wrackEndColor")
		return r1-r, g1-g, b1-b, a1-a
	end,
	CheckColors = function(self, r, g, b, a)
		if r > 1 then r = 1 end
		if r < 0 then r = 0 end
		if g > 1 then g = 1 end
		if g < 0 then g = 0 end
		if b > 1 then b = 1 end
		if b < 0 then b = 0 end
		if a > 1 then a = 1 end
		if a < 0 then a = 0 end
		return r, g, b, a
	end,
	SPELL_AURA_APPLIED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if self:Option("wrackEnabled") and (spellID == 89421 or spellID == 92955) then
			local r, g, b, a = self:Option("wrackStartColor")
			local radius = self:Option("wrackRadius")
			self.wrack[destName] = self.wrack[destName] or register(HudMap:PlaceRangeMarkerOnPartyMember("highlight", destName, radius, 10, r, g, b, a):Rotate(360, 5):Appear():SetLabel(destName .. ": " .. "0"))
			self.wrackDuration[destName] = 0
		end
	end,
	SPELL_AURA_REMOVED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if self:Option("wrackEnabled") and (spellID == 89421 or spellID == 92955) then
			self.wrack[destName] = free(self.wrack[destName])
			self.wrackDuration[destName] = 0
		end
	end,
	SPELL_PERIODIC_DAMAGE = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if self:Option("wrackEnabled") and (spellID == 89421 or spellID == 92955) then
			local radius = self:Option("wrackRadius")
			local dr, dg, db, da = self:GetDeltas()
			self.wrackDuration[destName] = self.wrackDuration[destName] + 2
			self.wrack[destName] = free(self.wrack[destName])
			local ir, ig, ib, ia = self:Option("wrackStartColor")
			local r, g, b, a = ir + dr / 30 * self.wrackDuration[destName], ig + dg / 30 * self.wrackDuration[destName], ib + db / 30 * self.wrackDuration[destName], ia + da / 30 * self.wrackDuration[destName]
			r, g, b, a = self:CheckColors(r, g, b, a)
			self.wrack[destName] = register(HudMap:PlaceRangeMarkerOnPartyMember("highlight", destName, radius, 10, r, g, b, a):Rotate(360, 5):Appear():SetLabel(destName .. ": " .. self.wrackDuration[destName]))
		end
	end,
}

encounters:RegisterModule(L["Bastion of Twilight"], valiona, council, chogall, sinestra)