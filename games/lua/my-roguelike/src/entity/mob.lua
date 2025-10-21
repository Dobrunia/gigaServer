-- entity/mob.lua
-- Mob (enemy) entity with AI
-- Public API: Mob.new(x, y, mobData, level), mob:update(dt, player), mob:dropXP()
-- Dependencies: base_entity.lua, constants.lua, utils.lua

local BaseEntity = require("src.entity.base_entity")
local Constants = require("src.constants")
local Utils = require("src.utils")

local Mob = setmetatable({}, {__index = BaseEntity})
Mob.__index = Mob

-- === CONSTRUCTOR ===

function Mob.new(x, y, mobData, level)
    local self = setmetatable(BaseEntity.new(x, y), Mob)
    
    -- Mob type data from config
    self.mobId = mobData.id
    self.mobName = mobData.name
    self.mobType = mobData.type  -- "melee" or "ranged"
    
    -- Base stats from mob config
    level = level or 1
    self.level = level
    
    self.maxHp = mobData.baseHp + (level - 1) * (mobData.hpGrowth or Constants.MOB_DEFAULT_HP_GROWTH)
    self.hp = self.maxHp
    self.armor = mobData.baseArmor + (level - 1) * (mobData.armorGrowth or Constants.MOB_DEFAULT_ARMOR_GROWTH)
    self.speed = mobData.baseMoveSpeed + (level - 1) * (mobData.speedGrowth or Constants.MOB_DEFAULT_SPEED_GROWTH)
    self.damage = mobData.baseDamage + (level - 1) * (mobData.damageGrowth or Constants.MOB_DEFAULT_DAMAGE_GROWTH)
    
    -- Combat
    self.attackSpeed = mobData.attackSpeed or Constants.MOB_DEFAULT_ATTACK_SPEED  -- Attacks per second
    self.attackCooldownTimer = 0           -- Timer for attack cooldown (prevents spam)
    self.attackCooldown = 1 / self.attackSpeed  -- Cooldown duration between attacks
    
    -- Ranged-specific
    if self.mobType == "ranged" then
        self.attackRange = mobData.attackRange or Constants.MOB_DEFAULT_ATTACK_RANGE
        self.projectileSpeed = mobData.projectileSpeed or Constants.MOB_DEFAULT_PROJECTILE_SPEED
        self.projectileHitboxRadius = mobData.projectileHitboxRadius or Constants.MOB_DEFAULT_PROJECTILE_RADIUS  -- Optional custom hitbox
        self.projectileAssetFolder = mobData.projectileAssetFolder  -- Optional asset folder
        -- Legacy spritesheet approach (fallback)
        self.projectileSpritesheet = mobData.projectileSpritesheet or "items"
        self.projectileSpriteIndex = mobData.projectileSpriteIndex or 371
    end
    
    -- AI state machine
    self.aiState = "idle"  -- idle, chase, attack
    self.aiTimer = 0
    self.aiUpdateInterval = Constants.MOB_AI_UPDATE_RATE
    self.target = nil  -- Usually player
    
    -- Direction for sprite flipping (1 = right, -1 = left)
    self.facingDirection = 1
    
    -- XP drop
    self.xpDrop = mobData.xpDrop + (level - 1) * (mobData.xpDropGrowth or Constants.MOB_DEFAULT_XP_GROWTH)

    -- Size configuration (use config values or defaults)
    self.configSpriteSize = mobData.spriteSize or Constants.MOB_DEFAULT_SPRITE_SIZE
    -- Hitbox radius calculated automatically based on sprite size (37.5% of sprite size)
    self.configHitboxRadius = self.configSpriteSize * 0.375

    -- Visual (override base entity defaults with config values)
    self.radius = self.configHitboxRadius

    -- Mob sprites (static, no animation)
    self.mobSprites = nil      -- Loaded mob sprites

    -- Mob animation properties (similar to hero animation)
    self.isAttacking = false           -- Attack animation state
    self.attackAnimationTimer = 0       -- Timer for attack animation (separate from attack cooldown)
    self.attackDuration = 0.5          -- Attack animation duration (0.5 seconds)
    self.isWalking = false             -- Walking animation state
    self.walkFrameIndex = 1            -- Current walking frame (1 or 2)
    self.walkTimer = 0                 -- Walking animation timer
    self.walkSpeed = 0.3               -- Seconds per walking frame

    return self
end

-- === MOB ANIMATION ===

function Mob:updateMobAnimation(dt)
    -- Update attack animation (HIGHEST PRIORITY)
    if self.isAttacking then
        self.attackAnimationTimer = self.attackAnimationTimer + dt
        if self.attackAnimationTimer >= self.attackDuration then
            self.isAttacking = false
            self.attackAnimationTimer = 0
        end
        return  -- Don't update walking animation during attack
    end

    -- Update walking animation (only when not attacking)
    if self.isWalking and self.mobSprites and self.mobSprites.idleFrames and #self.mobSprites.idleFrames >= 2 then
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

function Mob:startAttackAnimation()
    self.isAttacking = true
    self.attackAnimationTimer = 0
end

-- Update facing direction based on target
function Mob:updateFacingDirection()
    if self.target and self.target.alive then
        local dx = self.target.x - self.x
        if dx > 0 then
            self.facingDirection = 1  -- Face right
        elseif dx < 0 then
            self.facingDirection = -1  -- Face left
        end
    end
end

-- === UPDATE ===

