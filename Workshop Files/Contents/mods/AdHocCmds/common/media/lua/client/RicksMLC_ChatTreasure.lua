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

    -- Restore any generated Towns from previous runs.
    for k, v in pairs(self.ChatHunts) do
        if v.Bounds then
            RicksMLC_MapUtils.AddTown(v.TownName, v.Bounds)
        end
    end

    if Events.RicksMLC_TreasureHunt_Finished then
        DebugLog.log(DebugType.Mod, "Added RickMLC_ChatTreasure.HandleTreasureHuntFinished")
        Events.RicksMLC_TreasureHunt_Finished.Add(RicksMLC_ChatTreasure.HandleTreasureHuntFinished)
    else
        DebugLog.log(DebugType.Mod, "Error: Unable to add RickMLC_ChatTreasure.HandleTreasureHuntFinished")
    end
    if Events.RicksMLC_TreasureHuntClient_Finished then
        DebugLog.log(DebugType.Mod, "Added RickMLC_ChatTreasure.HandleTreasureHuntClientFinished")
        Events.RicksMLC_TreasureHuntClient_Finished.Add(RicksMLC_ChatTreasure.HandleTreasureHuntClientFinished)
    else
        DebugLog.log(DebugType.Mod, "Error: Unable to add RickMLC_ChatTreasure.HandleTreasureHuntClientFinished")
    end
end

local function ChatDecorator(stashMap, x, y)
    stashMap:addStamp("FaceDead", nil, x, y, 0.8, 0.1, 0.1)
    stashMap:addStamp(nil, "You'll never make it! Bwahahah", x + 20, y, 0.8, 0.1, 0.1)
end

local function DirtyHand(handId)
    local visual = getPlayer():getHumanVisual()
    -- body parts: BodyPartType Hand_L Hand_R
    local totalBlood = visual:getBlood(handId)
    local totalDirt = visual:getDirt(handId)
    return {Dirt = totalDirt, Blood = totalBlood}
end

local function RandomOffset(min, max)
    local n = (ZombRand(1, 100) <= 50 and 1) or -1
    return ZombRand(min, max) * n
end

-- DrawHandPrints
--  hand:       "Left" or "Right" (case sensitive)
--  mapSide :   -1 for left, +1 for right
local function DrawHandPrints(mapUI, x, y, visualDecoratorData, hand, mapSide)
    local handPrints = hand .. "HandPrints"
    local scale = 0.75
    local layerName = "legend"
    local tex = "media/textures/worldMap/" .. hand .. "Hand1.png"
    local alpha = 0.1
    local handType = (hand == "Left" and BloodBodyPartType.Hand_L) or BloodBodyPartType.Hand_R
    local dirtyHand = DirtyHand(handType)
    if not visualDecoratorData[handPrints] then
        visualDecoratorData[handPrints] = {}
    end

    if #visualDecoratorData[handPrints] > 2 then
        -- TODO: Finger/thumb prints or some other grime
    end

    visualDecoratorData[handPrints][#visualDecoratorData[handPrints]+1] = {
        DirtyHand = dirtyHand,
        X = x + (ZombRand(300, 500) * mapSide),
        Y = y + RandomOffset(250, 350),
        Texture = tex,
        Alpha = math.max(dirtyHand.Blood, dirtyHand.Dirt)
    }

    for i, v in ipairs(visualDecoratorData[handPrints]) do
        
        RicksMLC_MapUtils.OverlayPNG(mapUI, v.X, v.Y, scale, layerName, v.Texture, v.Alpha)
    end
    return visualDecoratorData
end


local function DrawCoffeeStain(mapUI, x, y, visualDecoratorData)
    local scale = 1
    local layerName = "legend"
    local tex = "media/textures/worldMap/CoffeeStain2.png"
    local alpha = 0.5

    -- Randomise the location of the coffee stain
    if not visualDecoratorData then
        visualDecoratorData = {}
        visualDecoratorData.CoffeeStain = { X = x + RandomOffset(200, 400), Y = y + RandomOffset(200, 400) }
    end
    RicksMLC_MapUtils.OverlayPNG(mapUI, visualDecoratorData.CoffeeStain.X, visualDecoratorData.CoffeeStain.Y, scale, layerName, tex, alpha)    
    return visualDecoratorData
end

local function VisualChatDecorator(mapUI, x, y, visualDecoratorData)
    visualDecoratorData = DrawCoffeeStain(mapUI, x, y, visualDecoratorData)
    visualDecoratorData = DrawHandPrints(mapUI, x, y, visualDecoratorData, "Left", -1)
    visualDecoratorData = DrawHandPrints(mapUI, x, y, visualDecoratorData, "Right", 1)
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
    local isUnique = RicksMLC_TreasureHuntMgr.Instance():IsTreasureHuntNameUnique(uniqueName)
    while not isUnique or self.ChatHunts[uniqueName] ~= nil do
        num = num + 1
        uniqueName = name .. " " .. RicksMLC_SharedUtils.to_roman(num)
        isUnique = RicksMLC_TreasureHuntMgr.Instance():IsTreasureHuntNameUnique(uniqueName)
    end
    self.ChatHunts[uniqueName] = {Num = num}
    return uniqueName
