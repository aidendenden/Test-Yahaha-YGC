local CustomEvents = CustomEventsScope:Get("Yahaha")
local DefaultColor = float3.New(0.4980389, 0.4980389, 0.4980389)
local champion = YaEntity.New(_ColorWarGameManager.Champion)
local crownlocation = _ColorWarGameManager.Crownlocation
local ChampionPlayer = nil
local DetectMode = 0
local PropsSkillsTable = {}
local PropsEntityTable = {}
local PlayerColorTable = {}
local ColorCubeTable = {}
local PlayerOwnedCubeTable = {}
local PlayerColorIsChanging = {}

--local basePosition = _movableComponent:GetPosition()
--local baseRotation = _movableComponent:GetRotation()

------------------- 随机数设置 ------------------------

math.randomseed(tostring(os.time()):reverse():sub(1, 6))

-- local _M = {}
-- function _M.random_seed()
--     local in_file = io.open("/dev/urandom", "r")
--     if in_file ~= nil then
--     	local d= in_file:read(4)
--         --math.randomseed(os.time() + d:byte(1) + (d:byte(2) * 256) + (d:byte(3) * 65536) + (d:byte(4) * 4294967296))
--         math.randomseed(tostring(os.time()):reverse():sub(1, 6)+ d:byte(1) + (d:byte(2) * 256) + (d:byte(3) * 65536) + (d:byte(4) * 4294967296))
--     else
--         math.randomseed(tostring(os.time()):reverse():sub(1, 7))
--     end
-- end
-- do return _M end

-- print(_M.random_seed)

------------------- 计算表长度 ------------------------
local function table_leng(t)
    local leng = 0
    for k, v in pairs(t) do
        leng = leng + 1
    end
    return leng;
end

------------------- 获取Entity ------------------------
local function GetPropsItemEntity(playerEntityId)
    if PropsEntityTable[playerEntityId] ~= nil then
        return PropsEntityTable[playerEntityId]
    end
    return nil
end

------------------- 改回默认颜色 ------------------------
local function ChangeBackToDefaultColor(TargetEntity)
    YaDisplayObjectAPI.SetColor(TargetEntity, DefaultColor)
end

------------------- 赐予颜色 ------------------------
local function GiveColor(playerEntityId)

    local R = 0
    local G = 0
    local B = 0

    local playerColor = float3.New(R, G, B)

    if PlayerColorTable == nil then
        while (R == 0.4980389 and G == 0.4980389 and B == 0.4980389) do
            R = math.random()
            G = math.random()
            B = math.random()
            playerColor = float3.New(R, G, B)
        end
    else

        local allColorTable = {}
        allColorTable = PlayerColorTable
        allColorTable[playerEntityId.EntityId] = DefaultColor

        local bo = true
        local num = 0

        while (bo) do
            R = math.random()
            G = math.random()
            B = math.random()

            playerColor = float3.New(R, G, B)

            for key, value in pairs(allColorTable) do
                if playerColor == value then
                    num = num + 1
                end
            end

            if num == 0 then
                bo = false
            elseif num > 0 then
                num = 0
            end
        end
    end

    PlayerColorTable[playerEntityId.EntityId] = playerColor
    PlayerColorIsChanging[playerEntity.EntityId] = false
end

------------------- 通过value移除表中相关值，并且改回默认颜色 ------------------------
function RemoveFromValue(t, Value)
    local idx = 1
    for k, v in pairs(t) do
        if v == Value then
            ChangeBackToDefaultColor(k)
            table.remove(t, idx)
            idx = idx - 1
        end
        idx = idx + 1
    end
end

