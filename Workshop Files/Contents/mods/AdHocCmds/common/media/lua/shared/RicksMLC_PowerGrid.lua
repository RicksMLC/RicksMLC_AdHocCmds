-- RicksMLC_PowerGrid.lua
-- Fiddle with the power grid.  The HydroPowerOnis based on the nights survived and the sandbox option.
-- this.bHydroPowerOn = GameTime.getInstance().NightsSurvived < SandboxOptions.getInstance():getElecShutModifier()

require "ISBaseObject"
require "RicksMLC_TreasureHunt"

LuaEventManager.AddEvent("RicksMLC_PowerGridOn")
LuaEventManager.AddEvent("RicksMLC_PowerGridOff")

RicksMLC_PowerGrid = ISBaseObject:derive("RicksMLC_PowerGrid");

RicksMLC_PowerGridInstance = nil

function RicksMLC_PowerGrid.Instance()
    if not RicksMLC_PowerGridInstance then
        RicksMLC_PowerGridInstance = RicksMLC_PowerGrid:new()
    end
    return RicksMLC_PowerGridInstance
end

function RicksMLC_PowerGrid:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self

    o.OrigElecShutModifier = SandboxVars.ElecShutModifier

    o.brownOutMinutes = 10

    return o
end

function RicksMLC_PowerGrid:PowerOff()
    getWorld():setHydroPowerOn(false)
    SandboxVars.ElecShutModifier = 0
    triggerEvent("RicksMLC_PowerGridOff")
end

function RicksMLC_PowerGrid:PowerOn(suggestDays)
    local restoreDays = self:CalcRestoreDays(suggestDays)
    getWorld():setHydroPowerOn(true)
    SandboxVars.ElecShutModifier = restoreDays
    triggerEvent("RicksMLC_PowerGridOn")
end

function RicksMLC_PowerGrid:CalcRestoreDays(suggestDays)
    if not suggestDays or GameTime.getInstance():getNightsSurvived() < self.OrigElecShutModifier then
        return self.OrigElecShutModifier
    end
    return GameTime.getInstance():getNightsSurvived() + suggestDays
end

function RicksMLC_PowerGrid:TogglePower(suggestDays)
    DebugLog.log(DebugType.Mod, "RicksMLC_PowerGrid.TogglePower()")
    DebugLog.log(DebugType.Mod, "RicksMLC_PowerGrid.TogglePower()" .. ((getWorld():isHydroPowerOn() and "Power was ON") or "Power was OFF"))

    if getWorld():isHydroPowerOn() then
        RicksMLC_PowerGrid.PowerOff()
    else
        RicksMLC_PowerGrid.PowerOn(suggestDays)
        DebugLog.log(DebugType.Mod, " Power Restore Days: " .. tostring(restoreDays))
    end

    -- FIXME: Do I need to do this with every power on/off?
    --if getWorld():getCell() then
    --    DebugLog.log(DebugType.Mod, "RicksMLC_PowerGrid.TogglePower() Set current cell")
    --    --FIXME: update() crashes if the IsoWorld does not have a CurrentCell set.
    --    getWorld():update()
    --end

    DebugLog.log(DebugType.Mod, "RicksMLC_PowerGrid.TogglePower()" .. ((getWorld():isHydroPowerOn() and "Power is now ON") or "Power is now OFF"))
end

function RicksMLC_PowerGrid:BrownOut(minutes)
    if not getWorld():isHydroPowerOn() then return end
    self:PowerOff()
    self.brownOutMinutes = minutes
    Events.EveryOneMinute.Remove(RicksMLC_PowerGrid.EveryOneMinuteBrownOut)
    Events.EveryOneMinute.Add(RicksMLC_PowerGrid.EveryOneMinuteBrownOut)
end

function RicksMLC_PowerGrid:HandleBrownOutMinutes()
    self.brownOutMinutes = self.brownOutMinutes - 1
    if self.brownOutMinutes > 1 then return end
    self:PowerOn()
    Events.EveryOneMinute.Remove(RicksMLC_PowerGrid.EveryOneMinuteBrownOut)
end

function RicksMLC_PowerGrid.EveryOneMinuteBrownOut()
    RicksMLC_PowerGrid.Instance():HandleBrownOutMinutes()
end

function RicksMLC_PowerGrid.OnGameStart()
    RicksMLC_PowerGrid.Instance()
end

Events.OnGameStart.Add(RicksMLC_PowerGrid.OnGameStart)
