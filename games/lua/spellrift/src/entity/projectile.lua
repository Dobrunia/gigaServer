local Object = require("src.entity.object")
local SpriteManager = require("src.utils.sprite_manager")
local Constants = require("src.constants")

local Projectile = {}
Projectile.__index = Projectile
setmetatable(Projectile, { __index = Object })

-- Пул / активные снаряды
local projectilePool    = {}
local activeProjectiles = {}

-- Достаём только fly/hit из конфига скилла
local function getSkillQuads(skillId)
    local skills = require("src.config.skills")
    local s = skills[skillId]
    if not s then error("Projectile: skill not found: " .. tostring(skillId)) end
    local q = s.quads or {}
    if not q.fly then
        error("Projectile: skills[" .. tostring(skillId) .. "].quads.fly is required")
    end
    return q.fly, q.hit
end

-- Переинициализация без аллокаций
local function initProjectile(self, world, caster, skill, tx, ty)
    self.world  = world
    self.caster = caster
    self.skill  = skill

    local st = skill.stats or {}
    self.speed   = st.speed  or 180
    self.radius  = st.radius or 12
    self.maxDist = st.range  or 250
    self.damage  = st.damage or 0

    -- старт из центра кастера
    self.x = caster.x + (caster.effectiveWidth or 0) * 0.5
    self.y = caster.y + (caster.effectiveHeight or 0) * 0.5
    self.startX, self.startY = self.x, self.y
    self.travel = 0

    -- направление
    local dx, dy = (tx - self.x), (ty - self.y)
    local d = math.sqrt(dx*dx + dy*dy)
    if d < 0.001 then dx, dy, d = 1, 0, 1 end
    self.vx, self.vy = (dx / d) * self.speed, (dy / d) * self.speed

    self.facing = (self.vx < 0) and -1 or 1
    self.angle = math.atan2(self.vy, self.vx)  -- угол поворота в радианах
    self.state = "fly"        -- fly | hit | dead
    self.stateTimer = 0
end

-- Публичный спавн (через пул)
function Projectile.spawn(world, caster, skill, tx, ty)
    local skillId = skill.id
    local qfly, qhit = getSkillQuads(skillId)
    local sheet = SpriteManager.loadSkillSprite(skillId)

    -- готовим объект (pool -> reuse)
    local self = table.remove(projectilePool)
    if not self then
        -- создаем объект с размером 64x64 (базовый размер)
        self = Object.new(sheet, 0, 0, 64, 64)
        setmetatable(self, Projectile)
    else
        self.spriteSheet = sheet
        self.animationsList = {}
        self.currentAnimation = "idle"
        self.currentAnimationTime = 0
        self.currentAnimationFrame = 1
    end
    
    -- устанавливаем размер из конфига скилла
    local skillConfig = require("src.config.skills")[skillId]
    if skillConfig and skillConfig.width and skillConfig.height then
        self:setSize(skillConfig.width, skillConfig.height)
    end

    -- анимация полёта (обязательна)
    self:setAnimationList(
        "fly",
        qfly.startrow or qfly.row or 1,
        qfly.startcol or qfly.col or 1,
        qfly.endcol   or qfly.col or 1,
        qfly.animationSpeed or 0.1
    )
    self:playAnimation("fly")

    -- анимация удара (опционально)
    self._hasHitAnim = false
    self._hitHold = (qhit and qhit.hold) or 0.15
    if qhit then
        self:setAnimationList(
            "hit",
            qhit.startrow or qhit.row or 1,
            qhit.startcol or qhit.col or 1,
            qhit.endcol   or qhit.col or 1,
            qhit.animationSpeed or 0.08
        )
        self._hasHitAnim = true
    end

    initProjectile(self, world, caster, skill, tx, ty)
    table.insert(activeProjectiles, self)
    return self
end

-- переход к hit анимации (при попадании в цель)
function Projectile:impact()
    if self.state ~= "fly" then return end
    if self._hasHitAnim then
        self.state = "hit"
        self.stateTimer = self._hitHold
        self:playAnimation("hit")
    else
        self.state = "dead"
    end
