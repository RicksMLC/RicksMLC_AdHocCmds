-- RicksMLC_SpawnServer.lua

if not isServer() then return end
if isClient() then return end

------------------------------------------------------------------------

require "Map/SGlobalObjectSystem"

RicksMLC_SpawnServer = SGlobalObjectSystem:derive("RicksMLC_SpawnServer")
function RicksMLC_SpawnServer:new()
 	local o = SGlobalObjectSystem.new(self, "RicksMLC_SpawnHandler")

    o.zombieSpawnList = { }
    o.numTrackedZombies = 0
    o.dogTagDisplayName = instanceItem("Necklace_DogTag"):getDisplayName()

    -- Note: Read from gos_RicksMLC_SpawnHandler.bin
    o.safehouseSafeZoneRadius = o.safehouseSafeZoneRadius or 16

 	return o
end

SGlobalObjectSystem.RegisterSystemClass(RicksMLC_SpawnServer)

function RicksMLC_SpawnServer:isValidIsoObject(isoObject)
	return false
end

function SGlobalObjectSystem:newLuaObject(globalObject)
	-- Return an object derived from SGlobalObject
	return nil
end

function RicksMLC_SpawnServer:initSystem()
	SGlobalObjectSystem.initSystem(self)

	-- Specify GlobalObjectSystem fields that should be saved.
	self.system:setModDataKeys({'zombieSpawnList', 'numTrackedZombies', 'safehouseSafeZoneRadius'})
end

function RicksMLC_SpawnServer:getInitialStateForClient()
	-- Return a Lua table that is used to initialize the client-side system.
	-- This is called when a client connects in multiplayer, and after
	-- server-side systems are created in singleplayer.
	return { 
        zombieSpawnList = self.zombieSpawnList,
        numTrackedZombies = self.numTrackedZombies,
        safehouseSafeZoneRadius = self.safehouseSafeZoneRadius
    }
end

function RicksMLC_SpawnServer:GetZombieDogtagName(zId, numZombies, spawner)
    local dogtagLabel = self.dogTagDisplayName
                        .. ": " .. spawner
                        .. " (" .. tostring(zId) .. " of " .. tostring(numZombies) .. ")"
    return dogtagLabel
end

function RicksMLC_SpawnServer:AddNewSpawns(spawnResult, spawner)
    --DebugLog.log(DebugType.Mod, "RicksMLC_ScratchServer:AddNewSpawns() " .. tostring(spawnResult.fullZombieArrayList:size()))
    local newSpawnList = self:DecorateZombies(spawnResult.fullZombieArrayList, spawner)
    local n = 0
    for k, v in pairs(newSpawnList) do
        self.zombieSpawnList[k] = v
        n = n + 1
    end
    if n == 0 then
        DebugLog.log(DebugType.Mod, "RicksMLC_SpawnServer:AddNewSpawns(): no spawned zombies")
        return
    end
    self.numTrackedZombies = self.numTrackedZombies + n

    local args = { zombieDogTagList = newSpawnList,  spawnResult = spawnResult, spawnBuildingIds = { buildingId = nil, spawnRoomId = nil }, spawner = spawner }
    --DebugLog.log(DebugType.Mod, "RicksMLC_SpawnServer:AddNewSpawns() spawnRoomInfo " .. tostring(spawnResult.spawnRoomInfo) .. " buildingDef: " .. tostring(spawnResult.spawnRoomInfo.buildingDef))
    if spawnResult.spawnRoomInfo and spawnResult.spawnRoomInfo.buildingDef then
        -- Convert the objects to Ids so the client can translate them back into objects
        --DebugLog.log(DebugType.Mod, "RicksMLC_SpawnServer:AddNewSpawns() " ..  tostring(spawnResult.spawnRoomInfo.buildingDef:getID()) .. " " .. tostring(spawnResult.spawnRoomInfo.spawnRoomDef:getID()))
        args.spawnBuildingIds.buildingId = spawnResult.spawnRoomInfo.buildingDef:getID()
        args.spawnBuildingIds.spawnRoomId = spawnResult.spawnRoomInfo.spawnRoomDef:getID()
    end
    --RicksMLC_SharedUtils.DumpArgs(args, 0, "Server:HandleSpawnedZombies")
    sendServerCommand('RicksMLC_SpawnHandler', 'HandleSpawnedZombies', args)
