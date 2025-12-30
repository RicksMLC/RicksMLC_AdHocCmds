-- RicksMLC_AdHocCmdsServer.lua
if not isServer() then return end

Events.OnClientCommand.Add(function(moduleName, command, player, args)
    --DebugLog.log(DebugType.Mod, "RicksMLC_AdHocCmdsServer.OnClientCommand() '" .. tostring(moduleName) .. "' '" .. tostring(command) .. "'")
    if moduleName == "RicksMLC_AdHocCmdsServer" then
        if command == "UpdateVendingConfig" then
            -- Respond to ping
            sendServerCommand("RicksMLC_AdHocCmdsClient", "UpdateVendingConfig", args)
        end
    end
end)