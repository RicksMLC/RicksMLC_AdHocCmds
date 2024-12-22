-- https://projectzomboid.com/modding////zombie/iso/WorldMarkers.DirectionArrow.html

require "Tests/_Test_RicksMLC_UI"

local RicksMLC_SpawnTest = ISBaseObject:derive("RicksMLC_SpawnTest")
RicksMLC_SpawnTestInstance = nil

function RicksMLC_SpawnTest:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.player = nil
    o.UIWindow = nil
    o.windowContents = {}
    o.arrow = nil
    o.circle = nil

    o.offset = 12
    o.radius = 4

    o.isoBuilding = nil
    o.otherRoomDef = nil
    o.freeSquare = nil
    
    o.showingSpawnResult = false

    o.safeZoneLoc = nil -- { x = vSafeToSpawn.x, y = vSafeToSpawn.y, z = 0, radius = radius, safehouse = {x = safeX, y = safeY, z = 0, radius = minSafeDistance} }

    o.safeHouseRangeUI = nil
    o.safeZoneSpawnUI = nil
    o.safeZoneRadius = RicksMLC_SpawnHandlerC.instance.safehouseSafeZoneRadius or 15

    return o
end

function RicksMLC_SpawnTest:UpdateSafeZoneRadius(newRadius)
    if isClient() and (isCoopHost() or isAdmin()) then
        self.safeZoneRadius = newRadius
        local args = { safeZoneRadius = self.safeZoneRadius }
        sendClientCommand(getPlayer(), 'RicksMLC_Zombies', 'UpdateSafeZoneFromClient', args)
    end

end

function RicksMLC_SpawnTest.onSliderChange(slider, newValue)
    if slider.valueLabel then
		slider.valueLabel:setName(ISDebugUtils.printval(newValue,3))
    end
    RicksMLC_SpawnTestInstance:UpdateSafeZoneRadius(newValue)
end

local overrideClose = _Test_RicksMLC_UI_Window.close
function _Test_RicksMLC_UI_Window.close(self)
    if RicksMLC_SpawnTestInstance then
        RicksMLC_SpawnTestInstance.safeHouseRangeUI:Remove()
        RicksMLC_SpawnTestInstance.safeZoneSpawnUI:Remove()
        RicksMLC_SpawnTestInstance.UIWindow = nil
    end
    overrideClose(self)
end

local overrideCreateChildren = _Test_RicksMLC_UI_Window.createChildren
function _Test_RicksMLC_UI_Window.createChildren(self)
    overrideCreateChildren(self)
    -- local bottomH = 100
    -- self.bottomPanel = ISPanel:new(0, self.height - bottomH, self.width, bottomH)
	-- self.bottomPanel:setAnchorTop(false)
	-- self.bottomPanel:setAnchorLeft(false)
	-- self.bottomPanel:setAnchorRight(false)
	-- self.bottomPanel:setAnchorBottom(true)
	-- self.bottomPanel:noBackground()
	-- self:addChild(self.bottomPanel)
    y = self.panel.y + self.panel.height + 30
    self.safeZoneSliderLabel = ISLabel:new(2, y, 16, "0", 1, 1, 1, 1.0, UIFont.Small, true);
    self.safeZoneSliderLabel:initialise()
    self.safeZoneSliderLabel:instantiate()
    self:addChild(self.safeZoneSliderLabel)

    self.safeZoneSlider = ISSliderPanel:new(20, y, 200, 20, self, RicksMLC_SpawnTest.onSliderChange)
	self.safeZoneSlider.anchorTop = false
	self.safeZoneSlider.anchorBottom = true
    self.safeZoneSlider:initialise()
	self.safeZoneSlider:setValues(1, 100, 1, 10)
	self.safeZoneSlider:setCurrentValue(15)
    self.safeZoneSlider.pretext = "Radius: "
    self.safeZoneSlider.valueLabel = self.safeZoneSliderLabel
	self:addChild(self.safeZoneSlider)
    y = self.safeZoneSliderLabel:getY() + self.safeZoneSliderLabel:getHeight()

    -- local y = self:getHeight() -30
    -- _,self.safeZoneSliderTitle = ISDebugUtils.addLabel(self, "Safe Zone", 10, y, "Safe", UIFont.Small, true)
	-- _,self.safeZoneSliderLabel = ISDebugUtils.addLabel(self, "Radius", 80, y, "1", UIFont.Small, false)
	-- _,self.safeZoneSlider = ISDebugUtils.addSlider(self, "radius", 130, y, 200, 20, RicksMLC_SpawnTest.onSliderChange)
	-- self.safeZoneSlider.pretext = "Radius: "
	-- self.safeZoneSlider.valueLabel = self.safeZoneSliderLabel
	-- self.safeZoneSlider:setValues(1, 100, 1, 10, true)
	-- self.safeZoneSlider.currentValue = 15
    -- self:addChild(self.safeZoneSlider)
	-- y=y+30
