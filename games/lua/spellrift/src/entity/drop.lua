local Object = require("src.entity.object")
local SpriteManager = require("src.utils.sprite_manager")

local Drop = {}
Drop.__index = Drop
setmetatable(Drop, {__index = Object})

function Drop.new(x, y, dropId)
    -- Загружаем спрайт
    local spriteSheet = SpriteManager.loadDropSprite(dropId)

    -- Получаем конфиг врага
    local config = require("src.config.drops")[dropId]
    if not config then
        error("Drop config not found: " .. dropId)
    end
    -- Инициализируем как Object
    local self = Object.new(spriteSheet, x, y, config.width, config.height)  -- Дропы меньше по размеру
    -- Устанавливаем Drop как метатаблицу
    setmetatable(self, Drop)
    
    -- Свойства дропа
    self.dropId = config.id
    self.dropName = config.name
    self.type = config.type
    self.value = config.value
    self.collected = false
    self.attractionRange = config.attractionRange
    
    -- Настраиваем анимации дропа
    self:setupAnimations()
    
    return self
end

function Drop:setupAnimations()
    -- Анимация мерцания
    self:setAnimationList("idle", 1, 1, 4, 0.5)  -- 4 кадра мерцания
    self:playAnimation("idle")
end

function Drop:update(dt, player)
    if self.collected then
        return
    end
    
    -- Обновляем анимацию
    Object.update(self, dt)
    
    -- Проверяем расстояние до игрока
    local distance = MathUtils.distanceBetween(self, player)
    
    if distance <= self.attractionRange then
        -- Притягиваем к игроку
        local speed = 200 * dt
        if distance > 0 then
            local dx, dy = MathUtils.directionBetween(self, player)
            self:changePosition(dx * speed, dy * speed)
        end
        
        -- Если очень близко - собираем
        if distance < 10 then
            self:collect(player)
        end
    end
end

function Drop:collect(player)
    if self.collected then return end
    
    self.collected = true
    
    if self.type == "xp" then
        player:gainExperience(self.value)
    elseif self.type == "item" then
        print("Got item!")
    end
end

function Drop:draw()
    if not self.collected then
        Object.draw(self)  -- Используем анимацию из Object
        
        -- Дополнительные эффекты
        if self.type == "xp" then
            love.graphics.setColor(0, 1, 0, 0.3)  -- Зеленое свечение
            love.graphics.circle("fill", self.x + self.width/2, self.y + self.height/2, 20)
            love.graphics.setColor(1, 1, 1, 1)
        end
    end
end

return Drop