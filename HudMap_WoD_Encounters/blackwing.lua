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

local omnotron = {
	name = L["Omnotron Defense System"],
	startEncounterIDs = { 42180, 42178, 42179, 42166 },
	endEncounterIDs = { 42180, 42178, 42179, 42166 },
	options = {
		conductor = SN[79888],
	},
	defaults = {
		conductorColor = {r = .9, g = .9, b = 1, a = 0.6},
	},
	conductor = {},
	SPELL_AURA_APPLIED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if self:Option("conductorEnabled") and (spellID == 79888 or spellID == 91431) then
			local r, g, b, a = self:Option("conductorColor")
			self.conductor[destName] = register(HudMap:PlaceRangeMarkerOnPartyMember("highlight", destName, 10, 15, r, g, b, a):Rotate(360, 6):Appear():SetLabel(destName))
		elseif self:Option("conductorEnabled") and (spellID == 91432 or spellID == 91433) then
			local r, g, b, a = self:Option("conductorColor")
			self.conductor[destName] = register(HudMap:PlaceRangeMarkerOnPartyMember("highlight", destName, 15, 15, r, g, b, a):Rotate(360, 6):Appear():SetLabel(destName))
		end
	end,
}

local maloriak = {
	name = L["Maloriak"],
	startEncounterIDs = 41378,
	endEncounterIDs = 41378,
	options = {
		freeze = SN[77699],
		sludge = "|cFFFF4444" .. SN[92987] .. "|r",
	},
	defaults = {
		freezeColor = {r = .1, g = .1, b = 1, a = 0.7},
		sludgeColor = {r = 1, g = 0.4, b = 1, a = 0.6},
		sludgeEnabled = false,
	},
	freeze = {},
	sludge = {},
	sludgeCount = 0,
	blackPhase = true,
	inMarker = function(self, destName)
		for k,v in pairs(sludge) do
			local x,y = v:Location()
			local dist = HudMap:DistanceToPoint(destName, x, y)
			if dist <= 3 then return true else return false end
		end
	end,
	SPELL_AURA_APPLIED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if self:Option("freezeEnabled") and (spellID == 77699 or spellID == 92978 or spellID == 92979 or spellID == 92980) then
			local r, g, b, a = self:Option("freezeColor")
			self.freeze[destName] = register(HudMap:PlaceRangeMarkerOnPartyMember("highlight", destName, 5, 15, r, g, b, a):Rotate(360, 4):Appear():SetLabel(destName))
			self.blackPhase = true
		elseif self:Option("sludgeEnabled") and self.blackPhase and (spellID == 92930 or spellID == 92986 or spellID == 92987 or spellID == 92988) then
			if not inMarker(destName) then
				local r, g, b, a = self:Option("sludgeColor")
				tinsert(sludge, register(HudMap:PlaceStaticMarkerOnPartyMember("highlight", destName, 3, nil, r, g, b, a):RegisterForAlerts():Appear()))
			end
		end
	end,
	SPELL_AURA_REMOVED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if spellID == 77699 or spellID == 92978 or spellID == 92979 or spellID == 92980 then
			self.freeze[destName] = free(self.freeze[destName])
		end
	end,
	UNIT_DIED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if encounters:IsHeroic() and HudMap.GuidToMobID[destGUID] == 49811 then
			self.sludgeCount = self.sludgeCount + 1
			local sludgeCount = self.sludgeCount
			if encounters:GetDungeonSize() == 25 then
				if sludgeCount >= 5 then
					blackPhase = false
					for i=1,#sludge do
						self.sludge[i] = free(sludge[i])
					end
					sludgeCount = 0
				end
			elseif encounters:GetDungeonSize() == 10 then
				if sludgeCount >= 3 then
					blackPhase = false
					for i=1,#sludge do
						self.sludge[i] = free(sludge[i])
					end
					self.sludge = {}
					sludgeCount = 0
				end
			end
		end
	end,
}


local chimaeron = {
	name = L["Chimaeron"],
	startEncounterIDs = 43296,
	endEncounterIDs = 43296,
	options =  {
		caustic = L["Caustic Slime Range"],
	},
	defaults = {
		causticEnabled = false,
		causticColor = {r = .1, g = 1, b = .2, a = 0.6},
	},
	feud = false,
	caustic = {},
	Start = function(self)
		self.feud = false
	end,
	SPELL_CAST_SUCCESS = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if spellID == 88872 then -- Feud
			self.feud = true
			self.caustic["player"] = free(self.caustic["player"])
		elseif spellID == 82890 then -- Mortality
			self.feud = true
			self.caustic["player"] = free(self.caustic["player"])
		end
	end,
	SPELL_CAST_START = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if spellID == 82848 then -- Massacre
			self.feud = false
		end
	end,
	SPELL_AURA_APPLIED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if self:Option("causticEnabled") and spellID == 88826 and not self.feud then -- Double Attack
			local r, g, b, a = self:Option("causticColor")
			self.caustic["player"] = self.caustic["player"] or register(HudMap:PlaceRangeMarkerOnPartyMember("highlight", "player", 6, 30, r, g, b, a):Rotate(360, 6):Appear():RegisterForAlerts():SetLabel("player"))
		end
	end,
	UNIT_DIED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if sourceName == UnitName("player") then
			self.feud = false
			self.caustic["player"] = free(self.caustic["player"])
		end
	end,
}

encounters:RegisterModule(L["Blackwing Descent"], omnotron, maloriak, chimaeron)