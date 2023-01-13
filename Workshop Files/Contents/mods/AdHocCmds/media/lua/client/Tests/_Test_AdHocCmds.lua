-- Test Concussion.lua
-- Rick's MLC Concussion

-- [ ] Test the RemoveGrassWithTool mod 
--

require "ISBaseObject"

local MockPlayer = ISBaseObject:derive("MockPlayer");
function MockPlayer:new(player)
    local o = {} 
    setmetatable(o, self)
    self.__index = self

    o.realPlayer = player
    o.lastThought = nil

    return o
end

function MockPlayer:Move(direction) self.realPlayer:Move(direction) end

function MockPlayer:getForwardDirection() return self.realPlayer:getForwardDirection() end

function MockPlayer:setForwardDirection(fwdDirVec) self.realPlayer:setForwardDirection(fwdDirVec) end

function MockPlayer:setForceSprint(value) self.realPlayer:setForceSprint(value) end

function MockPlayer:setSprinting(value) self.realPlayer:setSprinting(value) end

function MockPlayer:getPlayerNum() return self.realPlayer:getPlayerNum() end

function MockPlayer:getPerkLevel(perkType) return self.realPlayer:getPerkLevel(perkLevel) end

function MockPlayer:getXp() return self.realPlayer:getXp() end

function MockPlayer:getPrimaryHandItem() return self.realPlayer:getPrimaryHandItem() end

function MockPlayer:setPrimaryHandItem(item) self.realPlayer:setPrimaryHandItem(item) end

function MockPlayer:getSecondaryHandItem() return self.realPlayer:getSecondaryHandItem() end

function MockPlayer:setSecondaryHandItem(item) self.realPlayer:setSecondaryHandItem(item) end

function MockPlayer:isTimedActionInstant() return false end

function MockPlayer:getTimedActionTimeModifier() return self.realPlayer:getTimedActionTimeModifier() end

function MockPlayer:Say(text, r, g, b, font, n, preset)
    self.realPlayer:Say(text, r, g, b, font, n, preset)
    self.lastThought = text
    DebugLog.log(DebugType.Mod, "MockPlayer:Say() end: " .. text)
end

function MockPlayer:getMoodles() return self.realPlayer:getMoodles() end

function MockPlayer:getBodyDamage() return self.realPlayer:getBodyDamage() end

----------------------------------------------------------------------

local AdHocCmds_Test = ISBaseObject:derive("AdHocCmds_Test")
local iTest = nil

function AdHocCmds_Test:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.player = nil
    o.isReady = false
    o.ISRemoveGrassInstance = nil
    o.preTestPrimaryItem = nil
    o.preTestSecondaryItem = nil
    o.resultsWindow = nil
    o.testResults = {}
    return o
end


function AdHocCmds_Test:Run()
    DebugLog.log(DebugType.Mod, "AdHocCmds_Test:Run()")
    if not self.isReady then
        DebugLog.log(DebugType.Mod, "AdHocCmds_Test:Run() not ready")
        return
    end
    DebugLog.log(DebugType.Mod, "AdHocCmds_Test:Run() begin")

    -- Insert test code here
    local climateMgr = getClimateManager()
    if climateMgr then
        --climateMgr:transmitTriggerTropical(100)
        climateMgr:triggerCustomWeatherStage(WeatherPeriod.STAGE_TROPICAL_STORM,8)
        DebugLog.log(DebugType.Mod, "AdHocCmds_Test:Run() transmitTriggerStorm()")
    end

    self.resultsWindow:createChildren()

    DebugLog.log(DebugType.Mod, "AdHocCmds_Test:Run() end")
end

function AdHocCmds_Test:Init()
    DebugLog.log(DebugType.Mod, "AdHocCmds_Test:Init()")

    self.player = MockPlayer:new(getPlayer())

    self:CreateWindow()

    -- Create the object instances to test, if any

    self.isReady = true
end

function AdHocCmds_Test:CreateWindow()
    if self.resultsWindow then
        self.resultsWindow:setObject(self.testResults)
    else
        DebugLog.log(DebugType.Mod, "AdHocCmds_Test:CreateWindow()")
        local x = getPlayerScreenLeft(self.player:getPlayerNum())
        local y = getPlayerScreenTop(self.player:getPlayerNum())
        local w = getPlayerScreenWidth(self.player:getPlayerNum())
        local h = getPlayerScreenHeight(self.player:getPlayerNum())
        self.resultsWindow = _Test_RicksMLC_UI_Window:new(x + 70, y + 50, self.player, self.testResults)
        self.resultsWindow:initialise()
        self.resultsWindow:addToUIManager()
        _Test_RicksMLC_UI_Window.windows[self.player] = window
        if self.player:getPlayerNum() == 0 then
            ISLayoutManager.RegisterWindow('AdHocCmds_Test', ISCollapsableWindow, self.resultsWindow)
        end
    end

    self.resultsWindow:setVisible(true)
    self.resultsWindow:addToUIManager()
    local joypadData = JoypadState.players[self.player:getPlayerNum()+1]
    if joypadData then
        joypadData.focus = window
    end
end

function AdHocCmds_Test:Teardown()
    DebugLog.log(DebugType.Mod, "AdHocCmds_Test:Teardown()")
    self.player:setPrimaryHandItem(self.preTestPrimaryItem)
    self.player:setSecondaryHandItem(self.getSecondaryHandItem)
    self.preTestPrimaryItem = nil
    self.preTestSecondaryItem = nil
    self.ISRemoveGrassInstance = nil
    self.isReady = false
end

-- Static --

function AdHocCmds_Test.IsTestSave()
    local saveInfo = getSaveInfo(getWorld():getWorld())
    DebugLog.log(DebugType.Mod, "AdHocCmds_Test.OnLoad() '" .. saveInfo.saveName .. "'")
	return saveInfo.saveName and saveInfo.saveName == "RicksMLC_Concussion_Test"
end

function AdHocCmds_Test.Execute()
    iTest = AdHocCmds_Test:new()
    iTest:Init()
    if iTest.isReady then 
        DebugLog.log(DebugType.Mod, "AdHocCmds_Test.Execute() isReady")
        iTest:Run()
        DebugLog.log(DebugType.Mod, "AdHocCmds_Test.Execute() Run complete.")
    end
    iTest:Teardown()
    iTest = nil
end

function AdHocCmds_Test.OnLoad()
    -- Check the loaded save is a test save?
    DebugLog.log(DebugType.Mod, "AdHocCmds_Test.OnLoad()")
	if AdHocCmds_Test.IsTestSave() then
        DebugLog.log(DebugType.Mod, "  - Test File Loaded")
        --FIXME: This is auto run: AdHocCmds_Test.Execute()
    end
end

function AdHocCmds_Test.OnGameStart()
    DebugLog.log(DebugType.Mod, "AdHocCmds_Test.OnGameStart()")
end

function AdHocCmds_Test.HandleOnKeyPressed(key)
	-- Hard coded to F9 for now
	if key == nil then return end

	if key == Keyboard.KEY_F9 and AdHocCmds_Test.IsTestSave() then
        DebugLog.log(DebugLog.Mod, "AdHocCmds_Test.HandleOnKeyPressed() Execute test")
        AdHocCmds_Test.Execute()
    end
end

--Events.OnKeyPressed.Add(AdHocCmds_Test.HandleOnKeyPressed)

Events.OnGameStart.Add(AdHocCmds_Test.OnGameStart)
Events.OnLoad.Add(AdHocCmds_Test.OnLoad)
