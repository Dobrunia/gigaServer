local Creature = require("src.entity.creature")
local SpriteManager = require("src.utils.sprite_manager")
local MathUtils = require("src.utils.math_utils")

local Hero = {}
Hero.__index = Hero

function Hero.new(x, y, heroId, level)
    local self = setmetatable({}, Hero)

    -- Загружаем спрайт только один раз на весь тип героя
    local spriteSheet = SpriteManager.loadHeroSprite(heroId)
    local config = require("src.config.heroes")[heroId]

    if not config then
        error("Hero config not found: " .. heroId)
    end

    -- Инициализация базового существа
    self = Creature.new(spriteSheet, x, y, config, level or 1)

    -- Свойства героя
    self.heroId = config.id
    self.heroName = config.name
    self.innateSkill = MathUtils.deepCopy(config.innateSkill)

    self.experience = 0
    self.experienceToNext = 100

    return self
end

function Hero:gainExperience(amount)
    self.experience = self.experience + amount
    if self.experience >= self.experienceToNext then
        self:levelUp()
    end
end

function Hero:levelUp()
    self.level = self.level + 1
    self.experienceToNext = self.experienceToNext * 1.3

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

return Hero