-----------------------计算赢家 ------------------------
local function ShowWinner(PlayerEntity)
    local playerEntity = YaEntity.New(PlayerEntity)
    if playerEntity ~= nil then
        if champion == nil then
            print("No Crown")
        else
            if ChampionPlayer == nil then
                ChampionPlayer = playerEntity
                local p = YaEquipParameter.Instance():EnableRotationAxis(true):PositionOffset(crownlocation)
                YaCharacterAPI.Instance(ChampionPlayer):Equip(champion, p)
            else
                YaCharacterAPI.Instance(ChampionPlayer):Unequip(champion)
                ChampionPlayer = playerEntity
                local p = YaEquipParameter.Instance():EnableRotationAxis(true):PositionOffset(crownlocation)
                YaCharacterAPI.Instance(ChampionPlayer):Equip(champion, p)
            end
        end
    else
        print("No winner")
    end
end

local function CalculateTheWinner()
    --table.sort(PlayerOwnedCubeTable)
    local Winner = nil
    local maxNumber = nil
    for k, v in pairs(PlayerOwnedCubeTable) do
        if (maxNumber == nil) then
            maxNumber = v
        end
        if (maxNumber < v) then
            maxNumber = v
            Winner = k
        elseif (maxNumber == v) then
            Winner = k
        end
    end
    ShowWinner(Winner)
    return Winner
end

local function WinnerLog()
    local winnerPlayer = CalculateTheWinner()
    if winnerPlayer ~= nil then
        local avatarCmp = YaScene:GetComponent(script:GetComponentType("YaCharacterComponent"),
            YaEntity.New(winnerPlayer))
        local playerEntity = avatarCmp:GetPlayer()
        local player = YaScene:GetComponent(script:GetComponentType("YaPlayerComponent"), playerEntity)
        print(player:GetName())
    else
        print("No winner")
    end
end

-----------------------统计单个玩家占有方块个数 ------------------------
local function CountTheNumberOfVariousColors(playerEntity)
    local quantity = 0
    for k, v in pairs(ColorCubeTable) do
        if v == playerEntity.EntityId then
            quantity = quantity + 1
        end
    end
    PlayerOwnedCubeTable[playerEntity.EntityId] = quantity
    CalculateTheWinner()
end

------------------- 隐藏/显示 avatar ------------------------
local function SetPlayerActive(playerEntity, bo)
    PhysicsAPI.SetCollidable(playerEntity, bo)
    YaDisplayObjectAPI.SetVisibility(playerEntity, bo)
end

------------------------ 戴上- -------------------
local function WearProps(playerEntity, changeEntity, position, SkillsType)
    if PropsEntityTable[playerEntity.EntityId] == nil then
        local p = YaEquipParameter.Instance():EnableRotationAxis(true):PositionOffset(position)
        YaCharacterAPI.Instance(playerEntity):Equip(changeEntity, p)
        PropsEntityTable[playerEntity.EntityId] = changeEntity
        PropsSkillsTable[changeEntity.EntityId] = SkillsType
    end
end

----------------------- 扔下 ------------------------
local function TakeOffProps(playerEntity)
    local changeEntity = GetPropsItemEntity(playerEntity.EntityId)
    if changeEntity ~= nil then
        PropsEntityTable[playerEntity.EntityId] = nil
        PropsSkillsTable[changeEntity.EntityId] = nil
        YaCharacterAPI.Instance(playerEntity):Unequip(changeEntity)
        EventHelper.Emit(CustomEvents, "TakeOffProps", changeEntity.EntityId)
        print("props have been dropped")
        return
    end
    print("player dont have change Props" .. playerEntity.EntityId)
end

----------------------- 使用 ------------------------
local function UseProps(playerEntity)
    local changeEntity = GetPropsItemEntity(playerEntity.EntityId)
    if changeEntity ~= nil then
        PropsEntityTable[playerEntity.EntityId] = nil
        PropsSkillsTable[changeEntity.EntityId] = nil
        PhysicsAPI.SetCollidable(changeEntity, false)
        --YaDisplayObjectAPI.SetVisibility(changeEntity,false)
        YaCharacterAPI.Instance(playerEntity):Unequip(changeEntity)
        EventHelper.Emit(CustomEvents, "UseProps", changeEntity.EntityId)
        return
    end
    print("player dont have Props" .. playerEntity.EntityId)
