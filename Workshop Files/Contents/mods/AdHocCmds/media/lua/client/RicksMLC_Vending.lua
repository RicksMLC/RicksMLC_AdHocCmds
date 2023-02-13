-- Vending Machine handling

require "ISBasObject"
require "TimedActions/ISTimedActionQueue"

RicksMLC_VendingMachineConfig = ISBaseObject:derive("RicksMLC_VendingMachineConfig")

RicksMLC_VendingConfigInstance = nil
function RicksMLC_VendingMachineConfig.Instance()
    if isClient() then
        -- TODO: Call the server
    end

    if not RicksMLC_VendingConfigInstance then
        RicksMLC_VendingConfigInstance = RicksMLC_VendingMachineConfig:new()
    end
    return RicksMLC_VendingConfigInstance 
end

function RicksMLC_VendingMachineConfig:new(prevConfig, cashIns, prevLevel)
    local o = {}
	setmetatable(o, self)
	self.__index = self

    o.minMaxTiers = {}
    o.tiers = {}
    o.prizes = {}
    o.containers = {}

    o.cashIns = cashIns
    o.prevVendingConfig = prevConfig

    o.pushLevel = 0
    if prevLevel then
        o.pushLevel = prevLevel + 1
    end

    o.tooltipsOn = false
    o.tooltipChatName = nil

    -- Sound params to attract zombies
    o.dogTagCashInRadius = 10
    o.dogTagCashInVolume = 1
    o.dispenseRadius = 20
    o.dispenseVolume = 5

	return o
end

function RicksMLC_VendingMachineConfig:GetPushLevelText()
    local txt = "Default"
    if self.pushLevel > 0 then
        txt = "Level " .. tostring(self.pushLevel) .. ". Remaining: " .. tostring(self.cashIns)
    end
    if self.tooltipChatName then
        txt = txt .. " (" .. self.tooltipChatName .. ")"
    end
    return txt
end

function RicksMLC_VendingMachineConfig:PushConfig(vendingConfigFile, cashIns)
    local newConfig = RicksMLC_VendingMachineConfig:new(self, cashIns, self.pushLevel)
    -- Clear the cashIns so the Update call is not recursive.
    --DebugLog.log(DebugType.Mod, "Pusing Vending Config: cash-ins:" .. tostring(cashIns))
    vendingConfigFile:Set("cashIns", "")
    newConfig:Update(vendingConfigFile)
    RicksMLC_VendingConfigInstance = newConfig
    RicksMLC_Vending.UpdateVendingMachineTooltips()
end

function RicksMLC_VendingMachineConfig:PopConfig()
    RicksMLC_VendingConfigInstance = self.prevVendingConfig
    RicksMLC_Vending.UpdateVendingMachineTooltips()
    --DebugLog.log(DebugType.Mod,  "Popping Vending Config...")
end

function RicksMLC_VendingMachineConfig:PopConfigIfNeeded()
    if self.cashIns then
        self.cashIns = self.cashIns - 1
        if self.cashIns <= 0 then
            self:PopConfig()
        end
    end
end

function RicksMLC_VendingMachineConfig:UpdateAttribute(vendingConfigFile, attrib, attribName, delim)
    local i = 1
    local attribLine = vendingConfigFile:Get(attribName .. tostring(i))
    while attribLine do
        local attribList = RicksMLC_Utils.SplitStr(attribLine, delim)
        attrib[i] = attribList
        i = i + 1
        attribLine = vendingConfigFile:Get(attribName .. tostring(i))
    end
end

function RicksMLC_VendingMachineConfig:UpdateTiers(vendingConfigFile)
    self:UpdateAttribute(vendingConfigFile, self.tiers, "tier", "%-")

    -- Convert the strings from the input file to numbers
    for i = 1, #self.tiers do
        for j = 1, #self.tiers[i] do
            if type(self.tiers[i][j]) == "string" then
                self.tiers[i][j] = tonumber(self.tiers[i][j])
            end
            if j == 1 and (not self.minMaxTiers[1] or self.tiers[i][j] < self.minMaxTiers[1]) then
                self.minMaxTiers[1] = self.tiers[i][j]
            elseif j == 2 and (not self.minMaxTiers[2] or self.tiers[i][j] > self.minMaxTiers[2]) then
                self.minMaxTiers[2] = self.tiers[i][j]
            end
        end
    end
