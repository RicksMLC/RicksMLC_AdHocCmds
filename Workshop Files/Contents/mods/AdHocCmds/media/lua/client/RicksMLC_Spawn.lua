-- RicksMLC_Spawn.lua
-- Spawn zombies in outfits
-- TODO:
--  [+] Spawn Zombie: outfit dictates the gender
--  [-] Set location for spawn
--      [+] Spawn in front of the player a given distance
--  [ ] Use the map?
--  [ ] HeliSpawn?

require "ISUI/ISInventoryPage"
require "ISBaseObject"
require "RicksMLC_Utils"
require "RicksMLC_AdHocCmds"
require "RicksMLC_ChatIO"

RicksMLC_Spawn = RicksMLC_ChatScriptFile:derive("RicksMLC_Spawn");
function RicksMLC_Spawn:new(spawnFile)
	local o = RicksMLC_ChatScriptFile:new()
	setmetatable(o, self)
	self.__index = self

	o.spawnFile = spawnFile
	o.spawner = nil
	o.outfit = nil
    o.centre = nil
    o.offset = nil
    o.radius = nil
    o.facing = true
    o.spawnPointPreference = nil
    o.minArea = 4
    o.safeZoneRadius = 15

    o.spawnX = nil
    o.spawnY = nil
    o.spawnZ = nil

    o.startTime = 0

    o.playerCell = nil
    o.preZombieList = nil
    o.postZombieList = nil

	return o
end

