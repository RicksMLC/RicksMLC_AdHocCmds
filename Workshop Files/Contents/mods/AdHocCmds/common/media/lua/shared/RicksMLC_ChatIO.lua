-- RicksMLC ChatIO
-- Communicate with Chat using a file
-- Retrieves each line as a key,value pair for a given key, where key is the first entry, and the value can be multple entries:
--      key, {value[, value]...}
--
-- [+] how? https://zomboid-javadoc.com/41.65/zombie/Lua/LuaManager.GlobalObject.html#getModFileWriter(java.lang.String,java.lang.String,boolean,boolean)
--     Looks like args are: getModFileWriter(modName, path, isCreateNew, isAppend)
--
-- Core.getMyDocumentFolder() .. getFileSeparator() .. "mods" .. getFileSeparator() .. "RicksMLC_AdHocCmds_Data"
-- https://projectzomboid.com/modding/index.html

require "ISBaseObject"
require "RicksMLC_SharedUtils"
RicksMLC_ChatIO = ISBaseObject:derive("RicksMLC_ChatIO");

--local basePath = "Lua/RicksMLC_AdHocCmds/"
function RicksMLC_ChatIO:new(modName, saveFilePath)
	local o = ISBaseObject.new(self)
    
    o.modName = modName
    o.saveFilePath = saveFilePath
    o.contentList = {}
	o.commentLines = {}

    return o
end

function RicksMLC_ChatIO.CloneChatIO(origChatIO)
	local chatIO = RicksMLC_ChatIO:new(origChatIO.modName, origChatIO.saveFilePath)
	chatIO.contentList = origChatIO.contentList
	chatIO.commentLines = origChatIO.commentLines
	return chatIO
end

function RicksMLC_ChatIO:Save(delim, isCommentOut)
	--DebugLog.log(DebugType.Mod, "RicksMLC_ChatIO:Save()" .. self.saveFilePath)
	--FIXME: Remove when final path is nailed down.
	local luaFileWriter = getModFileWriter(self.modName, self.saveFilePath, true, false) 
	--local luaFileWriter = getFileWriter(self.saveFilePath, false, true) 
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
			if value ~= nil then
				--DebugLog.log(DebugType.Mod, "key: '" .. tostring(key) .. "' delim '" .. tostring(delim) .. "' value: " .. (value or "nil"))
            	line = line .. delim .. value
			else
				line = line .. delim
			end
        end
		if isCommentOut and line:find("hourly") == nil then
			line = commentOutSring .. line
		end
        luaFileWriter:writeln(line)
    end
	for i, value in ipairs(self.commentLines) do
		luaFileWriter:writeln(value)
	end
	luaFileWriter:close()
end


function RicksMLC_ChatIO:RevealModWriterPath()
	DebugLog.log(DebugType.Mod, "RicksMLC_ChatIO:Load() Writing debug_path.txt file to the getModFileWriter path")
	local debugFileWriter = getFileWriter("debug_path.txt", false, true)
	debugFileWriter:writeln("modId: '" .. self.modName )
	debugFileWriter:close()
	written = true
end

function RicksMLC_ChatIO:Load(delim, resetComments)
	--self:DebugModId()
	--DebugLog.log(DebugType.Mod, "RicksMLC_ChatIO:Load()" .. " modId: '" .. self.modName .. "' path: '" .. self.saveFilePath .. "'")
	--self:RevealModWriterPath()
	--FIXME: Remove when final path is nailed down.
	local fileReader = getModFileReader(self.modName, self.saveFilePath, true)
	--local fileReader = getFileReader(self.saveFilePath, true)
	if fileReader then
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
					listLine = RicksMLC_Utils.SplitStr(line, delim)
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
	else
		DebugLog.log(DebugType.Mod, "RicksMLC_ChatIO:Load() Error: no file reader. modId: '" .. self.modName .. "' path: '" .. self.saveFilePath .. "'")
	end
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
