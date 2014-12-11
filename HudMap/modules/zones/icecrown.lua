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

local marrowgar = {
	name = L["Marrowgar"],
	startEncounterIDs = 36612,
	endEncounterIDs = 36612,
	options = {
		spikeRadius = {
			name = L["Bone Spike Radius"],
			type = "range",
			min = 1,
			max = 5,
			step = 1,
			bigStep = 1
		},
		spikes = SN[73143],
	},
	defaults = {
		spikeRadius = 2,
		spikesColor = {r = 1, g = 0, b = 0, a = 0.6}
	},
	spikes = {},
	-- Bone Spikes
	SPELL_AURA_APPLIED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if self:Option("spikesEnabled") and spellID == 69065 then
			local radius = self:Option("spikeRadius")
			local r, g, b, a = self:Option("spikesColor")
			self.spikes[destName] = register(HudMap:PlaceRangeMarkerOnPartyMember("highlight", destName, radius, 8, r, g, b, a):Rotate(360, 2):SetLabel(destName))
		end
	end,
	SPELL_AURA_REMOVED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if spellID == 69065 then
			self.spikes[destName] = free(self.spikes[destName])
		end
	end
}

local deathwhisper = {
	name = L["Lady Deathwhisper"],	
	startEncounterIDs = 36855,
	endEncounterIDs = 36855,
	options = {
		mindControl = SN[71289],
	},
	defaults = {
		mindControlColor = {r = 1, g = 0.35, b = 0, a = 0.4}
	},	
	SPELL_AURA_APPLIED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if spellID == 71289 and self:Option("mindControlEnabled") then
			local r, g, b, a = self:Option("mindControlColor")
			register(HudMap:PlaceRangeMarkerOnPartyMember("timer", destName, 8, 12, r, g, b, a):Rotate(360, 12):Appear():RegisterForAlerts():SetLabel(destName))
		end
	end	
}

local festergut = {
	name = L["Festergut"],	
	startEncounterIDs = 36626,
	endEncounterIDs = 36626,	
	options = {
		spores = SN[69279],
		gas = SN[69240],
	},
	defaults = {
		sporesColor = {r = 1, g = 0.5, b = 0, a = 0.8},
		gasColor = {r = 0.5, g = 0.5, b = 0, a = 0.8}
	},
	-- Gas Spore, 8yd radius
	SPELL_AURA_APPLIED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if spellID == 69279 and self:Option("sporesEnabled") then
			local r, g, b, a = self:Option("sporesColor")
			register(HudMap:PlaceRangeMarkerOnPartyMember("timer", destName, 8, 12, r, g, b, a):Rotate(360, 12):Appear():SetLabel(destName))
		elseif (spellID == 69240 or spellID == 69248 or spellID == 71218 or spellID == 72272 or spellID == 72273 or spellID == 73019 or spellID == 73020) and self:Option("gasEnabled") then
			local r, g, b, a = self:Option("gasColor")
			register(HudMap:PlaceRangeMarkerOnPartyMember("timer", destName, 8, 6, r, g, b, a):Rotate(360, 8):Appear():SetLabel(destName))
		end
	end
}

