-- https://projectzomboid.com/modding////zombie/iso/WorldMarkers.DirectionArrow.html

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

    return o
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
        self.UIWindow = _Test_RicksMLC_UI_Window:new(x + 70, y + 50, self.player, self.windowContents)
        self.UIWindow:initialise()
        self.UIWindow:addToUIManager()
        _Test_RicksMLC_UI_Window.windows[self.player] = window
        if self.player:getPlayerNum() == 0 then
            ISLayoutManager.RegisterWindow('RicksMLC_SpawnTest', ISCollapsableWindow, self.UIWindow)
        end
        self.arrow = getWorldMarkers():addDirectionArrow(self.player, self.player:getX(), self.player:getY(), self.player:getZ(), "dir_arrow_up", 0.2, 0.8, 0.25, 0.95);
        self.circle = getWorldMarkers():addGridSquareMarker("circle_center", "circle_only_highlight", self.player:getSquare(), 0.2, 0.8, 0.25, true, 2.5);
        self.circle:setSize(self.radius)
    end

    self.UIWindow:setVisible(true)
    self.UIWindow:addToUIManager()
    local joypadData = JoypadState.players[self.player:getPlayerNum()+1]
    if joypadData then
        joypadData.focus = window
    end
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
    self.windowContents[1] = "Look: " .. tostring(round(lookDir:getX(), 2)) .. ", " .. tostring(round(lookDir:getY(), 2))
    self.windowContents[2] = "Loc:" .. tostring(round(self.player:getX(), 2)) .. ", " .. tostring(round(self.player:getY(), 2))
    self.windowContents[3] = "Spawn: " .. tostring(round(spawnX, 2)) .. ", " .. tostring(round(spawnY, 2))
    self.windowContents[4] = "Building info: " .. self:GetSpawnRoomText(self.player)
    self.arrow:setX(spawnX)
    self.arrow:setY(spawnY)
    self.arrow:setZ(self.player:getZ())
    self.circle:setPos(spawnX, spawnY, self.player:getZ())
    self.circle:setSize(self.radius)
    self:UpdateSpawnPoint()
end

function RicksMLC_SpawnTest:ConvertIdsToRoom(spawnBuildingIds)
    local spawnBuildingDef = getPlayer():getCurrentBuildingDef()
    if spawnBuildingDef then
        self.otherRoomDef = getPlayer():getCell():getRoom(spawnBuildingIds.spawnRoomId)
        -- local roomDefArrayList = spawnBuildingDef:getRooms()
        -- for j = 0, roomDefArrayList:size()-1 do
        --     if roomDefArrayList:get(j):getID() == spawnBuildingIds.spawnRoomId then
        --         self.otherRoomDef = roomDefArrayList:get(j)
        --         self.freeSquare = self.otherRoomDef:getFreeSquare()
        --         break
        --     end
        -- end
        if self.otherRoomDef then
            self.isoBuilding = self.otherRoomDef:getIsoRoom():getBuilding()
            self.showingSpawnResult = true
            return true
        end
    end
    return false
end

function RicksMLC_SpawnTest:ShowSpawnResult(spawnResult, spawnBuildingIds)
    -- args { spanwResult.spawnLoc, spawnResult.spawnRoomInfo }
    if spawnResult.spawnLoc then
        self:DrawSpawnPoint(spawnResult.spawnLoc.x, spawnResult.spawnLoc.y, spawnResult.spawnLoc.z, 1, 1)
        self.showingSpawnResult = true
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
    RicksMLC_SpawnTestInstance.UIWindow:createChildren()
    Events.OnPlayerUpdate.Add(RicksMLC_SpawnTest.OnPlayerUpdate)
end

Events.OnCreatePlayer.Add(RicksMLC_SpawnTest.OnCreatePlayer)
