-- RicksMLC_ChatVsChat.lua
-- Handle the streamer scores and publish results.

require "ISBaseObject"

------------------------------------------------------------------
RicksMLC_DeathNote = ISBaseObject:derive("RicksMLC_DeathNote")
function RicksMLC_DeathNote:new(player, gameTimeStamp)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.player = player
    o.gameTimeStamp = gameTimeStamp
    o.hits = {}
    o.who = {}
    return o
end

------------------------------------------------------------------

RicksMLC_ChatVsChat = ISBaseObject:derive("RicksMLC_ChatVsChat")
RicksMLC_ChatVsChatInstance = nil

function RicksMLC_ChatVsChat.WriteScore()
    local scoreFile = RicksMLC_SharedUtils.WriteFile("ChatVChatScore.txt", true, false)
    if not scoreFile then 
        DebugLog.log(DebugType.Mod, "RicksMLC_ChatVsChat.WriteScore() Error unable to create scoreFile")
        return
    end

end

function RicksMLC_ChatVsChat:AddDeath(player)
    DebugLog.log(DebugType.Mod, "RicksMLC_ChatVsChat:AddDeath()")
    local woundLines = RicksMLC_SpawnStats:Instance():GenerateWoundLines()
    local gameTimeStamp = RicksMLC_SharedUtils.getGameTimeStamp()
    DebugLog.log(DebugType.Mod, "  gameTimeStamp: " .. gameTimeStamp)

    local deathNote = RicksMLC_DeathNote:new(player, gameTimeStamp)
    deathNote.hits = RicksMLC_SpawnStats:Instance():GetZombieHits() -- Client SpawnStats are the "hit" stats for the current player character in this client.

    if not self.deathNotes[player:getUsername()] then
        self.deathNotes[player:getUsername()] = {}
    end
    self.deathNotes[player:getUsername()][gameTimeStamp] = deathNote
    
    self:Dump()
end

function RicksMLC_ChatVsChat:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self

    o.teams = {}
    o.deathNotes = {} -- Player death info. Index by player team name
    o.killNotes = {} -- Player kills info. Index by player team name

    return o
end

function RicksMLC_ChatVsChat:Dump()
    DebugLog.log(DebugType.Mod, "RicksMLC_ChatVsChat:Dump()")
    RicksMLC_SharedUtils.DumpArgs(self.deathNotes, 1, "RicksMLC_ChatVsChat:dump() deathNotes")
    RicksMLC_SharedUtils.DumpArgs(self.killNotes, 1, "RicksMLC_ChatVsChat:dump() killNotes")
end

function RicksMLC_ChatVsChat.OnGameStart()
    if isClient() then
        RicksMLC_ChatVsChatInstance = RicksMLC_ChatVsChat:new()
    end
end

-- TODO: Uncomment to develop and run
--Events.OnGameStart.Add(RicksMLC_ChatVsChat.OnGameStart)