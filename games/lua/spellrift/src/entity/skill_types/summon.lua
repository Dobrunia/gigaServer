-- src/entity/skill_types/summon.lua
-- Cоздаёт вспомогательное существо (ally) из Object, со своей логикой движения/атаки.
-- Без циклических зависимостей: не требует Creature и не требует Skill.

local MathUtils     = require("src.utils.math_utils")
local SpriteManager = require("src.utils.sprite_manager")
local Constants     = require("src.constants")
local Object        = require("src.entity.object")

local Summon = {}
Summon.__index = Summon

local _pool, _alive = {}, {}

-- ───────────────────────── helpers ─────────────────────────

local function _normalize(x, y)
    local d = math.sqrt(x*x + y*y)
    if d < 1e-6 then return 0, 0 end
    return x/d, y/d
end

local function _dist(ax, ay, bx, by)
    local dx, dy = bx-ax, by-ay
    return math.sqrt(dx*dx + dy*dy)
end

-- ───────────────────────── ctor ─────────────────────────

local function _addInternalSkill(summonObj, skillId)
    -- берём «сырой» конфиг скилла и делаем лёгкую версию без require Skill
    local cfg = require("src.config.skills")[skillId]
    if not cfg then return end

    local s = {
        id = cfg.id,
        type = cfg.type,
        stats = MathUtils.deepCopy(cfg.stats or {}),
        level = 1,
        isOnCooldown = false,
        cooldownTimer = 0,
        caster = summonObj,
    }

    function s:canCast()
        return not self.isOnCooldown and (self.cooldownTimer <= 0)
    end

    function s:startCooldown()
        self.isOnCooldown = true
        self.cooldownTimer = self.stats.cooldown or 1.0
    end

    function s:update(dt)
        if self.isOnCooldown then
            self.cooldownTimer = self.cooldownTimer - dt
            if self.cooldownTimer <= 0 then
                self.isOnCooldown, self.cooldownTimer = false, 0
            end
        end
    end

    function s:castAt(world, tx, ty)
        if not self:canCast() then return false end
        if not (world and self.caster) then return false end

        if self.type == "melee" then
            local Melee = require("src.entity.skill_types.melee")
            -- во время замаха слегка «заморозим» саммона
            local wind = (self.stats and self.stats.windup) or 0
            if wind > 0 then
                self.caster._lockMoveTimer = math.max(self.caster._lockMoveTimer or 0, wind)
                self.caster._lockFaceTimer = math.max(self.caster._lockFaceTimer or 0, wind)
            end
            Melee.spawn(world, self.caster, self, tx, ty)
            self:startCooldown()
            return true

        elseif self.type == "projectile" then
            local Projectile = require("src.entity.projectile")
            Projectile.spawn(world, self.caster, self, tx, ty)
            self:startCooldown()
            return true
        end

        return false
    end

    table.insert(summonObj.skills, s)
end

