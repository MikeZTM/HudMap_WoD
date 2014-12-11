-- Ping module, by Adirelle (adirelle@tagada-team.net)

local modName = "Compass"

local parent = HudMap
local L = LibStub("AceLocale-3.0"):GetLocale("HudMap")
local mod = HudMap:NewModule(modName, "AceEvent-3.0")

local options = {
	type = "group",
	name = L["Compass"],
	args = {
		color = {
			type = "color",
			name = L["Color"],
			hasAlpha = true,
			get = function()
				return unpack(mod.db.profile.color)
			end,
			set = function(info, ...)
				local c = mod.db.profile.color
				c[1], c[2], c[3], c[4] = ...
				mod:Update()
			end,
			order = 21,
		},
		size = {
			type = "range",
			name = L["Size (yards)"],
			min = 10,
			max = 50,
			step = 1,
			bigStep = 1,
			get = function()
				return mod.db.profile.size
			end,
			set = function(info, v)
				mod.db.profile.size = v
			end,
			order = 22,
		},
	}
}

local defaults = {
	profile = {
		color = { 0, 0.6, 0, 0.5 },
		size = 30,
	}
}

local NUM_MARKS = 8

function mod:OnInitialize()
	self.defaultState = "disabled"
	self.db = parent.db:RegisterNamespace(modName, defaults)
	parent:RegisterModuleOptions(modName, options, modName)

	local frame = CreateFrame("Frame", nil, parent.canvas)
	frame:SetAllPoints(parent.canvas)
	frame:Hide()

	local marks = {}
	for index = 1, NUM_MARKS do
		local mark = frame:CreateTexture(nil, "BORDER")
		local size = (index == 1 and 24) or (index % 2 == 1 and 16) or 10
		mark.offset = size * 0.25
		mark.theta = math.pi * 2 * (index - 1) / NUM_MARKS
		mark:SetWidth(size)
		mark:SetHeight(size)
		mark:SetTexture([[Interface\AddOns\HudMap\assets\compass_mark]])
		mark:SetVertTile(false)
		mark:SetHorizTile(false)
		tinsert(marks, mark)
	end

	self.frame, self.marks = frame, marks
end

function mod:OnEnable()
	self:Update()
	self.frame:Show()
	parent.RegisterCallback(self, 'Update', 'UpdateCompass')
end

function mod:OnDisable()
	parent.UnregisterAllCallbacks(self)
	self.frame:Hide()
end

local quarter = 0.5 * math.pi
local cos, sin = math.cos, math.sin

function mod:UpdateCompass()
	local mapSize = parent:GetMinimapSize()
	local compassSize = self.db.profile.size
	if compassSize > mapSize then
		scale = 1.0 + 0.2 * (compassSize / mapSize)
	else
		scale = 0.2 + 0.8 * compassSize / mapSize
	end
	self.frame:SetScale(scale)
	local radius = math.min(compassSize, mapSize) * parent.db.profile.maxSize / mapSize
	local angle = parent.db.profile.rotateMap and (quarter - GetPlayerFacing()) or 0
	for index, mark in pairs(self.marks) do
		local markAngle = angle + mark.theta
		local markRadius = (radius / scale) - mark.offset
		mark:SetPoint("CENTER", markRadius * cos(markAngle), markRadius * sin(markAngle))
		mark:SetRotation(markAngle - quarter)
	end
end

function mod:Update()
	local r, g, b, a = unpack(mod.db.profile.color)
	for index, mark in pairs(self.marks) do
		mark:SetVertexColor(r, g, b, a)
	end
end
