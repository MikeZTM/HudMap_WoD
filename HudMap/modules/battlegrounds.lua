local modName = "Battlegrounds"
local parent = HudMap
local L = LibStub("AceLocale-3.0"):GetLocale("HudMap")
local mod = HudMap:NewModule(modName, "AceEvent-3.0")
local db

local free = parent.free

--[[ Default upvals
     This has a slight performance benefit, but upvalling these also makes it easier to spot leaked globals. ]]--
local _G = _G.getfenv(0)
local wipe, type, pairs, tinsert, tremove, tonumber = _G.wipe, _G.type, _G.pairs, _G.tinsert, _G.tremove, _G.tonumber
local math, math_abs, math_pow, math_sqrt, math_sin, math_cos, math_atan2 = _G.math, _G.math.abs, _G.math.pow, _G.math.sqrt, _G.math.sin, _G.math.cos, _G.math.atan2
local error, rawset, rawget, print = _G.error, _G.rawset, _G.rawget, _G.print
local tonumber, tostring = _G.tonumber, _G.tostring
local getmetatable, setmetatable, pairs, ipairs, select, unpack = _G.getmetatable, _G.setmetatable, _G.pairs, _G.ipairs, _G.select, _G.unpack
--[[ -------------- ]]--

local battlegroundTemplate = {
	Option = function(self, tkey)
		return db.battlegrounds[self.key].points[tkey]
	end,
	Register = function(self, key, ...)
		if self:Option(key) then
			for i = 1, select("#", ...) do
				local v = select(i, ...)
				self.pointKeys[v] = key
			end
		end
	end
}

local battlegrounds = {}
local function battleground(key, name, t)
	t.key = key
	t.name = name
	battlegrounds[key] = setmetatable(t, {__index = battlegroundTemplate})
	battlegrounds[key].pointKeys = {}
	return battlegrounds[key]
end

local activeModule
local playerFaction
local flagMarker
local tex = [[Interface\Minimap\POIIcons.blp]]
local POIs = {}
local playerFaction = select(2, UnitFactionGroup("player"))

battleground("AlteracValley", L["Alterac Valley"], {
	options = {
		mines = L["Mines"],
		graveyards = L["Graveyards"],
		liveTowers = L["Live Towers"],
		deadTowers = L["Destroyed Towers"]
	},
	GetPoiIndexes = function(self)
		wipe(self.pointKeys)
		self:Register("mines", 1, 2, 3)
		self:Register("graveyards", 4, 13, 14, 15)
		self:Register("liveTowers", 10, 11, 50, 52)
		self:Register("deadTowers", 51, 53, 55)
	end
})

battleground("WarsongGulch", L["Warsong Gulch"], {
	options = {
		flag = L["Flag Carrier"],
	},
	BattlegroundMessage = function(faction, msg)
		local faction, tex
		if faction == "horde" then
			tex = [[Interface\WorldStateFrame\AllianceFlag.blp]]
		else
			tex = [[Interface\WorldStateFrame\HordeFlag.blp]]
		end
		local pickupName = msg:match(L["was picked up by (.+)!"])
		local dropped = msg:match(L["was dropped"])
		local capped = msg:match(L["captured the"])
		if pickupName and faction == playerFaction then
			flagMarker = parent:PlaceRangeMarkerOnPartyMember(tex, pickupName, "25px", nil, 1, 1, 1, 1):Identify(self, "flag"):AlwaysShow():SetLabel(pickupName, "BOTTOM", "TOP", nil, nil, nil, nil, 0, 5)
			flagMarker.texture:SetTexCoord(0.139, 0.870, 0.134, 0.848)
			flagMarker.texture:SetDrawLayer("OVERLAY")
			flagMarker.RegisterCallback(self, "Free", "FreeFlag")
		elseif (dropped and faction ~= playerFaction) or (capped and faction == playerFaction) then
			free(flagMarker, self, "flag")
		end
	end
})

battleground("ArathiBasin", L["Arathi Basin"], {
	options = {
		mine = L["Gold Mine"],
		mill = L["Lumber Mill"],
		smith = L["Blacksmith"],
		farm = L["Farm"],
		stables = L["Stables"]
	},
	GetPoiIndexes = function(self)
		wipe(self.pointKeys)
		self:Register("mine", 16, 17, 18, 19, 20)
		self:Register("mill", 21, 22, 23, 24, 25)
		self:Register("smith", 26, 27, 28, 29, 30)
		self:Register("farm", 31, 32, 33, 34, 35)
		self:Register("stables", 36, 37, 38, 39, 40)
	end
})

