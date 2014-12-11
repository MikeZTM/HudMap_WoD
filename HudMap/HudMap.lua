HudMap = LibStub("AceAddon-3.0"):NewAddon("HudMap", "AceEvent-3.0", "AceHook-3.0", "AceComm-3.0", "AceSerializer-3.0")
local mod = HudMap
local L = LibStub("AceLocale-3.0"):GetLocale("HudMap")
local db

local Media = LibStub("LibSharedMedia-3.0")
-- local MapData = LibStub("LibMapData-1.0")
local outlines = {
	[""] = L["None"],
	OUTLINE = L["Outline"],
	THICKOUTLINE = L["Thick Outline"]
}
mod.outlines = outlines

BINDING_HEADER_HUDMAP 			= L["HudMap"]
BINDING_NAME_HUDMAP_ZOOMIN 	= L["Zoom In"]
BINDING_NAME_HUDMAP_ZOOMOUT = L["Zoom Out"]
BINDING_NAME_TOGGLE_HUDMAP 	= L["Toggle HudMap"]

local debugNames = {"Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot", "Golf", "Hotel"}

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
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local updateFrame = CreateFrame("Frame")
local Astrolabe = DongleStub("Astrolabe-1.0")
local onUpdate, minimapSize, indoors, Point, Edge
local zoneScale = {1500, 1000}
local followedUnits = {}
local paused
local callbacks = CallbackHandler:New(mod)
local showOverride, toggleOverride
local optionFrames = {}
local LDB = LibStub("LibDataBroker-1.1", true)
local Icon = LibStub("LibDBIcon-1.0")
local LDB_Plugin
local configFrame

local SN = setmetatable({}, {__index = function(t, k)
	local n = GetSpellInfo(k)
	rawset(t, k, n)
	return n
end})

mod.SN = SN

local GetNumRaidMembers, GetNumPartyMembers = _G.GetNumRaidMembers, _G.GetNumPartyMembers
local GetCVar, GetTime, UIParent = _G.GetCVar, _G.GetTime, _G.UIParent
local UnitExists, UnitIsUnit = _G.UnitExists, _G.UnitIsUnit

local targetCanvasAlpha
-- local HudMapMinimap, HudMapStandaloneCluster = _G.HudMapMinimap, _G.HudMapStandaloneCluster

local textureLookup = {
	diamond 	= [[Interface\TARGETINGFRAME\UI-RAIDTARGETINGICON_3.BLP]],
	star 			= [[Interface\TARGETINGFRAME\UI-RaidTargetingIcon_1.blp]],
	circle  	= [[Interface\TARGETINGFRAME\UI-RaidTargetingIcon_2.blp]],
	triangle 	= [[Interface\TARGETINGFRAME\UI-RaidTargetingIcon_4.blp]],
	moon			= [[Interface\TARGETINGFRAME\UI-RaidTargetingIcon_5.blp]],
	square		= [[Interface\TARGETINGFRAME\UI-RaidTargetingIcon_6.blp]],
	cross			= [[Interface\TARGETINGFRAME\UI-RaidTargetingIcon_7.blp]],
	skull			= [[Interface\TARGETINGFRAME\UI-RaidTargetingIcon_8.blp]],
	cross2		= [[Interface\RAIDFRAME\ReadyCheck-NotReady.blp]],
	check			= [[Interface\RAIDFRAME\ReadyCheck-Ready.blp]],
	question	= [[Interface\RAIDFRAME\ReadyCheck-Waiting.blp]],
	targeting = [[Interface\Minimap\Ping\ping5.blp]],
	highlight = [[Interface\AddOns\HudMap\assets\alert_circle]],
	radius 		= [[Interface\AddOns\HudMap\assets\radius]],
	radius_lg	= [[Interface\AddOns\HudMap\assets\radius_lg]],
	timer			= [[Interface\AddOns\HudMap\assets\timer]],
	glow			= [[Interface\GLUES\MODELS\UI_Tauren\gradientCircle]],
	party     = [[Interface\MINIMAP\PartyRaidBlips]],
	tank      = [[Interface\AddOns\HudMap\assets\roles]],
	dps	      = [[Interface\AddOns\HudMap\assets\roles]],
	healer    = [[Interface\AddOns\HudMap\assets\roles]],
	fadecircle	= [[Interface\AddOns\HudMap\assets\fadecircle]],
	ring			= [[SPELLS\CIRCLE]],
	rune1			= [[SPELLS\AURARUNE256.BLP]],
	rune2			= [[SPELLS\AURARUNE9.BLP]],
	rune3			= [[SPELLS\AURARUNE_A.BLP]],
	rune4			= [[SPELLS\AURARUNE_B.BLP]],
	paw				= [[SPELLS\Agility_128.blp]],
	cyanstar  = [[SPELLS\CYANSTARFLASH.BLP]],
	summon    = [[SPELLS\DarkSummon.blp]],
	reticle   = [[SPELLS\Reticle_128.blp]],
	fuzzyring = [[SPELLS\WHITERINGTHIN128.BLP]],
	fatring 	= [[SPELLS\WhiteRingFat128.blp]],
	swords		= [[SPELLS\Strength_128.blp]],
	-- tank      = [[Interface\LFGFrame\LFGRole_BW]],
	-- dps	      = [[Interface\LFGFrame\LFGRole_BW]],
	-- healer    = [[Interface\LFGFrame\LFGRole_BW]]
}
local textureKeys, textureVals = {}, {}
mod.textureKeys, mod.textureVals = textureKeys, textureVals

local texBlending = {
	highlight = "ADD",
	targeting = "ADD",
	glow 			= "ADD",
	ring      = "ADD",
	rune1			= "ADD",
	rune2			= "ADD",
	rune3			= "ADD",
	rune4			= "ADD",
	paw				= "ADD",
	reticle   = "ADD",
	cyanstar  = "ADD",
	summon		= "ADD",
	fuzzyring	= "ADD",
	fatring		= "ADD",
	swords		= "ADD"
	-- timer			= "ADD",
}

local texCoordLookup = {
	party = {0.525, 0.6, 0.04, 0.2},
	tank = {0.5, 0.75, 0, 1},
	dps = {0.75, 1, 0, 1},
	healer = {0.25, 0.5, 0, 1},
	paw = {0.124, 0.876, 0.091, 0.903},
	rune4 = {0.032, 0.959, 0.035, 0.959},
	reticle = {0.05, 0.95, 0.05, 0.95}
}

local frameScalars = {
	rune1 = 0.86,
	rune2 = 0.86,
	rune3 = 0.77,
	summon = 0.86,
}

local function UnregisterAllCallbacks(obj)
	-- Cancel all registered callbacks. CBH doesn't seem to provide a method to do this.
	if obj.callbacks.insertQueue then
		for eventname, callbacks in pairs(obj.callbacks.insertQueue) do
			for k, v in pairs(callbacks) do
				callbacks[k] = nil
			end
		end
	end
	for eventname, callbacks in pairs(obj.callbacks.events) do
		for k, v in pairs(callbacks) do
			callbacks[k] = nil
		end
		if obj.callbacks.OnUnused then
			obj.callbacks.OnUnused(obj.callbacks, target, eventname)
		end
	end
end

mod.RegisterTexture = function(self, key, tex, blend, cx1, cx2, cy1, cy2, scalar)
	if key then
		textureLookup[key] = tex
		if blend then texBlending[key] = blend end
		if cx1 and cx2 and cy1 and cy2 then
			texCoordLookup[key] = {cx1, cx2, cy1, cy2}
		end
		if scalar then
			frameScalars[key] = scalar
		end
	end
	wipe(textureKeys)
	for k, v in pairs(textureLookup) do tinsert(textureKeys, k) end
	wipe(textureVals)
	for k, v in pairs(textureLookup) do textureVals[v] = v end
end
mod:RegisterTexture()

mod.UnitIsMappable = function(unit, allowSelf)
	local x, y = GetPlayerMapPosition(unit)
	if (not allowSelf and UnitIsUnit("player", unit)) or
		 (x == 0 and y == 0) or
		 not UnitIsConnected(unit) or
		 UnitIsConnected(unit) == 0
		 then return false end
	return true
end

mod.free = function(e, owner, id, noAnimate)
	if e and not e.freed then
		if owner and id then
			if e:Owned(owner, id) then
				e:Free(noAnimate)
			else
				return e
			end
		else
			e:Free()
		end
	end
	return nil
end

local options = {
	type = "group",
	args = {}
}
mod.options = options

