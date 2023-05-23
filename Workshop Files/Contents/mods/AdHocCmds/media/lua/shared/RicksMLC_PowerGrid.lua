-- -- RicksMLC_PowerGrid.lua
-- Does not work - there may be no way to turn the power back on.  getWorld():setHydroPowerOn() does not trigger update.

-- RicksMLC_PowerGrid={}
-- RicksMLC_PowerGrid.OrigElecShutModifier = 1
-- RicksMLC_PowerGrid.ManuallyControlled = false

-- function RicksMLC_PowerGrid.TogglePower()
--     DebugLog.log(DebugType.Mod, "RicksMLC_PowerGrid.TogglePower()")
--     DebugLog.log(DebugType.Mod, "RicksMLC_PowerGrid.TogglePower()" .. ((getWorld():isHydroPowerOn() and "Power was ON") or "Power was OFF"))

--     getWorld():setHydroPowerOn(not getWorld():isHydroPowerOn())

--     if RicksMLC_PowerGrid.ManuallyControlled then
--         SandboxVars.ElecShutModifier = 0
--         RicksMLC_PowerGrid.ManuallyControlled = true
--         DebugLog.log(DebugType.Mod, "RicksMLC_PowerGrid.TogglePower() Shut OFF")
--     else
--         SandboxVars.ElecShutModifier = RicksMLC_PowerGrid.OrigElecShutModifier
--         RicksMLC_PowerGrid.ManuallyControlled = false
--         DebugLog.log(DebugType.Mod, "RicksMLC_PowerGrid.TogglePower() Turned ON")
--     end
--     if not getWorld():getCell() then
--         DebugLog.log(DebugType.Mod, "RicksMLC_PowerGrid.TogglePower() Set current cell")
--         FIXME: update() crashes if the IsoWorld does not have a CurrentCell set.
--     end
--     getWorld():update()

--     DebugLog.log(DebugType.Mod, "RicksMLC_PowerGrid.TogglePower()" .. ((getWorld():isHydroPowerOn() and "Power is now ON") or "Power is now OFF"))
-- end

-- function RicksMLC_PowerGrid.OnGameStart()
--     RicksMLC_PowerGrid.OrigElecShutModifier = SandboxVars.ElecShutModifier
-- end

-- Events.OnGameStart.Add(RicksMLC_PowerGrid.OnGameStart)