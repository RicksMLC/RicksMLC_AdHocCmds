-- Rick's MLC Radio
-- Note: These are copied from ISWeatherChannel.lua

---------------------------------------------------------------------------------
-- FIXME: Commented out for now as it looks like the radio broadcast to a non-equipped
--        radio may be controlled in the java component.
--
-- Override the ISRadioWindow:Update so the radio will still work on the belt
--require "RadioCom/ISRadioWindow"
--local origIsRadioWindowUpdate = ISRadioWindow.update
--function ISRadioWindow:update()
--    local radioDevice = self.device
--    local preIsTurnedOn = self.deviceData:getIsTurnedOn()
--
--    origIsRadioWindowUpdate(self)
--
--    if self.device then return end -- The radio window has not been closed
--
--    local postIsTurnedOn = radioDevice:getDeviceData():getIsTurnedOn()
--    if preIsTurnedOn and not postIsTurnedOn then
--        local location = getPlayer():getAttachedItems():getLocation(radioDevice)
--        if location then
--            radioDevice:getDeviceData():setIsTurnedOn(true);
--        end
--    end
--end

---------------------------------------------------------------------------------

RicksMLC_Radio = {};
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
	--DebugLog.log(DebugType.Mod, "RicksMLC_AdHocCmds.OnLoadRadioScripts()")

    local chatChannel = RadioChannel.new(RicksMLC_Radio.name, RicksMLC_Radio.freq, RicksMLC_Radio.category, RicksMLC_Radio.channelUUID);
    radioScriptMgr:AddChannel(chatChannel, false);
end

function RicksMLC_Radio.AddBroadcast(lines)
    local bc = RicksMLC_Radio.CreateBroadcast(getGameTime(), lines)
    local radioChannel  = RadioScriptManager.getInstance():getRadioChannel(RicksMLC_Radio.channelUUID)
    radioChannel:AddBroadcast(bc);
end

function RicksMLC_Radio.BroadcastImmediate(lines)
    local bc = RicksMLC_Radio.CreateBroadcast(getGameTime(), lines)
    local radioChannel  = RadioScriptManager.getInstance():getRadioChannel(RicksMLC_Radio.channelUUID)
    radioChannel:setAiringBroadcast(bc);
end

function RicksMLC_Radio.CreateBroadcast(gametime, lines)
    local bc = RadioBroadCast.new("GEN-"..tostring(ZombRand(100000,999999)),-1,-1)

    for i, line in ipairs(lines) do
        local text = line[1]
        local color = line[2]
        bc:AddRadioLine(RadioLine.new(text, color.r, color.g, color.b))
    end

	return bc
end

Events.OnLoadRadioScripts.Add(RicksMLC_Radio.OnLoadRadioScripts)