end

function RicksMLC_SpawnTest:CreateWindow()
    if self.UIWindow then
        self.UIWindow:setObject(self.windowContents)
    else
        DebugLog.log(DebugType.Mod, "RicksMLC_SpawnTest:CreateWindow()")
        local x = getPlayerScreenLeft(self.player:getPlayerNum())
        local y = getPlayerScreenTop(self.player:getPlayerNum())
        local w = getPlayerScreenWidth(self.player:getPlayerNum())
        local h = getPlayerScreenHeight(self.player:getPlayerNum())
        self.UIWindow = _Test_RicksMLC_UI_Window:new(x + 80, y + 280, self.player, self.windowContents, 600, 16 * 8)
        self.UIWindow:initialise()
        self.UIWindow:addToUIManager()
        _Test_RicksMLC_UI_Window.windows[self.player] = window

        self.arrow = getWorldMarkers():addDirectionArrow(self.player, self.player:getX(), self.player:getY(), self.player:getZ(), "dir_arrow_up", 0.2, 0.8, 0.25, 0.95);
        self.circle = getWorldMarkers():addGridSquareMarker("circle_center", "circle_only_highlight", self.player:getSquare(), 0.2, 0.8, 0.25, true, 2.5);
        self.circle:setSize(self.radius)

        self.safeHouseRangeUI = RicksMLC_SpawnPointUIElement:new("Safehouse Range", self.player, {r = 0.0, g = 0.8, b = 0.2, a = 0.5}, {r = 0.0, g = 0.8, b = 0.2, a = 0.5})
        self.safeZoneSpawnUI = RicksMLC_SpawnPointUIElement:new("Safe Zone Spawn", self.player, {r = 0.8, g = 0.5, b = 0.2, a = 0.5}, {r = 0.8, g = 0.5, b = 0.2, a = 0.5})

        if self.player:getPlayerNum() == 0 then
            ISLayoutManager.RegisterWindow('RicksMLC_SpawnTest', ISCollapsableWindow, self.UIWindow)
        end
    end

    self.UIWindow:setVisible(true)
    self.UIWindow:addToUIManager()
    local joypadData = JoypadState.players[self.player:getPlayerNum()+1]
    if joypadData then
        joypadData.focus = window
    end
    self.UIWindow:createChildren()
end

function RicksMLC_SpawnTest:Update(offset, radius)
    self.offset = offset
    self.radius = radius
end

function RicksMLC_SpawnTest:DrawSpawnPoint(spawnX, spawnY, spawnZ, radius, offset)
    if self.spawnCircle then
        self.spawnCircle:remove()
    end
    if self.spawnArrow then
        self.spawnArrow:remove()
    end
    self.spawnArrow = getWorldMarkers():addDirectionArrow(self.player, spawnX, spawnY, spawnZ, "dir_arrow_up", 0.8, 0.3, 0.25, 0.95);
    self.spawnCircle = getWorldMarkers():addGridSquareMarker(self.player:getSquare(), 0.8, 0.8, 0.0, true, radius);
	self.spawnCircle:setScaleCircleTexture(true);
    --self.spawnCircle = getWorldMarkers():addGridSquareMarker("circle_center", "circle_only_highlight", self.player:getSquare(), 0.8, 0.2, 0.2, true, radius);
    self.spawnCircle:setPosAndSize(spawnX, spawnY, spawnZ, radius)
    self:Update(offset, radius)
end

