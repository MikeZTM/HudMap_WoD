-- Ping module, by Adirelle (adirelle@tagada-team.net)

local modName = "Ping"

local parent = HudMap
local L = LibStub("AceLocale-3.0"):GetLocale("HudMap")
local mod = HudMap:NewModule(modName, "AceEvent-3.0")

local function free(e)
	if e then e:Free() end
	return nil
end

local minimapSize = {
	indoors = {
		[0] = 290,
		[1] = 230,
		[2] = 175,
		[3] = 119,
		[4] = 79,
		[5] = 49.8,
	},
	outdoors = {
		[0] = 450,
		[1] = 395,
		[2] = 326,
		[3] = 265,
		[4] = 198,
		[5] = 132
	},
}

local options = {
	type = "group",
	name = L["Ping"],
	args = {
		arrow = {
			type = "toggle",
			name = L["Display arrow"],
			order = 5,
			get = function()
				return mod.db.profile.arrow
			end,
			set = function(info, v)
				mod.db.profile.arrow = v
			end
		},
		label = {
			type = "toggle",
			name = L["Display pinger name"],
			order = 5,
			get = function()
				return mod.db.profile.label
			end,
			set = function(info, v)
				mod.db.profile.label = v
			end
		},
	}
}

-- Define your module's defaults here. Your options will toggle them.
local defaults = {
	profile = {
		arrow = true,
		label = true,
	}
}

-- One-time setup code is done here.
function mod:OnInitialize()
	self.db = parent.db:RegisterNamespace(modName, defaults)
	parent:RegisterModuleOptions(modName, options, modName)	
end

function mod:OnEnable()
	self:RegisterEvent('MINIMAP_PING')
	self:RegisterEvent('MINIMAP_UPDATE_ZOOM')
	self:MINIMAP_UPDATE_ZOOM()
end

function mod:OnDisable()
	if self.ping then
		self.ping:Free()
	end
end

function mod:MINIMAP_UPDATE_ZOOM()
	local zoom = Minimap:GetZoom()
	if GetCVar("minimapZoom") == GetCVar("minimapInsideZoom") then
		Minimap:SetZoom(zoom < 2 and zoom + 1 or zoom - 1)
	end
	self.minimapZoom = GetCVar("minimapZoom")+0 ~= Minimap:GetZoom() and "indoors" or "outdoors"
	Minimap:SetZoom(zoom)
end

function mod:GetMinimapSize()
	local zoom = Minimap:GetZoom()
	if GetCVar("minimapZoom") == GetCVar("minimapInsideZoom") then
		Minimap:SetZoom(zoom < 2 and zoom + 1 or zoom - 1)
	end
	local size = minimapSize[GetCVar("minimapZoom")+0 ~= Minimap:GetZoom() and "indoors" or "outdoors"][zoom]
	Minimap:SetZoom(zoom)
	return size
end

function mod:MINIMAP_PING(event, sender, dx, dy)
	if math.abs(dx) > 0.6 or math.abs(dy) > 0.6 then return end
	if GetCVarBool("rotateMinimap") then
		local bearing = GetPlayerFacing()
		local angle = math.atan2(dx, dy)
		local hyp = math.abs(math.sqrt((dx * dx) + (dy * dy)))
		dx = hyp * math.sin(angle - bearing)
		dy = hyp * math.cos(angle - bearing)
	end

	local diameter = minimapSize[self.minimapZoom][Minimap:GetZoom()]
	local x, y = parent:GetUnitPosition("player")
	x = x + dx * diameter
	y = y + dy * diameter

	if self.ping and self.ping:Owned(self, "ping") then self.ping:Free() end
	local t1, t2 = "targeting", "SPELLS\\GENERICGLOW2B1.BLP"
	
	self.ping = parent:PlaceRangeMarker(t1, x, y, "25px", 5.5, 1, 1, 1, 1.0, "ADD"):Pulse(1.5, 1):Appear():Identify(self, "ping"):AlwaysShow():SetClipOffset("50px")
	self.glow = parent:PlaceRangeMarker(t2, x, y, "50px", 5.5, 1, 1, 0, 0.6, "ADD"):Pulse(0.8, 1):Appear():Identify(self, "glow"):AlwaysShow()
	self.ping.RegisterCallback(self, "Free", "FreePing")	

	if self.db.profile.label then
		local _, class = UnitClass(sender)
		local r, g, b = 1, 1, 1
		local classColor = class and RAID_CLASS_COLORS[class]
		if classColor then
			r, g, b = classColor.r, classColor.g, classColor.b
		end	
		self.ping:SetLabel(UnitName(sender), "BOTTOM", "TOP", r, g, b, 1, 0, 5)
	end

	if self.db.profile.arrow then
		self.glow:EdgeTo("player", nil, 5.5, 1, 0.9, 0.5, 1)
	end
end

function mod:FreePing(cbk, dot)
	self.ping = nil
	self.glow = free(self.glow)
end