local Creature = require("src.entity.creature")
local SpriteManager = require("src.utils.sprite_manager")
local MathUtils = require("src.utils.math_utils")
local Drop = require("src.entity.drop")

local Enemy = {}
Enemy.__index = Enemy
setmetatable(Enemy, {__index = Creature})

function Enemy.new(x, y, enemyId, level)
    local spriteSheet = SpriteManager.loadEnemySprite(enemyId)
    local config = require("src.config.enemies")[enemyId]
    if not config then error("Enemy config not found: " .. enemyId) end

    local self = Creature.new(spriteSheet, x, y, config, level)
    setmetatable(self, Enemy)

    self.enemyId    = config.id
    self.enemyName  = config.name
    self.dropConfig = config.drop
    self._config    = config

    -- добавим все скиллы моба
    if config.skills then
        for _, skillId in ipairs(config.skills) do
            self:addSkill(skillId, level or 1)
        end
    end

    -- таймер "зависания" на кадре атаки
    self._attackAnimTimer = 0
    -- длительность удержания кадра каста (можно переопределить в enemies.lua полем castHold)
    self._castHold = config.castHold or 0.3

    return self
end

-- минимальная дистанция, чтобы можно было кастовать хоть что-то (готовое в приоритете)
function Enemy:getDesiredStopDistance()
    local minReady, minAny
    if self.skills then
        for _, sk in ipairs(self.skills) do
            local r = sk.stats and sk.stats.range
            
            if r then
                if sk:canCast() then
                    minReady = (minReady and math.min(minReady, r)) or r
                end
                minAny = (minAny and math.min(minAny, r)) or r
            end
        end
    end
    return minReady or minAny or 180
end

-- попытка кастануть любой готовый скилл, который достаёт до героя
function Enemy:tryCastAt(hero)
    if not (self.skills and hero) then return false end

    for _, sk in ipairs(self.skills) do
        local r = sk.stats and sk.stats.range
        
        if r and sk:canCast() then
            local canHit = MathUtils.canAttackTarget(self, hero, r)
            
            -- Для melee навыков добавляем более простую проверку дистанции
            if sk.type == "melee" and not canHit then
                local dx = hero.x - self.x
                local dy = hero.y - self.y
                local dist = math.sqrt(dx*dx + dy*dy)
                canHit = dist <= r
            end
            
            if canHit then
            -- смотреть на цель
            local dx = hero.x - self.x
            local dy = hero.y - self.y
            if dx < -0.001 then self.facing = -1
            elseif dx > 0.001 then self.facing = 1 end

            -- анимация каста: если есть — включаем и "замораживаем" позицию
            if self.animationsList and self.animationsList["cast"] then
                self:playAnimation("cast")
                self._attackAnimTimer = self._castHold
            end

            -- запускаем скилл - передаем центр хитбокса героя, а не угол
            local heroCenterX = hero.x + (hero.effectiveWidth or 0) * 0.5
            local heroCenterY = hero.y + (hero.effectiveHeight or 0) * 0.5
            sk:castAt(self.world, heroCenterX, heroCenterY)
            return true
            end
        end
    end
    return false
end

function Enemy:update(dt, hero)
    -- Если мертв, обновляем только анимации (для die анимации)
    if self.isDead then
        Creature.update(self, dt)
        return
    end

    -- тикает удержание кадра каста
    if self._attackAnimTimer and self._attackAnimTimer > 0 then
        self._attackAnimTimer = self._attackAnimTimer - dt
        -- пока "кастуем" — не двигаемся (freeze)
        Creature.update(self, dt)
        return
    else
        -- сбрасываем анимацию каста когда таймер закончился
        if self.currentAnimation == "cast" then
            self:playAnimation("idle")
        end
    end

    if hero then
        local dx, dy = hero.x - self.x, hero.y - self.y
        local dist = math.sqrt(dx*dx + dy*dy)

        local stopDist = self:getDesiredStopDistance()
        -- Для melee навыков нужен меньший гистерезис, чтобы подойти ближе
        local hasMelee = false
        if self.skills then
            for _, sk in ipairs(self.skills) do
                if sk.type == "melee" then
                    hasMelee = true
                    break
                end
            end
        end
        local hyst = hasMelee and 2 or 8  -- меньший гистерезис для melee
        local stopWithHyst = math.max(0, stopDist - hyst)

        if dist > stopWithHyst and dist > 0.0001 then
            -- идём к герою (через changePosition -> флип и walk сработают)
            local nx, ny = dx / dist, dy / dist
            local step = (self.moveSpeed or self.baseMoveSpeed or 60) * dt
            local need = dist - stopWithHyst
            if step > need then step = need end
            self:changePosition(nx * step, ny * step)
        else
            -- уже на позиции — пытаемся кастовать
            self:tryCastAt(hero)
        end
    end

    -- базовые апдейты (скиллы/дебаффы/анимации walk/idle)
    Creature.update(self, dt)
end

function Enemy:die()
    Creature.die(self)
    self:createDrop()
end

function Enemy:createDrop()
    if not (self.dropConfig and self.world) then return end
    local drop = Drop.new(self.x, self.y, self.dropConfig, self.level or 1)
    self.world:addDrop(drop)
end

return Enemy