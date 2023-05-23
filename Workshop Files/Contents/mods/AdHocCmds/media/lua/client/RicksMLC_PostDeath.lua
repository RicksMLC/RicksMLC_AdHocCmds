-- PostDeath - Add the list of zombie names who damaged the player.

require "ISBaseObject"

RicksMLC_SpawnStats = ISBaseObject:derive(RicksMLC_SpawnStats)
RicksMLC_SpawnStatsInstance = nil
function RicksMLC_SpawnStats:Instance()
    if not RicksMLC_SpawnStatsInstance then
        RicksMLC_SpawnStatsInstance = RicksMLC_SpawnStats:new()
    end
    return RicksMLC_SpawnStatsInstance
end

function RicksMLC_SpawnStats:new()
    local o = RicksMLC_ChatScriptFile:new()
	setmetatable(o, self)
	self.__index = self

    o.spawnedZombies = {} -- Key: Zombie Id, value: spawners index
    o.spawners = {} -- array of chat people.  key: index, value: chat name, {[injury]} list of inflicted injuries to the player
    o.wounds = {}
    o.wounds["bitten"] = {}
    o.wounds["cut"] = {}
    o.wounds["scratched"] = {}
    o.wounds["deepWounded"] = {}
    return o
end

function RicksMLC_SpawnStats:ResetWounds()
    self.wounds = {}
    self.wounds["bitten"] = {}
    self.wounds["cut"] = {}
    self.wounds["scratched"] = {}
    self.wounds["deepWounded"] = {}
    for i = 1, #self.spawners do
        self.spawners[i][2] = {}
    end
end

