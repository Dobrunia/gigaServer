local Object = require("src.entity.object")
local SpriteManager = require("src.utils.sprite_manager")
local MathUtils = require("src.utils.math_utils")

local Drop = {}
Drop.__index = Drop
setmetatable(Drop, { __index = Object })

-- config: таблица из enemies.lua (внутри поля drop), mobLevel: уровень моба
function Drop.new(x, y, config, mobLevel)
    assert(config and config.id, "Drop config is nil or has no id")

    local spriteSheet = SpriteManager.loadDropSprite(config.id)

    -- Передаем width и height из конфига
    local width = config.width or 32
    local height = config.height or 32
    local self = Object.new(spriteSheet, x, y, width, height)
    setmetatable(self, Drop)

    self.dropId = config.id
    self.dropName = config.name
    self.type = config.type
    local lvl = mobLevel or 1
    self.value = config.value + (lvl - 1) * config.valueGrowth
    self.collected= false

    local q = config.quads.idle
    self:setAnimationList("idle", q.row, q.col, q.col, q.animationSpeed or 999999)
    self:playAnimation("idle")
    return self
end

function Drop:update(dt, player)
    if self.collected then return end

    Object.update(self, dt)

    if not player then return end

    local pickupRange = player.pickupRange or 200  -- значение по умолчанию
    local distance = MathUtils.distanceBetween(self, player)

    if distance <= pickupRange then
        local speed = 200 * dt
        if distance > 0 then
            local dx, dy = MathUtils.directionBetween(self, player)
            self:changePosition(dx * speed, dy * speed)
        end
        
        -- Проверяем касание с границей хитбокса героя
        local playerRadius = (player.effectiveWidth or 0) * 0.5
        local dropRadius = (self.effectiveWidth or 0) * 0.5
        local touchDistance = playerRadius + dropRadius
        
        if distance <= touchDistance then
            self:collect(player)
        end
    end
end

function Drop:collect(player)
    if self.collected then return end
    self.collected = true
    if self.type == "xp" and player and player.gainExperience then
        player:gainExperience(self.value)
    end
end

function Drop:draw()
    if self.collected then return end
    Object.draw(self)
    if self.type == "xp" then
        love.graphics.setColor(0.4, 0.8, 1.0, 0.3)  -- нежно-голубой блик для дропа
        love.graphics.circle("fill", self.x + self.effectiveWidth/2, self.y + self.effectiveHeight/2, 20)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

return Drop