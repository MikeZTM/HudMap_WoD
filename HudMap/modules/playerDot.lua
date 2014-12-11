local modName = "Player Icon"
local parent = HudMap
local L = LibStub("AceLocale-3.0"):GetLocale("HudMap")
local mod = HudMap:NewModule(modName, "AceEvent-3.0")

--[[ Default upvals 
     This has a slight performance benefit, but upvalling these also makes it easier to spot leaked globals. ]]--
local _G = _G.getfenv(0)
local wipe, type, pairs, tinsert, tremove, tonumber = _G.wipe, _G.type, _G.pairs, _G.tinsert, _G.tremove, _G.tonumber
local math, math_abs, math_pow, math_sqrt, math_sin, math_cos, math_atan2 = _G.math, _G.math.abs, _G.math.pow, _G.math.sqrt, _G.math.sin, _G.math.cos, _G.math.atan2
local error, rawset, rawget, print = _G.error, _G.rawset, _G.rawget, _G.print
local tonumber, tostring = _G.tonumber, _G.tostring
local getmetatable, setmetatable, pairs, ipairs, select, unpack = _G.getmetatable, _G.setmetatable, _G.pairs, _G.ipairs, _G.select, _G.unpack
--[[ -------------- ]]--

local db

local playerIcons = {
	minimapArrow 	= [[Interface\Minimap\MinimapArrow]],
	corners 			= [[Interface\BUTTONS\UI-AutoCastableOverlay]],
	metalRing			= [[Interface\CHARACTERFRAME\TotemBorder]],
	glowingRing 	= [[Interface\Cooldown\ping4]],
	crosshairs 		= [[Interface\Minimap\Ping\ping5]],
	pingRing			= [[Interface\Minimap\Ping\ping2]],
	silverArrow		= [[Interface\Minimap\Rotating-MinimapGroupArrow]],
	goldArrow			= [[Interface\Minimap\ROTATING-MINIMAPGUIDEARROW]],
	rune1					= [[SPELLS\AURARUNE_B]],
	rune2					= [[SPELLS\AURARUNE_C]],
	glowingDot		= [[SPELLS\AURA_01]],	
}

local playerIconNames = {
	minimapArrow 	= L["Minimap Arrow"],
	corners 			= L["Corners"],
	metalRing 		= L["Metal Ring"],
	glowingRing 	= L["Glowing Ring"],	
	crosshairs 		= L["Crosshairs"],
	pingRing			= L["Ping Ring"],
	silverArrow		= L["Silver Arrow"],
	goldArrow			= L["Gold Arrow"],
	rune1					= L["Rune 1"],
	rune2					= L["Rune 2"],
	glowingDot		= L["Glowing Dot"],
}

local playerDotBlends = {
	crosshairs = "ADD",
	glowingDot = "ADD",
	glowingRing = "ADD",
	pingRing = "ADD",
	rune1 = "ADD",
	rune2 = "ADD",
}

local playerIconsLookup = {}
for k, v in pairs(playerIcons) do
	playerIconsLookup[k] = playerIconNames[k]
end

local defaults = {
	profile = {
		size = 32,
		color = {r = 1, g = 1, b = 1, a = 1},
		texture = "minimapArrow",
		rotationSpeed = 0,
		pulseSpeed = 29,
		pulseSize = 1.6
	}
}

