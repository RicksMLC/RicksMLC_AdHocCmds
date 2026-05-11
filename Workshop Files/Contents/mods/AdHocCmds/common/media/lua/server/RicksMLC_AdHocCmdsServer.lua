-- RicksMLC_AdHocCmdsServer.lua
if not isServer() then return end

require "RicksMLC_VendingServer"


Events.OnClientCommand.Add(function(moduleName, command, player, args)
    if moduleName ~= "RicksMLC_AdHocCmdsServer" then return end

    DebugLog.log(DebugType.Mod, "RicksMLC_AdHocCmdsServer.OnClientCommand() '" .. tostring(moduleName) .. "' '" .. tostring(command) .. "'")
    if command == "VendingConfigRequest" then
        --sendServerCommand("RicksMLC_", "UpdateVendingConfig", args)
        return
    end
end)

Events.OnServerStarted.Add(function()
    -- Initial setup actions
    -- Initialize the vending config
    DebugLog.log(DebugType.Mod, "RicksMLC_AdHocCmdsServer.OnServerStarted() Initializing vending config")

    local savePath = Core.getInstance():getSaveFolder()
    DebugLog.log(DebugType.Mod, "RicksMLC_AdHocCmdsServer.OnServerStarted() Save path: " .. tostring(savePath))
    local getMyDocumentFolder = Core.getMyDocumentFolder()
    DebugLog.log(DebugType.Mod, "RicksMLC_AdHocCmdServer.OnServerStarted() getMyDocumentFolder: " .. tostring(getMyDocumentFolder))
    -- ensureFolderExists
end)