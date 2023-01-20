-- RicksMLC_Spawn.lua
-- Spawn zombies in outfits
-- TODO:
--  [+] Spawn Zombie: outfit dictates the gender
--  [-] Set location for spawn
--      [+] Spawn in front of the player a given distance
--  [ ] Use the map?
--  [ ] HeliSpawn?

require "ISInventoryPage"
require "ISBaseObject"
require "TimedActions/ISTimedActionQueue"
require "RicksMLC_Utils"
require "RicksMLC_AdHocCmds"
require "RicksMLC_ChatIO"
require "RicksMLC_ChatScriptFile"

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
    o.spawnX = nil
    o.spawnY = nil
    o.spawnZ = nil

	return o
end

function RicksMLC_Spawn:SpawnZombies(paramList)
    -- TODO: [ ] Allow the outfit to dictate the gender
    local startTime = getTimeInMillis()

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

    local endTime = getTimeInMillis()
    --DebugLog.log(DebugType.Mod, "RicksMLC_Spawn:Spawn() Time: " .. tostring(endTime - startTime) .. "ms")

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

function RicksMLC_Spawn:SetZombieDogtag(zombie, zId, numZombies)
    local dogtag = InventoryItemFactory.CreateItem("Necklace_DogTag")
    dogtag:setName(dogtag:getDisplayName() .. ": " .. self.spawner .. " (" .. tostring(zId) .. " of " .. tostring(numZombies) .. ")")
    dogtag:setCustomName(true)
    zombie:addItemToSpawnAtDeath(dogtag)
    local zModData = zombie:getModData()
    zModData["RicksMLC_Spawn"] = {self.spawner, numZombies, zId}
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
        self:SetZombieDogtag(zombie, zId, numZombies)
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
-- Vending Machine implementation
RicksMLC_VendingMachineConfig = ISBaseObject:derive("RicksMLC_VendingMachineConfig")

RicksMLC_VendingConfigInstance = RicksMLC_VendingMachineConfig:new()
function RicksMLC_VendingMachineConfig.Instance()
    if not RicksMLC_VendingConfigInstance then
        RicksMLC_VendingConfigInstance = RicksMLC_VendingMachineConfig:new()
    end
    return RicksMLC_VendingConfigInstance 
end

function RicksMLC_VendingMachineConfig:new()
    local o = {}
	setmetatable(o, self)
	self.__index = self

    o.prizes = {}

	return o
end

function RicksMLC_VendingMachineConfig:Update(vendingConfigFile)
    --DebugLog.log(DebugType.Mod, "RicksMLC_VendingMachineConfig:Update() ")
    local prizeLine = vendingConfigFile:Get("prizes")
    self.prizes = RicksMLC_Utils.SplitStr(prizeLine, ",")
end

