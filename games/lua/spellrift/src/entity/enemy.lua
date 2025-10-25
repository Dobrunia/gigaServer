local Creature = require("src.entity.creature")
local Constants = require("src.entity.constants")
local SpriteManager = require("src.utils.sprite_manager")

local Enemy = {}
Enemy.__index = Enemy

function Enemy.new(x, y, enemyId, level)
    local self = setmetatable({}, Enemy)
    
    -- Загружаем спрайт только один раз
    local spriteSheet = SpriteManager.loadEnemySprite(enemyId)
    
    -- Получаем конфиг врага
    local config = require("src.config.enemies")[enemyId]
    if not config then
        error("Enemy config not found: " .. enemyId)
    end
    
    -- Инициализируем как Creature
    self = Creature.new(self, spriteSheet, x, y, config, level)
    
    -- Свойства врага
    self.enemyId = config.id
    self.enemyName = config.name

    self.xpDrop = config.xpDrop + (level - 1) * config.xpDropGrowth
    self.xpDropGrowth = config.xpDropGrowth
    self.xpDropSpritesheet = config.xpDropSpritesheet

    return self
end

function Enemy:die()
    Creature.die(self)  -- Вызываем базовую смерть
    
    -- Создаем дроп
    self:createDrop()
end

function Enemy:createDrop()
    -- Создаем XP дроп
    local xpDrop = {
        x = self.x,
        y = self.y,
        value = self.xpDrop,
        sprite = SpriteManager.loadDropSprite(self.xpDropSpritesheet),
        type = "xp",
        collected = false
    }
    
    -- Добавляем в список дропа
end