local modName = "Encounters"
local parent = HudMap
local L = LibStub("AceLocale-3.0"):GetLocale("HudMap")
local mod = HudMap:NewModule(modName, "AceEvent-3.0")
local db

--[[ Default upvals 
     This has a slight performance benefit, but upvalling these also makes it easier to spot leaked globals. ]]--
local _G = _G.getfenv(0)
local wipe, type, pairs, tinsert, tremove, tonumber = _G.wipe, _G.type, _G.pairs, _G.tinsert, _G.tremove, _G.tonumber
local math, math_abs, math_pow, math_sqrt, math_sin, math_cos, math_atan2 = _G.math, _G.math.abs, _G.math.pow, _G.math.sqrt, _G.math.sin, _G.math.cos, _G.math.atan2
local error, rawset, rawget, print = _G.error, _G.rawset, _G.rawget, _G.print
local tonumber, tostring = _G.tonumber, _G.tostring
local getmetatable, setmetatable, pairs, ipairs, select, unpack = _G.getmetatable, _G.setmetatable, _G.pairs, _G.ipairs, _G.select, _G.unpack
--[[ -------------- ]]--

local CallbackHandler = LibStub:GetLibrary("CallbackHandler-1.0")
local callbacks, activeCallbacks = {}, {}

local options = {
	type = "group",
	name = L["Encounters"],
	args = {
		zones = {
			type = "group",
			name = L["Zones"],
			args = {},
			get = function(info)
				local obj = db.zones
				for i = 3, #info do
					obj = obj[info[i]]
				end			
				if type(obj) == "table" then
					return obj.r, obj.g, obj.b, obj.a
				else
					return obj
				end
			end,
			
			set = function(info, ...)
				local obj = db.zones
				for i = 3, #info - 1 do
					obj = obj[info[i]]
				end
				if select("#", ...) == 1 then
					obj[info[#info]] = ...
				else
					local t = obj[info[#info]]
					t.r, t.g, t.b, t.a = ...
				end
			end			
		}
	}
}

local defaults = {
	profile = {
		zones = {}		
	}
}

local moduleCallbacks = {}
local encounterStartLookup, encounterEndLookup = {}, {}
local activeModule, activatedAt = nil, nil
mod.group = HudMap.group

mod.GuidToMobID = setmetatable({}, {__index = function(t, k)
	k = k or 0
	local id = (k and tonumber(k:sub(7, 10), 16)) or 0
	rawset(t, k, id)
	return id	
end})

function mod:OnInitialize()
	self.db = parent.db:RegisterNamespace(modName, defaults)
	db = self.db.profile
	parent:RegisterModuleOptions(modName, options, modName)
end

function mod:OnEnable()
	self.db:RegisterDefaults(defaults)
	db = self.db.profile
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")	
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE", "Yell")
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL", "Yell")
	self:RegisterEvent("CHAT_MSG_MONSTER_EMOTE", "Yell")
	self:RegisterEvent("CHAT_MSG_MONSTER_SAY", "Yell")	
	self:RegisterEvent("ZONE_CHANGED", "FreeEncounterMarkers")
end

function mod:OnDisable()
	self:FreeEncounterMarkers()
end

function mod:COMBAT_LOG_EVENT_UNFILTERED(_, timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, ...)
	local srcMob = mod.GuidToMobID[sourceGUID]
	local dstMob = mod.GuidToMobID[destGUID]
	
	if event == "UNIT_DIED" then
		local b = encounterEndLookup[dstMob]
		if b and b.Win then b.Win(b) end
		if b then
			self:FreeEncounterMarkers()
			activeModule = nil
			return
		end
	else
		if encounterStartLookup[dstMob] or encounterStartLookup[srcMob] then
			newModule = encounterStartLookup[dstMob] or encounterStartLookup[srcMob]
			if newModule and newModule ~= activeModule then
				activeModule = newModule
				if activeModule.Start then
					activeModule:Start()
				end
			end
			activatedAt = GetTime()
		end
		if activatedAt and activatedAt < GetTime() - 180 then
			activeModule = nil
		end
	end	
	if not activeModule then return end
	
	local ev = activeModule[event]
	if ev then
		activeModule[event](activeModule, spellID, sourceName, destName, sourceGUID, destGUID, ...)
	end
end

function mod:Yell(event, ...)
	if not activeModule then return end
	local ev = activeModule[event]
	if ev then
		activeModule[event](activeModule, ...)
	end
end

do
	local function option(self, setting)
		local t = db.zones[self.zone:gsub(" ", "")][self.name:gsub(" ", "")][setting]	
		if type(t) == "table" then
			return t.r, t.g, t.b, t.a
		else
			return t
		end
	end

	local nukeKeys, merge = {}, {}
	function mod:RegisterModule(zone, ...)	
		for i = 1, select("#", ...) do
			local module = select(i, ...)
			if module.name and module.options then
				options.args.zones.args[zone:gsub(" ", "")] = options.args.zones.args[zone:gsub(" ", "")] or {
					type = "group",
					name = zone,
					args = {}
				}
				module.Option = option
				module.zone = zone:gsub(" ", "")
				local t = options.args.zones.args[zone:gsub(" ", "")]
				
				wipe(nukeKeys)
				wipe(merge)
				local serial = 150
				for k, v in pairs(module.options) do
					if type(v) == "string" then
						tinsert(nukeKeys, k)
						merge[k .. "Enabled"] = {
							type = "toggle",
							name = L["Enable"] .. " " .. v,
							order = serial + 1
						}
						merge[k .. "Color"] = {
							type = "color",
							name = v .. " " .. L["Color"],
							hasAlpha = true,
							order = serial + 2							
						}
						serial = serial + 2
						if module.defaults[k .. "Enabled"] == nil then module.defaults[k .. "Enabled"] = true end
					end
				end
				for k, v in pairs(merge) do
					module.options[k] = v
				end
				for k, v in ipairs(nukeKeys) do
					module.options[v] = nil
				end
				
				if module.defaults then
					local gzone = zone:gsub(" ", "")
					defaults.profile.zones[gzone] = defaults.profile.zones[gzone] or {}
					defaults.profile.zones[gzone][module.name:gsub(" ", "")] = module.defaults
				end

				t.args[module.name:gsub(" ", "")] = {
					type = "group",
					name = module.name,
					args = module.options
				}
			end
			
			if module.startEncounterIDs then
				if type(module.startEncounterIDs) == "table" then
					for _, v in ipairs(module.startEncounterIDs) do
						encounterStartLookup[v] = module
					end
				elseif type(module.startEncounterIDs) == "number" then
					encounterStartLookup[module.startEncounterIDs] = module
				end
			end
			
			if module.endEncounterIDs then
				if type(module.endEncounterIDs) == "table" then
					for _, v in ipairs(module.endEncounterIDs) do
						encounterEndLookup[v] = module
					end
				elseif type(module.endEncounterIDs) == "number" then
					encounterEndLookup[module.endEncounterIDs] = module
				end
			end
		end
	end
end

local approximateUnits = {}
function mod:ApproximateBossPosition()
	wipe(approximateUnits)
	local prefix, max
	if GetNumRaidMembers() > 0 then
		prefix = "party"
		max = "4"
	elseif GetNumPartyMembers() > 0 then		
		prefix = "raid"
		max = 25
	end
	for i = 1, max do
		local _, cls = UnitClass(prefix..i)
		if not cls then break end
		
		if cls == "HUNTER" and UnitExists(prefix..i.."pet") then
			tinsert(approximateUnits, prefix..i)
		elseif cls == "ROGUE" or cls == "WARRIOR" or cls == "DEATHKNIGHT" then
			tinsert(approximateUnits, prefix..i)
		end
	end
	local sumX, sumY, sumN = 0, 0, 0
	for _, v in ipairs(approximateUnits) do
		local x, y = HudMap:GetUnitPosition(v)
		if x and y and x ~= 0 and y ~= 0 then
			sumX = sumX + x
			sumY = sumY + y
			sumN = sumN + 1
		end
	end
	return sumX / sumN, sumY / sumN
end

function mod:IsHeroic()
	local diff, switchable = select(6, GetInstanceInfo())
	if switchable then
		return diff == 1
	else
		return GetInstanceDifficulty() >= 3
	end
end

function mod:GetDungeonSize()
	local size = select(5, GetInstanceInfo())
	return size
end

do
	function mod:RangeCheckAll(tex, radius, duration, nr, ng, nb, na, excludePlayer)
		for index, unit in mod.group() do
			local n = UnitName(unit)
			if n and not UnitIsDead(unit) and not UnitIsUnit("player", unit) then
				local c = HudMap:PlaceRangeMarkerOnPartyMember(tex, n, radius, duration, nr, ng, nb, na):Appear():Rotate(360, duration):RegisterForAlerts(nil, n)
			end
		end	
	end
end

function mod:HomeToTarget(unit, radius, r, g, b, a)
	radius = radius or 2
	r = r or 1
	g = g or 1
	b = b or 1
	a = a or 1	
end

function mod:GetMobTarget(mobID)
	for index, unit in mod.group() do
		local g = UnitGUID(unit.."target")
		if g then
			if mod.GuidToMobID[g] == mobID then
				return UnitName(unit.."targettarget")
			end
		end
	end	
end

local encounterMarkers = {}
function mod:RegisterEncounterMarker(e)
	encounterMarkers[e] = true
	e.RegisterCallback(self, "Free", "FreeEncounterMarker")
end

function mod:FreeEncounterMarker(cbk, e)
	encounterMarkers[e] = nil
end

function mod:FreeEncounterMarkers()
	for k, _ in pairs(encounterMarkers) do
		encounterMarkers[k] = k:Free()
	end
end

do
	local gpu = HudMap.GetUnitPosition
	function mod:GetCenterOfRaid(tolerance)
		SetMapToCurrentZone()
		local sx, sy, sc = 0, 0, 0
		for index, unit in mod.group() do
			local x, y = gpu(HudMap, unit)
			sx = sx + x
			sy = sy + y
			sc = sc + 1
		end
		local ax, ay = sx / sc, sy / sc
		sx, sy, sc = 0, 0, 0
		for index, unit in mod.group() do
			local x, y = gpu(HudMap, unit)
			local dx = ax - x
			local dy = ay - y
			if math_abs(math_pow((dx*dx)+(dy*dy), 0.5)) < tolerance then
				sx = sx + x
				sy = sy + y
				sc = sc + 1
			end
		end
		return sx / sc, sy / sc
	end
end

do
	local delays = {}
	function mod:Delay(func, delay, ...)
		if select("#", ...) > 0 then
			local a,b,c,d,e,f,g,h = ...
			local func2 = function() func(a,b,c,d,e,f,g,h) end
			delays[func2] = GetTime() + delay
		else
			delays[func] = GetTime() + delay
		end
	end

	local timerFrame = CreateFrame("Frame", nil, UIParent)
	timerFrame:SetWidth(1)
	timerFrame:SetHeight(1)
	timerFrame:SetScript("OnUpdate", function(self, t)
		local ct = GetTime()
		for k, v in pairs(delays) do
			if ct > v then
				k()
				delays[k] = nil
			end
		end
	end)
end
