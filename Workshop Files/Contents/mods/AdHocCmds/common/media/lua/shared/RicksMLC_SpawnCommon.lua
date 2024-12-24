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

    RicksMLC_SpawnCommon.SpawnAnimals(player, args)

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

-- Build42: Add animals

local function dumpAnimals(animals)
    local output = ""
    for k, v in pairs(animals) do
        output = output .. " " .. k .. ": "
        for k1, v1 in pairs(v) do 
            output = output .. " " .. k1 .. " " 
        end
        output = output .. "; "
    end
    DebugLog.log(DebugType.Mod, output)
end

function RicksMLC_SpawnCommon.SpawnAnimals(player, args)
    if not args.animalGroup then return end

    DebugLog.log(DebugType.Mod, "RicksMLC_SpawnCommon.SpawnAnimals(): animalGroup: '" .. args.animalGroup .. "' animalType: '".. args.animalType .. "' stress: " .. tostring(args.animalStress))

    local animals = {}
    local numGroups = 0
    local defs = getAllAnimalsDefinitions()
	for i=0, defs:size()-1 do
		local def = defs:get(i);
		if not animals[def:getGroup()] then
			animals[def:getGroup()] = {}
            numGroups = numGroups + 1
		end
        animals[def:getGroup()][def:getAnimalType()] = {breeds = {}};
        local breedList = def:getBreeds();
        for i=0, breedList:size()-1 do
            local breed = breedList:get(i)
            local breeds = animals[def:getGroup()][def:getAnimalType()].breeds
            breeds[#breeds+1] = {breedName = breed:getName(), breed = breed}
        end
	end

    --dumpAnimals(animals)
    --RicksMLC_SharedUtils.DumpArgs(animals, 0, "getAllAnimalDefinitions()->defs")

    local x = 0
    local y = 0
    local z = 0
    if isSpawnInBuilding(player, args) then
        local spawnRoomInfo = RicksMLC_SpawnCommon.ChooseSpawnRoom(player, args.minArea)
        if spawnRoomInfo and spawnRoomInfo.freeSquare then
            x = spawnRoomInfo.freeSquare:getX()
            y = spawnRoomInfo.freeSquare:getY()
            z = spawnRoomInfo.freeSquare:getZ()
        end
    else
        local spawnResult = { spawnLoc = {} }
        spawnResult.spawnLoc = RicksMLC_SpawnCommon.MakeSpawnLocation(player, args.radius, args.offset, args.facing, args.safeZoneRadius) 
        if spawnResult.spawnLoc then
            local randomLoc = calcRandomLocation(spawnResult.spawnLoc, args.radius)
            x = spawnResult.spawnLoc.x
            y = spawnResult.spawnLoc.y
            z = spawnResult.spawnLoc.z
        end
    end

    for i = 1, args.animalCount do
        local cell = player:getCell()
        local skeleton = false
        local breedInfo = animals[args.animalGroup][args.animalType].breeds[ZombRand(1, #animals[args.animalGroup][args.animalType].breeds)] -- Random breeds
        local breed = breedInfo.breed
        local animal = addAnimal(cell, x, y, z, args.animalType, breed, skeleton)
        animal:setDebugStress(args.animalStress)
        animal:addToWorld()
    end
end


-- IsoAnimal
-- public String getStressTxt(boolean var1, int var2) {
--     String var3 = Translator.getText("IGUI_Animal_Calm");
--     String var4 = "";
--     if (var1) {
--         var4 = " (" + PZMath.roundFloat(this.stressLevel, 2) + ")";
--     }
--     if (this.stressLevel > 40.0F) {
--         var3 = Translator.getText("IGUI_Animal_Unnerved");
--     }
--     if (this.stressLevel > 60.0F) {
--         var3 = Translator.getText("IGUI_Animal_Stressed");
--     }
--     if (this.stressLevel > 80.0F) {
--         var3 = Translator.getText("IGUI_Animal_Agitated");
--     }
--     if (var2 < 4) {
--         var3 = Translator.getText("IGUI_Animal_Calm");
--         if (this.stressLevel > 40.0F) {
--             var3 = Translator.getText("IGUI_Animal_Stressed");
--         }
--     }
--     return var3 + var4;
-- }
-- LuaManager {
    -- @LuaMethod(
    --     name = "addAnimal",
    --     global = true
    -- )
    -- public static IsoAnimal addAnimal(IsoCell var0, int var1, int var2, int var3, String var4, AnimalBreed var5, boolean var6) {
    --     return new IsoAnimal(var0, var1, var2, var3, var4, var5, var6);
    -- }

    -- @LuaMethod(
    --     name = "addAnimal",
    --     global = true
    -- )
    -- public static IsoAnimal addAnimal(IsoCell var0, int var1, int var2, int var3, String var4, AnimalBreed var5) {
    --     return new IsoAnimal(var0, var1, var2, var3, var4, var5);
    -- }

    -- @LuaMethod(
    --     name = "removeAnimal",
    --     global = true
    -- )
    -- public static void removeAnimal(int var0) {
    --     IsoAnimal var1 = getAnimal(var0);
    --     if (var1 != null) {
    --         var1.remove();
    --     } else {
    --         AnimalSynchronizationManager.getInstance().delete((short)var0);
    --     }

    -- }
--}