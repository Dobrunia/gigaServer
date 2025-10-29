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

-- Проверяет, пересекается ли круг с прямоугольником (хотя бы наполовину)
function MathUtils.circleIntersectsRect(circleX, circleY, radius, rectX, rectY, rectW, rectH)
    -- Находим ближайшую точку прямоугольника к центру круга
    local closestX = math.max(rectX, math.min(circleX, rectX + rectW))
    local closestY = math.max(rectY, math.min(circleY, rectY + rectH))
    
    -- Расстояние от центра круга до ближайшей точки прямоугольника
    local dx = circleX - closestX
    local dy = circleY - closestY
    local distance = math.sqrt(dx * dx + dy * dy)
    
    return distance <= radius
end

-- Проверяет, может ли атакующий попасть по цели навыком
function MathUtils.canAttackTarget(attacker, target, skillRange)
    local attackerCenterX = attacker.x + attacker.effectiveWidth * 0.5
    local attackerCenterY = attacker.y + attacker.effectiveHeight * 0.5
    local targetX = target.x
    local targetY = target.y
    local targetW = target.effectiveWidth
    local targetH = target.effectiveHeight
    
    return MathUtils.circleIntersectsRect(attackerCenterX, attackerCenterY, skillRange, 
                                        targetX, targetY, targetW, targetH)
end

-- Находит ближайшего противника в заданном радиусе
function MathUtils.findNearestOpponent(caster, world, maxDist)
    local list = (caster and caster.enemyId) and (world and world.heroes) or (world and world.enemies)
    if not list then return nil end
    local cx = caster.x + (caster.effectiveWidth or 0) * 0.5
    local cy = caster.y + (caster.effectiveHeight or 0) * 0.5
    local best, bestD2 = nil, (maxDist and maxDist*maxDist) or math.huge
    for i=1,#list do
        local t = list[i]
        if t and not t.isDead then
            local px = t.x + (t.effectiveWidth  or 0) * 0.5
            local py = t.y + (t.effectiveHeight or 0) * 0.5
            local dx, dy = px-cx, py-cy
            local d2 = dx*dx + dy*dy
            if d2 < bestD2 then
                best, bestD2 = {x=px,y=py}, d2
            end
        end
    end
    return best, math.sqrt(bestD2)
end

-- Поворот вектора на заданный угол (в радианах)
function MathUtils.rotateVector(x, y, angle)
    local ca, sa = math.cos(angle), math.sin(angle)
    return x*ca - y*sa, x*sa + y*ca
end

-- Проверяет, находится ли точка в секторе
function MathUtils.pointInSector(px, py, cx, cy, dx, dy, rMin, rMax, halfAngle)
    local vx, vy = px - cx, py - cy
    local dist2 = vx*vx + vy*vy
    if dist2 < rMin*rMin or dist2 > rMax*rMax then return false end
    local d = math.sqrt(dist2)
    if d < 1e-6 then return true end
    
    -- Нормализуем вектор от центра к точке
    vx, vy = vx/d, vy/d
    
    -- Вычисляем угол между направлением сектора и вектором к точке
    local dot = vx*dx + vy*dy
    if dot > 1 then dot = 1 elseif dot < -1 then dot = -1 end
    local angle = math.acos(dot)
    
    -- Проверяем, что угол меньше половины угла сектора
    -- halfAngle уже в радианах и представляет половину угла сектора
    return angle <= halfAngle
end

-- Проверяет, пересекается ли прямоугольник с сектором
function MathUtils.rectIntersectsSector(rectX, rectY, rectW, rectH, cx, cy, dx, dy, rMin, rMax, halfAngle)
    -- Проверяем углы прямоугольника
    local corners = {
        {rectX, rectY},                    -- левый верхний
        {rectX + rectW, rectY},            -- правый верхний
        {rectX, rectY + rectH},            -- левый нижний
        {rectX + rectW, rectY + rectH}     -- правый нижний
    }
    
    -- Проверяем центр прямоугольника
    local centerX = rectX + rectW * 0.5
    local centerY = rectY + rectH * 0.5
    table.insert(corners, {centerX, centerY})
    
    -- Если хотя бы одна точка попадает в сектор, считаем пересечение
    for _, corner in ipairs(corners) do
        if MathUtils.pointInSector(corner[1], corner[2], cx, cy, dx, dy, rMin, rMax, halfAngle) then
            return true
        end
    end
    
    -- Дополнительная проверка: если центр сектора находится внутри прямоугольника
    if centerX >= rectX and centerX <= rectX + rectW and 
       centerY >= rectY and centerY <= rectY + rectH then
        return true
    end
    
    return false
end

-- Получает направление от кастера к цели с учетом режима направления
function MathUtils.directionFromCaster(caster, tx, ty, followAim, directionMode)
    local cx = caster.x + (caster.effectiveWidth  or 0) * 0.5
    local cy = caster.y + (caster.effectiveHeight or 0) * 0.5
    local dx, dy
    
    if followAim then
        -- Вектор от кастера к цели
        dx, dy = tx - cx, ty - cy
    else
        dx = (caster.facing == -1) and -1 or 1
        dy = 0
    end

    if directionMode == "horizontal" then
        dx = (dx < 0) and -1 or 1
        dy = 0
    elseif directionMode == "vertical" then
        dx = 0
        dy = (cy - ty < 0) and -1 or 1
    end
    
    return MathUtils.normalize(dx, dy)
end

return MathUtils