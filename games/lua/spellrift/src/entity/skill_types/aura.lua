local MathUtils = require("src.utils.math_utils")
local SpriteManager = require("src.utils.sprite_manager")
local Constants = require("src.constants")

local Aura = {}
Aura.__index = Aura

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
        tickTimer = 0,  -- таймер для тиков урона
        hitTargets = {}, -- цели, которые уже получили урон в этом тике
    }
    setmetatable(self, Aura)

    local st = skill.stats or {}

    -- тайминги
    self.duration = st.duration or 8.0  -- длительность существования
    self.tickRate = st.tickRate or 0.5  -- частота тиков урона (раз в секунду)

    -- параметры ауры
    self.radius = st.radius or 100  -- радиус ауры
    self.damage = st.damage or 10   -- урон за тик

    -- поведение
    self.followCaster = (st.followCaster ~= false)  -- следовать за кастером
    self.destroyOnCasterDeath = (st.destroyOnCasterDeath ~= false)  -- уничтожать при смерти кастера

    -- дебаффы
    self.debuffType = st.debuffType
    self.debuffDuration = st.debuffDuration or 0
    self.debuffDamage = st.debuffDamage or 0
    self.debuffTickRate = st.debuffTickRate or 0

    return self
end

function Aura.spawn(world, caster, skill)
    local self = table.remove(_pool)
    if self then
        -- реинициализация в существующий объект пула
        for k in pairs(self) do self[k] = nil end
        local fresh = _build(world, caster, skill)
        for k,v in pairs(fresh) do self[k] = v end
        setmetatable(self, Aura)
    else
        self = _build(world, caster, skill)
    end
    self._dead = false
    table.insert(_alive, self)
    
    return self
end

-- ================== logic ==================

function Aura:update(dt)
    self.timer = self.timer + dt
    self.tickTimer = self.tickTimer + dt

    -- Проверяем условия уничтожения
    if self.timer >= self.duration then
        self:dispose()
        return
    end
    
    if self.destroyOnCasterDeath and (not self.caster or self.caster.isDead) then
        self:dispose()
        return
    end

    -- Проверяем тики урона
    if self.tickTimer >= self.tickRate then
        self.tickTimer = 0
        self.hitTargets = {} -- сбрасываем список пораженных целей
        self:_applyTickDamage()
    end
end

function Aura:_applyTickDamage()
    local targets = (self.caster and self.caster.enemyId) and (self.world and self.world.heroes) or (self.world and self.world.enemies)
    if not targets then return end

    local casterX = self.caster.x + (self.caster.effectiveWidth or 0) * 0.5
    local casterY = self.caster.y + (self.caster.effectiveHeight or 0) * 0.5

    for i, target in ipairs(targets) do
        if target and not target.isDead then
            -- Проверяем, не получил ли уже урон в этом тике
            local alreadyHit = false
            for _, hitTarget in ipairs(self.hitTargets) do
                if hitTarget == target then
                    alreadyHit = true
                    break
                end
            end
            
            if not alreadyHit then
                -- Проверяем расстояние до цели
                local dx = target.x + (target.effectiveWidth or 0) * 0.5 - casterX
                local dy = target.y + (target.effectiveHeight or 0) * 0.5 - casterY
                local distance = math.sqrt(dx*dx + dy*dy)
                
                if distance <= self.radius then
                    -- Попадание в ауру
                    if target.takeDamage then 
                        target:takeDamage(self.damage)
                        -- Отслеживаем урон для статистики
                        if self.caster and self.caster.dealDamage then
                            self.caster:dealDamage(self.damage)
                        end
                    end
                    
                    -- Применяем дебаффы если есть
                    if self.debuffType and target.addDebuff then
                        target:addDebuff(self.debuffType, self.debuffDuration, {
                            damage = self.debuffDamage,
                            tickRate = self.debuffTickRate
                        }, self.caster)
                    end
                    
                    -- Добавляем в список пораженных целей
                    table.insert(self.hitTargets, target)
                end
            end
        end
    end
end

-- ================== draw ==================

function Aura:draw()
    local casterX = self.caster.x + (self.caster.effectiveWidth or 0) * 0.5
    local casterY = self.caster.y + (self.caster.effectiveHeight or 0) * 0.5
    
    -- Загружаем спрайт скилла
    local skillId = self.skill.id
    local skillConfig = require("src.config.skills")[skillId]
    local spriteSheet = SpriteManager.loadSkillSprite(skillId)
    local quads = skillConfig.quads or {}
    
    -- Рисуем спрайт ауры если есть
    if spriteSheet and quads.fly then
        local fly = quads.fly
        local quadWidth = 64  -- размер кадра в спрайте
        local quadHeight = 64
        local col = fly.startcol or fly.col or 1
        local row = fly.startrow or fly.row or 1
        
        local flyQuad = love.graphics.newQuad(
            (col - 1) * quadWidth, 
            (row - 1) * quadHeight, 
            quadWidth, 
            quadHeight, 
            spriteSheet:getWidth(), 
            spriteSheet:getHeight()
        )
        
        -- Размер спрайта = radius * 2 (диаметр), но делаем на 30% больше для круглого хитбокса в квадратном спрайте
        local spriteSize = 64  -- размер кадра в спрайте
        local targetSize = self.radius * 2 * 1.3  -- желаемый размер (диаметр) + 30%
        local scale = targetSize / spriteSize  -- масштаб для достижения нужного размера
        
        -- Пульсирующая прозрачность
        local alpha = 0.7 + 0.3 * math.sin(self.timer * 3)
        love.graphics.setColor(1, 1, 1, alpha)
        
        love.graphics.draw(
            spriteSheet,
            flyQuad,
            casterX,
            casterY,
            0, -- без поворота
            scale,
            scale,
            spriteSize * 0.5,  -- центр спрайта (32, 32)
            spriteSize * 0.5   -- центр спрайта (32, 32)
        )
    else
        -- Fallback: рисуем ауру как полупрозрачный круг
        local alpha = 0.2 + 0.1 * math.sin(self.timer * 3) -- пульсирующая прозрачность
        love.graphics.setColor(1, 0, 0, alpha) -- красный цвет для сатанинской ауры
        love.graphics.circle("fill", casterX, casterY, self.radius)
        
        -- Контур ауры
        love.graphics.setColor(1, 0.2, 0.2, 0.6)
        love.graphics.circle("line", casterX, casterY, self.radius)
    end
    
    -- Рисуем хитбокс если включена отладка
    if Constants.DEBUG_DRAW_HITBOXES then
        love.graphics.setColor(0, 1, 0, 0.3) -- зеленый полупрозрачный
        love.graphics.circle("line", casterX, casterY, self.radius)
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

-- ================== pool ==================

function Aura:isDead() return self._dead end

function Aura:dispose()
    self._dead = true
    self.world, self.caster, self.skill = nil, nil, nil
    self.hitTargets = {}
    table.insert(_pool, self)
end

function Aura.updateAll(dt, world)
    for i = #_alive, 1, -1 do
        local a = _alive[i]
        if not a or not a.update then
            table.remove(_alive, i)
        else
            a:update(dt)
            if a:isDead() then table.remove(_alive, i) end
        end
    end
end

function Aura.drawAll()
    for i = 1, #_alive do
        local a = _alive[i]
        if a and a.draw then a:draw() end
    end
end

function Aura.clearAll()
    for i = #_alive, 1, -1 do
        _alive[i] = nil
    end
    for i = #_pool, 1, -1 do
        _pool[i] = nil
    end
end

return Aura