end

-- исчезновение без анимации (при достижении максимальной дистанции)
function Projectile:disappear()
    if self.state ~= "fly" then return end
    self.state = "dead"
end

function Projectile:update(dt, world)
    if self.state == "dead" then return end

    if self.state == "hit" then
        self.stateTimer = self.stateTimer - dt
        if self.stateTimer <= 0 then
            self.state = "dead"
        end
        Object.update(self, dt)
        return
    end

    -- fly: движение
    local dx, dy = self.vx * dt, self.vy * dt
    self:changePosition(dx, dy)
    self.travel = self.travel + math.sqrt(dx*dx + dy*dy)
    if self.travel >= self.maxDist then
        self:disappear()
        Object.update(self, dt)
        return
    end

    -- цели: враги если кастер герой, и герои если кастер враг
    local targets = (self.caster and self.caster.enemyId) and (world and world.heroes) or (world and world.enemies)
    if targets then
        local cx, cy = self.x, self.y  -- self.x, self.y уже центр спрайта
        local r2 = self.radius * self.radius
        for i = 1, #targets do
            local t = targets[i]
            if t and not t.isDead then
                local targetWidth = t.effectiveWidth
                local targetHeight = t.effectiveHeight
                local closestX = math.max(t.x, math.min(cx, t.x + targetWidth))
                local closestY = math.max(t.y, math.min(cy, t.y + targetHeight))
                local ddx, ddy = cx - closestX, cy - closestY
                if (ddx*ddx + ddy*ddy) <= r2 then
                    -- попадание
                    if t.takeDamage then t:takeDamage(self.damage) end
                    local st = self.skill.stats
                    if st.debuffType and t.addDebuff then
                        t:addDebuff("burn", st.debuffDuration, {
                            damage = st.debuffDamage,   -- опционально
                            tickRate = st.debuffTickRate -- опционально
                        }, self.caster)                        
                    end
                    self:impact()
                    break
                end
            end
        end
    end

    Object.update(self, dt)
end

function Projectile:draw()
    if self.state == "dead" then return end
    local quad = self:getCurrentQuad()
    if quad then
        local ox = self.baseWidth * 0.5  -- центр спрайта
        local oy = self.baseHeight * 0.5
        love.graphics.draw(self.spriteSheet, quad, self.x, self.y, self.angle, self.scaleWidth, self.scaleHeight, ox, oy)
    end
    
    -- Рисуем хитбокс если включена отладка
    if Constants.DEBUG_DRAW_HITBOXES then
        love.graphics.setColor(0, 1, 0, 0.5) -- зеленый полупрозрачный
        -- Центрируем хитбокс как спрайт (с учетом ox, oy)
        local hitboxX = self.x - self.effectiveWidth * 0.5
        local hitboxY = self.y - self.effectiveHeight * 0.5
        love.graphics.rectangle("line", hitboxX, hitboxY, self.effectiveWidth, self.effectiveHeight)
        love.graphics.setColor(1, 1, 1, 1) -- сбрасываем цвет
    end
end

function Projectile:isDead()
    return self.state == "dead"
end

function Projectile:dispose()
    self.world, self.caster, self.skill = nil, nil, nil
    self.state, self.stateTimer = "dead", 0
    table.insert(projectilePool, self)
end

-- батч-апдейты
function Projectile.updateAll(dt, world)
    for i = #activeProjectiles, 1, -1 do
        local p = activeProjectiles[i]
        p:update(dt, world)
        if p:isDead() then
            p:dispose()
            table.remove(activeProjectiles, i)
        end
    end
end

function Projectile.drawAll()
    for i = 1, #activeProjectiles do
        activeProjectiles[i]:draw()
    end
end

function Projectile.clearAll()
    for i = #activeProjectiles, 1, -1 do
        activeProjectiles[i]:dispose()
        table.remove(activeProjectiles, i)
    end
end

function Projectile.getCount()
    return #activeProjectiles
end

return Projectile