local coreOptions = {
	type = "group",
	name = L["General"],
	order = 1,
	args = {
		adaptiveZoom = {
			type = "group",
			name = L["Adaptive Zoom"],
			disabled = function() return not db.useAdaptiveZoom end,
			args = {
				interestRadius = {
					type = "range",
					name = L["Interest Radius"],
					min = 20,
					max = 200,
					step = 5,
					bigStep = 5,
					get = function()
						return db.interestRadius
					end,
					set = function(info, v)
						db.interestRadius = v
					end,
					order = 101,
				},
				minRadius = {
					type = "range",
					name = L["Minimum Radius"],
					min = 5,
					max = 50,
					step = 5,
					bigStep = 5,
					get = function()
						return db.minRadius
					end,
					set = function(info, v)
						db.minRadius = v
					end,
					order = 102,
				},
			}
		},
		staticZoom = {
			type = "group",
			name = L["Static Zoom"],
			disabled = function() return db.useAdaptiveZoom end,
			args = {
				zoomLevel = {
					type = "range",
					name = L["Fixed Zoom"],
					min = 20,
					max = 200,
					step = 5,
					bigStep = 5,
					get = function()
						return db.zoomLevel
					end,
					set = function(info, v)
						db.zoomLevel = v
						mod:SetZoom(v)
					end,
					order = 102,					
				},
				zoomInBinding = {
					type = "keybinding",
					name = L["Zoom In"],
					order = 105,
					get = function() return GetBindingKey("HUDMAP_ZOOMIN") end,
					set = function(info, v)
						SetBinding(v, "HUDMAP_ZOOMIN")
						SaveBindings(GetCurrentBindingSet())
					end
				},
				zoomOutBinding = {
					type = "keybinding",
					name = L["Zoom Out"],
					order = 106,
					get = function() return GetBindingKey("HUDMAP_ZOOMOUT") end,
					set = function(info, v)
						SetBinding(v, "HUDMAP_ZOOMOUT")
						SaveBindings(GetCurrentBindingSet())
					end
				}
			}
		},
		labels = {
			type = "group",
			order = 200,
			name = L["Labels"],
			args = {
				useText = {
					type = "toggle",
					name = L["Show Labels"],
					get = function() return db.labels.enable end,
					set = function(info, v)
						db.labels.enable = v
						mod:UpdateLabels()
					end
				},
				font = {
					type = "select",
					name = L["Font"],
					desc = L["Font"],
					dialogControl = 'LSM30_Font',
					values = AceGUIWidgetLSMlists.font,
					get = function() return db.labels.font end,
					set = function(info, v) 
						db.labels.font = v
						mod:UpdateLabels()
					end
				},
				fontsize = {
					type = "range",
					name = L["Font size"],
					desc = L["Font size"],
					min = 4,
					max = 30,
					step = 1,
					bigStep = 1,
					get = function() return db.labels.size end,
					set = function(info, v)
						db.labels.size = v
						mod:UpdateLabels()
					end
				},
				outline = {
					type = "select",
					name = L["Font Outline"],
					desc = L["Font outlining"],
					values = outlines,
					get = function() return db.labels.outline or "" end,
					set = function(info, v) 
						db.labels.outline = v
						mod:UpdateLabels()
					end
				}				
			}
		},
		general = {
			type = "group",
			name = L["General Options"],
			order = 1,
			args = {
				mode = {
					type = "select",
					name = L["Mode"],
					values = {
						hud = L["HUD"],
						minimap = L["Minimap"]
					},
					get = function() return db.mode end,
					set = function(info, v)
						db.mode = v
						mod:UpdateFrame()
						if not configFrame:IsVisible() then
							mod:SetArea()
						end
					end
				},
				enableMinimap = {
					type = "toggle",
					name = L["Enable Minimap Button"],
					get = function()
						return not db.minimapIcon.hide
					end,
					disabled = function() return Icon == nil end,
					set = function(info, v)
						db.minimapIcon.hide = not v
						if Icon then
							if db.minimapIcon.hide then
								Icon:Hide("HudMap")
							else
								Icon:Show("HudMap")
							end
						end
					end
				},
				adjust = {
					type = "execute",
					name = L["Set Visible Area"],
					func = function() mod:SetArea() end,
					order = 200
				},
				reset = {
					type = "execute",
					name = L["Reset Visible Area"],
					func = function()
						db.canvasX = nil
						db.canvasY = nil
						mod:UpdateCanvasPosition()
					end,					
					order = 201
				},

				rotateMap = {
					type = "toggle",
					name = L["Rotate Map"],
					desc = L["Rotates the map around you as you move."],
					get = function()
						return db.rotateMap
					end,
					set = function(info, v)
						db.rotateMap = v
					end,
					order = 50
				},
				useAutozoom = {
					type = "toggle",
					name = L["Use Adaptive Zoom"],
					get = function()
						return db.useAdaptiveZoom
					end,
					set = function(info, v)
						db.useAdaptiveZoom = v
					end,
					order = 51
				},
				alpha = {
					type = "range",
					name = L["Master Opacity"],
					order = 6,
					min = 0,
					max = 1,
					step = 0.01,
					bigStep = 0.01,
					get = function()
						return db.alpha
					end,
					set = function(info, v)
						db.alpha = v
						mod.canvas:SetAlpha(v)
					end,
					order = 101
				},
				binding = {
					type = "keybinding",
					name = L["Toggle Binding"],
					order = 2,
					get = function()
						return GetBindingKey("TOGGLE_HUDMAP")
					end,
					set = function(info, v)
						SetBinding(v, "TOGGLE_HUDMAP")
						SaveBindings(GetCurrentBindingSet())
					end,
					order = 150
				},
				clipFar = {
					type = "toggle",
					name = L["Clip Far Objects"],
					desc = L["Hide objects that are outside of your zoom level or interest radius"],
					order = 125,
					get = function() return db.clipFar end,
					set = function(info, v) db.clipFar = v end
				},
				clipRadius = {
					type = "toggle",
					name = L["Include Radius For Clip"],
					desc = L["When checked, objects whose radius falls outside the zoom level will be hidden. When unchecked, objects whose center falls outside the zoom level will be hidden."],
					order = 126,
					get = function() return db.clipRadius end,
					set = function(info, v) db.clipRadius = v end
				},
				autoHide = {
					type = "toggle",
					name = L["Auto hide"],
					desc = L["Hide when there are no other active HUD objects."],
					get = function()
						return db.autoHide
					end,
					set = function(info, v)
						toggleOverride = nil
						db.autoHide = v
						mod:UpdateVisibility()
					end
				}
			}
		},
		modules = {
			type = "group",
			name = L["Modules"],
			order = 2,
			args = {}
		},
		minimapMode = {
			type = "group",
			name = L["Border & Background"],
			get = function(info)
				local t = db.frameSettings[info[#info]]
				if type(t) == "table" then
					return unpack(t)
				else
					return t
				end
			end,
			set = function(info, ...)
				if select("#", ...) > 1 then
					for i = 1, select("#", ...) do
						db.frameSettings[info[#info]][i] = select(i, ...)
					end
				else
					db.frameSettings[info[#info]] = ...
				end
				mod:UpdateFrame()
			end,
			args = {
				background = {
					name = L["Background"],
					type = "select",
					dialogControl = 'LSM30_Background',
					values = AceGUIWidgetLSMlists.background,
					order = 10
				},
				backgroundColor = {
					type = "color",
					hasAlpha = true,
					name = L["Background Color"],
					order = 11
				},
				border = {
					name = L["Border"],
					type = "select",
					dialogControl = 'LSM30_Border',
					values = AceGUIWidgetLSMlists.border,
					order = 20,
				},
				borderColor = {
					type = "color",
					hasAlpha = true,
					name = L["Border Color"],
					order = 21
				},				
				inset = {
					name = L["Insets"],
					type = "range",
					min = 0,
					max = 20,
					step = 1,
					bigStep = 1,						
				}
			}
		},
		visibility = {
			type = "group",
			order = 105,
			name = L["Show when..."],
			get = function(info)
				return db.visibility[info[#info]]
			end,
			set = function(info, v)
				db.visibility[info[#info]] = v
				toggleOverride = nil
				mod:UpdateVisibility()
			end,
			args = {
				anywhere = {
					name = L["Anywhere"],
					type = "toggle",
					order = 1
				},
				battleground = {
					name = L["Battlegrounds"],
					type = "toggle",
					disabled = function() return db.visibility.anywhere end
				},
				party = {
					name = L["5-man Instance"],
					type = "toggle",
					disabled = function() return db.visibility.anywhere end
				},
				raid = {
					name = L["Raid Instance"],
					type = "toggle",
					disabled = function() return db.visibility.anywhere end
				}
			}
		}
	}
}

local defaults = {
	profile = {
		useGatherMate = true,
		useQuestHelper = true,
		useRoutes = true,
		hudColor = {},
		textColor = {r = 0.5, g = 1, b = 0.5, a = 1},
		scale = 6,
		alpha = 1,
		maxSize = UIParent:GetHeight() * 0.48,
		maxSizeSet = false,
		interestRadius = 100,
		minRadius = 15,
		zoomLevel = 100,
		enabled = true,
		useAdaptiveZoom = true,
		visibility = {
			anywhere = true
		},
		rotateMap = true,
		labels = {
			enable = true,
			size = 12,
			outline = "THICKOUTLINE"
		},
		clipFar = true,
		clipRadius = true,
		frameSettings = {
			inset = 3,
			border = "Blizzard Tooltip",
			background = "Blizzard Dialog Background",
			borderColor = {1, 1, 1, 1},
			backgroundColor = {0, 0, 0, 1},
		},
		autoHide = true,
		minimapIcon = {},
		modules = {},
		mode = "hud"
	}
}

do
	configFrame = CreateFrame("Frame", "HudMapConfigFrame", UIParent)
	local closer
	configFrame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background"})
	configFrame:SetPoint("CENTER")
	configFrame:SetBackdropColor(0, 0.5, 0, 0.5)
	configFrame:Hide()
	configFrame.testDots = {}
	configFrame:SetScript("OnHide", function(self)
		for _, dot in ipairs(self.testDots) do
			dot:Free()
		end
	end)
	configFrame:SetMinResize(100, 100)
	configFrame:SetResizable(true)
	configFrame:SetMovable(true)
	configFrame:EnableMouse(true)
	local onUpdate = function(self)
		local x, y = self:GetCenter()
		local x2, y2 = UIParent:GetCenter()
		db.canvasX = x - x2
		db.canvasY = y - y2
		mod:UpdateCanvasPosition()
	end
	configFrame:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			self:StartMoving()
			self:SetScript("OnUpdate", onUpdate)
		end
	end)
	configFrame:SetScript("OnMouseUp", function(self)
		self:StopMovingOrSizing()
		self:SetScript("OnUpdate", nil)
	end)
	configFrame:SetScript("OnSizeChanged", function(self)
		if not self.lastSize or self.noForceResize then
			self.noForceResize = false
			return
		end
		local xd = math.abs(self:GetWidth() - self.lastSize)
		local yd = math.abs(self:GetHeight() - self.lastSize)
		self.noForceResize = true
		local size = xd > yd and self:GetWidth() or self:GetHeight()		
		self.lastSize = size
		self:SetSize(size, size)
		db.maxSize = size / 2
		db.maxSizeSet = true
		self:ClearAllPoints()
		self:SetPoint("CENTER", UIParent, "CENTER", db.canvasX, db.canvasY)
		mod:UpdateCanvasPosition()
	end)
	
	local locations = {"RIGHT", "BOTTOM"}
	for index, location in ipairs(locations) do
		local arrow = CreateFrame("Button", nil, configFrame)
		arrow:SetNormalTexture([[Interface\GLUES\COMMON\Glue-LeftArrow-Button-Up.blp]])
		arrow:SetHighlightTexture([[Interface\GLUES\COMMON\Glue-LeftArrow-Button-Highlight.blp]])
		arrow:SetPushedTexture([[Interface\GLUES\COMMON\Glue-LeftArrow-Button-Down.blp]])
		local rot = math.pi * (1 - ((index - 1) * 0.5))
		arrow:GetNormalTexture():SetRotation(rot)
		arrow:GetHighlightTexture():SetRotation(rot)
		arrow:GetPushedTexture():SetRotation(rot)
		arrow:SetPoint(location)
		arrow:SetSize(32, 32)
		arrow:SetScript("OnMouseDown", function(self)
			self:GetParent():StartSizing()			
		end)
		arrow:SetScript("OnMouseUp", function(self)
			self:GetParent():StopMovingOrSizing()
		end)
	end
	
	local closer = CreateFrame("Button", nil, configFrame)
	closer:SetNormalTexture([[Interface\BUTTONS\UI-Panel-MinimizeButton-Up.blp]])
	closer:SetHighlightTexture([[Interface\BUTTONS\UI-Panel-MinimizeButton-Highlight.blp]])
	closer:SetPushedTexture([[Interface\BUTTONS\UI-Panel-MinimizeButton-Down.blp]])
	closer:SetPoint("TOPRIGHT")
	closer:SetSize(32, 32)
	closer:SetScript("OnClick", function(self)
		self:GetParent():Hide()
		showOverride = false
		mod:UpdateVisibility()
	end)
	configFrame.closer = closer
end

if LDB then	
	LDB_Plugin = CreateFrame("Frame", "Broker_HudMap")
	LDB_Plugin.obj = LDB:NewDataObject("Broker_HudMap", {type = "data source", icon = [[Interface\ICONS\Spell_Arcane_TeleportShattrath]], label = "HudMap"})

	function LDB_Plugin.obj.OnClick(self, button)
		if button == "RightButton" then
			if IsControlKeyDown() then
				HudMap:SetArea()
			else
				-- AceConfigDialog:Open("HudMap")
				InterfaceOptionsFrame_OpenToCategory(optionFrames.default)
			end
		elseif button == "MiddleButton" then
			mod:Debug()
		else
			HudMap:Toggle(nil)
		end			
	end
	
	function LDB_Plugin.obj.OnTooltipShow(self)
		GameTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
		GameTooltip:ClearLines()
		GameTooltip:SetText(L["HudMap"])
		GameTooltip:AddDoubleLine(
			("|cff00ff00%s|r"):format(L["Left Click"]),
			L["Toggle HudMap"]
		)
		GameTooltip:AddDoubleLine(
			("|cff00ff00%s|r"):format(L["Right Click"]),
			L["Configure"]
		)
		GameTooltip:AddDoubleLine(
			("|cff00ff00%s|r"):format(L["Ctrl-Right Click"]),
			L["Move HudMap"]
		)
		GameTooltip:AddDoubleLine(
			("|cff00ff00%s|r"):format(L["Middle Click"]),
			L["Debug Mode"]
		)
		GameTooltip:Show()
	end
end

local function groupIter(state, index)
	if index < 0 then return end
	local raid, party = GetNumGroupMembers(), GetNumGroupMembers()
	local prefix = raid > 0 and "raid" or "party"
	local unit = prefix .. index
	if UnitExists(unit) then
		return index + 1, unit
	elseif raid == 0 then
		return -1, "player"
	end
end

local function group()
	return groupIter, nil, 1
end

mod.group = group

local ACD3 = LibStub("AceConfigDialog-3.0")
local coloredTextures = {}
local gatherCircle, gatherLine
local indicators = {"N", "NE", "E", "SE", "S", "SW", "W", "NW"}
local new, free
local pointCache, edgeCache = {}, {}
local activePointList, activeEdgeList = {}, {}

local zoomScale, targetZoomScale = 45, 40
local zoomMin, zoomMax = 15, 100

do
	local fine, coarse = 1 / 60, 3
	local fineTotal, fineFrames, coarseTotal = 0, 0, 0
	local zoomDelay, fadeInDelay, fadeOutDelay = 0.5, 0.25, 0.5
	
	local function computeNewScale()
		local px, py = mod:GetUnitPosition("player")
		local maxDistance = 0
		local activeObjects = 0
		for point, _ in pairs(activePointList) do
			local d = point:Distance(px, py, true)
			local maxSize
			if not db.clipFar then
				maxSize = UIParent:GetWidth()
			else
				maxSize = db.useAdaptiveZoom and db.interestRadius or db.zoomLevel
			end
			if (d > 0 and d < maxSize and not point.persist) or point.alwaysShow then
				activeObjects = activeObjects + 1				
			end

			if d > 0 and d < db.interestRadius and d > maxDistance then
				maxDistance = d
			end
		end
		if maxDistance < db.minRadius then maxDistance = db.minRadius end
		return maxDistance, activeObjects
	end
	
	local floor, ceil, min, max = math.floor, math.ceil, math.min, math.max
	function onUpdate(self, t)
		fineTotal = fineTotal + t
		coarseTotal = coarseTotal + t
		
		if coarseTotal > coarse then
			coarseTotal = coarseTotal % coarse
			mod:UpdateZoneData()
		end
		
		if fineTotal > fine then
			local steps = floor(fineTotal / fine)
			local elapsed = fine * steps
			fineTotal = fineTotal - elapsed
			
			local zoom
			zoom, mod.activeObjects = computeNewScale()
			if db.useAdaptiveZoom then
				targetZoomScale = zoom
			end
			mod:UpdateVisibility()
			
			local currentAlpha = mod.canvas:GetAlpha()
			if targetCanvasAlpha and currentAlpha ~= targetCanvasAlpha then
				local newAlpha
				if targetCanvasAlpha > currentAlpha then
					newAlpha = min(targetCanvasAlpha, currentAlpha + db.alpha * elapsed / fadeInDelay)
				else
					newAlpha = max(targetCanvasAlpha, currentAlpha - db.alpha * elapsed / fadeOutDelay)
				end
				if newAlpha == 0 and targetCanvasAlpha then
					mod.canvas:Hide()
				end
				mod.canvas:SetAlpha(newAlpha)
			elseif targetCanvasAlpha == 0 and currentAlpha == 0 then
				mod.canvas:Hide()
			end
			
			if paused then
				zoomScale = targetZoomScale
			else
				if zoomScale < targetZoomScale then
					zoomScale = min(targetZoomScale, zoomScale + ceil((targetZoomScale - zoomScale) * elapsed / zoomDelay))
				elseif zoomScale > targetZoomScale then
					zoomScale = max(targetZoomScale, zoomScale - ceil((zoomScale - targetZoomScale) * elapsed / zoomDelay))
				end
		
				mod:Update()
				callbacks:Fire("Update", mod)
			end
		end
	end
end

function mod:OnProfileChanged()
end

function mod:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("HudMapDB", defaults)
	db = self.db.profile
	self.db.RegisterCallback(self, "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
	
	self:RegisterComm("HUD")
	
	if LDB and Icon then
		Icon:Register("HudMap", LDB_Plugin.obj, db.minimapIcon)
	end
	
	AceConfig:RegisterOptionsTable("HudMap", options, {"hudmap"})
	-- optFrame = AceConfigDialog:AddToBlizOptions("HudMap", "HudMap")
	self:RegisterModuleOptions("General", coreOptions, L["General"], true)
	self:RegisterModuleOptions("GeneralOptions", coreOptions, L["General Options"], true)
	
	self.canvas = CreateFrame("Frame", "HudMapCanvas", UIParent)
	self.canvas:SetSize(UIParent:GetWidth(), UIParent:GetHeight())
	self.canvas:SetPoint("CENTER")
	self.canvas:SetScript("OnShow", function() paused = true; mod:UpdateZoneData(); end)
	self.canvas:SetScript("OnHide", function() paused = false end)
	
	self.activeObjects = 0
end

function mod:OnCommReceived(prefix, text, distribution, target, priority)
	local result, data = self:Deserialize(text)
	if data.id and self:PointExists(data.id) then
		return
	end
			
	local point = Point:New(data.zone, data.x, data.y, data.follow, data.lifetime, data.texfile, data.size, data.blend, data.r, data.g, data.b, data.a)
	if(data.label) then
		local ld = data.label
		point:SetLabel(ld.text, ld.anchorFrom, ld.anchorTo, ld.r, ld.g, ld.b, ld.a, ld.xOff, ld.yOff, ld.fontSize, ld.outline)
		point.id = data.id
	end
	
	if data.ar then
		point:SetAlertColor(data.ar, data.ag, data.ab, data.aa)
	end
	
	if data.shouldUpdateRange then
		point:RegisterForAlerts(data.shouldUpdateRange, data.alertLabel)
	end
	
	if data.pulseSize then
		point:Pulse(data.pulseSize, data.pulseSpeed)
	end
	
	if data.rotateAmount then
		point:Rotate(data.rotateAmount, data.rotateSpeed)
	end
	
	point:Appear()
end

function mod:OnProfileChanged()
	for name, module in self:IterateModules() do
		module:Disable()
		if db.modules[name] then
			module:Enable()
		end
	end
end

function mod:OnEnable()
	db = self.db.profile
	Media.RegisterCallback(mod, "LibSharedMedia_Registered")
	self:RegisterEvent("PLAYER_ENTERING_WORLD",	"UpdateZoneData")
	self:RegisterEvent("ZONE_CHANGED", 					"UpdateZoneData")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA",	"UpdateZoneData")
	self:RegisterEvent("ZONE_CHANGED_INDOORS", 	"UpdateZoneData")	
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	updateFrame:SetScript("OnUpdate", onUpdate)
	self.canvas:SetAlpha(db.alpha)
	self:UpdateCanvasPosition()
	
	if not self.addedProfiles then
		self:RegisterModuleOptions("Profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db), L["Profiles"], true)
		self.addedProfiles = true
	end
	
	self:HookScript(WorldMapFrame, "OnShow", function() paused = true end)
	self:HookScript(WorldMapFrame, "OnHide", function() paused = false end)
	
	targetZoomScale = db.scale	
	mod.pixelsPerYard = UIParent:GetHeight() / self:GetMinimapSize()	
	self:UpdateZoneData()
	self:SetZoom()
	self:UpdateFrame()
end

function mod:ShowCanvas()
	if not self.canvas:IsVisible() then
		zoomScale = targetZoomScale
		self:UpdateZoneData()
		self.canvas:SetAlpha(0)
		self.canvas:Show()
	end
	targetCanvasAlpha = db.alpha
end

function mod:HideCanvas()
	targetCanvasAlpha = 0
end

-- This is used both in :UpdateVisibility and :Toggle
function mod:TestVisibility(ignoreToggle)
	if toggleOverride ~= nil and not ignoreToggle then
		return toggleOverride
	elseif showOverride then
		return true
	end
	local inInstance, instanceType = IsInInstance()
	if db.visibility.anywhere or
		(db.visibility.battleground and instanceType == "pvp") or
		(db.visibility.party and instanceType == "party") or
		(db.visibility.raid and instanceType == "raid") then
		return not db.autoHide or mod.activeObjects > 0
	end
	return false
end

function mod:UpdateVisibility()
	if self:TestVisibility() then
		self:ShowCanvas()
	else
		self:HideCanvas()
	end
end

do
	local backdrop = {		
		tile = false,
		tileSize = 0,
		edgeSize = 16, 
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	}
	function mod:UpdateFrame()
		if db.mode == "minimap" then
			backdrop.bgFile = Media:Fetch("background", db.frameSettings.background)
			backdrop.edgeFile = Media:Fetch("border", db.frameSettings.border)
			local i = db.frameSettings.inset
			backdrop.insets.left, backdrop.insets.right, backdrop.insets.top, backdrop.insets.bottom = i, i, i, i 
			self.canvas:SetBackdrop(backdrop)
			self.canvas:SetBackdropColor(unpack(db.frameSettings.backgroundColor))
			self.canvas:SetBackdropBorderColor(unpack(db.frameSettings.borderColor))
		else
			self.canvas:SetBackdrop(nil)
		end
	end
end

function mod:LibSharedMedia_Registered()
	self:UpdateLabels()
end

function mod:UpdateLabels()
	for k, v in pairs(activePointList) do
		k:SetLabel(k.text:GetText())
	end
end

function mod:PointExists(id)
	for k, v in pairs(activePointList) do
		if(k.id == id) then
			return true
		end
	end
	return false
end

do
	local serial = 0
	local lastDot
	local debugging = false	
	function mod:ReplaceMarker()
		if not debugging then return end
		serial = (serial + 1) % 8
		local x,y = HudMap:GetUnitPosition("player", true)
		local mx = math.random(94) - 47
		local my = math.random(94) - 47
		local r, g, b, a = math.random(), math.random(), math.random(), (math.random(128) + 128) / 255
		local lifetime = math.random() * 8
		local radius = math.random() * 8 + 5
		local tex = "highlight" -- textureKeys[math.random(#textureKeys)]
		local rot = math.random(2) == 1 and -1 or 1
		local dot = HudMap:PlaceRangeMarker(tex, x+mx, y+my, radius, lifetime, r, g, b, a):Appear():Rotate(360 * rot, lifetime):SetLabel(debugNames[serial + 1])
		local edge = HudMap:AddEdge(r, g, b, a, lifetime, "player", nil, nil, nil, x+mx, y+my)
		dot:AttachEdge(edge)
		if lastDot and not lastDot.freed then
			edge = HudMap:AddEdge(r, g, b, a, lifetime, nil, nil, lastDot.stickX, lastDot.stickY, x+mx, y+my)
			dot:AttachEdge(edge)
			lastDot:AttachEdge(edge)
		end
		dot.RegisterCallback(self, "Free", "ReplaceMarker")
		lastDot = dot
	end

	function mod:Debug(num)
		debugging = not debugging
		print("|cffffff00HudMap|r: Debug mode", debugging and "|cff00ff00ON|r" or "|cffff0000OFF|r")
		showOverride = debugging
		mod:UpdateVisibility()
		if not debugging then return end
		for i = 1, (num or 10) do
			self:ReplaceMarker()
		end
	end
end

function mod:RegisterModuleOptions(name, optionTbl, displayName, noDisable)
	options.args[name] = (type(optionTbl) == "function") and optionTbl() or optionTbl
	if not noDisable then
		coreOptions.args.modules.args[name] = {
			type = "toggle",
			name = displayName,
			get = function()
				return mod:GetModule(name):IsEnabled()
			end,
			set = function(info, v)
				db.modules[name] = v
				if v then
					mod:GetModule(name):Enable()
				else
					mod:GetModule(name):Disable()
				end
			end,
			order = 1
		}
		options.args[name].disabled = function()
			return not mod:GetModule(name):IsEnabled()
		end
		local s = db.modules[name]
		local module = mod:GetModule(name)
		local state = mod.defaultState == nil and true or mod.defaultState
		module:SetEnabledState(((s == nil) and state) or (s == true and s) or false)
	end
	
	if not optionFrames.default then
		optionFrames.default = ACD3:AddToBlizOptions("HudMap", nil, nil, name)
	else
		optionFrames[name] = ACD3:AddToBlizOptions("HudMap", displayName, "HudMap", name)
	end
end

function mod:UpdateCanvasPosition()
	self.canvas:ClearAllPoints()
	configFrame:ClearAllPoints()
	if db.canvasX and db.canvasY then
		configFrame:SetPoint("CENTER", UIParent, "CENTER", db.canvasX, db.canvasY)
		self.canvas:SetPoint("CENTER", UIParent, "CENTER", db.canvasX, db.canvasY)
	else
		configFrame:SetPoint("CENTER", UIParent, "CENTER")
		self.canvas:SetPoint("CENTER", UIParent, "CENTER")
	end	
	self.canvas:SetSize(db.maxSize * 2, db.maxSize * 2)
end

function mod:COMBAT_LOG_EVENT_UNFILTERED(ev, timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, ...)
	if event == "UNIT_DIED" then
		for k, v in pairs(followedUnits) do
			if sourceName and k and UnitIsUnit(sourceName, k) and not v.persist then
				v:Free()
			end
		end
	end
end

function mod:Toggle(flag)
	if showOverride then return end
	if flag == nil then
		-- Guess what the user wants: show when actually hidden (or fading out) or hide when actually shown
		flag = not self.canvas:IsVisible() or (targetCanvasAlpha == 0)
	end
	-- What would be done without toggleOverride
	local visible = self:TestVisibility(true)
	if flag and not visible then
		-- HudMap should be hidden but the user wants to show it: override to show
		toggleOverride = true
	elseif not flag and visible then
		-- HudMap should be shown but the user wants to hide it: override to hide
		toggleOverride = false
	else
		-- Not-overriden state is what user wants: do not override
		toggleOverride = nil
	end
	-- Apply the change
	self:UpdateVisibility()
end

function mod.SetArea()
	if configFrame:IsVisible() then
		configFrame.closer:Click()
		return
	end
	showOverride = true
	mod:UpdateVisibility()
	mod:UpdateCanvasPosition()
	local size = db.maxSizeSet and (db.maxSize * 2) or 0.96 * UIParent:GetHeight()
	configFrame.lastSize = size
	configFrame:SetSize(size, size)
	configFrame:Show()
	local x,y = HudMap:GetUnitPosition("player", true)
	local a, b, c, d
	a = HudMap:PlaceRangeMarker("highlight", x+20, y, 8, nil, 1, 0, 0, 0.5):Appear():Pulse(1.2, 0.5):SetLabel(debugNames[1])
	b = HudMap:PlaceRangeMarker("highlight", x-20, y, 8, nil, 0, 1, 0, 0.5):Appear():Pulse(1.2, 1):SetLabel(debugNames[2])
	c = HudMap:PlaceRangeMarker("highlight", x, y+20, 8, nil, 0, 0, 1, 0.5):Appear():Pulse(1.2, 1.5):SetLabel(debugNames[3])
	d = HudMap:PlaceRangeMarker("highlight", x, y-20, 8, nil, 1, 0, 1, 0.5):Appear():Pulse(1.2, 2):SetLabel(debugNames[4])
	tinsert(configFrame.testDots, a)
	tinsert(configFrame.testDots, b)
	tinsert(configFrame.testDots, c)
	tinsert(configFrame.testDots, d)
end

function mod:GetMinimapShape()
	return "ROUND"
end

-- function mod:SetScales()
	-- HudMapMinimap:SetZoom(0)
	-- HudMapMinimap:ClearAllPoints()
	-- HudMapMinimap:SetPoint("CENTER", UIParent, "CENTER")
	
	-- HudMapStandaloneCluster:ClearAllPoints()
	-- HudMapStandaloneCluster:SetPoint("CENTER")
	
	-- local size = UIParent:GetHeight() / db.scale * 0.9
	-- HudMapMinimap:SetWidth(size)
	-- HudMapMinimap:SetHeight(size)
	-- HudMapStandaloneCluster:SetHeight(size)
	-- HudMapStandaloneCluster:SetWidth(size)
	
	-- HudMapStandaloneCluster:SetScale(db.scale)
-- end

-----------------------------------
--- Points
-----------------------------------

mod.textures = textureLookup

local animations = {
	onLoad = function(self)
		self.regionParent = self:GetRegionParent()
	end,
	scale = function(self)
		local p = self:GetProgress()
		local progress = self:GetParent():GetLoopState() == "REVERSE" and (1 - p) or p
		
		if progress < 0 then progress = 0
		elseif progress > 1 then progress = 1
		end
		
		local scale = 1 + ((self.pulseTarget - 1) * progress)
		self.regionParent:SetScale(scale)
	end, 
	alpha = function(self)
		self.regionParent:SetAlpha(self:GetProgress())
	end,
	fullOpacity = function(self)
		self.regionParent:SetAlpha(1)
	end,
	scaleIn = function(self)
		local scale = 1 + ((1 - self:GetProgress()) * 0.5)
		self.regionParent:SetScale(scale)
	end,
	hideParent = function(self)
		self:GetRegionParent():Hide()
	end,
	replay = function(self)
		self:Play()
	end	
}

local function DrawRouteLineCustom(T, C, sx, sy, ex, ey, w, relPoint)
   if (not relPoint) then relPoint = "BOTTOMLEFT"; end

   -- Determine dimensions and center point of line
   local dx,dy = ex - sx, ey - sy;
   local cx,cy = (sx + ex) / 2, (sy + ey) / 2;

   -- Normalize direction if necessary
	 local reverse = dx < 0 and -1 or 1
   if (dx < 0) then
      dx,dy = -dx,-dy;
   end

   -- Calculate actual length of line
   local l = math_sqrt((dx * dx) + (dy * dy));

   -- Quick escape if it's zero length
   if (l == 0) then
      T:SetTexCoord(0,0,0,0,0,0,0,0);
      T:SetPoint("BOTTOMLEFT", C, relPoint, cx,cy);
      T:SetPoint("TOPRIGHT",   C, relPoint, cx,cy);
      return;
   end

   -- Sin and Cosine of rotation, and combination (for later)
   local s,c = -dy / l, dx / l;
   local sc = s * c;

   -- Calculate bounding box size and texture coordinates
   local Bwid, Bhgt, BLx, BLy, TLx, TLy, TRx, TRy, BRx, BRy;
   if (dy >= 0) then
      Bwid = ((l * c) - (w * s)) * TAXIROUTE_LINEFACTOR_2;
      Bhgt = ((w * c) - (l * s)) * TAXIROUTE_LINEFACTOR_2;
      BLx, BLy, BRy = (w / l) * sc, s * s, (l / w) * sc;
      BRx, TLx, TLy, TRx = 1 - BLy, BLy, 1 - BRy, 1 - BLx; 
      TRy = BRx;
   else
      Bwid = ((l * c) + (w * s)) * TAXIROUTE_LINEFACTOR_2;
      Bhgt = ((w * c) + (l * s)) * TAXIROUTE_LINEFACTOR_2;
      BLx, BLy, BRx = s * s, -(l / w) * sc, 1 + (w / l) * sc;
      BRy, TLx, TLy, TRy = BLx, 1 - BRx, 1 - BLx, 1 - BLy;
      TRx = TLy;
   end
	 Bwid = Bwid * reverse
	 Bhgt = Bhgt * reverse

   -- Set texture coordinates and anchors
   T:ClearAllPoints();
   T:SetTexCoord(TLx, TLy, BLx, BLy, TRx, TRy, BRx, BRy);
   T:SetPoint("BOTTOMLEFT", C, relPoint, cx - Bwid, cy - Bhgt);
   T:SetPoint("TOPRIGHT",   C, relPoint, cx + Bwid, cy + Bhgt);
end

local max, min, abs = math.max, math.min, math.abs

local animationNames = {"fadeOutGroup", "fadeOut", "repeatAnimations", "pulseAnimations", "pulse", "rotate", "fadeInGroup"}
local Object = {
	Serial = function(self, prefix)
		self.serials = self.serials or {}
		self.serials[prefix] = (self.serials[prefix] or 0) + 1
		return prefix .. self.serials[prefix]
	end,
	
	OnAcquire = function(self)
		if self.freed == false then
			error("ERROR: Attempted to reallocate a freed object.")
		end
		
		self.radiusClipOffset = nil
		self.fixedClipOffset = nil
		self.ownerModule = nil
		self.id = nil
		self.freed = false
		
		-- print("Acquiring", self.serial)
		self.frame:Show()
		self.frame:SetAlpha(1)
		self.frame:StopAnimating()
		
		-- This shouldn't be necessary, but some animations aren't stopping.
		for _, anim in ipairs(animationNames) do
			if self[anim] then self[anim]:Stop() end
		end
	end,
	
	OnFree = function(self, noAnimate)
		if self.freed then return false end
		self.freed = true
		self.callbacks:Fire("Free", self)
		UnregisterAllCallbacks(self)
		self:Hide(noAnimate)
	end,

	ParseSize = function(self, size)
		local yards, fixed, t
		if type(size) == "string" then
			t = size:match("(%d+)px")
			if t then
				fixed = tonumber(t)
			else
				t = size:match("(%d+)yd")
				if t then
					yards = tonumber(t)
				end
			end				
		else
			yards = size
		end
		return yards, fixed
	end,
	
	SetClipOffset = function(self, offset)
		self.radiusClipOffset, self.fixedClipOffset = self:ParseSize(offset)
		return self
	end,
	
	Identify = function(self, ownerModule, id)
		self.ownerModule = ownerModule
		self.id = id
		return self
	end,
	
	Owned = function(self, ownerModule, id)
		return not self.freed and ownerModule == self.ownerModule and id == self.id
	end,
	
	Show = function(self, noAnimate)
	end,
	
	Hide = function(self, noAnimate)
		if noAnimate then
			self.frame:Hide()				
			self.frame:StopAnimating()
		else
			self.fadeOutGroup:Play()
		end
	end
}

local object_mt = {__index = Object}
local edge_mt, point_mt = {}, {}

Edge = setmetatable({
	Free = function(self, noAnimate)
		if self:OnFree(noAnimate) == false then return end
		
		for point, _ in pairs(self.points) do
			point:DetachEdge(self)
		end		
		wipe(self.points)
		self.srcPlayer, self.dstPlayer, self.sx, self.sy, self.dx, self.dy = nil, nil, nil, nil, nil, nil
		activeEdgeList[self] = nil
		
		tinsert(edgeCache, self)
		return nil
	end,
	New = function(self, r, g, b, a, srcPlayer, dstPlayer, sx, sy, dx, dy, lifetime)
		local t = tremove(edgeCache)
		if not t then
			t = setmetatable({}, edge_mt)
			t.points = {}
			t.serial = self:Serial("Edge")
			t.callbacks = CallbackHandler:New(t)
			t.frame = CreateFrame("Frame", nil, mod.canvas)
			t.frame:SetFrameStrata("LOW")
			t.texture = t.frame:CreateTexture()
			t.texture:SetAllPoints()
			-- local line = "Interface\\TaxiFrame\\UI-Taxi-Line"
			local line = "Interface\\AddOns\\HudMap\\assets\\line"
			t.texture:SetTexture(line)
			
			t.fadeOutGroup = t.frame:CreateAnimationGroup()
			t.fadeOut = t.fadeOutGroup:CreateAnimation("alpha")
      -- t.fadeOut:SetMaxFramerate(60)
			t.fadeOut:SetChange(-1)
			t.fadeOut:SetDuration(0.25)
			t.fadeOut:SetScript("OnFinished", animations.hideParent)
		end
		t:OnAcquire()
		t.srcPoint = nil
		t.dstPoint = nil
		
		t.lifetime = type(lifetime) == "number" and GetTime() + lifetime or nil
		t:SetColor(r, g, b, a)
		t.srcPlayer, t.dstPlayer = srcPlayer, dstPlayer
		t.sx, t.sy, t.dx, t.dy = sx, sy, dx, dy
		activeEdgeList[t] = true
		return t
	end,
	SetColor = function(self, r, g, b, a)
		self.r = r or 1
		self.g = g or 1
		self.b = b or 1
		self.a = a or 1
		self.texture:SetVertexColor(r, g, b, a)	
	end,	
	AttachPoint = function(self, point)
		self.points[point] = true
	end,
	DetachPoint = function(self, point)
		self.points[point] = nil
	end,	
	TrackFrom = function(self, src_or_x, y)
		if type(src_or_x) == "string" then
			self.srcPlayer = src_or_x
		elseif type(src_or_x) == "table" then
			self.srcPoint = src_or_x
		elseif src_or_x and y then
			self.srcPlayer = nil
			self.sx = src_or_x
			self.sy = y
		end
		return self	end,
	TrackTo = function(self, dst_or_x, y)
		if type(dst_or_x) == "string" then
			self.dstPlayer = dst_or_x
		elseif type(dst_or_x) == "table" then
			self.dstPoint = dst_or_x
		elseif dst_or_x and y then
			self.dstPlayer = nil
			self.dx = dst_or_x
			self.dy = y
		end
		return self
	end,
	UpdateAll = function(self)
		if(self ~= Edge) then return end
		for t, _ in pairs(activeEdgeList) do
			t:Update()
		end	
	end,
	Update = function(self)
		if self.lifetime and GetTime() > self.lifetime then
			self:Free()
			return
		end
		local sx, sy, dx, dy		
		if self.srcPlayer then
			sx, sy = mod:GetUnitPosition(self.srcPlayer)
		elseif self.srcPoint then
			sx, sy = self.srcPoint:Location()
		elseif self.sx and self.sy then
			sx, sy = self.sx, self.sy
		end
		
		if self.dstPlayer then
			dx, dy = mod:GetUnitPosition(self.dstPlayer)
		elseif self.dstPoint then
			dx, dy = self.dstPoint:Location()
		elseif self.dx and self.dy then
			dx, dy = self.dx, self.dy
		end
		
		local visible
		if sx and sy and dx and dy then
			local px, py = mod:GetUnitPosition("player")
			local radius = zoomScale * zoomScale 
			local d1 = math_pow(px - sx, 2) + math_pow(py - sy, 2)
			local d2 = math_pow(px - dx, 2) + math_pow(py - dy, 2)
			visible = d1 < radius or d2 < radius
			
			sx, sy = mod:LocationToMinimapOffset(sx, sy, db.clipFar, self.radiusClipOffset, self.fixedClipOffset)
			dx, dy = mod:LocationToMinimapOffset(dx, dy, db.clipFar, self.radiusClipOffset, self.fixedClipOffset)
		end
		if visible then
			local ox = mod.canvas:GetWidth() / 2
			local oy = mod.canvas:GetHeight() / 2
			sx = sx + ox
			dx = dx + ox
			sy = sy + oy
			dy = dy + oy
			local ax = dx - sx
			local ay = dy - sy
			local hyp = math_pow((ax*ax) + (ay*ay), 0.5)
			if hyp > 15 then
				self.texture:Show()
				DrawRouteLineCustom(self.texture, mod.canvas, sx, sy, dx, dy, 100);
			else
				self.texture:Hide()
			end
		end
	end,
}, object_mt)

function mod:AddEdge(r, g, b, a, lifetime, srcPlayer, dstPlayer, sx, sy, dx, dy)
	return Edge:New(r, g, b, a, srcPlayer, dstPlayer, sx, sy, dx, dy, lifetime)
end

do
	Point = setmetatable({
		Free = function(self, noAnimate)
			if self:OnFree(noAnimate) == false then return end
			
			if self.follow then
				followedUnits[self.follow] = nil
			end
			for edge, _ in pairs(self.edges) do
				edge:Free()
			end
			wipe(self.edges)
			
			self.stickX = nil
			self.stickY = nil
			self.follow = nil
			self.lifetime = nil
			self.lastPPY = nil
			self.lastRadius = nil
			
			activePointList[self] = nil
			tinsert(pointCache, self)

			return nil
		end,
		
		AttachEdge = function(self, edge)
			self.edges[edge] = true
			edge:AttachPoint(self)
		end,
		
		DetachEdge = function(self, edge)
			self.edges[edge] = nil
			edge:DetachPoint(self)
		end,	
		
		Stick = function(self, zone, x, y)
			self.follow = nil
			self.stickX = x
			self.stickY = y
			return self
		end,
		
		Follow = function(self, unit)
			self.stickX = nil
			self.stickY = nil
			self.follow = unit
			followedUnits[unit] = self
			return self
		end,
		
		Location = function(self)
			if self.stickX then
				return self.stickX, self.stickY
			elseif self.follow then
				return mod:GetUnitPosition(self.follow)
			end
		end,
		
		Update = function(self)
			if self.zone and mod.currentZone ~= self.zone and not self.persist then self:Free(); return end
			if not self.lifetime or self.lifetime > 0 and self.lifetime < GetTime() then self:Free(); return end
			local x, y
			
			self.callbacks:Fire("Update", self)
			
			if db.clipFar and not self.alwaysShow then
				local distance
				local px, py = mod:GetUnitPosition("player")
				distance, x, y = self:Distance(px, py, db.clipRadius)
				if distance > (db.useAdaptiveZoom and db.interestRadius or db.zoomLevel) then
					self:Hide()
					return
				end
			else
				x, y = self:Location()
			end
			
			if not x or not y or (x == 0 and y == 0) then
				self:Free()
				return
			elseif not self.frame:IsVisible() then
				self.frame:Show()
				self.fadeIn:Play()
			end
			
			x, y = mod:LocationToMinimapOffset(x, y, self.alwaysShow, self.radiusClipOffset or self.radius, self.fixedClipOffset or self.fixedSize)
			
			local needUpdate = false
			if self.follow == "player" then
				needUpdate = not self.placed
			else
				needUpdate = self.lastX ~= x or self.lastY ~= y
			end
			
			self:UpdateSize()
			
			if needUpdate then
				self.frame:ClearAllPoints()
				self.frame:SetPoint("CENTER", self.frame:GetParent(), "CENTER", x, y)
			end
			self.placed = true
			self.lastX = x
			self.lastY = y
			if self.shouldUpdateRange then
				self:UpdateAlerts()
			end
		end,
		
		UpdateSize = function(self)
			if self.radius then
				if self.lastPPY ~= mod.pixelsPerYard or self.lastRadius ~= self.radius then
					self.lastPPY = mod.pixelsPerYard
					self.lastRadius = self.radius
					local radius = self.radius / (frameScalars[self.texfile] or 1)
					local pixels = mod:RangeToPixels(radius * 2)
					self.frame:SetSize(pixels, pixels)
				end
			elseif self.fixedSize then
				self.frame:SetSize(self.fixedSize, self.fixedSize)
			end	
		end,
		
		UpdateAll = function(self)
			if(self ~= Point) then return end
			for t, _ in pairs(activePointList) do
				t:Update()
			end
		end,
		
		Pulse = function(self, size, speed)
			self.pulseSize = size
			self.pulseSpeed = speed
		
			self.pulse:SetDuration(speed)
			self.pulse:SetScale(size, size)
			self.pulseIn:SetDuration(speed)
			self.pulseIn:SetScale(1 / size, 1 / size)
			self.pulseAnimations:Play()
			return self
		end,

		Rotate = function(self, amount, speed)
			self.rotateAmount = amount
			self.rotateSpeed = speed
			
			local norm = 360 / amount
			speed = speed * norm
			amount = -360
			if speed < 0 then
				speed = speed * -1
				amount = 360
			end
			
			self.rotate:SetDuration(speed)
			self.rotate:SetDegrees(amount)
			self.repeatAnimations:Play()		
			return self
		end,
		
		Appear = function(self)
			self.fadeInGroup:Play()
			return self
		end,
		
		SetTexCoords = function(self, a, b, c, d)
			self.texture:SetTexCoord(a,b,c,d)
			return self
		end,
		
		Alert = function(self, bool)
			local r, g, b, a
			r = bool and self.alert.r or self.normal.r or 1
			g = bool and self.alert.g or self.normal.g or 1
			b = bool and self.alert.b or self.normal.b or 1
			a = bool and self.alert.a or self.normal.a or 1
			self.texture:SetVertexColor(r, g, b, a)
			if bool then
				self:SetLabel(self.alertLabel)
			else
				self:SetLabel(nil)
			end
			return self
		end,
		
		RegisterForAlerts = function(self, bool, alertLabel)
			if bool == nil then bool = true end
			self.alertLabel = alertLabel
			self.shouldUpdateRange = bool
			return self
		end,
		
		Distance = function(self, x2, y2, includeRadius)
			local x, y = self:Location()
			if not x or not y or (x == 0 and y == 0) then
				return -1
			end
			local e = x2-x
			local f = y2-y
			return math_sqrt((e*e)+(f*f)) + (includeRadius and self.radius or 0), x, y
		end,
		
		Persist = function(self, bool)
			self.persist = bool == nil and true or bool
			return self
		end,
		
		AlwaysShow = function(self, bool)
			if bool == nil then bool = true end
			self.alwaysShow = bool
			return self
		end,
		
		UpdateAlerts = function(self)
			if not self.radius then return end
			local x, y = self:Location()
			
			local alert = false
			if self.shouldUpdateRange == "all" or (self.follow and UnitIsUnit(self.follow, "player")) then
				for index, unit in group() do
					if not UnitIsUnit(unit, "player") and not UnitIsDead(unit) then
						alert = mod:DistanceToPoint(unit, x, y) < self.radius
						if alert then break end
					end
				end
			else
				alert = mod:DistanceToPoint("player", x, y) < self.radius
			end
			self:Alert(alert)	
		end,
		
		SetColor = function(self, r, g, b, a)
			self.normal.r = r or 1
			self.normal.g = g or 1
			self.normal.b = b or 1
			self.normal.a = a or 0.5
			self:Alert(false)
			return self
		end,
		
		SetAlertColor = function(self, r, g, b, a)
			self.alert.r = r or 1
			self.alert.g = g or 0
			self.alert.b = b or 0
			self.alert.a = a or 0.5
			return self
		end,
		
		SetTexture = function(self, texfile, blend)
			local tex = self.texture
			texfile = texfile or "glow"
			tex:SetTexture(textureLookup[texfile] or texfile or [[Interface\GLUES\MODELS\UI_Tauren\gradientCircle]])
			if texCoordLookup[texfile] then
				tex:SetTexCoord(unpack(texCoordLookup[texfile]))
			else
				tex:SetTexCoord(0, 1, 0, 1)
			end	
			blend = blend or texBlending[texfile] or "BLEND"
			tex:SetBlendMode(blend)
			return self
		end,
		
		SetLabel = function(self, text, anchorFrom, anchorTo, r, g, b, a, xOff, yOff, fontSize, outline)
			self.text.anchorFrom = anchorFrom or self.text.anchorFrom
			self.text.anchorTo = anchorTo or self.text.anchorTo
			self.text:ClearAllPoints()

			if not r and text then
				local _, cls = UnitClass(text)
				if cls and RAID_CLASS_COLORS[cls] then
					r, g, b, a = unpack(RAID_CLASS_COLORS[cls])
				end
			end
			self.text.r = r or self.text.r
			self.text.g = g or self.text.g
			self.text.b = b or self.text.b
			self.text.a = a or self.text.a
			
			self.text.xOff = xOff or self.text.xOff or 0
			self.text.yOff = yOff or self.text.yOff or 0
			
			if not text or text == "" or not db.labels.enable then
				self.text:SetText(nil)
				self.text:Hide()
			else
				self.text:SetPoint(self.text.anchorFrom, self.frame, self.text.anchorTo, self.text.xOff, self.text.yOff)
				self.text:SetTextColor(self.text.r, self.text.g, self.text.b, self.text.a)
				self.text:Show()
				local f, s, m = self.text:GetFont() 			
				local font = Media:Fetch("font", db.labels.font or f)
				local size = fontSize or db.labels.size or s
				local outline = outline or db.labels.outline or m
				self.text:SetFont(font, size, outline)
				self.text:SetText(text)
			end
			
			-- LabelData is for sending to remote clients
			self.labelData = self.labelData or {}
			wipe(self.labelData)
			self.labelData.text = text
			self.labelData.anchorFrom = anchorFrom
			self.labelData.anchorTo = anchorTo
			self.labelData.r = r
			self.labelData.g = g
			self.labelData.b = b
			self.labelData.a = a
			self.labelData.xOff = xOff
			self.labelData.yOff = yOff
			self.labelData.fontSize = fontSize
			self.labelData.outline = outline
			return self
		end,
		
		SetSize = function(self, size)
			self.lastRadius = nil
			self.size = size
			self.radius, self.fixedSize = self:ParseSize(size)
			if not self.radius and not self.fixedSize then
				self.fixedSize = 20
			end
			self:UpdateSize()
			return self
		end,
		
		EdgeFrom = function(self, point_or_unit_or_x, to_y, lifetime, r, g, b, a)
			local fromPlayer = self.follow
			local unit, x, y
			if type(point_or_unit_or_x) == "table" then
				unit = point_or_unit_or_x.follow
				x = point_or_unit_or_x.stickX
				y = point_or_unit_or_x.stickY
			else
				unit = to_y == nil and point_or_unit_or_x
				x = to_y ~= nil and point_or_unit_or_x
				y = to_y
			end
			local edge = Edge:New(r, g, b, a, fromPlayer, unit, self.stickX, self.stickY, x, y, lifetime)
			self:AttachEdge(edge)
			if type(point_or_unit_or_x) == "table" then
				point_or_unit_or_x:AttachEdge(edge)
				edge:SetClipOffset(point_or_unit_or_x.fixedSize and point_or_unit_or_x.fixedSize .. "px" or point_or_unit_or_x.radius)
			else
				edge:SetClipOffset(self.fixedSize and self.fixedSize .. "px" or self.radius)
			end
			return edge
		end,
		
		EdgeTo = function(self, point_or_unit_or_x, from_y, lifetime, r, g, b, a)
			local toPlayer = self.follow
			local unit, x, y
			if type(point_or_unit_or_x) == "table" then
				unit = point_or_unit_or_x.follow
				x = point_or_unit_or_x.stickX
				y = point_or_unit_or_x.stickY
			else
				unit = to_y == nil and point_or_unit_or_x
				x = to_y ~= nil and point_or_unit_or_x
				y = to_y
			end
			
			local edge = Edge:New(r, g, b, a, unit, toPlayer, x, y, self.stickX, self.stickY, lifetime)
			self:AttachEdge(edge)
			if type(point_or_unit_or_x) == "table" then
				point_or_unit_or_x:AttachEdge(edge)
			end
			edge:SetClipOffset(self.fixedSize and self.fixedSize .. "px" or self.radius)
			return edge
		end,
		
		Broadcast = function(self)
			local data = self.sendData or {}
			wipe(data)
			
			-- Base
			data.zone = self.zone
			data.x, data.y = self:Location()			
			data.lifetime = self.baseLifetime
			data.texfile = self.texfile
			data.size = self.size
			data.blend = self.blend
			data.r = self.normal.r
			data.g = self.normal.g
			data.b = self.normal.b
			data.a = self.normal.a
			data.ar = self.alert.r
			data.ag = self.alert.g
			data.ab = self.alert.b
			data.aa = self.alert.a
			data.id = self.id			
			data.pulseSize = self.pulseSize
			data.pulseSpeed = self.pulseSpeed			
			data.rotateAmount = self.rotateAmount
			data.rotateSpeed = self.rotateSpeed			
			
			-- Alert
			data.alertLabel = self.alertLabel
			data.shouldUpdateRange = self.shouldUpdateRange
			
			-- Label
			data.label = self.labelData
			local text = mod:Serialize(data)
			
			mod:SendCommMessage("HUD", text, "RAID", nil, "ALERT")
		end,
		
		New = function(self, zone, x, y, follow, lifetime, texfile, size, blend, r, g, b, a)
			local t = tremove(pointCache)
			if not t then
				t = setmetatable({}, point_mt)
				t.serial = self:Serial("Circle")
				t.callbacks = CallbackHandler:New(t)
				t.frame = CreateFrame("Frame", nil, mod.canvas)
				t.frame:SetFrameStrata("MEDIUM")
				t.frame.owner = t
				t.text = t.frame:CreateFontString()
				t.text:SetFont(STANDARD_TEXT_FONT, 10, "")
				t.text:SetDrawLayer("OVERLAY")
				t.text:SetPoint("BOTTOM", t.frame, "CENTER")
				t.edges = {}
				t.texture = t.frame:CreateTexture()
				t.texture:SetAllPoints()
				t.repeatAnimations = t.frame:CreateAnimationGroup()
				t.repeatAnimations:SetLooping("REPEAT")
				
				t.pulseAnimations = t.frame:CreateAnimationGroup()
				t.pulseAnimations:SetScript("OnFinished", animations.replay)				
				
				t.pulse = t.pulseAnimations:CreateAnimation("scale")
        -- t.pulse:SetMaxFramerate(60)
				t.pulse:SetOrder(1)
				t.pulseIn = t.pulseAnimations:CreateAnimation("scale")
        -- t.pulseIn:SetMaxFramerate(60)
				t.pulseIn:SetOrder(2)
				t.pulse:SetScript("OnPlay", animations.onLoad)
				
				t.rotate = t.repeatAnimations:CreateAnimation("rotation")
        -- t.rotate:SetMaxFramerate(60)
				
				t.normal, t.alert = {}, {}				
				
				do
					t.fadeInGroup = t.frame:CreateAnimationGroup()
					
					local scaleOut = t.fadeInGroup:CreateAnimation("scale")
          -- scaleOut:SetMaxFramerate(60)
					scaleOut:SetDuration(0)
					scaleOut:SetScale(1.5, 1.5)
					scaleOut:SetOrder(1)
					
					t.fadeIn = t.fadeInGroup:CreateAnimation()
          -- t.fadeIn:SetMaxFramerate(60)
					t.fadeIn:SetDuration(0.35)
					t.fadeIn:SetScript("OnPlay", function(self)
						animations.onLoad(self)
						t.fadeOutGroup:Stop()
					end)

					t.fadeIn:SetScript("OnUpdate", animations.alpha)
					t.fadeIn:SetScript("OnStop", animations.fullOpacity)
					t.fadeIn:SetOrder(2)

					local scaleIn = t.fadeInGroup:CreateAnimation("scale")
          -- scaleIn:SetMaxFramerate(60)
					scaleIn:SetDuration(0.35)
					scaleIn:SetScale(1 / 1.5, 1 / 1.5)
					scaleIn:SetOrder(2)
				end
				
				t.fadeOutGroup = t.frame:CreateAnimationGroup()
				t.fadeOut = t.fadeOutGroup:CreateAnimation("alpha")
        -- t.fadeOut:SetMaxFramerate(60)
				t.fadeOut:SetChange(-1)
				t.fadeOut:SetDuration(0.25)
				t.fadeOut:SetScript("OnFinished", animations.hideParent)
				t.fadeOutGroup:SetScript("OnPlay", function() t.fadeInGroup:Stop() end)
			end
			
			-- These need to be reset so that reconstitution via broadcasts don't get pooched up.
			t.id = nil
			t.shouldUpdateRange = nil
			t.pulseSize = nil
			t.rotateAmount = nil
			
			t:OnAcquire()
			
			t.texture:SetDrawLayer("ARTWORK")
			t.alwaysShow = nil
			t.persist = nil
			t.placed = false

			t:SetLabel(nil, "BOTTOM", "CENTER", r, g, b, a)
			
			t.texfile = texfile
			t:SetTexture(texfile, blend)
			t:SetSize(size or 20)
			
			t:SetColor(r, g, b, a)
			t:SetAlertColor(1, 0, 0, a)
			t:Alert(false)
			
			t.shouldUpdateRange = false
			
			if x and y then
				t:Stick(zone, x, y)
			elseif follow then
				t:Follow(follow)
			end
			t.baseLifetime = lifetime
			t.lifetime = lifetime and (GetTime() + lifetime) or -1
			t.zone = zone
			activePointList[t] = true
			t.callbacks:Fire("New", t)
			return t
		end,
	}, object_mt)
end
edge_mt.__index = Edge
point_mt.__index = Point

function mod:UpdateMode()
end

function mod:PlaceRangeMarker(texture, x, y, radius, duration, r, g, b, a, blend)
	return Point:New(self.currentZone, x, y, nil, duration, texture, radius, blend, r, g, b, a)	
end

function mod:PlaceStaticMarkerOnPartyMember(texture, person, radius, duration, r, g, b, a, blend)
	local x, y = self:GetUnitPosition(person)
	return Point:New(nil, x, y, nil, duration, texture, radius, blend, r, g, b, a)
end

function mod:PlaceRangeMarkerOnPartyMember(texture, person, radius, duration, r, g, b, a, blend)
	return Point:New(nil, nil, nil, person, duration, texture, radius, blend, r, g, b, a)
end

local ABS, POW = math.abs, math.pow
function mod:DistanceToPoint(unit, x, y)
	local x1, y1 = self:GetUnitPosition(unit)
	local x2, y2 = x, y
	local dx = x2 - x1
	local dy = y2 - y1
	return ABS(POW((dx*dx)+(dy*dy), 0.5))
end

function mod:UnitDistance(unitA, unitB)
	local x1, y1 = self:GetUnitPosition(unitA)
	local x2, y2 = self:GetUnitPosition(unitB)
	local dx = x2 - x1
	local dy = y2 - y1
	-- 
	return ABS(POW((dx*dx)+(dy*dy), 0.5))
end

function mod:GetUnitPosition(unit, forceZone)
	if not unit then return nil, nil end
	if forceZone then SetMapToCurrentZone()	end
	local x, y = GetPlayerMapPosition(unit)
	return self:CoordsToPosition(x, y)
end

function mod:CoordsToPosition(x, y)
	if not x or not y or (x == 0 and y == 0) then return x, y end
	if not zoneScale then
		return x * 1500, (1 - y) * 1000
	end
	return x * zoneScale[1], (1 - y) * zoneScale[2]
end

function mod:UpdateZoneData()
	if not self.canvas:IsVisible() or WorldMapFrame:IsVisible() then
		paused = true
		return
	end
	paused = false
  
  local m, l, x, y = Astrolabe:GetUnitPosition("player", true)
	if (x == 0 and y == 0) then
		paused = true
		return
	end
  
  -- Do we need to clear zoneScale if we don't have a map?
  if not m then return end
	
  local _, _, w, h = Astrolabe:GetMapInfo(m, l or 0)
	if(w and h) then
	zoneScale[1] = w
	zoneScale[2] = h
  end
  
	self.currentZone = l > 0 and (m .. l) or l
end

do
	local a, b
	function mod:Measure(restart)
		local a2, b2 = self:GetUnitPosition("player", true)
		if restart or not a then
			a, b = a2, b2
		else
			local c, d = (a2 - a), (b2 - b)
			print(math.sqrt((c*c)+(d*d)))
			a, b = nil, nil
		end
	end
end

function mod:SetZoom(zoom, zoomChange)
	if zoom then
		targetZoomScale = zoom
	elseif zoomChange then
		targetZoomScale = targetZoomScale + zoomChange
	else
		targetZoomScale = db.zoomLevel
	end
	db.zoomLevel = targetZoomScale
	if targetZoomScale < 20 then
		targetZoomScale = 20
	elseif targetZoomScale > 200 then
		targetZoomScale = 200
	end
end

function mod:Update()
	Point:UpdateAll()
	Edge:UpdateAll()
end

function mod:GetMinimapSize()
	return zoomScale -- math.pow(zoomScale, 2)
	-- return minimapSize[indoors and "indoor" or "outdoor"][HudMapMinimap:GetZoom()]
end

do
	local function ClipPointToRadius(dx, dy, offset)
		local clipped
		local px, py = 0, 0
		local e = px - dx
		local f = py - dy
		local distance = math_sqrt((e*e)+(f*f)) + offset
		local scaleFactor = 1 - (db.maxSize / distance)
		if distance > db.maxSize then
			dx = dx + (scaleFactor * e)
			dy = dy + (scaleFactor * f)
			clipped = true
		end
		return dx, dy
	end

	local function ClipPointToEdges(dx, dy, offset)
		local nx, ny
		local px, py = 0, 0
		local z2 = db.maxSize
		dx, dy = ClipPointToRadius(dx, dy, offset)
		nx = min(max(dx, px - z2 + offset), px + z2 - offset)
		ny = min(max(dy, py - z2 + offset), py + z2 - offset)
		return nx, ny, nx ~= dx or ny ~= dy
	end

	function mod:GetFacing()
		return GetPlayerFacing()
	end
	
	function mod:LocationToMinimapOffset(x, y, alwaysShow, radiusOffset, pixelOffset)
		mod.pixelsPerYard = db.maxSize / zoomScale
		local px, py = self:GetUnitPosition("player")
		local dx, dy
		local nx, ny
		if db.rotateMap then
			dx = (px - x) * mod.pixelsPerYard
			dy = (py - y) * mod.pixelsPerYard
		else
			dx = (x - px) * mod.pixelsPerYard
			dy = (y - py) * mod.pixelsPerYard
		end
		
		-- Now adjust for rotation
		if db.rotateMap then
			local bearing = GetPlayerFacing()
			local angle = math_atan2(dx, dy)
			local hyp = math.abs(math_sqrt((dx * dx) + (dy * dy)))
			local x, y = math_sin(angle + bearing), math_cos(angle + bearing)
			nx, ny = -x * hyp, -y * hyp
		else
			nx, ny = dx, dy
		end
		
		if alwaysShow then
			local offset = (radiusOffset and radiusOffset * mod.pixelsPerYard) or (pixelOffset and pixelOffset / 2) or 0
			if db.mode == "hud" then
				nx, ny = ClipPointToRadius(nx, ny, offset)
			else	
				nx, ny = ClipPointToEdges(nx, ny, offset)
			end
		end		
		return nx, ny
	end

	function mod:RangeToPixels(range)
		mod.pixelsPerYard = db.maxSize / zoomScale
		return mod.pixelsPerYard * range
	end
end

------------------------------------
-- Data
------------------------------------

minimapSize = {
	indoor = {
		[0] = 290,
		[1] = 230,
		[2] = 175,
		[3] = 119,
		[4] = 79,
		[5] = 49.8,
	},
	outdoor = {
		[0] = 450,
		[1] = 395,
		[2] = 326,
		[3] = 265,
		[4] = 198,
		[5] = 132
	},
}
mod.minimapSize = minimapSize
