-- RicksMLC_ChatFliesClient.lua


require("RicksMLC_Flies")
if not RicksMLC_Flies then 
    DebugLog.log(DebugType.Mod, "RicksMLC_ChatFliesClient: require 'RicksMLC_Flies' failed.  No RicksMLC_Flies support.")
    return
end

RicksMLC_ChatFliesClient = {}

-- Send the AdHocCmds msg to the server so it can forward to all clients
function RicksMLC_ChatFliesClient.SendSetFlies(setFliesOn)
    local args = {Flies = setFliesOn}
    sendClientCommand(getPlayer(), "RicksMLC_ChatFliesServer", "SetFlies", args)
end

-- Receive a server command to set the flies status
local function OnServerCommand(moduleName, command, args)
    --DebugLog.log(DebugType.Mod, "RicksMLC_ChatSupply.OnServerCommand() '" .. tostring(moduleName) .. "' '" .. tostring(command) .. "'")
    if moduleName and moduleName == "RicksMLC_ChatFliesClient" and command and command == "SetFlies" then
        --RicksMLC_SharedUtils.DumpArgs(args, 1, "RicksMLC_ChatFliesClient")
        RicksMLC_Flies.SetEnabled(args.Flies)
    end
end

Events.OnServerCommand.Add(OnServerCommand)