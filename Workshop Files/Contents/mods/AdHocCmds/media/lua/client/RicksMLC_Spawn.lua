-- RicksMLC_Spawn.lua
-- Spawn zombies in outfits
-- TODO:
--  [+] Spawn Zombie: outfit dictates the gender
--  [-] Set location for spawn
--      [+] Spawn in front of the player a given distance
--  [ ] Use the map?
--  [ ] HeliSpawn?


require "ISBaseObject"
require "RicksMLC_Utils"
require "RicksMLC_ChatScriptFile"
RicksMLC_Spawn = RicksMLC_ChatScriptFile:derive("RicksMLC_Spawn");

function RicksMLC_Spawn:new(spawnFile)
	local o = RicksMLC_ChatScriptFile:new()
	setmetatable(o, self)

	o.spawnFile = spawnFile
	o.spawner = nil
	o.outfit = nil
    o.centre = nil
    o.offset = nil
    o.spawnX = nil
    o.spawnY = nil
    o.spawnZ = nil

	self.__index = self
	return o
end

function RicksMLC_Spawn:SpawnZombies(paramList)
    -- TODO: [ ] Allow the outfit to dictate the gender
	local i = 1
	local zCount = tonumber(paramList["zCount" .. tostring(i)])
	local fullZombieList = nil

    local x = self.spawnX
    local y = self.spawnY
    local z = self.spawnZ

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
		local zombieList = addZombiesInOutfit(x, y, z, zCount, outfit, femaleChance, crawler, isFallOnFront, isFakeDead, knockedDown, health);
		if fullZombieList == nil then
			fullZombieList = zombieList
		else
			fullZombieList:addAll(zombieList)
		end
		i = i + 1
		zCount = tonumber(paramList["zCount" .. tostring(i)])
	end
    return fullZombieList
end

function RicksMLC_Spawn:MakeSpawnLocation(paramList) 
    local radius = paramList["radius"] or 10
	local offset = paramList["offset"] or 12
    local facing = paramList["facing"] 

    if facing then 
        local lookDir = getPlayer():getForwardDirection()
        self.spawnX = getPlayer():getX() + (lookDir:getX() * offset)
        self.spawnY = getPlayer():getY() + (lookDir:getY() * offset)
        self.spawnZ = getPlayer():getZ()
        return
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
        self.spawnX = getPlayer():getX() + xCentre
        self.spawnY = getPlayer():getY() + yCentre
        self.spawnZ = getPlayer():getZ()
    end
end

function RicksMLC_Spawn:Spawn(paramList)
	--DebugLog.log(DebugType.Mod, "RicksMLC_Spawn:Spawn()")

	self.spawner = paramList["zedname"]

    self:MakeSpawnLocation(paramList)

	local fullZombieList = self:SpawnZombies(paramList)

	local numZombies = fullZombieList:size()
	local zId = 1
	for j=0, numZombies - 1 do
		local zombie = fullZombieList:get(j)
		local dogtag = InventoryItemFactory.CreateItem("Necklace_DogTag")
		dogtag:setName(dogtag:getDisplayName() .. ": " .. self.spawner .. " (" .. tostring(zId) .. " of " .. tostring(numZombies) .. ")");
		dogtag:setCustomName(true);
		zombie:addItemToSpawnAtDeath(dogtag)
		zId = zId + 1
	end
end

function RicksMLC_Spawn:WriteOutfits()
	DebugLog.log(DebugType.Mod, "RicksMLC_Spawn:WriteOutfits()")

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

Events.OnGameStart.Add(RicksMLC_Spawn.CacheOutfits)