local function _build(world, caster, outerSkill)
    local st = outerSkill.stats or {}
    
    -- получаем сырой конфиг скилла
    local skillConfig = require("src.config.skills")[outerSkill.id]

    -- точка спавна рядом с кастером
    local spawnX = caster.x + (caster.effectiveWidth  or 0) * 0.5 + (math.random()-0.5)*100
    local spawnY = caster.y + (caster.effectiveHeight or 0) * 0.5 + (math.random()-0.5)*100

    -- спрайт — через id скилла (как просили)
    local spriteSheet = SpriteManager.loadSkillSprite(outerSkill.id)

    local summon = Object.new(
        spriteSheet,
        spawnX, spawnY,
        skillConfig.width or 64,
        skillConfig.height or 64
    )

    -- базовые параметры
    summon.world      = world
    summon.isDead     = false
    summon.hp         = st.health or 100
    summon.maxHp      = st.health or 100
    summon.armor      = st.armor  or 0
    summon.moveSpeed  = st.moveSpeed or 80
    summon.facing     = 1
    summon.skills     = {}
    summon.debuffs    = {}
    summon._vx, summon._vy = 0, 0
    summon._lockMoveTimer, summon._lockFaceTimer = 0, 0
    summon._castAnimTimer = 0  -- таймер для анимации каста
    summon._animChangeTimer = 0  -- таймер для задержки смены анимаций
    
    -- добавляем метод получения урона
    function summon:takeDamage(damage)
        if self.isDead then return end
        
        -- применяем броню
        local actualDamage = damage
        if self.armor and self.armor > 0 then
            local reduction = 1 - math.min(0.75, self.armor * 0.06)
            actualDamage = damage * reduction
        end
        
        self.hp = self.hp - actualDamage
        
        -- показываем цифру урона если включена отладка
        if self.world and self.world.damageManager then
            local color = {1, 0, 0, 1} -- красный для урона
            self.world.damageManager:addDamageNumber(self.x, self.y, actualDamage, color)
        end
        
        if self.hp <= 0 then
            self.hp = 0
            self.isDead = true
        end
    end

    -- анимации
    local q = skillConfig.quads or {}
    if q.idle then
        local r = q.idle
        summon:setAnimationList("idle", r.startrow or r.row, r.startcol or r.col, r.endcol or r.col, 999999)
        summon:playAnimation("idle")
    else
        -- дефолт на случай отсутствия квадов
        summon:setAnimationList("idle", 1, 1, 1, 999999)
        summon:playAnimation("idle")
    end

    if q.walk then
        local r = q.walk
        local spd = r.animationSpeed or 0.3
        summon:setAnimationList("walk", r.startrow or r.row, r.startcol or r.col, r.endcol or r.col, spd)
    end

    if q.cast then
        local r = q.cast
        local spd = r.animationSpeed or 0.5
        summon:setAnimationList("cast", r.startrow or r.row, r.startcol or r.col, r.endcol or r.col, spd)
    end

    -- внутренние скиллы саммона
    if skillConfig.skills then
        for _, skillId in ipairs(skillConfig.skills) do
            _addInternalSkill(summon, skillId)
        end
    end

    local self = {
        _dead   = false,
        world   = world,
        caster  = caster,
        skill   = outerSkill,
        summon  = summon,
        timer   = 0,

        duration       = st.duration or 30.0,
        followDistance = st.followDistance or 500
    }
    setmetatable(self, Summon)
    return self
end

function Summon.spawn(world, caster, skill)
    local self = table.remove(_pool)
    if self then
        for k in pairs(self) do self[k] = nil end
        local fresh = _build(world, caster, skill)
        for k,v in pairs(fresh) do self[k] = v end
        setmetatable(self, Summon)
    else
        self = _build(world, caster, skill)
    end
    self._dead = false
    table.insert(_alive, self)
    
    -- регистрируем саммона в мире
    if world and world.summons then
        table.insert(world.summons, self)
    end
    
    return self
end

-- ───────────────────────── logic ─────────────────────────

function Summon:_findNearestEnemy()
    local s = self.summon
    if not s.world or not s.world.enemies then return nil, math.huge end
    local best, bestD = nil, math.huge
    local sx = s.x + (s.effectiveWidth or 0)*0.5
    local sy = s.y + (s.effectiveHeight or 0)*0.5
    for _, e in ipairs(s.world.enemies) do
        if e and not e.isDead then
            local ex = e.x + (e.effectiveWidth or 0)*0.5
            local ey = e.y + (e.effectiveHeight or 0)*0.5
            local d = _dist(sx, sy, ex, ey)
            if d < bestD then best, bestD = e, d end
        end
    end
    return best, bestD
end

function Summon:_moveTowards(x, y, dt)
    local s = self.summon
    if (s._lockMoveTimer or 0) > 0 then return end
    local dx, dy = x - (s.x + (s.effectiveWidth or 0)*0.5), y - (s.y + (s.effectiveHeight or 0)*0.5)
    local nx, ny = _normalize(dx, dy)
    local step = (s.moveSpeed or 80) * dt
    s:changePosition(nx*step, ny*step)

    -- записываем движение для анимаций
    s._lastMoveX = nx * step
    s._lastMoveY = ny * step
    
    if dx < -0.001 then s.facing = -1 elseif dx > 0.001 then s.facing = 1 end
end

