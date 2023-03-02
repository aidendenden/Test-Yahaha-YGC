local common = x_require("common")
local Vec3 = x_require("vec3")
local stl = x_require("stl")
local YaTimer = x_require("timer")

local XEntity = common.newClass(function (data)
    return { gTName = "Entity", gTId = data.entity.EntityId }
end)
local _tmpPos = float3.New(0, 0, 0)

XEntity.fromEntityId = function (entityId)
    return XEntity:New({ entity = YaEntity.New(entityId) })
end

local function doWithBuffVFX(selfEntity)
    selfEntity:onDead(function (avatarEntity)
        local buffList = avatarEntity.buffList
        for i, v in ipairs(buffList.data) do
            local buff = v
            if buff.vfx then
                avatarEntity:unequipVFX(buff.vfx)
                local movable = YaScene:GetComponent(script:GetComponentType("YaMovableComponent"), buff.vfx)
                _tmpPos.x = 5000
                _tmpPos.y = 5000
                _tmpPos.z = 5000
                movable:SetPosition(_tmpPos)
            end
        end
    end)
    selfEntity:onRevival(function (avatarEntity)
        local buffList = avatarEntity.buffList
        for i, v in ipairs(buffList.data) do
            local buff = v
            if buff.vfx then
                avatarEntity:equipVFX(buff.vfx, buff.vfxHeight or 1)
            end
        end
    end)
end

XEntity.Construct = function (self)
    self.buffList = stl.Array:New()
    self.botMoveData = nil
    self.player = self.player or nil
    self.movableCmp = YaScene:GetComponent(script:GetComponentType("YaMovableComponent"), self.entity)
    doWithBuffVFX(self)
end

XEntity.setPos = function (self, x, y, z)
    local movable = self.movableCmp
    if movable then
        if type(x) == "number" then
            _tmpPos.x = x
            _tmpPos.y = y
            _tmpPos.z = z
            movable:SetPosition(_tmpPos)
        elseif type(x) == "table" and x.x then
            _tmpPos.x = x.x
            _tmpPos.y = x.y
            _tmpPos.z = x.z
            movable:SetPosition(_tmpPos)
        else
            movable:SetPosition(x)
        end
    else
        error("Entity[" .. tostring(self.entity.EntityId) .. "] have no movable component!")
    end
end

XEntity.characterSetRotation = function (self, y)
    if self:isAvatar() then
        YaCharacterAPI.Instance(self.entity):SetRotation(math.rad(y))
    end
end

XEntity.getPos = function (self)
    local movable = self.movableCmp
    if movable then
        return Vec3.fromPoint(movable:GetPosition())
    end
    return nil
end

XEntity.setRotation = function (self, x, y, z)
    local movable = self.movableCmp
    if movable then
        if type(x) == "number" then
            _tmpPos.x = x
            _tmpPos.y = y
            _tmpPos.z = z
            movable:SetRotationEuler(_tmpPos)
        elseif type(x) == "table" and x.x then
            _tmpPos.x = x.x
            _tmpPos.y = x.y
            _tmpPos.z = x.z
            movable:SetRotationEuler(_tmpPos)
        else
            movable:SetRotationEuler(x)
        end
    else
        error("Entity[" .. tostring(self.entity.EntityId) .. "] have no movable component!")
    end
end

XEntity.getRotation = function (self)
    local movable = self.movableCmp
    if movable then
        return Vec3.fromPoint(movable:GetRotationEuler())
    end
    return nil
end

XEntity.killMe = function (self)
    local damageCmp = YaScene:GetComponent(script:GetComponentType("DamageableComponent"), self.entity)
    if damageCmp then
        damageCmp:ApplyDamage(damageCmp.MaxHitPoints * 2)
    else
        if self:isBot() then
            self.player:killMe()
        end
    end
end

XEntity.onTriggerEnter = function (self, callback)
    PhysicsAPI.Instance(self.entity):OnTriggerEnter(function (entity)
        callback(XEntity:New({ entity = entity }))
    end)
end

