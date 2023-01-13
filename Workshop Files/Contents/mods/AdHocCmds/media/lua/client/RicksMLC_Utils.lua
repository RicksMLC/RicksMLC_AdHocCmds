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
