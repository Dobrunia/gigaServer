local Spawner = require("src.world.spawner")
local Hero = require("src.entity.hero")
local Projectile = require("src.entity.projectile")

local World = {}
World.__index = World

function World.new(mapWidth, mapHeight)
    local self = setmetatable({}, World)
    self.width = mapWidth
    self.height = mapHeight

    self.heroes = {}
    self.enemies = {}
    self.drops = {}

    self.spawner = Spawner.new(self.width, self.height)

    -- если где-то остались старые вызовы addProjectile, не упадём
    self._legacyProjectiles = {}

    return self
end

function World:setup(selectedHeroId, selectedSkillId, mapWidth, mapHeight)
    if mapWidth  then self.width  = mapWidth  end
    if mapHeight then self.height = mapHeight end
    if self.spawner and self.spawner.resize then
        self.spawner:resize(self.width, self.height)
    end

    -- Герой в центре карты
    local cx = (self.width  or 0) * 0.5
    local cy = (self.height or 0) * 0.5
    local hero = Hero.new(cx, cy, selectedHeroId, 1)

    -- Выбранный стартовый скилл
    if selectedSkillId then
        hero:addSkill(selectedSkillId, 1)
    end

    self:addHero(hero)
end

-- ==== Добавление сущностей ====
function World:addHero(hero)
    hero.world = self
    table.insert(self.heroes, hero)
end

function World:addEnemy(enemy)
    enemy.world = self
    table.insert(self.enemies, enemy)
end

-- Оставлено для совместимости: если где-то вручную создают projectile-объекты
function World:addProjectile(projectile)
    -- Централизованное управление проджектайлами находится в Projectile.updateAll/drawAll().
    -- Этот список оставлен, чтобы не ломать старые места вызова.
    table.insert(self._legacyProjectiles, projectile)
end

function World:addDrop(drop)
    table.insert(self.drops, drop)
end

-- ==== Апдейт ====
function World:update(dt)
    -- Герои
    for i = 1, #self.heroes do
        self.heroes[i]:update(dt)
    end

    -- Враги (с передачей первого героя как цели для AI)
    local hero = self.heroes[1]
    for i = 1, #self.enemies do
        self.enemies[i]:update(dt, hero)
    end

    -- Проджектайлы из пула (главный путь)
    Projectile.updateAll(dt, self)

    -- Совместимость: если кто-то вручную добавил projectile-объекты
    -- требующие update — поддержим
    for i = #self._legacyProjectiles, 1, -1 do
        local p = self._legacyProjectiles[i]
        if p.update then p:update(dt, self) end
        if (p.isDead and p:isDead()) or p.active == false then
            table.remove(self._legacyProjectiles, i)
        end
    end

    -- Дропы
    for i = #self.drops, 1, -1 do
        local d = self.drops[i]
        d:update(dt, hero)
        if d.collected then
            table.remove(self.drops, i)
        end
    end

    -- Спавнер (если есть герой)
    if hero then
        self.spawner:update(dt, self, hero)
    end

    -- Очистка умерших врагов (если кто-то не удалил сам)
    for i = #self.enemies, 1, -1 do
        if self.enemies[i].isDead then
            table.remove(self.enemies, i)
        end
    end
end

-- ==== Рендер ====
function World:draw()
    -- Порядок слоёв можно менять по вкусу
    -- 1) Герои
    for i = 1, #self.heroes do
        self.heroes[i]:draw()
    end

    -- 2) Враги
    for i = 1, #self.enemies do
        self.enemies[i]:draw()
    end

    -- 3) Проджектайлы из пула
    Projectile.drawAll()

    -- 4) Дропы
    for i = 1, #self.drops do
        self.drops[i]:draw()
    end

    -- 5) Совместимость: вручную добавленные проджектайлы
    for i = 1, #self._legacyProjectiles do
        local p = self._legacyProjectiles[i]
        if p.draw then p:draw() end
    end
end

return World