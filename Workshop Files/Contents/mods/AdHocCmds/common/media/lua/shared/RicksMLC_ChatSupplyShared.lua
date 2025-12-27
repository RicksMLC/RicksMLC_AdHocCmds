require "ISBaseObject"
------------------------------------------------------------------------------------

RicksMLC_ChatSupply = ISBaseObject:derive("RicksMLC_ChatSupply");

function RicksMLC_ChatSupply:new(supplyFile)
	local o ={}
	setmetatable(o, self)
	self.__index = self

	o.supplyFile = supplyFile

	return o
end

Presents = {}
Presents[1] = "Present_ExtraSmall"
Presents[2] = "Present_Small"
Presents[5] = "Present_Medium"
Presents[10] = "Present_Large"
Presents[20] = "Present_ExtraLarge"

function RicksMLC_ChatSupply.SupplyGiftBox(item, player)
    local weight = item:getWeight()
    local box = nil
    for key, value in pairs(Presents) do
        if key > weight then
            box = value
            break
        end
    end
    if box then
        boxItem = instanceItem(box)
        local itemInv = boxItem:getItemContainer()
        itemInv:addItem(item)
        return boxItem
    end
    -- The item is too big to gift wrap
    return item
end

function RicksMLC_ChatSupply.SupplyToPlayer(itemType, player, isGift)
    local item = instanceItem(itemType)
    if not item then
        DebugLog.log(DebugType.Mod, "Chat Supply Fail: '" .. itemType .. "' is not here (maybe typo or missing mod item)")
        return nil
    end

    if isGift then
        -- DebugLog.log(DebugType.Mod, "RicksMLC_ChatSupply.SupplyToPlayer() Gift wrapping item " .. item:getDisplayName() .. " for " .. player:getUsername())
        item = RicksMLC_ChatSupply.SupplyGiftBox(item, player)
    end
    -- DebugLog.log(DebugType.Mod, "RicksMLC_ChatSupply.SupplyToPlayer() item " .. item:getDisplayName() .. " for " .. player:getUsername())
    return RicksMLC_ChatSupply.SupplyActualItem(player, item)
end

function RicksMLC_ChatSupply.GetRandomItemType(category)
    if category then
        local itemType = RicksMLC_ChatSupplyConfig.Instance():GetRandomSupply(category)
        return itemType
    end
    DebugLog.log(DebugType.Mod, "I don't understand this category '" .. tostring(category) .. "' which should be in my shoe")
    return nil
end

function RicksMLC_ChatSupply.SupplyItem(player, itemType)
    local item = instanceItem(itemType)
    if item then
        return RicksMLC_ChatSupply.SupplyActualItem(player, item)
    end
    DebugLog.log(DebugType.Mod, "Chat Supply Fail: '" .. itemType .. "' is not here (maybe typo or missing mod item)")
end

function RicksMLC_ChatSupply.SupplyActualItem(player, item)
    if not isClient() then
        -- DebugLog.log(DebugType.Mod, "RicksMLC_ChatSupply.SupplyActualItem() Supplying item " .. item:getDisplayName() .. " to player " .. (isServer() and player:getUsername()) or "")
        player:getInventory():AddItem(item)
        sendAddItemToContainer(player:getInventory(), item)
        return item
    end
end
