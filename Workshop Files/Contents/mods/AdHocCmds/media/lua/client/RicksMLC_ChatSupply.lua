require "ISBaseObject"

RicksMLC_ChatSupplyConfig = ISBaseObject:derive("RicksMLC_ChatSupplyConfig")
RicksMLC_ChatSupplyConfigInstance = nil
function RicksMLC_ChatSupplyConfig.Instance()
    if not RicksMLC_ChatSupplyConfigInstance then
        RicksMLC_ChatSupplyConfigInstance = RicksMLC_ChatSupplyConfig:new()
    end
    return RicksMLC_ChatSupplyConfigInstance 
end

function RicksMLC_ChatSupplyConfig:new()
    local o = {}
	setmetatable(o, self)
	self.__index = self

    o.supplies = {}

	return o
end

function RicksMLC_ChatSupplyConfig:Update(configFile)
    DebugLog.log(DebugType.Mod, "RicksMLC_ChatSuppliesConfig:Update() " .. type(self.supplies))
    for key, value in pairs(configFile.contentList) do
        if key ~= "type" and value then
            DebugLog.log(DebugType.Mod, "  key: '" .. key .. "' value: '" .. value .. "'")
            local supplyList = RicksMLC_Utils.SplitStr(value, ",")
            self.supplies[key] = supplyList
        end
    end
end

function RicksMLC_ChatSupplyConfig:GetRandomSupply(category)
    local prizes = self.supplies[category]
    if not prizes then return nil end

    local rnd = ZombRand(1, #prizes+1)
    DebugLog.log(DebugType.Mod, "RicksMLC_ChatSupplyConfig:GetRandomSupply() " .. tostring(rnd))
    return prizes[rnd]
end

function RicksMLC_ChatSupplyConfig.Init()
    RicksMLC_ChatSupplyConfigInstance = RicksMLC_ChatSupplyConfig:new()

    local filename = "ChatSupplyConfig.txt"
    local chatScriptFile = RicksMLC_ChatIO:new(RicksMLC_AdHocCmds.GetModName(), RicksMLC_AdHocCmds.GetZomboidPath() .. filename)
    RicksMLC_AdHocCmds.Instance():ScriptFactory(chatScriptFile, immediate, filename)
    RicksMLC_ChatSupplyConfig.Instance():Update(chatScriptFile)
end

Events.OnGameStart.Add(RicksMLC_ChatSupplyConfig.Init)

------------------------------------------------------------------------------------

RicksMLC_ChatSupply = ISBaseObject:derive("RicksMLC_ChatSupply");

function RicksMLC_ChatSupply:new(supplyFile)
	local o ={}
	setmetatable(o, self)
	self.__index = self

	o.supplyFile = supplyFile

	return o
end

function RicksMLC_ChatSupply:Supply(contentList)
    local category = self.supplyFile:Get("category")
    if category then
        local itemType = RicksMLC_ChatSupplyConfig.Instance():GetRandomSupply(category)
        if itemType then
            local item = InventoryItemFactory.CreateItem(itemType)
            if item then
                getPlayer():getInventory():AddItem(item)
                RicksMLC_Utils.Think(getPlayer(), "Oh look.  I had a " .. item:getDisplayName() .. " in my shoe the whole time", 1)
            end
        else
            RicksMLC_Utils.Think(getPlayer(), "No item returned for category '" .. category .. "'", 3)
        end
    else
        RicksMLC_Utils.Think(getPlayer(), "I don't understand what should be in my shoe", 3)
    end
end

