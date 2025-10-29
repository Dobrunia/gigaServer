local MathUtils = require("src.utils.math_utils")
local Enemy = require("src.entity.enemy")
local EnemiesConfig = require("src.config.enemies")

local Spawner = {}
Spawner.__index = Spawner

-- ===================== utils ======================

local function clamp(v, a, b) return math.max(a, math.min(b, v)) end

-- моб доступен по времени?
local function canSpawnAtTime(cfg, elapsed)
  local startTime = cfg.spawnStartTime or 0
  local endTime   = cfg.spawnEndTime   -- nil = бесконечно
  if elapsed < startTime then return false end
  if endTime and elapsed > endTime then return false end
  return true
end

-- выбор с учётом "обратных" весов (1 = часто, 10 = редко)
local function chooseWeightedEnemy(elapsed)
  local pool, total = {}, 0
  for id, cfg in pairs(EnemiesConfig) do
    if canSpawnAtTime(cfg, elapsed) then
      local wraw = cfg.spawnWeight or 1
      local w = (wraw > 0) and (1 / wraw) or 1       -- инвертируем
      total = total + w
      pool[#pool+1] = { id = id, w = w }
    end
  end
  if total <= 0 or #pool == 0 then return nil end

  local r, acc = math.random() * total, 0
  for i = 1, #pool do
    acc = acc + pool[i].w
    if r <= acc then return pool[i].id end
  end
  return pool[1].id
end

-- точка в пределах карты
local function inBounds(x, y, W, H, m)
  return x >= m and x <= W - m and y >= m and y <= H - m
end

-- случайная точка, но не ближе minDist к герою
local function randomPointAwayFromHero(heroX, heroY, minDist, W, H, m)
  local tries, maxTries = 0, 50
  repeat
    local x = MathUtils.randomRange(m, W - m)
    local y = MathUtils.randomRange(m, H - m)
    local dx, dy = x - heroX, y - heroY
    if (dx*dx + dy*dy) >= (minDist * minDist) then
      return x, y
    end
    tries = tries + 1
  until tries >= maxTries

  -- fallback: противоположный угол от героя
  local cx = (heroX < W * 0.5) and (W - m) or m
  local cy = (heroY < H * 0.5) and (H - m) or m
  return cx, cy
end

-- равномерное размещение группы вдоль случайного направления
local function makeGroupPositions(baseX, baseY, n, spacing, W, H, m)
  if n <= 1 then return { {x = baseX, y = baseY} } end
  local a = MathUtils.randomRange(0, 2 * math.pi)
  local ux, uy = math.cos(a), math.sin(a)

  -- центрируем: индексы -k..+k
  local firstIndex = -((n - 1) * 0.5)
  local pts = {}
  for i = 1, n do
    local t = firstIndex + (i - 1)
    local x = baseX + ux * t * spacing
    local y = baseY + uy * t * spacing
    -- если вышли за границы — слегка «подтягиваем» к базе
    if not inBounds(x, y, W, H, m) then
      x = clamp(x, m, W - m)
      y = clamp(y, m, H - m)
    end
    pts[i] = { x = x, y = y }
  end
  return pts
end

-- ===================== ctor ======================

function Spawner.new(mapWidth, mapHeight)
  local self = setmetatable({}, Spawner)

  self.mapWidth  = mapWidth
  self.mapHeight = mapHeight
  self.mapMargin = 100

  -- базовые темпы спавна (можешь потом подкрутить)
  self.cooldown = 2.0
  self.timer    = 0
  self.maxAlive = 20

  self.minDistanceFromHero = 300

  -- хронометр
  self.elapsed = 0

  -- попытки поиска места
  self.maxAttempts = 5

  return self
end

-- живые враги
local function aliveCount(list)
  local c = 0
  for i = 1, #list do
    local e = list[i]
    if e and not e.isDead then c = c + 1 end
  end
  return c
end

-- темп спавна/лимит со временем (опциональная простая динамика)
function Spawner:updateDifficulty(dt)
  self.elapsed = self.elapsed + dt
  -- немного ускоряем спавн и поднимаем лимит со временем
  self.cooldown = math.max(0.6, 2.0 - self.elapsed * 0.01)
  self.maxAlive = math.min(60, math.floor(20 + self.elapsed * 0.12))
end

-- уровень по времени: [0..1:59] = 1, [2:00..2:59] = 2, и т.д.
local function levelFromElapsed(elapsedSeconds, maxLevel)
  local base = math.max(1, math.floor(elapsedSeconds / 60)) -- шаг каждую минуту, но первые 2 мин → 1
  if maxLevel then return clamp(base, 1, maxLevel) end
  return base
end

-- ===================== update ======================

function Spawner:update(dt, world, hero)
  if not world or not hero then return end

  self:updateDifficulty(dt)

  self.timer = self.timer - dt
  if self.timer > 0 then return end

  -- лимит живых
  local alive = aliveCount(world.enemies)
  if alive >= self.maxAlive then
    self.timer = self.cooldown * 0.5
    return
  end

  -- выбор врага
  local enemyId = chooseWeightedEnemy(self.elapsed)
  if not enemyId then
    self.timer = self.cooldown * 0.5
    return
  end
  local cfg = EnemiesConfig[enemyId] or {}

  -- размер шага между юнитами в группе
  local sizeW = cfg.width  or 64
  local sizeH = cfg.height or 64
  local spacing = 2 * math.max(sizeW, sizeH)

  local groupSize = cfg.spawnGroupSize or 1
  local canSpawn  = math.min(groupSize, self.maxAlive - alive)
  if canSpawn <= 0 then
    self.timer = self.cooldown * 0.5
    return
  end

  -- общий уровень (строго по времени) + кэп по maxLevel моба
  local lvl = levelFromElapsed(self.elapsed, cfg.maxLevel)

  -- базовая точка
  local bx, by = randomPointAwayFromHero(
    hero.x, hero.y, self.minDistanceFromHero,
    self.mapWidth, self.mapHeight, self.mapMargin
  )
  if not bx or not by then
    self.timer = self.cooldown * 0.5
    return
  end

  -- позиции группы
  local pts = makeGroupPositions(bx, by, canSpawn, spacing, self.mapWidth, self.mapHeight, self.mapMargin)

  -- спавним
  for i = 1, #pts do
    local px, py = pts[i].x, pts[i].y
    -- финальная проверка «не слишком близко к герою»
    local dx, dy = px - hero.x, py - hero.y
    if (dx*dx + dy*dy) < (self.minDistanceFromHero * self.minDistanceFromHero) then
      -- если близко — сместим вдоль луча от героя
      local d = math.sqrt(dx*dx + dy*dy) + 1e-6
      local k = (self.minDistanceFromHero + 16) / d
      px = hero.x + dx * k
      py = hero.y + dy * k
      px = clamp(px, self.mapMargin, self.mapWidth  - self.mapMargin)
      py = clamp(py, self.mapMargin, self.mapHeight - self.mapMargin)
    end

    local enemy = Enemy.new(px, py, enemyId, lvl)
    world:addEnemy(enemy)
  end

  -- следующий тик
  self.timer = self.cooldown
end

return Spawner
