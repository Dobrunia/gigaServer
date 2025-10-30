local MathUtils = require("src.utils.math_utils")
local SpriteManager = require("src.utils.sprite_manager")
local Constants = require("src.constants")

local GroundAOE = {}
GroundAOE.__index = GroundAOE

local _pool  = {}
local _alive = {}

-- === helpers ===
local function getTargetsList(world, caster)
    if caster and caster.enemyId then
        -- враг кастует → цели герои + саммоны
        local list = {}
        if world and world.heroes then
            for i = 1, #world.heroes do list[#list+1] = world.heroes[i] end
        end
        if world and world.summons then
            for i = 1, #world.summons do
                local s = world.summons[i]
                if s and s.summon and not s.summon.isDead then list[#list+1] = s.summon end
            end
        end
        return list
    else
        return world and world.enemies or nil
    end
end

local function pickUpToNNearestTargets(world, caster, count)
    local list = getTargetsList(world, caster)
    if not list or #list == 0 then return {} end
    local cx = caster.x + (caster.effectiveWidth or 0) * 0.5
    local cy = caster.y + (caster.effectiveHeight or 0) * 0.5
    local tmp = {}
    for i = 1, #list do
        local t = list[i]
        if t and not t.isDead then
            local px = t.x + (t.effectiveWidth or 0) * 0.5
            local py = t.y + (t.effectiveHeight or 0) * 0.5
            local dx, dy = px - cx, py - cy
            tmp[#tmp+1] = { target = t, d2 = dx*dx + dy*dy }
        end
    end
    table.sort(tmp, function(a,b) return a.d2 < b.d2 end)
    local out = {}
    for i = 1, math.min(count or 1, #tmp) do
        out[#out+1] = tmp[i].target
    end
    return out
end

-- targets within distance band from caster center
local function findTargetsInBand(world, caster, rmin, rmax)
    local list = getTargetsList(world, caster)
    if not list or #list == 0 then return {} end
    local cx = caster.x + (caster.effectiveWidth or 0) * 0.5
    local cy = caster.y + (caster.effectiveHeight or 0) * 0.5
    local rmin2 = (rmin or 0) * (rmin or 0)
    local rmax2 = (rmax or math.huge)
    rmax2 = rmax2 * rmax2
    local out = {}
    for i = 1, #list do
        local t = list[i]
        if t and not t.isDead then
            local px = t.x + (t.effectiveWidth or 0) * 0.5
            local py = t.y + (t.effectiveHeight or 0) * 0.5
            local dx, dy = px - cx, py - cy
            local d2 = dx*dx + dy*dy
            if d2 >= rmin2 and d2 <= rmax2 then
                out[#out+1] = t
            end
        end
    end
    return out
end

-- === ctor ===
local function _build(world, caster, skill, x, y, startDelay, target)
    local st = skill.stats or {}
    local self = {
        _dead = false,
        world = world,
        caster = caster,
        skill = skill,
        timer = 0,
        startDelay = startDelay or 0,
        state = "arming", -- arming -> exploded -> fading
        x = x, y = y,
        target = target, -- для followTargetDuringArm

        -- cached
        radius = st.radius or 80,
        armTime = st.armTime or 1.0,
        zoneLifetime = st.zoneLifetime or 0.2,
        warningBlinkSpeed = st.warningBlinkSpeed or 8.0,
        warningAlphaMin = st.warningAlphaMin or 0.25,
        warningAlphaMax = st.warningAlphaMax or 0.85,
        color = st.color or {1,0,0},
        followTargetDuringArm = (st.followTargetDuringArm == true),
        followTargetSpeed = st.followTargetSpeed or 0,

        -- visuals (optional sprite)
        spriteSheet = nil,
        flyCfg = nil,
    }
    setmetatable(self, GroundAOE)
    -- try to load sprite for this skill id
    local skillId = skill.id
    local skillConfig = require("src.config.skills")[skillId]
    if skillConfig and skillConfig.quads and skillConfig.quads.fly then
        self.spriteSheet = SpriteManager.loadSkillSprite(skillId)
        self.flyCfg = skillConfig.quads.fly -- startrow, startcol, endcol
    end
    return self
end

-- публичный спавн: создаёт серии зон согласно конфигу
function GroundAOE.spawn(world, caster, skill)
    local st = skill.stats or {}
    local count = math.max(1, st.spawnCount or 1)
    local interval = math.max(0, st.spawnInterval or 0)
    local created = {}

    if (st.spawnMode == "on_target") then
        -- берём цели ТОЛЬКО в диапазоне [spawnRadiusMin, spawnRadiusMax]
        local candidates = findTargetsInBand(world, caster, st.spawnRadiusMin or 0, st.spawnRadiusMax or math.huge)
        -- сортируем по близости и ограничиваем количеством
        table.sort(candidates, function(a,b)
            local cx = caster.x + (caster.effectiveWidth or 0) * 0.5
            local cy = caster.y + (caster.effectiveHeight or 0) * 0.5
            local ax = a.x + (a.effectiveWidth or 0) * 0.5
            local ay = a.y + (a.effectiveHeight or 0) * 0.5
            local bx = b.x + (b.effectiveWidth or 0) * 0.5
            local by = b.y + (b.effectiveHeight or 0) * 0.5
            local ad2 = (ax-cx)*(ax-cx) + (ay-cy)*(ay-cy)
            local bd2 = (bx-cx)*(bx-cx) + (by-cy)*(by-cy)
            return ad2 < bd2
        end)
        local targets = {}
        for i = 1, math.min(count, #candidates) do targets[i] = candidates[i] end
        for i = 1, #targets do
            local t = targets[i]
            local px = t.x + (t.effectiveWidth or 0) * 0.5
            local py = t.y + (t.effectiveHeight or 0) * 0.5
            local z = table.remove(_pool) or {}
            for k in pairs(z) do z[k] = nil end
            local fresh = _build(world, caster, skill, px, py, (i-1)*interval, t)
            for k, v in pairs(fresh) do z[k] = v end
            setmetatable(z, GroundAOE)
            _alive[#_alive+1] = z
            created[#created+1] = z
        end
    else
        -- around_caster: случайные точки в кольце
        local cx = caster.x + (caster.effectiveWidth or 0) * 0.5
        local cy = caster.y + (caster.effectiveHeight or 0) * 0.5
        local rmin = st.spawnRadiusMin or 100
        local rmax = st.spawnRadiusMax or 250
        -- спавним только если есть хотя бы одна цель в бэнде
        local bandTargets = findTargetsInBand(world, caster, rmin, rmax)
        if #bandTargets == 0 then
            return created
        end
        for i = 1, count do
            local ang = MathUtils.randomRange(0, 2*math.pi)
            local dist = MathUtils.randomRange(rmin, rmax)
            local x = cx + math.cos(ang) * dist
            local y = cy + math.sin(ang) * dist
            local z = table.remove(_pool) or {}
            for k in pairs(z) do z[k] = nil end
            local fresh = _build(world, caster, skill, x, y, (i-1)*interval, nil)
            for k, v in pairs(fresh) do z[k] = v end
            setmetatable(z, GroundAOE)
            _alive[#_alive+1] = z
            created[#created+1] = z
        end
    end

    return created
end

-- предкастовая проверка: есть ли цели в кольце спавна
function GroundAOE.hasEligibleTargets(world, caster, skill)
    local st = skill.stats or {}
    local rmin = st.spawnRadiusMin or 0
    local rmax = st.spawnRadiusMax or math.huge
    local list = findTargetsInBand(world, caster, rmin, rmax)
    return list and #list > 0
end

-- === logic ===
function GroundAOE:_applyExplosion()
    local st = self.skill.stats or {}
    local dmg = st.damage or 0
    local targets = getTargetsList(self.world, self.caster)
    if not targets then return end
    local cx, cy, r = self.x, self.y, self.radius

    for i = 1, #targets do
        local t = targets[i]
        if t and not t.isDead then
            local rx, ry = t.x, t.y
            local rw = t.effectiveWidth or 0
            local rh = t.effectiveHeight or 0
            -- точная проверка пересечения круга и AABB цели (учёт краёв)
            if MathUtils.circleIntersectsRect(cx, cy, r, rx, ry, rw, rh) then
                if t.takeDamage then t:takeDamage(dmg) end
                if self.caster and self.caster.dealDamage then
                    self.caster:dealDamage(dmg)
                end
                -- опциональный дебафф
                if st.debuffType and t.addDebuff then
                    t:addDebuff(st.debuffType, st.debuffDuration or 0, {
                        damage = st.debuffDamage or 0,
                        tickRate = st.debuffTickRate or 0
                    }, self.caster)
                end
            end
        end
    end
end

function GroundAOE:update(dt)
    self.timer = self.timer + dt

    if self.timer < (self.startDelay or 0) then
        return
    end

    local localTime = self.timer - (self.startDelay or 0)

    if self.state == "arming" then
        -- если нужно следовать за целью во время зарядки
        if self.followTargetDuringArm and self.target and (not self.target.isDead) and self.followTargetSpeed > 0 then
            local tx = self.target.x + (self.target.effectiveWidth or 0) * 0.5
            local ty = self.target.y + (self.target.effectiveHeight or 0) * 0.5
            local dx, dy = tx - self.x, ty - self.y
            local nx, ny = MathUtils.normalize(dx, dy)
            local step = self.followTargetSpeed * dt
            self.x = self.x + nx * step
            self.y = self.y + ny * step
        end

        if localTime >= self.armTime then
            -- взрыв
            self.state = "exploded"
            self:_applyExplosion()
            self._stateTimer = 0
        end
    elseif self.state == "exploded" then
        self._stateTimer = (self._stateTimer or 0) + dt
        if self._stateTimer >= (self.zoneLifetime or 0) then
            self:dispose()
        end
    end
end

-- === draw ===
function GroundAOE:draw()
    local st = self.skill.stats or {}
    if self.timer < (self.startDelay or 0) then return end

    local localTime = self.timer - (self.startDelay or 0)
    local r = self.radius
    local cx, cy = self.x, self.y

    if self.state == "arming" then
        -- мигающая красная зона
        local aMin, aMax = self.warningAlphaMin, self.warningAlphaMax
        local freq = self.warningBlinkSpeed
        local t = 0.5 * (1 + math.sin(localTime * 2 * math.pi * freq))
        local alpha = aMin + (aMax - aMin) * t
        love.graphics.setColor(self.color[1], self.color[2], self.color[3], alpha)
        love.graphics.circle("fill", cx, cy, r)
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.circle("line", cx, cy, r)

        if Constants.DEBUG_DRAW_HITBOXES then
            love.graphics.setColor(0, 1, 0, 0.4)
            love.graphics.circle("line", cx, cy, r)
            love.graphics.setColor(1,1,1,1)
        end
    elseif self.state == "exploded" then
        -- FLY: анимация после нанесения урона до конца zoneLifetime
        if self.spriteSheet and self.flyCfg then
            local cfg = self.flyCfg
            local totalCols = (cfg.endcol or cfg.startcol or cfg.col or 1) - (cfg.startcol or cfg.col or 1) + 1
            local progress = (self._stateTimer or 0) / (self.zoneLifetime > 0 and self.zoneLifetime or 0.0001)
            progress = MathUtils.clamp(progress, 0, 1)
            local frameIndex = (cfg.startcol or cfg.col or 1) + math.floor(progress * math.max(0, totalCols - 1))
            local row = cfg.startrow or cfg.row or 1
            local spriteSize = 64
            local quad = love.graphics.newQuad((frameIndex - 1) * spriteSize, (row - 1) * spriteSize, spriteSize, spriteSize, self.spriteSheet:getWidth(), self.spriteSheet:getHeight())
            local scale = (r * 2) / spriteSize
            love.graphics.setColor(1,1,1,1)
            love.graphics.draw(self.spriteSheet, quad, cx, cy, 0, scale, scale, spriteSize * 0.5, spriteSize * 0.5)
        else
            -- fallback вспышка / затухание
            local k = 1 - MathUtils.clamp((self._stateTimer or 0) / (self.zoneLifetime > 0 and self.zoneLifetime or 0.0001), 0, 1)
            love.graphics.setColor(1, 1, 1, 0.6 * k)
            love.graphics.circle("fill", cx, cy, r)
            love.graphics.setColor(1, 1, 0, 0.8 * k)
            love.graphics.circle("line", cx, cy, r)
            love.graphics.setColor(1,1,1,1)
        end
    end
end

-- === pool ===
function GroundAOE:isDead() return self._dead end

function GroundAOE:dispose()
    self._dead = true
    self.world, self.caster, self.skill = nil, nil, nil
    table.insert(_pool, self)
end

function GroundAOE.updateAll(dt, world)
    for i = #_alive, 1, -1 do
        local z = _alive[i]
        if not z or not z.update then
            table.remove(_alive, i)
        else
            z:update(dt)
            if z:isDead() then table.remove(_alive, i) end
        end
    end
end

function GroundAOE.drawAll()
    for i = 1, #_alive do
        local z = _alive[i]
        if z and z.draw then z:draw() end
    end
end

function GroundAOE.clearAll()
    for i = #_alive, 1, -1 do _alive[i] = nil end
    for i = #_pool, 1, -1 do _pool[i] = nil end
end

return GroundAOE


