-- RicksMLC ChatIO
-- Communicate with Chat using a file
-- Retrieves each line as a key,value pair for a given key, where key is the first entry, and the value can be multple entries:
--      key, {value[, value]...}
--
-- [+] how? https://zomboid-javadoc.com/41.65/zombie/Lua/LuaManager.GlobalObject.html#getModFileWriter(java.lang.String,java.lang.String,boolean,boolean)
--     Looks like args are: getModFileWriter(modName, path, isCreateNew, isAppend)
--
-- https://projectzomboid.com/modding/index.html

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

function RicksMLC_ChatIO:new(modName, saveFilePath)
	local o = {}
	setmetatable(o, self)
	self.__index = self
    
    o.modName = modName
    o.saveFilePath = saveFilePath
    o.contentList = {}
	o.commentLines = {}

    return o
end

function RicksMLC_ChatIO:Save(delim, isCommentOut)
	--DebugLog.log(DebugType.Mod, "RicksMLC_ChatIO:Save()")
	local luaFileWriter = getModFileWriter(self.modName, self.saveFilePath, true, false) 
	-- Looks like args are: getModFileWriter(modName, path, isCreateNew, isAppend)
	local commentOutString = ""
	if isCommentOut then
		commentOutSring = "--"
	end
    for key,value in pairs(self.contentList) do
        local line = key
        if type(value) == "table" then
            line = line .. delim .. table.concat(value, ",")
        else
            line = line .. delim .. value
        end
		if line:find("hourly") == nil then
			line = commentOutSring .. line
		end
        luaFileWriter:writeln(line)
    end
	for i, value in ipairs(self.commentLines) do
		luaFileWriter:writeln(value)
	end
	luaFileWriter:close()
end

function RicksMLC_ChatIO:Load(delim, resetComments)
	--DebugLog.log(DebugType.Mod, "RicksMLC_ChatIO:Load()")
	local fileReader = getModFileReader(self.modName, self.saveFilePath, true)
	if fileReader:ready() then
		self.contentList = {}
		self.commentLines = {}
		local line = fileReader:readLine()
        while line ~= nil do
		    --DebugLog.log(DebugType.Mod, "   line: " .. line)
			if resetComments then 
				if line:find("%-%-") == 1 then
					line = line:sub(3)
				end
			end
			local i = line:find("%-%-")
			if not i or i ~= 1 then
				listLine = splitstr(line, delim)
				local key = listLine[1]
				table.remove(listLine, 1)
				self.contentList[key] = listLine[1]
			else
				self.commentLines[#self.commentLines + 1] = line
			end
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
