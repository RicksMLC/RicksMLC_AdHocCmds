-- RicksMLC_SpawnCommon.lua
-- Common code for spawning client and server

RicksMLC_SpawnCommon = {}

function RicksMLC_SpawnCommon.CalcSafeZoneSpawnPoint(spawnLoc, radius, minSafeDistance)
    for i=0,SafeHouse.getSafehouseList():size()-1 do
        local safe = SafeHouse.getSafehouseList():get(i);
        local safeX = safe:getX() + safe:getW()/2
        local safeY = safe:getY() + safe:getH()/2
        local distance = IsoUtils.DistanceTo2D(spawnLoc.x, spawnLoc.y, safeX, safeY)
        if distance < minSafeDistance + radius then
            local vSafeToPlayer = Vector2.new(spawnLoc.x - safeX, spawnLoc.y - safeY)
            local vSafeToSpawn = Vector2.new(vSafeToPlayer)
            vSafeToSpawn:setLength(minSafeDistance + radius)
            vSafeToSpawn:add(Vector2.new(safeX, safeY))
            return { 
                x = PZMath.roundToInt(vSafeToSpawn:getX()), y = PZMath.roundToInt(vSafeToSpawn:getY()), z = 0, radius = radius, 
                safehouse = {x = PZMath.roundToInt(safeX), y = PZMath.roundToInt(safeY), z = 0, radius = minSafeDistance} 
            }
        end
        return nil
    end
end

function RicksMLC_SpawnCommon.MakeSpawnLocation(player, radius, offset, facing, safeZoneRadius) 
    local retLoc = { 
        x = player:getX(),
        y = player:getY(),
        z = player:getZ() 
    }
    if facing then 
        local lookDir = player:getForwardDirection()
        retLoc.x = player:getX() + (lookDir:getX() * offset)
        retLoc.y = player:getY() + (lookDir:getY() * offset)
        retLoc.z = player:getZ()
    else
        -- Random location for the spawn point and add offset
        local xCentre = ZombRand(-radius, radius + 1)
        if xCentre < 0 then
            xCentre = xCentre - offset
        else
            xCentre = xCentre + offset
        end
        local yCentre = ZombRand(-radius, radius + 1)
        if yCentre < 0 then
            yCentre = yCentre - offset
        else
            yCentre = yCentre + offset
        end
        retLoc.x = player:getX() + xCentre
        retLoc.y = player:getY() + yCentre
        retLoc.z = player:getZ()
    end
    if isServer() and safeZoneRadius then
        local safeZoneLoc = RicksMLC_SpawnCommon.CalcSafeZoneSpawnPoint(retLoc, radius, safeZoneRadius)
        if safeZoneLoc then
            return safeZoneLoc
        end
    end

    return retLoc
end

local function tooCloseToPlayers(spawnLoc, playerList)
    local minDistSq = 2
    for i = 0, playerList:size()-1 do
        local dist = IsoUtils.DistanceToSquared(playerList:get(i):getX(), playerList:get(i):getY(), spawnLoc.x, spawnLoc.y)
        if dist <= minDistSq then
            return true
        end
    end
    return false
end

local function jitterLocation(origLoc, radius)
    local jitterLoc = { x = origLoc.x, y = origLoc.y }
    local jitterX = ZombRand(-radius, radius)
    -- to make a circle the y needs to be calc based on x and r.  ie: y*y = r*r + x*x
    local yRadius = math.sqrt((radius * radius) - (jitterX * jitterX))
    local jitterY = ZombRand(-yRadius, yRadius)
    jitterLoc.x = origLoc.x + jitterX
    jitterLoc.y = origLoc.y + jitterY
    return jitterLoc
end

local function getPlayersToAvoid()
    if isServer() then
        return getOnlinePlayers()
    end
    local singlePlayerList = ArrayList:new()
    singlePlayerList:add(getPlayer())
    return singlePlayerList
end


local function calcRandomLocation(spawnLoc, radius, numZombies)
    local playerList = getPlayersToAvoid()
    local retLoc = jitterLocation(spawnLoc, radius)
    local tryNum = 0 -- Limit the number of tries - if it runs out of trys, just use the last one.
    while tooCloseToPlayers(retLoc, playerList) and tryNum < 5 do
        retLoc = jitterLocation(spawnLoc, radius)
        tryNum = tryNum + 1
    end
    return retLoc
end

