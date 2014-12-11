-- This file is script-generated and should not be manually edited. 
-- Localizers may copy this file to edit as necessary. 
local AceLocale = LibStub:GetLibrary("AceLocale-3.0") 
local L = AceLocale:NewLocale("HudMap", "enUS", true) 
if not L then return end 
 
-- ./HudMap.lua
L["None"] = true
L["Outline"] = true
L["Thick Outline"] = true
L["HudMap"] = true
L["Zoom In"] = true
L["Zoom Out"] = true
L["Toggle HudMap"] = true
L["General"] = true
L["Adaptive Zoom"] = true
L["Interest Radius"] = true
L["Minimum Radius"] = true
L["Static Zoom"] = true
L["Fixed Zoom"] = true
L["Labels"] = true
L["Show Labels"] = true
L["Font"] = true
L["Font size"] = true
L["Font Outline"] = true
L["Font outlining"] = true
L["General Options"] = true
L["Mode"] = true
L["HUD"] = true
L["Minimap"] = true
L["Enable Minimap Button"] = true
L["Set Visible Area"] = true
L["Reset Visible Area"] = true
L["Rotate Map"] = true
L["Rotates the map around you as you move."] = true
L["Use Adaptive Zoom"] = true
L["Master Opacity"] = true
L["Toggle Binding"] = true
L["Clip Far Objects"] = true
L["Hide objects that are outside of your zoom level or interest radius"] = true
L["Include Radius For Clip"] = true
L["When checked, objects whose radius falls outside the zoom level will be hidden. When unchecked, objects whose center falls outside the zoom level will be hidden."] = true
L["Auto hide"] = true
L["Hide when there are no other active HUD objects."] = true
L["Modules"] = true
L["Border & Background"] = true
L["Background"] = true
L["Background Color"] = true
L["Border"] = true
L["Border Color"] = true
L["Insets"] = true
L["Show when..."] = true
L["Anywhere"] = true
L["Battlegrounds"] = true
L["5-man Instance"] = true
L["Raid Instance"] = true
L["Left Click"] = true
L["Right Click"] = true
L["Configure"] = true
L["Ctrl-Right Click"] = true
L["Move HudMap"] = true
L["Middle Click"] = true
L["Debug Mode"] = true
L["Profiles"] = true
L["The Frozen Throne"] = true

-- ./modules/aoeHealing.lua
L["AOE Healing"] = true
L["Spells"] = true
L["Spark"] = true
L["Dots"] = true
L["Large Dots"] = true
L["Solid"] = true
L["Ring 2"] = true
L["Ring 3"] = true
L["Glow"] = true
L["Enable"] = true
L["Texture"] = true
L["Color"] = true
L["Size"] = true

-- ./modules/battlegrounds.lua
L["Alterac Valley"] = true
L["Mines"] = true
L["Graveyards"] = true
L["Live Towers"] = true
L["Destroyed Towers"] = true
L["Warsong Gulch"] = true
L["Flag Carrier"] = true
L["was picked up by (.+)!"] = true
L["was dropped"] = true
L["captured the"] = true
L["Arathi Basin"] = true
L["Gold Mine"] = true
L["Lumber Mill"] = true
L["Blacksmith"] = true
L["Farm"] = true
L["Stables"] = true
L["Isle of Conquest"] = true
L["Workshop"] = true
L["Hangar"] = true
L["Docks"] = true
L["Refinery"] = true
L["Quarry"] = true
L["Eye of the Storm"] = true
L["Towers"] = true
L["(.+) has taken the flag"] = true
L["has been dropped"] = true
L["Strand of the Ancients"] = true
L["Live Gates"] = true
L["Assaulted Gates"] = true
L["Dead Gates"] = true
L["Show POI Labels"] = true
L["Points of Interest"] = true

-- ./modules/compass.lua
L["Compass"] = true
L["Size (yards)"] = true

-- ./modules/encounters.lua
L["Encounters"] = true
L["Zones"] = true

-- ./modules/example.lua
L["My Module"] = true