function RicksMLC_SpawnTest:ChooseSpawnRoom(player, minArea)
    if self.isoBuilding ~= player:getCurrentBuilding() then
        self.otherRoomDef = nil
        self.freeSquare = nil
        self.isoBuilding = player:getCurrentBuilding()
    end
    local currentRoomDef = player:getCurrentRoomDef()
    local getRoomsNumber = self.isoBuilding:getRoomsNumber()
    if currentRoomDef == self.otherRoomDef then
        self:ClearSpawnPoint()
        self.otherRoomDef = nil
        self.freeSquare = nil
    end
    if getRoomsNumber > 1 and not self.otherRoomDef then
        self.otherRoomDef = self.isoBuilding:getDef():getRandomRoom(minArea)
        local i = 0
        while i < 10 do
            if self.otherRoomDef and self.otherRoomDef ~= currentRoomDef then
                self.freeSquare = self.otherRoomDef:getIsoRoom():getRandomFreeSquare()
                if self.freeSquare then
                    return
                end
            end
            i = i + 1
        end
        -- Fall through means no other room was found
        self.otherRoomDef = nil
        self.freeSquare = nil
    end
end

function RicksMLC_SpawnTest:GetSpawnRoomText(player)
    if not player or player:isOutside() then
        return "Is Outside"
    end

    local currentRoomDef = player:getCurrentRoomDef()
    local getRoomsNumber = self.isoBuilding:getRoomsNumber()
    local txt = "Room: '" .. currentRoomDef:getName() .. "' (of ".. tostring(getRoomsNumber).. ")"
    if self.otherRoomDef then 
        txt = txt .. " Other room: '" .. self.otherRoomDef:getName() .. "'"
        if self.freeSquare then
            txt = txt .. " free square found"
        else 
            txt = txt .. " no free square."
        end
    else
        txt = txt .. " No other room found."
    end
    return txt
end

function RicksMLC_SpawnTest:ClearSpawnPoint()
    if self.spawnCircle then
        self.spawnCircle:remove()
        self.spawnCircle = nil
    end
    if self.spawnArrow then
        self.spawnArrow:remove()
        self.spawnArrow = nil
    end
end

function RicksMLC_SpawnTest:UpdateSpawnPoint()
    if self.freeSquare then
        self:DrawSpawnPoint(self.freeSquare:getX(), self.freeSquare:getY(), self.freeSquare:getZ(), 1, 1)
    else
        self:ClearSpawnPoint()
    end
end

function RicksMLC_SpawnTest:HandlePlayerUpdate()
    if not self.UIWindow then return end

    -- Sets the values to display
    if not self.player or self.player:isOutside() then
        if self.showingSpawnResult then
            self.showingSpawnResult = false
        end
        self.otherRoomDef = nil
        self.freeSquare = nil
        self.isoBuilding = nil
    else
        if not self.showingSpawnResult then
            self:ChooseSpawnRoom(self.player, 4)
        end
    end
    self.isoBuilding = self.player:getCurrentBuilding()

    local lookDir = self.player:getForwardDirection()
    local spawnX = self.player:getX() + (lookDir:getX() * self.offset)
    local spawnY = self.player:getY() + (lookDir:getY() * self.offset)

    self.arrow:setX(spawnX)
    self.arrow:setY(spawnY)
    self.arrow:setZ(self.player:getZ())
    self.circle:setPos(spawnX, spawnY, self.player:getZ())
    self.circle:setSize(self.radius)

    local radius = 5
    local playerLoc = { x = self.player:getX(), y = self.player:getY(), z = 0}
    self.safeZoneLoc = RicksMLC_SpawnCommon.CalcSafeZoneSpawnPoint(playerLoc, radius, self.safeZoneRadius)
    if self.safeZoneLoc then
        self.safeZoneSpawnUI:SetActive(true)
        self.safeHouseRangeUI:SetActive(true)
        self.safeZoneSpawnUI:CreateOrUpdate(self.safeZoneLoc)
        self.safeHouseRangeUI:CreateOrUpdate(self.safeZoneLoc.safehouse)
    else
        self.safeZoneSpawnUI:SetActive(false)
        self.safeHouseRangeUI:SetActive(false)
    end

    self.windowContents[1] = "Look: " .. tostring(round(lookDir:getX(), 2)) .. ", " .. tostring(round(lookDir:getY(), 2))
    self.windowContents[2] = "Loc:" .. tostring(round(self.player:getX(), 2)) .. ", " .. tostring(round(self.player:getY(), 2))
    self.windowContents[3] = "Spawn: " .. tostring(round(spawnX, 2)) .. ", " .. tostring(round(spawnY, 2))
    self.windowContents[4] = "Building info: " .. self:GetSpawnRoomText(self.player)
    if isClient() then
        if self.safeHouseRangeUI then
            self.windowContents[5] = self.safeHouseRangeUI:GetInfo()
        end
        if self.safeZoneSpawnUI then
            self.windowContents[6] = self.safeZoneSpawnUI:GetInfo()
        end
    end

    self:UpdateSpawnPoint()
