-- RicksMLC_SpawnUI.lua

-- TODO: Update so it shows all safehouses
--       Show your own safehouse in green and the other in.. some other colour.
--       Update with checkbox to always show your own safe house

require "ISUI/ISPanel"
require "ISUI/ISCollapsableWindow"

RicksMLC_SpawnPointUIElement = ISBaseObject:derive("RicksMLC_SpawnPointUIElement")
function RicksMLC_SpawnPointUIElement:new(name, player, arrowRGBA, circleRGBA)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.name = name
    o.player = player
    o.arrow = nil
    o.arrowRGBA = arrowRGBA
    o.circle = nil
    o.circleRGBA = circleRGBA

    o.radius = nil
    o.offset = nil
    o.facing = nil

    return o
end

function RicksMLC_SpawnPointUIElement:Remove()
    if not (self.arrow and self.circle) then return end

    self.arrow:remove()
    self.circle:remove()
end

function RicksMLC_SpawnPointUIElement:SetActive(active)
    if not (self.arrow and self.circle) then return end

    self.arrow:setActive(active)
    self.circle:setActive(active)
end

function RicksMLC_SpawnPointUIElement:GetInfo()
    local info = self.name 
    if self.arrow then
        info = info .. " Loc:" .. tostring(self.arrow:getX()) .. " " .. tostring(self.arrow:getY()) .. " " .. tostring(self.arrow:getZ()) 
            .. " Radius: " .. tostring(self.radius)
            .. " Distance: " .. tostring(round(IsoUtils.DistanceTo2D(self.player:getX(), self.player:getY(), self.arrow:getX(), self.arrow:getY())), 2)
    else
        info = info .. "arrow not init yet"
    end
    return info
end

function RicksMLC_SpawnPointUIElement:CreateOrUpdate(loc)
    if self.circle and self.arrow then
        self:SetPosAndSizeLoc(loc)
        return
    end
    self.arrow = getWorldMarkers():addDirectionArrow(self.player, loc.x, loc.y, loc.z, "dir_arrow_up", self.arrowRGBA.r, self.arrowRGBA.g, self.arrowRGBA.b, self.arrowRGBA.a);
    self.circle = getWorldMarkers():addGridSquareMarker(self.player:getSquare(), self.circleRGBA.r, self.circleRGBA.g, self.circleRGBA.b, true, loc.radius);
	self.circle:setScaleCircleTexture(false)

    self:SetPosAndSizeLoc(loc)
end

function RicksMLC_SpawnPointUIElement:SetPosAndSizeLoc(loc)
    self.arrow:setX(loc.x)
    self.arrow:setY(loc.y)
    self.arrow:setZ(loc.z)
    self.circle:setPos(loc.x, loc.y, loc.z)
    self.circle:setSize(loc.radius / 0.666)
    self.radius = loc.radius
end

---------------------------------------------------------------------------
RicksMLC_SpawnUI = ISCollapsableWindow:derive("RicksMLC_SpawnUI")
RicksMLC_SpawnUI.instance = nil


function RicksMLC_SpawnUI.Activate(playerNum)
    if RicksMLC_SpawnUI.instance == nil then
        RicksMLC_SpawnUI.instance = RicksMLC_SpawnUI:new(100, 100, 800, 600, getPlayer())
        RicksMLC_SpawnUI.instance:addToUIManager()
        RicksMLC_SpawnUI.instance:setVisible(true)
    else
        RicksMLC_SpawnUI.instance:setVisible(true)
    end
end

function RicksMLC_SpawnUI:close()
    ISCollapsableWindow.close(self)

    self.safeHouseRangeUI:Remove()
    self.safeZoneSpawnUI:Remove()
    self.playerSpawnZoneUI:Remove()

    self:removeFromUIManager()
    self:setVisible(false)

    RicksMLC_SpawnUI.instance = nil
end

function RicksMLC_SpawnUI:render()
	ISCollapsableWindow.render(self)
end


