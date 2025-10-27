local Spawner = require("src.world.spawner")
local Hero = require("src.entity.hero")

local World = {}
World.__index = World

function World.new()
    local self = setmetatable({}, World)
    self.heroes = {}
    self.enemies = {}
    self.projectiles = {}
    self.drops = {}
    self.spawner = Spawner.new()
    return self
end

function World:setup(selectedHero, selectedSkill)
    -- Создаем героя в центре карты
    local hero = Hero.new(400, 300, selectedHero.id, 1)
    
    -- Добавляем выбранный скилл герою
    hero:addSkill(selectedSkill, 1)
    
    -- Добавляем героя в мир
    self:addHero(hero)
end

function World:addHero(hero)
    table.insert(self.heroes, hero)
end

function World:addEnemy(enemy)
    table.insert(self.enemies, enemy)
end

function World:addProjectile(projectile)
    table.insert(self.projectiles, projectile)
end

function World:addDrop(drop)
    table.insert(self.drops, drop)
end

function World:update(dt)
    -- Обновляем все объекты
    for _, hero in ipairs(self.heroes) do
        hero:update(dt)
    end
    
    for _, enemy in ipairs(self.enemies) do
        enemy:update(dt, self.heroes[1])
    end
    
    for _, projectile in ipairs(self.projectiles) do
        projectile:update(dt, self.heroes[1])
    end
    
    for _, drop in ipairs(self.drops) do
        drop:update(dt, self.heroes[1])
    end
    
    -- Обновляем спавнер (если есть герой)
    if #self.heroes > 0 then
        self.spawner:update(dt, self, self.heroes[1])
    end
end

function World:draw()
    for _, hero in ipairs(self.heroes) do
        hero:draw()
    end
    
    for _, enemy in ipairs(self.enemies) do
        enemy:draw()
    end
    
    for _, projectile in ipairs(self.projectiles) do
        projectile:draw()
    end
    
    for _, drop in ipairs(self.drops) do
        drop:draw()
    end
end

return World