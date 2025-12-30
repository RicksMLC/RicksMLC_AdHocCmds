-----------------------------------------------
-- RicksMLC_SpawnHandler is the client-side of the server spawn.
-- This class receives messages from the server with the list of 
-- spawned zombies, which is uses to set the zombie dogtags when the client hits them.
require "ISBaseObject"
RicksMLC_SpawnHandler = ISBaseObject:derive("RicksMLC_SpawnHandler")

RicksMLC_SpawnHandlerInstance = nil
function RicksMLC_SpawnHandler.Instance()
    if not RicksMLC_SpawnHandlerInstance then
        RicksMLC_SpawnHandlerInstance = RicksMLC_SpawnHandler:new()
    end
    return RicksMLC_SpawnHandlerInstance
end

function RicksMLC_SpawnHandler:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.spawnedZombies = {}
    o.numTrackedZombies = 0

    o.isOnHitZombieOn = false

    return o
end

function RicksMLC_SpawnHandler:AddDogTag(zombie)
    DebugLog.log(DebugType.Mod, "RicksMLC_SpawnHandler:AddDogTag")
    local zombieId = zombie:getOnlineID()
    local zombieDogTagInfo = self.spawnedZombies[zombieId]
    if zombieDogTagInfo then
        local dogtag = instanceItem("RicksMLC.Necklace_DogTag_Vending")
        dogtag:setName(zombieDogTagInfo)
        dogtag:setCustomName(true)
        zombie:addItemToSpawnAtDeath(dogtag)
        if isClient() then
            sendClientCommand(getPlayer(),"RicksMLC_Zombies", "AddZombieDogtag", { zombieId = zombie:getOnlineID(), item = dogtag, dogtagLabel = zombieDogTagInfo } )
        end
        self.spawnedZombies[zombieId] = nil
        self.numTrackedZombies = self.numTrackedZombies - 1
        self:UpdateOnHitZombieEvent()
    end
end

RicksMLC_SpawnHandler.OnHitZombie = function (zombie, character, bodyPartType, handWeapon)
    DebugLog.log(DebugType.Mod, "RicksMLC_SpawnHandler.OnHitZombie()")
    RicksMLC_SpawnHandler.Instance():AddDogTag(zombie)
end

function RicksMLC_SpawnHandler:UpdateOnHitZombieEvent()
    if self.numTrackedZombies == 0 and self.isOnHitZombieOn then
        Events.OnHitZombie.Remove(RicksMLC_SpawnHandler.OnHitZombie)
        self.isOnHitZombieOn = false
        DebugLog.log(DebugType.Mod, "RicksMLC_SpawnHandler:UpdateOnHitZombieEvent() OnHitZombie ON")
        return
    end
    if self.numTrackedZombies > 0 and not self.isOnHitZombieOn then
        Events.OnHitZombie.Add(RicksMLC_SpawnHandler.OnHitZombie)
        self.isOnHitZombieOn = true
        DebugLog.log(DebugType.Mod, "RicksMLC_SpawnHandler:UpdateOnHitZombieEvent() OnHitZombie OFF")
    end
end

function RicksMLC_SpawnHandler:AddSpawnedZombies(spawnArgs)
    DebugLog.log(DebugType.Mod, "RicksMLC_SpawnHandler:AddSpawnedZombies() ")
    for k, v in pairs(spawnArgs.zombieDogTagList) do
        self.spawnedZombies[k] = v.dogtagLabel
        self.numTrackedZombies = self.numTrackedZombies + 1
        DebugLog.log(DebugType.Mod, "      " .. tostring(k) .. " " .. self.spawnedZombies[k])
    end

    RicksMLC_SpawnStats:Instance():AddZombiesFromServer(spawnArgs.spawner, spawnArgs.zombieDogTagList)

    if RicksMLC_SpawnTestInstance then
        -- Show the spawn result diagnostic for the target player
        if getPlayer():getUsername() == spawnArgs.spawnResult.targetPlayerName then
            --RicksMLC_SharedUtils.DumpArgs(spawnArgs, 0, "Client:AddSpawnedZombies()")
            RicksMLC_SpawnTestInstance:ShowSpawnResult(spawnArgs.spawnResult, spawnArgs.spawnBuildingIds)
        end
    end

    self:UpdateOnHitZombieEvent()
end

local RicksMLC_ServerCmds = {}
local Cmds = {}
Cmds.RicksMLC_SpawnHandler = {} -- The RicksMLC_ prefix is needed to distinguish from the vanilla server commands

Cmds.RicksMLC_SpawnHandler.HandleSpawnedZombies = function(args)
    DebugLog.log(DebugType.Mod, "Cmds.RicksMLC_SpawnHandler.HandleSpawnedZombies()")
    RicksMLC_SpawnHandler.Instance():AddSpawnedZombies(args)
end

RicksMLC_ServerCmds.OnServerCommand = function(moduleName, command, args)
   	if Cmds[moduleName] and Cmds[moduleName][command] then
   		Cmds[moduleName][command](args)
   	end
end

---------------------------------------------------------

function RicksMLC_SpawnHandler.TestSendSpawnToServer()
    DebugLog.log(DebugType.Mod, "RicksMLC_ScratchShared.SendSpawnToServer()")
    local offset = 10
    local lookDir = getPlayer():getForwardDirection()
    local spawnX = getPlayer():getX() + (lookDir:getX() * offset)
    local spawnY = getPlayer():getY() + (lookDir:getY() * offset)
    local spawnZ = getPlayer():getZ()

    local args = { x = spawnX, y = spawnY, z = spawnZ }
    args.outfit = ""
    args.spawner = "Moriarity"
    sendClientCommand(getPlayer(), 'RicksMLC_Zombies', 'SpawnOutfit', args)
end
