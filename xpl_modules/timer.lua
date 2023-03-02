local common = x_require("common")
local stl = x_require("stl")
local GV = common.getGlobalVars()
common.makeGVNotNil({ "GlobalTimer" })
local function getGVal(key, defaultValue)
    local v = GV.GlobalTimer[key]
    if v == nil then
        GV.GlobalTimer[key] = defaultValue
        v = defaultValue
    end
    return v
end
local _TimerCreated = getGVal("TimerCreated", false)
local _RegisterYaTimers = getGVal("RegisterYaTimers", stl.Map:New())

local function registerYaTimer(yaTimer)
    local idx = getGVal("RegisterYaTimerIdx", 0)
    _RegisterYaTimers:insert(idx, yaTimer)
    idx = idx + 1
    GV.GlobalTimer["RegisterYaTimerIdx"] = idx
end

if not _TimerCreated then
    GV.GlobalTimer["TimerCreated"] = true
    local function stopTimer(timer)
        if timer.endFunc then
            timer.endFunc()
        end
        timer.started = false
        timer.stopFlag = false
        timer.stopped = true
        timer.curNopCount = 0
    end
    local function tickLogic()
        local timerToRemove = {}
        _RegisterYaTimers:foreach(function (k, timer)
            if timer.stopFlag then
                stopTimer(timer)
            end
            if timer.started then
                timer.curNopCount = timer.curNopCount + 1
                if timer.curNopCount > timer.nopCountPerTick then
                    timer.curNopCount = 0
                    timer.hitCount = timer.hitCount + 1
                    if timer.tickFunc then
                        timer.tickFunc(timer.hitCount)
                    end
                    if (timer.repeatCount > 0 and timer.hitCount >= timer.repeatCount) then
                        stopTimer(timer)
                    end
                end
            end
            if timer.stopped then
                table.insert(timerToRemove, k)
            end
        end)
        for i, idx in ipairs(timerToRemove) do
            _RegisterYaTimers:removeByKey(idx)
        end
    end
    local function gTickUpdate()
        local gTimer = YaTime:WaitFor(0.02)
        EventHelper.AddListener(gTimer, "TimeEvent", function(...)
            gTickUpdate()
        end)
        tickLogic()
    end
    gTickUpdate()
end

local YaTimer = common.newClass()

--参数列表：
--tick：每次的时间间隔，默认为1
--repeatCount：重复次数，默认为1。【0为无限重复】
--tickFunc：触发时的回调
--endFunc：结束时的回调
YaTimer.Construct = function (self)
    if self.tick == nil then
        self.tick = 1
    end
    if self.repeatCount == nil then
        self.repeatCount = 1
    end
    self.started = false
    self.stopFlag = false
    self.stopped = false
    registerYaTimer(self)
end

YaTimer.start = function (self)
    -- local function tickUpdate(timer)
    --     if (not timer.stopFlag) and (timer.repeatCount == 0 or timer.hitCount < timer.repeatCount) then
    --         local tm = YaTime:WaitFor(timer.tick)
    --         EventHelper.AddListener(tm, "TimeEvent", function(...)
    --             if timer.tickFunc then
    --                 timer.tickFunc(timer.hitCount)
    --             end
    --             timer.hitCount = timer.hitCount + 1
    --             tickUpdate(timer)
    --         end)
    --     else
    --         if timer.endFunc then
    --             timer.endFunc()
    --         end
    --         timer.started = false
    --         timer.stopFlag = false
    --         timer.stopped = true
    --     end
    -- end
    self.hitCount = 0
    self.nopCountPerTick = self.tick * 50 - 1
    if self.nopCountPerTick < 0 then
        self.nopCountPerTick = 0
    end
    self.curNopCount = 0
    self.started = true
    -- tickUpdate(self)
end

YaTimer.stop = function (self)
    self.stopFlag = true
end

local exports = YaTimer