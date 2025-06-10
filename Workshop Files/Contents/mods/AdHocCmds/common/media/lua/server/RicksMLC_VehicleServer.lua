-- RicksMLC_VehicleServer.lua

-- Handle the vehicle hacking...

RicksMLC_VehicleServer = {}

RicksMLC_VehicleServer.ClearResults = {}

function RicksMLC_VehicleServer.clearResults(player, args)
    if args.vehicle then
        local vehicle = getVehicleById(args.vehicle)
        if vehicle then
            local vehicleName = vehicle:getScript():getName()
            RicksMLC_VehicleServer.ClearResults[player:getOnlineID()] = ATA2TuningTable[vehicleName].parts[args.partName][args.modelName].uninstall.result
            ATA2TuningTable[vehicleName].parts[args.partName][args.modelName].uninstall.result = {}
        end
    end
end

function RicksMLC_VehicleServer.restoreResults(player, args)
    if args.vehicle then
        local vehicle = getVehicleById(args.vehicle)
        if vehicle then
            local vehicleName = vehicle:getScript():getName()
            ATA2TuningTable[vehicleName].parts[args.partName][args.modelName].uninstall.result = RicksMLC_VehicleServer.ClearResults[player:getOnlineID()]
        end
    end
end

function RicksMLC_VehicleServer.HandleCommand(moduleName, commandName, player, args)
    if moduleName == "RicksMLC_VehicleServer" then
        if commandName == "clearResults" then
            RicksMLC_VehicleServer.clearResults(player, args)
            return
        end
        if commandName == "restoreResults" then
            RicksMLC_VehicleServer.restoreResults(player, args)
            return
        end
    end
end

Events.OnClientCommand.Add(RicksMLC_VehicleServer.HandleCommand)