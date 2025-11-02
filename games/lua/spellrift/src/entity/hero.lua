local Creature = require("src.entity.creature")
local SpriteManager = require("src.utils.sprite_manager")
local MathUtils = require("src.utils.math_utils")
local Constants = require("src.constants")

local Hero = {}
Hero.__index = Hero
setmetatable(Hero, {__index = Creature})

function Hero.new(x, y, heroId, level)
    local spriteSheet = SpriteManager.loadHeroSprite(heroId)
    local config = require("src.config.heroes")[heroId]
    if not config then
        error("Hero config not found: " .. heroId)
    end

    local self = Creature.new(spriteSheet, x, y, config, level or 1)
    setmetatable(self, Hero)

    -- базовое
    self.heroId = config.id
    self.heroName = config.name
    self.innateSkill = MathUtils.deepCopy(config.innateSkill)

    self.experience = 0
    self.experienceToNext = 100
    self.damageDealt = 0
    
    -- радиус подбора дропов (из конфига героя или дефолтное значение)
    self.pickupRange = config.pickupRange or 100

    -- анимация каста
    self._castAnimTimer = 0
    self._castHold = 0.3

    -- === РЕЖИМ ПРИЦЕЛИВАНИЯ (ЛКМ ЗАЖАТА) ===
    self.aimOverride = false
    self.aimX, self.aimY = self.x, self.y

    return self
end

-- публичный API для игры: включить прицеливание от курсора
function Hero:setAimPoint(worldX, worldY)
    self.aimOverride = true
    self.aimX, self.aimY = worldX, worldY
end

-- выключить прицеливание (вернуться к авто-таргету)
function Hero:clearAim()
    self.aimOverride = false
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
    self.experience = 0  -- очищаем опыт при повышении уровня
    self.experienceToNext = self.experienceToNext * 1.3

    self.baseHp = self.baseHp + self.hpGrowth
    self.hp = self.hp + self.hpGrowth
    self.baseArmor = self.baseArmor + self.armorGrowth
    self.armor = self.armor + self.armorGrowth
    self.baseMoveSpeed = self.baseMoveSpeed + self.speedGrowth
    self.moveSpeed = self.moveSpeed + self.speedGrowth
    
    -- Флаг для показа экрана выбора скиллов
    self.needsSkillChoice = true
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
        baseHp = self.baseHp,
        baseArmor = self.baseArmor,
        baseMoveSpeed = self.baseMoveSpeed,
        pickupRange = self.pickupRange or 100,
    }
end

-- Найти ближайшего врага в радиусе хотя бы одного направленного скилла
function Hero:findNearestEnemyInRange()
    if not self.world or not self.world.enemies then
        return nil
    end
    local nearestEnemy, nearestDist = nil, math.huge

    for _, enemy in ipairs(self.world.enemies) do
        if enemy and not enemy.isDead then
            local dx, dy = (enemy.x - self.x), (enemy.y - self.y)
            local dist = math.sqrt(dx*dx + dy*dy)
            -- есть ли у героя хоть один скилл с радиусом > 0
            for _, skill in ipairs(self.skills) do
                local range = (skill.stats and skill.stats.range) or 0
                if range > 0 and MathUtils.canAttackTarget(self, enemy, range) and dist < nearestDist then
                    nearestEnemy, nearestDist = enemy, dist
                    break
                end
            end
        end
    end
    return nearestEnemy
end

-- Каст анимации + поворот
function Hero:_faceAndPlayCast(targetX, targetY)
    local dx = targetX - self.x
    if dx < -0.001 then
        self.facing = -1
    elseif dx > 0.001 then
        self.facing = 1
    end
    if self.animationsList and self.animationsList["cast"] then
        self:playAnimation("cast")
        self._castAnimTimer = self._castHold
    end
end

-- Автоатака / прицельная атака
function Hero:_attackLogic()
    if not self.world then return end

    if self.aimOverride then
        -- РЕЖИМ ПРИЦЕЛИВАНИЯ: кастуем ВСЕ направленные скиллы, которые готовы
        local tx, ty = self.aimX, self.aimY
        
        -- Просто поворачиваемся к цели без анимации
        local dx = tx - self.x
        if dx < -0.001 then
            self.facing = -1
        elseif dx > 0.001 then
            self.facing = 1
        end

        for _, skill in ipairs(self.skills) do
            -- считаем направленными скиллы типа "projectile" и "melee"
            -- орбитальные скиллы не кастуются в режиме прицеливания
            if (skill.type == "projectile" or skill.type == "melee") and skill:canCast() then
                -- Играем анимацию только при успешном касте
                self:_faceAndPlayCast(tx, ty)
                skill:castAt(self.world, tx, ty)
            end
        end
        return
    end

    -- АВТОЦЕЛЬ: ближайшая цель и первый доступный подходящий скилл
    local target = self:findNearestEnemyInRange()
    if not target then return end

    for _, skill in ipairs(self.skills) do
        -- Орбитальные скиллы и ауры уже кастуются автоматически в Creature.update()
        if skill.type ~= "orbital" and skill.type ~= "aura" and skill:canCast() then
            local range = (skill.stats and skill.stats.range) or 0
            if range > 0 and MathUtils.canAttackTarget(self, target, range) then
                self:_faceAndPlayCast(target.x, target.y)
                skill:castAt(self.world, target.x, target.y)
                return
            end
        end
    end
