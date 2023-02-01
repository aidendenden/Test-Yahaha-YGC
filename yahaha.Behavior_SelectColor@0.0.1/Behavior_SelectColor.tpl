local CustomEvents = CustomEventsScope:Get("Yahaha")
local selfEntity = script:SelfEntity()

--------------------- 触发选色 ----------------------
local function ActivationSelectColor(player)
    if YaCharacterAPI.IsPlayerCharacter(player) == true then
        EventHelper.Emit(CustomEvents, "SelectColor", player,_SelectColor.TargetColor)
    end
end

if YaCharacterAPI.IsPlayerCharacter(selfEntity) == false then
    PhysicsAPI.Instance(selfEntity):OnTriggerEnter(ActivationSelectColor)
end
