-- Rick's MLC AdHocCmds - Twitch streaming interface if you have TouchPortal or something like that
-- TODO:
-- 		[ ] RicksMLC_SpawnUI.lua: Show all safe houses, and checkbox for "show my safehouse"
--		[ ] Add a designator for the Chat so we know which zombies are from what streamer
--		[ ] Add post-death notice with Chat as well as Chatter caused the death.
--		[ ] Keep a score for each player Kills/Killed By
--		[ ] Make a UI for the score.
--		[ ] Output the score to a ChatIO file so the streamrs can use it.
--
--
-- Note: https://projectzomboid.com/modding/index.html
-- Note: https://pzwiki.net/wiki/Category:Lua_Events
-- Touchportal

require "ISBaseObject"
require "RicksMLC_ChatIO"
require "RicksMLC_Radio"
require "RicksMLC_ChatSupply"
require "RicksMLC_Flies"
require "RicksMLC_PowerGrid"
require "RicksMLC_TreasureHuntMgr"
require "RicksMLC_ChatTreasure"
require "RicksMLC_Vehicle"

RicksMLC_AdHocCmds = ISBaseObject:derive("RicksMLC_AdHocCmds");
RicksMLC_AdHocCmdsInstance = nil

local RicksMLC_ModName = "\\RicksMLC_AdHocCmds"
function RicksMLC_AdHocCmds.GetModName() return RicksMLC_ModName end

local ZomboidPath = "./ChatIO/"
function RicksMLC_AdHocCmds.GetZomboidPath() return ZomboidPath end

local RicksMLC_CtrlFilePath = ZomboidPath .. "chatInput.txt"
local RicksMLC_CtrlBootFilePath = ZomboidPath .. "boot.txt"

function RicksMLC_AdHocCmds:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self

	o.ChatIO_CtrlFile = nil

	o.weather = nil
	o.radioScriptsImmediate = {}
	o.radioScriptsHourly = {}

	o.isStorming = false

	o.skipFirstTen = true -- Skip the first 10 minute timer to prevent early spawns

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

function RicksMLC_AdHocCmds:DumpChatIOFiles()
	for k, v in pairs(self.ChatIO_CtrlFile.contentList) do
		DebugLog.log(DebugType.Mod, "  " .. k .. " " .. v )
	end
end

function RicksMLC_AdHocCmds:LoadChatIOFiles(isForceReadAll, ctrlFilePath)
	--DebugLog.log(DebugType.Mod, "RicksMLC_AdHocCmds:LoadChatIOFiles() " .. RicksMLC_CtrlFilePath )
	self.ChatIO_CtrlFile = RicksMLC_ChatIO:new(RicksMLC_ModName, ctrlFilePath)
	self.ChatIO_CtrlFile:Load("=", isForceReadAll) 	-- Read the list of chat files to read

	-- Load each file from the control file and perform their commands
	local chatFiles = {}
	for k, v in pairs(self.ChatIO_CtrlFile.contentList) do
		chatFiles[k] = v
	end
	local isApplied = false
	for filename, schedule in pairs(chatFiles) do
		local chatScriptFile = RicksMLC_ChatIO:new(RicksMLC_ModName, ZomboidPath .. filename)
		-- TODO: Add test for misspelt chat file name in chatInput.txt EG: WASDCtrl.txt
		isApplied = self:ScriptFactory(chatScriptFile, schedule, filename) or isApplied
	end

	-- If any chatfiles were applied update the control file to comment out the exected files.
	if isApplied then
		if ctrlFilePath ~= RicksMLC_CtrlBootFilePath then
			self.ChatIO_CtrlFile:Save("=", true)			-- Comment out the control file contents 
		end
	end
end

