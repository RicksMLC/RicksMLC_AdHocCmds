-- RicksMLC_Alarms.lua

-- Trigger an alarm in the nearest building
-- TODO: Make multiplayer

RicksMLC_Alarms = {}
function RicksMLC_Alarms.TriggerAlarm()
    local nearestBuildingDef = AmbientStreamManager.getNearestBuilding(getPlayer():getX(), getPlayer():getY(), Vector2f.new())

    if not nearestBuildingDef then
        DebugLog.log(DebugType.Mod, "RicksMLC_Alarms.TriggerAlarm() Fail: No nearest building at " .. tostring(getPlayer():getX()) .. "," .. tostring(getPlayer():getY()))
        return
    end
    nearestBuildingDef:setAlarmed(true)
end