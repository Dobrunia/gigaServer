local Object = require("src.entity.object")
local SpriteManager = require("src.utils.sprite_manager")
local MathUtils = require("src.utils.math_utils")

local Projectile = {}
Projectile.__index = Projectile

-- Пул объектов для переиспользования
local projectilePool = {}
local activeProjectiles = {}

function Projectile.new(x, y, targetX, targetY, projectileId)
    local self = table.remove(projectilePool) or setmetatable({}, Projectile)
    
    -- Загружаем спрайт только один раз
    local spriteSheet = SpriteManager.loadProjectileSprite(projectileId)
    local config = require("src.config.projectiles")[projectileId]

    if not config then
        error("Projectile config not found: " .. projectileId)
    end
    -- Инициализируем как Object
    self = Object.new(self, spriteSheet, x, y, config.width, config.height)  -- Маленький размер для снарядов
    
    -- Свойства снаряда
    self.damage = config.damage
    self.speed = config.speed
    self.active = true
    
    -- Направление движения
    local dx, dy = MathUtils.direction(x, y, targetX, targetY)
    self.velocityX = dx * self.speed
    self.velocityY = dy * self.speed
    
    -- Настраиваем анимацию
    self:setupAnimations()
    
    -- Добавляем в активные
    table.insert(activeProjectiles, self)
    
    return self
end

function Projectile:setupAnimations()
    -- Простая анимация полета
    self:setAnimationList("fly", 1, 1, 3, 0.1)
    self:playAnimation("fly")
end

function Projectile:update(dt, player)
    if not self.active then
        return
    end
    
    -- Обновляем анимацию
    Object.update(self, dt)
    
    -- Движение
    self:changePosition(self.velocityX * dt, self.velocityY * dt)
    
    -- Проверяем столкновение с игроком
    if self:checkCollision(player) then
        player:takeDamage(self.damage)
        self:destroy()
    end
end

function Projectile:checkCollision(target)
    if not target or target.isDead then
        return false
    end
    
    -- Простая проверка столкновения (AABB)
    return self.x < target.x + target.width and
           self.x + self.width > target.x and
           self.y < target.y + target.height and
           self.y + self.height > target.y
end

function Projectile:destroy()
    if not self.active then
        return
    end
    
    self.active = false
    
    -- Удаляем из активных
    for i, projectile in ipairs(activeProjectiles) do
        if projectile == self then
            table.remove(activeProjectiles, i)
            break
        end
    end
end

function Projectile:draw()
    if self.active then
        Object.draw(self)
    end
end

-- Статические методы для управления всеми снарядами
function Projectile.updateAll(dt, player)
    for i = #activeProjectiles, 1, -1 do
        local projectile = activeProjectiles[i]
        projectile:update(dt, player)
        
        if not projectile.active then
            table.remove(activeProjectiles, i)
        end
    end
end

function Projectile.drawAll()
    for _, projectile in ipairs(activeProjectiles) do
        projectile:draw()
    end
end

function Projectile.clearAll()
    for _, projectile in ipairs(activeProjectiles) do
        projectile.active = false
    end
    activeProjectiles = {}
end

function Projectile.getCount()
    return #activeProjectiles
end

return Projectile