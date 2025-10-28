local DamageNumber = {}
DamageNumber.__index = DamageNumber

function DamageNumber.new(x, y, damage, color)
    local self = setmetatable({}, DamageNumber)
    
    self.x = x
    self.y = y
    self.damage = damage
    self.color = color or {1, 0, 0, 1} -- красный по умолчанию
    self.lifeTime = 1.0 -- время жизни в секундах
    self.maxLifeTime = 1.0
    self.velocityY = -50 -- скорость движения вверх
    self.active = true
    
    return self
end

function DamageNumber:update(dt)
    if not self.active then return end
    
    self.lifeTime = self.lifeTime - dt
    if self.lifeTime <= 0 then
        self.active = false
        return
    end
    
    -- Движение вверх
    self.y = self.y + self.velocityY * dt
    
    -- Замедление со временем
    self.velocityY = self.velocityY * 0.95
end

function DamageNumber:draw()
    if not self.active then return end
    
    -- Прозрачность зависит от оставшегося времени жизни
    local alpha = self.lifeTime / self.maxLifeTime
    local r, g, b = self.color[1], self.color[2], self.color[3]
    
    love.graphics.setColor(r, g, b, alpha)
    
    -- Размер шрифта зависит от величины урона
    local fontSize = math.min(24, math.max(12, 12 + self.damage * 0.5))
    love.graphics.setFont(love.graphics.newFont(fontSize))
    
    -- Центрируем текст
    local text = tostring(math.floor(self.damage))
    local textWidth = love.graphics.getFont():getWidth(text)
    local textHeight = love.graphics.getFont():getHeight()
    
    local drawX = self.x - textWidth * 0.5
    local drawY = self.y - textHeight * 0.5
    
    -- Тень для лучшей читаемости
    love.graphics.setColor(0, 0, 0, alpha * 0.5)
    love.graphics.print(text, drawX + 1, drawY + 1)
    
    -- Основной текст
    love.graphics.setColor(r, g, b, alpha)
    love.graphics.print(text, drawX, drawY)
    
    love.graphics.setColor(1, 1, 1, 1)
end

function DamageNumber:isActive()
    return self.active
end

return DamageNumber