-- Store the chatNames in an array so the idx can be used as the value for the spawned zombies spawner data
function RicksMLC_SpawnStats:AddZombies(chatName, zombieList)
    for i, v in ipairs(self.spawners) do
        if v[1] == chatName then
            for j=0, zombieList:size()-1 do
                local zombie = zombieList:get(j)
                local zombieId = zombie:getUID()
                self.spawnedZombies[zombieId] = i
            end
            return
        end
    end
    -- If we get here the chatName is not in the list yet, so add it
    self.spawners[#self.spawners+1] = {chatName, {}}
    for k=0, zombieList:size()-1 do
        local zombie = zombieList:get(k)
        local zombieId = zombie:getUID()
        self.spawnedZombies[zombieId] = #self.spawners
    end
end

-- The server cannot send an IsoZombie to the client, so it is sending the ID instead.
function RicksMLC_SpawnStats:AddZombiesFromServer(chatName, zombieList)
    for i, v in ipairs(self.spawners) do
        if v[1] == chatName then
            for k, v in pairs(zombieList) do
                local zombieId = v.zombieId
                self.spawnedZombies[zombieId] = i
            end
            return
        end
    end
    -- If we get here the chatName is not in the list yet, so add it
    self.spawners[#self.spawners+1] = {chatName, {}}
    for k, v in pairs(zombieList) do
        local zombieId = v.zombieId
        self.spawnedZombies[zombieId] = #self.spawners
    end
end


function RicksMLC_SpawnStats:RecordWound(zombieId, woundType)
    local spawnerIdx = self.spawnedZombies[zombieId]
    if not spawnerIdx then
        --FIXME: Check if this is a player?
    end
    if spawnerIdx then
        if self.spawners[spawnerIdx][2][woundType] then
            self.spawners[spawnerIdx][2][woundType] = self.spawners[spawnerIdx][2][woundType] + 1
        else
            self.spawners[spawnerIdx][2][woundType] = 1
        end
    end
end

function RicksMLC_SpawnStats:GenerateWoundLines()
    local lines = {}
    for wound, inflictors in pairs(self.wounds) do
        lines[wound] = {}
        for who, count in pairs(inflictors) do
            lines[wound][#lines[wound]+1] = {who, count}
        end
    end
    return lines
end

function RicksMLC_SpawnStats:CollateWounds()
    for i, spawnerInfo in ipairs(self.spawners) do
        local spawnName = spawnerInfo[1]
        local wounds = spawnerInfo[2] -- wounds inflicted by spawner
        for wound, count in pairs(wounds) do
            self.wounds[wound][spawnName] = count
        end
    end
end

function RicksMLC_SpawnStats:Dump()
    DebugLog.log(DebugType.Mod, "RicksMLC_SpawnStats:Dump() Spawners")
    for i, spawnerInfo in ipairs(self.spawners) do
        local spawnName = spawnerInfo[1]
        local txt = spawnName -- spawner name
        local wounds = spawnerInfo[2] -- wounds inflicted by spawner
        for wound, count in pairs(wounds) do
            txt = txt .. " " .. wound .. ": " .. tostring(count)
            self.wounds[wound][spawnName] = count
        end
        DebugLog.log(DebugType.Mod, "  " .. txt)
    end
    DebugLog.log(DebugType.Mod, "RicksMLC_SpawnStats:Dump() wounds")
    for wound, inflictors in pairs(self.wounds) do
        DebugLog.log(DebugType.Mod, "   " .. wound .. ":")
        for who, count in pairs(inflictors) do
            DebugLog.log(DebugType.Mod, "    " .. who .. " x " .. tostring(count))
        end
    end

    DebugLog.log(DebugType.Mod, "RicksMLC_SpawnStats:Dump() end")
end

-----------------------------------------------------------------------
RicksMLC_PostDeath = ISBaseObject:derive("RicksMLC_PostDeath");
RicksMLC_PostDeathInstance = nil

function RicksMLC_PostDeath.Instance()
    if not RicksMLC_PostDeathInstance then
        RicksMLC_PostDeathInstance = RicksMLC_PostDeath:new()
    end
    return RicksMLC_PostDeathInstance
end

function RicksMLC_PostDeath:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self
    
    o.wounds = {}

    return o
end

function RicksMLC_PostDeath:ResetWounds()
    self.wounds = {}
end

function RicksMLC_PostDeath.OnKeyPressed(key)

    if key == Keyboard.KEY_F9 then
		RicksMLC_PostDeath.TestUI()
    end
end

function RicksMLC_PostDeath.TestUI()
    ISPostDeathUI.OnPlayerDeath(getPlayer())
    RicksMLC_PostDeath.OnPostDeath(getPlayer())
end

function RicksMLC_PostDeath.OnPostDeath(playerObj)
    local uiInst = ISPostDeathUI.instance

    local playerNum = playerObj:getPlayerNum()
    local panel = ISPostDeathUI.instance[playerNum]
    if panel then
        RicksMLC_SpawnStats:Instance():CollateWounds()
        local lines = RicksMLC_SpawnStats:Instance():GenerateWoundLines()

        if #lines["bitten"] > 0 then
            table.insert(panel.lines, "_____________________________________")
            table.insert(panel.lines, "Biters:                                                                     ")
            for key, inflictors in pairs(lines["bitten"]) do
                table.insert(panel.lines, "   " .. inflictors[1] .. " x " .. tostring(inflictors[2]))
            end

        end
        if #lines["cut"] > 0 then
            table.insert(panel.lines, "_____________________________________")
            table.insert(panel.lines, "Lacerators:                                                           ")
            for key, inflictors in pairs(lines["cut"]) do
                table.insert(panel.lines, "   " .. inflictors[1] .. " x " .. tostring(inflictors[2]))
            end
        end
        if #lines["scratched"] > 0 then
            table.insert(panel.lines, "_____________________________________")
            table.insert(panel.lines, "Scratchers:                                                           ")
            for key, inflictors in pairs(lines["scratched"]) do
                table.insert(panel.lines, "   " .. inflictors[1] .. " x " .. tostring(inflictors[2]))
            end
        end
        if #lines["deepWounded"] > 0 then
            table.insert(panel.lines, "_____________________________________")
            table.insert(panel.lines, "Deep Wounders:                                                 ")
            for key, inflictors in pairs(lines["deepWounded"]) do
                table.insert(panel.lines, "   " .. inflictors[1] .. " x " .. tostring(inflictors[2]))
            end
        end
    end
  
end

function RicksMLC_PostDeath:RecordNewWound(bodyPartType, zombieId, woundId, wound)
    local bodyPartTypeIdx = BodyPartType.ToIndex(bodyPartType)
    if not self.wounds[bodyPartTypeIdx] then
        self.wounds[bodyPartTypeIdx] = {}
    end
    --DebugLog.log(DebugType.Mod, "RecordNewWound(): '" .. tostring(self.wounds[bodyPartTypeIdx][woundId]) .. "'")
    if not self.wounds[bodyPartTypeIdx][woundId] then
        --DebugLog.log(DebugType.Mod, "    New Wound of type: " .. tostring(woundId) .. " " .. wound)
        self.wounds[bodyPartTypeIdx][woundId] = zombieId
        RicksMLC_SpawnStats:Instance():RecordWound(zombieId, wound)
    end
end

function RicksMLC_PostDeath:RecordNewWounds(bodyPartType, isBitten, isCut, isScratched, isDeepWounded, zombieId)
    -- TODO: Detect Infection
    if isBitten then
        self:RecordNewWound(bodyPartType, zombieId, 1, "bitten")
    end
    if isCut then
        self:RecordNewWound(bodyPartType, zombieId, 2, "cut")
    end
    if isScratched then
        self:RecordNewWound(bodyPartType, zombieId, 3, "scratched")
    end
    if isDeepWounded then
        self:RecordNewWound(bodyPartType, zombieId, 4, "deepWounded")
    end
end

-- Expeimental code: Commented out for now.
-- TODO: Get the meth:invoke() working.
-- function RicksMLC_PostDeath:AttackerReanimatedPlayer(zombie)
--     local player = self:GetFunctionValueFromIsoZombie(zombie, "getReanimatedPlayer")
--     if player then
--         DebugLog.log(DebugType.Mod, "RicksMLC_PostDeath:AttackerReanimatedPlayer() Player: '" .. player:getDisplayName() .. "'")
--         return true
--     end
--     return false
-- end
--
-- function RicksMLC_PostDeath:GetFunctionValueFromIsoZombie(zombie, fName)
--     if not instanceof(zombie, "IsoZombie") then
--         return nil
--     end
--     local c = getNumClassFunctions(zombie);
--     for i=0, c-1 do
--         local meth = getClassFunction(zombie, i);
--         if meth:getName() == fName then
--             return meth:invoke(zombie)
--         end
--     end
-- end
--
-- -- FIXME: Experimental test code for working out subclass fields
-- function RicksMLC_PostDeath:GetZombieIdFromAttacker(attacker)
--     if not instanceof(attacker, "IsoZombie") then
--         return nil
--     end
--     local c = getNumClassFields(attacker);
--     for i=0, c-1 do
--         local meth = getClassField(attacker, i);
--         DebugLog.log(DebugType.Mod, "RicksMLC_PostDeath:GetZombieIdFromAttacker() '" .. meth:getName() .. "'")
--         if meth:getName() == "ZombieID" then
--             local val = KahluaUtil.rawTostring2(getClassFieldVal(attacker, meth));
--             return val
--             --if(val == nil) then val = "nil" end
--             --local s = tabToX(meth:getType():getSimpleName(), 18) .. " " .. tabToX(meth:getName(), 24) .. " " .. tabToX(val, 24);
--             --self.objectView:addItem(s, meth);
--         end
--     end
-- end

function RicksMLC_PostDeath:GetZombieId(attacker)
    -- FIXME: Uncomment this to work out the player
    -- if self:AttackerReanimatedPlayer(attacker) then return end

    if isClient() or isServer() then
        -- For multiplayer the UID() is not the same on different clients and the server, so use the online id
        return attacker:getOnlineID()
    end
    -- This is a single player, so the UID is valid.  The online id is always -1 in single player
    return attacker:getUID()
end

function RicksMLC_PostDeath:HandleOnAIStateChange(character, newState, oldState)
    if character ~= getPlayer() then return end

    local oldStateName = character:getPreviousStateName()
    local newStateName = character:getCurrentStateName()
    --DebugLog.log(DebugType.Mod, "RicksMLC_PostDeath.OnAIStateChange() old: '" .. tostring(oldStateName) .. "' new: '" .. newStateName .. "'")

    -- Zombie Damage Player Sequence:
    --  Zombie: LungeState -> AttackState
    --  Player: IdleState(?) -> PlayerHitReactionState
    if newStateName == "PlayerHitReactionState" then
        local attacker = character:getAttackedBy() -- make sure this is a zombie, and not another player?
        -- FIXME: Remove when players can wound other players
        if not attacker:isZombie() then return end

        local bodyDamage = character:getBodyDamage()
        local bodyPartList = bodyDamage:getBodyParts()

        for i=0, bodyPartList:size()-1 do
            local bodyPart = bodyPartList:get(i)
            local bodyPartName = BodyPartType.getDisplayName(bodyPart:getType())
            local bodyPartType = bodyPart:getType()
            self:RecordNewWounds(
                bodyPartType,
                bodyDamage:IsBitten(bodyPartType),
                bodyDamage:IsCut(bodyPartType),
                bodyDamage:IsScratched(bodyPartType),
                bodyDamage:IsDeepWounded(bodyPartType),
                self:GetZombieId(attacker))
        end
    end
end

function RicksMLC_PostDeath.OnAIStateChange(character, newState, oldState)
    -- Make sure this event is for the player, otherwise on multiplayer everyone gets concussed

    -- Return if this is a dedicated server.
    if isServer() then return end

    if RicksMLC_PostDeathInstance then
        RicksMLC_PostDeathInstance:HandleOnAIStateChange(character, newState, oldState)
    end
end

function RicksMLC_PostDeath.OnCreatePlayer(player)
    RicksMLC_SpawnStats.Instance():ResetWounds()
    RicksMLC_PostDeath.Instance():ResetWounds()
end

local eventsOn = nil
function RicksMLC_PostDeath.Init()
    if not isServer() then 
        DebugLog.log(DebugType.Mod, "RicksMLC_PostDeath.Init()")
        RicksMLC_PostDeathInstance = RicksMLC_PostDeath:new()
        RicksMLC_SpawnStatsInstance = RicksMLC_SpawnStats:new()

        if not eventsOn and SandboxVars.RicksMLC_AdHocCmds.RememberZombieNames then
            Events.OnAIStateChange.Add(RicksMLC_PostDeath.OnAIStateChange)
            Events.OnPlayerDeath.Add(RicksMLC_PostDeath.OnPostDeath)
            -- Comment out for release.  Keypress is for testing only:
            --Events.OnKeyPressed.Add(RicksMLC_PostDeath.OnKeyPressed)
            Events.OnCreatePlayer.Add(RicksMLC_PostDeath.OnCreatePlayer)
            eventsOn = true
        end
    end
end

