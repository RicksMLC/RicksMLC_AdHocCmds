-- RicksMLC_ChatFliesServer.lua

local RicksMLC_Commands = {}

RicksMLC_Commands.RicksMLC_ChatFliesServer = {}

function RicksMLC_Commands.RicksMLC_ChatFliesServer.SetFlies(player, args)
    DebugLog.log(DebugType.Mod, "RicksMLC_Commands.RicksMLC_ChatFlies.SetFlies")
    local clientArgs = {Flies = args.Flies}
    sendServerCommand("RicksMLC_ChatFliesClient", "SetFlies", clientArgs)
end


local OnClientCommand = function(moduleName, command, player, args)
    --DebugLog.log(DebugType.Mod, 'RicksMLC_ChatSupplyServer.OnClientCommand() ' .. moduleName .. "." .. command)
    if RicksMLC_Commands[moduleName] and RicksMLC_Commands[moduleName][command] then
         -- FIXME: Comment out when done?
        local argStr = ''
 		for k,v in pairs(args) do argStr = argStr..' '..k..'='..tostring(v) end
 		DebugLog.log(DebugType.Mod, 'received '..moduleName..' '..command..' '..tostring(player)..argStr)

 		RicksMLC_Commands[moduleName][command](player, args)
    end
end

Events.OnClientCommand.Add(OnClientCommand)