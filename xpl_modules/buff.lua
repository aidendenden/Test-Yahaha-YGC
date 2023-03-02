local common = x_require("common")
local YaTimer = x_require("timer")

local YaBuff = common.newClass()
local _tmpPos = float3.New(0, 0, 0)

--参数列表：
--buffId：Buff的ID
--time：Buff的持续时间，单位为秒，为0则为永久，默认为0
--tick: Buff的tick间隔，默认为0.5
--stackType: Buff的叠加方式，默认为0【0：独立叠加 1：新Buff会刷新已有Buff的持续时间 2：新Buff会增加现有Buff的持续时间】
--onAddCallBack：Buff添加时的回调
--onTickCallBack：Buff每个tick触发时的回调
--onRemoveCallBack：Buff删除时的回调
--vfxName: Buff对应的特效名称
--vfxHeight: Buff特效的高度
YaBuff.Construct = function (self)
    self.vfx = nil
    self.timer = YaTimer:New()
    if self.time == nil then
        self.time = 0
    end
    if self.tick == nil then
        self.tick = 0.5
    end
    if self.tick < 0.1 then
        self.tick = 0.1
    end
    if self.stackType == nil then
        self.stackType = 0
    end
end

YaBuff.onAdd = function (self, entity)
    self.entity = entity
    if self.onAddCallBack then
        self.onAddCallBack(entity)
    end
    if self.vfxName and (not self.entity:hasBuff(self.buffId)) then
        _tmpPos.x = -500
        _tmpPos.y = -500
        _tmpPos.z = -500
        self.vfx = YaScene:Spawn(self.vfxName, _tmpPos)
    end
    if self.vfx then
        entity:equipVFX(self.vfx, self.vfxHeight or 1)
    end
    if self.time ~= 0 then
        local tickCount = math.floor(self.time / self.tick)
        self.timer.tick = self.tick
        self.timer.repeatCount = tickCount
        self.timer.tickFunc = function (hitCount)
            self:onTick(hitCount)
        end
        self.timer.endFunc = function ()
            self.entity:removeBuff(self)
        end
        self.timer:start()
    end
end

YaBuff.onTick = function (self, hitCount)
    if self.onTickCallBack then
        self.onTickCallBack(self.entity, hitCount)
    end
end

YaBuff.onRemove = function (self)
    if self.onRemoveCallBack then
        self.onRemoveCallBack(self.entity)
    end
    if self.vfx then
        self.entity:unequipVFX(self.vfx)
        local movable = YaScene:GetComponent(script:GetComponentType("YaMovableComponent"), self.vfx)
        _tmpPos.x = -500
        _tmpPos.y = -500
        _tmpPos.z = -500
        movable:SetPosition(_tmpPos)
    end
    if self.timer.started then
        self.timer:stop()
    end
end

YaBuff.destroy = function (self)
    if self.vfx then
        YaScene:DestroyObject(self.vfx)
    end
end

local exports = YaBuff