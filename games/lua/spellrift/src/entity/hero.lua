local Creature = require("src.entity.creature")
local SpriteManager = require("src.utils.sprite_manager")
local MathUtils = require("src.utils.math_utils")

local Hero = {}
Hero.__index = Hero
setmetatable(Hero, {__index = Creature})

function Hero.new(x, y, heroId, level)
    -- Загружаем спрайт только один раз на весь тип героя
    local spriteSheet = SpriteManager.loadHeroSprite(heroId)
    local config = require("src.config.heroes")[heroId]

    if not config then
        error("Hero config not found: " .. heroId)
    end

    -- Инициализация базового существа
    local self = Creature.new(spriteSheet, x, y, config, level or 1)
    -- Устанавливаем Hero как метатаблицу
    setmetatable(self, Hero)

    -- Свойства героя
    self.heroId = config.id
    self.heroName = config.name
    self.innateSkill = MathUtils.deepCopy(config.innateSkill)

    self.experience = 0
    self.experienceToNext = 100
    
    -- Статистика
    self.damageDealt = 0

    -- Таймер удержания анимации каста
    self._castAnimTimer = 0
    self._castHold = 0.3  -- длительность удержания каста

    return self
end

function Hero:gainExperience(amount)
    self.experience = self.experience + amount
    if self.experience >= self.experienceToNext then
        self:levelUp()
    end
end

function Hero:dealDamage(amount)
    self.damageDealt = self.damageDealt + amount
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

function Hero:getStats()
    return {
        level = self.level,
        hp = self.hp,
        maxHp = self.baseHp,
        xp = self.experience,
        xpToNext = self.experienceToNext,
        armor = self.armor,
        armorGrowth = self.armorGrowth,
        speed = self.moveSpeed,
        speedGrowth = self.speedGrowth,
        castSpeed = self.castSpeed,
        castSpeedGrowth = self.castSpeedGrowth
    }
end

-- Найти ближайшего врага в радиусе атаки
function Hero:findNearestEnemyInRange()
    if not self.world or not self.world.enemies then
        return nil
    end
    
    local nearestEnemy = nil
    local nearestDistance = math.huge
    
    for _, enemy in ipairs(self.world.enemies) do
        if enemy and not enemy.isDead then
            local dx = enemy.x - self.x
            local dy = enemy.y - self.y
            local distance = math.sqrt(dx * dx + dy * dy)
            
            -- Проверяем, есть ли у нас навык с достаточным радиусом
            for _, skill in ipairs(self.skills) do
                local skillRange = skill.stats and skill.stats.range or 0
                if skillRange > 0 and MathUtils.canAttackTarget(self, enemy, skillRange) and distance < nearestDistance then
                    nearestEnemy = enemy
                    nearestDistance = distance
                    break
                end
            end
        end
    end
    
    return nearestEnemy
end

-- Автоатака - использует первый доступный навык
function Hero:autoAttack()
    if not self.world then return end
    
    -- Ищем ближайшего врага в радиусе атаки
    local target = self:findNearestEnemyInRange()
    if not target then
        return -- нет целей в радиусе
    end
    
    -- Ищем первый навык не на кулдауне
    for _, skill in ipairs(self.skills) do
        if skill:canCast() then
            local skillRange = skill.stats and skill.stats.range or 0
            if skillRange > 0 and MathUtils.canAttackTarget(self, target, skillRange) then
                -- Смотрим на цель
                local dx = target.x - self.x
                local dy = target.y - self.y
                if dx < -0.001 then
                    self.facing = -1
                elseif dx > 0.001 then
                    self.facing = 1
                end
                
                -- Переключаемся на анимацию каста
                if self.animationsList and self.animationsList["cast"] then
                    self:playAnimation("cast")
                    self._castAnimTimer = self._castHold
                end
                
                skill:castAt(self.world, target.x, target.y)
                return
            end
        end
    end
end

-- Переопределяем update для добавления автоатаки
function Hero:update(dt)
    -- Если мертв, не обновляем логику
    if self.isDead then
        return
    end

    -- Обновляем таймер анимации каста
    if self._castAnimTimer and self._castAnimTimer > 0 then
        self._castAnimTimer = self._castAnimTimer - dt
        -- Пока кастуем - не двигаемся и не атакуем
        Creature.update(self, dt)
        return
    else
        -- Сбрасываем анимацию каста когда таймер закончился
        if self.currentAnimation == "cast" then
            self:playAnimation("idle")
        end
    end

    -- Вызываем базовый update из Creature
    Creature.update(self, dt)
    
    -- Автоатака (только если герой жив и не кастует)
    if not self.isDead then
        self:autoAttack()
    end
end

return Hero
