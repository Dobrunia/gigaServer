local Object = require("src.entity.object")
local Constants = require("src.constants")
local Debuff = require("src.entity.debuff")
local Skill = require("src.entity.skill")
local GroundAOE = require("src.entity.skill_types.ground_aoe")

local Creature = {}
Creature.__index = Creature
setmetatable(Creature, {__index = Object})

function Creature.new(spriteSheet, x, y, config, level)
    -- Передаем размеры из конфига в Object.new
    local targetWidth = config.width or 64
    local targetHeight = config.height or 64
    local self = Object.new(spriteSheet, x, y, targetWidth, targetHeight)
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

    self._moveLockTimer = 0   -- заморозка перемещения
    self._faceLockTimer = 0   -- заморозка поворота
    self._lockedFacing  = 1   -- тут хранится фиксированный фейс

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
        -- поддержка как старого формата (row/col), так и нового (startrow/startcol/endrow/endcol)
        if cq.startrow and cq.startcol and cq.endcol then
            local speed = cq.animationSpeed or 0.5
            self:setAnimationList("cast", cq.startrow, cq.startcol, cq.endcol, speed)
        else
            -- один кадр: start=end=col; скорость любая (мы удерживаем кадр таймером)
            self:setAnimationList("cast", cq.row, cq.col, cq.col, 999999)
        end
    end

    -- die анимация (для врагов)
    if config.quads and config.quads.die then
        local dq = config.quads.die
        local speed = dq.animationSpeed or 0.3
        local startrow = dq.startrow or dq.row or 1
        local startcol = dq.startcol or dq.col or 1
        local endcol = dq.endcol or dq.col or 1
        self:setAnimationList("die", startrow, startcol, endcol, speed)
    end

    return self
end

function Creature:lockMovement(duration)
    if duration and duration > 0 then
        self._moveLockTimer = math.max(self._moveLockTimer or 0, duration)
    end
end

function Creature:lockFacing(duration)
    if duration and duration > 0 then
        self._lockedFacing = self.facing
        self._faceLockTimer = math.max(self._faceLockTimer or 0, duration)
    end
end

function Creature:changePosition(dx, dy)
    if (self._moveLockTimer or 0) > 0 then
        return
    end

    -- Запоминаем последний сдвиг для выбора анимации и флипа
    self._lastMoveX = dx or 0
    self._lastMoveY = dy or 0

    if self._lastMoveX < -0.001 then
        self.facing = -1       -- смотрим влево
    elseif self._lastMoveX > 0.001 then
        self.facing = 1        -- смотрим вправо
    end

    -- Применяем отталкивание перед основным движением
    local separationDx, separationDy = self:getSeparationForce()
    dx = dx + separationDx
    dy = dy + separationDy

    -- Проверяем границы карты перед движением
    if self.world then
        local newX = self.x + dx
        local newY = self.y + dy
        
        -- Ограничиваем движение границами карты (с учетом размера существа + 1 блок отступ)
        local blockSize = 64  -- размер блока карты
        local minX = blockSize
        local minY = blockSize
        local maxX = self.world.width - self.effectiveWidth - blockSize
        local maxY = self.world.height - self.effectiveHeight - blockSize
        
        -- Корректируем движение, если выходим за границы
        if newX < minX then
            dx = minX - self.x
        elseif newX > maxX then
            dx = maxX - self.x
        end
        
        if newY < minY then
            dy = minY - self.y
        elseif newY > maxY then
            dy = maxY - self.y
        end
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
    
    -- Показываем цифру урона если включена отладка
    if self.world and self.world.damageManager then
        local color = {1, 0, 0, 1} -- красный для урона
        self.world.damageManager:addDamageNumber(self.x, self.y, damage, color)
    end
    
    if self.hp <= 0 then
        self:die()
    end
end

function Creature:die()
    self.isDead = true
    -- проигрываем die анимацию если есть
    if self.animationsList and self.animationsList["die"] then
        self:playAnimation("die")
        self._dieAnimPlaying = true
        -- вычисляем длительность die анимации для таймера удаления
        local anim = self.animationsList["die"]
        if anim and anim.totalFrames and anim.animationSpeed then
            -- длительность = количество кадров * скорость анимации
            self._dieAnimDuration = anim.totalFrames * anim.animationSpeed
        else
            -- дефолтная длительность если не удалось вычислить
            self._dieAnimDuration = 1.0
        end
        self._dieAnimTimer = self._dieAnimDuration
    else
        -- если нет die анимации, можно удалить сразу
        self._dieAnimTimer = 0
    end
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