end

function RicksMLC_SpawnServer:RemoveDeadZombie(zombie)
    self.zombieSpawnList[zombie:getOnlineID()] = nil
    self.numTrackedZombies = self.numTrackedZombies - 1
end

function RicksMLC_SpawnServer:DecorateZombies(fullZombieArrayList, spawner)
    --DebugLog.log(DebugType.Mod, "DecorateZombies()" .. tostring(fullZombieArrayList:size()))
	local numZombies = fullZombieArrayList:size()
    local decoratedZombies = {}
	local zId = 1
	for j=0, numZombies - 1 do
		local zombie = fullZombieArrayList:get(j)
        local dogtagLabel = self:GetZombieDogtagName(zId, numZombies, spawner)
        local zombieId = zombie:getOnlineID()
        -- DebugLog.log(DebugType.Mod, "DecorateZombies() '" .. zombieId .. "' '" .. dogtagLabel .. "'")
        decoratedZombies[zombieId] = { dogtagLabel = dogtagLabel, zombieId = zombie:getOnlineID() }
		zId = zId + 1
	end
    return decoratedZombies
end

function RicksMLC_SpawnServer:SendZombieList(player)
    if self.numTrackedZombies == 0 then return end

    local args = { zombieDogTagList = self.zombieSpawnList }
    sendServerCommand('RicksMLC_SpawnHandler', 'HandleSpawnedZombies', args)
end

function RicksMLC_SpawnServer:UpdateSafeZone(player, args)
    
    if args.safeZoneRadius and self.safehouseSafeZoneRadius ~= args.safeZoneRadius then
        self.safehouseSafeZoneRadius = args.safeZoneRadius
        local clientArgs = { safehouseSafeZoneRadius = args.safeZoneRadius }
        self:sendCommand('UpdateSafehouseZone', clientArgs)
    end
end

local RicksMLC_Commands = {}
RicksMLC_Commands.RicksMLC_Zombies = {}

RicksMLC_Commands.RicksMLC_Zombies.SpawnOutfit = function(player, args)
    --DebugLog.log(DebugType.Mod, "RicksMLC_Commands.RicksMLC_Zombies.SpawnOutfit()")
    local spawnResult = RicksMLC_SpawnCommon.SpawnOutfit(player, args)
    if spawnResult.fullZombieArrayList then
        --DebugLog.log(DebugType.Mod, "RicksMLC_Commands.RicksMLC_Zombies.SpawnOutfit(): AddNewSpawns() called")
        RicksMLC_SpawnServer.instance:AddNewSpawns(spawnResult, args.spawner)
    end
    --DebugLog.log(DebugType.Mod, "RicksMLC_Commands.RicksMLC_Zombies.SpawnOutfit(): Finished.")
end

RicksMLC_Commands.RicksMLC_Zombies.UpdateSafeZoneFromClient = function(player, args)
    RicksMLC_SpawnServer.instance:UpdateSafeZone(player, args)
end

function RicksMLC_SpawnServer.OnZombieDead(zombie)
    --DebugLog.log(DebugType.Mod, "RicksMLC_SpawnServer.OnZombieDead() " .. tostring(zombie:getOnlineID()))
    RicksMLC_SpawnServer.instance:RemoveDeadZombie(zombie)
end

function RicksMLC_SpawnServer.OnClientCommand(moduleName, command, player, args)
    -- Receive a message from a client
    --DebugLog.log(DebugType.Mod, 'RicksMLC_SpawnServer.OnClientCommand() ' .. moduleName .. "." .. command)
    if RicksMLC_Commands[moduleName] and RicksMLC_Commands[moduleName][command] then
        -- FIXME: Comment out when done?
        -- local argStr = ''
 		-- for k,v in pairs(args) do argStr = argStr..' '..k..'='..tostring(v) end
 		-- DebugLog.log(DebugType.Mod, 'received '..moduleName..' '..command..' '..tostring(player)..argStr)
 		RicksMLC_Commands[moduleName][command](player, args)
    end
end

Events.OnClientCommand.Add(RicksMLC_SpawnServer.OnClientCommand)
Events.OnZombieDead.Add(RicksMLC_SpawnServer.OnZombieDead)
