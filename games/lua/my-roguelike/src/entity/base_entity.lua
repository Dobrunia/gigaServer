-- entity/base_entity.lua
-- Base class for all game entities (player, mobs, projectiles)
-- Provides common properties and methods
-- Public API: BaseEntity.new(x, y), entity:update(dt), entity:draw(), entity:takeDamage(amount)
-- Dependencies: ui/colors.lua

local Colors = require("src.ui.colors")

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
    
    -- Hitbox (circle) - default size, can be overridden by subclasses
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
    
    -- Hero animation
    self.heroSprites = nil     -- Loaded hero sprites
    self.isAttacking = false   -- Attack animation state
    self.attackTimer = 0       -- Attack animation timer
    self.attackDuration = 0.5  -- Attack animation duration (0.5 seconds)
    self.isWalking = false     -- Walking animation state
    self.walkFrameIndex = 1    -- Current walking frame (1 or 2)
    self.walkTimer = 0         -- Walking animation timer
    self.walkSpeed = 0.3       -- Seconds per walking frame
    
    -- Status effects
    self.statusEffects = {}
    
    return self
end

-- === HERO ANIMATION ===

function BaseEntity:updateHeroAnimation(dt)
    -- Update attack animation (HIGHEST PRIORITY)
    if self.isAttacking then
        self.attackTimer = self.attackTimer + dt
        if self.attackTimer >= self.attackDuration then
            self.isAttacking = false
            self.attackTimer = 0
        end
        return  -- Don't update walking animation during attack
    end
    
    -- Update walking animation (only when not attacking)
    if self.isWalking and self.heroSprites and self.heroSprites.idleFrames and #self.heroSprites.idleFrames >= 2 then
        self.walkTimer = self.walkTimer + dt
        if self.walkTimer >= self.walkSpeed then
            self.walkTimer = 0
            self.walkFrameIndex = self.walkFrameIndex + 1
            if self.walkFrameIndex > 2 then
                self.walkFrameIndex = 1
            end
        end
    end
end

function BaseEntity:startAttackAnimation()
    self.isAttacking = true
    self.attackTimer = 0
end

-- === UPDATE ===

