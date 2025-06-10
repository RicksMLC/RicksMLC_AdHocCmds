-- RicksMLC_Vehicle.lua

-- Create a given part to add to a vehicle
-- Add the part to the vehicle (current or future?)
-- Repair current vehicle?
-- TODO: vehicle:triggerAlarm()

require "Tuning2/Fixes/SVUC_ATATuning2"
require "RicksMLC_SharedUtils"
RicksMLC_Vehicle = {}

local function dumpParts(vehicleScript)
    DebugLog.log(DebugType.Mod, "Vehicle parts: " .. vehicleScript:getName() )
    for i=0, vehicleScript:getPartCount()-1 do
        local part = vehicleScript:getPart(i)
        DebugLog.log(DebugType.Mod, "  [" .. tostring(i) .. "] " .. part:getId())
    end
    DebugLog.log(DebugType.Mod, "Vehicle parts: " .. vehicleScript:getName() .. " end")
end


local function dumpPart(vehicle, part)
    local vehicleName = vehicle:getScript():getName()
    local partName = part:getId()
    local item = nil
    part:getModData().tuning2 = {}
    if ATA2TuningTable[vehicleName] and ATA2TuningTable[vehicleName].parts[partName] then
        RicksMLC_SharedUtils.DumpArgs(ATA2TuningTable[vehicleName].parts[partName], 0, "Part '" .. partName .. "' contents:")
    end
end

function RicksMLC_Vehicle.ReportError(vehicle, partType, msg)
    local vehicleName = vehicle:getScript():getName()
    local scriptManager = getScriptManager()
    local vehicleScript = scriptManager:getVehicle(vehicleName)
    DebugLog.log(DebugType.Mod, msg)
    dumpParts(vehicleScript)
end

function RicksMLC_Vehicle.UninstallPart(vehicle, part, modelName)
    local args = {
        vehicle = vehicle:getId(), 
        partName = part:getId(),
        modelName = modelName
    }

    sendClientCommand(getPlayer(), "RicksMLC_VehicleServer", "clearResults", args)
    sendClientCommand(getPlayer(), 'atatuning2', 'uninstallTuning', args)
    sendClientCommand(getPlayer(), "RicksMLC_VehicleServer", "restoreResults", args)
end

function RicksMLC_Vehicle.InstallPart(vehicle, part, modelName)
    local firstCondition = 86
    local args = {
        vehicle = vehicle:getId(), 
        partName = part:getId(),
        modelName = modelName,
        condition = firstCondition
    }

    sendClientCommand(getPlayer(), 'atatuning2', 'installTuning', args)
end

function RicksMLC_Vehicle.ProcessCommand(chatScriptFile)
    -- FIXME:  Check the SVU mod is included...
    --if not getActivatedMods():contains("StandardizedVehicleUpgrades3V") then return; end

    local isRepair = chatScriptFile.contentList["repair"] and chatScriptFile.contentList["repair"] == "true"
    local partType = chatScriptFile.contentList["part"]
    local modelType = chatScriptFile.contentList["modelType"]
    local action = chatScriptFile.contentList["action"]
    local triggerAlarm = chatScriptFile.contentList["alarm"] and chatScriptFile.contentList["alarm"] == "true"

    if partType then
        local vehicle = getPlayer():getVehicle()
        if vehicle then
            local part = vehicle:getPartById(partType)
            if not part then
                RicksMLC_Vehicle.ReportError(vehicle, partType, "Error: Part '" .. partType .. "' not found")
                return
            end
            if part:getInventoryItem() then
                DebugLog.log(DebugType.Mod, "Part already installed - removing")
                -- FIXME: Handle remove explicitly? 
                if action == "remove" then
                    RicksMLC_Vehicle.UninstallPart(vehicle, part, modelType)
                end
            else
                DebugLog.log(DebugType.Mod, "Part not installed yet")
                RicksMLC_Vehicle.InstallPart(vehicle, part, modelType)
            end
        end
    end

end