-- entity/base_entity.lua
-- Base class for all game entities (player, mobs, projectiles)
-- Provides common properties and methods
-- Public API: BaseEntity.new(x, y), entity:update(dt), entity:draw(), entity:takeDamage(amount)
-- Dependencies: none

local BaseEntity = {}
BaseEntity.__index = BaseEntity

-- === CONSTRUCTOR ===

function BaseEntity.new(x, y)
    local self = setmetatable({}, BaseEntity)
    
    -- Position
    self.x = x or 0
    self.y = y or 0
    self.prevX = self.x
    self.prevY = self.y
    
    -- Physics
    self.vx = 0
    self.vy = 0
    self.speed = 100
    
    -- Hitbox (circle)
    self.radius = 16
    
    -- Combat stats
    self.maxHp = 100
    self.hp = self.maxHp
    self.armor = 0
    self.damage = 10
    
    -- State
    self.alive = true
    self.active = true
    
    -- Visual
    self.sprite = nil          -- Direct image (legacy)
    self.spritesheet = nil     -- Spritesheet image
    self.quad = nil            -- Quad for spritesheet
    self.spriteIndex = nil     -- Index in spritesheet
    self.rotation = 0
    self.scale = 1
    
    -- Status effects
    self.statusEffects = {}
    
    return self
end

-- === UPDATE ===

function BaseEntity:update(dt)
    -- Store previous position
    self.prevX = self.x
    self.prevY = self.y
    
    -- Update position from velocity
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
    
    -- Update status effects
    self:updateStatusEffects(dt)
end

-- === MOVEMENT ===

function BaseEntity:move(dx, dy, dt)
    local moveSpeed = self:getEffectiveSpeed()
    self.vx = dx * moveSpeed
    self.vy = dy * moveSpeed
end

function BaseEntity:stopMovement()
    self.vx = 0
    self.vy = 0
end

function BaseEntity:setPosition(x, y)
    self.x = x
    self.y = y
    self.prevX = x
    self.prevY = y
end

-- === COMBAT ===

function BaseEntity:takeDamage(amount, source)
    if not self.alive then return 0 end
    
    -- Apply armor reduction
    local actualDamage = amount
    if self.armor > 0 then
        local reduction = 1 - math.min(0.75, self.armor * 0.06)
        actualDamage = amount * reduction
    end
    
    self.hp = self.hp - actualDamage
    
    if self.hp <= 0 then
        self.hp = 0
        self:die()
    end
    
    return actualDamage
end

function BaseEntity:heal(amount)
    if not self.alive then return end
    self.hp = math.min(self.maxHp, self.hp + amount)
end

function BaseEntity:die()
    self.alive = false
    self.active = false
    -- Override in subclasses for death behavior
end

-- === STATUS EFFECTS ===

function BaseEntity:addStatusEffect(effectType, duration, params)
    -- params can include: damage (for poison), slowPercent (for slow), etc.
    local effect = {
        type = effectType,
        duration = duration,
        timer = 0,
        params = params or {}
    }
    
    -- Check if effect already exists (refresh or stack)
    local found = false
    for i, existing in ipairs(self.statusEffects) do
        if existing.type == effectType then
            -- Refresh duration
            existing.duration = duration
            existing.timer = 0
            existing.params = params or existing.params
            found = true
            break
        end
    end
    
    if not found then
        table.insert(self.statusEffects, effect)
    end
end

function BaseEntity:removeStatusEffect(effectType)
    for i = #self.statusEffects, 1, -1 do
        if self.statusEffects[i].type == effectType then
            table.remove(self.statusEffects, i)
        end
    end
end

function BaseEntity:hasStatusEffect(effectType)
    for _, effect in ipairs(self.statusEffects) do
        if effect.type == effectType then
            return true
        end
    end
    return false
end

function BaseEntity:updateStatusEffects(dt)
    for i = #self.statusEffects, 1, -1 do
        local effect = self.statusEffects[i]
        effect.timer = effect.timer + dt
        
        -- Apply tick effects (poison)
        if effect.type == "poison" then
            local tickRate = effect.params.tickRate or 0.5
            local lastTick = effect.lastTick or 0
            if effect.timer - lastTick >= tickRate then
                self:takeDamage(effect.params.damage or 1, nil)
                effect.lastTick = effect.timer
            end
        end
        
        -- Remove expired effects
        if effect.timer >= effect.duration then
            table.remove(self.statusEffects, i)
        end
    end
