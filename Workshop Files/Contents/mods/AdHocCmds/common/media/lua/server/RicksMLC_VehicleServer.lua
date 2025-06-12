-- RicksMLC_VehicleServer.lua

-- Handle the vehicle hacking...

require "ATA2TuningTable"

RicksMLC_VehicleServer = {}

RicksMLC_VehicleServer.ClearResults = {}

function RicksMLC_VehicleServer.clearResults(player, args)
    if args.vehicle then
        local vehicle = getVehicleById(args.vehicle)
        if vehicle then
            local vehicleName = vehicle:getScript():getName()
            local tmp = ATA2TuningTable
            if not tmp[vehicleName].parts[args.partName] then
                DebugLog.log(DebugType.Mod, "Error - part/model not found")
                return
            end
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
            if not ATA2TuningTable[vehicleName].parts[args.partName] then
                return
            end
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