local common = x_require("common")

local _tmpPos = float3.New(0, 0, 0)
local Vec3 = common.newClass()

--设值
Vec3.set = function (self, x, y, z)
    if x then
        self.x = x
    end
    if y then
        self.y = y
    end
    if z then
        self.z = z
    end
end

--克隆
Vec3.clone = function (self, v)
    self.x = v.x
    self.y = v.y
    self.z = v.z
end

-- 向量相加
Vec3.add = function (self, v)
    local v1 = self
    local v2 = v
    local v = Vec3:New()
    v:set(v1.x + v2.x, v1.y + v2.y, v1.z + v2.z)
    return v
end

--向量相减
Vec3.sub = function (self, v)
    local v1 = self
    local v2 = v
    local v = Vec3:New()
    v:set(v1.x - v2.x, v1.y - v2.y, v1.z - v2.z)
    return v
end

-- 向量点乘
Vec3.dot = function (self, v)
    local v1 = self
    local v2 = v
    return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z
end
 
-- 向量叉乘
Vec3.cross = function (self, v)
    local v1 = self
    local v2 = v
    local v = Vec3:New()
    v:set(v1.y * v2.z - v2.y * v1.z, v2.x * v1.z - v1.x * v2.z, v1.x * v2.y - v2.x * v1.y)
    return v
end

-- 向量除法
Vec3.div = function (self, d)
    local v1 = self
    local v = Vec3:New()
    v:set(v1.x / d, v1.y / d, v1.z / d)
    return v
end
 
-- 向量的模
Vec3.magnitude = function (self)
    local v = self
    return math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
end

--归一化
Vec3.normalize = function (self)
    local v1 = self
	local num = v1:magnitude()
	if num == 1 then
        local v = Vec3:New()
        v:clone(v1)
        return v
    elseif num > 1e-5 then
        return v1:div(num)
    else
        local v = Vec3:New()
        v:set(0, 0, 0)
        return v
	end
end
 
-- 求两向量间夹角
Vec3.getAngle = function (self, v)
    local v1 = self
    local v2 = v
    local cos = v1:dot(v2) / (v1:magnitude() * v2:magnitude())
    return math.acos(cos) * 180 / math.pi
end

-- 绕y轴顺时针旋转a度
Vec3.yRotate = function (self, a)
    local v = self
    a = a * -1
    local sinA = math.sin(math.rad(a))
    local cosA = math.cos(math.rad(a))
    if math.abs(a) == 90 then
        cosA = 0
    elseif math.abs(a) == 180 then
        sinA = 0
    end
    self:set(v.x * cosA - v.z * sinA, nil, v.x * sinA + v.z * cosA)
end

-- 给定长度和y轴上的角度，返回一个向量
Vec3.dirVec = function (m, a)
    local v = Vec3:New()
    v:set(m * math.sin(math.rad(a)), 0, m * math.cos(math.rad(a)))
    return v
end

Vec3.toPoint = function (self, new)
    local pos = _tmpPos
    if new then
        pos = float3.New(0, 0, 0)
    end
    pos.x = self.x
    pos.y = self.y
    pos.z = self.z
    return pos
end

Vec3.fromPoint = function (p)
    local v = Vec3:New()
    v.x = p.x
    v.y = p.y
    v.z = p.z
    return v
end

Vec3.str = function (self)
    return "(" .. tostring(self.x) .. ", " .. tostring(self.y) .. ", " .. tostring(self.z) .. ")"
end

local exports = Vec3