-- entity/projectile.lua
-- Projectile entity for ranged attacks
-- Uses object pooling for performance
-- Public API: Projectile.new(), projectile:init(x, y, dirX, dirY, speed, damage, maxDist, owner, spritesheet, spriteIndex), projectile:update(dt)
-- Dependencies: base_entity.lua, constants.lua, utils.lua

local BaseEntity = require("src.entity.base_entity")
local Constants = require("src.constants")
local Utils = require("src.utils")

local Projectile = setmetatable({}, {__index = BaseEntity})
Projectile.__index = Projectile

-- === CONSTRUCTOR ===

function Projectile.new()
    local self = setmetatable(BaseEntity.new(0, 0), Projectile)
    
    self.active = false
    self.radius = Constants.PROJECTILE_HITBOX_RADIUS
    
    -- Projectile-specific
    self.dirX = 0
    self.dirY = 0
    self.speed = 300
    self.damage = 10
    self.owner = nil  -- "player" or "mob"
    
    self.distanceTraveled = 0
    self.maxDistance = 500
    
    -- Animation (using direct Image objects, not indices)
    self.flightSprites = nil  -- Array of Image objects
    self.hitSprite = nil  -- Single Image object
    self.currentFrameIndex = 1
    self.animationTimer = 0
    self.animationSpeed = 0.1
    self.isHitting = false
    self.hitTimer = 0
    self.hitDuration = 0.15  -- How long to show hit sprite
    
    return self
end

-- === POOLING SUPPORT ===

-- Initialize projectile when acquired from pool
-- flightSprites: array of Image objects for animation
-- hitSprite: single Image object for hit effect (optional)
-- hitboxRadius: collision radius in pixels
function Projectile:init(x, y, dirX, dirY, speed, damage, maxDist, owner, flightSprites, hitSprite, animSpeed, hitboxRadius)
    self.x = x
    self.y = y
    self.prevX = x
    self.prevY = y
    
    -- Normalize direction
    local len = math.sqrt(dirX * dirX + dirY * dirY)
    if len > 0 then
        self.dirX = dirX / len
        self.dirY = dirY / len
    else
        self.dirX = 1
        self.dirY = 0
    end
    
    -- Store denormalized direction for drawing rotation
    self.dx = self.dirX
    self.dy = self.dirY
    
    self.speed = speed or 300
    self.damage = damage or 10
    self.maxDistance = maxDist or 500
    self.owner = owner or "player"
    
    -- Hitbox
    self.radius = hitboxRadius or Constants.PROJECTILE_HITBOX_RADIUS
    
    -- Sprite info (direct Image objects)
    self.flightSprites = flightSprites or {}
    self.hitSprite = hitSprite or nil
    self.animationSpeed = animSpeed or 0.1
    
    -- Animation state
    self.currentFrameIndex = 1
    self.animationTimer = 0
    self.isHitting = false
    self.hitTimer = 0
    
    self.distanceTraveled = 0
    self.active = true
    self.alive = true
    
    self.rotation = math.atan2(self.dirY, self.dirX)
end

-- Reset projectile when returned to pool
function Projectile:reset()
    self.active = false
    self.alive = false
    self.distanceTraveled = 0
    self.owner = nil
    self.flightSprites = nil
    self.hitSprite = nil
    self.currentFrameIndex = 1
    self.animationTimer = 0
    self.isHitting = false
    self.hitTimer = 0
end

-- === UPDATE ===

function Projectile:update(dt)
    if not self.active then return end
    
    -- If hitting, show hit animation then deactivate
    if self.isHitting then
        self.hitTimer = self.hitTimer + dt
        if self.hitTimer >= self.hitDuration then
            self:deactivate()
        end
        return
    end
    
    -- Store previous position
    self.prevX = self.x
    self.prevY = self.y
    
    -- Move
    local moveX = self.dirX * self.speed * dt
    local moveY = self.dirY * self.speed * dt
    
    self.x = self.x + moveX
    self.y = self.y + moveY
    
    -- Track distance
    self.distanceTraveled = self.distanceTraveled + math.sqrt(moveX * moveX + moveY * moveY)
    
    -- Update flight animation
    if self.flightSprites and #self.flightSprites > 1 then
        self.animationTimer = self.animationTimer + dt
        if self.animationTimer >= self.animationSpeed then
            self.animationTimer = self.animationTimer - self.animationSpeed
            self.currentFrameIndex = self.currentFrameIndex + 1
            if self.currentFrameIndex > #self.flightSprites then
                self.currentFrameIndex = 1
            end
        end
    end
    
    -- Check if exceeded max distance
    if self.distanceTraveled >= self.maxDistance then
        self:deactivate()
        return
    end
    
    -- Check if out of map bounds
    if self.x < 0 or self.x > Constants.MAP_WIDTH or
       self.y < 0 or self.y > Constants.MAP_HEIGHT then
        self:deactivate()
        return
    end
end

-- === COLLISION ===

function Projectile:checkHit(target)
    if not self.active or not target.alive then return false end
    
    -- Don't check collision if already hitting (showing hit animation)
    if self.isHitting then return false end
    
    -- Don't hit owner type (player projectiles don't hit player)
    if self.owner == "player" and target.isPlayer then return false end
    if self.owner == "mob" and target.mobId then return false end
    
    -- Circle collision
    return self:collidesWith(target)
end

function Projectile:hit(target)
    if target and target.takeDamage then
        target:takeDamage(self.damage, self.owner)
    end
    
    -- Show hit animation if available
    if self.hitSprite then
        self.isHitting = true
        self.hitTimer = 0
    else
        self:deactivate()
    end
end

-- === LIFECYCLE ===

function Projectile:deactivate()
    self.active = false
    self.alive = false
end

-- === DRAW ===

function Projectile:draw()
    if not self.active then return end
    
    love.graphics.setColor(1, 1, 1, 1)
    
    if self.sprite then
        love.graphics.draw(
            self.sprite,
            self.x, self.y,
            self.rotation,
            1, 1,
            self.sprite:getWidth() / 2,
            self.sprite:getHeight() / 2
        )
    else
        -- Draw simple circle
        if self.owner == "player" then
            love.graphics.setColor(1, 1, 0.3, 1)
        else
            love.graphics.setColor(1, 0.5, 0.5, 1)
        end
        love.graphics.circle("fill", self.x, self.y, self.radius)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

return Projectile

