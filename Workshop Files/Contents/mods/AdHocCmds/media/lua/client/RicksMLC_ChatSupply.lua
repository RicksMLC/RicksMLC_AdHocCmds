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
    local i = 1
    self.supplies = {} -- Clear all existing supplies.
    for key, value in pairs(configFile.contentList) do
        if key ~= "type" and value then
            --DebugLog.log(DebugType.Mod, "  key: '" .. key .. "' value: '" .. value .. "'")
            self.supplies[key] = {}
            local supplyList = RicksMLC_Utils.SplitStr(value, ",")
            for i, itemName in ipairs(supplyList) do
                -- Verify the item exists and only add if found.  This is to handle configurations which include mod items
                local item = InventoryItemFactory.CreateItem(itemName)
                if item then
                    self.supplies[key][#self.supplies[key]+1] = itemName
                end
            end
        end
    end
end

function RicksMLC_ChatSupplyConfig:GetRandomSupply(category)
    local prizes = self.supplies[category]
    if not prizes then return nil end

    local rnd = PZMath.roundToInt(ZombRand(1, #prizes+1))
    --DebugLog.log(DebugType.Mod, "RicksMLC_ChatSupplyConfig:GetRandomSupply() " .. tostring(rnd))
    return prizes[rnd]
end

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
    local playerName = self.supplyFile:Get("player")
    if playerName then
        player = getPlayerFromUsername(playerName)
        if not player then
            RicksMLC_Utils.Think(getPlayer(), "Weird? Chat sent supplies to '" .. playerName .. "' but I don't know who that is.", 3)
            DebugLog.log(DebugType.Mod, "RicksMLC_ChatSupply: Error: player username '" .. playerName .. "' not found.  Current users:")
            local playerList = getOnlinePlayers()
            for i = 0, playerList:size()-1 do
                DebugLog.log(DebugType.Mod, "  Username '" .. playerList:get(i):getUsername() .. "'")
            end
            return
        end
    else
        player = getPlayer()
    end
    if category then
        local itemType = RicksMLC_ChatSupplyConfig.Instance():GetRandomSupply(category)
        if itemType then
            local item = InventoryItemFactory.CreateItem(itemType)
            if item then
                player:getInventory():AddItem(item)
                RicksMLC_Utils.Think(player, "Oh look.  I had a " .. item:getDisplayName() .. " in my shoe the whole time", 1)
            else
                RicksMLC_Utils.Think(player, "Chat Supply Fail: '" .. itemType .. "' is not here (maybe typo or missing mod item)", 3)
            end
        else
            RicksMLC_Utils.Think(player, "No items for category '" .. category .. "' (maybe a typo or missing mod item)", 3)
        end
    else
        RicksMLC_Utils.Think(player, "I don't understand what should be in my shoe", 3)
    end
end