function RicksMLC_VendingMachineConfig:GetRandomPrize()
    if #self.prizes == 0 then 
        DebugLog.log(DebugType.Mod, "RicksMLC_VendingMachineConfig:GetRandomPrize() Error - no prizes in list")
        return
    end
    local rnd = ZombRand(1, #self.prizes+1)
    --DebugLog.log(DebugType.Mod, "RicksMLC_VendingMachineConfig:GetRandomPrize() " .. tostring(rnd))
    return self.prizes[rnd]
end

-----

ISCashInDogTagAction = ISBaseTimedAction:derive("ISCashInDogTagAction");

function ISCashInDogTagAction:isValid()
    return true
end

function ISCashInDogTagAction:waitToStart()
	self.character:faceThisObject(self.vendingMachine)
	return self.character:shouldBeTurning()end

function ISCashInDogTagAction:start()
	self.sound = self.character:playSound("VendingMachineCoin02")
end

function ISCashInDogTagAction:stop()
	ISBaseTimedAction.stop(self)
end

function ISCashInDogTagAction:perform()
	self.character:stopOrTriggerSound(self.sound)

    self.invPage.inventoryPane.inventory:Remove(self.item)

    -- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

function ISCashInDogTagAction:new(character, vendingMachine, invPage, item, time)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.maxTime = time
    if character:HasTrait("Dextrous") then
        o.maxTime = o.maxTime * 0.5
    end
    if character:HasTrait("AllThumbs") then
        o.maxTime = o.maxTime * 2.0
    end
    o.character = character
	-- custom fields
	o.vendingMachine = vendingMachine
    o.invPage = invPage
	o.item = item
	return o
end

ISCashInVendAction = ISBaseTimedAction:derive("ISCashInVendAction");

function ISCashInVendAction:isValid()
    return true
end

function ISCashInVendAction:waitToStart()
	self.character:faceThisObject(self.vendingMachine)
	return self.character:shouldBeTurning()end

function ISCashInVendAction:start()
	self.sound = self.character:playSound("VendingMachineVend01")
end

function ISCashInVendAction:stop()
	ISBaseTimedAction.stop(self)
end

function ISCashInVendAction:perform()
	self.character:stopOrTriggerSound(self.sound)

    self.invPage.inventoryPane.inventory:AddItem(self.prize)

    -- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

function ISCashInVendAction:new(character, vendingMachine, invPage, prize, time)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.maxTime = time
    o.character = character
	-- custom fields
	o.vendingMachine = vendingMachine
    o.invPage = invPage
	o.prize = prize
	return o
end

function RicksMLC_Spawn.RemoveDogTags(invPage, zedName, itemList)
    local vendingMachineItemContainer = invPage.inventoryPane.inventory
    local vendingMachine = vendingMachineItemContainer:getParent()
    local time = 80
    for i = 1, #itemList do
        local action = ISCashInDogTagAction:new(getPlayer(), vendingMachine, invPage, itemList[i], time)
        ISTimedActionQueue.add(action)
    end
end

function RicksMLC_Spawn.AddPrize(invPage)
    --local type = "Acorn"
    local type = RicksMLC_VendingMachineConfig.Instance():GetRandomPrize()
    local prize = InventoryItemFactory.CreateItem(type)
    local vendingMachineItemContainer = invPage.inventoryPane.inventory
    local vendingMachine = vendingMachineItemContainer:getParent()
    local time = 100
    local action = ISCashInVendAction:new(getPlayer(), vendingMachine, invPage, prize, time)
    ISTimedActionQueue.add(action)
end

function RicksMLC_Spawn.ParseDogTag(fullName)
    local zedName, zedId, zedCount = string.match(fullName, "%:%s([%a%s%.%-%_%']+)%s%((%d+)%sof%s(%d+)%)")
    if not (zedName and zedId and zedCount) then return nil end
    return {zedName..zedCount, tonumber(zedCount), tonumber(zedId)}
end

function RicksMLC_Spawn.QueueClaimPrizeActions(invPage, zomName, itemList)
    RicksMLC_Spawn.RemoveDogTags(invPage, zomName, itemList)
    RicksMLC_Spawn.AddPrize(invPage)
end

local spawnName = 1
local numZombies = 2
local spawnId = 3
local zCashInCount = 1
function RicksMLC_Spawn:CashIn()
    --DebugLog.log(DebugType.Mod, "RicksMLC_Spawn:CashIn()")
    --Note: self is the ISInventoryPage

    local dogtags = {}
    local it = self.inventoryPane.inventory:getItems()
    for i = 0, it:size()-1 do
        local item = it:get(i)
        if item:getType() == "Necklace_DogTag" then
            local dogTagData = RicksMLC_Spawn.ParseDogTag(item:getName())
            if dogTagData then
                if dogtags[dogTagData[spawnName]] == nil then
                    dogtags[dogTagData[spawnName]] = { dogTagData[numZombies], {} }
                end
                dogtags[dogTagData[spawnName]][2][dogTagData[spawnId]] = item
            end
        end
    end
    for zomName, v in pairs(dogtags) do
        local allZedsAccounted = true
        for j = 1, v[1] do
            -- Read each in sequence.  Any missed seqence fails test.
            if not v[2][j] then
                DebugLog.log(DebugType.Mod, " Fail.  Missing #" .. tostring(j))
                allZedsAccounted = false
                break
            end
        end
        if allZedsAccounted then
            -- We have a winner.
            RicksMLC_Spawn.QueueClaimPrizeActions(self, zomName, v[2])
        end
    end
end

function RicksMLC_Spawn.AddCashInButtonIfNeeded(invPage)
    if invPage.cashIn then return end

    invPage.cashIn = ISButton:new(invPage.lootAll:getRight() + 16, 0, 50, invPage:titleBarHeight(), getText("IGUI_RicksMLC_Spawn_CashIn"), invPage, RicksMLC_Spawn.CashIn);
    invPage.cashIn:initialise();
    invPage.cashIn.borderColor.a = 0.0;
    invPage.cashIn.backgroundColor.a = 0.0;
    invPage.cashIn.backgroundColorMouseOver.a = 0.7;
    invPage:addChild(invPage.cashIn);
    invPage.cashIn:setVisible(false);
end

function RicksMLC_Spawn.OnRefreshInventoryWindowContainers(invPage, state)
	-- ISInventoryPage invPage, string State
	if state == "buttonsAdded" then
    	--DebugLog.log(DebugType.Mod, "RicksMLC_Scratch.OnRefreshInventoryWindowContainers() buttonsAdded state")
        -- invPage has an "inventory" which is really an ItemContainer
        -- invPage.inventory.type == "vendingpop", but what about other vending machines? Maybe use title anyway
        -- fridges also have the type "vendingpop", so use the title.
        if not invPage.onCharacter and invPage.title == "Vending Machine" then
            -- add "cash-in" button for vending machines
            RicksMLC_Spawn.AddCashInButtonIfNeeded(invPage)
            invPage.cashIn:setVisible(true)
        elseif invPage.cashIn then
            invPage.cashIn:setVisible(false)
        end
   	end
end

Events.OnRefreshInventoryWindowContainers.Add(RicksMLC_Spawn.OnRefreshInventoryWindowContainers)

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
    RicksMLC_Spawn.CacheOutfits()

    local filename = "VendingConfig.txt"
    local chatScriptFile = RicksMLC_ChatIO:new(RicksMLC_AdHocCmds.GetModName(), RicksMLC_AdHocCmds.GetZomboidPath() .. filename)
    RicksMLC_AdHocCmds.Instance():ScriptFactory(chatScriptFile, immediate, filename)
    RicksMLC_VendingMachineConfig.Instance():Update(chatScriptFile)
end

Events.OnGameStart.Add(RicksMLC_Spawn.Init)