end

function RicksMLC_VendingMachineConfig:UpdatePrizes(vendingConfigFile)
    self:UpdateAttribute(vendingConfigFile, self.prizes, "prizes", ",")
end

function RicksMLC_VendingMachineConfig:MakeContainer(containerList)
    -- Returns: ContainerItem with items.

    local container = InventoryItemFactory.CreateItem(containerList[2])
    for i=3,#containerList do 
        local item = InventoryItemFactory.CreateItem(containerList[i])
        if item then
            container:getInventory():AddItem(item)
        end
    end
    return container
end

function RicksMLC_VendingMachineConfig:AddContainerPrizes(vendingConfigFile)
    -- Special prizes:
    -- Eg: container1=SackOfNuts,EmptySandbag,Acorn,Acorn

    local i = 1
    local attribName = "container"
    local attribLine = vendingConfigFile:Get(attribName .. tostring(i))
    while attribLine do
        local attribList = RicksMLC_Utils.SplitStr(attribLine, ",")
        self.containers[attribList[1]] = self:MakeContainer(attribList)
        i = i + 1
        attribLine = vendingConfigFile:Get(attribName .. tostring(i))
    end
end

function RicksMLC_VendingMachineConfig:UpdateSounds(vendingConfigFile)
    self.dogTagCashInRadius = tonumber(vendingConfigFile:Get("dogTagCashInSoundRadius"))
    self.dogTagCashInVolume = tonumber(vendingConfigFile:Get("dogTagCashInSoundVolume"))
    self.dispenseRadius = tonumber(vendingConfigFile:Get("dispensePrizeSoundRadius"))
    self.dispenseVolume = tonumber(vendingConfigFile:Get("dispensePrizeSoundVolume"))
end

function RicksMLC_VendingMachineConfig:Update(vendingConfigFile)
    --DebugLog.log(DebugType.Mod, "RicksMLC_VendingMachineConfig:Update() ")
    -- Clear the existing tables for re-population

    local cashIns = tonumber(vendingConfigFile:Get("cashIns"))
    if cashIns then
        self:PushConfig(vendingConfigFile, cashIns)
        return
    end

    self.tooltipsOn = (vendingConfigFile:Get("tooltips") == "on")
    self.tooltipChatName = vendingConfigFile:Get("tooltipChatName")

    self.containers = {}
    self.tiers = {}
    self.prizes = {}
    self:AddContainerPrizes(vendingConfigFile) -- Do this first so any defined containers are available for UpdatePrizes()
    self:UpdateTiers(vendingConfigFile)
    self:UpdatePrizes(vendingConfigFile)
    self:UpdateSounds(vendingConfigFile)
end

function RicksMLC_VendingMachineConfig:CalcTierNum(numZombies)
    if #self.tiers == 0 then 
        DebugLog.log(DebugType.Mod, "RicksMLC_VendingMachineConfig:CalcTierNum() Error - no tiers set ")
        return nil
    end
    for i = 1, #self.tiers do
        if numZombies >= self.tiers[i][1] and numZombies <= self.tiers[i][2] then
            return i
        end
    end
    if numZombies < self.minMaxTiers[1] then
        return 1
    elseif numZombies > self.minMaxTiers[2] then
        return #self.tiers
    end
end

