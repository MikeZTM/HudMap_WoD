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

local orbBuf = {}
local halion = {
	name = L["Halion"],	
	startEncounterIDs = 39863,
	endEncounterIDs = 39863,
	options = {
		fieryCombustion = SN[74562],
		soulConsumption = SN[74792],
		orbSpeed = {
			name = L["Orb Speed"],
			type = "range",
			min = 35,
			max = 50,
			step = 0.1,
			bigStep = 0.1
		},
		orbOffset = {
			name = L["Orb Offset"],
			type = "range",
			min = 0,
			max = 360,
			step = 1,
			bigStep = 1
		},    
		-- meteorStrike = SN[75877],
	},
	defaults = {
    orbSpeed = 42.5,
    orbOffset = 40,
		fieryCombustionColor = {r = 1, g = 0.35, b = 0, a = 0.4},
		soulConsumptionColor = {r = 0, g = 0.35, b = 0.5, a = 0.4},
		meteorStrikeColor = {r = 1, g = 0.35, b = 0, a = 0.4}
	},
	pew_pew_lazers_center = { 369.71918592321, 226.96435510462 },
	radius = 95 / 2,
	MARK_OF_CONSUMPTION = 74567,
	MARK_OF_COMBUSTION = 74795,
	marks = {},
	orbs = {},
	markMarkers = {},
	doMark = function(self, spellID, destName, isLong)
		self.markMarkers[destName] = free(self.markMarkers[destName], self, "mark" .. spellID .. destName)
		local stacks = (self.marks[destName] or 1)
		if stacks < 1 then stacks = 1 end
		local size = encounters:IsHeroic() and stacks * 4 or 4
		local timer = isLong and 40 or 2
		local r, g, b, a
		if spellID == 74567 and self:Option("fieryCombustionEnabled") then
			r, g, b, a = self:Option("fieryCombustionColor")
		elseif spellID == 74795 and self:Option("soulConsumptionEnabled") then
			r, g, b, a = self:Option("soulConsumptionColor")
		end	
		if r then
			local t
			if isLong then
				local x, y = HudMap:GetUnitPosition(destName)
				t = HudMap:PlaceRangeMarker("timer", x, y, size, timer, r, g, b, a):Identify(self, "mark" .. spellID .. destName)
			else
				t = HudMap:PlaceRangeMarkerOnPartyMember("timer", destName, size, timer, r, g, b, a):Identify(self, "mark-stack-" .. stacks .. "-" .. spellID .. destName)
				self.markMarkers[destName] = t
			end
			register(t):Rotate(360, timer):Appear():RegisterForAlerts():SetLabel(destName):Broadcast()
		end
	end,
	SPELL_AURA_APPLIED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if spellID == 71289 and self:Option("meteorStrikeEnabled") then
			-- local r, g, b, a = self:Option("meteorStrikeColor")
			-- self.markMarkers[destName] = register(HudMap:PlaceRangeMarkerOnPartyMember("timer", destName, 8, 12, r, g, b, a):Rotate(360, 12):Appear():RegisterForAlerts():SetLabel(destName))
			
		elseif spellID == self.MARK_OF_CONSUMPTION or spellID == self.MARK_OF_COMBUSTION then
			self.marks[destName] = 1
			self:doMark(spellID, destName)
		end
	end,
	SPELL_AURA_APPLIED_DOSE = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		-- Consumption, Combustion
		if spellID == self.MARK_OF_CONSUMPTION or spellID == self.MARK_OF_COMBUSTION then
			self.marks[destName] = (self.marks[destName] or 0) + 1
			self:doMark(spellID, destName)
		end
	end,
	SPELL_AURA_REMOVED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if spellID == self.MARK_OF_CONSUMPTION or spellID == self.MARK_OF_COMBUSTION then
			self:doMark(spellID, destName, true)
		end
	end,
	CHAT_MSG_RAID_BOSS_EMOTE = function(self, msg)
		-- do return end		-- Orb location prediction doesn't work yet
		if msg == L["The orbiting spheres pulse with dark energy!"] then
			self.orbs["orb1"].showOffset = true
			self.orbs["orb1"]:EdgeTo(self.orbs["orb2"], nil, 15, 0.7, 0.3, 1, 0.4):TrackFrom(self.orbs["orb1"]):TrackTo(self.orbs["orb2"])
			if encounters:IsHeroic() then
				self.orbs["orb3"]:EdgeTo(self.orbs["orb4"], nil, 15, 0.7, 0.3, 1, 0.4):TrackFrom(self.orbs["orb3"]):TrackTo(self.orbs["orb4"])
			end
		end
	end,
	orb_offsets = {0.5, 1.5, 0, 1},
	CHAT_MSG_MONSTER_YELL = function(self, msg)
		-- do return end		-- Orb location prediction doesn't work yet
		if msg == L["Your world teeters on the brink of annihilation. You will ALL bear witness to the coming of a new age of DESTRUCTION!"] then
			self.phaseOneStartTime = GetTime()
		elseif msg == L["You will find only suffering within the realm of twilight! Enter if you dare!"] then
			self.phaseTwoStartTime = GetTime()
			local orbs = encounters:IsHeroic() and 4 or 2
			for i = 1, orbs do
				local t = HudMap:PlaceRangeMarker("highlight", 0, 0, 4, nil, 0.5, 0, 1, 0.4):Identify(self, "halion_orb" .. i)
				t.RegisterCallback(self, "Update")
				t.orb_offset = self.orb_offsets[i] * math.pi
				self.orbs["orb" .. i] = register(t)
			end
		end
	end,
	orbPosition = function(self, bearing)		
		local x = math.sin(bearing) * self.radius + self.pew_pew_lazers_center[1]
		local y = math.cos(bearing) * self.radius + self.pew_pew_lazers_center[2]
		return x, y
	end,
	Update = function(self, callback, orb)
		local ROTATE_TIME = self:Option("orbSpeed")		-- How long it takes an orb to make a complete circle.
		local ROTATE_OFFSET = self:Option("orbOffset") / 360 * 2 * math.pi
		-- 4 seconds from yell to portal spawn
		local delta = (GetTime() - self.phaseTwoStartTime) % ROTATE_TIME
		local offset = orb.orb_offset + (math.pi * 2 / ROTATE_TIME * delta) + ROTATE_OFFSET
		orb.stickX, orb.stickY = self:orbPosition(offset)		
	end
}
Halion = halion

encounters:RegisterModule(L["Ruby Sanctum"], halion)