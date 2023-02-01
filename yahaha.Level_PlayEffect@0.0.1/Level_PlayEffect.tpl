local CustomEvents = CustomEventsScope:Get("Yahaha")

--------------- spawn  ---------------------
local function Spawn(name, position)
    return YaScene:Spawn(name, position)
end

--------------- Destroy ----------------
local function DestroyObject(entity)
    YaScene:DestroyObject(entity)
end

local function GetVfxNameByIndex(Index)
    local needDestroy = true
    local playTime = 1
    if _PlayEffect.Effect ~= nil then
        local idx = 1
        for k,v in pairs(_PlayEffect.Effect) do
            if idx == Index then
                if (v.needDestroyType == "1") then
                    needDestroy = true
                    playTime = v.playTime
                else
                    if (v.needDestroyType == "2") then
                        needDestroy = false
                        playTime = 999
                    end
                end
                return v.vfxName, needDestroy, playTime
            end
            idx = idx + 1
        end
    end
end

function SpawnEffect(player)
    local playerMovable = YaScene:GetComponent(script:GetComponentType("YaMovableComponent"), player)
    local position = playerMovable:GetPosition()
    print(position.x,position.y,position.z)
    local vfxName, needDestroy, playTime = GetVfxNameByIndex(1)
    print(vfxName)
    local effEntity = Spawn(vfxName, position)
    print(effEntity.EntityId)
    local p = YaEquipParameter.Instance():EnableRotationAxis(true):RotationOffset(float3.New(90, 0, 0)):PositionOffset(float3.New(0, 2, 0))
    YaCharacterAPI.Instance(player):Equip(effEntity, p)
    local timer = YaTime:WaitFor(0.5);
    EventHelper.AddListener(timer, "TimeEvent", function(...)
        local vfx = YaScene:GetComponent(script:GetComponentType("YaVfxComponent"), effEntity)
        vfx:RePlay()
    end)
end


function OnSpawned(playerId,pointEntity, playerEntity)
    local timer = YaTime:WaitFor(6)
    EventHelper.AddListener(timer, "TimeEvent", function(...)
        SpawnEffect(playerEntity)
    end)
end


function OnJoined(playerId)
    local player = YaGame:GetPlayer(playerId)
    EventHelper.AddListener(player, "SpawnedEvent", OnSpawned)
end

EventHelper.AddListener(YaGame, "PlayerJoinedEvent", OnJoined)



