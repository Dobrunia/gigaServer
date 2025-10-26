local Debuff = {}
Debuff.__index = Debuff

function Debuff.new(effectType, duration, params, caster)
    local self = setmetatable({}, Debuff)
    
    self.type = effectType
    self.duration = duration
    self.timeLeft = duration
    self.params = params or {}
    self.caster = caster
    self.active = true
    
    -- Визуальные параметры
    self.sprite = nil
    self.animation = nil
    self.color = {1, 1, 1, 1}
    
    -- Настраиваем эффект по типу
    self:setupDebuff()
    
    return self
end

function Debuff:setupDebuff()
    if self.type == "poison" then
        self.color = {0, 1, 0, 0.8}  -- Зеленый
        self.tickRate = self.params.tickRate or 1.0
        self.damage = self.params.damage or 5
        self.lastTick = 0
    elseif self.type == "slow" then
        self.color = {0, 0, 1, 0.6}  -- Синий
        self.slowAmount = self.params.slowAmount or 0.5
    elseif self.type == "burn" then
        self.color = {1, 0.5, 0, 0.8}  -- Оранжевый
        self.tickRate = self.params.tickRate or 0.5
        self.damage = self.params.damage or 3
        self.lastTick = 0
    elseif self.type == "freeze" then
        self.color = {0.5, 0.8, 1, 0.7}  -- Голубой
        self.freezeAmount = self.params.freezeAmount or 0.3
    elseif self.type == "stun" then
        self.color = {1, 1, 0, 0.8}  -- Желтый
    end
end

function Debuff:update(dt, target)
    if not self.active then
        return
    end
    
    self.timeLeft = self.timeLeft - dt
    
    -- Проверяем, закончился ли эффект
    if self.timeLeft <= 0 then
        self:remove(target)
        return
    end
    
    -- Применяем эффект в зависимости от типа
    if self.type == "poison" or self.type == "burn" then
        self:applyDamageOverTime(dt, target)
    elseif self.type == "slow" or self.type == "freeze" then
        self:applyMovementModifier(target)
    elseif self.type == "stun" then
        self:applyStun(target)
    end
end

function Debuff:applyDamageOverTime(dt, target)
    self.lastTick = self.lastTick + dt
    if self.lastTick >= self.tickRate then
        target:takeDamage(self.damage)
        self.lastTick = 0
    end
end

function Debuff:applyMovementModifier(target)
    if self.type == "slow" then
        target.moveSpeed = target.baseMoveSpeed * self.slowAmount
    elseif self.type == "freeze" then
        target.moveSpeed = target.baseMoveSpeed * self.freezeAmount
    end
end

function Debuff:applyStun(target)
    target.moveSpeed = 0
    target.canCast = false
end

function Debuff:remove(target)
    self.active = false
    
    -- Восстанавливаем параметры цели
    if self.type == "slow" or self.type == "freeze" then
        target.moveSpeed = target.baseMoveSpeed
    elseif self.type == "stun" then
        target.moveSpeed = target.baseMoveSpeed
        target.canCast = true
    end
end

function Debuff:draw(target)
    if not self.active then
        return
    end
    
    -- Рисуем цветовой эффект поверх существа
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", target.x, target.y, target.width, target.height)
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Рисуем индикатор времени эффекта
    local barWidth = target.width
    local barHeight = 2
    local barX = target.x
    local barY = target.y - 15
    
    -- Фон индикатора
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
    
    -- Прогресс эффекта
    local progress = self.timeLeft / self.duration
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.8)
    love.graphics.rectangle("fill", barX, barY, barWidth * progress, barHeight)
    love.graphics.setColor(1, 1, 1, 1)
end

function Debuff:getTimeLeft()
    return self.timeLeft
end

function Debuff:isActive()
    return self.active
end

return Debuff
