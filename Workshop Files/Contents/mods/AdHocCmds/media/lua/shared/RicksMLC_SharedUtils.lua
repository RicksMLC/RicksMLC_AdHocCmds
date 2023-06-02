RicksMLC_SharedUtils = {}
RicksMLC_SharedUtils.RicksMLC_ServerCmds = {}

RicksMLC_SharedUtils.OnServerCommand = function(moduleName, command, args)
    --DebugLog.log(DebugType.Mod, 'RicksMLC_SharedUtils.OnClientCommand() ' .. moduleName .. "." .. command)
    if RicksMLC_SharedUtils[moduleName] and RicksMLC_SharedUtils[moduleName][command] then
         -- FIXME: Comment out when done?
        RicksMLC_SpawnCommon.DumpArgs(args, 0, "RicksMLC_SharedUtils.OnServerCommand() '" .. moduleName .. "' '" .. command .. "'")

 		RicksMLC_SharedUtils[moduleName][command](args)
    end
end

local RicksMLC_ModName = "RicksMLC_AdHocCmds"
local ZomboidPath = "./ChatIO/"

function RicksMLC_SharedUtils.RicksMLC_ServerCmds.WriteUserNamesFromServer(args)
	DebugLog.log(DebugType.Mod, "RicksMLC_SharedUtils.WriteUserNamesFromServer()")
	local luaFileWriter = getModFileWriter(RicksMLC_ModName, ZomboidPath .. "usernames.txt", true, false) 
	if luaFileWriter then
        for idx, v in ipairs(args.players) do
            luaFileWriter:writeln(v)
        end
	end
	luaFileWriter:close()
end

Events.OnServerCommand.Add(RicksMLC_SharedUtils.OnServerCommand)