end

function RicksMLC_SpawnTest:ConvertIdsToRoom(spawnBuildingIds)
    local spawnBuildingDef = getPlayer():getCurrentBuildingDef()
    if spawnBuildingDef then
        self.otherRoomDef = getPlayer():getCell():getRoom(spawnBuildingIds.spawnRoomId)
        if self.otherRoomDef then
            self.isoBuilding = self.otherRoomDef:getIsoRoom():getBuilding()
            self.showingSpawnResult = true
            return true
        end
    end
    return false
end

function RicksMLC_SpawnTest:ShowSpawnResult(spawnResult, spawnBuildingIds)
    if not self.UIWindow then return end

    -- args { spanwResult.spawnLoc, spawnResult.spawnRoomInfo }
    if spawnResult.spawnLoc then
        self:DrawSpawnPoint(spawnResult.spawnLoc.x, spawnResult.spawnLoc.y, spawnResult.spawnLoc.z, 1, 1)
        self.showingSpawnResult = true
        if spawnResult.spawnLoc.safehouse then
            self.safeHouseRangeUI:CreateOrUpdate(spawnResult.spawnLoc.safehouse)
            self.safeZoneSpawnUI:CreateOrUpdate(spawnResult.spawnLoc)
            self.safeZoneRadius = spawnResult.spawnLoc.safehouse.radius
        end
    elseif spawnResult.spawnRoomInfo then
        if not spawnResult.spawnRoomInfo.spawnRoomDef and spawnBuildingIds and spawnBuildingIds.spawnRoomId then
            if not self:ConvertIdsToRoom(spawnBuildingIds) then
                self.showingSpawnResult = false
                self:ClearSpawnPoint()
                return
            end
        elseif not spawnResult.spawnRoomInfo.spawnRoomDef then
            DebugLog.log(DebugType.Mod, "RicksMLC_SpawnTest:ShowSpawnResult() spawnRoomInfo has no spawnRoomDef or spawnRoomId")
            self.showingSpawnResult = false
            self:ClearSpawnPoint()    
            return
        end
        self.otherRoomDef = spawnResult.spawnRoomInfo.spawnRoomDef
        self.freeSquare = spawnResult.spawnRoomInfo.freeSquare
        self.isoBuilding = self.otherRoomDef:getIsoRoom():getBuilding()
        self.showingSpawnResult = true
    else
        self.showingSpawnResult = false
        self:ClearSpawnPoint()
    end
end

function RicksMLC_SpawnTest.onRicksMLC_SpawnWindowInfo(player)
    if RicksMLC_SpawnTestInstance then
        RicksMLC_SpawnTestInstance:CreateWindow()
    end
end


function RicksMLC_SpawnTest.OnFillWorldObjectContextMenu(player, context, worldobjects, test)
    context:addOption("Rick's MLC Spawn Info", player, RicksMLC_SpawnTest.onRicksMLC_SpawnWindowInfo)
end

function RicksMLC_SpawnTest.OnPlayerUpdate()
    if RicksMLC_SpawnTestInstance then
        RicksMLC_SpawnTestInstance:HandlePlayerUpdate()
    end
end

function RicksMLC_SpawnTest.OnCreatePlayer(playerNumber, player)
    DebugLog.log(DebugType.Mod, "RicksMLC_SpawnTest.OnCreatePlayer() " .. tostring(player))

    if not player then return end

    RicksMLC_SpawnTestInstance = RicksMLC_SpawnTest:new()
    
    RicksMLC_SpawnTestInstance.player = player
    RicksMLC_SpawnTestInstance:CreateWindow()
    Events.OnPlayerUpdate.Add(RicksMLC_SpawnTest.OnPlayerUpdate)
    if isClient() then
        Events.OnFillWorldObjectContextMenu.Add(RicksMLC_SpawnTest.OnFillWorldObjectContextMenu)
    end
end

--Events.OnCreatePlayer.Add(RicksMLC_SpawnTest.OnCreatePlayer)
