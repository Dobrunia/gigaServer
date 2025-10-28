local Creature = require("src.entity.creature")
local Constants = require("src.constants")
local SpriteManager = require("src.utils.sprite_manager")
local Drop = require("src.entity.drop")

local Enemy = {}
Enemy.__index = Enemy
setmetatable(Enemy, {__index = Creature})

function Enemy.new(x, y, enemyId, level)
    -- Загружаем спрайт только один раз
    local spriteSheet = SpriteManager.loadEnemySprite(enemyId)
    
    -- Получаем конфиг врага
    local config = require("src.config.enemies")[enemyId]
    if not config then
        error("Enemy config not found: " .. enemyId)
    end
    
    -- Инициализируем как Creature
    local self = Creature.new(spriteSheet, x, y, config, level)
    -- Устанавливаем Enemy как метатаблицу
    setmetatable(self, Enemy)
    
    -- Свойства врага
    self.enemyId = config.id
    self.enemyName = config.name

    self.dropConfig = config.drop
    return self
end

function Enemy:die()
    Creature.die(self)  -- Вызываем базовую смерть
    
    -- Создаем дроп
    self:createDrop()
end

function Enemy:createDrop()
    if not (self.dropConfig and self.world) then return end
    local drop = Drop.new(self.x, self.y, self.dropConfig, self.level or 1)
    self.world:addDrop(drop)   -- <— кладём в мир
end

return Enemy