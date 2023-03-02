local YaEntity = x_require("entity")
local stl = x_require("stl")
local YaTimer = x_require("timer")

local YaSpawnPool = {}

local _pool = {}
local _entitiesToSpawn = {}

YaSpawnPool.initPool = function (data)
    for i, v in ipairs(data) do
        local name = v.name
        local count = v.count
        if _pool[name] == nil then
            _pool[name] = stl.Array:New()
        end
        for j = 1, count do
            table.insert(_entitiesToSpawn, name)
        end
    end
    local timer = YaTimer:New()
    timer.tick = 0.02
    timer.repeatCount = math.floor(#_entitiesToSpawn / 20) + 1
    timer.tickFunc = function (hitCount)
        for i = 1, 20 do
            if #_entitiesToSpawn > 0 then
                local name = _entitiesToSpawn[1]
                table.remove(_entitiesToSpawn, 1)
                local entity = YaEntity.spawn(name, -500, -500, -500)
                _pool[name]:push(entity)
            else
                break
            end
        end
    end
    timer:start()
end

YaSpawnPool.getEntityFromPool = function (name)
    local pool = _pool[name]
    if pool == nil then
        return nil
    end
    if pool:count() < 1 then
        return nil
    end
    return pool:shift()
end

YaSpawnPool.pushEntityToPool = function (name, entity)
    if _pool[name] == nil then
        _pool[name] = stl.Array:New()
    end
    local pool = _pool[name]
    entity:setPos(-500, -500, -500)
    pool:push(entity)
end

local exports = YaSpawnPool