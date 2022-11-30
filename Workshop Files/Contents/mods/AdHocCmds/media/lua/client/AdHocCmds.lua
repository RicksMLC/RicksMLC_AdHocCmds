-- Rick's MLC Template
-- TODO:
--		 [ ] Use the radio to report changes caused by "Unusual Unknown Circumstances"
--				Chaos Happens At Times - C.H.A.T. Radio

-- Note: https://projectzomboid.com/modding/index.html
-- Note: https://pzwiki.net/wiki/Category:Lua_Events
-- Touchportal

require "ISBaseObject"
require "RicksMLC_ChatIO"
require "RicksMLC_Radio"

RicksMLC_AdHocCmds = ISBaseObject:derive("RicksMLC_AdHocCmds");
RicksMLC_AdHocCmdsInstance = nil

local RicksMLC_ModName = "RicksMLC_AdHocCmds"
local ZomboidPath = "./ChatIO/"
local RicksMLC_CtrlFilePath = ZomboidPath .. "chatInput.txt"

function RicksMLC_AdHocCmds:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self

	o.ChatIO_CtrlFile = nil

	o.weather = nil
	o.radioScriptsImmediate = {}
	o.radioScriptsHourly = {}

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
	-- FIXME: Move these to the scheduled weather script
	--getClimateManager():transmitTriggerTropical(duration)
	--getClimateManager():triggerWinterIsComingStorm()

	local colorWhite = {r = 1.0, g = 1.0, b = 1.0}
	local colorDarkBlue = {r = 0.3, g = 0.5, b = 0.7}
	local lines = { 
		{ RicksMLC_Radio.name, colorWhite },
		{ RicksMLC_Radio.Intro, colorWhite },
		{ "An unknown force is creating havoc in our atmosphere", colorDarkBlue } 
	}
	RicksMLC_Radio.BroadcastImmediate(lines)
end

function RicksMLC_AdHocCmds:StopStorm()
	self.isStorming = false
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
	RicksMLC_Radio.BroadcastImmediate(lines)
end


function RicksMLC_AdHocCmds:StartStorm()
	self:StartKateBobIntroStorm(getPlayer():getX(), getPlayer():getY())
	self.isStorming = true
end

function RicksMLC_AdHocCmds:ToggleStorm()
	if self.isStorming then
		self:StopStorm()
	else
		self:StartStorm()
	end
end

function RicksMLC_AdHocCmds:DumpChatIOFiles()
	for k, v in pairs(self.ChatIO_CtrlFile.contentList) do
		DebugLog.log(DebugType.Mod, "  " .. k .. " " .. v )
	end
end

function RicksMLC_AdHocCmds:LoadChatIOFiles(isForceReadAll)
	--DebugLog.log(DebugType.Mod, "RicksMLC_AdHocCmds:LoadChatIOFiles() " .. RicksMLC_CtrlFilePath )
	self.ChatIO_CtrlFile = RicksMLC_ChatIO:new(RicksMLC_ModName, RicksMLC_CtrlFilePath)
	self.ChatIO_CtrlFile:Load("=", isForceReadAll)
	self.ChatIO_CtrlFile:Save("=", true)

	local chatFiles = {}
	for k, v in pairs(self.ChatIO_CtrlFile.contentList) do
		chatFiles[k] = v
	end
	for filename, schedule in pairs(chatFiles) do
		local chatScriptFile = RicksMLC_ChatIO:new(RicksMLC_ModName, ZomboidPath .. filename)
		-- TODO: Add test for misspelt chat file name in chatInput.txt EG: WASDCtrl.txt
		self:ScriptFactory(chatScriptFile, schedule, filename)
	end
end

function RicksMLC_AdHocCmds:ScriptFactory(chatScriptFile, schedule, filename)
	--DebugLog.log(DebugType.Mod, "RicksMLC_AdHocCmds:ScriptFactory()")
	chatScriptFile:Load("=", false)
	local scriptType = chatScriptFile.contentList["type"]
	
	if scriptType == "radioscript" then
		-- Assign to its schedule or immediate
		if schedule == "immediate" then
			-- TODO: Schedule?
			--self.radioScriptsImmediate[filename] = radioScript
			local radioScript = RicksMLC_ChatScriptFile:new()
			radioScript:AddLines(chatScriptFile.contentList)
			radioScript:Broadcast()
		elseif schedule == "hourly" then
			local radioScript = RicksMLC_HourlyScriptFile:new()
			radioScript:AddLines(chatScriptFile.contentList)
			self.radioScriptsHourly[filename] = radioScript
		else
			DebugLog.log(DebugType.Mod, "RicksMLC_AdHocCmds:ScriptFactory() Error: " .. filename .. ": unknown schedule '" .. schedule .. "'")
		end
	elseif scriptType == "weather" then
		-- Create the new weather ctrl object to initiate
		local wScript = RicksMLC_WeatherScript:new()
		wScript:AddLines(chatScriptFile.contentList)
		wScript:UpdateValues(chatScriptFile.contentList)
		self.weather = wScript
		--DebugLog.log(DebugType.Mod, "RicksMLC_AdHocCmds:ScriptFactory() TEST BROADCAST IMMEDIATE")
		-- TODO: Schedule. Just broadcast it for now as a test
		--self.weather:Broadcast()
	end
end

function RicksMLC_AdHocCmds:HandleEveryTenMinutes()
	self:LoadChatIOFiles(false)
end

function RicksMLC_AdHocCmds:HandleEveryHours()
	for filename, radioScript in pairs(self.radioScriptsHourly) do
		radioScript:Broadcast()
	end
end