battleground("IsleofConquest", L["Isle of Conquest"], {
	options = {
		workshop = L["Workshop"],
		hangar = L["Hangar"],
		docks = L["Docks"],
		refinery = L["Refinery"],
		quarry = L["Quarry"]
	},
	GetPoiIndexes = function(self)
		wipe(self.pointKeys)
		self:Register("workshop", 135, 136, 137, 138, 139)
		self:Register("hangar", 140, 141, 142, 143, 144)
		self:Register("docks", 145, 146, 147, 148, 149)
		self:Register("refinery", 150, 151, 152, 153, 154)
		self:Register("quarry", 16, 17, 18, 19, 20)
	end
})

battleground("NetherstormArena", L["Eye of the Storm"], {
	options = {
		flag = L["Flag Carrier"],
		towers = L["Towers"]
	},
	GetPoiIndexes = function(self)
		wipe(self.pointKeys)
		self:Register("towers", 6, 9, 10, 11, 12)			-- Towers
	end,
	BattlegroundMessage = function(faction, msg)
		local faction, tex
		if faction == "horde" then
			tex = [[Interface\WorldStateFrame\HordeFlag.blp]]
		else
			tex = [[Interface\WorldStateFrame\AllianceFlag.blp]]
		end
		local pickupName = msg:match(L["(.+) has taken the flag"])
		local dropped = msg:match(L["has been dropped"])
		local capped = msg:match(L["captured the"])
		if pickupName and faction == playerFaction then
			flagMarker = parent:PlaceRangeMarkerOnPartyMember(tex, pickupName, "25px", nil, 1, 1, 1, 1):Identify(self, "flag"):AlwaysShow():SetLabel(pickupName, "BOTTOM", "TOP", nil, nil, nil, nil, 0, 5)
			flagMarker.texture:SetTexCoord(0.139, 0.870, 0.134, 0.848)
			flagMarker.texture:SetDrawLayer("OVERLAY")
			flagMarker.RegisterCallback(self, "Free", "FreeFlag")
		elseif dropped or capped then
			free(flagMarker, self, "flag")
		end
	end
})

battleground("StrandoftheAncients", L["Strand of the Ancients"], {
	options = {
		graveyards = L["Graveyards"],
		liveGates = L["Live Gates"],
		brokenGates = L["Assaulted Gates"],
		deadGates = L["Dead Gates"],
	},
	GetPoiIndexes = function(self)
		wipe(self.pointKeys)
		self:Register("graveyards", 4, 13, 14, 15)
		self:Register("liveGates", 74, 77, 80, 102, 105, 108)		-- Live Gates
		self:Register("brokenGates", 75, 78, 81, 103, 106, 109)		-- Assaulted Gates
		self:Register("deadGates", 76, 79, 82, 104, 107, 110)		-- Dead Gates
	end
})

local POILookup = setmetatable({}, {__index = function(t, k)
	local c
	if battlegrounds[k].GetPoiIndexes then
		battlegrounds[k]:GetPoiIndexes()
		c = battlegrounds[k].pointKeys
	end
	rawset(t, k, c)
	return c
end})