-- Получить силу отталкивания от других существ
function Creature:getSeparationForce()
    if not self.world then return 0, 0 end
    
    local separationForce = 50  -- сила отталкивания
    local separationRadius = 40 -- радиус отталкивания
    local separationX, separationY = 0, 0
    
    -- Проверяем всех врагов
    if self.world.enemies then
        for _, other in ipairs(self.world.enemies) do
            if other ~= self and not other.isDead then
                local dx = self.x - other.x
                local dy = self.y - other.y
                local distance = math.sqrt(dx * dx + dy * dy)
                
                if distance > 0 and distance < separationRadius then
                    -- Нормализуем и применяем силу отталкивания
                    local force = (separationRadius - distance) / separationRadius
                    separationX = separationX + (dx / distance) * force
                    separationY = separationY + (dy / distance) * force
                end
            end
        end
    end
    
    -- Проверяем всех героев
    if self.world.heroes then
        for _, other in ipairs(self.world.heroes) do
            if other ~= self and not other.isDead then
                local dx = self.x - other.x
                local dy = self.y - other.y
                local distance = math.sqrt(dx * dx + dy * dy)
                
                if distance > 0 and distance < separationRadius then
                    -- Нормализуем и применяем силу отталкивания
                    local force = (separationRadius - distance) / separationRadius
                    separationX = separationX + (dx / distance) * force
                    separationY = separationY + (dy / distance) * force
                end
            end
        end
    end
    
    -- Возвращаем силу отталкивания (без dt, так как применяется в changePosition)
    return separationX * separationForce, separationY * separationForce
end

function Creature:update(dt)
    -- Если мертв, обновляем только анимации (для die анимации)
    if self.isDead then
        -- тикаем таймер die анимации
        if self._dieAnimTimer then
            self._dieAnimTimer = self._dieAnimTimer - dt
            if self._dieAnimTimer <= 0 then
                self._dieAnimTimer = nil
                self._dieAnimPlaying = false
            end
        end
        Object.update(self, dt)
        return
    end

    -- Тикаем локи
    if self._moveLockTimer and self._moveLockTimer > 0 then
        self._moveLockTimer = math.max(0, self._moveLockTimer - dt)
    end
    if self._faceLockTimer and self._faceLockTimer > 0 then
        self._faceLockTimer = math.max(0, self._faceLockTimer - dt)
        -- фиксируем фейс, если кто-то попытается поменять где-то ещё
        self.facing = self._lockedFacing or self.facing
    end

    -- Обновляем кулдауны всех использованных навыков
    for _, skill in ipairs(self.skills) do
        skill:update(dt)
    end

    -- Автокаст орбитальных скиллов, аур и суммонов - они не требуют целей
    for _, skill in ipairs(self.skills) do
        if (skill.type == "orbital" or skill.type == "aura" or skill.type == "summon") and skill:canCast() then
            skill:castAt(self.world, nil, nil)
        elseif skill.type == "ground_aoe" and skill:canCast() then
            -- ground_aoe требует цели в кольце [spawnRadiusMin, spawnRadiusMax]
            if GroundAOE.hasEligibleTargets(self.world, self, skill) then
                skill:castAt(self.world, nil, nil)
            end
        end
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
    
    -- НЕ переключаем анимацию если уже играет cast или die
    if self.currentAnimation == "cast" or self.currentAnimation == "die" then
        -- оставляем анимацию как есть
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
    -- рендерим die анимацию даже если мертв
    if self.isDead and not (self._dieAnimPlaying and self.currentAnimation == "die") then
        return
    end

    -- Используем базовую отрисовку из Object
    Object.draw(self)

    -- Полоска HP (не показываем если мертв)
    if not self.isDead then
        local barWidth, barHeight = self.effectiveWidth, 4 * self.scaleHeight
        local barX, barY = self.x, self.y - 10 * self.scaleHeight
        local healthPercent = (self.baseHp and self.baseHp > 0) and (self.hp / self.baseHp) or 0

        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)

        love.graphics.setColor(1, 0, 0, 0.9)
        love.graphics.rectangle("fill", barX, barY, barWidth * healthPercent, barHeight)
        love.graphics.setColor(1, 1, 1, 1)
    end

    -- рисуем эффекты под ногами
    for _, debuff in ipairs(self.debuffs) do
        debuff:draw(self)
    end
    
    -- Рисуем дальность навыков если включена отладка
    if Constants.DEBUG_DRAW_HITBOXES then
        for _, skill in ipairs(self.skills) do
            local range = skill:getRange()
            if range > 0 then
                love.graphics.setColor(0, 1, 1, 0.3) -- голубой полупрозрачный
                love.graphics.circle("line", self.x + self.effectiveWidth * 0.5, self.y + self.effectiveHeight * 0.5, range)
                love.graphics.setColor(1, 1, 1, 1) -- сбрасываем цвет
            end
        end
    end
    
    -- Рисуем уровень существа если включена отладка
    if Constants.DEBUG_DRAW_LEVELS then
        local levelText = "Lv." .. (self.level or 1)
        local textX = self.x + self.effectiveWidth * 0.5
        local textY = self.y - 20 -- выше существа
        
        -- Фон для текста
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(levelText)
        local textHeight = font:getHeight()
        
        love.graphics.setColor(0, 0, 0, 0.7) -- черный полупрозрачный фон
        love.graphics.rectangle("fill", textX - textWidth * 0.5 - 2, textY - textHeight * 0.5 - 1, textWidth + 4, textHeight + 2)
        
        -- Текст уровня
        love.graphics.setColor(1, 1, 0, 1) -- желтый цвет
        love.graphics.printf(levelText, textX - textWidth * 0.5, textY - textHeight * 0.5, textWidth, "center")
        love.graphics.setColor(1, 1, 1, 1) -- сбрасываем цвет
    end
end

return Creature