function RicksMLC_Spawn:SpawnZombies(paramList)
    self.startTime = getTimeInMillis()

    self.spawner = paramList["zedname"]
    self.radius = tonumber(paramList["radius"]) or 10
    self.offset = tonumber(paramList["offset"]) or 12
    self.facing = paramList["facing"] 
    self.spawnPointPreference = paramList["spawnPointPreference"]
    self.minArea = tonumber(paramList["minArea"])
    self.safeZoneRadius = tonumber(paramList["safeZoneRadius"])

	local i = 1
	local zCount = tonumber(paramList["zCount" .. tostring(i)])
	local spawnResult = { fullZombieArrayList = nil }
    local safeZoneRadius = nil
    if RicksMLC_SpawnHandlerC.instance and RicksMLC_SpawnHandlerC.instance.safehouseSafeZoneRadius then
        safeZoneRadius = RicksMLC_SpawnHandlerC.instance.safehouseSafeZoneRadius
    end
    local spawnArgs = { 
        spawner = self.spawner,
        playerUserName = paramList["player"],
        radius = self.radius,
        offset = self.offset,
        facing = self.facing,
        spawnPointPreference = self.spawnPointPreference,
        minArea = self.minArea,
        safeZoneRadius = safeZoneRadius,
        outfits = {}
    }

	while zCount do
		local outfit = paramList["outfit" .. tostring(i)]
		local gender = paramList["gender" .. tostring(i)] -- "f"= female "m" = male.  Other = random
		local femaleChance = ZombRand(0, 100)
		if gender then
			if gender == "m" then
				femaleChance = 0
			elseif gender == "f" then
				femaleChance = 100
			end
        end

        -- Outfit overrides the gender
        local isFemale = RicksMLC_Spawn.isFemaleOutfit(outfit)
        local isMale = RicksMLC_Spawn.isMaleOutfit(outfit)
        if isFemale and not isMale then
            femaleChance = 100
        elseif isMale and not isFemale then
            femaleChance = 0
        end

		local crawler = false
		local isFallOnFront = true
		local isFakeDead = false
		local knockedDown = true
		local health = ZombRand(1, 2.9)
        spawnArgs.outfits[#spawnArgs.outfits+1] = {zCount = zCount, outfit = outfit, femaleChance = femaleChance, crawler = crawler, isFallOnFront = isFallOnFront, isFakeDead = isFakeDead, knockedDown = knockedDown, health = health}
		i = i + 1
		zCount = tonumber(paramList["zCount" .. tostring(i)])
	end

    if isClient() then
        -- Server spawns need time to generate the zombies
        -- TODO: This is a first approximation for new zombies.  A future update should use client/server protocol
        -- or better yet, spawn using the server instead of the client driving the dogtag on death assignment.
        --RicksMLC_SpawnTimer:Instance():Add(self)
        sendClientCommand(getPlayer(), 'RicksMLC_Zombies', 'SpawnOutfit', spawnArgs)
    
    elseif not isServer() then
        spawnResult = RicksMLC_SpawnCommon.SpawnOutfit(getPlayer(), spawnArgs)
        if RicksMLC_SpawnTestInstance then
            RicksMLC_SpawnTestInstance:ShowSpawnResult(spawnResult)
        end

    end

    return spawnResult.fullZombieArrayList
end

function RicksMLC_Spawn:SetZombieDogtag(zombie, zId, numZombies)
    local dogtag = InventoryItemFactory.CreateItem("Necklace_DogTag")
    local dogTagName = dogtag:getDisplayName() .. ": " .. self.spawner .. " (" .. tostring(zId) .. " of " .. tostring(numZombies) .. ")"

    --DebugLog.log(DebugType.Mod, "RicksMLC_Spawn:SetZombieDogtag(): " .. tostring(dogTagName))

    dogtag:setName(dogTagName)
    dogtag:setCustomName(true)
    zombie:addItemToSpawnAtDeath(dogtag)
end

function RicksMLC_Spawn:DecorateZombies(fullZombieList)
    --DebugLog.log(DebugType.Mod, "RicksMLC_Spawn:DecorateZombies()")
	local numZombies = fullZombieList:size()
	local zId = 1
	for j=0, numZombies - 1 do
		local zombie = fullZombieList:get(j)
        self:SetZombieDogtag(zombie, zId, numZombies)
		zId = zId + 1
	end
    -- Record the zombie in the spawnstats for collecting wounds
    RicksMLC_SpawnStats:Instance():AddZombies(self.spawner, fullZombieList)
end

function RicksMLC_Spawn:Spawn(paramList)
	--DebugLog.log(DebugType.Mod, "RicksMLC_Spawn:Spawn()")

	local fullZombieList = self:SpawnZombies(paramList)
    if not fullZombieList then return end -- The server may need time to generate them. Wait for the RicksMLC_SpawnTimer
    if not isClient() and not isServer() then
        self:DecorateZombies(fullZombieList)
    end
end

function RicksMLC_Spawn:WriteOutfits()
	--DebugLog.log(DebugType.Mod, "RicksMLC_Spawn:WriteOutfits()")

	local femaleOutfits = getAllOutfits(true);
	self.spawnFile.contentList["zf"] = "Female outfits:"
	for i=0, femaleOutfits:size()-1 do
		self.spawnFile.contentList["zf" .. tostring(i)] = femaleOutfits:get(i)
	end

	local maleOutfits = getAllOutfits(false);
	self.spawnFile.contentList["zm"] = "Male outfits:"
 	for i=0, maleOutfits:size()-1 do
		self.spawnFile.contentList["zm" .. tostring(i)] = maleOutfits:get(i)
	end

	self.spawnFile:Save("=", false)
end

-----------------------------------------------

require "Map/CGlobalObjectSystem"

RicksMLC_SpawnHandlerC = CGlobalObjectSystem:derive("RicksMLC_SpawnHandlerC")

function RicksMLC_SpawnHandlerC:new()
	local o = CGlobalObjectSystem.new(self, "RicksMLC_SpawnHandler")
	if not o.zombieSpawnList then error "zombieSpawnList wasn't sent from the server?" end
    if not o.numTrackedZombies then error "numTrackedZombies wasn't sent from the server?" end
    if not o.safehouseSafeZoneRadius then error "safehouseSafeZoneRadius wasn't sent from the server?" end

	return o
end

function RicksMLC_SpawnHandlerC:OnServerCommand(command, args)
	if command == "HandleSpawnedZombies" then
		self.zombieSpawnList = args.zombieSpawnList
        self.numTrackedZombies = args.numTrackedZombies
    elseif command == "UpdateSafehouseZone" then
        self.safehouseSafeZoneRadius = args.safehouseSafeZoneRadius
    else
		CGlobalObjectSystem.OnServerCommand(self, command, args)
	end
end

if isClient() then
    DebugLog.log(DebugType.Mod, "RicksMLC_Spawn. RegisterSystemClass")
    CGlobalObjectSystem.RegisterSystemClass(RicksMLC_SpawnHandlerC)
end

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
    --DebugLog.log(DebugType.Mod, "RicksMLC_SpawnHandler:AddDogTag")
    local zombieId = zombie:getOnlineID()
    local zombieDogTagInfo = self.spawnedZombies[zombieId]
    if zombieDogTagInfo then
        local dogtag = InventoryItemFactory.CreateItem("Necklace_DogTag")
        dogtag:setName(zombieDogTagInfo)
        dogtag:setCustomName(true)
        zombie:addItemToSpawnAtDeath(dogtag)
        self.spawnedZombies[zombieId] = nil
        self.numTrackedZombies = self.numTrackedZombies - 1
        self:UpdateOnHitZombieEvent()
    end
end

RicksMLC_SpawnHandler.OnHitZombie = function (zombie, character, bodyPartType, handWeapon)
    --DebugLog.log(DebugType.Mod, "RicksMLC_SpawnHandler.OnHitZombie()")
    RicksMLC_SpawnHandler.Instance():AddDogTag(zombie)
end

function RicksMLC_SpawnHandler:UpdateOnHitZombieEvent()
    if self.numTrackedZombies == 0 and self.isOnHitZombieOn then
        Events.OnHitZombie.Remove(RicksMLC_SpawnHandler.OnHitZombie)
        self.isOnHitZombieOn = false
        --DebugLog.log(DebugType.Mod, "RicksMLC_SpawnHandler:UpdateOnHitZombieEvent() OnHitZombie ON")
        return
    end
    if self.numTrackedZombies > 0 and not self.isOnHitZombieOn then
        Events.OnHitZombie.Add(RicksMLC_SpawnHandler.OnHitZombie)
        self.isOnHitZombieOn = true
        --DebugLog.log(DebugType.Mod, "RicksMLC_SpawnHandler:UpdateOnHitZombieEvent() OnHitZombie OFF")
    end
end

function RicksMLC_SpawnHandler:AddSpawnedZombies(spawnArgs)
    --DebugLog.log(DebugType.Mod, "RicksMLC_SpawnHandler:AddSpawnedZombies() ")
    for k, v in pairs(spawnArgs.zombieDogTagList) do
        self.spawnedZombies[k] = v.dogtagLabel
        self.numTrackedZombies = self.numTrackedZombies + 1
        --DebugLog.log(DebugType.Mod, "      " .. tostring(k) .. " " .. self.spawnedZombies[k])
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
    --DebugLog.log(DebugType.Mod, "Cmds.RicksMLC_SpawnHandler.HandleSpawnedZombies()")
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

-----------------------------------------------
-- Static things
-- Cache the outfits to check for gender match
local femaleOutfits = nil
local maleOutfits = nil
function RicksMLC_Spawn.CacheOutfits()
	femaleOutfits = getAllOutfits(true);
	maleOutfits = getAllOutfits(false);
end

function RicksMLC_Spawn.isFemaleOutfit(outfit)
    if not femaleOutfits then
        RicksMLC_Spawn.CacheOutfits()
    end
    return femaleOutfits:contains(outfit)
end

function RicksMLC_Spawn.isMaleOutfit(outfit)
    if not maleOutfits then
        RicksMLC_Spawn.CacheOutfits()
    end
    return maleOutfits:contains(outfit)
end

function RicksMLC_Spawn.Init()
    DebugLog.log(DebugType.Mod, "RicksMLC_Spawn.Init()")
    RicksMLC_Spawn.CacheOutfits()

    if isClient() then
        Events.OnServerCommand.Add(RicksMLC_ServerCmds.OnServerCommand)
    end
end