function RicksMLC_SpawnUI:update()
    ISCollapsableWindow.update(self)

    local radius = tonumber(self.safeZoneCtrls.sliderField:getText()) or self.safeZoneRadius 
    if radius ~= self.safeZoneRadius then
        self.safeZoneRadius = radius
        self.safeZoneCtrls.slider:setCurrentValue(self.safeZoneRadius)
        self:UpdateServerSafeZoneRadius()
    end

    local playerRadius = tonumber(self.playerSpawnZoneCtrls.sliderField:getText()) or self.playerSpawnZoneUI.radius
    if playerRadius ~= self.playerSpawnZoneUI.radius then
        self.playerSpawnZoneUI.radius = playerRadius
        self.playerSpawnZoneCtrls.slider:setCurrentValue(self.playerSpawnZoneUI.radius)
    end

    local playerOffset = tonumber(self.playerSpawnOffsetCtrls.sliderField:getText()) or self.playerSpawnZoneUI.offset
    if playerOffset ~= self.playerSpawnZoneUI.offset then
        self.playerSpawnZoneUI.offset = playerOffset
        self.playerSpawnOffsetCtrls.slider:setCurrentValue(self.playerSpawnZoneUI.offset)
    end

    local playerLoc = { x = self.player:getX(), y = self.player:getY(), z = 0}
    local playerRadius = self.playerSpawnZoneUI.radius
    local playerSpawnLoc = RicksMLC_SpawnCommon.MakeSpawnLocation(self.player, self.playerSpawnZoneUI.radius, self.playerSpawnZoneUI.offset, self.playerSpawnZoneUI.facing, nil) 
    local houseSafeZoneLoc = RicksMLC_SpawnCommon.CalcSafeZoneSpawnPoint(playerSpawnLoc, playerRadius, self.safeZoneRadius)
    local playerSafeZoneLoc = RicksMLC_SpawnCommon.CalcSafeZoneSpawnPoint(playerLoc, playerRadius, self.safeZoneRadius)
    -- Use the playerSafeZoneLoc to determine if the zones are displayed, but use the houseSafeZoneLoc for the actual display
    -- In this way the safe zone display is based on the player location relative to the safehouse.  The spawn display is the actual 
    -- spawn location.

    if houseSafeZoneLoc and houseSafeZoneLoc.safehouse then
        self.safeZoneSpawnUI:SetActive(true)
        self.safeZoneSpawnUI:CreateOrUpdate(houseSafeZoneLoc)
        self.safeHouseRangeUI:SetActive(true)
        self.safeHouseRangeUI:CreateOrUpdate(houseSafeZoneLoc.safehouse)
    elseif playerSafeZoneLoc and playerSafeZoneLoc.safehouse then
        self.safeZoneSpawnUI:SetActive(true)
        self.safeZoneSpawnUI:CreateOrUpdate(playerSafeZoneLoc)
        self.safeHouseRangeUI:SetActive(true)
        self.safeHouseRangeUI:CreateOrUpdate(playerSafeZoneLoc.safehouse)
    else
        self.safeZoneSpawnUI:SetActive(false)
        self.safeHouseRangeUI:SetActive(false)
    end

    playerSpawnLoc.radius = self.playerSpawnZoneUI.radius -- Fiddle the playerSpawnLoc so it has a radius so the spawn loc will appear.
    if playerSpawnLoc then
        self.playerSpawnZoneUI:CreateOrUpdate(playerSpawnLoc)
    end
end

function RicksMLC_SpawnUI:UpdateServerSafeZoneRadius()
    if isClient() and (isCoopHost() or isAdmin()) then
        if RicksMLC_SpawnHandlerC.instance.safehouseSafeZoneRadius ~= self.safeZoneRadius then
            local args = { safeZoneRadius = self.safeZoneRadius }
            --RicksMLC_SpawnCommon.DumpArgs(args, 0, "RicksMLC_SpawnUI:UpdateServerSafeZoneRadius()")
            sendClientCommand(getPlayer(), 'RicksMLC_Zombies', 'UpdateSafeZoneFromClient', args)
        end
    end
end

function RicksMLC_SpawnUI:new(x, y, width, height, player)
    local width = 440
	local height = 140
	local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.player = player
    o.title = "Rick's MLC Spawn Zone Tool"
    o.safeZoneRadius = RicksMLC_SpawnHandlerC.instance.safehouseSafeZoneRadius or 10
    o.safeZoneCtrls = nil
    o.playerSpawnZoneCtrls = nil

    return o
end

function RicksMLC_SpawnUI.onSliderChangePlayerZone(slider, newValue)
    if not (RicksMLC_SpawnUI.instance and RicksMLC_SpawnUI.instance.playerSpawnZoneCtrls) then return end
    RicksMLC_SpawnUI.instance.playerSpawnZoneCtrls.sliderField:setText(tostring(newValue))
end

function RicksMLC_SpawnUI.onSliderChangePlayerOffset(slider, newValue)
    if not (RicksMLC_SpawnUI.instance and RicksMLC_SpawnUI.instance.playerSpawnOffsetCtrls) then return end
    RicksMLC_SpawnUI.instance.playerSpawnOffsetCtrls.sliderField:setText(tostring(newValue))
end

function RicksMLC_SpawnUI.onSliderChange(slider, newValue)
    if not (RicksMLC_SpawnUI.instance and RicksMLC_SpawnUI.instance.safeZoneCtrls) then return end
    RicksMLC_SpawnUI.instance.safeZoneCtrls.sliderField:setText(tostring(newValue))
end