end

----------------------- 改色 ------------------------
local function ChangeColor(playerEntity, TargetEntity)
    if PlayerColorTable[playerEntity.EntityId] ~= nil then
        YaDisplayObjectAPI.SetColor(TargetEntity, PlayerColorTable[playerEntity.EntityId])
        ColorCubeTable[TargetEntity.EntityId] = playerEntity.EntityId
        CountTheNumberOfVariousColors(playerEntity)
    else
        print("YOU NEED SETECT COLOR!")
    end
end

------------------ 场景功能--零时换色 ------------------
local function SelectColor(playerEntity, ChangeColor)
    if PlayerColorIsChanging[playerEntity.EntityId] == false then
        local OriginalColor = PlayerColorTable[playerEntity.EntityId]
        PlayerColorTable[playerEntity.EntityId] = ChangeColor
        PlayerColorIsChanging[playerEntity.EntityId] = true
        for k, v in pairs(ColorCubeTable) do
            if v == playerEntity.EntityId then
                local targetEntity = YaEntity.New(k)
                YaDisplayObjectAPI.SetColor(targetEntity, ChangeColor)
            end
        end
        local timer = YaTime:WaitFor(3)
        EventHelper.AddListener(timer, "TimeEvent", function(...)
            PlayerColorTable[playerEntity.EntityId] = OriginalColor
            for k, v in pairs(ColorCubeTable) do
                if v == playerEntity.EntityId then
                    local targetEntity = YaEntity.New(k)
                    YaDisplayObjectAPI.SetColor(targetEntity, OriginalColor)
                end
            end
            PlayerColorIsChanging[playerEntity.EntityId] = false
        end)
    end
end

----------------------- 开门 ------------------------
local function UnlockDoor(playerEntity, TargetEntity, MovingPosition)
    local changeEntity = GetPropsItemEntity(playerEntity.EntityId)
    if changeEntity ~= nil and PropsSkillsTable[changeEntity.EntityId] ~= nil and
        PropsSkillsTable[changeEntity.EntityId] == "Key" then
        UseProps(playerEntity)
        local mover = YaScene:GetComponent(script:GetComponentType("YaMoverComponent"), TargetEntity)
        if mover ~= nil then
            mover:SetSpeed(5)
            mover:SetTargetPosition(MovingPosition)
            mover:Start()
        end
        return
    end
end

----------------------- 物理爆炸 ------------------------
function PhysicalExplosion(playerEntity)
    local movableCmp = YaScene:GetComponent(script:GetComponentType("YaMovableComponent"), playerEntity)
    local position = movableCmp:GetGlobalPosition()
    local query = YaQueryParameter.Instance():GeometrySphere(_ColorWarGameManager.ExplosionRadius):QueryAllPhysicsLayer()
    local entities = PhysicsAPI.Overlap(position, query)
    print("overlap is:", entities, "pos:", position.x, position.y, position.z)
    if entities ~= nil then
        for i = 0, entities.Count - 1 do
            if entities[i].EntityId ~= playerEntity.EntityId then
                print("explosion, add explosion impulse force to ", entities[i].EntityId)
                PhysicsAPI.AddExplosionImpulseForce(entities[i], _ColorWarGameManager.ExplosionForce, position,
                    _ColorWarGameManager.ExplosionRadius, _ColorWarGameManager.ExplosionUpwardsModifier)
            end
        end
    end
end

----------------------- 国王效果 ------------------------
local function KingBuff(playerEntity)
    local movableCmp = YaScene:GetComponent(script:GetComponentType("YaMovableComponent"), playerEntity)
    local position = movableCmp:GetGlobalPosition()
    local query = YaQueryParameter.Instance():GeometrySphere(6):QueryAllPhysicsLayer()
    local entities = PhysicsAPI.Overlap(position, query)
    print("overlap is:", entities, "pos:", position.x, position.y, position.z)
    if entities ~= nil then
        for i = 0, entities.Count - 1 do
            local component = YaScene:GetComponent(script:GetComponentType("ChangeColor"), entities[i])
            if component ~= nil then
                ChangeColor(playerEntity, entities[i])
            end
        end
    end
