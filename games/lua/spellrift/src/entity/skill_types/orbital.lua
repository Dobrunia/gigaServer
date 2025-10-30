local MathUtils = require("src.utils.math_utils")
local Projectile = require("src.entity.projectile")
local SpriteManager = require("src.utils.sprite_manager")
local Constants = require("src.constants")

local Orbital = {}
Orbital.__index = Orbital

local _pool  = {}
local _alive = {}

-- ================== helpers ==================

local function _normalize(x, y)
    local d = math.sqrt(x*x + y*y)
    if d < 1e-6 then return 0, 0 end
    return x/d, y/d
end

-- ================== ctor ==================

local function _build(world, caster, skill)
    local self = {
        _dead = false,
        world  = world,
        caster = caster,
        skill  = skill,
        timer  = 0,
        projectiles = {}, -- массив орбитальных проджектайлов
    }
    setmetatable(self, Orbital)

    local st = skill.stats or {}

    -- тайминги
    self.duration = st.duration or 10.0  -- длительность существования
    self.spawnDelay = st.spawnDelay or 0.1  -- задержка между спавном проджектайлов

    -- орбитальные параметры
    self.orbitRadius = st.orbitRadius or 80  -- радиус орбиты
    self.orbitSpeed = st.orbitSpeed or 2.0   -- скорость вращения вокруг кастера (рад/сек)
    self.projectileCount = st.projectileCount or 3  -- количество проджектайлов
    self.projectileSpacing = (2 * math.pi) / self.projectileCount  -- угол между проджектайлами

    -- параметры проджектайлов
    self.projectileDamage = st.damage or 20
    self.projectileRadius = st.radius or 12
    self.projectileSpeed = st.speed or 0  -- 0 = статичные, >0 = движутся по орбите
    self.selfRotationSpeed = st.selfRotationSpeed or 0  -- скорость вращения вокруг своей оси
    self.hitCooldown = st.hitCooldown or 0.4

    -- поведение
    self.followCaster = (st.followCaster ~= false)  -- следовать за кастером
    self.destroyOnCasterDeath = (st.destroyOnCasterDeath ~= false)  -- уничтожать при смерти кастера

    return self
end

function Orbital.spawn(world, caster, skill)
    local self = table.remove(_pool)
    if self then
        -- реинициализация в существующий объект пула
        for k in pairs(self) do self[k] = nil end
        local fresh = _build(world, caster, skill)
        for k,v in pairs(fresh) do self[k] = v end
        setmetatable(self, Orbital)
    else
        self = _build(world, caster, skill)
    end
    self._dead = false
    table.insert(_alive, self)
    
    -- Создаем орбитальные проджектайлы
    self:_spawnProjectiles()
    
    return self
end

-- Создание орбитальных проджектайлов
function Orbital:_spawnProjectiles()
    local casterX = self.caster.x + (self.caster.effectiveWidth or 0) * 0.5
    local casterY = self.caster.y + (self.caster.effectiveHeight or 0) * 0.5
    
    for i = 0, self.projectileCount - 1 do
        local angle = i * self.projectileSpacing
        local x = casterX + math.cos(angle) * self.orbitRadius
        local y = casterY + math.sin(angle) * self.orbitRadius
        
        -- Создаем специальный проджектайл для орбиты
        local projectile = self:_createOrbitalProjectile(x, y, angle)
        table.insert(self.projectiles, projectile)
    end
end

-- Создание орбитального проджектайла
function Orbital:_createOrbitalProjectile(x, y, initialAngle)
    local skillId = self.skill.id
    local skillConfig = require("src.config.skills")[skillId]
    
    -- Загружаем спрайт скилла
    local spriteSheet = SpriteManager.loadSkillSprite(skillId)
    local quads = skillConfig.quads or {}
    local flyQuad = nil
    
    -- Создаем quad для анимации полета
    if quads.fly then
        local fly = quads.fly
        local quadWidth = 64  -- размер кадра в спрайте
        local quadHeight = 64
        local col = fly.startcol or fly.col or 1
        local row = fly.startrow or fly.row or 1
        
        flyQuad = love.graphics.newQuad(
            (col - 1) * quadWidth, 
            (row - 1) * quadHeight, 
            quadWidth, 
            quadHeight, 
            spriteSheet:getWidth(), 
            spriteSheet:getHeight()
        )
    end
    
    local projectile = {
        x = x,
        y = y,
        angle = initialAngle,  -- угол на орбите
        selfRotation = 0,      -- вращение вокруг своей оси
        damage = self.projectileDamage,
        radius = self.projectileRadius,
        speed = self.projectileSpeed,
        selfRotationSpeed = self.selfRotationSpeed,
        world = self.world,
        caster = self.caster,
        skill = self.skill,
        isDead = false,
        -- Спрайт
        spriteSheet = spriteSheet,
        flyQuad = flyQuad,
        scale = 1.0,
        -- Per-target hit cooldown
        _recentHits = {}  -- таблица последних попаданий по целям
    }
    
    return projectile
end

-- ================== logic ==================

function Orbital:update(dt)
    self.timer = self.timer + dt

    -- Проверяем условия уничтожения
    if self.timer >= self.duration then
        self:dispose()
        return
    end
    
    if self.destroyOnCasterDeath and (not self.caster or self.caster.isDead) then
        self:dispose()
        return
    end

    -- Обновляем позиции проджектайлов
    self:_updateProjectiles(dt)
    
    -- Проверяем попадания
    self:_checkHits()
end