XEntity.onTriggerExit = function (self, callback)
    PhysicsAPI.Instance(self.entity):OnTriggerExit(function (entity)
        callback(XEntity:New({ entity = entity }))
    end)
end

XEntity.onEnterHit = function (self, callback)
    if self:isAvatar() then
        YaCharacterAPI.Instance(self.entity):OnEnterHit(function (entity, hitLocation, normalDirection)
            callback(XEntity:New({ entity = entity }))
        end)
    end
end

XEntity.onExitHit = function (self, callback)
    if self:isAvatar() then
        YaCharacterAPI.Instance(self.entity):OnExitHit(function (entity, hitLocation, normalDirection)
            callback(XEntity:New({ entity = entity }))
        end)
    end
end

XEntity.onDead = function (self, callback)
    if self:isAvatar() then
        if self:isBot() then
            self.player.player:onDead(callback)
        else
            YaCharacterAPI.Instance(self.entity):OnDied(function(entity)
                callback(XEntity:New({ entity = entity }))
            end)
        end
    end
end

XEntity.onRevival = function (self, callback)
    if self:isAvatar() then
        if self:isBot() then
            self.player.player:onRevival(callback)
        else
            YaCharacterAPI.Instance(self.entity):OnRevival(function (entity)
                callback(XEntity:New({ entity = self.entity }))
            end)
        end
    end
end

XEntity.spawn = function (spawnName, x, y, z)
    _tmpPos.x = x
    _tmpPos.y = y
    _tmpPos.z = z
    return XEntity:New({ entity = YaScene:Spawn(spawnName, _tmpPos) })
end

XEntity.isBot = function (self)
    return self.player and self.player:isBotPlayer()
end

XEntity.getPlayer = function (self)
    return self.player
end

XEntity.isAvatar = function (self)
    if self:id() > 100000 then
        return true
    end
    if self:isBot() then
        return true
    end
    return YaCharacterAPI.IsPlayerCharacter(self.entity)
end

XEntity.id = function (self)
    return self.entity.EntityId
end

XEntity.enableInput = function (self, b)
    if not self:isAvatar() then
        return
    end
    if self:isBot() then
        self.inputEnabled = b
        if not b then
            --如果是PlayerBot，要让它停下来
            if self.botMoveData then
                self.botMoveData.timer:stop()
            end
        end
        return
    end
    if b then
        YaCharacterAPI.Instance(self.entity):EnableInput()
    else
        YaCharacterAPI.Instance(self.entity):DisabledInput()
        if self.player and YaGame:IsAIPlayer(self.player.player:GetEntity()) then
            YaCharacterAPI.Instance(self.entity):ClearMoveToTarget()
        end
    end
    self.inputEnabled = b
end

XEntity.isInputEnabled = function (self)
    if self.inputEnabled == nil then
        return true
    end
    return self.inputEnabled
end

XEntity.isDead = function (self)
    if self:isBot() then
        return not self.player.player:isAlive()
    end
    return YaCharacterAPI.Instance(self.entity):GetIsDie()
end

XEntity.equipVFX = function (self, vfx, yAxis, rAxis)
    if not self:isAvatar() then
        return
    end
    if self:isBot() then
        return
    end
    _tmpPos.x = 0
    _tmpPos.y = yAxis
    _tmpPos.z = 0
    local p = YaEquipParameter.Instance():EnableRotationAxis(rAxis or true):PositionOffset(_tmpPos)
    YaCharacterAPI.Instance(self.entity):Equip(vfx, p)
end

XEntity.unequipVFX = function (self, vfx)
    if not self:isAvatar() then
        return
    end
    if self:isBot() then
        return
    end
    YaCharacterAPI.Instance(self.entity):Unequip(vfx)
end

XEntity.addBuff = function (self, buff)
    buff:onAdd(self)
    if buff.stackType == 0 then
        self.buffList:push(buff)
    else
        local found = false
        for i, k in ipairs(self.buffList.data) do
            if k.buffId == buff.buffId then
                if buff.stackType == 1 then
                    k.time = buff.time
                else
                    k.time = k.time + buff.time
                end
                found = true
                break
            end
        end
        if not found then
            self.buffList:push(buff)
        end
    end
