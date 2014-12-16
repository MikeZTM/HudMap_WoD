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
		markRadius = {
			name = L["Mark of Chaos Radius"],
			type = "range",
			min = 1,
			max = 35,
			step = 1,
			bigStep = 1
		},
		mark = SN[164178],
	},
	defaults = {
		markRadius = 35,
		markColor = {r = 1, g = 0, b = 0, a = 0.6}
	},
	mark = {},
	-- Mark
	SPELL_AURA_APPLIED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		DEFAULT_CHAT_FRAME:AddMessage("HudMap 1!")
		if self:Option("markEnabled") and (spellID == 164178 or spellID == 158605 or spellID == 164176 or spellID == 164191) then
			DEFAULT_CHAT_FRAME:AddMessage("HudMap 2!")
			local radius = self:Option("markRadius")
			local r, g, b, a = self:Option("markColor")
			self.mark[destName] = register(HudMap:PlaceRangeMarkerOnPartyMember("highlight", destName, radius, 8, r, g, b, a):Rotate(360, 2):SetLabel(destName))
		end
	end,
	SPELL_AURA_REMOVED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		DEFAULT_CHAT_FRAME:AddMessage("HudMap 3!")
		if (spellID == 164178 or spellID == 158605 or spellID == 164176 or spellID == 164191) then
			DEFAULT_CHAT_FRAME:AddMessage("HudMap 4!")
			self.mark[destName] = free(self.mark[destName])
		end
	end
}

local bladefist= {
	name = L["Kargath Bladefist"],
	startEncounterIDs = 87444,
	endEncounterIDs = 87444,
	options = {
		rushRadius = {
			name = L["Berserker Rush"],
			type = "range",
			min = 1,
			max = 35,
			step = 1,
			bigStep = 1
		},
		rush = SN[159002],
	},
	defaults = {
		rushRadius = 10,
		rushColor = {r = 1, g = 0, b = 0, a = 0.6}
	},
	rush = {},
	SPELL_AURA_APPLIED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if (spellID == 158986 or spellID == 159001 or spellID == 159002 or spellID == 159004 or spellID == 159029) then
			DEFAULT_CHAT_FRAME:AddMessage("Berserker Rush!")
			local radius = self:Option("rushRadius")
			local r, g, b, a = self:Option("rushColor")
			self.rush[destName] = register(HudMap:PlaceRangeMarkerOnPartyMember("highlight", destName, radius, 8, r, g, b, a):Rotate(360, 2):SetLabel(destName))
		end
	end,
	SPELL_AURA_REMOVED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if (spellID == 158986 or spellID == 159001 or spellID == 159002 or spellID == 159004 or spellID == 159029) then
			self.rush[destName] = free(self.rush[destName])
		end
	end
}

local dummy= {
	name = L["Dummy"],
	startEncounterIDs = 79756,
	endEncounterIDs = 79756,
	options = {
		markRadius = {
			name = L["Mark of Chaos Radius"],
			type = "range",
			min = 1,
			max = 35,
			step = 1,
			bigStep = 1
		},
		mark = SN[8050],
	},
	defaults = {
		markRadius = 35,
		markColor = {r = 1, g = 0, b = 0, a = 0.6}
	},
	mark = {},
	-- Mark
	SPELL_AURA_APPLIED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		DEFAULT_CHAT_FRAME:AddMessage("1!")
		if spellID == 52127 then
			DEFAULT_CHAT_FRAME:AddMessage("2!")
			local radius = self:Option("markRadius")
			local r, g, b, a = self:Option("markColor")
			self.mark[destName] = register(HudMap:PlaceStaticMarkerOnPartyMember("highlight", destName, 3, 30, r, g, b, a):Rotate(360,4):Appear():RegisterForAlerts())
		end
	end,
	SPELL_AURA_REMOVED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if spellID == 52127 then
			DEFAULT_CHAT_FRAME:AddMessage("3!")
			self.mark[destName] = free(self.mark[destName])
		end
	end
}

encounters:RegisterModule(L["Highmaul"], bladefist, imperator, dummy)