function Orbital:_updateProjectiles(dt)
    local casterX = self.caster.x + (self.caster.effectiveWidth or 0) * 0.5
    local casterY = self.caster.y + (self.caster.effectiveHeight or 0) * 0.5
    
    for i, projectile in ipairs(self.projectiles) do
        if not projectile.isDead then
            -- Обновляем угол на орбите
            projectile.angle = projectile.angle + self.orbitSpeed * dt
            
            -- Обновляем позицию на орбите
            projectile.x = casterX + math.cos(projectile.angle) * self.orbitRadius
            projectile.y = casterY + math.sin(projectile.angle) * self.orbitRadius
            
            -- Обновляем вращение вокруг своей оси
            if projectile.selfRotationSpeed > 0 then
                projectile.selfRotation = projectile.selfRotation + projectile.selfRotationSpeed * dt
            end
        end
    end
end

function Orbital:_checkHits()
    local targets = (self.caster and self.caster.enemyId)
        and (self.world and self.world.heroes)
        or  (self.world and self.world.enemies)
    if not targets then return end

    local now = love.timer.getTime()  -- текущее время (в секундах)

    for _, projectile in ipairs(self.projectiles) do
        if not projectile.isDead then
            for _, target in ipairs(targets) do
                if target and not target.isDead then
                    local targetWidth = target.effectiveWidth or 0
                    local targetHeight = target.effectiveHeight or 0
                    local closestX = math.max(target.x, math.min(projectile.x, target.x + targetWidth))
                    local closestY = math.max(target.y, math.min(projectile.y, target.y + targetHeight))
                    local ddx, ddy = projectile.x - closestX, projectile.y - closestY
                    local distanceSquared = ddx*ddx + ddy*ddy
                    local radiusSquared = projectile.radius * projectile.radius

                    if distanceSquared <= radiusSquared then
                        -- ⏳ проверяем, можно ли снова бить эту цель
                        local lastHit = projectile._recentHits[target]
                        if not lastHit or (now - lastHit) >= self.hitCooldown then
                            projectile._recentHits[target] = now  -- обновляем время

                            -- Наносим урон один раз в HIT_COOLDOWN
                            if target.takeDamage then 
                                target:takeDamage(projectile.damage)
                                if self.caster and self.caster.dealDamage then
                                    self.caster:dealDamage(projectile.damage)
                                end
                            end

                            -- Дебаффы
                            local st = self.skill.stats
                            if st.debuffType and target.addDebuff then
                                target:addDebuff(st.debuffType, st.debuffDuration, {
                                    damage = st.debuffDamage,
                                    tickRate = st.debuffTickRate
                                }, self.caster)
                            end

                            -- Если destroyOnHit == true, убиваем снаряд как раньше
                            if st.destroyOnHit ~= false then
                                projectile.isDead = true
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ================== draw ==================

function Orbital:draw()
    for i, projectile in ipairs(self.projectiles) do
        if not projectile.isDead then
            -- Рисуем спрайт проджектайла
            if projectile.spriteSheet and projectile.flyQuad then
                -- Размер спрайта = radius * 2 (диаметр), но масштабируем под размер спрайта
                local spriteSize = 64  -- размер кадра в спрайте
                local targetSize = projectile.radius * 2  -- желаемый размер (диаметр)
                local scale = targetSize / spriteSize  -- масштаб для достижения нужного размера
                
                -- Вычисляем угол поворота (орбитальный + собственный)
                local totalRotation = projectile.angle + projectile.selfRotation
                
                love.graphics.draw(
                    projectile.spriteSheet,
                    projectile.flyQuad,
                    projectile.x,
                    projectile.y,
                    totalRotation,
                    scale,
                    scale,
                    spriteSize * 0.5,  -- центр спрайта (32, 32)
                    spriteSize * 0.5   -- центр спрайта (32, 32)
                )
            else
                -- Fallback: простой круг если нет спрайта
                love.graphics.setColor(1, 0.5, 0, 0.8) -- оранжевый
                love.graphics.circle("fill", projectile.x, projectile.y, projectile.radius)
                love.graphics.setColor(1, 1, 0, 1) -- желтый контур
                love.graphics.circle("line", projectile.x, projectile.y, projectile.radius)
            end
            
            -- Рисуем хитбокс если включена отладка
            if Constants.DEBUG_DRAW_HITBOXES then
                love.graphics.setColor(0, 1, 0, 0.5) -- зеленый полупрозрачный
                love.graphics.circle("line", projectile.x, projectile.y, projectile.radius)
                love.graphics.setColor(1, 1, 1, 1) -- сбрасываем цвет
            end
            
            -- Рисуем направление если есть вращение (для отладки)
            if projectile.selfRotationSpeed > 0 and Constants.DEBUG_DRAW_DIRECTION_ARROW then
                local dirX = math.cos(projectile.selfRotation) * projectile.radius
                local dirY = math.sin(projectile.selfRotation) * projectile.radius
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.line(projectile.x, projectile.y, 
                                 projectile.x + dirX, projectile.y + dirY)
            end
        end
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

-- ================== pool ==================

function Orbital:isDead() return self._dead end

function Orbital:dispose()
    self._dead = true
    self.world, self.caster, self.skill = nil, nil, nil
    self.projectiles = {}
    table.insert(_pool, self)
end

function Orbital.updateAll(dt, world)
    for i = #_alive, 1, -1 do
        local o = _alive[i]
        if not o or not o.update then
            table.remove(_alive, i)
        else
            o:update(dt)
            if o:isDead() then table.remove(_alive, i) end
        end
    end
end

function Orbital.drawAll()
    for i = 1, #_alive do
        local o = _alive[i]
        if o and o.draw then o:draw() end
    end
end

function Orbital.clearAll()
    for i = #_alive, 1, -1 do
        _alive[i] = nil
    end
    for i = #_pool, 1, -1 do
        _pool[i] = nil
    end
end

return Orbital