end

XEntity.hasBuff = function (self, buffId)
    for i, v in ipairs(self.buffList.data) do
        if v.buffId == buffId then
            return true
        end
    end
    return false
end

XEntity.removeBuff = function (self, buff)
    buff:onRemove(buff)
    self.buffList:remove(buff)
end

XEntity.removeBuffById = function (self, buffId)
    for i = #self.buffList.data, 1, -1 do
        local buff = self.buffList:at(i)
        if buff.buffId == buffId then
            table.remove(self.buffList.data, i)
        end
    end
end

XEntity.playAnim = function (self, animName)
    if self:isAvatar() then
        YaAnimatorAPI.Instance(self.entity):Play(animName)
    end
end

XEntity.aiMoveTo = function (self, x, y, z)
    if self:isBot() then
        self:botMoveTo(x, y, z)
        return
    end
    local tPoint = x
    if self:isAvatar() then
        if type(x) == "number" then
            _tmpPos.x = x
            _tmpPos.y = y
            _tmpPos.z = z
            tPoint = _tmpPos
        elseif type(x) == "table" and x.x then
            _tmpPos.x = x.x
            _tmpPos.y = x.y
            _tmpPos.z = x.z
            tPoint = _tmpPos
        end
        YaCharacterAPI.Instance(self.entity):MoveTo(tPoint)
    end
end

XEntity.aiMoveToByNavigation = function (self, x, y, z)
    if self:isBot() then
        self:botMoveTo(x, y, z)
        return true
    end
    local tPoint = x
    if self:isAvatar() then
        if type(x) == "number" then
            _tmpPos.x = x
            _tmpPos.y = y
            _tmpPos.z = z
            tPoint = _tmpPos
        elseif type(x) == "table" and x.x then
            _tmpPos.x = x.x
            _tmpPos.y = x.y
            _tmpPos.z = x.z
            tPoint = _tmpPos
        end
        return YaCharacterAPI.Instance(self.entity):TryMoveToByNavigation(tPoint)
    end
    return false
end

XEntity.botMoveTo = function (self, x, y, z)
    if self.botMoveData then
        self.botMoveData.timer:stop()
    end
    if self:isBot() then
        self.botMoveData = {}
        local tPoint = Vec3:New()
        if type(x) == "number" then
            tPoint:set(x, y, z)
        elseif type(x) == "table" and x.x then
            tPoint:set(x.x, x.y, x.z)
        else
            tPoint:set(x.x, x.y, x.z)
        end
        self.botMoveData.targetPos = tPoint
        self.botMoveData.timer = YaTimer:New({
            repeatCount = 0,
            tick = 0.02,
            tickFunc = function (hitCount)
                local tPoint = self.botMoveData.targetPos
                local pos = self:getPos()
                local tv = tPoint:sub(pos)
                if tv:magnitude() > 0.1 then
                    tv = tv:normalize()
                    tv = tv:div(5)
                    tPoint = pos:add(tv)
                    self:setPos(tPoint)
                else
                    self.botMoveData.timer:stop()
                    self.botMoveData = nil
                end
            end
        })
        self.botMoveData.timer:start()
    end
end

XEntity.setCollidable = function (self, b)
    PhysicsAPI.SetCollidable(self.entity, b)
end

XEntity.Destroy = function (self)
    YaScene:DestroyObject(self.entity)
end

XEntity.jump = function (self, t)
    if self:isAvatar() then
        if t == nil then
            t = 0.5
        end
        log("jump start")
        YaCharacterAPI.Instance(self.entity):StartJumping()
        YaTimer:New({ tick = t, endFunc = function ()
            YaCharacterAPI.Instance(self.entity):StopJumping()
            log("jump end")
        end }):start()
    end
end

XEntity.str = function (self)
    return "{ EntityId：" .. tostring(self.entity.EntityId) .. " }"
end

local exports = XEntity