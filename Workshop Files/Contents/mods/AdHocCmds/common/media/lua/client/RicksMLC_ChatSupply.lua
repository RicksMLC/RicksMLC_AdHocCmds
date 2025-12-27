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
    o.isGift = true

	return o
end

function RicksMLC_ChatSupplyConfig:Update(configFile)
    -- DebugLog.log(DebugType.Mod, "RicksMLC_ChatSuppliesConfig:Update() " .. type(self.supplies))
    local i = 1
    self.supplies = {} -- Clear all existing supplies.
    for key, value in pairs(configFile.contentList) do
        if key == "gift" then
            self.isGift = value == "true"
        elseif key ~= "type" and value then
            --DebugLog.log(DebugType.Mod, "  key: '" .. key .. "' value: '" .. value .. "'")
            self.supplies[key] = {}
            local supplyList = RicksMLC_Utils.SplitStr(value, ",")
            for i, itemName in ipairs(supplyList) do
                -- Verify the item exists and only add if found.  This is to handle configurations which include mod items
                local item = instanceItem(itemName)
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
require "RicksMLC_ChatSupplyShared"

function RicksMLC_ChatSupply.SupplyToPlayerFromServer(otherPlayerName, itemType, isGift)
    local args = { playerName = otherPlayerName, itemType = itemType, isGift = isGift }
    sendClientCommand(getPlayer(), 'RicksMLC_ChatSupply', 'SupplyAnotherPlayer', args)
end

function RicksMLC_ChatSupply:Supply(contentList)
    local category = self.supplyFile:Get("category")
    local playerName = self.supplyFile:Get("player")
    local itemType = RicksMLC_ChatSupply.GetRandomItemType(category)
    local item = nil
    if itemType then
        item = instanceItem(itemType)
        if not item then
            RicksMLC_Utils.Think(getPlayer(), "Chat Supply Fail: '" .. itemType .. "' is not here (maybe typo or missing mod item)", 3)
            return
        end
    else
        RicksMLC_Utils.Think(getPlayer(), "No items for category '" .. category .. "' (maybe a typo or missing mod item)", 3)
        return
    end
    if isClient() and playerName then
        RicksMLC_ChatSupply.SupplyToPlayerFromServer(playerName, itemType, RicksMLC_ChatSupplyConfig.Instance().isGift)
    else
        RicksMLC_ChatSupply.SupplyToPlayer(itemType, getPlayer(), RicksMLC_ChatSupplyConfig.Instance().isGift)
    end
end

function RicksMLC_ChatSupply.OnServerCommand(moduleName, command, args)
    -- DebugLog.log(DebugType.Mod, "RicksMLC_ChatSupply.OnServerCommand() '" .. tostring(moduleName) .. "' '" .. tostring(command) .. "'")
    if moduleName and moduleName == "RicksMLC_ChatSupply" and command and command == "SupplyPlayer" then
        if args.playerName and args.playerName == getPlayer():getUsername() then
            RicksMLC_Utils.Think(getPlayer(), "Oh look.  I had a " .. args.itemDisplayName .. " in my shoe", 1)
        else
            ---DebugLog.log(DebugType.Mod, "RicksMLC_ChatSupply.OnServerCommand() Unknown player '" .. args.playerName .. "'")
        end
    end
end

Events.OnServerCommand.Add(RicksMLC_ChatSupply.OnServerCommand)