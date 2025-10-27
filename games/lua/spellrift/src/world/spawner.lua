local MathUtils = require("src.utils.math_utils")
local Enemy = require("src.entity.enemy")
local EnemiesConfig = require("src.config.enemies")

local Spawner = {}
Spawner.__index = Spawner

local function chooseRandom(t)
    return t[math.random(1, #t)]
end

-- Проверяем, может ли враг спавниться в данное время
local function canSpawnAtTime(enemyConfig, elapsedTime)
    local startTime = enemyConfig.spawnStartTime or 0
    local endTime = enemyConfig.spawnEndTime
    
    -- Проверяем время начала
    if elapsedTime < startTime then
        return false
    end
    
    -- Проверяем время окончания (если указано)
    if endTime and elapsedTime > endTime then
        return false
    end
    
    return true
end

-- Выбираем случайного врага с учетом весов и времени
local function chooseWeightedEnemy(elapsedTime)
    local candidates = {}
    local totalWeight = 0
    
    for id, config in pairs(EnemiesConfig) do
        if canSpawnAtTime(config, elapsedTime) then
            local weight = config.spawnWeight or 1
            table.insert(candidates, {id = id, weight = weight})
            totalWeight = totalWeight + weight
        end
    end
    
    if totalWeight == 0 then
        return nil -- Нет доступных врагов
    end
    
    -- Выбираем случайного врага с учетом весов
    local randomValue = math.random() * totalWeight
    local currentWeight = 0
    
    for _, candidate in ipairs(candidates) do
        currentWeight = currentWeight + candidate.weight
        if randomValue <= currentWeight then
            return candidate.id
        end
    end
    
    return candidates[1].id -- Fallback
end

local function randomRingPoint(cx, cy, minR, maxR)
    local r = MathUtils.randomRange(minR, maxR)
    local a = MathUtils.randomRange(0, math.pi * 2)
    return cx + math.cos(a) * r, cy + math.sin(a) * r
end

function Spawner.new()
    local self = setmetatable({}, Spawner)
    
    -- Настройки спавна
    self.cooldown = 2.0                    -- Интервал между спавнами
    self.timer = 0
    self.maxAlive = 20                     -- Максимум живых врагов
    
    -- Радиус спавна вокруг героя
    self.minRadius = 200
    self.maxRadius = 400
    
    -- Прогрессия сложности
    self.elapsed = 0
    self.levelBase = 1
    self.levelGain = 0.1
    
    -- Попытки найти подходящую точку
    self.maxAttempts = 5
    
    return self
end

-- Подсчет живых врагов
local function getAliveEnemiesCount(enemies)
    local count = 0
    for _, enemy in ipairs(enemies) do
        if enemy and not enemy.isDead then
            count = count + 1
        end
    end
    return count
end

-- Обновление сложности со временем
function Spawner:updateDifficulty(dt)
    self.elapsed = self.elapsed + dt
    
    -- Увеличиваем сложность со временем
    self.cooldown = math.max(0.5, 2.0 - self.elapsed * 0.01)  -- Быстрее спавн
    self.maxAlive = math.min(50, math.floor(20 + self.elapsed * 0.1))  -- Больше лимит
end

-- Основной метод обновления
function Spawner:update(dt, world, hero)
    if not world or not hero then return end
    
    self:updateDifficulty(dt)
    
    self.timer = self.timer - dt
    if self.timer > 0 then return end
    
    -- Проверяем лимит живых врагов
    local alive = getAliveEnemiesCount(world.enemies)
    if alive >= self.maxAlive then
        self.timer = self.cooldown * 0.5
        return
    end
    
    -- Выбираем случайного врага с учетом времени и весов
    local enemyId = chooseWeightedEnemy(self.elapsed)
    if not enemyId then
        self.timer = self.cooldown * 0.5
        return
    end
    
    local enemyConfig = EnemiesConfig[enemyId]
    local spawnGroupSize = enemyConfig.spawnGroupSize or 1
    
    -- Сколько можем заспавнить (учитываем групповой спавн)
    local canSpawn = math.min(spawnGroupSize, self.maxAlive - alive)
    if canSpawn <= 0 then
        self.timer = self.cooldown * 0.5
        return
    end
    
    -- Уровень врагов растет со временем
    local enemyLevel = math.max(1, math.floor(self.levelBase + self.elapsed * self.levelGain))
    
    -- Спавним группу врагов
    for i = 1, canSpawn do
        local attempts = 0
        local sx, sy
        
        repeat
            attempts = attempts + 1
            sx, sy = randomRingPoint(hero.x, hero.y, self.minRadius, self.maxRadius)
        until sx and sy or attempts >= self.maxAttempts
        
        if sx and sy then
            local enemy = Enemy.new(sx, sy, enemyId, enemyLevel)
            world:addEnemy(enemy)
        end
    end
    
    -- Следующий спавн
    self.timer = self.cooldown
end

return Spawner
