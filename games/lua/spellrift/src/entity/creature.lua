local Object = require("src.entity.object")
local Constants = require("src.entity.constants")

local Creature = {}
Creature.__index = Creature

function Creature.new(spriteSheet, x, y, config, level)
    local self = setmetatable({}, Creature)
    
    -- Инициализируем как Object
    self = Object.new(self, spriteSheet, x, y, config.width, config.height)
    
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

    self.cooldownReduction = 0
    if config.innateSkill and config.innateSkill.modifiers and config.innateSkill.modifiers.cooldownReduction then
        self.cooldownReduction = config.innateSkill.modifiers.cooldownReduction
    end

    return self
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

function Creature:update(dt)
    -- Если мертв, не обновляем логику
    if self.isDead then
        return
    end

    -- Обновляем кулдауны всех использованных навыков
    for _, skill in ipairs(self.skills) do
        skill:update(dt)
    end

    Object.update(self, dt)
end

function Creature:draw()
    if self.isDead then
        return
    end
    
    Object.draw(self)

    -- Рисуем полоску здоровья
    local barWidth = self.width
    local barHeight = 4
    local barX = self.x
    local barY = self.y - 10
    
    -- Фон
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
    
    -- Текущее здоровье
    love.graphics.setColor(1, 0, 0, 0.9)
    love.graphics.rectangle("fill", barX, barY, barWidth * healthPercent, barHeight)
end

return Creature