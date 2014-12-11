-- Name your module whatever you want.
local modName = "Range Markers"

local parent = HudMap
local L = LibStub("AceLocale-3.0"):GetLocale("HudMap")
local mod = HudMap:NewModule(modName, "AceEvent-3.0")
local db

local function deepcopy(tbl)
   local new = {}
   for key,value in pairs(tbl) do
      new[key] = type(value) == "table" and deepcopy(value) or value -- if it's a table, run deepCopy on it too, so we get a copy and not the original
   end
   return new
end

-- This is an Ace3 options table.
-- http://www.wowace.com/addons/ace3/pages/ace-config-3-0-options-tables/
-- db is a handle to your module's current profile settings, so you can use it directly.
local options = {
	type = "group",
	name = L["Range Markers"],
	args = {
		addMarker = {
			type = "execute",
			name = L["Add Marker"],
			func = function() mod:AddMarker() end
		},
		ranges = {
			type = "group",
			name = L["Range Markers"],
			get = function(info)
				if not db.markers[info[#info-1]] then return end
				local t = db.markers[info[#info-1]][info[#info]]
				if type(t) == "table" then
					return unpack(t)
				else
					return t
				end
			end,
			set = function(info, ...)
				if select("#", ...) > 1 then
					db.markers[info[#info-1]][info[#info]] = db.markers[info[#info-1]][info[#info]] or {}
					for i = 1, select("#", ...) do
						db.markers[info[#info-1]][info[#info]][i] = select(i, ...)
					end
				else
					db.markers[info[#info-1]][info[#info]] = ...
				end
				mod:UpdateMarker(info[#info-1])
			end,
			args = {}
		}
	}
}

-- Define your module's defaults here. Your options will toggle them.
local defaults = {
	profile = {
		serial = 0,
		enable = true,
		markers = {}
	}
}
local activeMarkers = {}

-- One-time setup code is done here.
function mod:OnInitialize()
	self.db = parent.db:RegisterNamespace(modName, defaults)
	db = self.db.profile
	parent:RegisterModuleOptions(modName, options, modName)
	for k, v in pairs(db.markers) do
		self:AddMarker(k)
	end
end

-- And we're ready to rock! Register events or do other startup code here.
function mod:OnEnable()
	db = self.db.profile
	local x, y = HudMap:GetUnitPosition("player")
	for k, v in pairs(db.markers) do
		self:UpdateMarker(k)
	end
end

function mod:OnDisable()
	for k, v in pairs(activeMarkers) do
		v:Free()
	end
	wipe(activeMarkers)
end

local ringDefaults = {
	name = L["New Marker"],
	color = {1, 1, 0, 1},
	texture = "ring",
	rotateSpeed = 0,
	size = 40,
	enable = true
}

local rangeKeys = {
	rune1 = L["Rune 1"],
	rune2 = L["Rune 2"],
	rune3 = L["Rune 3"],
	rune4 = L["Rune 4"],
	highlight = L["Highlight"],
	radius = L["Dots"],
	radius = L["Large Dots"],
	timer = L["Clock"],
	ring = L["Circle"],
	reticle = L["Reticle"],
	fuzzyring = L["Ring 2"],
	fatring = L["Ring 3"],
	fadecircle = L["Faded Circle"],
}

function mod:AddMarker(key)
	if not key then
		key = db.serial
		db.serial = db.serial + 1
		key = "range" .. tostring(key)
	end
	
	db.markers[key] = db.markers[key] or deepcopy(ringDefaults)
	local disable = function() return not db.markers[key].enable end
	local marker = {
		type = "group",
		name = db.markers[key].name or L["New Marker"],
		args = {
			enable = {
				type = "toggle",
				name = L["Enable"],
				order = 1,
				disabled = false
			},
			range = {
				name = L["Range (yards)"],
				type = "range",
				min = 1,
				max = 100,
				step = 1,
				bigStep = 1,
				disabled = disable
			},
			color = {
				name = L["Color"],
				type = "color",
				hasAlpha = true,
				disabled = disable
			},
			texture = {
				name = L["Texture"],
				type = "select",
				values = rangeKeys,
				disabled = disable
			},
			rotateSpeed = {
				name = L["Rotate Speed"],
				type = "range",
				min = -100,
				max = 100,
				step = 1,
				bigStep = 1,
				disabled = disable
			},
			delete = {
				name = L["Delete Marker"],
				type = "execute",
				confirm = true,
				confirmText = L["Delete this marker?"],
				func = function()
					options.args.ranges.args[key] = nil
					db.markers[key] = nil
					if activeMarkers[key] then
						activeMarkers[key] = activeMarkers[key]:Free()
					end
				end,
				disabled = disable
			}
		}
	}
	marker.args.name = {
		name = L["Name"],
		type = "input",
		get = function() return db.markers[key].name end,
		set = function(info, v)
			marker.name = v			
			db.markers[key].name = v
		end,
		order = 1
	}

	options.args.ranges.args[key] = options.args.ranges.args[key] or marker
	self:UpdateMarker(key)
end

function mod:UpdateMarker(key)
	local marker = activeMarkers[key]
	local settings = db.markers[key]
	if not settings.enable and marker then
		activeMarkers[key] = marker:Free()
		return
	end
	if not marker then
		marker = parent:PlaceRangeMarkerOnPartyMember("ring", "player", 30, nil, 1, 1, 0, 1):Persist()
		activeMarkers[key] = marker
		marker.RegisterCallback(self, "Free", "FreeMarker")
	end
	marker:SetSize(settings.range)
	marker:SetColor(unpack(settings.color))
	marker:SetTexture(settings.texture)
	marker:Rotate(settings.rotateSpeed * 1.8, 1)
end

function mod:FreeMarker(cbk, m)
	for k, v in pairs(activeMarkers) do
		if v == m then
			activeMarkers[k] = nil
			return
		end
	end
end