end

---------------------- 检测方块 --------------------------
local function DetectColorCube(playerEntity, targetEntity)
    if DetectMode == 0 then
        ChangeColor(playerEntity, targetEntity)
    elseif DetectMode == 1 then
        KingBuff(playerEntity)
    end
end

----------------------- 技能使用 ------------------------

local function UseSkills(playerEntity)
    local changeEntity = GetPropsItemEntity(playerEntity.EntityId)
    if changeEntity ~= nil and PropsSkillsTable[changeEntity.EntityId] ~= nil then
        if PropsSkillsTable[changeEntity.EntityId] == "Key" then
            print("Please get close to where you need the key, the door will open automatically")
            return
        end
        if PropsSkillsTable[changeEntity.EntityId] == "SelfSpeedUp" then
            local WalkSpeed = YaCharacterAPI.Instance(playerEntity):GetWalkMaxSpeed()
            local RunSpeed = YaCharacterAPI.Instance(playerEntity):GetRunMaxSpeed()
            YaCharacterAPI.Instance(playerEntity):SetWalkMaxSpeed(15)
            YaCharacterAPI.Instance(playerEntity):SetRunMaxSpeed(15)
            UseProps(playerEntity)
            local timer = YaTime:WaitFor(3)
            EventHelper.AddListener(timer, "TimeEvent", function(...)
                YaCharacterAPI.Instance(playerEntity):SetWalkMaxSpeed(WalkSpeed)
                YaCharacterAPI.Instance(playerEntity):SetRunMaxSpeed(RunSpeed)
            end)
            return
        end
        if PropsSkillsTable[changeEntity.EntityId] == "OtherPlayersSpeedSlowly" then
            local playerlist = YaGame:GetPlayers()
            if playerlist.Length > 1 then
                for i = 0, playerlist.Length - 1 do
                    local playerAvartar = playerlist[i]:GetAvatar()
                    local playerAvartarEntity = playerAvartar:GetEntity()
                    if playerEntity.EntityId ~= playerAvartarEntity.EntityId then
                        local WalkSpeed = YaCharacterAPI.Instance(playerAvartarEntity):GetWalkMaxSpeed()
                        local RunSpeed = YaCharacterAPI.Instance(playerAvartarEntity):GetRunMaxSpeed()
                        YaCharacterAPI.Instance(playerAvartarEntity):SetWalkMaxSpeed(1)
                        YaCharacterAPI.Instance(playerAvartarEntity):SetRunMaxSpeed(1)
                        UseProps(playerEntity)
                        local timer = YaTime:WaitFor(2)
                        EventHelper.AddListener(timer, "TimeEvent", function(...)
                            YaCharacterAPI.Instance(playerAvartarEntity):SetWalkMaxSpeed(WalkSpeed)
                            YaCharacterAPI.Instance(playerAvartarEntity):SetRunMaxSpeed(RunSpeed)
                        end)
                    end
                end
            else
                print("No other players")
            end
            return
        end
        if PropsSkillsTable[changeEntity.EntityId] == "Stealth" then
            SetPlayerActive(playerEntity, false)
            UseProps(playerEntity)
            local timer = YaTime:WaitFor(5)
            EventHelper.AddListener(timer, "TimeEvent", function(...)
                SetPlayerActive(playerEntity, true)
            end)
            return
        end
        if PropsSkillsTable[changeEntity.EntityId] == "JumpHigh" then
            local JumpHeight = YaCharacterAPI.Instance(playerEntity):GetJumpHeight()
            YaCharacterAPI.Instance(playerEntity):SetJumpHeight(5)
            UseProps(playerEntity)
            local timer = YaTime:WaitFor(4)
            EventHelper.AddListener(timer, "TimeEvent", function(...)
                YaCharacterAPI.Instance(playerEntity):SetJumpHeight(JumpHeight)
            end)
            return
        end
        if PropsSkillsTable[changeEntity.EntityId] == "Shield" then
            local _info = YaScene:GetComponent(script:GetComponentType("YaCustomPropertyComponent"), playerEntity)
            _info:AddOrUpdateProperty("defence", 1000)
            print("defence : " .. _info:GetProperty("defence"))
            UseProps(playerEntity)
            local timer = YaTime:WaitFor(6)
            EventHelper.AddListener(timer, "TimeEvent", function(...)
                _info:AddOrUpdateProperty("defence", 0)
            end)
            return
        end
        if PropsSkillsTable[changeEntity.EntityId] == "PushAway" then
            UseProps(playerEntity)
            PhysicalExplosion(playerEntity)
            return
        end
        if PropsSkillsTable[changeEntity.EntityId] == "TrapBomb" then
            UseProps(playerEntity)
            -- to do spawn Bomb
            return
        end
        if PropsSkillsTable[changeEntity.EntityId] == "Smoke" then
            UseProps(playerEntity)
            -- to do spawn Smoke
            return
        end
        if PropsSkillsTable[changeEntity.EntityId] == "King" then
            DetectMode = 1
            UseProps(playerEntity)
            local timer = YaTime:WaitFor(5)
            EventHelper.AddListener(timer, "TimeEvent", function(...)
                DetectMode = 0
            end)
            return
        end
    else
        print("PropsSkillsTable is null")
    end