function BaseEntity:update(dt)
    -- Store previous position
    self.prevX = self.x
    self.prevY = self.y
    
    -- Update position from velocity
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
    
    -- Update movement direction for sprite flipping
    if self.vx ~= 0 or self.vy ~= 0 then
        self.dx = self.vx
        self.dy = self.vy
    end
    
    -- Update hero animation
    if self.heroSprites then
        self:updateHeroAnimation(dt)
    end
    
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
        
        -- Apply tick effects (poison, burning)
        if effect.type == "poison" or effect.type == "burning" then
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
    
    love.graphics.setColor(1, 1, 1, 1)  -- White for sprites (don't tint)
    
    -- Draw using spritesheet+quad if available, otherwise use direct sprite
    if self.spritesheet and self.quad then
        -- Spritesheet rendering with quad
        -- Use configured sprite size for origin calculation (assuming square sprites)
        local originSize = self.configSpriteSize or Constants.MOB_DEFAULT_SPRITE_SIZE
        love.graphics.draw(
            self.spritesheet,
            self.quad,
            self.x, self.y,
            self.rotation,
            self.scale, self.scale,
            originSize / 2, originSize / 2  -- Origin at center based on sprite size
        )
    elseif self.heroSprites then
        -- Hero sprite rendering with animation and direction flipping
        local sprite = nil
        
        -- Choose sprite based on state (PRIORITY: Attack > Walking > Idle)
        if self.isAttacking and self.heroSprites.attack then
            -- Attack animation (0.5 seconds) - HIGHEST PRIORITY
            sprite = self.heroSprites.attack
        elseif self.isWalking and self.heroSprites.idleFrames and #self.heroSprites.idleFrames >= 2 then
            -- Walking animation (1.png, 2.png) - MEDIUM PRIORITY
            sprite = self.heroSprites.idleFrames[self.walkFrameIndex] or self.heroSprites.idle
        else
            -- Idle animation (standing) - LOWEST PRIORITY
            sprite = self.heroSprites.idle
        end
        
        if sprite then
            local spriteW, spriteH = sprite:getDimensions()
            -- Use configured sprite size or default
            local targetSize = self.configSpriteSize or Constants.PLAYER_DEFAULT_SPRITE_SIZE
            local scale = targetSize / math.max(spriteW, spriteH)

            -- Flip horizontally if facing left (dx < 0)
            local flipX = (self.dx and self.dx < 0) and -1 or 1
            local flipY = 1

            love.graphics.draw(
                sprite,
                self.x, self.y,
                0,  -- No rotation
                scale * flipX, scale * flipY,
                spriteW / 2, spriteH / 2
            )
        end
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
        -- Fallback: draw circle with configured radius
        love.graphics.circle("fill", self.x, self.y, self.radius)
    end
    
    -- Draw burning effect under entity if burning
    if self:hasStatusEffect("burning") then
        self:drawBurningEffect()
    end
    
    -- Draw HP bar if damaged
    if self.hp < self.maxHp then
        self:drawHPBar()
    end
    
    -- Draw status effect icons (except burning - it's drawn under entity)
    self:drawStatusIcons()
end

function BaseEntity:drawHPBar()
    local barWidth = self.radius * 2
    local barHeight = 4
    local x = self.x - barWidth / 2
    local y = self.y - self.radius - 10
    
    -- Background
    love.graphics.setColor(Colors.BAR_BACKGROUND)
    love.graphics.rectangle("fill", x, y, barWidth, barHeight)
    
    -- HP
    local hpPercent = self.hp / self.maxHp
    love.graphics.setColor(Colors.BAR_HP)
    love.graphics.rectangle("fill", x, y, barWidth * hpPercent, barHeight)
    
    love.graphics.setColor(1, 1, 1, 1)  -- Reset to white
end

function BaseEntity:drawBurningEffect()
    local Assets = require("src.assets")
    
    -- Find burning effect
    local burningEffect = nil
    for _, effect in ipairs(self.statusEffects) do
        if effect.type == "burning" then
            burningEffect = effect
            break
        end
    end
    
    if not burningEffect then return end
    
    -- Draw animated flame sprite under entity's feet
    local burningSprite = Assets.images.statusBurning
    local burningQuads = Assets.quads.statusBurning
    if burningSprite and burningQuads then
        -- Calculate which frame to show based on effect timer
        local frameCount = #burningQuads
        local animSpeed = 0.1  -- 10 FPS animation
        local frameIndex = math.floor(burningEffect.timer / animSpeed) % frameCount + 1
        local quad = burningQuads[frameIndex]
        
        love.graphics.setColor(1, 1, 1, 1)  -- White for flame sprite
        -- Draw flame at entity's feet (below hitbox)
        -- Get actual quad size to calculate proper center
        local _, _, quadW, quadH = quad:getViewport()
        local flameScale = 2.5  -- 2.5x larger for visibility
        local flameY = self.y + self.radius - 7  -- Below the hitbox
        -- Center the flame sprite
        love.graphics.draw(burningSprite, quad, self.x, flameY, 0, flameScale, flameScale, quadW/2, quadH/2)
    end
    
    love.graphics.setColor(1, 1, 1, 1)  -- Reset to white
end

function BaseEntity:drawStatusIcons()
    -- Count non-burning effects for positioning
    local iconEffects = {}
    for _, effect in ipairs(self.statusEffects) do
        if effect.type ~= "burning" then  -- Burning is drawn separately under entity
            table.insert(iconEffects, effect)
        end
    end
    
    if #iconEffects == 0 then return end
    
    local iconSize = 10  -- Smaller circles for icons
    local spacing = 3
    local totalWidth = (#iconEffects * (iconSize * 2 + spacing)) - spacing
    local startX = self.x - totalWidth / 2
    local y = self.y - self.radius - 18  -- Above HP bar
    
    for i, effect in ipairs(iconEffects) do
        local x = startX + (i - 1) * (iconSize * 2 + spacing) + iconSize
        
        -- Draw colored circle for effect type
        if effect.type == "slow" then
            love.graphics.setColor(Colors.STATUS_SLOW)  -- Blue for slow
        elseif effect.type == "poison" then
            love.graphics.setColor(Colors.STATUS_POISON)  -- Green for poison
        elseif effect.type == "root" then
            love.graphics.setColor(Colors.STATUS_ROOT)  -- Brown for root
        elseif effect.type == "stun" then
            love.graphics.setColor(Colors.STATUS_STUN)  -- Yellow for stun
        else
            love.graphics.setColor(Colors.STATUS_UNKNOWN)  -- Gray for unknown
        end
        
        -- Draw filled circle
        love.graphics.circle("fill", x, y, iconSize)
        
        -- Draw border for better visibility
        love.graphics.setColor(0, 0, 0, 0.8)  -- Black border
        love.graphics.setLineWidth(1)
        love.graphics.circle("line", x, y, iconSize)
    end
    
    love.graphics.setColor(1, 1, 1, 1)  -- Reset to white
    love.graphics.setLineWidth(1)
end

return BaseEntity