function RicksMLC_AdHocCmds:ScriptFactory(chatScriptFile, schedule, filename)
	--DebugLog.log(DebugType.Mod, "RicksMLC_AdHocCmds:ScriptFactory()")
	chatScriptFile:Load("=", false)
	local scriptType = chatScriptFile.contentList["type"]

	--DebugLog.log(DebugType.Mod, "RicksMLC_AdHocCmds:ScriptFactory()" .. scriptType)

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
		return true
	elseif scriptType == "weather" then
		-- Create the new weather ctrl object to initiate
		local wScript = RicksMLC_WeatherScript:new()
		wScript:AddLines(chatScriptFile.contentList)
		wScript:UpdateValues(chatScriptFile.contentList)
		self.weather = wScript
		return true
		--DebugLog.log(DebugType.Mod, "RicksMLC_AdHocCmds:ScriptFactory() TEST BROADCAST IMMEDIATE")
		-- TODO: Schedule. Just broadcast it for now as a test
		--self.weather:Broadcast()
	elseif scriptType == "spawn" then
		local spawnScript = RicksMLC_Spawn:new(chatScriptFile)
		spawnScript:Spawn(chatScriptFile.contentList)
		spawnScript:AddLines(chatScriptFile.contentList)
		spawnScript:Broadcast()
		return true
	elseif scriptType == "vendingconfig" then
		if isClient() then
			sendClientCommand("RicksMLC_AdHocCmdsServer", "UpdateVendingConfig", {configfile = chatScriptFile})
		else
			RicksMLC_VendingMachineConfig.Instance():Update(chatScriptFile)
		end
		return true
	elseif scriptType == "chatsupplyconfig" then
		RicksMLC_ChatSupplyConfig.Instance():Update(chatScriptFile)
		return true
	elseif scriptType == "chatsupply" then
		local supplyScript = RicksMLC_ChatSupply:new(chatScriptFile)
		supplyScript:Supply()
		return true
	elseif scriptType == "alarm" then
		RicksMLC_Alarms.TriggerAlarm()
		return true
	elseif scriptType == "toggleflies" then
		if RicksMLC_Flies then
			if isClient() then
				RicksMLC_ChatFliesClient.SendSetFlies(not RicksMLC_Flies.IsEnabled())
			else
				RicksMLC_Flies.ToggleFlies()
			end
		end
		return true
	elseif scriptType == "powerGrid" then
		if chatScriptFile.contentList["action"] == "BrownOut" then
			RicksMLC_PowerGrid.Instance():BrownOut(chatScriptFile.contentList["minutes"])
		else
			RicksMLC_PowerGrid.Instance():TogglePower(tonumber(chatScriptFile.contentList["restoreDays"]))
		end
		return true
	elseif scriptType == "treasureHunt" then
		if RicksMLC_TreasureHuntMgr then
			RicksMLC_ChatTreasure.Instance():AddTreasureHunt(chatScriptFile.contentList)
		end
		return true
	elseif scriptType == "lostTreasureMap" then
		if RicksMLC_TreasureHuntMgr then
			RicksMLC_ChatTreasure.Instance():ResetLostMaps()
		end
		return true
	elseif scriptType == "vehicle" then
		RicksMLC_Vehicle.ProcessCommand(chatScriptFile)
		return true
	end
	return false
end

function RicksMLC_AdHocCmds:HandleEveryTenMinutes()
	if self.skipFirstTen then
		self.skipFirstTen = false
		return
	end

	self:LoadChatIOFiles(false, RicksMLC_CtrlFilePath)
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
	self:LoadChatIOFiles(false, RicksMLC_CtrlBootFilePath)
end


------------------------
-- Weather controls - should move to its own module

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

function RicksMLC_AdHocCmds:WeatherTriggers()
	-- FIXME: This is copied from the debugger UI: adjust as appropriate:
	if _button.customData == "StopWeather" then
		if isClient() then
			getClimateManager():transmitStopWeather();
		else
			getClimateManager():stopWeatherAndThunder()
		end
	elseif _button.customData == "TriggerStorm" then
		local dur = self.sliderDurationSlider:getCurrentValue();
		if isClient() then
			getClimateManager():transmitTriggerStorm(dur);
		else
			getClimateManager():triggerCustomWeatherStage(WeatherPeriod.STAGE_STORM,dur);
		end
	elseif _button.customData == "TriggerTropical" then
		local dur = self.sliderDurationSlider:getCurrentValue();
		if isClient() then
			getClimateManager():transmitTriggerTropical(dur);
		else
			getClimateManager():triggerCustomWeatherStage(WeatherPeriod.STAGE_TROPICAL_STORM,dur);
		end
	elseif _button.customData == "TriggerBlizzard" then
		local dur = self.sliderDurationSlider:getCurrentValue();
		if isClient() then
			getClimateManager():transmitTriggerBlizzard(dur);
		else
			getClimateManager():triggerCustomWeatherStage(WeatherPeriod.STAGE_BLIZZARD,dur);
		end
	end
end


---------------------------------------------------------------------------------------
RicksMLC_ChatScriptFile = ISBaseObject:derive("RicksMLC_ChatScriptFile");
function RicksMLC_ChatScriptFile:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self

	o.lines = {}

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

