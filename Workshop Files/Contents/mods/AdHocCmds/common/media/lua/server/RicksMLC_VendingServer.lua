-- RicksMLC_VendingServer.lua
require "RicksMLC_VendingShared"

RicksMLC_VendingServer = {}
RicksMLC_VendingServer.MasterConfig = RicksMLC_VendingMachineConfig:Instance()


function RicksMLC_VendingServer.UpdateConfig(configFile)
    DebugLog.log(DebugType.Mod, "RicksMLC_VendingServer.UpdateConfig()")

    RicksMLC_VendingServer.MasterConfig:Update(configFile)

    -- Notify all clients of the updated config
    local args = { configFile = configFile }
    sendClientCommand(nil, "RicksMLC_Vending", "VendingConfigUpdate", args)
end

function RicksMLC_VendingServer.SendFullConfigToClient(player)
    DebugLog.log(DebugType.Mod, "RicksMLC_VendingServer.SendFullConfigToClient()")

    -- Send the master configs in push order to the client (ie: default first, then overrides)
    local args = { configFiles = { RicksMLC_VendingServer.MasterConfig.configFile } }
    local prevVendingConfig = RicksMLC_VendingServer.MasterConfig.prevVendingConfig
    while prevVendingConfig do
        table.insert(args.configFiles, 1, prevVendingConfig.configFile)
        prevVendingConfig = prevVendingConfig.prevVendingConfig
    end
    sendServerCommand(player, "RicksMLC_Vending", "FullVendingConfig", args)
end

function RicksMLC_VendingServer.UpdateVendingConfig(player, args)
    DebugLog.log(DebugType.Mod, "RicksMLC_VendingServer.UpdateVendingConfig()")

    -- if the cashIns is not set, reset the configs and default to the given config file
    if args.configFile:Get("cashIns") == nil then
        RicksMLC_VendingServer.MasterConfig = nil
        RicksMLC_VendingServer.MasterConfig = RicksMLC_VendingMachineConfig:Instance()
    end
    local vendingConfig = RicksMLC_ChatIO.CloneChatIO(args.configFile)
    RicksMLC_VendingServer.UpdateConfig(vendingConfig)
end


Events.OnClientCommand.Add(function(moduleName, command, player, args)
    DebugLog.log(DebugType.Mod, "RicksMLC_VendingServer.OnClientCommand() '" .. tostring(moduleName) .. "' '" .. tostring(command) .. "'")
    if moduleName ~= "RicksMLC_Vending" then return end

    if command == "UpdateVendingConfig" then
        DebugLog.log(DebugType.Mod, "RicksMLC_VendingServer.OnClientCommand() UpdateVendingConfig received from client")
        local vendingConfig = RicksMLC_ChatIO.CloneChatIO(args.configFile)
        RicksMLC_VendingServer.UpdateConfig(vendingConfig)
        return
    end
    if command == "VendingConfigRequest" then
        DebugLog.log(DebugType.Mod, "RicksMLC_VendingServer.OnClientCommand() VendingConfigRequest received from client")
        local args = { configFile = RicksMLC_VendingServer.MasterConfig.configFile }
        sendClientCommand(nil, "RicksMLC_Vending", "VendingConfigUpdate", args)
        return
    end
    if command == "RequestFullConfig" then
        DebugLog.log(DebugType.Mod, "RicksMLC_VendingServer.OnClientCommand() RequestFullConfig received from client")
        RicksMLC_VendingServer.SendFullConfigToClient(player)
        return
    end
end)

