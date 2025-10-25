local Creature = require("src.entity.creature")
local Constants = require("src.entity.constants")

local Hero = {}
Hero.__index = Hero

local spriteCache = {}

function Hero.new(x, y, heroId, level = 1)
    local self = setmetatable({}, Hero)

    -- Загружаем спрайт только один раз на весь тип героя
    local spriteSheet = Hero.loadSprite(heroId)
    local config = require("src.config.heroes")[heroId]

    if not config then
        error("Hero config not found: " .. heroId)
    end

    -- Инициализация базового существа
    self = Creature.new(self, spriteSheet, x, y, config, level)

    -- Свойства героя
    self.heroId = config.id
    self.heroName = config.name
    self.innateSkill = config.innateSkill

    self.experience = 0
    self.experienceToNext = Constants.EXPERIENCE_TO_NEXT_LEVEL

    return self
end

function Hero.loadSprite(heroId)
    -- Проверяем глобальный кэш
    if not spriteCache[heroId] then
        spriteCache[heroId] = love.graphics.newImage("assets/heroes/" .. heroId .. "/spritesheet.png")
    end
    return spriteCache[heroId]
end

function Hero:gainExperience(amount)
    self.experience = self.experience + amount
    if self.experience >= self.experienceToNext then
        self:levelUp()
    end
end

function Hero:levelUp()
    self.level = self.level + 1
    self.experienceToNext = self.experienceToNext * Constants.EXPERIENCE_TO_NEXT_LEVEL_MULTIPLIER

    -- Улучшаем параметры
    self.baseHp = self.baseHp + self.hpGrowth
    self.hp = self.hp + self.hpGrowth  -- Восстанавливаем HP
    self.baseArmor = self.baseArmor + self.armorGrowth
    self.armor = self.armor + self.armorGrowth
    self.baseMoveSpeed = self.baseMoveSpeed + self.speedGrowth
    self.moveSpeed = self.moveSpeed + self.speedGrowth
    self.baseCastSpeed = self.baseCastSpeed + self.castSpeedGrowth
    self.castSpeed = self.castSpeed + self.castSpeedGrowth
    
    -- Показываем выбор навыка
end

function Hero:draw()
    Creature.draw(self)
end

function Hero:update(dt)
    Creature.update(self, dt)
end

return Hero