end

function BaseEntity:getEffectiveSpeed()
    local speed = self.speed
    
    -- Root or stun = no movement
    if self:hasStatusEffect("root") or self:hasStatusEffect("stun") then
        return 0
    end
    
    -- Slow reduces speed
    for _, effect in ipairs(self.statusEffects) do
        if effect.type == "slow" then
            local slowPercent = effect.params.slowPercent or 50
            speed = speed * (1 - slowPercent / 100)
        end
    end
    
    return speed
end

function BaseEntity:canAttack()
    -- Stun prevents attacking
    return not self:hasStatusEffect("stun")
end

-- === COLLISION ===

function BaseEntity:collidesWith(other)
    if not self.alive or not other.alive then return false end
    
    local dx = self.x - other.x
    local dy = self.y - other.y
    local distSq = dx * dx + dy * dy
    local radiusSum = self.radius + other.radius
    
    return distSq < radiusSum * radiusSum
end

-- === DRAW ===

function BaseEntity:draw()
    if not self.active then return end
    
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Draw using spritesheet+quad if available, otherwise use direct sprite
    if self.spritesheet and self.quad then
        -- Spritesheet rendering with quad
        love.graphics.draw(
            self.spritesheet,
            self.quad,
            self.x, self.y,
            self.rotation,
            self.scale, self.scale,
            16, 16  -- Origin at center (16, 16) for 32x32 sprites
        )
    elseif self.sprite then
        -- Direct sprite rendering (legacy/placeholders)
        love.graphics.draw(
            self.sprite,
            self.x, self.y,
            self.rotation,
            self.scale, self.scale,
            self.sprite:getWidth() / 2,
            self.sprite:getHeight() / 2
        )
    else
        -- Fallback: draw circle
        love.graphics.circle("fill", self.x, self.y, self.radius)
    end
    
    -- Draw HP bar if damaged
    if self.hp < self.maxHp then
        self:drawHPBar()
    end
    
    -- Draw status effect icons
    self:drawStatusIcons()
end

function BaseEntity:drawHPBar()
    local barWidth = self.radius * 2
    local barHeight = 4
    local x = self.x - barWidth / 2
    local y = self.y - self.radius - 10
    
    -- Background
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", x, y, barWidth, barHeight)
    
    -- HP
    local hpPercent = self.hp / self.maxHp
    love.graphics.setColor(0.2, 0.8, 0.2, 1)
    love.graphics.rectangle("fill", x, y, barWidth * hpPercent, barHeight)
    
    love.graphics.setColor(1, 1, 1, 1)
end

function BaseEntity:drawStatusIcons()
    if #self.statusEffects == 0 then return end
    
    local iconRadius = 5
    local spacing = 3
    local totalWidth = (#self.statusEffects * (iconRadius * 2 + spacing)) - spacing
    local startX = self.x - totalWidth / 2 + iconRadius
    local y = self.y - self.radius - 18  -- Above HP bar
    
    for i, effect in ipairs(self.statusEffects) do
        local x = startX + (i - 1) * (iconRadius * 2 + spacing)
        
        -- Draw colored circle for effect type
        if effect.type == "slow" then
            love.graphics.setColor(0.4, 0.6, 1, 0.9)  -- Blue for slow
        elseif effect.type == "poison" then
            love.graphics.setColor(0.1, 0.9, 0.1, 0.9)  -- Green for poison
        elseif effect.type == "root" then
            love.graphics.setColor(0.6, 0.4, 0.2, 0.9)  -- Brown for root
        elseif effect.type == "stun" then
            love.graphics.setColor(1, 1, 0.2, 0.9)  -- Yellow for stun
        else
            love.graphics.setColor(0.5, 0.5, 0.5, 0.9)  -- Gray for unknown
        end
        
        -- Draw filled circle
        love.graphics.circle("fill", x, y, iconRadius)
        
        -- Draw border for better visibility
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.setLineWidth(1)
        love.graphics.circle("line", x, y, iconRadius)
    end
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
end

return BaseEntity

