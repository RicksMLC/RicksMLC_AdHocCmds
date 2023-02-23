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
        self:SupplyAnotherPlayer(playerName, category)
        return
    end
    RicksMLC_ChatSupply.SupplyItem(getPlayer(), category)
end

function RicksMLC_ChatSupply.SupplyItem(player, category)
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

function RicksMLC_ChatSupply:SupplyAnotherPlayer(otherPlayerName, category)
    local args = { playerName = otherPlayerName, category = category }
    sendClientCommand(getPlayer(), 'RicksMLC_ChatSupply', 'SupplyAnotherPlayer', args)
end

function RicksMLC_ChatSupply.OnServerCommand(moduleName, command, args)
    --DebugLog.log(DebugType.Mod, "RicksMLC_ChatSupply.OnServerCommand() '" .. tostring(moduleName) .. "' '" .. tostring(command) .. "'")
    if moduleName and moduleName == "RicksMLC_ChatSupply" and command and command == "SupplyPlayer" then
        if args.playerName and args.playerName == getPlayer():getUsername() then
            RicksMLC_ChatSupply.SupplyItem(getPlayer(), args.category)
        else
            DebugLog.log(DebugType.Mod, "RicksMLC_ChatSupply.OnServerCommand() Unknown player '" .. args.playerName .. "'")
        end
    end
end

Events.OnServerCommand.Add(RicksMLC_ChatSupply.OnServerCommand)