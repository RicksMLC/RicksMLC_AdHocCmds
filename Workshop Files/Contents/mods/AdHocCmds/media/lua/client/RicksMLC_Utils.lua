-- RicksMLC_Utils.lua
-- Sundry small general purpose utils

RicksMLC_Utils = {}
function RicksMLC_Utils.SplitStr(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		table.insert(t, str)
	end
	return t
end

local r = {1.0, 0.0,  0.75}
local g = {1.0, 0.75, 0.0}
local b = {1.0, 0.0,  0.0}
local fonts = {UIFont.AutoNormLarge, UIFont.AutoNormMedium, UIFont.AutoNormSmall, UIFont.Handwritten}
function RicksMLC_Utils.Think(player, thought, colourNum)
	-- colourNum 1 = white, 2 = green, 3 = red
	player:Say(thought, r[colourNum], g[colourNum], b[colourNum], fonts[2], 1, "radio")
    --player:setHaloNote(thought, r[colourNum], g[colourNum], b[colourNum], 150)
end