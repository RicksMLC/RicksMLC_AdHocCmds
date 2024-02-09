-- Rick's MLC Radio
-- Note: These are copied from ISWeatherChannel.lua

---------------------------------------------------------------------------------

RicksMLC_Radio = ISBaseObject:derive("RicksMLC_Radio")
RicksMLC_Radio.channelUUID = "RicksMLC CHAT-1234567"; --required for DynamicRadio
RicksMLC_Radio.debugTestAll = false;

RicksMLC_Radio.name = "Radio C.H.A.T."
RicksMLC_Radio.freq = 106800
RicksMLC_Radio.category = ChannelCategory.Amateur

RicksMLC_Radio.Intro = "The radio station where 'Chaos Happens At Times'"
RicksMLC_Radio.SpecialMsg = "And now a special message from a caller..."

local colorWhite =     {r = 1.0, g = 1.0, b = 1.0}
local colorDarkRed =   {r = 0.7, g = 0.2, b = 0.2}
local colorDarkGreen = {r = 0.3, g = 0.7, b = 0.5}
local colorDarkBlue =  {r = 0.3, g = 0.3, b = 0.7}
local colorBlack =     {r = 0.3, g = 0.3, b = 0.3}
local colorOrange =    {r = 0.86, g = 0.65, b = 0.02}
function RicksMLC_Radio.GetColor(colorName)
    if colorName == "white" then
        return colorWhite
    elseif colorName == "green" then
        return colorDarkGreen
    elseif colorName == "red" then
        return colorDarkRed
    elseif colorName == "blue" then
        return colorDarkBlue
    elseif colorName == "orange" then
        return colorOrange
    elseif colorName == "black" then
        return colorBlack
    end
    return colorBlack
end

function RicksMLC_Radio.OnLoadRadioScripts(radioScriptMgr, _isNewGame)
	DebugLog.log(DebugType.Mod, "RicksMLC_Radio.OnLoadRadioScripts()")

    local chatChannel = RadioChannel.new(RicksMLC_Radio.name, RicksMLC_Radio.freq, RicksMLC_Radio.category, RicksMLC_Radio.channelUUID);
    radioScriptMgr:AddChannel(chatChannel, false);
end

-----------------------------------------
RicksMLC_Broadcaster = ISBaseObject:derive("RicksMLC_Broadcaster")
function RicksMLC_Broadcaster:new(channel, lines)
    local o = {}
	setmetatable(o, self)
	self.__index = self

    o.radioChannel = channel
    o.lines = lines
    o.broadcast = nil

	return o
end

function RicksMLC_Broadcaster:AirBroadcast()
    self:CreateBroadcast()
    self.radioChannel:setAiringBroadcast(self.broadcast);
end

function RicksMLC_Broadcaster:AddBroadcast()
    self:CreateBroadcast()
    self.radioChannel:AddBroadcast(self.broadcast)
end

function RicksMLC_Broadcaster:CreateBroadcast()
    self.broadcast = RadioBroadCast.new("GEN-"..tostring(ZombRand(100000,999999)),-1,-1)
    for i, line in ipairs(self.lines) do
        local text = line[1]
        local color = line[2]
        self.broadcast:AddRadioLine(RadioLine.new(text, color.r, color.g, color.b))
    end
end
-----------------------------------------

function RicksMLC_Radio.BroadcastImmediate(lines)
    local bc = RicksMLC_Broadcaster:new(RadioScriptManager.getInstance():getRadioChannel(RicksMLC_Radio.channelUUID), lines)
    bc:AirBroadcast()
end

function RicksMLC_Radio.AddBroadcast(lines)
    local bc = RicksMLC_Broadcaster:new(RadioScriptManager.getInstance():getRadioChannel(RicksMLC_Radio.channelUUID), lines)
    bc:AddBroadcast();
end


function RicksMLC_Radio.Init()
    DebugLog.log(DebugType.Mod, "RicksMLC_Radio.Init()")

    local radioScriptMgr = RadioScriptManager.getInstance()
    if not radioScriptMgr then
        DebugLog.log(DebugType.Mod, "RicksMLC_Radio.OnGameStart():Error no radio script manager instance")
        return
    end

    RicksMLC_Radio.OnLoadRadioScripts(RadioScriptManager.getInstance(), _isNewGame)
end

-- Commented out: The OnLoadRadioScripts event does not seem to trigger - call manually in Init() instead
--Events.OnLoadRadioScripts.Add(RicksMLC_Radio.OnLoadRadioScripts)

