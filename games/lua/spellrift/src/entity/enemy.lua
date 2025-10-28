local Creature = require("src.entity.creature")
local SpriteManager = require("src.utils.sprite_manager")
local Drop = require("src.entity.drop")
local SkillsCfg = require("src.config.skills")

local Enemy = {}
Enemy.__index = Enemy
setmetatable(Enemy, {__index = Creature})

function Enemy.new(x, y, enemyId, level)
    local spriteSheet = SpriteManager.loadEnemySprite(enemyId)
    local config = require("src.config.enemies")[enemyId]
    if not config then error("Enemy config not found: " .. enemyId) end

    local self = Creature.new(spriteSheet, x, y, config, level)
    setmetatable(self, Enemy)

    self.enemyId = config.id
    self.enemyName = config.name
    self.dropConfig = config.drop
    self._config = config

    -- закешируем радиус атаки (если указан прямо в мобе — он приоритетнее)
    self.attackRange = config.range

    return self
end

-- Получить дальность атаки: приоритет моба -> первый скилл -> дефолт
function Enemy:getAttackRange()
    if self.attackRange then return self.attackRange end

    local range
    if self._config and self._config.skills and #self._config.skills > 0 then
        local firstSkillId = self._config.skills[1]
        local sk = SkillsCfg[firstSkillId]
        if sk and sk.stats and sk.stats.range then
            range = sk.stats.range
        end
    end

    self.attackRange = range
    return self.attackRange
end

-- Идём к герою, пока дальше, чем дистанция атаки
function Enemy:update(dt, hero)
    if self.isDead then return end

    if hero then
        local dx = hero.x - self.x
        local dy = hero.y - self.y
        local dist = math.sqrt(dx*dx + dy*dy)

        local range   = self:getAttackRange()
        local stopDst = math.max(0, range - 8)   -- гистерезис 8px, чтобы не дёргался на границе

        if dist > stopDst and dist > 0.0001 then
            local nx, ny = dx / dist, dy / dist
            local step   = (self.moveSpeed or self.baseMoveSpeed or 60) * dt
            local need   = dist - stopDst
            if step > need then step = need end
            -- важно звать changePosition — это ставит facing и включает walk
            self:changePosition(nx * step, ny * step)
        end
        -- иначе стоим: Creature.update сам переключит на idle
    end

    -- базовая логика (скиллы/дебаффы/анимации)
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