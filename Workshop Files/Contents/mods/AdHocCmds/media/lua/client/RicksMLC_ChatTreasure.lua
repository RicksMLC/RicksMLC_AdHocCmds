-- RicksMLC_ChatTreasure.lua

require "RicksMLC_TreasureHuntMgr"
if not RicksMLC_TreasureHuntMgr then 
    DebugLog.log(DebugType.Mod, "RicksMLC_ChatTreasure: require 'RicksMLC_TreasureHuntMgr' failed.  No Rick's MLC Treasure Hunt support.")
    return
end
require "RicksMLC_TreasureHunt"
require "RicksMLC_SharedUtils"
require "ISBaseObject"

RicksMLC_ChatTreasure = ISBaseObject:derive("RicksMLC_ChatTreasure");

RicksMLC_ChatTreasureInstance = nil

function RicksMLC_ChatTreasure.Instance()
    if not RicksMLC_ChatTreasureInstance then
        RicksMLC_ChatTreasureInstance = RicksMLC_ChatTreasure:new()
        RicksMLC_ChatTreasureInstance:Init()
    end
    return RicksMLC_ChatTreasureInstance
end

function RicksMLC_ChatTreasure:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self

    o.ChatHunts = {}
    o.ModData = nil

    return o
end

function RicksMLC_ChatTreasure:Init()
    DebugLog.log(DebugType.Mod, "RicksMLC_ChatTreasure:Init()")
    self:RegisterMapDecorators()
    self:LoadModData()
    self.ChatHunts = self.ModData.ChatHunts or {}
    if Events.RicksMLC_TreasureHunt_Finished then
        DebugLog.log(DebugType.Mod, "Added RickMLC_ChatTreasure.HandleTreasureHuntFinished")
        Events.RicksMLC_TreasureHunt_Finished.Add(RicksMLC_ChatTreasure.HandleTreasureHuntFinished)
    else
        DebugLog.log(DebugType.Mod, "Error: Unable to add RickMLC_ChatTreasure.HandleTreasureHuntFinished")
    end
end

local function ChatDecorator(stashMap, x, y)
    stashMap:addStamp("FaceDead", nil, x, y, 0.8, 0.1, 0.1)
    stashMap:addStamp(nil, "You'll never make it! Bwahahah", x + 20, y, 0.8, 0.1, 0.1)
end

local function DirtyHand(handId)
    local visual = getPlayer():getHumanVisual()
    -- body parts: BodyPartType Hand_L Hand_R
    local part = BloodBodyPartType.FromIndex(handId)
    local totalBlood = visual:getBlood(part)
    local totalDirt = visual:getDirt(part)
    return {Dirt = totalDirt, Blood = totalBlood}
end

local function VisualChatDecorator(mapUI, x, y, visualDecoratorData)
    --overlayPNG(mapUI, 8500, 7320, 0.333, "legend", "media/textures/worldMap/Legend.png")
    local scale = 1
    local layerName = "legend"
    local tex = "media/textures/worldMap/CoffeeStain2.png"
    local alpha = 0.5

    -- local leftHandDirty = DirtyHand(BodyPartType.Hand_L)
    -- local rightHandDirty = DirtyHand(BodyPartType.Hand_R)

    -- Randomise the location of the coffee stain
    if visualDecoratorData then
        x = visualDecoratorData.X
        y = visualDecoratorData.Y
        -- if visualDecorator.DirtyLeftHand < leftHandDirty then
        --     visualDecorator.DirtyLeftHand = leftHandDirty
        -- end
        -- if visualDecorator.DirtyRightHand < rightHandDirty then
        --     visualDecorator.DirtyRightHand = rightHandDirty
        -- end
    else
        visualDecoratorData = {}
        local dX = (ZombRand(1, 100) <= 50 and 1) or -1
        local dY = (ZombRand(1, 100) <= 50 and 1) or -1
        visualDecoratorData.X = x + (ZombRand(200, 400) * dX)
        visualDecoratorData.Y = y + (ZombRand(200, 400) * dY)
        -- visualDecoratorData.DirtyLeftHand = leftHandDirty
        -- visualDecoratorData.DirtyRightHand = rightHandDirty
        x = visualDecoratorData.X
        y = visualDecoratorData.Y
    end
    RicksMLC_MapUtils.OverlayPNG(mapUI, x, y, scale, layerName, tex, alpha)    
    return visualDecoratorData
