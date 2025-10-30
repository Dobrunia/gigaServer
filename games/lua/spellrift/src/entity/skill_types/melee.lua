-- src/entity/skill_types/melee.lua
-- ближний удар (сектор/круг), с ограничением направления: free / horizontal / vertical

local MathUtils = require("src.utils.math_utils")

local Melee = {}
Melee.__index = Melee

local _pool  = {}
local _alive = {}

-- ================== helpers ==================

local function _normalize(x, y)
    local d = math.sqrt(x*x + y*y)
    if d < 1e-6 then return 0, 0 end
    return x/d, y/d
end


-- ================== ctor ==================

local function _build(world, caster, skill, tx, ty)
    local self = {
        _dead = false,
        world  = world,
        caster = caster,
        skill  = skill,
        timer  = 0,
        didHit = false,
    }
    setmetatable(self, Melee)

    local st = skill.stats or {}

    -- тайминги
    self.windup = st.windup or 0
    self.active = st.active or 0

    -- геометрия
    self.arcAngle  = math.rad(st.arcAngleDeg or 90)
    self.halfAngle = self.arcAngle * 0.5
    self.arcRadius = st.range or 60  -- используем range вместо arcRadius
    self.arcInner  = st.arcInnerRadius or 0
    self.arcOffset = math.rad(st.arcOffsetDeg or 0)

    -- поведение
    self.followAim         = (st.followAim ~= false)
    self.trackDuringWindup = false            -- ВАЖНО: во время замаха ничего не «подтягиваем»
    self.lockMovement      = (st.lockMovement ~= false)
    self.directionMode     = st.directionMode or "free"
    self.centerOffset      = st.centerOffset or 0

    -- визуал
    self.color = st.telegraphColor or {1,1,1}
    self.alpha = st.telegraphAlpha or 0.15

    -- стартовые центр/направление
    self.centerX = caster.x + (caster.effectiveWidth  or 0) * 0.5
    self.centerY = caster.y + (caster.effectiveHeight or 0) * 0.5
    self.dirX, self.dirY = MathUtils.directionFromCaster(caster, tx, ty, self.followAim, self.directionMode)

    -- сохраняем "снимок" на старте (именно эти значения и рисуем, и бьём)
    self.fixedCenterX, self.fixedCenterY = self.centerX, self.centerY
    self.fixedDirX,    self.fixedDirY    = self.dirX, self.dirY

    if self.centerOffset ~= 0 then
        self.centerX = self.centerX + self.dirX * self.centerOffset
        self.centerY = self.centerY + self.dirY * self.centerOffset
    end

    if not self.trackDuringWindup then
        self.fixedCenterX, self.fixedCenterY = self.centerX, self.centerY
        self.fixedDirX,    self.fixedDirY    = self.dirX, self.dirY
    end

    -- боевые
    self.hitMaxTargets = st.hitMaxTargets or 0
    self.knockback     = st.knockback or 0

    return self
end

function Melee.spawn(world, caster, skill, tx, ty)
    local self = table.remove(_pool)
    if self then
        -- реинициализация в существующий объект пула
        for k in pairs(self) do self[k] = nil end
        local fresh = _build(world, caster, skill, tx, ty)
        for k,v in pairs(fresh) do self[k] = v end
        setmetatable(self, Melee)   -- <-- гарантируем метатаблицу
    else
        self = _build(world, caster, skill, tx, ty)
    end
    self._dead = false              -- <-- обязательно сбрасываем
    table.insert(_alive, self)
    
    -- Заморозка кастера на время замаха (и фейс не менять)
    if self.lockMovement and caster then
        if caster.lockMovement then caster:lockMovement(self.windup or 0) end
        if caster.lockFacing  then caster:lockFacing(self.windup or 0)  end
        if caster.animationsList and caster.animationsList["cast"] then
            caster:playAnimation("cast")
        end
    end
    
    return self
end

-- ================== logic ==================