end

local function AddPlayerCentredTownToTreasureHunt(suffix)
    DebugLog.log(DebugType.Mod, "AddPlayerCentredTownToTreasureHunt()")
    local dX = 500
    local dY = 500
    local bounds = {getPlayer():getX() - dX, getPlayer():getY() - dY, getPlayer():getX() + dX, getPlayer():getY() + dY, RicksMLC_MapUtils.DefaultMap()}
    local townName = "PlayerTown" .. suffix .. ":" .. tostring(getPlayer():getX()) .. "," .. tostring(getPlayer():getY())
    RicksMLC_MapUtils.AddTown(townName, bounds)
    return {townName, bounds}
end

local function SplitStrIntoTreasureItems(str, zombies, barricades)
    local treasures = {}
    treasures = RicksMLC_Utils.SplitStr(str, ",")
    local retTable = {}
    for i, v in ipairs(treasures) do
        retTable[#retTable+1] = {
            Item = v, 
            Zombies = zombies, 
            Barricades = barricades,
        --    Decorator = "ChatDecorator", -- Commented out as the AddTreasureHunt sets the common decorators.  I am leaving this here just in case I decide to customise it further.
        --    VisualDecorator = "VisualChatDecorator"
        }
    end
    return retTable
end

function RicksMLC_ChatTreasure:AddTreasureHunt(chatArgs)
    -- Start with the simplest: Treasure item with random town with barricade and zombie counts
    RicksMLC_SharedUtils.DumpArgs(chatArgs, 1, "RicksMLC_ChatTreasure:AddTreasureHunt")
    local treasures = {}
    treasures = SplitStrIntoTreasureItems(chatArgs.Treasure, tonumber(chatArgs.Zombies), tonumber(chatArgs.Barricades))
    local uniqueName = self:MakeUniqueName(chatArgs.Name)
    local townName = chatArgs.Town
    if chatArgs.Town == "Player" then
        local townData = AddPlayerCentredTownToTreasureHunt(uniqueName)
        townName = townData[1]
        -- Record the town and bounds so on a restart the generated town is reloaded before using the treasure maps.
        self.ChatHunts[uniqueName].TownName = townName
        self.ChatHunts[uniqueName].Bounds = townData[2]
        self.ModData.ChatHunts = self.ChatHunts
        self:SaveModData()    
    end
    local treasureHuntDefn = {
        Name = uniqueName,
        Town = townName,
        Barricades = tonumber(chatArgs.Barricades),
        Zombies = tonumber(chatArgs.Zombies),
        Treasures = treasures,
        Decorator = "ChatDecorator",
        VisualDecorator = "VisualChatDecorator",
        Player = chatArgs.Player,
        Mode = chatArgs.Mode
    }
    RicksMLC_TreasureHuntMgr.Instance():AddTreasureHunt(treasureHuntDefn)
end

function RicksMLC_ChatTreasure:ResetLostMaps()
    RicksMLC_TreasureHuntMgr.Instance():ResetLostMaps()
end

function RicksMLC_ChatTreasure.HandleTreasureHuntFinished(treasureHuntDefn)
    RicksMLC_Utils.Think(getPlayer(), "Phew - I am glad the " .. treasureHuntDefn.Name .. " is over with", 1)
    getPlayer():playSound("Birthday Noisemaker Sound Effect")
end

function RicksMLC_ChatTreasure.HandleTreasureHuntClientFinished(treasureHuntDefn, username)
    DebugLog.log(DebugType.Mod, "RicksMLC_ChatTreasure.HandleTreasureHuntClientFinished() username: " .. username .. " treasureHuntDefn.Player: " .. treasureHuntDefn.Player)
    local msg = nil
    if username ~= getPlayer():getUsername() then
        if treasureHuntDefn.Player and username ~= treasureHuntDefn.Player then
            if treasureHuntDefn.Player == getPlayer():getUsername() then
                msg = "ARGH! Player " .. username .. " found my last treasure hunt item.  Curses!"
            else
                msg = "Hmm... player " .. username .. " found player " .. treasureHuntDefn.Player .. " last treasure hunt item"
            end
        else
            msg =  "I sense player '" .. username .. "' has finished their treasure hunt"
        end
        -- TODO: Add an appropriate sound.  Maybe a bad sound if the treasure hunt was mine!
    end
    if msg then
        RicksMLC_Utils.Think(getPlayer(), msg, 1)
    end
    getPlayer():playSound("lose_01")
end