local options = {
	type = "group",
	name = L["Battlegrounds"],
	get = function(info)
		local p = db; for i = 2, #info - 1 do p = p[info[i]] end
		return p[info[#info]]
	end,
	set = function(info, v)
		local p = db; for i = 2, #info - 1 do p = p[info[i]] end
		p[info[#info]] = v
		wipe(POILookup)
		mod:UpdateWorldState()
	end,
	args = {
		battlegrounds = {
			type = "group",
			name = L["Battlegrounds"],
			args = {
				fontSize = {
					type = "range",
					name = L["Font size"],
					desc = L["Font size"],
					min = 4,
					max = 30,
					step = 1,
					bigStep = 1,
					get = function()
						return db.battlegrounds.fontSize or parent.db.profile.labels.size
					end,
					set = function(info, v)
						db.battlegrounds.fontSize = v
						for k, v in pairs(db.battlegrounds) do
							if type(v) == "table" then
								v.fontSize = nil
							end
						end
						mod:UpdateWorldState()
					end,
					order = 5
				},
				outline = {
					type = "select",
					name = L["Font Outline"],
					desc = L["Font outlining"],
					values = parent.outlines,
					get = function()
						return db.battlegrounds.outline or parent.db.profile.labels.outline
					end,
					set = function(info, v)
						db.battlegrounds.outline = v
						for k, v in pairs(db.battlegrounds) do
							if type(v) == "table" then
								v.outline = nil
							end
						end
						mod:UpdateWorldState()
					end,
					order = 6
				}
			}
		}
	}
}

local defaults = {
	profile = {
		showFlags = true,
		battlegrounds = {}
	}
}

for k, v in pairs(battlegrounds) do
	local opt = {
		name = v.name,
		type = "group",
		args = {
			showLabels = {
				type = "toggle",
				name = L["Show POI Labels"],
				order = 4
			},
			fontSize = {
				type = "range",
				name = L["Font size"],
				desc = L["Font size"],
				min = 4,
				max = 30,
				step = 1,
				bigStep = 1,
				get = function() return db.battlegrounds[k].fontSize or db.battlegrounds.fontSize or parent.db.profile.labels.size end,
				order = 5
			},
			outline = {
				type = "select",
				name = L["Font Outline"],
				desc = L["Font outlining"],
				values = parent.outlines,
				get = function() return db.battlegrounds[k].outline or db.battlegrounds.outline or parent.db.profile.labels.outline end,
				order = 6
			},
			points = {
				type = "group",
				name = L["Points of Interest"],
				inline = true,
				args = {}
			}
		}
	}

	defaults.profile.battlegrounds[k] = defaults.profile.battlegrounds[k] or {
		points = {},
		showLabels = true
	}

	for key, name in pairs(v.options) do
		opt.args.points.args[key] = {
			type = "toggle",
			name = name
		}
		defaults.profile.battlegrounds[k].points[key] = true
	end
	options.args.battlegrounds.args[k] = opt
end

local SN = parent.SN

function mod:OnInitialize()
	self.db = parent.db:RegisterNamespace(modName, defaults)
	db = self.db.profile
	parent:RegisterModuleOptions(modName, options, modName)
end

function mod:OnEnable()
	db = self.db.profile
	if not HudMap.db.profile.modules[self:GetName()] then self:Disable(); end
	
	self:RegisterEvent("ZONE_CHANGED", "UpdateActiveModule")
	
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateActiveModule")
	self:RegisterEvents()
	self:UpdateActiveModule()
end

function mod:OnDisable()
	self:FreeMarkers()
end

function mod:FreeMarkers()
	flagMarker = free(flagMarker, self, "flag")
	for k, v in pairs(POIs) do
		free(v, self, k)
	end
	wipe(POIs)
end

function mod:RegisterEvents()
	self:RegisterEvent("CHAT_MSG_BG_SYSTEM_HORDE", "BattlegroundMessage")
	self:RegisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE", "BattlegroundMessage")
	self:RegisterEvent("WORLD_MAP_UPDATE", "UpdateWorldState")
end

function mod:UnregisterEvents()
	self:UnregisterEvent("CHAT_MSG_BG_SYSTEM_HORDE")
	self:UnregisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE")
	self:UnregisterEvent("WORLD_MAP_UPDATE", "UpdateWorldState")
end

function mod:UpdateActiveModule()
	SetMapToCurrentZone()
	local area = GetMapInfo()
	local newModule = battlegrounds[area]
	if newModule ~= activeModule then
		if activeModule then
		end
		self:FreeMarkers()
		activeModule = newModule
		if activeModule then
			self:RegisterEvents()
			self:UpdateWorldState()
		else
			self:UnregisterEvents()
		end
	end
end

function mod:BattlegroundMessage(event, msg)
	if not activeModule then return end
	if not activeModule:Option("flag") then return end
	if activeModule.BattlegroundMessage then
		activeModule:BattlegroundMessage(event == "CHAT_MSG_BG_SYSTEM_HORDE" and "horde" or "alliance", msg)
	end
end

local usedPOIs = {}
function mod:UpdateWorldState()
	if not activeModule then return end
	wipe(usedPOIs)
	for i = 1, GetNumMapLandmarks(), 1 do
		local name, desc, texIndex, x, y = GetMapLandmarkInfo(i)
		local landmark = POILookup[activeModule.key] and POILookup[activeModule.key][texIndex]
		if landmark then
			local settings = db.battlegrounds[activeModule.key]
			if settings.points[landmark] and x ~= 0 and y ~= 0 and texIndex ~= 0 then
				local mx, my = parent:CoordsToPosition(x, y)
				local key = landmark .. texIndex .. i
				free(POIs[key], self, key)
				local m = parent:PlaceRangeMarker(tex, mx, my, "15px", nil, 1, 1, 1, 1):Identify(self, key):AlwaysShow()
				if settings.showLabels then
					m:SetLabel(name, "BOTTOM", "TOP", nil, nil, nil, nil, 0, 5, settings.fontSize or db.battlegrounds.fontSize, settings.outline or db.battlegrounds.outline)
				end
				m.texture:SetTexCoord(WorldMap_GetPOITextureCoords(texIndex))
				POIs[key] = m
				usedPOIs[key] = true
				m.RegisterCallback(self, "Free", "FreePOI")
			end
		end
	end
	for k, v in pairs(POIs) do
		if not usedPOIs[k] then
			POIs[k] = free(v, self, k)
		end
	end
end

function mod:FreePOI(cbk, poi)
	for k, v in pairs(POIs) do
		if v == poi then
			POIs[k] = nil
			return
		end
	end
end

function mod:FreeFlag(cbk, flag)
	flagMarker = nil
end