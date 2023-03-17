-- RicksMLC_Alarms.lua

-- Trigger an alarm in the nearest building

RicksMLC_Alarms = {}
function RicksMLC_Alarms.TriggerAlarm()
    local closestXY = Vector2f:new(50, 50)
    local nearestBuildingDef = AmbientStreamManager.instance:getNearestBuilding(getPlayer():getX(), getPlayer():getY(), closestXY)

    nearestBuildingDef:setAlarmed(true)
 
end