-- RicksMLC_ChatFliesClient.lua

-- FIXME: Try to get this working or delete it:
-- local status, module = pcall(require, "RicksMLC_Flies")
-- if not status then 
--     DebugLog.log(DebugType.Mod "RicksMLC_ChatFliesClient: require 'RicksMLC_Flies' returned false.  No RicksMLC_Flies support.")
--     return
-- end

require("RicksMLC_Flies")
if not RicksMLC_Flies then 
    DebugLog.log(DebugType.Mod, "RicksMLC_ChatFliesClient: require 'RicksMLC_Flies' failed.  No RicksMLC_Flies support.")
    return
end

RicksMLC_ChatFliesClient = {}

-- Send the AdHocCmds msg to the server so it can forward to all clients
function RicksMLC_ChatFliesClient.SendSetFlies(setFliesOn)
    local args = {Flies = setFliesOn}
    sendClientCommand("RicksMLC_ChatFliesServer", "SetFlies", args)
end

-- Receive a server command to set the flies status
local function OnServerCommand(moduleName, command, args)
    --DebugLog.log(DebugType.Mod, "RicksMLC_ChatSupply.OnServerCommand() '" .. tostring(moduleName) .. "' '" .. tostring(command) .. "'")
    if moduleName and moduleName == "RicksMLC_ChatFliesClient" and command and command == "SetFlies" then
        --RicksMLC_SharedUtils.DumpArgs(args, 1, "RicksMLC_ChatFliesClient")
        RicksMLC_Flies.SetEnable(args.Flies)
    end
end

Events.OnServerCommand.Add(OnServerCommand)