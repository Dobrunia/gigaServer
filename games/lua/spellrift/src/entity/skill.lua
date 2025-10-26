local Skill = {}
Skill.__index = Skill

function Skill.new(skillId, level = 1)
    local self = setmetatable({}, Skill)

    local config = require("src.config.skills")[skillId]
    if not config then
        error("Skill config not found: " .. skillId)
    end

    self.id = config.id
    self.name = config.name
    self.description = config.description
    self.type = config.type
    self.level = level
    self.maxLevel = #config.upgrades + 1
    self.isStartingSkill = config.isStartingSkill
    self.upgrades = config.upgrades
    
    self.stats = config.stats
    for key, value in pairs(config.stats) do
        self.stats[key] = value
    end

    self.cooldownTimer = 0
    self.isOnCooldown = false

    self:applyUpgrades(self.level)
    return self
end

-- Проверка на возможность каста
function Skill:canCast()
    return not self.isOnCooldown
end

-- Активация способности
function Skill:cast()
    if not self:canCast() then
        return false
    end

    -- Запускаем кулдаун
    self.isOnCooldown = true
    self.cooldownTimer = self.stats.cooldown
end

-- Обновление таймера кулдауна
function Skill:update(dt)
    if self.isOnCooldown then
        self.cooldownTimer = self.cooldownTimer - dt
        if self.cooldownTimer <= 0 then
            self.isOnCooldown = false
            self.cooldownTimer = 0
        end
    end
end

function Skill:applyUpgrades(level)
    -- применяем все апгрейды до текущего уровня
    for i = 1, math.min(level - 1, #self.upgrades) do
        for key, value in pairs(self.upgrades[i]) do
            self.stats[key] = value
        end
    end
end

function Skill:canLevelUp()
    return self.level < self.maxLevel
end

function Skill:levelUp()
    if not self:canLevelUp() then
        return
    end
    
    self.level = self.level + 1
    self:applyUpgrades(self.level)
end

function Skill:getStatValue(statName)
    if not self.stats[statName] then
        error("Stat not found: " .. statName)
    end
    return self.stats[statName]
end

return Skill
    