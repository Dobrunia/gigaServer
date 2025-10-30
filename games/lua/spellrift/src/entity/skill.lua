local MathUtils   = require("src.utils.math_utils")
local Projectile  = require("src.entity.projectile")

-- types
local Melee = require("src.entity.skill_types.melee")
local Orbital = require("src.entity.skill_types.orbital")
local Aura = require("src.entity.skill_types.aura")
local Summon = require("src.entity.skill_types.summon")

local Skill = {}
Skill.__index = Skill


-- скилл не наследник Object, он создаёт/управляет сущностями (проджектайлы, зоны и т.п.)
function Skill.new(skillId, level, caster)
    local self = setmetatable({}, Skill)

    local config = require("src.config.skills")[skillId]
    if not config then
        error("Skill config not found: " .. tostring(skillId))
    end

    self.id = config.id
    self.name = config.name
    self.description = config.description
    self.type = config.type
    self.level = level or 1
    self.maxLevel = (config.upgrades and #config.upgrades or 0) + 1
    self.isStartingSkill = config.isStartingSkill
    self.upgrades = MathUtils.deepCopy(config.upgrades or {})
    self.stats = MathUtils.deepCopy(config.stats or {})
    self.caster = caster or nil
    self.cooldownTimer = 0
    self.isOnCooldown = false
    self:applyCasterModifiers()

    return self
end

-- Применяем модификаторы кастера к базовым статам (например, CDR)
function Skill:applyCasterModifiers()
    if self.caster and self.caster.cooldownReduction and self.stats and self.stats.cooldown then
        self.stats.cooldown = self.stats.cooldown * (1 - self.caster.cooldownReduction)
    end
end

-- ==== КУЛДАУН ====
function Skill:canCast()
    return not self.isOnCooldown
end

function Skill:startCooldown()
    local cd = (self.stats and self.stats.cooldown) or 0
    if cd > 0 then
        self.isOnCooldown  = true
        self.cooldownTimer = cd
    else
        -- мгновенно готов снова
        self.isOnCooldown  = false
        self.cooldownTimer = 0
    end
end

-- Базовый каст без цели (оставлен для совместимости с бафами/аурами)
function Skill:cast()
    if not self:canCast() then
        return false
    end
    self:startCooldown()
    return true
end

-- Каст по точке: для projectile — спавним проджектайл и запускаем КД
function Skill:castAt(world, tx, ty)
    if not self:canCast() then
        return false
    end

    if self.type == "projectile" then
        if not (world and self.caster) then
            -- без мира/кастера проджектайл создать нельзя
            return false
        end

        Projectile.spawn(world, self.caster, self, tx, ty)
        self:startCooldown()
        return true

    elseif self.type == "melee" then
        if not (world and self.caster) then return false end
    
        -- если координаты не передали — автонаведение по ближайшей цели в пределах триггер-дистанции
        if tx == nil or ty == nil then
            local castRange = (self.stats and (self.stats.range or self.stats.arcRadius)) or 0
            local tgt, dist = MathUtils.findNearestOpponent(self.caster, world, castRange > 0 and castRange or nil)
            if not tgt then return false end
            -- если указан range, не кастуем, если цель слишком далеко
            if castRange > 0 and dist > castRange then return false end
            tx, ty = tgt.x, tgt.y
        end
    
        Melee.spawn(world, self.caster, self, tx, ty)
        self:startCooldown()
        return true

    elseif self.type == "volley" then
        if not (world and self.caster) then return false end
        
        local directions = self.stats.direction or 4
        local angleStep = (2 * math.pi) / directions
        
        -- Создаем проджектайлы в разных направлениях
        for i = 0, directions - 1 do
            local angle = i * angleStep
            local dirX = math.cos(angle)
            local dirY = math.sin(angle)
            
            -- Вычисляем целевую точку в направлении стрельбы
            local range = self.stats.range or 250
            local targetX = self.caster.x + (self.caster.effectiveWidth or 0) * 0.5 + dirX * range
            local targetY = self.caster.y + (self.caster.effectiveHeight or 0) * 0.5 + dirY * range
            
            Projectile.spawn(world, self.caster, self, targetX, targetY)
        end
        
        self:startCooldown()
        return true

    elseif self.type == "orbital" then
        if not (world and self.caster) then return false end
        
        -- Орбитальные скиллы кастуются автоматически по готовности (как ауры)
        -- Не требуют целей рядом, кастуются всегда когда не в КД
        Orbital.spawn(world, self.caster, self)
        self:startCooldown()
        return true

    elseif self.type == "aura" then
        if not (world and self.caster) then return false end
        
        -- Ауры кастуются автоматически по готовности
        -- Не требуют целей рядом, кастуются всегда когда не в КД
        Aura.spawn(world, self.caster, self)
        self:startCooldown()
        return true

    elseif self.type == "summon" then
        if not (world and self.caster) then return false end
        Summon.spawn(world, self.caster, self)
        self:startCooldown()
        return true
    end

    -- другие типы добавим позже (aoe/instant и т.д.)
    return self:cast()
end

-- ==== ТИК КУЛДАУНА ====
function Skill:update(dt)
    if self.isOnCooldown then
        self.cooldownTimer = self.cooldownTimer - dt
        if self.cooldownTimer <= 0 then
            self.isOnCooldown  = false
            self.cooldownTimer = 0
        end
    end
end

-- ==== ПРОКАЧКА ====
function Skill:applyUpgrades(level)
    -- применяем все апгрейды до текущего уровня включительно (кроме базового)
    local targetLevel = math.min(level - 1, #self.upgrades)
    for i = 1, targetLevel do
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
    if not self.stats or self.stats[statName] == nil then
        error("Stat not found: " .. tostring(statName))
    end
    return self.stats[statName]
end

-- Получить радиус навыка для отрисовки
function Skill:getRange()
    return self.stats and self.stats.range or 0
end

function Skill:getCooldownDuration()
    return (self.stats and self.stats.cooldown) or 0
end

function Skill:getCooldownRemaining()
    return self.cooldownTimer or 0
end

function Skill:isOnCD()
    return self.isOnCooldown and (self.cooldownTimer or 0) > 0
end


return Skill