-- RicksMLC Chat Supply Server
--

if isClient() then return end
if not isServer() then return end

local RicksMLC_Commands = {}
RicksMLC_Commands.RicksMLC_ChatSupply = {}

RicksMLC_Commands.RicksMLC_ChatSupply.SupplyAnotherPlayer = function(hostPlayer, args)
    --DebugLog.log(DebugType.Mod, "RicksMLC_Commands.RicksMLC_ChatSupply.SupplyAnotherPlayer()")
    -- Send a message to the client to supply the player
    if args.playerName then
        player = RicksMLC_ServerUtils.GetPlayer(args.playerName)
        if not player then
            DebugLog.log(DebugType.Mod, "RicksMLC_ChatSupply: Error: player username '" .. args.playerName .. "' not found.  Current users:")
            local playerList = getOnlinePlayers()
            for i = 0, playerList:size()-1 do
                DebugLog.log(DebugType.Mod, "  Username '" .. playerList:get(i):getUsername() .. "'")
                if playerList:get(i):getUsername() == args.playerName then
                    DebugLog.log(DebugType.Mod, "  Username '" .. playerList:get(i):getUsername() .. "' found ¯\_(ツ)_/¯ ")
                    player = playerList:get(i)
                    break
                end
            end
        end
        if player then
            sendServerCommand(player, "RicksMLC_ChatSupply", "SupplyPlayer", args)
        else
            args.playerName = hostPlayer:getUsername()
            DebugLog.log(DebugType.Mod, "RicksMLC_Commands.RicksMLC_ChatSupply. player not found, Send back to host '" .. args.playerName .. "'")
            sendServerCommand(hostPlayer, "RicksMLC_ChatSupply", "SupplyPlayer", args)
        end
    else
        DebugLog.log(DebugType.Mod, "RicksMLC_Commands.RicksMLC_ChatSupply.SupplyAnotherPlayer() Error playerName " .. tostring(args.playerName) .. " not set")
    end
end

local RicksMLC_ChatSupplyServer = {}

RicksMLC_ChatSupplyServer.OnClientCommand = function(moduleName, command, player, args)
    --DebugLog.log(DebugType.Mod, 'RicksMLC_ChatSupplyServer.OnClientCommand() ' .. moduleName .. "." .. command)
    if RicksMLC_Commands[moduleName] and RicksMLC_Commands[moduleName][command] then
         -- FIXME: Comment out when done?
        -- local argStr = ''
 		-- for k,v in pairs(args) do argStr = argStr..' '..k..'='..tostring(v) end
 		-- DebugLog.log(DebugType.Mod, 'received '..moduleName..' '..command..' '..tostring(player)..argStr)

 		RicksMLC_Commands[moduleName][command](player, args)
    end
end

Events.OnClientCommand.Add(RicksMLC_ChatSupplyServer.OnClientCommand)