local function getGlobalVars()
    local g = CustomEvents.CustomGlobalVars
    if g == nil then
        CustomEvents.CustomGlobalVars = {}
        g = CustomEvents.CustomGlobalVars
    end
    if g then
        return g
    end
    EventHelper.Emit(CustomEvents, "GetGlobals", function (gv)
        g = gv
    end)
    return g
end

local function makeGVNotNil(arr)
    local g = getGlobalVars()
    for i, v in ipairs(arr) do
        if g[v] == nil then
            g[v] = {}
        end
        g = g[v]
    end
end

local new = function (cls, vGFunc, data)
    local vData = nil
    local GV = getGlobalVars()
    if vGFunc then
        vData = vGFunc(data)
        if vData then
            if GV[vData.gTName] == nil then
                GV[vData.gTName] = {}
            end
            local gObj = GV[vData.gTName][vData.gTId]
            if gObj then
                return gObj
            end
        end
    end
    local obj = {}
    for k, v in pairs(cls) do
        if k ~= "New" then
            obj[k] = v
        end
    end
    if data then
        for k, v in pairs(data) do
            obj[k] = v
        end
    end
    if obj["Construct"] then
        obj["Construct"](obj)
    end
    if vData then
        GV[vData.gTName][vData.gTId] = obj
    end
    return obj
end

local newClass = function (vGFunc)
    local obj = {}
    obj.New = function (self, data)
        return new(self, vGFunc, data)
    end
    return obj
end

local _randomSeed = os.time()

local randomInt = function(m, n)
    if n == nil then
        n = m
        m = 1
    end
    math.randomseed(_randomSeed)
    _randomSeed = _randomSeed + 1
    return math.random(m, n)
end

local tStr = function (t)
    local str = "{ "
    for k, v in pairs(t) do
        str = str .. tostring(k) .. " = " .. tostring(v) .. ", "
    end
    str = str .. "}"
    return str
end

local addServerListener = function (evName, func)
    EventHelper.AddListener(ServerEvents, evName, function(a, b, ...)
        func(...)
    end)
    EventHelper.AddListener(CustomEvents, "aiBot_" .. evName, function(...)
        func(...)
    end)
end

local Utils = {
    randomInt = randomInt,
    tStr = tStr,
    addServerListener = addServerListener
}

local exports = {
    getGlobalVars = getGlobalVars,
    makeGVNotNil = makeGVNotNil,
    newClass = newClass,
    utils = Utils
}