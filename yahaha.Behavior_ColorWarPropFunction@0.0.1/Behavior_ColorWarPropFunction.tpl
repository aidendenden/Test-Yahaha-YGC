local CustomEvents = CustomEventsScope:Get("Yahaha")
local selfEntity = script:SelfEntity()
local _movableComponent = script:GetYaComponent("YaMovableComponent")
--local basePosition = _movableComponent:GetPosition()
--local baseRotation = _movableComponent:GetRotation()

--------------------- 触发道具穿戴 ----------------------
local function ActivationWearProps(player)
    if YaCharacterAPI.IsPlayerCharacter(player) == true then
        EventHelper.Emit(CustomEvents, "WearProps", player,selfEntity,_ColorWarPropFunction.Proplocation,_ColorWarPropFunction.SkillsType)
    end
end
--------------------- 脱下道具  ----------------------
local function ActivationTakeOffProps(entityId)
    --local p = float3.New(0, -1.8, 0)
    local p=_movableComponent:GetPosition()
    if entityId ~= selfEntity.EntityId then
        return
    end
    local timer = YaTime:WaitFor(0.2)
    EventHelper.AddListener(timer, "TimeEvent", function(...)
        _movableComponent:SetPosition(p)
        --_movableComponent:SetRotation(_movableComponent)
    end)
end

--------------------- 使用效果  ----------------------
local function ActivationUseProps(entityId)
    local P = float3.New(0, 0, 0)
    local R = float3.New(0, 0, 0)
    --local p=_movableComponent:GetPosition()
    if entityId ~= selfEntity.EntityId then
        return
    end
    local timer = YaTime:WaitFor(0.2)
    EventHelper.AddListener(timer, "TimeEvent", function(...)
        _movableComponent:SetPosition(P)
        _movableComponent:SetRotation(R)
    end)
end

EventHelper.AddListener(CustomEvents, "UseProps", ActivationUseProps)
EventHelper.AddListener(CustomEvents, "TakeOffProps", ActivationTakeOffProps)
PhysicsAPI.Instance(selfEntity):OnTriggerEnter(ActivationWearProps)