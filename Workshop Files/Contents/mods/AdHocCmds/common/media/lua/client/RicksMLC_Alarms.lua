-- RicksMLC_Alarms.lua

-- Trigger an alarm in the nearest building
-- TODO: Make multiplayer

RicksMLC_Alarms = {}

-- Note that AmbientStreamManager is not on the server in vanilla.
-- See function RicksMLC_TreasureHuntMgrServer.OnServerStarted() which instantiates one on the server
function RicksMLC_Alarms.getNearestBuildingDef(x, y, ...)
    local metaGrid = getWorld():getMetaGrid() -- Ensure the metaGrid is intitialised before calling AmbientStreamManager.getNearestBuilding()
    local nearestBuildingDef = AmbientStreamManager.getNearestBuilding(x, y, Vector2f.new())
    return nearestBuildingDef
end

function RicksMLC_Alarms.TriggerAlarm()
    local nearestBuildingDef = RicksMLC_Alarms.getNearestBuildingDef(getPlayer():getX(), getPlayer():getY())

    if not nearestBuildingDef then
        DebugLog.log(DebugType.Mod, "RicksMLC_Alarms.TriggerAlarm() Fail: No nearest building at " .. tostring(getPlayer():getX()) .. "," .. tostring(getPlayer():getY()))
        return
    end
    nearestBuildingDef:setAlarmed(true)
end