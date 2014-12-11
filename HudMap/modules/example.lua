-- Name your module whatever you want.
local modName = "My Module"

local parent = HudMap
local L = LibStub("AceLocale-3.0"):GetLocale("HudMap")
local mod = HudMap:NewModule(modName, "AceEvent-3.0")
local db

-- This is an Ace3 options table.
-- http://www.wowace.com/addons/ace3/pages/ace-config-3-0-options-tables/
-- db is a handle to your module's current profile settings, so you can use it directly.
local options = {
	type = "group",
	name = L["My Module"],
	args = {
		enable = {
			type = "toggle",
			name = L["Enable"],
			get = function()
				return db.enable
			end,
			set = function(info, v)
				db.enable = v
			end
		}
	}
}

-- Define your module's defaults here. Your options will toggle them.
local defaults = {
	profile = {
		enable = true
	}
}

-- One-time setup code is done here.
function mod:OnInitialize()
	self.db = parent.db:RegisterNamespace(modName, defaults)
	db = self.db.profile

	parent:RegisterModuleOptions(modName, options, modName)
end

-- And we're ready to rock! Register events or do other startup code here.
function mod:OnEnable()
	db = self.db.profile
	local x, y = HudMap:GetUnitPosition("player")
	HudMap:PlaceRangeMarker("highlight", x-10, y-10, 10, nil, 1, 0, 0, 0.7)
	HudMap:PlaceRangeMarker("highlight", x-10, y+10, 10, nil, 0, 1 , 0, 0.7)
	HudMap:PlaceRangeMarker("highlight", x+10, y-10, "10yd", nil, 0, 0, 1, 0.7)
	HudMap:PlaceRangeMarker("highlight", x+10, y+10, "10yd", nil, 0, 1, 1, 0.7)
	
	-- HudMap:PlaceRangeMarker("highlight", x, y, 16, nil, 0, 0.7, 0, 0.3):Appear():Pulse(0.95, 1.5):Rotate(-360, 4)
	-- HudMap:PlaceRangeMarker("star", x+20, y+10, "20px")
	-- HudMap:PlaceRangeMarker("skull", x, y, "20px"):SetLabel("skull")
	-- HudMap:PlaceRangeMarker("targeting", x, y, "35px", nil, 1, 1, 1, 1):Appear():Pulse(3.5, 1.75):Rotate(360, 6)
	
	-- HudMap:AddEdge(1, 0.5, 0, 0.5, "player", nil, nil, nil, x + 10, y - 10)
	-- HudMap:AddEdge(0, 1, 0.5, 0.5, "player", nil, nil, nil, x + 10, y + 10)
	-- HudMap:AddEdge(0.5, 1, 0, 0.5, "player", nil, nil, nil, x - 10, y - 20)
	-- HudMap:AddEdge(0.75, 0.75, 0, 0.5, nil, "player", x - 20, y + 20)
end