local rotface = {
	name = L["Rotface"],
	startEncounterIDs = 36627,
	endEncounterIDs = 36627,
	options = {
		splash = L["Splash Zones"],
		infection = L["Infection Arrow"],
		vile = SN[72272],
	},
	defaults = {
		splashColor = {r = 0, g = 1, b = 0, a = 0.5},
		infectionColor = {r = 0, g = 1, b = 0, a = 0.8},
		vileColor = {r = 1, g = 0.5, b = 0, a = 0.8}
	},
	-- Throttle to prevent the multi-cast bug. Thanks incessantjunk and olog.	
	-- Will improperly prevent a second ooze from showing its explosions if popped within 5 sec of the first, but if you're
	-- doing that, the addon probably won't save you anyway.
	lastSplash = 0,
	showSplashes = function(self)
		for index, unit in encounters.group() do
			if not UnitIsDead(unit) then
				local x, y = HudMap:GetUnitPosition(unit, true)
				local r, g, b, a = self:Option("splashColor")
				register(HudMap:PlaceRangeMarker("timer", x, y, 6, 10, r, g, b, a):Rotate(360, 10):Appear():RegisterForAlerts())
			end
		end
	end,
	
	SPELL_CAST_START = function(self, spellID, sourceName, destName, sourceGUID, destGUID)	
		-- Big Ooze Explosion
		if spellID == 69839 and self:Option("splashEnabled") and self.lastSplash < GetTime() - 5 then
			self.lastSplash = GetTime()
			self.invoker = self.invoker or function() self:showSplashes() end
			encounters:Delay(self.invoker, 4)
		end
	end,
	
	SPELL_AURA_APPLIED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		-- Vile Gas
		if (spellID == 72272 or spellID == 72273) and self:Option("vileEnabled") then
			local r, g, b, a = self:Option("vileColor")
			register(HudMap:PlaceRangeMarkerOnPartyMember("timer", destName, 8, 6, r, g, b, a):Rotate(360, 6):Appear():RegisterForAlerts():SetLabel(destName))
			
		-- Mutated Infection
		elseif (spellID == 69674 or spellID == 73022 or spellID == 71224 or spellID == 73023) and self:Option("infectionEnabled") then
			local target = encounters:GetMobTarget(36899)
			if target then
				local r, g, b, a = self:Option("infectionColor")
				self.navArrow = HudMap:AddEdge(r, g, b, a, 10, "player", target):Identify(self, "navArrow")
			end
		end
	end,
	
	SPELL_AURA_REMOVED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if spellID == 69674 or spellID == 73022 or spellID == 71224 or spellID == 73023 then
			self.navArrow = free(self.navArrow, self, "navArrow")
		end
	end,
	
	-- If any small ooze dies, remove the nav arrow
	-- TODO: Try to build a queue of oozes to iterate through to know if the ooze that died was ours.
	UNIT_DIED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if encounters.GuidToMobID[destGUID] == 36897 then
			self.navArrow = free(self.navArrow, self, "navArrow")
		end
	end,
	
	-- If any small ooze casts merge, remove the nav arrow
	-- TODO: Try to build a queue of oozes to iterate through to know if the ooze that merged was ours.
	SPELL_CAST_SUCCESS = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if encounters.GuidToMobID[destGUID] == 36897 then
			self.navArrow = free(self.navArrow, self, "navArrow")
		end
	end
}