end

---------------------- 检测键盘按键 --------------------------
local function DetectKeyboardKeys(avatar, KeyboardKeys)
    if string.char(KeyboardKeys) == 'e' then
        UseSkills(avatar)
    end
    if string.char(KeyboardKeys) == 'q' then
        TakeOffProps(avatar)
    end
end

----------------------  AddListener --------------------------
function OnSpawned(playerId, player, pointEntity)
    local spawnerPlayer = YaGame:GetPlayer(playerId)
    local avatar = spawnerPlayer:GetAvatar():GetEntityId()
    GiveColor(avatar)
    YaInputAPI.OnKeyDown(avatar, DetectKeyboardKeys)
    YaCharacterAPI.Instance(avatar):OnDied(TakeOffProps)
    --YaCharacterAPI.Instance(avatar):OnInputAttack()
end

function OnJoined(playerId)
    local player = YaGame:GetPlayer(playerId)
    EventHelper.AddListener(player, "SpawnedEvent", OnSpawned)
end

function OnLeft(playerId)
    local leftPlayer = YaGame:GetPlayer(playerId)
    local avatar = leftPlayer:GetAvatar():GetEntityId()
    table.remove(PlayerOwnedCubeTable[avatar.EntityId])
    table.remove(PropsEntityTable[avatar.EntityId])
    table.remove(PlayerColorTable[avatar.EntityId])
    table.remove(PlayerColorIsChanging[avatar.EntityId])
    RemoveFromValue(ColorCubeTable, avatar.EntityId)
    if ChampionPlayer ~= nil and ChampionPlayer == playerId.EntityId then
        YaCharacterAPI.Instance(ChampionPlayer):Unequip(champion)
        ChampionPlayer = nil
        CalculateTheWinner()
    end
end

EventHelper.AddListener(CustomEvents, "DetectColorCube", DetectColorCube)
EventHelper.AddListener(CustomEvents, "WearProps", WearProps)
EventHelper.AddListener(CustomEvents, "SelectColor", SelectColor)
EventHelper.AddListener(CustomEvents, "UnlockDoor", UnlockDoor)

EventHelper.AddListener(YaGame, "PlayerLeftEvent", OnLeft)
EventHelper.AddListener(YaGame, "PlayerJoinedEvent", OnJoined)
