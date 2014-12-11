-- Name your module whatever you want.
local modName = "AOE Healing"

local parent = HudMap
local L = LibStub("AceLocale-3.0"):GetLocale("HudMap")
local mod = HudMap:NewModule(modName, "AceEvent-3.0")
local db
local SN = parent.SN

-- This is an Ace3 options table.
-- http://www.wowace.com/addons/ace3/pages/ace-config-3-0-options-tables/
-- db is a handle to your module's current profile settings, so you can use it directly.
local options = {
	type = "group",
	name = L["AOE Healing"],
	args = {
		spells = {
			type = "group",
			name = L["Spells"],
			get = function(info)
				local t = db.spells[info[#info-1]][info[#info]]
				if type(t) == "table" then
					return unpack(t)
				else
					return t
				end
			end,
			set = function(info, ...)
				if select("#", ...) > 1 then
					for i = 1, select("#", ...) do
						db.spells[info[#info-1]][info[#info]][i] = select(i, ...)
					end
				else
					db.spells[info[#info-1]][info[#info]] = ...
				end
			end,
			args = {}			
		}
	}
}

-- Define your module's defaults here. Your options will toggle them.
local defaults = {
	profile = {
		spells = {
			
			-- Efflor
			[SN[81262]:gsub(" ", "")] = {
				color = {0, 1, 0, 0.4},
				enable = true,
				texture = "fatring",
				size = 8
			},
			
			-- Holy Radiance
			[SN[82327]:gsub(" ", "")] = {
				color = {.93, .60, .69, 0.7},
				enable = true,
				texture = "fadecircle",
				size = 8
			},
		}
	}
}


local bounceSpells = {
	[SN[81262]] = false,	-- Efflorescence
	[SN[82327]] = false		-- Holy Radiance
}
local aoeSpells = {
}

local textures = {
	cyanstar = L["Spark"],
	radius = L["Dots"],
	radius_lg = L["Large Dots"],
	ring = L["Solid"],
	fuzzyring = L["Ring 2"],
	fatring = L["Ring 3"],
	glow = L["Glow"],
	fadecircle = L["Faded Circle"],
}
-- One-time setup code is done here.
function mod:OnInitialize()
	self.db = parent.db:RegisterNamespace(modName, defaults)
	parent:RegisterModuleOptions(modName, options, modName)
	db = self.db.profile
	
	for k, v in pairs(bounceSpells) do
		local opt = {
			type = "group",
			name = k,
			args = {
				enable = {
					type = "toggle",
					name = L["Enable"]
				},
				texture = {
					type = "toggle",
					name = L["Texture"],
					type = "select",
					values = textures
				},
				color = {
					type = "color",
					name = L["Color"],
					hasAlpha = true
				},
				-- size = {
					-- name = L["Size"],
					-- type = "range",
					-- min = 5,
					-- max = 50,
					-- step = 1,
					-- bigStep = 1
				-- }
			}
		}
		options.args.spells.args[k:gsub(" ", "")] = opt
	end
	
	for k, v in pairs(aoeSpells) do
		local opt = {
			type = "group",
			name = k,
			args = {
				enable = {
					type = "toggle",
					name = L["Enable"]
				},
				texture = {
					type = "toggle",
					name = L["Texture"],
					type = "select",
					values = textures
				},
				color = {
					type = "color",
					name = L["Color"],
					hasAlpha = true
				},
				size = {
					name = L["Size"],
					type = "range",
					min = 5,
					max = 50,
					step = 1,
					bigStep = 1
				}
			}
		}
		options.args.spells.args[k:gsub(" ", "")] = opt
	end
end

function mod:OnEnable()
	db = self.db.profile
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

local lastPlayer, lastPlayerTime = {}, {}
local playerGUID = UnitGUID("player")
local defaultColor, emptyTable = {0, 1, 0, 0.6}, {}
local swiftMendTarget = {}

function mod:COMBAT_LOG_EVENT_UNFILTERED(ev, timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, ...)
	if event == "SPELL_CAST_START" or event == "SPELL_CAST_SUCCESS" then
		lastPlayer[spellName] = nil
		if spellID == 18562 then -- Swiftmend
			swiftMendTarget[sourceName] = destName
		end
	end
	
	local isPlayer = bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) == COMBATLOG_OBJECT_TYPE_PLAYER
	
	if event == "SPELL_AURA_APPLIED" and isPlayer and destName == sourceName then
		if spellID == 81262 and UnitInParty(swiftMendTarget[sourceName]) and db.spells[SN[81262]:gsub(" ", "")].enable then
			local settings = db.spells[spellName:gsub(" ", "")] or emptyTable
			local texture = settings.texture or "ring"
			local size = settings.size or 8
			local r, g, b, a = unpack(settings.color or defaultColor)
			parent:PlaceStaticMarkerOnPartyMember(texture, swiftMendTarget[sourceName], size, 7, r, g, b, a):Appear()
		elseif spellID == 82327 and UnitInParty(destName) and db.spells[SN[82327]:gsub(" ", "")].enable then
			local settings = db.spells[spellName:gsub(" ", "")] or emptyTable
			local texture = settings.texture or "ring"
			local size = settings.size or 8
			local bigSize = 20
			local r, g, b, a = unpack(settings.color or defaultColor)
			local a2 = a - 0.3
			if a2 < 0 then a2 = 0 end
			parent:PlaceRangeMarkerOnPartyMember(texture, destName, size, 10, r, g, b, a):Appear():Rotate(360,15)
			parent:PlaceRangeMarkerOnPartyMember(texture, destName, bigSize, 10, r, g, b, a2):Appear():Rotate(360,15)
		end
	end
	
	-- if sourceGUID == playerGUID and destName and isPlayer then
		-- if bounceSpells[spellName] then
			-- local source = lastPlayer[spellName] or "player"
			-- lastPlayer[spellName] = destName
			
			-- local settings = db.spells[spellName:gsub(" ", "")] or emptyTable
			-- local r, g, b, a = unpack(settings.color or defaultColor)
			-- parent:AddEdge(r, g, b, a, 0.6, source, destName)
			
		-- elseif aoeSpells[spellName] then
			-- local settings = db.spells[spellName:gsub(" ", "")] or emptyTable
			-- local texture = settings.texture or "ring"
			-- local size = (settings.size or 25) .. "px"
			-- local r, g, b, a = unpack(settings.color or defaultColor)
			-- parent:PlaceRangeMarkerOnPartyMember(texture, destName, size, 0.9, r, g, b, a, "ADD"):Pulse(1.8, 0.9):Rotate(360, 2):Appear()
		-- end
	-- end
end
