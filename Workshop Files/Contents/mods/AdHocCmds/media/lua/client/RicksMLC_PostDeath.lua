-- PostDeath - Add the list of zombie names who damaged the player.

require "ISBaseObject"

RicksMLC_PostDeath = ISBaseObject:derive("RicksMLC_PostDeath");
RicksMLC_PostDeathInstance = nil

function RicksMLC_PostDeath:new(modName, saveFilePath)
	local o = {}
	setmetatable(o, self)
	self.__index = self


    
    return o
end


function RicksMLC_PostDeath.OnPostDeath(playerObj)
    local uiInst = ISPostDeathUI.instance

    local playerNum = playerObj:getPlayerNum()
    local panel = ISPostDeathUI.instance[playerNum]
    if panel then

        table.insert(panel.lines, s)
    end
  
end

function RicksMLC_PostDeath:HandleOnAIStateChange(character, newState, oldState)
    local oldStateName = character:getPreviousStateName()
    local newStateName = character:getCurrentStateName()
    DebugLog.log(DebugType.Mod, "RicksMLC_PostDeath.OnAIStateChange() old: '" .. tostring(oldStateName) .. "' new: '" .. newStateName .. "'")

    -- Zombie Damage Player Sequence:
    --  Zombie: LungeState -> AttackState
    --  Player: IdleState(?) -> PlayerHitReactionState
    if newStateName == "PlayerHitReactionState" then
        local attacker = character:getAttackedBy()
        local bodyDamage = character:getBodyDamage()
        --local isBitten = bodyDamage:isBitten()
        --local isWounded = bodyDamage:isWounded()

        DebugLog.log(DebugType.Mod, "  Body Damage: ")

    end
end

function RicksMLC_PostDeath.OnAIStateChange(character, newState, oldState)
    -- Make sure this event is for the player, otherwise on multiplayer everyone gets concussed
    --if character ~= RicksMLC_Concussion.getPlayer() or isServer() then return end
    if isClient() then return end

    if RicksMLC_PostDeathInstance then
        RicksMLC_PostDeathInstance:HandleOnAIStateChange(character, newState, oldState)
    end
end

function RicksMLC_PostDeath.Init()
    if not isClient() then 
        DebugLog.log(DebugType.Mod, "RicksMLC_PostDeath.Init()")
        RicksMLC_PostDeathInstance = RicksMLC_PostDeath:new()
    end
end

-- FIXME: Disabled
--Events.OnAIStateChange.Add(RicksMLC_PostDeath.OnAIStateChange)
--Events.OnPlayerDeath.Add(RicksMLC_PostDeath.OnPostDeath)