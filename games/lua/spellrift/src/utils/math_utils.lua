local MathUtils = {}
MathUtils.__index = MathUtils

function MathUtils.deepCopy(original)
    if type(original) ~= "table" then
        return original
    end
    
    local copy = {}
    for key, value in pairs(original) do
        copy[key] = MathUtils.deepCopy(value)
    end
    return copy
end

-- Вычисление расстояния между двумя точками
function MathUtils.distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx*dx + dy*dy)
end

-- Вычисление расстояния между двумя объектами
function MathUtils.distanceBetween(obj1, obj2)
    return MathUtils.distance(obj1.x, obj1.y, obj2.x, obj2.y)
end

-- Нормализация вектора
function MathUtils.normalize(x, y)
    local length = math.sqrt(x*x + y*y)
    if length > 0 then
        return x/length, y/length
    end
    return 0, 0
end

-- Направление от точки A к точке B
function MathUtils.direction(fromX, fromY, toX, toY)
    return MathUtils.normalize(toX - fromX, toY - fromY)
end

-- Направление от объекта A к объекту B
function MathUtils.directionBetween(from, to)
    return MathUtils.direction(from.x, from.y, to.x, to.y)
end

-- Проверка, находится ли точка в радиусе
function MathUtils.isInRange(x1, y1, x2, y2, range)
    return MathUtils.distance(x1, y1, x2, y2) <= range
end

-- Проверка, находится ли объект в радиусе от другого объекта
function MathUtils.isObjectInRange(obj1, obj2, range)
    return MathUtils.distanceBetween(obj1, obj2) <= range
end

-- Интерполяция между двумя значениями
function MathUtils.lerp(a, b, t)
    return a + (b - a) * t
end

-- Ограничение значения в диапазоне
function MathUtils.clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

-- Случайное число в диапазоне
function MathUtils.randomRange(min, max)
    return min + math.random() * (max - min)
end

-- Округление числа до указанного количества знаков после запятой
function MathUtils.round(num, decimals)
    if num == nil then
        return 0
    end
    local mult = 10^(decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- Форматирование времени в MM:SS
function MathUtils.formatTime(seconds)
    if seconds == nil then
        return "00:00"
    end
    local minutes = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d", minutes, secs)
end

return MathUtils