function Summon:_combatAI(dt)
    local s = self.summon
    local cx = self.caster.x + (self.caster.effectiveWidth  or 0)*0.5
    local cy = self.caster.y + (self.caster.effectiveHeight or 0)*0.5
    local sx = s.x + (s.effectiveWidth or 0)*0.5
    local sy = s.y + (s.effectiveHeight or 0)*0.5

    -- 1) не отставать от хозяина
    local toCaster = _dist(sx, sy, cx, cy)
    if toCaster > (self.followDistance or 500) then
        self:_moveTowards(cx, cy, dt)
        return
    end

    -- 2) работать по ближайшему врагу
    local enemy, dist = self:_findNearestEnemy()
    if not enemy then
        if s.animationsList["idle"] then s:playAnimation("idle") end
        return
    end

    -- поворот
    local dx = enemy.x - s.x
    if dx < -0.001 then s.facing = -1 elseif dx > 0.001 then s.facing = 1 end

    -- подходим, если далеко от дистанции самого близкого готового скилла
    local minReady, minAny = nil, nil
    for _, sk in ipairs(s.skills) do
        local r = (sk.stats and sk.stats.range) or 0
        if r and r > 0 then
            minAny = (minAny and math.min(minAny, r)) or r
            if sk:canCast() then
                minReady = (minReady and math.min(minReady, r)) or r
            end
        end
    end
    local stopDist = minReady or minAny or 120
    local hyst = 8
    local stopWithHyst = math.max(0, stopDist - hyst)

    if dist > stopWithHyst then
        local ex = enemy.x + (enemy.effectiveWidth or 0)*0.5
        local ey = enemy.y + (enemy.effectiveHeight or 0)*0.5
        self:_moveTowards(ex, ey, dt)
    else
        -- убираем переключение анимации отсюда - теперь это делает _updateAnimations
        -- попытка атаки
        for _, sk in ipairs(s.skills) do
            if sk:canCast() then
                local ex = enemy.x + (enemy.effectiveWidth or 0)*0.5
                local ey = enemy.y + (enemy.effectiveHeight or 0)*0.5
                local r = (sk.stats and sk.stats.range) or 0
                if r == 0 or dist <= r + 1 then
                    if s.animationsList["cast"] then 
                        s:playAnimation("cast")
                        s._castAnimTimer = 0.5  -- длительность анимации каста
                        s._animChangeTimer = 0.2  -- задержка перед следующей сменой анимации
                    end
                    -- лочим фейс на короткое окно (если задан windup)
                    if sk.type == "melee" then
                        local wind = (sk.stats and sk.stats.windup) or 0
                        if wind > 0 then
                            s._lockFaceTimer = math.max(s._lockFaceTimer or 0, wind)
                            s._lockMoveTimer = math.max(s._lockMoveTimer or 0, wind)
                        end
                    end
                    sk:castAt(s.world, ex, ey)
                    break
                end
            end
        end
    end
end

function Summon:update(dt)
    self.timer = self.timer + dt
    local s = self.summon

    if (not s) or s.isDead or (not self.caster) or self.caster.isDead then
        self:dispose(); return
    end
    if self.timer >= (self.duration or 30.0) then
        self:dispose(); return
    end

    -- тики лочков
    if s._lockMoveTimer and s._lockMoveTimer > 0 then
        s._lockMoveTimer = math.max(0, s._lockMoveTimer - dt)
    end
    if s._lockFaceTimer and s._lockFaceTimer > 0 then
        s._lockFaceTimer = math.max(0, s._lockFaceTimer - dt)
        -- удерживаем фейс
    end
    
    -- тик анимации каста
    if s._castAnimTimer and s._castAnimTimer > 0 then
        s._castAnimTimer = math.max(0, s._castAnimTimer - dt)
    end
    
    -- тик задержки смены анимаций
    if s._animChangeTimer and s._animChangeTimer > 0 then
        s._animChangeTimer = math.max(0, s._animChangeTimer - dt)
    end

    -- 1) СНАЧАЛА ИИ (движение/касты)
    self:_combatAI(dt)

    -- 2) затем обновим внутренние кулдауны скиллов
    for _, sk in ipairs(s.skills) do
        if sk.update then sk:update(dt) end
    end

    -- 3) и только ПОТОМ апдейт объекта (анимации корректно выберутся)
    s:update(dt)
    
    -- 4) переключение анимаций после обновления
    self:_updateAnimations()
    
    -- 5) сбрасываем накопленное движение
    s._lastMoveX, s._lastMoveY = 0, 0