local putricide = {
	name = L["Professor Putricide"],
	startEncounterIDs = { 37562, 36678, 37697},
	endEncounterIDs = 36678,
	options = {
		goo = SN[72295],
		allGooSpots = L["All Malleable Goo Positions"],
		plague = SN[72855],
		oozeVariable = SN[74118],
		gasVariable = SN[74119],
	},
	defaults = {
		gooColor = {r = 0, g = 1, b = 0, a = 0.8},
		allGooSpotsColor = {r = 1, g = 1, b = 0, a = 0.25},
		
		plagueColor = {r = 1, g = 0.5, b = 0, a = 0.8},
		oozeVariableColor = {r = 0, g = 1, b = 0, a = 0.35},
		gasVariableColor = {r = 1, g = 0.5, b = 0, a = 0.35},
	},
	
	markers = {},
	gooTargetFunc = function(self)
		local gooTarget = encounters:GetMobTarget(36678)
		if gooTarget then
			local x, y = HudMap:GetUnitPosition(gooTarget, true)
			local r, g, b, a = self:Option("gooColor")
			register(HudMap:PlaceRangeMarker("highlight", x, y, 7, 7, r, g, b, a):RegisterForAlerts():Appear():Rotate(360, 3):SetLabel(SN[74280]))
		end
	end,
	SPELL_CAST_SUCCESS = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		-- Malleable Goo. Find Putricide's target and mark their splash zone. Can we mark bounce spots as well?
		if (spellID == 72295 or spellID == 74280 or spellID == 72615 or spellID == 74281) then
			if self:Option("gooEnabled") then
				self.invoker = self.invoker or function() self:gooTargetFunc() end
				encounters:Delay(self.invoker, 0.1)
			end
			if self:Option("allGooSpotsEnabled") and encounters:GetDungeonSize() == 25 then
				for index, unit in encounters.group() do
					if not UnitIsDead(unit) then
						local x, y = HudMap:GetUnitPosition(unit, true)
						local r, g, b, a = self:Option("allGooSpotsColor")
						register(HudMap:PlaceRangeMarker("rune1", x, y, 7, 7, r, g, b, a):RegisterForAlerts():Appear())
					end
				end
			end
		end
	end,
	SPELL_AURA_APPLIED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		-- Player picks up Unbound Plague
		if (spellID == 72855 or spellID == 72856) and self:Option("plagueEnabled") then
			local r, g, b, a = self:Option("plagueColor")
			free(self.ping, self, "ping")
			free(self.markers[destGUID], self, "plague" .. destGUID)
			self.markers[destGUID] = register(HudMap:PlaceRangeMarkerOnPartyMember("timer", destName, 3, 60, r, g, b, a):Appear():Rotate(360, 10):SetLabel(destName):Identify(self, "plague" .. destGUID))
			self.ping = register(HudMap:PlaceRangeMarkerOnPartyMember("targeting", destName, 3, 60, 1, 0.5, 0, 0.8):Appear():Rotate(360, 3):Identify(self, "ping"):Pulse(1.3, 0.5))
		elseif (spellID == 73117 or spellID == 70953) and self:Option("plagueEnabled") then
			free(self.markers[destGUID .. "sick"], self, "sick" .. destGUID)
			free(self.markers[destGUID .. "skull"], self, "skull" .. destGUID)
			self.markers[destGUID .. "sick"] = register(HudMap:PlaceRangeMarkerOnPartyMember("highlight", destName, 3, 60, 1, 0, 0, 0.6):Appear():Rotate(360, 10):Identify(self, "sick" .. destGUID))
			self.markers[destGUID .. "skull"] = register(HudMap:PlaceRangeMarkerOnPartyMember("skull", destName, "25px", 60, 1, 1, 1, 1):Appear():Identify(self, "skull" .. destGUID))
		elseif (spellID == 70352 or spellID == 74118) and self:Option("oozeVariableEnabled") then
			local r, g, b, a = self:Option("oozeVariableColor")
			free(self.markers[destGUID .. "variable"], self, "variable" .. destGUID)
			self.markers[destGUID .. "variable"] = register(HudMap:PlaceRangeMarkerOnPartyMember("fatring", destName, 3, 60, r, g, b, a):Appear():Identify(self, "variable" .. destGUID))
		elseif (spellID == 74119 or spellID == 70353) and self:Option("gasVariableEnabled") then			
			local r, g, b, a = self:Option("gasVariableColor")
			self.markers[destGUID .. "variable"] = register(HudMap:PlaceRangeMarkerOnPartyMember("fatring", destName, 3, 60, r, g, b, a):Appear():Identify(self, "variable" .. destGUID))
		end
	end,
	SPELL_AURA_REMOVED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		-- Player loses Unbound Plague
		if spellID == 72855 or spellID == 72856 then
			self.markers[destGUID] = free(self.markers[destGUID], self, "plague" .. destGUID)
			self.ping = free(self.ping, self, "ping")
		elseif (spellID == 73117 or spellID == 70953) then
			self.markers[destGUID .. "sick"] = free(self.markers[destGUID .. "sick"], self, "sick" .. destGUID)
			self.markers[destGUID .. "skull"] = free(self.markers[destGUID .. "skull"], self, "skull" .. destGUID)
		elseif spellID == 70352 or spellID == 74118 or spellID == 74119 or spellID == 70353 then
			self.markers[destGUID .. "variable"] = free(self.markers[destGUID .. "variable"], self, "variable" .. destGUID)
		end
	end
}

