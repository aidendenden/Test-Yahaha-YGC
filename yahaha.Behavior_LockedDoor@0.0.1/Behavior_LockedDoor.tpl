local CustomEvents = CustomEventsScope:Get("Yahaha")
local selfEntity = script:SelfEntity()
local _movableComponent = script:GetYaComponent("YaMovableComponent")
local basePosition = _movableComponent:GetPosition()

--------------------- 触发开门 ----------------------
local function ActivationUnlockDoor(player)
    if YaCharacterAPI.IsPlayerCharacter(player) == true then
        local p =_movableComponent:GetPosition()
        local P = _LockedDoor.MovingPosition
        p = p + P
        EventHelper.Emit(CustomEvents, "UnlockDoor", player,selfEntity,p)
    end
end

if YaCharacterAPI.IsPlayerCharacter(selfEntity) == false then
    PhysicsAPI.Instance(selfEntity):OnTriggerEnter(ActivationUnlockDoor)
end