end

function Summon:_updateAnimations()
    local s = self.summon
    if not s or s.isDead then return end
    
    -- если играет cast анимация и таймер не истек, не переключаем
    if s.currentAnimation == "cast" and (s._castAnimTimer or 0) > 0 then
        return
    end
    
    -- если не прошло достаточно времени с последней смены анимации, не переключаем
    if (s._animChangeTimer or 0) > 0 then
        return
    end
    
    -- проверяем движение - используем _lastMoveX и _lastMoveY как в Creature
    local mv = math.abs(s._lastMoveX or 0) + math.abs(s._lastMoveY or 0)
    
    if mv > 0.01 and s.animationsList["walk"] then
        if s.currentAnimation ~= "walk" then
            s:playAnimation("walk")
            s._animChangeTimer = 0.2  -- задержка 200мс перед следующей сменой
        end
    elseif s.animationsList["idle"] then
        if s.currentAnimation ~= "idle" then
            s:playAnimation("idle")
            s._animChangeTimer = 0.2  -- задержка 200мс перед следующей сменой
        end
    end
end

-- ───────────────────────── draw ─────────────────────────

function Summon:draw()
    local s = self.summon
    if not s or s.isDead then return end

    s:draw()

    -- Duration bar (желтая полоска времени жизни)
    local bw, bh = s.effectiveWidth or 64, 4
    local bx, by = s.x, s.y - 20
    local durationPercent = (self.duration > 0) and (1 - self.timer / self.duration) or 1
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", bx, by, bw, bh)
    love.graphics.setColor(1, 1, 0, 0.9) -- желтый цвет
    love.graphics.rectangle("fill", bx, by, bw * durationPercent, bh)

    -- HP bar
    local hpBy = s.y - 10
    local hp = (s.maxHp > 0) and (s.hp / s.maxHp) or 0
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", bx, hpBy, bw, bh)
    love.graphics.setColor(0, 1, 0, 0.9)
    love.graphics.rectangle("fill", bx, hpBy, bw * hp, bh)
    
    -- Level text
    local levelText = "Lv." .. (s.level or 1)
    local textX = s.x + (s.effectiveWidth or 64) * 0.5
    local textY = s.y - 35
    
    -- Фон для текста
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(levelText)
    local textHeight = font:getHeight()
    
    love.graphics.setColor(0, 0, 0, 0.7) -- черный полупрозрачный фон
    love.graphics.rectangle("fill", textX - textWidth * 0.5 - 2, textY - textHeight * 0.5 - 1, textWidth + 4, textHeight + 2)
    
    -- Текст уровня
    love.graphics.setColor(1, 1, 0, 1) -- желтый цвет
    love.graphics.printf(levelText, textX - textWidth * 0.5, textY - textHeight * 0.5, textWidth, "center")
    
    love.graphics.setColor(1, 1, 1, 1)
end

-- ───────────────────────── pool ─────────────────────────

function Summon:isDead() return self._dead end

function Summon:dispose()
    self._dead = true
    if self.summon then self.summon.isDead = true end
    
    -- удаляем из мира
    if self.world and self.world.summons then
        for i = #self.world.summons, 1, -1 do
            if self.world.summons[i] == self then
                table.remove(self.world.summons, i)
                break
            end
        end
    end
    
    self.world, self.caster, self.skill, self.summon = nil, nil, nil, nil
    table.insert(_pool, self)
end

function Summon.updateAll(dt)
    for i = #_alive, 1, -1 do
        local s = _alive[i]
        if not s or not s.update then
            table.remove(_alive, i)
        else
            s:update(dt)
            if s:isDead() then table.remove(_alive, i) end
        end
    end
end

function Summon.drawAll()
    for i = 1, #_alive do
        local s = _alive[i]
        if s and s.draw then s:draw() end
    end
end

return Summon