local princes = {
	name = L["Blood Council"],
	startEncounterIDs = { 37973, 37972, 37970 },
	endEncounterIDs = { 37973, 37972, 37970 },
	options = {	
		princeArrows = L["Prince Arrow"],
		fireArrows = L["Fire Arrow"],
		vortexes = SN[72037],
		empoweredShock = SN[72039],
	},
	defaults = {
		fireArrowsColor = {r = 1, g = 0.8, b = 0, a = 0.8},
		princeArrowsColor = {r = 1, g = 0, b = 0, a = 0.8},
		empoweredShockColor = {r = 1, g = 1, b = 1, a = 0.6},
		vortexesColor = {r = 1, g = 1, b = 1, a = 0.4},
	},
	shockTargetFunc = function(self)
		local shockTarget = encounters:GetMobTarget(37970)
		if shockTarget then
			local x, y = HudMap:GetUnitPosition(shockTarget, true)
			-- Timer is 45 sec on heroic?
			local r, g, b, a = self:Option("vortexesColor")
			register(HudMap:PlaceRangeMarker("timer", x, y, 15, 10, r, g, b, a):Appear():Rotate(360, 10):RegisterForAlerts())
			encounters:Delay(function()
				register(HudMap:PlaceRangeMarker("highlight", x, y, 15, 30, r, g, b, a):Rotate(360, 4):RegisterForAlerts())
			end, 10)
		end
	end,
	SPELL_CAST_START = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		-- AOE shock vortex
		-- Seems to have a ~10 sec arming time, then persists for X seconds
		if spellID == 72037 and self:Option("vortexesEnabled") then
			self.invoker = self.invoker or function() self:shockTargetFunc() end
			encounters:Delay(self.invoker, 0.1)
		-- Empowered shock vortex
		elseif (spellID == 72039 or spellID == 73037 or spellID == 73038 or spellID == 73039) and self:Option("empoweredShockEnabled") then
			local r, g, b, a = self:Option("empoweredShockColor")
			encounters:RangeCheckAll("timer", 12, 5, r, g, b, a, true)
		end
	end,
	SPELL_CAST_SUCCESS = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if (spellID == 72789 or spellID == 71393 or spellID == 72790 or spellID == 72791) then
			self.fireArrow = free(self.fireArrow, self, "fireArrow")
		end
	end,
	CHAT_MSG_RAID_BOSS_EMOTE = function(self, message, sender, language, channelString, target)
		if message and message:match(L["Empowered Flames speed toward (%S+)!"]) and target and self:Option("fireArrowsEnabled") then
			local r, g, b, a = self:Option("fireArrowsColor")
			local tank = encounters:GetMobTarget(37973)
			if tank then
				self.fireArrow = HudMap:AddEdge(r, g, b, a, 15, tank, target):Identify(self, "fireArrow")
			end
		end
	end
	-- TODO: On health swap, draw arrow to next prince 
	-- Alerts are not working (yet)
}

local bloodqueen = {
	name = L["Blood Queen Lana'thel"],
	startEncounterIDs = 37955,
	endEncounterIDs = 37955,
	options = {
		fear = SN[71900]
	},
	defaults = {
		fearColor = {r = 1, g = 0.4, b = 1, a = 0.6}
	},
	SPELL_CAST_SUCCESS = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		-- Fear
		if spellID == 73070 and self:Option("fearEnabled") then
			local r, g, b, a = self:Option("fearColor")
			encounters:RangeCheckAll("timer", 6, 13, r, g, b, a, true)
		end
	end
}

