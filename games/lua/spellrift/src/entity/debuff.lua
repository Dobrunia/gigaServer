-- src/entity/debuff.lua
local SpriteManager = require("src.utils.sprite_manager")

local Debuff = {}
Debuff.__index = Debuff

-- Debuff.new(type, duration, params, caster)
-- params для burn (опционально): damage, tickRate
function Debuff.new(debuffType, duration, params, caster)
    local self = setmetatable({}, Debuff)

    self.type     = debuffType
    self.duration = math.max(0.0001, duration or 0)  -- защита от 0
    self.timeLeft = self.duration
    self.params   = params or {}
    self.caster   = caster
    self.active   = true

    -- общие (могут не использоваться, но не мешают)
    self.color    = {1, 1, 1, 1}

    if self.type == "burn" then
        -- ====== ЖЁСТКО ЗАДАННАЯ КОНФИГА ДЛЯ BURN ======
        -- спрайт: одна строка, 14 кадров, высота 12px, кадры слева-направо
        self.sprite = SpriteManager.loadDebuffSprite("burn")
        self.framesCount = 14
        self.tileHeight  = 12

        -- вычислим ширину кадра по спрайту
        local sheetW = self.sprite:getWidth()
        self.tileWidth = math.floor(sheetW / self.framesCount)

        -- соберём quads
        self.quads = {}
        for col = 1, self.framesCount do
            local q = SpriteManager.getQuad(self.sprite, col, 1, self.tileWidth, self.tileHeight)
            if q then table.insert(self.quads, q) end
        end

        -- DoT параметры (если нужны)
        self.tickRate = self.params.tickRate or 0.5
        self.damage   = self.params.damage   or 3
        self._lastTick = 0

    elseif self.type == "root" then
        -- ====== КОНФИГА ДЛЯ ROOT ======
        -- спрайт: одна строка, 7 кадров (1-7), проигрываем туда-обратно
        self.sprite = SpriteManager.loadDebuffSprite("root")
        if self.sprite then
            self.framesCount = 7  -- кадры 1..7
            
            -- вычислим размеры кадра по спрайту
            local sheetW = self.sprite:getWidth()
            local sheetH = self.sprite:getHeight()
            self.tileWidth = math.floor(sheetW / self.framesCount)
            self.tileHeight = sheetH  -- высота равна высоте всего спрайта (один ряд)

            -- соберём quads (кадры 1..7)
            self.quads = {}
            for col = 1, self.framesCount do
                local q = SpriteManager.getQuad(self.sprite, col, 1, self.tileWidth, self.tileHeight)
                if q then 
                    table.insert(self.quads, q) 
                end
            end
        else
            self.sprite = nil
            self.quads = nil
        end

    else
        -- Для остальных типов сейчас ничего не делаем
        self.sprite = nil
        self.quads  = nil
    end

    return self
end

function Debuff:update(dt, target)
    if not self.active then return end

    self.timeLeft = self.timeLeft - dt
    if self.timeLeft <= 0 then
        self:remove(target)
        return
    end

    -- простейшая логика DoT только для burn
    if self.type == "burn" and self.damage and self.tickRate then
        self._lastTick = self._lastTick + dt
        if self._lastTick >= self.tickRate then
            self._lastTick = 0
            if target and target.takeDamage then
                target:takeDamage(self.damage)
            end
        end
    end

    -- root: блокирует движение цели
    if self.type == "root" and target then
        -- блокируем движение через lockMovement (как в creature)
        if target.lockMovement then
            target:lockMovement(self.timeLeft + 0.1) -- держим блок пока действует root
        end
    end
end

function Debuff:remove(target)
    self.active = false
    -- для burn ничего возвращать не нужно
end

-- Рисуем «ауру» под ногами: кадр выбираем по ПРОГРЕССУ времени,
-- так анимация всегда полностью проигрывается за self.duration.
function Debuff:draw(target)
    if not self.active or (self.type ~= "burn" and self.type ~= "root") or not self.sprite or not self.quads then
        return
    end

    local progress = 1.0 - (self.timeLeft / self.duration)  -- 0..1
    if progress < 0 then progress = 0 elseif progress > 1 then progress = 1 end

    local idx
    if self.type == "burn" then
        -- burn: простая линейная анимация 1..framesCount
        idx = math.floor(progress * self.framesCount) + 1
        if idx > self.framesCount then idx = self.framesCount end

    elseif self.type == "root" then
        -- root: туда-обратно 1→7→1 за время длительности
        -- используем пилообразную волну для четкого перехода туда-обратно
        -- один полный цикл туда-обратно за duration
        local cycleProgress = (progress * 2.0) % 2.0  -- 0..2 (один туда-обратно)
        if cycleProgress > 1.0 then
            -- обратно: 7→1
            cycleProgress = 2.0 - cycleProgress  -- инвертируем 1..0
        end
        -- маппим на кадры 1..7
        idx = math.floor(cycleProgress * (self.framesCount - 1)) + 1
        if idx < 1 then idx = 1 elseif idx > self.framesCount then idx = self.framesCount end
    end

    if idx < 1 or idx > #self.quads then return end
    
    local quad = self.quads[idx]
    if not quad then return end

    -- Подгоняем ширину эффекта под ширину существа
    local targetW = (target.effectiveWidth  or target.width  or self.tileWidth)
    local targetH = (target.effectiveHeight or target.height or self.tileHeight)

    -- Делам чуть уже (на 90%), чтобы красиво помещалось
    local desiredWidth = targetW * 0.9
    local scaleX = desiredWidth / self.tileWidth
    local scaleY = scaleX  -- пропорциональное масштабирование

    -- Координаты: центрируем по X и рисуем у основания спрайта
    local drawX = target.x + (targetW - self.tileWidth * scaleX) * 0.5
    local drawY = target.y + targetH - self.tileHeight * scaleY * 0.9

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.sprite, quad, drawX, drawY, 0, scaleX, scaleY)
    love.graphics.setColor(1, 1, 1, 1)
end

function Debuff:getTimeLeft()
    return self.timeLeft
end

function Debuff:isActive()
    return self.active
end

return Debuff