function Melee:_applyHit()
    local st = self.skill.stats or {}
    local dmg = st.damage or 0

    local cx = self.fixedCenterX or self.centerX
    local cy = self.fixedCenterY or self.centerY
    local dx = self.fixedDirX    or self.dirX
    local dy = self.fixedDirY    or self.dirY
    dx, dy = MathUtils.rotateVector(dx, dy, self.arcOffset)

    -- цели: враги если кастер герой, и герои+саммоны если кастер враг
    local targets
    if self.caster and self.caster.enemyId then
        -- враг атакует - цели: герои + саммоны
        targets = {}
        if self.world and self.world.heroes then
            for _, hero in ipairs(self.world.heroes) do
                table.insert(targets, hero)
            end
        end
        -- добавляем саммонов как цели для атак врагов
        if self.world and self.world.summons then
            for _, summon in ipairs(self.world.summons) do
                if summon.summon and not summon.summon.isDead then
                    table.insert(targets, summon.summon)
                end
            end
        end
    else
        -- герой атакует - цели: враги
        targets = (self.world and self.world.enemies)
    end
    if not targets then return end

    local hits = 0
    for i = 1, #targets do
        local t = targets[i]
        if t and not t.isDead then
            local rectX = t.x
            local rectY = t.y
            local rectW = t.effectiveWidth or 0
            local rectH = t.effectiveHeight or 0
            
            -- Проверяем несколько точек внутри хитбокса цели
            local points = {
                -- Центр
                {rectX + rectW * 0.5, rectY + rectH * 0.5},
                -- Углы
                {rectX, rectY},
                {rectX + rectW, rectY},
                {rectX, rectY + rectH},
                {rectX + rectW, rectY + rectH},
                -- Середины сторон
                {rectX + rectW * 0.5, rectY},
                {rectX + rectW * 0.5, rectY + rectH},
                {rectX, rectY + rectH * 0.5},
                {rectX + rectW, rectY + rectH * 0.5}
            }
            
            local hit = false
            for _, point in ipairs(points) do
                if MathUtils.pointInSector(point[1], point[2], cx, cy, dx, dy, self.arcInner, self.arcRadius, self.halfAngle) then
                    hit = true
                    break
                end
            end
            
            if hit then
                local px = rectX + rectW * 0.5
                local py = rectY + rectH * 0.5
                if t.takeDamage then t:takeDamage(dmg) end
                if self.knockback > 0 and t.changePosition then
                    local kx, ky = _normalize(px - cx, py - cy)
                    t:changePosition(kx * self.knockback, ky * self.knockback)
                end
                hits = hits + 1
                if self.hitMaxTargets > 0 and hits >= self.hitMaxTargets then break end
            end
        end
    end
end

function Melee:update(dt)
    self.timer = self.timer + dt

    -- Никакого «прилипания»: используем фиксированные значения
    if not self.didHit and self.timer >= self.windup then
        self.didHit = true
        self:_applyHit()
    end

    if self.timer >= self.windup + self.active then
        self:dispose()
    end
end

-- ================== draw ==================

function Melee:draw()
    local cx = self.fixedCenterX or self.centerX
    local cy = self.fixedCenterY or self.centerY
    local dx = self.fixedDirX    or self.dirX
    local dy = self.fixedDirY    or self.dirY
    local baseAng = math.atan2(dy, dx) + self.arcOffset
    local a1, a2 = baseAng - self.halfAngle, baseAng + self.halfAngle

    -- Вычисляем прогресс заполнения (0 = только контур, 1 = полностью заполнен)
    local progress = 0
    if self.timer < self.windup then
        -- Во время windup заполняем от 0 до 1
        progress = self.timer / self.windup
    else
        -- После windup полностью заполнен
        progress = 1
    end

    -- Рисуем контур сектора
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], self.alpha * 0.5)
    love.graphics.arc("line", cx, cy, self.arcRadius, a1, a2, 32)
    
    -- Рисуем заполнение сектора в зависимости от прогресса
    if progress > 0 then
        local fillRadius = self.arcRadius * progress
        love.graphics.setColor(self.color[1], self.color[2], self.color[3], self.alpha)
        
        if self.arcInner > 0 then
            -- Для дуги с внутренним радиусом
            love.graphics.arc("fill", cx, cy, fillRadius, a1, a2)
            love.graphics.setColor(0, 0, 0, 1) -- черный для "вырезания" внутренней части
            love.graphics.arc("fill", cx, cy, self.arcInner, a1, a2)
        else
            -- Обычный сектор
            love.graphics.arc("fill", cx, cy, fillRadius, a1, a2)
        end
    end

    -- Рисуем направление атаки (стрелка)
    if progress > 0.5 then
        local arrowLength = 20
        local arrowEndX = cx + dx * arrowLength
        local arrowEndY = cy + dy * arrowLength
        
        love.graphics.setColor(1, 1, 0, 0.8) -- желтая стрелка
        love.graphics.setLineWidth(3)
        love.graphics.line(cx, cy, arrowEndX, arrowEndY)
        
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
    end

    love.graphics.setColor(1, 1, 1, 1)
end

-- ================== pool ==================

function Melee:isDead() return self._dead end

function Melee:dispose()
    self._dead = true
    self.world, self.caster, self.skill = nil, nil, nil
    table.insert(_pool, self)
end

function Melee.updateAll(dt, world)
    for i = #_alive, 1, -1 do
        local m = _alive[i]
        -- защита от «битых» записей
        if not m or not m.update then
            table.remove(_alive, i)
        else
            m:update(dt)
            if m:isDead() then table.remove(_alive, i) end
        end
    end
end

function Melee.drawAll()
    for i = 1, #_alive do
        local m = _alive[i]
        if m and m.draw then m:draw() end
    end
end

function Melee.clearAll()
    for i = #_alive, 1, -1 do
        _alive[i] = nil
    end
    for i = #_pool, 1, -1 do
        _pool[i] = nil
    end
end

return Melee