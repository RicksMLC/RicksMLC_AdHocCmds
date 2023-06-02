-- RicksMLC_ServerUtils.lua
if not isServer() then return end


RicksMLC_ServerUtils = {}
function RicksMLC_ServerUtils.GetPlayer(userName, verbose)
    local player = getPlayerFromUsername(userName)
    if not player then
        if verbose then DebugLog.log(DebugType.Mod, "RicksMLC_ServerUtils.GetPlayer() Error: player username '" .. userName .. "' not found.  Current users:") end
        local playerList = getOnlinePlayers()
        for i = 0, playerList:size()-1 do
            if verbose then  DebugLog.log(DebugType.Mod, "  Username '" .. playerList:get(i):getUsername() .. "'")  end
            if playerList:get(i):getUsername() == userName then
                if verbose then DebugLog.log(DebugType.Mod, "  Username '" .. playerList:get(i):getUsername() .. "' found ¯\_(ツ)_/¯ ") end
                player = playerList:get(i)
                break
            end
        end
    end
    return player
end

-----------------------------------------------------

local hostPlayer = nil
RicksMLC_ServerUtils.RicksMLC_ServerCmds = {}

RicksMLC_ServerUtils.RicksMLC_ServerCmds.PlayerConnectionUpdate = function(player, args)
    DebugLog.log(DebugType.Mod, 'RicksMLC_ServerUtils.RicksMLC_ServerCmds.PlayerConnectionUpdate()')

    RicksMLC_ServerUtils.WriteUserNames()
end

RicksMLC_ServerUtils.OnClientCommand = function(moduleName, command, player, args)
    --DebugLog.log(DebugType.Mod, 'RicksMLC_ServerUtils.OnClientCommand() ' .. moduleName .. "." .. command)
    if RicksMLC_ServerUtils[moduleName] and RicksMLC_ServerUtils[moduleName][command] then
        --RicksMLC_SpawnCommon.DumpArgs(args, 0, "RicksMLC_ServerUtils.OnClientCommand() '" .. moduleName .. "' '" .. command .. "'")

 		RicksMLC_ServerUtils[moduleName][command](player, args)
    end
end

local RicksMLC_ModName = "RicksMLC_AdHocCmds"
local ZomboidPath = "./ChatIO/"

function RicksMLC_ServerUtils.WriteUserNames()
	--DebugLog.log(DebugType.Mod, "RicksMLC_ServerUtils.WriteUserNames()")
    local playerList = getOnlinePlayers()
    local players = {}
    for i = 0, playerList:size()-1 do
        players[#players+1] = playerList:get(i):getUsername()
    end
    local args = { players = players }
    sendServerCommand("RicksMLC_ServerCmds", "WriteUserNamesFromServer", args)
end

Events.OnClientCommand.Add(RicksMLC_ServerUtils.OnClientCommand)