function RicksMLC_SpawnUI:CreateSlider(y, name, defaultValue, onChangeFn, tooltip)
    local sliderCtrls = {}

    sliderCtrls.sliderLabel = ISLabel:new(2, y, 16, name, 1, 1, 1, 1.0, UIFont.Small, true);
    sliderCtrls.sliderLabel:initialise()
    sliderCtrls.sliderLabel:instantiate()
    self:addChild(sliderCtrls.sliderLabel)

    local sliderLabelWidth = sliderCtrls.sliderLabel:getWidth() -- 50?
    local sliderWidth = 200
    local sliderX = 150 -- sliderLabelWidth + 10
    --DebugLog.log(DebugType.Mod, "RicksMLC_SpawnUI:createSlider(): " .. tostring(sliderLabelWidth))
    sliderCtrls.sliderField = ISTextEntryBox:new(tostring(defaultValue), sliderX + sliderWidth + 10, y, 26, 15)
    sliderCtrls.sliderField:initialise()
    sliderCtrls.sliderField:instantiate()
    sliderCtrls.sliderField:setOnlyNumbers(true)
    sliderCtrls.sliderField.tooltip = tooltip
    self:addChild(sliderCtrls.sliderField)

    sliderCtrls.slider = ISSliderPanel:new(sliderX, y, sliderWidth, 20, self, onChangeFn)
    sliderCtrls.slider.anchorTop = true
    sliderCtrls.slider:initialise()
    sliderCtrls.slider:instantiate()
    sliderCtrls.slider:setValues(1, 100, 1, 10)
    sliderCtrls.slider:setCurrentValue(defaultValue)
    sliderCtrls.slider:setVisible(true)
    self:addChild(sliderCtrls.slider)
    return sliderCtrls
end

function RicksMLC_SpawnUI:createChildren()
    ISCollapsableWindow.createChildren(self)

    local th = self:titleBarHeight()

    y = th + 10

    self.safeZoneCtrls = self:CreateSlider(y, "Safe Zone Radius", self.safeZoneRadius, RicksMLC_SpawnUI.onSliderChange, "Safehouse safe zone on the server.  Zombies will not spawn in this area")
    y = self.safeZoneCtrls.slider:getY() + self.safeZoneCtrls.slider:getHeight() + 10

    self.playerSpawnZoneCtrls = self:CreateSlider(y, "Player Spawn Zone", 3, RicksMLC_SpawnUI.onSliderChangePlayerZone, "Example player spawn zone radius (not stored)")
    y = self.playerSpawnZoneCtrls.slider:getY() + self.playerSpawnZoneCtrls.slider:getHeight() + 10

    self.playerSpawnOffsetCtrls = self:CreateSlider(y, "Player Spawn Offset", 10, RicksMLC_SpawnUI.onSliderChangePlayerOffset,  "Example player spawn zone offset (not stored)")
    y = self.playerSpawnOffsetCtrls.slider:getY() + self.playerSpawnOffsetCtrls.slider:getHeight() + 10

    -- Safe house and player spawn circles and arrows
    self.safeHouseRangeUI = RicksMLC_SpawnPointUIElement:new("Safehouse Range", self.player, {r = 0.0, g = 0.8, b = 0.2, a = 0.5}, {r = 0.0, g = 0.8, b = 0.2, a = 0.5})
    self.safeZoneSpawnUI = RicksMLC_SpawnPointUIElement:new("Safe Zone Spawn", self.player, {r = 0.8, g = 0.5, b = 0.2, a = 0.5}, {r = 0.8, g = 0.5, b = 0.2, a = 0.5})
    self.playerSpawnZoneUI = RicksMLC_SpawnPointUIElement:new("Player Spawn Zone", self.player, {r = 0.2, g = 0.2, b = 0.8, a = 0.5}, {r = 0.2, g = 0.2, b = 0.8, a = 0.5})
    self.playerSpawnZoneUI.radius = 3
    self.playerSpawnZoneUI.offset = 10
    self.playerSpawnZoneUI.facing = true
end

function RicksMLC_SpawnUI.OnFillWorldObjectContextMenu(player, context, worldobjects, test)
    context:addOption("Rick's MLC Spawn Info", player, RicksMLC_SpawnUI.Activate)
end

function RicksMLC_SpawnUI.OnCreatePlayer(playerNumber, player)
    DebugLog.log(DebugType.Mod, "RicksMLC_SpawnUI.OnCreatePlayer() " .. tostring(player))

    if not player then return end

    if isClient() then
        Events.OnFillWorldObjectContextMenu.Remove(RicksMLC_SpawnUI.OnFillWorldObjectContextMenu) -- to prevent multiple menu items on respawn
        Events.OnFillWorldObjectContextMenu.Add(RicksMLC_SpawnUI.OnFillWorldObjectContextMenu)
    end
end

function RicksMLC_SpawnUI.OnPlayerDeath(player)
    if player == getPlayer() and RicksMLC_SpawnUI.instance then
        RicksMLC_SpawnUI.instance:close()
    end
end

Events.OnCreatePlayer.Add(RicksMLC_SpawnUI.OnCreatePlayer)
Events.OnPlayerDeath.Add(RicksMLC_SpawnUI.OnPlayerDeath)
