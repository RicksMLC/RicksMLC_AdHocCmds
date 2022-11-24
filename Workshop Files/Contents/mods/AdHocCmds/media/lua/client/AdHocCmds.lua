-- Rick's MLC Template
-- TODO:
--		 [ ] Use the radio to report changes caused by "Unusual Unknown Circumstances"
--				Chaos Happens At Times - C.H.A.T. Radio

-- Note: https://projectzomboid.com/modding////index.html
-- Note: https://pzwiki.net/wiki/Category:Lua_Events

require "ISBaseObject"
require "RicksMLC_ChatIO"
require "RicksMLC_Radio"

RicksMLC_AdHocCmds = ISBaseObject:derive("RicksMLC_AdHocCmds");
RicksMLC_AdHocCmdsInstance = nil

local RicksMLC_ModName = "RicksMLC_AdHocCmds"
local RicksMLC_relPath = "./ChatIO/chatInput.txt"
RicksMLC_ChatIO_Instance = RicksMLC_ChatIO:new(RicksMLC_ModName, RicksMLC_relPath)

function RicksMLC_AdHocCmds:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self

	o.isStorming = false

    return o
end

function RicksMLC_AdHocCmds.Instance()
    return RicksMLC_AdHocCmdsInstance
end

local r = {1.0, 0.0,  0.75}
local g = {1.0, 0.75, 0.0}
local b = {1.0, 0.0,  0.0}
local fonts = {UIFont.AutoNormLarge, UIFont.AutoNormMedium, UIFont.AutoNormSmall, UIFont.Handwritten}
function RicksMLC_AdHocCmds:Think(player, thought, colourNum)
	-- colourNum 1 = white, 2 = green, 3 = red
	player:Say(thought, r[colourNum], g[colourNum], b[colourNum], fonts[2], 1, "radio")
end


function RicksMLC_AdHocCmds:StartKateBobIntroStorm(x, y)
	local w = getClimateManager():getWeatherPeriod();
	if w:isRunning() then
		getClimateManager():stopWeatherAndThunder();
	end
	local duration = 20
	local strength = 0.75
	local initialProgress = 6
	local angle = 180
	local initialPuddles = 0.9
	getClimateManager():triggerKateBobIntroStorm(x, y, duration, strength, initialProgress, angle, initialPuddles);
	getClimateManager():getThunderStorm():triggerThunderEvent(x, y, true, true, true)
	--getClimateManager():transmitTriggerTropical(duration)
	--getClimateManager():triggerWinterIsComingStorm()

	local colorWhite = {r = 1.0, g = 1.0, b = 1.0}
	local colorDarkBlue = {r = 0.3, g = 0.5, b = 0.7}
	local lines = { 
		{ RicksMLC_Radio.name, colorWhite },
		{ RicksMLC_Radio.Intro, colorWhite },
		{ "An unknown force is creating havoc in our atmosphere", colorDarkBlue } 
	}
	local bc = RicksMLC_Radio.CreateBroadcast(getGameTime(), lines)
	local radioChannel  = RadioScriptManager.getInstance():getRadioChannel(RicksMLC_Radio.channelUUID)
	radioChannel:setAiringBroadcast(bc);
end

function RicksMLC_AdHocCmds:StopStorm()
	local w = getClimateManager():getWeatherPeriod();
	if w:isRunning() then
		getClimateManager():stopWeatherAndThunder();
		w:stopWeatherPeriod()
	end

	local colorWhite = {r = 1.0, g = 1.0, b = 1.0}
	local colorDarkGreen = {r = 0.3, g = 0.7, b = 0.5}
	local lines = { 
		{ RicksMLC_Radio.name, colorWhite },
		{ RicksMLC_Radio.Intro, colorWhite },
		{ "Folks, the storm has just ... vanished", colorDarkGreen },
		{ "Just another day of reporting on " .. RicksMLC_Radio.name, colorDarkGreen }
	}
	local bc = RicksMLC_Radio.CreateBroadcast(getGameTime(), lines)
	local radioChannel  = RadioScriptManager.getInstance():getRadioChannel(RicksMLC_Radio.channelUUID)
	radioChannel:setAiringBroadcast(bc);

end

function RicksMLC_AdHocCmds:ToggleStorm()
	local w = getClimateManager():getWeatherPeriod();
	if self.isStorming then
		self:StopStorm()
		self.isStorming = false
	else
		self:StartKateBobIntroStorm(getPlayer():getX(), getPlayer():getY())
		self.isStorming = true
	end
end

function RicksMLC_AdHocCmds:Init()
	local w = getClimateManager():getWeatherPeriod();
	self.isStorming = (w:isThunderStorm() or w:isTropicalStorm())
end

---------------------------------------------------------------------------------------
-- Static Methods

function RicksMLC_AdHocCmds.OnKeyPressed(key)
	--DebugLog.log(DebugType.Mod, "RicksMLC_AdHocCmds.OnKeyPressed()")

	if not RicksMLC_AdHocCmdsInstance then return end

	if isAltKeyDown() then
		if key == Keyboard.KEY_F9 then
			RicksMLC_AdHocCmdsInstance:ToggleStorm()
		end
	end
end

function RicksMLC_AdHocCmds.OnCreatePlayer()
    DebugLog.log(DebugType.Mod, "RicksMLC_AdHocCmds.OnCreatePlayer(): ")
	if isServer() then return end

    RicksMLC_AdHocCmdsInstance = RicksMLC_AdHocCmds:new()
	RicksMLC_AdHocCmdsInstance:Init()
	
end

Events.OnCreatePlayer.Add(RicksMLC_AdHocCmds.OnCreatePlayer)
Events.OnKeyPressed.Add(RicksMLC_AdHocCmds.OnKeyPressed)

