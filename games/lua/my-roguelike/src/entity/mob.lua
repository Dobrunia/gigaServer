local Mob = {}
Mob.__index = Mob

function Mob:new(x, y, maxHp)
    local obj = {
        x = x or 0,
        y = y or 0,
        maxHp = maxHp,
        hp = maxHp,
        dead = false, -- маркер: смерть уже обработана (onDeath вызван)
    }
    return setmetatable(obj, self)
end

-- Переместить моба (в grid-играх проверку проходимости делать в менеджере)
function Mob:move(dx, dy)
    self.x = self.x + (dx or 0)
    self.y = self.y + (dy or 0)
end

-- Возвращает true если моб мёртв (hp <= 0)
function Mob:isDead()
    return self.hp <= 0
end

-- Нанести урон. Если моб уже мёртв — ничего не делаем.
-- При достижении hp <= 0 — вызываем onDeath (только один раз).
function Mob:takeDamage(damage)
    if self:isDead() then
        return
    end
    damage = damage or 0
    self.hp = self.hp - damage

    if self.hp <= 0 then
        self.hp = 0
        if not self.dead then
            self.dead = true
            self:onDeath()
        end
    end
end

-- Лечение: нельзя лечить мёртвого. Возвращает true если лечение прошло.
function Mob:heal(amount)
    if self:isDead() then
        return false
    end
    amount = amount or 0
    self.hp = math.min(self.maxHp, self.hp + amount)
    return true
end

-- Обработчик смерти — по умолчанию помечает как dead.
-- Переопределяй в наследниках, чтобы: проиграть анимацию, выбросить предметы и т.д.
function Mob:onDeath()
    -- Default behaviour: ничего дополнительного (маркер уже установлен).
    -- Пример переопределения в наследнике:
    -- function Enemy:onDeath() dropLoot(self.x, self.y) end
end

function Mob:distanceTo(other)
    local dx = (self.x or 0) - (other.x or 0)
    local dy = (self.y or 0) - (other.y or 0)
    return math.sqrt(dx * dx + dy * dy)
end

function Mob:getPosition()
    return "(" .. tostring(self.x) .. ", " .. tostring(self.y) .. ")"
end

-- Возвращает числовые значения и строковое представление
function Mob:getHealth()
    return {hp = self.hp, maxHp = self.maxHp, text = tostring(self.hp) .. "/" .. tostring(self.maxHp)}
end

-- Доля здоровья [0..1]
function Mob:getHpRatio()
    local maxHp = self.maxHp or 1
    if maxHp <= 0 then return 0 end
    local hp = self.hp or 0
    if hp < 0 then hp = 0 end
    if hp > maxHp then hp = maxHp end
    return hp / maxHp
end

-- Рисует HP бар над мобом
-- px, py: экранные координаты верхнего левого угла тайла
-- tileSize: ширина/высота тайла
function Mob:drawHpBar(px, py, tileSize)
    if not love or not love.graphics then return end
    local barWidth = tileSize
    local barHeight = 4
    local y = py - (barHeight + 2)

    local ratio = self:getHpRatio()

    -- фон
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", px, y, barWidth, barHeight)

    -- заполнение текущим здоровьем
    love.graphics.setColor(0.15, 0.85, 0.2, 1)
    love.graphics.rectangle("fill", px, y, math.floor(barWidth * ratio), barHeight)

    -- восстановим белый цвет
    love.graphics.setColor(1, 1, 1, 1)
end

return Mob
