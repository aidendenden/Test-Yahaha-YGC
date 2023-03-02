local common = x_require("common")

local Array = common.newClass()

Array.Construct = function (self)
    self.data = {}
end

Array.str = function (self)
    local s = "["
    local len = #self.data
    for i = 1, len do
        s = s .. tostring(self.data[i])
        if i < len then
            s = s .. ", "
        end
    end
    s = s .. "]"
    return s
end

Array.clear = function (self)
    self.data = {}
end

Array.push = function (self, v)
    table.insert(self.data, v)
end

Array.count = function (self)
    return #self.data
end

Array.pop = function (self)
    local len = #self.data
    if len < 1 then
        return nil
    end
    local v = self.data[len]
    table.remove(self.data, len)
    return v
end

Array.shift = function (self)
    local len = #self.data
    if len < 1 then
        return nil
    end
    local v = self.data[1]
    table.remove(self.data, 1)
    return v
end

Array.remove = function (self, v)
    for i = #self.data, 1, -1 do
        if self.data[i] == v then
            table.remove(self.data, i)
        end
    end
end

Array.shuffle = function (self)
    local len = #self.data
    for i = 1, len do
        local tmp = self.data[i]
        local idx = common.utils.randomInt(1, len)
        self.data[i] = self.data[idx]
        self.data[idx] = tmp
    end
end

Array.randomPick = function (self)
    local len = #self.data
    if len > 0 then
        return self.data[common.utils.randomInt(1, len)]
    end
    return nil
end

Array.fromTable = function (self, t)
    self.data = {}
    for i, v in ipairs(t) do
        table.insert(self.data, v)
    end
end

Array.at = function (self, i)
    return self.data[i]
end

Array.len = function (self)
    return #self.data
end

Array.isEmpty = function (self)
    return #self.data < 1
end

local Map = common.newClass()

Map.Construct = function (self)
    self.data = {}
end

Map.clear = function (self)
    self.data = {}
end

Map.insert = function (self, k, v)
    self.data[k] = v
end

Map.contains = function (self, k)
    return self.data[k] ~= nil
end

Map.get = function (self, k)
    return self.data[k]
end

Map.removeByKey = function(self, key)
    self.data[key] = nil
end

Map.removeByValue = function(self, value)
    local idx = 1
    for k, v in pairs(self.data) do
        if v == value then
            table.remove(self.data, idx)
            idx = idx - 1
        end
        idx = idx + 1
    end
end

Map.kvs = function (self)
    local keys = {}
    local vals = {}
    for k, v in pairs(self.data) do
        table.insert(keys, k)
        table.insert(vals, v)
    end
    return { keys = keys, values = vals }
end

Map.isEmpty = function (self)
    local empty = true
    for k, v in pairs(self.data) do
        empty = false
        break
    end
    return empty
end

Map.foreach = function (self, func)
    for k, v in pairs(self.data) do
        func(k, v)
    end
end

local exports = {
    Array = Array,
    Map = Map
}