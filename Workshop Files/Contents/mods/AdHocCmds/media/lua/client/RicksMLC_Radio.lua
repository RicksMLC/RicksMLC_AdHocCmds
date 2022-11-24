-- Rick's MLC Radio
-- Note: These are copied from ISWeatherChannel.lua

RicksMLC_Radio = {};
RicksMLC_Radio.channelUUID = "RicksMLC CHAT-1234567"; --required for DynamicRadio
RicksMLC_Radio.debugTestAll = false;

RicksMLC_Radio.name = "Radio C.H.A.T."
RicksMLC_Radio.freq = 106800
RicksMLC_Radio.category = ChannelCategory.Amateur

RicksMLC_Radio.Intro = "The radio station where 'Chaos Happens At Times'"
RicksMLC_Radio.SpecialMsg = "And now a special message from a caller..."


--required for DynamicRadio:
function RicksMLC_Radio.OnLoadRadioScripts(radioScriptMgr, _isNewGame)
	--DebugLog.log(DebugType.Mod, "RicksMLC_AdHocCmds.OnLoadRadioScripts()")

    local chatChannel = DynamicRadioChannel.new(RicksMLC_Radio.name, RicksMLC_Radio.freq, RicksMLC_Radio.category, RicksMLC_Radio.channelUUID);

	-- FIXME: What to do with this?
	local airCounterMultiplier = nil
    if airCounterMultiplier and airCounterMultiplier >0 then
        chatChannel:setAirCounterMultiplier(airCounterMultiplier);
    end

    radioScriptMgr:AddChannel(chatChannel, false);
end

--required for DynamicRadio:
function RicksMLC_Radio.OnEveryHour(_channel, _gametime, _radio)
	-- FIXME: Broadcast from dynamic file
--    local hour = _gametime:getHour();
--
--    if hour<120 then
--        local bc = RicksMLC_Radio.CreateBroadcast(_gametime);
--
--        _channel:setAiringBroadcast(bc);
--    end
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

