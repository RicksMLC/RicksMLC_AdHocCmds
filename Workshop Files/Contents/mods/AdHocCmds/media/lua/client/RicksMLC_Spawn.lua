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
    o.spawnX = nil
    o.spawnY = nil
    o.spawnZ = nil

    o.startTime = 0

    o.playerCell = nil
    o.preZombieList = nil
    o.postZombieList = nil

	return o
end

function RicksMLC_Spawn:EndTimerCallback(retryNum)
    -- Callback function at the end of the timer
    -- returns true if the timer can end

    self.postZombieList = self.playerCell:getZombieList()
    --DebugLog.log(DebugType.Mod, "RicksMLC_Spawn:Spawn() Server pre: " .. tostring(self.preZombieList:size()) .. " post: " .. tostring(self.postZombieList:size()))
    -- These must be the new zombie, but do we need a timer and wait for an update?
    local zombieList = ArrayList.new()
    if self.preZombieList:size() < self.postZombieList:size() then
        for i = self.preZombieList:size(), self.postZombieList:size()-1 do
            zombieList:add(self.postZombieList:get(i))
        end
    end
    if zombieList:size() == 0 then
        local timeout = getTimeInMillis() - self.startTime
        if timeout > 10000 then
            -- Abort if over timeout (10 seconds)
            DebugLog.log(DebugType.Mod, "RicksMLC_Spawn:EndTimerCallback() Abort.  Tries:" .. tostring(retryNum) .. " Time: " .. tostring(timeout) .."ms")
            RicksMLC_Utils.Think(getPlayer(), "Zombie Spawn Timeout for " .. tostring(self.spawner) .. "'s zombies - sorry. Timeout " .. tostring(timeout) .."ms", 3)
            return true
        end
        return false
    end

    self:DecorateZombies(zombieList)

    --DebugLog.log(DebugType.Mod, "RicksMLC_Spawn:EndTimerCallback() Complete.  Tries:" .. tostring(retryNum))

    return true
end

function RicksMLC_Spawn:SpawnServerZombies(x, y, z, zCount, outfit, crawler, isFallOnFront, isFakeDead, knockedDown, health)
    --DebugLog.log(DebugType.Mod, "RicksMLC_Spawn:SpawnServerZombies()")
    if not self.playerCell then
        self.playerCell = getPlayer():getCell()
        self.preZombieList = self.playerCell:getZombieList():clone()
        --DebugLog.log(DebugType.Mod, "RicksMLC_Spawn:SpawnServerZombies() preZombieList:" .. tostring(self.preZombieList:size()))
    end

    SendCommandToServer(
        string.format("/createhorde2 -x %d -y %d -z %d -count %d -radius %d -crawler %s -isFallOnFront %s -isFakeDead %s -knockedDown %s -health %s -outfit %s ",
        x, y, z, zCount, self.radius, tostring(crawler), tostring(isFallOnFront), tostring(isFakeDead), tostring(knockedDown), tostring(health), outfit or ""))

end

function RicksMLC_Spawn:SpawnZombies(paramList)
    -- TODO: [ ] Allow the outfit to dictate the gender
    self.startTime = getTimeInMillis()

	local i = 1
	local zCount = tonumber(paramList["zCount" .. tostring(i)])
	local fullZombieList = nil

    local x = self.spawnX
    local y = self.spawnY
    local z = self.spawnZ
    local isServerSpawn = false

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
        if isClient() then
            self:SpawnServerZombies(x, y, z, zCount, outfit, crawler, isFallOnFront, isFakeDead, knockedDown, health)
            isServerSpawn = true
        else
		    local zombieList = addZombiesInOutfit(x, y, z, zCount, outfit, femaleChance, crawler, isFallOnFront, isFakeDead, knockedDown, health);
		    if fullZombieList == nil then
    			fullZombieList = zombieList
	    	else
		    	fullZombieList:addAll(zombieList)
		    end
        end
		i = i + 1
		zCount = tonumber(paramList["zCount" .. tostring(i)])
	end

    if isServerSpawn then
        -- Server spawns need time to generate the zombies, so set a timer to check for new zombies in the cell
        -- TODO: This is a first approximation for new zombies.  A future update should use client/server protocol
        -- or better yet, spawn using the server instead of the client driving the dogtag on death assignment.
        RicksMLC_SpawnTimer:Instance():Add(self)
    end

    return fullZombieList
end

function RicksMLC_Spawn:MakeSpawnLocation(paramList) 
    self.radius = paramList["radius"] or 10
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
        local xCentre = ZombRand(-self.radius, self.radius + 1)
        if xCentre < 0 then
            xCentre = xCentre - offset
        else
            xCentre = xCentre + offset
        end
        local yCentre = ZombRand(-self.radius, self.radius + 1)
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

function RicksMLC_Spawn:SetZombieDogtag(zombie, zId, numZombies)
    local dogtag = InventoryItemFactory.CreateItem("Necklace_DogTag")
    local dogTagName = dogtag:getDisplayName() .. ": " .. self.spawner .. " (" .. tostring(zId) .. " of " .. tostring(numZombies) .. ")"

    --DebugLog.log(DebugType.Mod, "RicksMLC_Spawn:SetZombieDogtag(): " .. tostring(dogTagName))

    dogtag:setName(dogTagName)
    dogtag:setCustomName(true)
    zombie:addItemToSpawnAtDeath(dogtag)
    local zModData = zombie:getModData()
    zModData["RicksMLC_Spawn"] = {self.spawner, numZombies, zId, zombie.ZombieID}
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

	self.spawner = paramList["zedname"]

    self:MakeSpawnLocation(paramList)

	local fullZombieList = self:SpawnZombies(paramList)
    if not fullZombieList then return end -- The server may need time to generate them. Wait for the RicksMLC_SpawnTimer

    self:DecorateZombies(fullZombieList)

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
end