local options = {
	type = "group",
	name = L["Player Icon"],
	args = {
		size = {
			type = "range",
			name = L["Size"],
			min = 5,
			max = 100,
			step = 1,
			bigStep = 1,
			get = function()
				return db.size
			end,
			set = function(info, v)
				db.size = v
				mod:UpdatePlayerDot()
			end
		},
		hue = {
			type = "color",
			name = L["Color"],
			hasAlpha = true,
			get = function()
				local c = db.color or defaults.profile.color
				return c.r, c.g, c.b, c.a
			end,
			set = function(info, r, g, b, a)
				db.color.r = r
				db.color.g = g
				db.color.b = b
				db.color.a = a
				mod:UpdatePlayerDot()
			end
		},
		graphic = {
			type = "select",
			name = L["Icon"],
			values = playerIconsLookup,
			get = function()
				return db.texture
			end,
			set = function(info, v)
				db.texture = v
				mod:UpdatePlayerDot()
			end
		},
		rotationSpeed = {
			type = "range",
			name = L["Rotation Speed"],
			min = -180,
			max = 180,
			step = 1,
			bigStep = 5,
			get = function()
				return db.rotationSpeed
			end,
			set = function(info, v)
				db.rotationSpeed = v
				mod:UpdatePlayerDot()
			end,
			disabled = function() return parent.db.profile.rotateMap end
		},
		pulseSpeed = {
			type = "range",
			name = L["Pulse Speed"],
			min = 0,
			max = 100,
			step = 1,
			bigStep = 5,
			get = function()
				return db.pulseSpeed
			end,
			set = function(info, v)
				db.pulseSpeed = v
				mod:UpdatePlayerDot()
			end
		},
		pulseSize = {
			type = "range",
			name = L["Pulse Size"],
			min = 1.1,
			max = 5,
			step = 0.1,
			bigStep = 0.1,
			get = function()
				return db.pulseSize
			end,
			set = function(info, v)
				db.pulseSize = v
				mod:UpdatePlayerDot()
			end
		}
	}
}

local playerDot

function mod:OnInitialize()
	self.db = parent.db:RegisterNamespace(modName, defaults)
	db = self.db.profile
	parent:RegisterModuleOptions(modName, options, modName)
	
	playerDot = HudMap.canvas:CreateTexture()
	playerDot:SetPoint("CENTER")
	playerDot:SetBlendMode("BLEND")
	playerDot:SetVertexColor(1,1,1,1)
	playerDot:SetDrawLayer("OVERLAY")
	playerDot.animations = playerDot:CreateAnimationGroup()
	playerDot.animations:SetLooping("REPEAT")			
	playerDot.rotate = playerDot.animations:CreateAnimation("rotation")
	playerDot.pulsing = playerDot:CreateAnimationGroup()
	-- playerDot.pulsing:SetLooping("REPEAT")			
	playerDot.pulsing:SetScript("OnFinished", function(self)
		self:Play()
	end)
	playerDot.pulseIn = playerDot.pulsing:CreateAnimation("scale")
	playerDot.pulseOut = playerDot.pulsing:CreateAnimation("scale")
	playerDot.pulseIn:SetOrder(1)
	playerDot.pulseOut:SetOrder(2)
	
	self:UpdatePlayerDot()	
end

function mod:OnEnable()
	db = self.db.profile
	playerDot:Show()
	parent.RegisterCallback(self, "Update", "UpdateRotation")
end

function mod:OnDisable()
	playerDot:Hide()
	parent.UnregisterCallback(self, "Update")
end

function mod:UpdatePlayerDot()
	playerDot:SetTexture(playerIcons[db.texture])
	playerDot:SetSize(db.size, db.size)
	playerDot:SetVertexColor(db.color.r, db.color.g, db.color.b, db.color.a)
	playerDot:SetBlendMode(playerDotBlends[db.texture] or "BLEND")	
	if db.rotationSpeed ~= 0 and parent.db.profile.rotateMap then
		playerDot.rotate:SetDegrees(db.rotationSpeed < 0 and 360 or -360)
		playerDot.rotate:SetDuration(360 / math.abs(db.rotationSpeed))
		playerDot.animations:Play()
	else
		playerDot.animations:Stop()
	end
	
	playerDot.pulseIn:SetScale(db.pulseSize, db.pulseSize)
	playerDot.pulseOut:SetScale(1 / db.pulseSize, 1 / db.pulseSize)
	
	if db.pulseSpeed ~= 0 then
		local pulseTotal= 2
		local speed = (100 - db.pulseSpeed) / 100 * pulseTotal
		playerDot.pulseIn:SetDuration(speed)
		playerDot.pulseOut:SetDuration(speed)
		playerDot.pulsing:Play()
	else
		playerDot.pulsing:Stop()
	end
end

local lastRotation
function mod:UpdateRotation()
	local newRotation
	if parent.db.profile.rotateMap then
		newRotation = 0
	else
		newRotation = GetPlayerFacing()
	end
	if newRotation ~= lastRotation then
		lastRotation = newRotation
		playerDot:SetRotation(newRotation)
	end
end