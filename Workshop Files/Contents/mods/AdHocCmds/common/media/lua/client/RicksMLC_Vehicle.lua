-- RicksMLC_Vehicle.lua

-- Create a given part to add to a vehicle
-- Add the part to the vehicle (current or future?)
-- Repair current vehicle?
-- TODO: vehicle:triggerAlarm()

require "Tuning2/Fixes/SVUC_ATATuning2"
require "RicksMLC_SharedUtils"
RicksMLC_Vehicle = {}

local function dumpPart(vehicle, part)
    local vehicleName = vehicle:getScript():getName()
    local partName = part:getId()
    local item = nil
    part:getModData().tuning2 = {}
    if ATA2TuningTable[vehicleName] and ATA2TuningTable[vehicleName].parts[partName] then
        RicksMLC_SharedUtils.DumpArgs(ATA2TuningTable[vehicleName].parts[partName], 0, "Part '" .. partName .. "' contents:")
    end
end

local function dumpParts(vehicle)
    local vehicleScript = vehicle:getScript()
    DebugLog.log(DebugType.Mod, "Vehicle parts: " .. vehicleScript:getName() )
    for i=0, vehicleScript:getPartCount()-1 do
        local part = vehicleScript:getPart(i)
        DebugLog.log(DebugType.Mod, "  [" .. tostring(i) .. "] " .. part:getId())
    end
    DebugLog.log(DebugType.Mod, "Vehicle parts: " .. vehicleScript:getName() .. " end")
end

-- These are in order of upgrade/downgrade
local ModelListWindowsAndDoors = {
    "Light",
    "LightRusted",
    "LightSpiked",
    "LightSpikedRusted", 
    "Heavy",
    "HeavyRusted",
    "HeavySpiked",
    "HeavySpikedRusted",
    "Reinforced",
    "ReinforcedRusted"
}
local ModelListBullbars = {
    "Small",
    "Medium",
    "Large",
    "LargeSpiked",
    "Truck", -- Note: this is just for for truck bullbar
    "Plow",
    "PlowRusted",
    "PlowSpiked",
    "PlowSpikedRusted"
}
local HoodProtectionId = "ATA2ProtectionHood"
local TrunkProtectionId = "ATA2ProtectionTrunk"

function RicksMLC_Vehicle.ReportError(vehicle, partType, msg)
    local vehicleName = vehicle:getScript():getName()
    local scriptManager = getScriptManager()
    local vehicleScript = scriptManager:getVehicle(vehicleName)
    DebugLog.log(DebugType.Mod, msg)
    if vehicleScript then
        dumpParts(vehicleScript)
    end
end

-- Get the ATA part that matches the partSpec string.  Vanilla parts are ignored
function RicksMLC_Vehicle.GetPartFromSpec(vehicle, partSpec)
    local partCount = vehicle:getPartCount()-1
    local part = nil
    for i = 0, partCount do
        local checkPart = vehicle:getPartByIndex(i)
        local partId = checkPart:getId()
        if RicksMLC_Vehicle.IsATAPart(partId) and string.find(checkPart:getId():lower(), partSpec) then
            part = checkPart
            break
        end
    end
    return part
end

function RicksMLC_Vehicle.GetModelTypeFromPart(part)
    if not part:getModData().tuning2 then return nil; end

    local modelType = part:getModData().tuning2.model
    if not modelType then
        return nil
    end
    return modelType
end

function RicksMLC_Vehicle.GetPartAndModelFromSpec(vehicle, partSpec)
    local part = RicksMLC_Vehicle.GetPartFromSpec(vehicle, partSpec)
    local modelType = nil
    if part then
        modelType = RicksMLC_Vehicle.GetModelTypeFromPart(part)
    end
    return part, modelType
end

function RicksMLC_Vehicle.UninstallPartSpec(vehicle, partSpec)
    local part, model = RicksMLC_Vehicle.GetPartAndModelFromSpec(vehicle, partSpec)
    if part and model then
        RicksMLC_Vehicle.UninstallPart(vehicle, part, modelType)
    end
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

function RicksMLC_Vehicle.IsATAPart(partType)
    return partType:lower():find("ata2") 
end

function RicksMLC_Vehicle.IsPartSpec(partType)
    return not RicksMLC_Vehicle.IsATAPart(partType)
end

function RicksMLC_Vehicle.WhichModelList(partSpec)
    if partSpec == "bullbar" then return ModelListBullbars; end
    return ModelListWindowsAndDoors