function Mob:update(dt, player, spatialHash)
    BaseEntity.update(self, dt)
    
    self.target = player
    
    -- Update AI less frequently for performance
    self.aiTimer = self.aiTimer + dt
    if self.aiTimer >= self.aiUpdateInterval then
        self:updateAI(dt)
        self.aiTimer = 0
    end
    
    -- Execute current AI behavior
    self:executeBehavior(dt)
    
    -- Update attack cooldown timer
    if self.attackCooldownTimer > 0 then
        self.attackCooldownTimer = self.attackCooldownTimer - dt
    end

    -- Update mob animation
    if self.mobSprites then
        self:updateMobAnimation(dt)
    end
end

-- === AI STATE MACHINE ===

function Mob:updateAI(dt)
    if not self.target or not self.target.alive then
        self.aiState = "idle"
        return
    end
    
    local distToTarget = Utils.distance(self.x, self.y, self.target.x, self.target.y)
    
    if self.mobType == "melee" then
        -- Melee: chase until in contact range
        if distToTarget > self.radius + self.target.radius then
            self.aiState = "chase"
        else
            self.aiState = "attack"
        end
    elseif self.mobType == "ranged" then
        -- Ranged: move to attack range, then attack
        if distToTarget > self.attackRange then
            self.aiState = "chase"
        else
            self.aiState = "attack"
        end
    end
end

function Mob:executeBehavior(dt)
    if self.aiState == "idle" then
        self:stopMovement()
        self.isWalking = false

    elseif self.aiState == "chase" then
        if self.target then
            local dx, dy = Utils.directionTo(self.x, self.y, self.target.x, self.target.y)
            self:move(dx, dy, dt)
            -- Update facing direction while moving
            self:updateFacingDirection()
            -- Start walking animation when moving (only if not attacking)
            if not self.isAttacking then
                self.isWalking = true
            end
        end

    elseif self.aiState == "attack" then
        if self.mobType == "melee" then
            -- Stop moving and attack if in range
            self:stopMovement()
            self.isWalking = false
            if self.attackCooldownTimer <= 0 and self:collidesWith(self.target) then
                self:attackMelee()
            end
        elseif self.mobType == "ranged" then
            -- Stop moving and shoot
            self:stopMovement()
            self.isWalking = false
            if self.attackCooldownTimer <= 0 then
                self:attackRanged()
            end
        end
    end
end

-- === COMBAT ===

function Mob:attackMelee()
    if not self.target or not self.target.alive then return end
    if not self:canAttack() then return end

    -- Start attack animation
    self:startAttackAnimation()

    self.target:takeDamage(self.damage, self)
    self.attackCooldownTimer = self.attackCooldown
end

function Mob:attackRanged()
    if not self.target or not self.target.alive then return end
    if not self:canAttack() then return end

    -- Update facing direction before attacking
    self:updateFacingDirection()

    -- Start attack animation
    self:startAttackAnimation()

    -- Signal to spawn projectile (handled by game/spawn manager)
    self.spawnProjectile = {
        x = self.x,
        y = self.y,
        targetX = self.target.x,
        targetY = self.target.y,
        damage = self.damage,
        speed = self.projectileSpeed,
        hitboxRadius = self.projectileHitboxRadius,
        assetFolder = self.projectileAssetFolder,
        -- Legacy fallback
        spritesheet = self.projectileSpritesheet,
        spriteIndex = self.projectileSpriteIndex
    }

    self.attackCooldownTimer = self.attackCooldown
    return true
end

-- === DEATH ===

function Mob:die()
    BaseEntity.die(self)
    -- XP drop will be handled by game system
end

function Mob:getXPDrop()
    return self.xpDrop
end

-- === DRAW ===

function Mob:draw()
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
    elseif self.mobSprites then
        -- Mob sprite rendering with animation and direction flipping
        local sprite = nil

        -- Choose sprite based on state (PRIORITY: Attack > Walking > Idle)
        if self.isAttacking and self.mobSprites.attack then
            -- Attack animation - HIGHEST PRIORITY
            sprite = self.mobSprites.attack
        elseif self.isWalking and self.mobSprites.idleFrames and #self.mobSprites.idleFrames >= 2 then
            -- Walking animation (1.png, 2.png) - MEDIUM PRIORITY
            sprite = self.mobSprites.idleFrames[self.walkFrameIndex] or self.mobSprites.idle
        else
            -- Idle animation (standing) - LOWEST PRIORITY
            sprite = self.mobSprites.idle or self.mobSprites.sprite
        end

        if sprite then
            local spriteW, spriteH = sprite:getDimensions()
            -- Use configured sprite size or default
            local targetSize = self.configSpriteSize or Constants.MOB_DEFAULT_SPRITE_SIZE
            local scale = targetSize / math.max(spriteW, spriteH)

            -- Flip horizontally based on facing direction
            local flipX = self.facingDirection
            local flipY = 1

            love.graphics.draw(
                sprite,
                self.x, self.y,
                0,  -- No rotation
                scale * flipX, scale * flipY,
                spriteW / 2, spriteH / 2  -- Origin at center
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

    -- Optional: draw aggro range or attack range for debug
    if Constants.DEBUG_DRAW_HITBOXES then
        if self.mobType == "ranged" and self.attackRange then
            love.graphics.setColor(1, 0, 0, 0.2)
            love.graphics.circle("line", self.x, self.y, self.attackRange)
            love.graphics.setColor(1, 1, 1, 1)
        end
    end
end

return Mob