end

function RicksMLC_ChatTreasure:RegisterMapDecorators()
    RicksMLC_MapDecorators.Instance():Register("ChatDecorator", ChatDecorator)
    RicksMLC_MapDecorators.Instance():Register("VisualChatDecorator", VisualChatDecorator)
end

function RicksMLC_ChatTreasure:LoadModData()
    self.ModData = getGameTime():getModData()["RicksMLC_ChatTreasure"]
    if not self.ModData then
        getGameTime():getModData()["RicksMLC_ChatTreasure"] = {}
        self.ModData = {}
        self.ModData.ChatHunts = {}
    end
end

function RicksMLC_ChatTreasure:SaveModData()
    getGameTime():getModData()["RicksMLC_ChatTreasure"] = self.ModData
end

function RicksMLC_ChatTreasure:MakeUniqueName(name)
    local uniqueName = name
    local num = 1
    uniqueName = name .. " " .. RicksMLC_SharedUtils.to_roman(num)
    while self.ChatHunts[uniqueName] ~= nil do
        num = num + 1
        uniqueName = name .. " " .. RicksMLC_SharedUtils.to_roman(num)
    end
    self.ChatHunts[uniqueName] = num
    return uniqueName
end

local function AddPlayerCentredTownToTreasureHunt(suffix)
    DebugLog.log(DebugType.Mod, "AddPlayerCentredTownToTreasureHunt()")
    local dX = 500
    local dY = 500
    local bounds = {getPlayer():getX() - dX, getPlayer():getY() - dY, getPlayer():getX() + dX, getPlayer():getY() + dY, RicksMLC_MapUtils.DefaultMap()}
    local townName = "PlayerTown" .. suffix .. ":" .. tostring(getPlayer():getX()) .. "," .. tostring(getPlayer():getY())
    RicksMLC_MapUtils.AddTown(townName, bounds)
    return townName
end

local function SplitStrIntoTreasureItems(str)
    local treasures = {}
    treasures = RicksMLC_Utils.SplitStr(str, ",")
    local retTable = {}
    for i, v in ipairs(treasures) do
        retTable[#retTable+1] = {Item = v, Decorator = "ChatDecorator", VisualDecorator = "VisualChatDecorator"}
    end
    return retTable
end

function RicksMLC_ChatTreasure:AddTreasureHunt(chatArgs)
    -- Start with the simplest: Treasure item with random town with barricade and zombie counts
    RicksMLC_SharedUtils.DumpArgs(chatArgs, 1, "RicksMLC_ChatTreasure:AddTreasureHunt")
    local treasures = {}
    --treasures = RicksMLC_Utils.SplitStr(chatArgs.Treasure, ",")
    treasures = SplitStrIntoTreasureItems(chatArgs.Treasure)
    local uniqueName = self:MakeUniqueName(chatArgs.Name)
    --local townName = AddPlayerCentredTownToTreasureHunt(uniqueName)
    local treasureHuntDefn = {
        Name = uniqueName,
        --Town = townName, -- FIXME: Temporary change to test centreing the map on the player
        Town = chatArgs.Town, 
        Barricades = tonumber(chatArgs.Barricades),
        Zombies = tonumber(chatArgs.Zombies),
        Treasures = treasures,
        --Decorators = {[1] = "ChatDecorator"}
    }
    RicksMLC_TreasureHuntMgr.Instance():AddTreasureHunt(treasureHuntDefn)
    self.ModData.ChatHunts = self.ChatHunts
    self:SaveModData()
end

function RicksMLC_ChatTreasure:ResetLostMaps()
    RicksMLC_TreasureHuntMgr.Instance():ResetLostMaps()
end

function RicksMLC_ChatTreasure.HandleTreasureHuntFinished(treasureHuntDefn)
    RicksMLC_Utils.Think(getPlayer(), "Phew - I am glad the " .. treasureHuntDefn.Name .. " is over with", 1)
    getPlayer():playSound("Birthday Noisemaker Sound Effect")
end