end

function RicksMLC_Vehicle.FindBetterModel(partSpec, modelType)
    local modelList = RicksMLC_Vehicle.WhichModelList(partSpec)
    if modelType == nil then
        return modelList[1]
    end
    for i = 1, #modelList-1 do
        if modelList[i] == modelType then
            return modelList[i+1]
        end
    end
    return "max"
end

function RicksMLC_Vehicle.FindWorseModel(partSpec, modelType)
    local modelList = RicksMLC_Vehicle.WhichModelList(partSpec)
    if modelType == nil then
        return "none"
    end
    for i = #modelList, 2, -1 do
        if modelList[i] == modelType then
            return modelList[i-1]
        end
    end
    return "none"
end

function RicksMLC_Vehicle.UpgradePart(vehicle, partSpec)
    local part, modelType = RicksMLC_Vehicle.GetPartAndModelFromSpec(vehicle, partSpec)
    if not RicksMLC_Vehicle.IsATAPart(part:getId()) then
        -- The current part is vanilla
        if partSpec == "hood" then
            part = vehicle:getPartById(HoodProtectionId)
            if not part then
                RicksMLC_Vehicle.ReportError(vehicle, HoodProtectionId, "Error: Part '" .. HoodProtectionId .. "' not found")
                return
            end
        elseif partSpec == "trunk" then
            part = vehicle:getPartById(TrunkProtectionId)
            if not part then
                RicksMLC_Vehicle.ReportError(vehicle, TrunkProtectionId, "Error: Part '" .. TrunkProtectionId .. "' not found")
                return
            end
        end

    end

    local newModelType = RicksMLC_Vehicle.FindBetterModel(partSpec, modelType)

    -- Special handling for bullbars
    if newModelType == "Truck" and part:getId() ~= "ATA2BullbarTruck" then
        newModelType = RicksMLC_Vehicle.FindBetterModel(partSpec, newModelType)
    end

    if newModelType == "max" then
        RicksMLC_Utils.Think(getPlayer(), "My " .. partSpec .. " doesn't get better than this" , 2)
        return
    end
    if modelType then
        RicksMLC_Vehicle.UninstallPart(vehicle, part, modelType)
    end
    RicksMLC_Vehicle.InstallPart(vehicle, part, newModelType)
end

function RicksMLC_Vehicle.DowngradePart(vehicle, partSpec)
    local part, modelType = RicksMLC_Vehicle.GetPartAndModelFromSpec(vehicle, partSpec)
    if not part or not RicksMLC_Vehicle.IsATAPart(part:getId()) then return; end

    local newModelType = RicksMLC_Vehicle.FindWorseModel(partSpec, modelType)

    -- Special handling for bullbars
    if newModelType == "Truck" and part:getId() ~= "ATA2BullbarTruck" then
        newModelType = RicksMLC_Vehicle.FindWorseModel(partSpec, newModelType)
    end

    if not modelType then return; end

    RicksMLC_Vehicle.UninstallPart(vehicle, part, modelType)

    if newModelType == "none" then 
        RicksMLC_Utils.Think(getPlayer(), "Oh no. Muh " .. partSpec .. "!" , 3)
        return 
    end
    RicksMLC_Vehicle.InstallPart(vehicle, part, newModelType)
end

function RicksMLC_Vehicle.UninstallPartSpec(vehicle, partSpec)
    local part, modelType = RicksMLC_Vehicle.GetPartAndModelFromSpec(partSpec)
    if part and modelType then
        RicksMLC_Vehicle.UninstallPart(vehicle, part, modelType)
    end
end

function RicksMLC_Vehicle.HandleGenericPartSpec(vehicle, partSpec, action)
    -- hood, trunk, bullbar
    if action == "remove" then
        RicksMLC_Vehicle.UninstallPartSpec(vehicle, partSpec)
        return
    end
    if action == "upgrade" then
        RicksMLC_Vehicle.UpgradePart(vehicle, partSpec)
        return
    end
    if action == "downgrade" then
        RicksMLC_Vehicle.DowngradePart(vehicle, partSpec)
        return
    end
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
            if RicksMLC_Vehicle.IsPartSpec(partType) then
                RicksMLC_Vehicle.HandleGenericPartSpec(vehicle, partType, action)
                return
            end

            local part = vehicle:getPartById(partType)
            if not part then
                --RicksMLC_Vehicle.ReportError(vehicle, partType, "Error: Part '" .. partType .. "' not found")
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

