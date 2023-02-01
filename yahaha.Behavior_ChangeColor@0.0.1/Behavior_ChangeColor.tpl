local CustomEvents = CustomEventsScope:Get("Yahaha")
local selfEntity = script:SelfEntity()

--------------------- 触发改色 ----------------------
local function ActivationChangeColor(player)
    if YaCharacterAPI.IsPlayerCharacter(player) == true then
        EventHelper.Emit(CustomEvents, "DetectColorCube", player,selfEntity )
    end
end

if YaCharacterAPI.IsPlayerCharacter(selfEntity) == false then
    PhysicsAPI.Instance(selfEntity):OnTriggerEnter(ActivationChangeColor)
end
