local common = x_require("common")
local stl = x_require("stl")
local GamePhaseMgr = x_require("gamephasemgr")
local YaEntity = x_require("entity")
local YaPlayer = x_require("player")

local GV = common.getGlobalVars()
common.makeGVNotNil({ "PlayerMgrData" })
local PlayerMgr = {}
local function getGVal(key, defaultValue)
    local v = GV.PlayerMgrData[key]
    if v == nil then
        GV.PlayerMgrData[key] = defaultValue
        v = defaultValue
    end
    return v
end
local _playerMap = getGVal("playerMap", stl.Map:New())
local _playerEnterCallBacks = getGVal("playerEnterCallBacks", {})
local _avatarSpawnCallBacks = getGVal("avatarSpawnCallBacks", {})
local _playerLeftCallBacks = getGVal("playerLeftCallBacks", {})
local _playerWatchCallBacks = getGVal("playerWatchCallBacks", {})

PlayerMgr.getAllPlayerData = function ()
    return _playerMap:kvs().values
end

PlayerMgr.getPlayerData = function (actNum)
    local actStr = tostring(actNum)
    return _playerMap.data[actStr]
end

PlayerMgr.searchPlayerDataByAvatar = function (avatar)
    local avatarId = avatar.EntityId
    if type(avatar) == "table" and avatar.id then
        avatarId = avatar:id()
    end
    for k, v in pairs(_playerMap.data) do
        if v.player.avatar ~= nil and v.player.avatar:id() == avatarId then
            return v
        end
    end
    return nil
end

PlayerMgr.searchPlayerDataByEntityId = function (entityId)
    for k, v in pairs(_playerMap.data) do
        if v.player ~= nil and v.player:getEntityId() == entityId then
            return v
        end
    end
    return nil
end

PlayerMgr.onPlayerEnter = function (callback)
    table.insert(_playerEnterCallBacks, callback)
end

PlayerMgr.onAvatarSpawn = function (callback)
    table.insert(_avatarSpawnCallBacks, callback)
end

PlayerMgr.onPlayerLeft = function (callback)
    table.insert(_playerLeftCallBacks, callback)
end

PlayerMgr.onPlayerWatch = function (callback)
    table.insert(_playerWatchCallBacks, callback)
end

local function createBaseAttr()
    return { gold = 0 }
end

local function savePlayerToMap(actNum, player, isbot)
    if isbot == nil then
        isbot = false
    end
    local actStr = tostring(actNum)
    if not _playerMap:contains(actStr) then
        local isAi = isbot
        if not isAi then
            isAi = YaGame:IsAIPlayer(player:GetEntity())
        end
        local yaPlayer = YaPlayer:New({ player = player, isAI = isAi, isBot = isbot })
        local playerData = { baseAttr = createBaseAttr() }
        yaPlayer.actNum = actNum
        playerData.player = yaPlayer
        for i, v in ipairs(_playerEnterCallBacks) do
            v(playerData)
        end
        _playerMap:insert(actStr, playerData)
    end
end

local function onPlayerSpawnEvent(actNum, spEntity, avatarEntity)
    local actStr = tostring(actNum)
    if _playerMap:contains(actStr) then
        _playerMap.data[actStr].player.avatar = YaEntity:New({ entity = avatarEntity, player = _playerMap.data[actStr].player })
        _playerMap.data[actStr].player.spawnEntity = YaEntity:New({ entity = spEntity })
    end
    for i, v in ipairs(_avatarSpawnCallBacks) do
        v(actNum)
    end
end

local function GetSpectorList()
    local spectatorIdList = {}
    for i, v in pairs(_playerMap.data) do
        local perPlayerId = v.player:getActNum()
        if not v.player.isAI then
            table.insert(spectatorIdList, perPlayerId)
        end
    end
    return spectatorIdList
end

local function onPlayerLeftEvent(actNum)
    local actStr = tostring(actNum)
    if _playerMap:contains(actStr) then
        for i, v in ipairs(_playerLeftCallBacks) do
            v(actNum)
        end
        _playerMap:removeByKey(actStr)
        local spectatorList = GetSpectorList()
        EventHelper.Emit(ServerEvents, "UpdateSpectators", spectatorList)
    end
    if _playerMap:isEmpty() then
        EventHelper.Emit(CustomEvents, "Level_GameEnd")
    end
end

local function onPlayerWatchEvent(actNum)
    local yaPlayer = YaPlayer:New({ player = YaGame:GetPlayer(actNum), isAI = false, isBot = false })
    for i, v in ipairs(_playerWatchCallBacks) do
        v(yaPlayer)
    end
    local spectatorList = GetSpectorList()
    ServerEvents:EmitToOnePlayer(actNum, "UpdateSpectators", spectatorList)
end

PlayerMgr.setup = function ()
    if GV.PlayerMgrData.setuped then
        return
    end
    GV.PlayerMgrData.setuped = true
    EventHelper.AddListener(YaGame, "PlayerJoinedEvent", function(actNum)
        if not GamePhaseMgr.isBeforeGameStart() then
            ServerEvents:EmitToOnePlayer(actNum, "WatchUI_Open")
            ServerEvents:EmitToOnePlayer(actNum, "PlayerFinishEvent", actNum)
            onPlayerWatchEvent(actNum)
            return
        end
        local player = YaGame:GetPlayer(actNum)
        savePlayerToMap(actNum, player, false)
        EventHelper.AddListener(player, "SpawnedEvent", function (actNum, spawnPointEntity, avatar)
            onPlayerSpawnEvent(actNum, spawnPointEntity, avatar)
        end)
    end)
    EventHelper.AddListener(YaGame, "PlayerLeftEvent", onPlayerLeftEvent)

    EventHelper.AddListener(CustomEvents, "PlayerBotJoin", function(playerBot)
        if not GamePhaseMgr.isBeforeGameStart() then
            return
        end
        savePlayerToMap(playerBot.actNum, playerBot, true)
    end)
    EventHelper.AddListener(CustomEvents, "PlayerBotAvatarSpawned", function (data)
        if not GamePhaseMgr.isBeforeGameStart() then
            return
        end
        onPlayerSpawnEvent(data.actNum, data.spawnPointEntity, data.avatar)
    end)
    EventHelper.AddListener(CustomEvents, "PlayerBotLeft", onPlayerLeftEvent)
end

PlayerMgr.shuffleInTeams = function (teamCount, revivalPoints)
    if teamCount == nil then
        teamCount = 2
    end
    local allPs = stl.Array:New()
    for k, v in pairs(_playerMap.data) do
        allPs:push(v)
    end
    allPs:shuffle()
    for i = 1, allPs:len() do
        local teamFlag = ((i - 1) % teamCount) + 1
        allPs:at(i).player.teamFlag = teamFlag
        if revivalPoints then
            local revivalPs = revivalPoints[teamFlag]
            if revivalPs then
                local rp = revivalPs[common.utils.randomInt(1, #revivalPs)]
                if rp then
                    local playerData = allPs:at(i)
                    playerData.player.avatar:onRevival(function (entity)
                        playerData.player.avatar:setPos(rp)
                    end)
                end
            end
        end
    end
end

local exports = PlayerMgr