end

function Hero:update(dt)
    if self.isDead then return end

    if self._castAnimTimer and self._castAnimTimer > 0 then
        self._castAnimTimer = self._castAnimTimer - dt
        Creature.update(self, dt)
        return
    else
        if self.currentAnimation == "cast" then
            self:playAnimation("idle")
        end
    end

    Creature.update(self, dt)

    -- атака: либо по прицелу, либо по ближайшему
    if not self.isDead then
        self:_attackLogic()
    end
end

function Hero:draw()
    -- Вызываем базовую отрисовку из Creature
    Creature.draw(self)
    
    -- Рисуем стрелку направления если включена отладка
    if Constants.DEBUG_DRAW_DIRECTION_ARROW then
        self:drawDirectionArrow()
    end
end

function Hero:drawDirectionArrow()
    if self.isDead then return end
    
    local centerX = self.x + self.effectiveWidth * 0.5
    local centerY = self.y + self.effectiveHeight * 0.5
    
    if self.aimOverride then
        -- Рисуем стрелку к точке прицеливания
        local dx = self.aimX - centerX
        local dy = self.aimY - centerY
        local distance = math.sqrt(dx * dx + dy * dy)
        
        if distance > 10 then -- минимальное расстояние для отображения стрелки
            local arrowLength = math.min(100, distance * 0.5)
            local arrowEndX = centerX + (dx / distance) * arrowLength
            local arrowEndY = centerY + (dy / distance) * arrowLength
            
            -- Основная линия стрелки
            love.graphics.setColor(1, 1, 0, 0.8) -- желтый
            love.graphics.setLineWidth(3)
            love.graphics.line(centerX, centerY, arrowEndX, arrowEndY)
            
            -- Наконечник стрелки
            local arrowHeadSize = 8
            local angle = math.atan2(dy, dx)
            local headX1 = arrowEndX - arrowHeadSize * math.cos(angle - 0.5)
            local headY1 = arrowEndY - arrowHeadSize * math.sin(angle - 0.5)
            local headX2 = arrowEndX - arrowHeadSize * math.cos(angle + 0.5)
            local headY2 = arrowEndY - arrowHeadSize * math.sin(angle + 0.5)
            
            love.graphics.line(arrowEndX, arrowEndY, headX1, headY1)
            love.graphics.line(arrowEndX, arrowEndY, headX2, headY2)
            
            love.graphics.setLineWidth(1)
            love.graphics.setColor(1, 1, 1, 1)
        end
    else
        -- Рисуем стрелку к ближайшему врагу
        local target = self:findNearestEnemyInRange()
        if target then
            local dx = target.x - centerX
            local dy = target.y - centerY
            local distance = math.sqrt(dx * dx + dy * dy)
            
            if distance > 10 then
                local arrowLength = math.min(80, distance * 0.4)
                local arrowEndX = centerX + (dx / distance) * arrowLength
                local arrowEndY = centerY + (dy / distance) * arrowLength
                
                -- Основная линия стрелки (зеленая для автоатаки)
                love.graphics.setColor(0, 1, 0, 0.6) -- зеленый
                love.graphics.setLineWidth(2)
                love.graphics.line(centerX, centerY, arrowEndX, arrowEndY)
                
                -- Наконечник стрелки
                local arrowHeadSize = 6
                local angle = math.atan2(dy, dx)
                local headX1 = arrowEndX - arrowHeadSize * math.cos(angle - 0.5)
                local headY1 = arrowEndY - arrowHeadSize * math.sin(angle - 0.5)
                local headX2 = arrowEndX - arrowHeadSize * math.cos(angle + 0.5)
                local headY2 = arrowEndY - arrowHeadSize * math.sin(angle + 0.5)
                
                love.graphics.line(arrowEndX, arrowEndY, headX1, headY1)
                love.graphics.line(arrowEndX, arrowEndY, headX2, headY2)
                
                love.graphics.setLineWidth(1)
                love.graphics.setColor(1, 1, 1, 1)
            end
        end
    end
end

return Hero