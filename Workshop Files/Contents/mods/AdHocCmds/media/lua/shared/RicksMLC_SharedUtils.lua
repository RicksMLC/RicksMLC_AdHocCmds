RicksMLC_SharedUtils = {}
RicksMLC_SharedUtils.RicksMLC_ServerCmds = {}

RicksMLC_SharedUtils.OnServerCommand = function(moduleName, command, args)
    --DebugLog.log(DebugType.Mod, 'RicksMLC_SharedUtils.OnClientCommand() ' .. moduleName .. "." .. command)
    if RicksMLC_SharedUtils[moduleName] and RicksMLC_SharedUtils[moduleName][command] then
         -- FIXME: Comment out when done?
        RicksMLC_SharedUtils.DumpArgs(args, 0, "RicksMLC_SharedUtils.OnServerCommand() '" .. moduleName .. "' '" .. command .. "'")

 		RicksMLC_SharedUtils[moduleName][command](args)
    end
end

local RicksMLC_ModName = "RicksMLC_AdHocCmds"
local ZomboidPath = "./ChatIO/"

-- Make a consistent save/load file path
--    eg: Core.getMyDocumentFolder() .. getFileSeparator() .. "mods" .. getFileSeparator() .. "RicksMLC_AdHocCmds_Data"
-- FIXME: This doesn't really work- Remove?
-- local RicksMLC_UserDir = Core.getMyDocumentFolder() .. getFileSeparator() .. "mods" .. getFileSeparator() .. "RicksMLC"
-- local RicksMLC_AdHocCmdsDir = RicksMLC_UserDir .. getFileSeparator() .. "AdHocCmds"
-- function RicksMLC_SharedUtils.FileWriter(filename, bCreateIfNull, bAppend)
--     DebugLog.log(DebugType.Mod, "RicksMLC_SharedUtils.FileWriter()" .. RicksMLC_AdHocCmdsDir .. getFileSeparator() .. filename)
--     return getFileWriter(RicksMLC_AdHocCmdsDir .. getFileSeparator() .. filename, bCreateIfNull, bAppend)
-- end

-- function RicksMLC_SharedUtils.FileReader(filename)
--     DebugLog.log(DebugType.Mod, "RicksMLC_SharedUtils.FileReader()" .. RicksMLC_AdHocCmdsDir .. getFileSeparator() .. filename)
--     return getFileReader(RicksMLC_AdHocCmdsDir .. getFileSeparator() .. filename)
-- end

-- TODO: Change to the RicksMLC_SharedUtils.FileWriter
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

function RicksMLC_SharedUtils.getGameTimeStamp()
    return tostring(getGameTime():getYear()) .. "-" .. tostring(getGameTime():getMonth()) .. "-" .. tostring(getGameTime():getDay()) .. " " .. tostring(getGameTime():getHour()) .. ":" .. tostring(getGameTime():getMinutes())
end


local function is_array(t)
    return t ~= nil and type(t) == 'table' and t[1] ~= nil
end

function RicksMLC_SharedUtils.DumpArgs(args, lvl, desc)
    if not lvl then lvl = 0 end
    if lvl == 0 then
        DebugLog.log(DebugType.Mod, "RicksMLC_SharedUtils.DumpArgs() " .. desc .. " begin")
        if not args then DebugLog.log(DebugType.Mod, " args is nil.") return end
    end
    local argIndent = ''
    for i = 1, lvl do
        argIndent = argIndent .. "   "
    end
    if is_array(args) then
        for idx, v in ipairs(args) do 
            local argStr = argIndent .. ' [' .. idx .. ']=' .. tostring(v) 
            DebugLog.log(DebugType.Mod, argStr)
            if type(v) == "table" then
                RicksMLC_SharedUtils.DumpArgs(v, lvl + 1)
            end
        end
    elseif type(args) == "table" then
        for k, v in pairs(args) do 
            local argStr = argIndent .. ' ' .. k .. '=' .. tostring(v) 
            DebugLog.log(DebugType.Mod, argStr)
            if type(v) == "table" then
                RicksMLC_SharedUtils.DumpArgs(v, lvl + 1)
            end
        end
    end
    if lvl == 0 then
        DebugLog.log(DebugType.Mod, "RicksMLC_SharedUtils.DumpArgs() " .. desc .. " end")
    end
end


Events.OnServerCommand.Add(RicksMLC_SharedUtils.OnServerCommand)