function RicksMLC_SpawnCommon.ChooseSpawnRoom(player, minArea)
    local isoBuilding = player:getCurrentBuilding()
    local currentRoomDef = player:getCurrentRoomDef()
    local getRoomsNumber = isoBuilding:getRoomsNumber()
    local spawnRoomInfo = { buildingDef = isoBuilding:getDef(), spawnRoomDef = nil, freeSquare = nil}
    if getRoomsNumber > 1 and not spawnRoomInfo.spawnRoomDef then
        spawnRoomInfo.spawnRoomDef = isoBuilding:getDef():getRandomRoom(minArea)
        local i = 0
        while i < 10 do
            if spawnRoomInfo.spawnRoomDef and spawnRoomInfo.spawnRoomDef ~= currentRoomDef then
                spawnRoomInfo.freeSquare = spawnRoomInfo.spawnRoomDef:getIsoRoom():getRandomFreeSquare()
                if spawnRoomInfo.freeSquare then
                    return spawnRoomInfo
                end
            end
            spawnRoomInfo.spawnRoomDef = isoBuilding:getDef():getRandomRoom(minArea)
            i = i + 1
        end
        -- Fall through means no other room was found
    end
    return nil
end

function RicksMLC_SpawnCommon.SpawnInBuilding(player, args)
    local spawnResult = { fullZombieArrayList = nil, spawnRoomInfo = {} }
    local spawnRoomInfo = RicksMLC_SpawnCommon.ChooseSpawnRoom(player, args.minArea)
    if spawnRoomInfo then
        spawnResult.spawnRoomInfo = spawnRoomInfo
        for k, v in ipairs(args.outfits) do
            -- DebugLog.log(DebugType.Mod, "    outfit: '" .. tostring(v.outfit) .. "' f% " .. tostring(v.femaleChance))
            local zombieArrayList = addZombiesInBuilding(spawnRoomInfo.buildingDef, v.zCount, v.outfit, spawnRoomInfo.spawnRoomDef, v.femaleChance);
            if spawnResult.fullZombieArrayList == nil then
                spawnResult.fullZombieArrayList = zombieArrayList
            else
                spawnResult.fullZombieArrayList:addAll(zombieArrayList)
            end
        end
    end
    return spawnResult
end

function RicksMLC_SpawnCommon.SpawnNormal(player, args)
    local spawnResult = { fullZombieArrayList = nil, spawnLoc = {} }
    spawnResult.spawnLoc = RicksMLC_SpawnCommon.MakeSpawnLocation(player, args.radius, args.offset, args.facing, args.safeZoneRadius) 
    for k, v in ipairs(args.outfits) do
        -- DebugLog.log(DebugType.Mod, "    outfit: '" .. tostring(v.outfit) .. "' f% " .. tostring(v.femaleChance))
        for i = 1, v.zCount do
            local randomLoc = calcRandomLocation(spawnResult.spawnLoc, args.radius, v.zCount)
            local bAgainstWall = false
            local bInvulnerable = false
            local zombieArrayList = addZombiesInOutfit(randomLoc.x, randomLoc.y, spawnResult.spawnLoc.z, 1, v.outfit, v.femaleChance, v.crawler, v.isFallOnFront, v.isFakeDead, v.knockedDown, bInvulnerable, bAgainstWall, v.health);
            --                                         var0,        var1         var2                   var3  var4    var5            var6       var7             var8          var9           var10          var11         var12  
            if spawnResult.fullZombieArrayList == nil then
                spawnResult.fullZombieArrayList = zombieArrayList
            else
                spawnResult.fullZombieArrayList:addAll(zombieArrayList)
            end
        end
    end
    return spawnResult
end


local function isSpawnInBuilding(player, args)
    return not player:isOutside() 
        and args.spawnPointPreference 
        and args.spawnPointPreference:find("SameBuilding") ~= nil
        and SafeHouse.getSafeHouse(player:getSquare()) == nil
end

function RicksMLC_SpawnCommon.SpawnOutfit(player, args)
    --DebugLog.log(DebugType.Mod, "RicksMLC_SpawnCommon.SpawnOutfit()")
    if args.playerUserName and isServer() then
        --DebugLog.log(DebugType.Mod, "RicksMLC_SpawnCommon.SpawnOutfit(): spawn on other player '" .. args.playerUserName .. "'")
        local otherPlayer = RicksMLC_ServerUtils.GetPlayer(args.playerUserName, true)
        if otherPlayer then
            player = otherPlayer
            --DebugLog.log(DebugType.Mod, "RicksMLC_SpawnCommon.SpawnOutfit(): Other player '" .. args.playerUserName .. "' found. Mwahahah.")
        end
    end

    local spawnResult = { fullZombieArrayList = nil, spawnLoc = {}, spawnRoomInfo = {}, targetPlayerName = nil }
    if isSpawnInBuilding(player, args) then
        spawnResult = RicksMLC_SpawnCommon.SpawnInBuilding(player, args)
    end
    -- Spawn normal ie: relative to the player co-ords if outside or no zombies spawned in the player building (maybe only one room)
    if spawnResult.fullZombieArrayList == nil then
        spawnResult = RicksMLC_SpawnCommon.SpawnNormal(player, args)
    end
    spawnResult.targetPlayerName = player:getUsername()

    --DebugLog.log(DebugType.Mod, "RicksMLC_SpawnCommon.SpawnOutfit(): Finished.")
    return spawnResult
end

