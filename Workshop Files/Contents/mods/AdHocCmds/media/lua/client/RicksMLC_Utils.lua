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


-----------------------------------------
-- Spawn Timer - hold a list of RicksMLC_Spawn objects to track for their timers

RicksMLC_SpawnTimer = ISBaseObject:derive("RicksMLC_SpawnTimer")
local RicksMLC_SpawnTimerInstance = nil
function RicksMLC_SpawnTimer.Instance()
	if not RicksMLC_SpawnTimerInstance then
		RicksMLC_SpawnTimerInstance = RicksMLC_SpawnTimer:new()
	end
	return RicksMLC_SpawnTimerInstance
end

function RicksMLC_SpawnTimer:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.isTimerOn = false
    o.elapsedTime = 0

    o.timedObjects = {}
    o.timerEndSeconds = timeoutInSeconds
    o.id = id

    return o
end

function RicksMLC_SpawnTimer:Add(spawnObj)
	self.timedObjects[#self.timedObjects+1] = {spawnObj, 0}
	if not self.isTimerOn then
		self:StartTimer()
	end
end

function RicksMLC_SpawnTimer:HandleUpdateTimer()
	for i, v in ipairs(self.timedObjects) do
		if v[1]:EndTimerCallback(v[2]) then
			self.timedObjects[i] = nil
		else
			self.timedObjects[i][2] = self.timedObjects[i][2] + 1
		end
	end
	if #self.timedObjects == 0 then
		self:CancelTimer()
	end
end

function RicksMLC_SpawnTimer:CancelTimer()
    --DebugLog.log(DebugType.Mod, "RicksMLC_Timer:CancelTimer()")
    self.isTimerOn = false
	Events.OnTick.Remove(RicksMLC_SpawnTimer.UpdateTimer)
end

function RicksMLC_SpawnTimer:StartTimer()
	if (not self.isTimerOn) then
		self.isTimerOn = true
		self.elapsedTime = 0
		Events.OnTick.Add(RicksMLC_SpawnTimer.UpdateTimer)
		--DebugLog.log(DebugType.Mod, "RicksMLC_SpawnTimer:StartTimer() added UpdateTimer")
	end
end

function RicksMLC_SpawnTimer.UpdateTimer()
	RicksMLC_SpawnTimer.Instance():HandleUpdateTimer()
end
----------------------------------------