-- ./modules/party.lua
L["Party & Raid"] = true
L["Show Spell Targets"] = true
L["Dot Size"] = true
L["Target"] = true
L["Target Name"] = true
L["Highlight Target"] = true
L["Highlight Mouseover"] = true
L["Arrow To Target"] = true
L["Target Arrow Color"] = true
L["Health Bars"] = true
L["Show Health Bars"] = true
L["Hide When Full"] = true
L["Hide When Empty"] = true
L["Width"] = true
L["Height"] = true
L["Edge Size"] = true
L["Inset"] = true
L["X Offset"] = true
L["Y Offset"] = true
L["Background Opacity"] = true

-- ./modules/ping.lua
L["Ping"] = true
L["Display arrow"] = true
L["Display pinger name"] = true

-- ./modules/playerDot.lua
L["Minimap Arrow"] = true
L["Corners"] = true
L["Metal Ring"] = true
L["Glowing Ring"] = true
L["Crosshairs"] = true
L["Ping Ring"] = true
L["Silver Arrow"] = true
L["Gold Arrow"] = true
L["Rune 1"] = true
L["Rune 2"] = true
L["Glowing Dot"] = true
L["Player Icon"] = true
L["Icon"] = true
L["Rotation Speed"] = true
L["Pulse Speed"] = true
L["Pulse Size"] = true

-- ./modules/ranges.lua
L["Range Markers"] = true
L["Add Marker"] = true
L["New Marker"] = true
L["Rune 3"] = true
L["Rune 4"] = true
L["Highlight"] = true
L["Clock"] = true
L["Circle"] = true
L["Faded Circle"] = true
L["Reticle"] = true
L["Range (yards)"] = true
L["Rotate Speed"] = true
L["Delete Marker"] = true
L["Delete this marker?"] = true
L["Name"] = true

-- ./modules/totems.lua
L["Totems"] = true
L["My Totems"] = true
L["Enable My Totems"] = true
L["Party Totems"] = true
L["Enable Party Totems"] = true
L["Fire Nova"] = true
L["Show Fire Nova Range"] = true
L["Ring Style"] = true
L["Fire Totems"] = true
L["Earth Totems"] = true
L["Water Totems"] = true
L["Air Totems"] = true
L["%s Color"] = true

-- ./modules/tracking.lua
L["Tracking"] = true
L["Enable Gathering Mode"] = true
L["GatherMate is a resource gathering helper mod. Installing it allows you to have resource pins on your HudMap."] = true
L["Use GatherMate pins"] = true
L["Use QuestHelper pins"] = true
L["Routes plots the shortest distance between resource nodes. Install it to show farming routes on your HudMap."] = true
L["Use Routes"] = true

-- ./modules/zones/icecrown.lua
L["Marrowgar"] = true
L["Bone Spike Radius"] = true
L["Lady Deathwhisper"] = true
L["Festergut"] = true
L["Rotface"] = true
L["Splash Zones"] = true
L["Infection Arrow"] = true
L["Professor Putricide"] = true
L["All Malleable Goo Positions"] = true
L["Blood Council"] = true
L["Prince Arrow"] = true
L["Fire Arrow"] = true
L["Empowered Flames speed toward (%S+)!"] = true
L["Blood Queen Lana'thel"] = true
L["Sindragosa"] = true
L["Automatic Ice Tomb Positions"] = true
L["The Lich King"] = true
L["Icecrown Citadel"] = true

-- ./modules/zones/sanctum.lua
L["Halion"] = true
L["Orb Speed"] = true
L["Orb Offset"] = true
L["The orbiting spheres pulse with dark energy!"] = true
L["Your world teeters on the brink of annihilation. You will ALL bear witness to the coming of a new age of DESTRUCTION!"] = true
L["You will find only suffering within the realm of twilight! Enter if you dare!"] = true
L["Ruby Sanctum"] = true

-- ./modules/zones/tourney.lua
L["Northrend Beasts"] = true
L["Charge Warning"] = true
L["Lord Jaraxxus"] = true
L["Tournament"] = true

-- ./modules/zones/ulduar.lua
L["XT-002 Deconstructor"] = true
L["Hodir"] = true
L["Freya"] = true
L["General Vexaz"] = true
L["Yogg-Saron"] = true
L["Ulduar"] = true

-- ./modules/zones/warsong.lua
-- no localization

