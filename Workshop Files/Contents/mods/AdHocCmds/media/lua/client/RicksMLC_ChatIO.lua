-- RicksMLC ChatIO
-- Communicate with Chat using a file
-- Retrieves each line as a key,value pair for a given key, where key is the first entry, and the value can be multple entries:
--      key, {value[, value]...}
--
-- [+] how? https://zomboid-javadoc.com/41.65/zombie/Lua/LuaManager.GlobalObject.html#getModFileWriter(java.lang.String,java.lang.String,boolean,boolean)
--     Looks like args are: getModFileWriter(modName, path, isCreateNew, isAppend)
--
-- https://zomboid-javadoc.com/41.65/

require "ISBaseObject"
RicksMLC_ChatIO = ISBaseObject:derive("RicksMLC_ChatIO");

local function splitstr(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		table.insert(t, str)
	end
	return t
end


function RicksMLC_ChatIO:Save()
	--DebugLog.log(DebugType.Mod, "RicksMLC_ChatIO:Save()")
	local luaFileWriter = getModFileWriter(self.modName, self.saveFilePath, true, false) 
    -- Looks like args are: getModFileWriter(modName, path, isCreateNew, isAppend)
    for key,value in pairs(self.contentList) do
        local line = key
        if type(value) == "table" then
            line = line .. "," .. table.concat(value, ",")
        else
            line = line .. "," .. value
        end
        luaFileWriter:writeln(line)
    end
	luaFileWriter:close()
end

function RicksMLC_ChatIO:Load()
	--DebugLog.log(DebugType.Mod, "RicksMLC_ChatIO:Load()")
	local fileReader = getModFileReader(self.modName, self.saveFilePath, true)
	if fileReader:ready() then
		local line = fileReader:readLine()
        while line ~= nil do
		    --DebugLog.log(DebugType.Mod, "   line: " .. line)
            listLine = splitstr(line, "=")
            local key = listLine[1]
            table.remove(listLine, 1)
            self.contentList[key] = listLine
            line = fileReader:readLine()
        end
	end
	fileReader:close()
end

function RicksMLC_ChatIO:Set(key, value)
    self.contentList[key] = value
end

function RicksMLC_ChatIO:Get(key)
    return self.contentList[key]
end

function RicksMLC_ChatIO:Remove(key)
    self.contentList[key] = nil
end

function RicksMLC_ChatIO:new(modName, saveFilePath)
	local o = {}
	setmetatable(o, self)
	self.__index = self
    
    o.modName = modName
    o.saveFilePath = saveFilePath
    o.contentList = {}

    return o
end