local skipFirst = true
local userSentToServer = false
function RicksMLC_AdHocCmds.EveryTenMinutes()
	if not RicksMLC_AdHocCmdsInstance then return end

	RicksMLC_AdHocCmdsInstance:HandleEveryTenMinutes()

	-- Inform the server that this client is here... so the server can update its usename list
	if isClient() then
		if skipFirst then skipFirst = false return end
	 	if not userSentToServer then
			RicksMLC_AdHocCmds.OnUserUpdate()
			userSentToServer = true
		end
	end
end

function RicksMLC_AdHocCmds.EveryOneMinute()
	if not RicksMLC_AdHocCmdsInstance then return end

	RicksMLC_AdHocCmdsInstance:MadWeather()
end

function RicksMLC_AdHocCmds.OnKeyPressed(key)

	if not RicksMLC_AdHocCmdsInstance then return end

	-- FIXME: Remove so it triggers immediate.
	-- if isClient() and not isCoopHost() then return end -- Prevent non hosts from sending updates to the server

	--if isAltKeyDown() then
		if key == Keyboard.KEY_F9 then
			RicksMLC_AdHocCmdsInstance:ToggleStorm()
		elseif key == Keyboard.KEY_F19 then
			-- Forces load of all chatInput.txt file
			--local startTime = getTimeInMillis()
			-- if isServer() then
			-- 	DebugLog.log(DebugType.Mod, " RicksMLC_AdHocCmds.OnKeyPressed server")
			-- elseif isClient() then
			-- 	DebugLog.log(DebugType.Mod, " RicksMLC_AdHocCmds.OnKeyPressed client")
			-- else
			-- 	DebugLog.log(DebugType.Mod, " RicksMLC_AdHocCmds.OnKeyPressed stand-alone")
			-- end
			RicksMLC_AdHocCmdsInstance:LoadChatIOFiles(false, RicksMLC_CtrlFilePath)
			--local endTime = getTimeInMillis()
    		--DebugLog.log(DebugType.Mod, " RicksMLC_AdHocCmds.OnKeyPressed Time: " .. tostring(endTime - startTime) .. "ms")
		end
	--end
end

function RicksMLC_AdHocCmds.OnServerCommand(module, command, args)
	--DebugLog.log(DebugType.Mod, "RicksMLC_AdHocCmds.OnServerCommand() module: " .. tostring(module) .. " command: " .. tostring(command) )
	if module == "RicksMLC_AdHocCmdsServer" then
		if command == "UpdateVendingConfig" then
			RicksMLC_VendingMachineConfig.Instance():Update(args.configfile)
		end
	end
end

function RicksMLC_AdHocCmds.OnGameStart()
    DebugLog.log(DebugType.Mod, "RicksMLC_AdHocCmds.OnGameStart(): ")
	if isServer() then 
		DebugLog.log(DebugType.Mod, "RicksMLC_AdHocCmds.OnGameStart(): isServer() == true")
		return
	end
	if isClient() then
		DebugLog.log(DebugType.Mod, "RicksMLC_AdHocCmds.OnGameStart(): isClient() == true")
	end

	RicksMLC_Spawn.Init()
	RicksMLC_PostDeath.Init()
    RicksMLC_AdHocCmdsInstance = RicksMLC_AdHocCmds:new()
	RicksMLC_AdHocCmdsInstance:Init() -- This also inits the ChatSupply and Vending from the boot.txt config files.
	RicksMLC_Radio.Init()
	if RicksMLC_ChatTreasure then
		RicksMLC_ChatTreasure.Instance():Init()
	end

	Events.OnKeyPressed.Add(RicksMLC_AdHocCmds.OnKeyPressed)
	Events.EveryOneMinute.Add(RicksMLC_AdHocCmds.EveryOneMinute)
	Events.EveryTenMinutes.Add(RicksMLC_AdHocCmds.EveryTenMinutes)
	Events.EveryHours.Add(RicksMLC_AdHocCmds.EveryHours)
	Events.OnServerCommand.Add(RicksMLC_AdHocCmds.OnServerCommand)
end

Events.OnGameStart.Add(RicksMLC_AdHocCmds.OnGameStart)

----------------------------------------------------------------

function RicksMLC_AdHocCmds.OnUserUpdate()
	--DebugLog.log(DebugType.Mod, "RicksMLC_AdHocCmds.OnUserUpdate()")
	local args = { isCoopHost = isCoopHost() }
    sendClientCommand(getPlayer(), 'RicksMLC_ServerCmds', 'PlayerConnectionUpdate', args)
end

Events.OnConnected.Add(RicksMLC_AdHocCmds.OnUserUpdate)
Events.OnDisconnect.Add(RicksMLC_AdHocCmds.OnUserUpdate)
