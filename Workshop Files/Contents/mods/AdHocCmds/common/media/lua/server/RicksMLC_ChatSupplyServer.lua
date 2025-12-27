-- RicksMLC Chat Supply Server
--

if isClient() then return end
if not isServer() then return end

local RicksMLC_Commands = {}
RicksMLC_Commands.RicksMLC_ChatSupply = {}

RicksMLC_Commands.RicksMLC_ChatSupply.SupplyAnotherPlayer = function(hostPlayer, args)
    -- DebugLog.log(DebugType.Mod, "RicksMLC_Commands.RicksMLC_ChatSupply.SupplyAnotherPlayer() " .. tostring(args.playerName) .. " itemType: " .. tostring(args.itemType) .. " isGift: " .. tostring(args.isGift))

    if args.playerName then
        local item = nil
        local player = RicksMLC_ServerUtils.GetPlayer(args.playerName)
        if player then
            item = RicksMLC_ChatSupply.SupplyToPlayer(args.itemType, player, args.isGift)
        else
            args.playerName = hostPlayer:getUsername()
            -- DebugLog.log(DebugType.Mod, "RicksMLC_Commands.RicksMLC_ChatSupply. player not found, Send back to host '" .. args.playerName .. "'")
            item = RicksMLC_ChatSupply.SupplyToPlayer(args.itemType, hostPlayer, args.isGift)
        end
        args.itemDisplayName = (item and item:getDisplayName()) or "[unknown item]"
        sendServerCommand(player, "RicksMLC_ChatSupply", "SupplyPlayer", args)
    else
        -- DebugLog.log(DebugType.Mod, "RicksMLC_Commands.RicksMLC_ChatSupply.SupplyAnotherPlayer() Error playerName " .. tostring(args.playerName) .. " not set")
    end
end

local RicksMLC_ChatSupplyServer = {}

RicksMLC_ChatSupplyServer.OnClientCommand = function(moduleName, command, player, args)
    --DebugLog.log(DebugType.Mod, 'RicksMLC_ChatSupplyServer.OnClientCommand() ' .. moduleName .. "." .. command)
    if RicksMLC_Commands[moduleName] and RicksMLC_Commands[moduleName][command] then
 		RicksMLC_Commands[moduleName][command](player, args)
    end
end

Events.OnClientCommand.Add(RicksMLC_ChatSupplyServer.OnClientCommand)