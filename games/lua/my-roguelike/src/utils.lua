-- utils.lua
-- Utility functions: math, geometry, debug, logging
-- Public API: various helper functions
-- Dependencies: constants.lua

local Constants = require("src.constants")

local Utils = {}

-- === VECTOR MATH ===

function Utils.distance(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

function Utils.distanceSquared(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return dx * dx + dy * dy
end

function Utils.normalize(x, y)
    local len = math.sqrt(x * x + y * y)
    if len == 0 then return 0, 0 end
    return x / len, y / len
end

function Utils.angleToVector(angle)
    return math.cos(angle), math.sin(angle)
end

function Utils.vectorToAngle(x, y)
    return math.atan2(y, x)
end

function Utils.directionTo(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return Utils.normalize(dx, dy)
end

function Utils.lerp(a, b, t)
    return a + (b - a) * t
end

function Utils.clamp(val, min, max)
    return math.max(min, math.min(max, val))
end

-- === AABB COLLISION ===

-- Check if two AABB boxes overlap
function Utils.aabbOverlap(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and
           x1 + w1 > x2 and
           y1 < y2 + h2 and
           y1 + h1 > y2
end

-- Check if two circles overlap
function Utils.circleOverlap(x1, y1, r1, x2, y2, r2)
    local distSq = Utils.distanceSquared(x1, y1, x2, y2)
    local radiusSum = r1 + r2
    return distSq < radiusSum * radiusSum
end

-- Check if point is inside AABB
function Utils.pointInAABB(px, py, x, y, w, h)
    return px >= x and px <= x + w and py >= y and py <= y + h
end

-- Check if point is inside circle
function Utils.pointInCircle(px, py, cx, cy, r)
    return Utils.distanceSquared(px, py, cx, cy) < r * r
end

-- === DAMAGE CALCULATION ===

-- Calculate damage after armor reduction
function Utils.calculateDamage(baseDamage, armor)
    local reduction = 1 - math.min(
        Constants.MAX_ARMOR_REDUCTION,
        armor * Constants.ARMOR_REDUCTION_FACTOR
    )
    return baseDamage * reduction
end

-- === XP & LEVELING ===

-- Calculate XP required for next level (exponential curve)
function Utils.xpForLevel(level)
    return math.floor(100 * math.pow(level, 1.5))
end

-- === TABLE UTILITIES ===

function Utils.shallowCopy(t)
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = v
    end
    return copy
end

function Utils.tableLength(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- Fisher-Yates shuffle
function Utils.shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

-- === STRING UTILITIES ===

function Utils.formatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%d:%02d", mins, secs)
end

function Utils.round(num, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- === DEBUG & LOGGING ===

Utils.debugLog = {}
Utils.debugLogMaxLines = 10

function Utils.log(message)
    if Constants.DEBUG_ENABLED then
        print("[LOG] " .. message)
        table.insert(Utils.debugLog, message)
        if #Utils.debugLog > Utils.debugLogMaxLines then
            table.remove(Utils.debugLog, 1)
        end
    end
end

function Utils.logError(message)
    print("[ERROR] " .. message)
    -- Could write to file here
end

-- === RANDOM ===

function Utils.randomFloat(min, max)
    return min + math.random() * (max - min)
end

function Utils.randomChoice(t)
    return t[math.random(#t)]
end

-- Random point in circle (for spawn positions)
function Utils.randomPointInCircle(cx, cy, radius)
    local angle = math.random() * 2 * math.pi
    local r = math.sqrt(math.random()) * radius
    return cx + r * math.cos(angle), cy + r * math.sin(angle)
end

-- Random point in ring (annulus)
function Utils.randomPointInRing(cx, cy, innerRadius, outerRadius)
    local angle = math.random() * 2 * math.pi
    local r = math.sqrt(math.random()) * (outerRadius - innerRadius) + innerRadius
    return cx + r * math.cos(angle), cy + r * math.sin(angle)
end

return Utils