function RicksMLC_VendingMachineConfig:GetRandomPrize(numZombies)
    -- Returns: Name of the item to spawn

    local tierNum = self:CalcTierNum(numZombies)
    if not tierNum then return end

    if #self.prizes[tierNum] == 0 then
        DebugLog.log(DebugType.Mod, "RicksMLC_VendingMachineConfig:GetRandomPrize() Error - no prizes in tier " .. tostring(tierNum))
        return
    end
    local rnd = PZMath.roundToInt(ZombRand(1, #self.prizes[tierNum]+1))
    --DebugLog.log(DebugType.Mod, "RicksMLC_VendingMachineConfig:GetRandomPrize() " .. tostring(rnd))
    return self.prizes[tierNum][rnd]
end

------------------------------------------------------------------------------
-- Timed Actions:

-- Dogtag cash in timed action
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
    local vendingMachineConfigInst = RicksMLC_VendingMachineConfig:Instance()

    if vendingMachineConfigInst.dogTagCashInRadius and vendingMachineConfigInst.dogTagCashInVolume then
        addSound(self.vendingMachine,
                 self.vendingMachine:getX(), 
                 self.vendingMachine:getY(), 
                 self.vendingMachine:getZ(), 
                 vendingMachineConfigInst.dogTagCashInRadius, 
                 vendingMachineConfigInst.dogTagCashInVolume)
    end
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

--------------------
-- Vend timed action
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
    local vendingMachineConfigInst = RicksMLC_VendingMachineConfig:Instance()
    if vendingMachineConfigInst.dispenseRadius and vendingMachineConfigInst.dispenseVolume then
        addSound(self.vendingMachine, 
                 self.vendingMachine:getX(), 
                 self.vendingMachine:getY(), 
                 self.vendingMachine:getZ(), 
                 vendingMachineConfigInst.dispenseRadius, 
                 vendingMachineConfigInst.dispenseVolume)
    end
    self.invPage.inventoryPane.inventory:AddItem(self.prize)
    -- Check if this is a config that needs popping
    vendingMachineConfigInst:PopConfigIfNeeded()

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
    o.dispenseRadius = 15
    o.dispenseVolume = 2
	return o
end


RicksMLC_Vending = ISBaseObject:derive("RicksMLC_Vending")
function RicksMLC_Vending.RemoveDogTags(invPage, zedName, itemList)
    local vendingMachineItemContainer = invPage.inventoryPane.inventory
    local vendingMachine = vendingMachineItemContainer:getParent()
    local time = 80
    for i = 1, #itemList do
        local action = ISCashInDogTagAction:new(getPlayer(), vendingMachine, invPage, itemList[i], time)
        ISTimedActionQueue.add(action)
    end
end

function RicksMLC_Vending.AddPrize(invPage, numZombies)
    local prizeType = RicksMLC_VendingMachineConfig.Instance():GetRandomPrize(numZombies)
    local prize = nil
    if type(prizeType) == "string" then
        -- Check for special container item
        local container = RicksMLC_VendingMachineConfig.Instance().containers[prizeType]
        if container then
            prize = container
        else
            prize = InventoryItemFactory.CreateItem(prizeType)
        end
    else
        prize = prizeType
    end
    local vendingMachineItemContainer = invPage.inventoryPane.inventory
    local vendingMachine = vendingMachineItemContainer:getParent()
    local time = 100
    local action = ISCashInVendAction:new(getPlayer(), vendingMachine, invPage, prize, time)
    ISTimedActionQueue.add(action)
end

function RicksMLC_Vending.ParseDogTag(fullName)
    local zedName, zedId, zedCount = string.match(fullName, "%:%s([%a%d%s%.%-%_%']+)%s%((%d+)%sof%s(%d+)%)")
    if not (zedName and zedId and zedCount) then return nil end
    return {zedName..zedCount, tonumber(zedCount), tonumber(zedId)}
end

function RicksMLC_Vending.ClaimPrizeActions(invPage, zomName, numZombies, itemList)
    RicksMLC_Vending.RemoveDogTags(invPage, zomName, itemList)
    RicksMLC_Vending.AddPrize(invPage, numZombies)
end

local spawnName = 1
local numZombies = 2
local spawnId = 3
local zCashInCount = 1
function RicksMLC_Vending:CashInButtonPress()
    --DebugLog.log(DebugType.Mod, "RicksMLC_Vending:CashIn()")
    --Note: self is the ISInventoryPage

    local dogtags = {}
    local it = self.inventoryPane.inventory:getItems()
    for i = 0, it:size()-1 do
        local item = it:get(i)
        if item:getType() == "Necklace_DogTag" then
            local dogTagData = RicksMLC_Vending.ParseDogTag(item:getName())
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
                --DebugLog.log(DebugType.Mod, " Fail.  Missing #" .. tostring(j))
                allZedsAccounted = false
                break
            end
        end
        if allZedsAccounted then
            -- We have a winner.
            RicksMLC_Vending.ClaimPrizeActions(self, zomName, v[1], v[2])
        end
    end
end

function RicksMLC_Vending.UpdateVendingMachineTooltips()
    -- Update the vending machine inventory display page, just in case the player can see it when the tooltip changes.
    local currentLootInventory = getPlayerLoot(getPlayer():getPlayerNum()) -- this is really an InventoryPage?
    if currentLootInventory then
        RicksMLC_Vending.UpdateCashInTooltip(currentLootInventory)
    end
end

function RicksMLC_Vending.UpdateCashInTooltip(invPage)
    if not invPage.cashIn then return end -- The cash in button may not have been created yet

    if not RicksMLC_VendingMachineConfig.Instance().tooltipsOn then
        invPage.cashIn.tooltip = nil 
        return
    end

    local toolTipText = "Currently vending: "
    local pushLevelText = RicksMLC_VendingMachineConfig.Instance():GetPushLevelText()
    if pushLevelText then
        toolTipText = toolTipText .. pushLevelText
    end
    invPage.cashIn.tooltip = toolTipText
end

function RicksMLC_Vending.AddCashInButtonIfNeeded(invPage)
    if not invPage.cashIn then 
    invPage.cashIn = ISButton:new(invPage.lootAll:getRight() + 16, 0, 50, invPage:titleBarHeight(), getText("IGUI_RicksMLC_Vending_CashIn"), invPage, RicksMLC_Vending.CashInButtonPress);
        invPage.cashIn:initialise()
        invPage.cashIn.borderColor.a = 0.0
        invPage.cashIn.backgroundColor.a = 0.0
        invPage.cashIn.backgroundColorMouseOver.a = 0.7
        invPage:addChild(invPage.cashIn)
        invPage.cashIn:setVisible(false)
    end
    RicksMLC_Vending.UpdateCashInTooltip(invPage)
end

function RicksMLC_Vending.OnRefreshInventoryWindowContainers(invPage, state)
	-- ISInventoryPage invPage, string State
	if state == "end" then
    	--DebugLog.log(DebugType.Mod, "RicksMLC_Scratch.OnRefreshInventoryWindowContainers() buttonsAdded state")
        -- invPage has an "inventory" which is really an ItemContainer
        -- invPage.inventory.type == "vendingpop", but what about other vending machines? Maybe use title anyway
        -- fridges also have the type "vendingpop", so I have to use the title.
        if not invPage.onCharacter and invPage.title == "Vending Machine" then
            -- add "cash-in" button for vending machines
            RicksMLC_Vending.AddCashInButtonIfNeeded(invPage)
            invPage.cashIn:setVisible(true)
        elseif invPage.cashIn then
            invPage.cashIn:setVisible(false)
        end
   	end
end

function RicksMLC_Vending.OnGameStart()
    -- TODO: Needs a VendingConfig server
    if isServer() then
        DebugLog.log(DebugType.Mod, "RicksMLC_Vending.OnGameStart() Server")
    elseif isClient() then
        DebugLog.log(DebugType.Mod, "RicksMLC_Vending.OnGameStart() Client")
    else
        DebugLog.log(DebugType.Mod, "RicksMLC_Vending.OnGameStart() stand-alone")
    end
end

Events.OnRefreshInventoryWindowContainers.Add(RicksMLC_Vending.OnRefreshInventoryWindowContainers)
Events.OnGameStart.Add(RicksMLC_Vending.OnGameStart)
