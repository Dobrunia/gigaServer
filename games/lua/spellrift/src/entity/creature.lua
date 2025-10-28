local Object = require("src.entity.object")
local Constants = require("src.constants")
local Debuff = require("src.entity.debuff")
local Skill = require("src.entity.skill")

local Creature = {}
Creature.__index = Creature
setmetatable(Creature, {__index = Object})

function Creature.new(spriteSheet, x, y, config, level)
    local self = Object.new(spriteSheet, x, y, config)
    -- Устанавливаем Creature как метатаблицу для наследования
    setmetatable(self, Creature)
    
    -- Добавляем свойства существа
    self.level = level
    self.baseHp = config.baseHp + (config.hpGrowth * (level - 1))
    self.hpGrowth = config.hpGrowth
    self.baseArmor = config.baseArmor + (config.armorGrowth * (level - 1))
    self.armorGrowth = config.armorGrowth
    self.baseMoveSpeed = config.baseMoveSpeed + (config.speedGrowth * (level - 1))
    self.speedGrowth = config.speedGrowth

    self.hp = self.baseHp
    self.armor = self.baseArmor
    self.moveSpeed = self.baseMoveSpeed

    self.skills = {}
    self.maxSkillSlots = config.maxSkillSlots or 4

    self.debuffs = {}

    self.cooldownReduction = 0
    if config.innateSkill and config.innateSkill.modifiers and config.innateSkill.modifiers.cooldownReduction then
        self.cooldownReduction = config.innateSkill.modifiers.cooldownReduction
    end

    -- Направление взгляда и трекинг последнего движения
    self.facing = 1            -- 1 = вправо (дефолт), -1 = влево
    self._lastMoveX = 0
    self._lastMoveY = 0

    -- Настройка анимаций из конфига героя (heroes.lua -> quads)
    -- idle: один кадр (row/col)
    if config.quads and config.quads.idle then
        local idle = config.quads.idle
        self:setAnimationList("idle", idle.row, idle.col, idle.col, 999999)
        self:playAnimation("idle")
    end

    -- walk: диапазон колонок в одной строке (startrow,startcol,endcol)
    if config.quads and config.quads.walk then
        local wq = config.quads.walk
        local speed = wq.animationSpeed or 0.3
        self:setAnimationList("walk", wq.startrow, wq.startcol, wq.endcol, speed)
    end

    if config.quads and config.quads.cast then
        local cq = config.quads.cast
        -- один кадр: start=end=col; скорость любая (мы удерживаем кадр таймером)
        self:setAnimationList("cast", cq.row, cq.col, cq.col, 999999)
    end

    return self
end

function Creature:changePosition(dx, dy)
    -- Запоминаем последний сдвиг для выбора анимации и флипа
    self._lastMoveX = dx or 0
    self._lastMoveY = dy or 0

    if self._lastMoveX < -0.001 then
        self.facing = -1       -- смотрим влево
    elseif self._lastMoveX > 0.001 then
        self.facing = 1        -- смотрим вправо
    end

    -- Реальный сдвиг делает базовый Object
    Object.changePosition(self, dx, dy)
end

function Creature:addSkill(skillId, level)
    if #self.skills >= self.maxSkillSlots then
        error("Cannot add skill: all slots full")
    end
    
    -- Создаем экземпляр навыка с модификаторами кастера
    local skill = Skill.new(skillId, level or 1, self)
    table.insert(self.skills, skill)
end

function Creature:takeDamage(damage)
    self.hp = self.hp - damage
    if self.hp <= 0 then
        self:die()
    end
end

function Creature:die()
    self.isDead = true
    -- self:playAnimation("death")
end

function Creature:castSkill(skill)
    skill:cast()
end

-- Добавляем дебафф
function Creature:addDebuff(debuffType, duration, params, caster)
    local debuff = Debuff.new(debuffType, duration, params, caster)
    table.insert(self.debuffs, debuff)
end

function Creature:cleanse()
    self.debuffs = {}
end

function Creature:update(dt)
    -- Если мертв, не обновляем логику
    if self.isDead then
        return
    end

    -- Обновляем кулдауны всех использованных навыков
    for _, skill in ipairs(self.skills) do
        skill:update(dt)
    end

    -- Обновляем дебаффы
    for i = #self.debuffs, 1, -1 do
        local debuff = self.debuffs[i]
        debuff:update(dt, self)
        
        if not debuff:isActive() then
            table.remove(self.debuffs, i)
        end
    end

    -- ВЫБОР АНИМАЦИИ по движению за этот кадр
    local mv = math.abs(self._lastMoveX) + math.abs(self._lastMoveY)
    
    -- НЕ переключаем анимацию если уже играет cast
    if self.currentAnimation == "cast" then
        -- оставляем cast анимацию как есть
    elseif mv > 0.01 and self.animationsList["walk"] then
        if self.currentAnimation ~= "walk" then
            self:playAnimation("walk")
        end
    elseif self.animationsList["idle"] then
        if self.currentAnimation ~= "idle" then
            self:playAnimation("idle")
        end
    end

    Object.update(self, dt)

    -- сбрасываем накопленное «движение за кадр»
    self._lastMoveX, self._lastMoveY = 0, 0
end

function Creature:draw()
    if self.isDead then return end

    -- Текущий quad из Object
    local quad = self:getCurrentQuad()
    if quad then
        local sx = (self.facing == -1) and -1 or 1
        local ox = (sx == -1) and self.width or 0
        love.graphics.draw(self.spriteSheet, quad, self.x, self.y, 0, sx, 1, ox, 0)
    end

    -- Полоска HP
    local barWidth, barHeight = self.width, 4
    local barX, barY = self.x, self.y - 10
    local healthPercent = (self.baseHp and self.baseHp > 0) and (self.hp / self.baseHp) or 0

    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)

    love.graphics.setColor(1, 0, 0, 0.9)
    love.graphics.rectangle("fill", barX, barY, barWidth * healthPercent, barHeight)
    love.graphics.setColor(1, 1, 1, 1)
end

return Creature