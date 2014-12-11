local encounters = HudMap:GetModule("Encounters")
local HudMap = _G.HudMap
local UnitName, UnitIsDead = _G.UnitName, _G.UnitIsDead
local parent = HudMap
local L = LibStub("AceLocale-3.0"):GetLocale("HudMap")
local SN = parent.SN
local UnitIsMappable = HudMap.UnitIsMappable

local function register(e)
	encounters:RegisterEncounterMarker(e)
	return e
end

local free = parent.free

local beasts = {
	name = L["Northrend Beasts"],
	options = {
		charge = {
			type = "toggle",
			name = L["Charge Warning"]
		},
		fire = SN[67621],
		bile = SN[67620],
	},
	startEncounterIDs = 34796,
	endEncounterIDs = 34797,
	fires = {},
	biles = {},
	bileArrows = {},
	defaults = {
		bileColor = {r = 0, g = 0.7, b = 0, a = 0.6},
		fireColor = {r = 0.7, g = 0.2, b = 0, a = 0.6}
	},
	Start = function(self)
		wipe(self.fires)
		wipe(self.biles)
		wipe(self.bileArrows)
	end,
	Win = function(self)
		wipe(self.fires)
		wipe(self.biles)
		wipe(self.bileArrows)
	end,
	SPELL_AURA_APPLIED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if (spellID == 67620 or spellID == 67619 or spellID == 67618 or spellID == 66823) and self:Option("bileEnabled") then
			local r, g, b, a = self:Option("bileColor")
			free(self.biles[destName])
			self.biles[destName] = register(HudMap:PlaceRangeMarkerOnPartyMember("glow", destName, 5, 30, r, g, b, a):Appear():SetLabel(destName):Identify(self, "bile"..destName))
			self.biles[destName].RegisterCallback(self, "Free", "FreeMarker")
		elseif (spellID == 67621 or spellID == 67623 or spellID == 67622 or spellID == 66870 or spellID == 66869) and self:Option("fireEnabled") then
			local r, g, b, a = self:Option("fireColor")
			free(self.fires[destName], self, "fire"..destName)
			self.fires[destName] = register(HudMap:PlaceRangeMarkerOnPartyMember("highlight", destName, 5, 30, r, g, b, a):Appear():SetLabel(destName):Identify(self, "fire"..destName))
			self.fires[destName].RegisterCallback(self, "Free", "FreeMarker")
			for k, v in pairs(self.biles) do
				local key = k .. ":" .. destName
				free(self.bileArrows[key], self, key)
				self.bileArrows[key] = v:EdgeFrom(self.fires[destName], nil, 30, 1, 1, 1, 1):Identify(self, key)
			end
		end
	end,
	SPELL_AURA_REMOVED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if (spellID == 67620 or spellID == 67619 or spellID == 67618 or spellID == 66832) and self:Option("bileEnabled") then
			free(self.biles[destName], self, "bile"..destName)
			for k, v in pairs(self.bileArrows) do
				local bile, fire = (":"):split(k)
				if bile == destName then
					self.bileArrows[k] = free(v, self, k)
				end
			end
		elseif (spellID == 67621 or spellID == 67623 or spellID == 67622 or spellID == 66870 or spellID == 66869) and self:Option("fireEnabled") then
			free(self.fires[destName], self, "fire"..destName)
			for k, v in pairs(self.bileArrows) do
				local bile, fire = (":"):split(k)
				if fire == destName then
					self.bileArrows[k] = free(v, self, k)
				end
			end
		end
	end,
	CHAT_MSG_MONSTER_EMOTE = function(self, message)
		local who = message.match("glares at %t")
		if who then
			register(HudMap:PlaceRangeMarkerOnPartyMember("skull", who, "30px", 8, 1, 1, 1, 1):Appear():SetLabel(who))
		end
	end,
	FreeMarker = function(self, cbk, b)
		for k, v in pairs(self.biles) do
			if v == b then
				self.biles[k] = nil
				return
			end
		end
		for k, v in pairs(self.fires) do
			if v == b then
				self.fires[k] = nil
				return
			end
		end
	end
}

local jaraxxus = {
	name = L["Lord Jaraxxus"],
	startEncounterIDs = 34780,
	endEncounterIDs = 34780,
	units = {},
	Start = function(self)
		for index, unit in HudMap.group() do
			local n = UnitName(unit)
			if n and not UnitIsDead(unit) and not UnitIsUnit("player", unit) then
				self.units[n] = register(HudMap:PlaceRangeMarkerOnPartyMember("ring", n, 8, nil, 1, 1, 1, 0.2):Appear():RegisterForAlerts(true):Identify(self, "range"))
			end
		end	
	end,
	UNIT_DIED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		free(self.units[destName], self, "range")
	end
}

encounters:RegisterModule(L["Tournament"], beasts, jaraxxus)