local sindragosa = {
	name = L["Sindragosa"],
	startEncounterIDs = 36853,
	endEncounterIDs = 36853,
	options = {
		tombs = SN[70157],
		cold = SN[70123],
		instability = SN[69766],
		sindraPositions = {
			type = "toggle",
			name = L["Automatic Ice Tomb Positions"]			
		}
	},
	defaults = {
		tombsColor = {r = 0.2, g = 0.9, b = 1, a = 0.7},
		coldColor = {r = 0.3, g = 0.5, b = 1, a = 0.7},
		instabilityColor = {r = 0.7, g = 0.3, b = 1, a = 0.7},
		sindraPositions = false
	},
	positions = {
		[25] = {
			skull = {269.53956118929,337.76000994167},
			cross = {282.47949627156, 339.4313988892},
			square = {294.08739616768, 338.45044344199},
			moon = {276.11522824042, 328.2487865677},
			triangle = {287.29786285233, 328.781499809},
			diamond = {299.06371249616, 327.73900886503}	
		},
		[10] = {
			skull = {275.96288167355, 330.19849182024},
			cross = {288.44287170219, 329.66235054601}		
		}
	},
	timers = {},
	markBlastRadius = function(self)
		local r, g, b, a = self:Option("coldColor")
		local x, y = encounters:GetCenterOfRaid(8)
		register(HudMap:PlaceRangeMarker("timer", x, y, 30, 5, r, g, b, a):Rotate(360, 5):Appear():RegisterForAlerts())
	end,
	lastTombTime = 0,
	tombsMarked = 0,
	DoTombs = function(self, destName)
		local r, g, b, a = self:Option("tombsColor")
		register(HudMap:PlaceRangeMarkerOnPartyMember("timer", destName, 10, 7, r, g, b, a):Appear():Rotate(360, 7):RegisterForAlerts():SetLabel(destName))
		if self:Option("sindraPositions") and GetTime() - self.lastTombTime < 5 and GetTime() - self.tombsMarked > 5 then
			for k, v in pairs(self.positions[encounters:GetDungeonSize()]) do
				if k ~= "diamond" or encounters:IsHeroic() then
					HudMap:PlaceRangeMarker(k, v[1], v[2], "30px", 10):Appear():Pulse(1.2, 0.5)
				end
			end
			self.tombsMarked = GetTime()
		end
		self.lastTombTime = GetTime()
	end,
	SPELL_AURA_APPLIED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		-- Frost beacon
		if spellID == 70126 and self:Option("tombsEnabled") then
			self:DoTombs(destName)
			
		-- Instability
		elseif spellID == 69766 and encounters:IsHeroic() and self:Option("instabilityEnabled") then
			local r, g, b, a = self:Option("instabilityColor")
			self.timers[destName] = register(HudMap:PlaceRangeMarkerOnPartyMember("highlight", destName, 20, nil, r, g, b, a):Appear():Rotate(360, 3):Identify(self, "instability" .. destName))
		end
	end,
	SPELL_AURA_REMOVED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		-- Instability
		if spellID == 69766 then
			self.timers[destName] = free(self.timers[destName], self, "instability" .. destName)
		end
	end,
	SPELL_CAST_SUCCESS = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		-- Icy Grip
		if spellID == 70117 and self:Option("coldEnabled") then
			self.markInvoker = self.markInvoker or function() self:markBlastRadius() end
			encounters:Delay(self.markInvoker, 1)
		end
	end
}