function RicksMLC_AdHocCmds:Init()
	--DebugLog.log(DebugType.Mod, "RicksMLC_AdHocCmds:Init()")

	local w = getClimateManager():getWeatherPeriod();
	self.isStorming = (w:isThunderStorm() or w:isTropicalStorm())
	self:LoadChatIOFiles(false)
end

function RicksMLC_AdHocCmds:MadWeather()
	--DebugLog.log(DebugType.Mod, "RicksMLC_AdHocCmds:MadWeather()")
	if not self.weather or self.weather.weatherType ~= "madness" then return end

	--DebugLog.log(DebugType.Mod, "RicksMLC_AdHocCmds:MadWeather(): ")
	if getPlayer():isOutside() then
		if not self.isStorming then 
			self:StartStorm()
		end
	else
		if self.isStorming then
			self:StopStorm()
		end
	end
end

---------------------------------------------------------------------------------------
RicksMLC_ChatScriptFile = ISBaseObject:derive("RicksMLC_ChatScriptFile");
function RicksMLC_ChatScriptFile:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self

	o.filePath = nil		-- FIXME: Do I need this here?
	o.updatePeriod = nil 	-- FIXME: Do I need this here?
	o.lines = {}
	o.lastUpdateTime = nil	-- FIXME: Do I need this here?

    return o
end

function RicksMLC_ChatScriptFile:AddLines(contentList)
	local i = 1
	local line = contentList["line" .. i]
	while line do
		local colorName = contentList["line" .. i .. "color"]
		local color = RicksMLC_Radio.GetColor(colorName)
		table.insert(self.lines, {line, color})
		i = i + 1
		line = contentList["line" .. i]
	end
end

function RicksMLC_ChatScriptFile:Broadcast()
	RicksMLC_Radio.BroadcastImmediate(self.lines)
end

---------------------------------------------------------------------------------

RicksMLC_HourlyScriptFile = RicksMLC_ChatScriptFile:derive("RicksMLC_HourlyScriptFile")
function RicksMLC_HourlyScriptFile:new()
	local o = RicksMLC_ChatScriptFile.new(self)
	setmetatable(o, self)
	self.__index = self

	return o
end

function RicksMLC_HourlyScriptFile:Broadcast()
	RicksMLC_Radio.BroadcastImmediate(self.lines)
	--FIXME: Should add so it queues with other added broadcasts
	--RicksMLC_Radio.AddBroadcast(self.lines)
end

----------------------------------------------------------------------------------

RicksMLC_WeatherScript = RicksMLC_ChatScriptFile:derive("RicksMLC_WeatherScript")
function RicksMLC_WeatherScript:new()
	local o = RicksMLC_ChatScriptFile:new()
	setmetatable(o, self)
	self.__index = self

	-- Default values:
	o.weatherType = "KateBobIntro" -- Types: tropical thunder blizzard KateBobIntro (madness?)
	o.duration = 20
	o.strength = 0.75
	o.initialProgress = 4
	o.angle = 180
	o.initialPuddles = 0.9

	o.inGameStartTime = 0
	return o
end

function RicksMLC_WeatherScript:UpdateValues(contentList)
	self.weatherType = contentList["weatherType"] or self.weatherType
	self.duration = contentList["duration"] or self.duration
	self.strength = contentList["strength"] or self.strength
	self.initialProgress = contentList["initialProgress"] or self.initialProgress
	self.angle = contentList["angle"] or self.angle
	self.initialPuddles = contentList["initialPuddles"] or self.initialPuddles
end

---------------------------------------------------------------------------------------
-- Static Methods

function RicksMLC_AdHocCmds.EveryHours()
	if not RicksMLC_AdHocCmdsInstance then return end

	RicksMLC_AdHocCmdsInstance:HandleEveryHours()
end

function RicksMLC_AdHocCmds.EveryTenMinutes()
	if not RicksMLC_AdHocCmdsInstance then return end

	RicksMLC_AdHocCmdsInstance:HandleEveryTenMinutes()
end

function RicksMLC_AdHocCmds.EveryOneMinute()
	if not RicksMLC_AdHocCmdsInstance then return end
	--DebugLog.log(DebugType.Mod, "RicksMLC_AdHocCmds.EveryOneMinute()")
	RicksMLC_AdHocCmdsInstance:MadWeather()

end

function RicksMLC_AdHocCmds.OnKeyPressed(key)
	--DebugLog.log(DebugType.Mod, "RicksMLC_AdHocCmds.OnKeyPressed()")

	if not RicksMLC_AdHocCmdsInstance then return end

	--if isAltKeyDown() then
		if key == Keyboard.KEY_F9 then
			RicksMLC_AdHocCmdsInstance:ToggleStorm()
		elseif key == Keyboard.KEY_F10 then
			-- Forces load of all chatInput.txt file
			RicksMLC_AdHocCmdsInstance:LoadChatIOFiles(false)
		end
	--end
end

function RicksMLC_AdHocCmds.OnCreatePlayer()
    DebugLog.log(DebugType.Mod, "RicksMLC_AdHocCmds.OnCreatePlayer(): ")
	if isServer() then return end

    RicksMLC_AdHocCmdsInstance = RicksMLC_AdHocCmds:new()
	RicksMLC_AdHocCmdsInstance:Init()
end

Events.OnCreatePlayer.Add(RicksMLC_AdHocCmds.OnCreatePlayer)
Events.OnKeyPressed.Add(RicksMLC_AdHocCmds.OnKeyPressed)
Events.EveryOneMinute.Add(RicksMLC_AdHocCmds.EveryOneMinute)
Events.EveryTenMinutes.Add(RicksMLC_AdHocCmds.EveryTenMinutes)
Events.EveryHours.Add(RicksMLC_AdHocCmds.EveryHours)