--[[
					elseif spellId == 73539 and self.o("shadowtrap") then
						local a = self.a("shadowtrap")
						AVRE:ScheduleTimer(function()						
							local target = AVRE:GetBossTarget(36597)
							if not target then return end
							AVR:AddCircleWarning(AVRE.scene, target, false, 5, 4, a.r, a.g, a.b, a.a)
						end, 0.05)

]]--
local lichking
do
	local UTFrame = CreateFrame("Frame")
	lichking = {
		name = L["The Lich King"],
		options = {
			necroticPlague = SN[70337],
			defile = SN[72754],
			shadowTrap = SN[73539]
		},
		defaults = {
			necroticPlagueColor = {r = 0.8, g = 0.6, b = 0, a = 0.4},
			defileColor = {r = 0.3, g = 0.3, b = 0.7, a = 0.8},
			shadowTrapColor = {r = 0.3, g = 0.3, b = 0.7, a = 0.8},
		},
		startEncounterIDs = 36597,
		endEncounterIDs = 36597,
		plagues = {},
		lastTrap = 0,
		trapInitialTarget = nil,
		defile = function(self)
			local defileTarget = encounters:GetMobTarget(36597)
			if defileTarget then
				local r, g, b, a = self:Option("defileColor")
				register(HudMap:PlaceRangeMarkerOnPartyMember("timer", defileTarget, 5, 2, r, g, b, a):Appear():Rotate(360, 2):RegisterForAlerts():SetLabel(defileTarget))
			end	
		end,
		shadowtrap = function(self)
			if GetTime() - self.lastTrap < 5 then return end
			local target = encounters:GetMobTarget(36597)
			if target and target ~= self.trapInitialTarget then
				self.lastTrap = GetTime()
				local r, g, b, a = self:Option("shadowTrapColor")
				register(HudMap:PlaceRangeMarkerOnPartyMember("timer", target, 5, 4, r, g, b, a):Appear():Rotate(360, 4):RegisterForAlerts():SetLabel(target))
			end	
		end,	
		SPELL_CAST_START = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
			if spellID == 72762 then
				self.invoker = self.invoker or function() self:defile() end
				encounters:Delay(self.invoker, 0.1)
			elseif spellID == 73539 and self:Option("shadowTrapEnabled") then
				self.stinvoker = self.stinvoker or function() self:shadowtrap() end
				self.stinvoker2 = self.stinvoker2 or function() self.trapInitialTarget = nil; self:shadowtrap() end
				self.trapInitialTarget = encounters:GetMobTarget(36597)
				if encounters.GuidToMobID[UnitGUID("target")] == 36597 then
					UTFrame:RegisterEvent("UNIT_TARGET")
				else
					-- Spam-check!
					encounters:Delay(self.stinvoker, 0.01)
					encounters:Delay(self.stinvoker, 0.02)
					encounters:Delay(self.stinvoker, 0.03)
					encounters:Delay(self.stinvoker, 0.04)
					encounters:Delay(self.stinvoker, 0.05)
				end
				encounters:Delay(self.stinvoker2, 1)
			end
		end,
		SPELL_CAST_SUCCESS = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
			if spellID == 70337 or spellID == 73912 or spellID == 73913 or spellID == 73914 or spellID == 70338 or spellID == 73785 or spellID == 73786 or spellID == 73787 then
				local r, g, b, a = self:Option("necroticPlagueColor")
				self.plagues[destName] = register(HudMap:PlaceRangeMarkerOnPartyMember("timer", destName, 3, 5, r, g, b, a):Appear():Rotate(360, 5):RegisterForAlerts():SetLabel(destName):Identify(self, "plagues" ..destName))
			end
		end,
		SPELL_DISPEL = function(self, spellID, sourceName, destName, sourceGUID, destGUID, spellName, spellSchool, dispelSpellId)
			if dispelSpellId == 70337 or dispelSpellId == 73912 or dispelSpellId == 73913 or dispelSpellId == 73914 or dispelSpellId == 70338 or dispelSpellId == 73785 or dispelSpellId == 73786 or dispelSpellId == 73787 then
				self.plagues[destName] = free(self.plagues[destName], self, "plagues" ..destName)
			end
		end
	}
	UTFrame:SetScript("OnEvent", function(self, unit)
		if UnitGUID(unit) and encounters.GuidToMobID[UnitGUID(unit)] == 36597 then
			lichking:shadowtrap()
			self:UnregisterEvent("UNIT_TARGET")
		end
	end)
end

encounters:RegisterModule(L["Icecrown Citadel"], marrowgar, deathwhisper, festergut, rotface, putricide, princes, bloodqueen, sindragosa, lichking)