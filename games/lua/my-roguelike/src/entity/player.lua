-- entity/player.lua
-- Player character entity
-- Public API: Player.new(x, y, heroData), player:update(dt), player:gainXP(amount), player:levelUp()
-- Dependencies: base_entity.lua, constants.lua, utils.lua

local BaseEntity = require("src.entity.base_entity")
local Constants = require("src.constants")
local Utils = require("src.utils")

local Player = setmetatable({}, {__index = BaseEntity})
Player.__index = Player

-- === CONSTRUCTOR ===

function Player.new(x, y, heroData)
    local self = setmetatable(BaseEntity.new(x, y), Player)
    
    -- Hero data from config
    self.heroId = heroData.id
    self.heroName = heroData.name
    
    -- Base stats from hero config
    self.maxHp = heroData.baseHp
    self.hp = self.maxHp
    self.armor = heroData.baseArmor
    self.speed = heroData.baseMoveSpeed
    self.castSpeed = heroData.baseCastSpeed  -- Affects skill cooldowns

    -- Buffs
    self.damageMultiplier = 1.0  -- Damage multiplier for buffs
    self.activeBuffs = {}  -- Store active buffs for this player
    
    -- Stat growth per level
    self.hpGrowth = heroData.hpGrowth
    self.armorGrowth = heroData.armorGrowth
    self.speedGrowth = heroData.speedGrowth
    self.castSpeedGrowth = heroData.castSpeedGrowth
    
    -- Level & XP
    self.level = 1
    self.xp = 0
    self.xpToNextLevel = Utils.xpForLevel(2)
    
    -- Skills
    self.skills = {}  -- Active skills
    self.innateSkill = heroData.innateSkill  -- Passive/modifier skill
    self.maxSkillSlots = Constants.MAX_ACTIVE_SKILLS
    
    -- Note: Starting skill will be added after construction using addSkill()
    self.startingSkillData = heroData.startingSkill
    
    -- Pickup radius
    self.pickupRadius = Constants.PLAYER_DEFAULT_PICKUP_RADIUS

    -- Size configuration (use config values or defaults)
    self.configSpriteSize = heroData.spriteSize or Constants.PLAYER_DEFAULT_SPRITE_SIZE
    -- Hitbox radius calculated automatically based on sprite size (40% of sprite size for heroes)
    self.configHitboxRadius = self.configSpriteSize * 0.4

    -- Combat
    self.autoAttackTimer = 0
    self.manualAimMode = false
    self.aimDirection = {x = 1, y = 0}
    
    -- Direction for sprite flipping (1 = right, -1 = left)
    self.facingDirection = 1

    -- Visual (override base entity defaults with config values)
    self.radius = self.configHitboxRadius
    self.directionArrow = 0  -- Angle for direction indicator

    -- Hero animation properties
    self.heroSprites = nil     -- Loaded hero sprites
    self.isAttacking = false   -- Attack animation state
    self.attackTimer = 0       -- Attack animation timer
    self.attackDuration = 0.5  -- Attack animation duration (0.5 seconds)
    self.isWalking = false     -- Walking animation state
    self.walkFrameIndex = 1    -- Current walking frame (1 or 2)
    self.walkTimer = 0         -- Walking animation timer
    self.walkSpeed = 0.3       -- Seconds per walking frame

    return self
end

-- === UPDATE ===

-- === HERO ANIMATION ===

function Player:updateHeroAnimation(dt)
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

function Player:startAttackAnimation()
    self.isAttacking = true
    self.attackTimer = 0
end

function Player:update(dt)
    BaseEntity.update(self, dt)

    -- Update hero animation
    if self.heroSprites then
        self:updateHeroAnimation(dt)
    end

    -- Update facing direction when aiming (like mob does)
    if self.manualAimMode and (self.aimDirection.x ~= 0 or self.aimDirection.y ~= 0) then
        if self.aimDirection.x < 0 then
            self.facingDirection = -1  -- Face left
        elseif self.aimDirection.x > 0 then
            self.facingDirection = 1   -- Face right
        end
    end
end

-- === MOVEMENT ===

function Player:setMovementInput(dx, dy, dt)
    if dx ~= 0 or dy ~= 0 then
        self:move(dx, dy, dt)
        -- Don't update directionArrow here - it should show attack direction, not movement
        
        -- Update facing direction for movement (only if not aiming)
        if not self.manualAimMode then
            if dx < 0 then
                self.facingDirection = -1  -- Face left
            elseif dx > 0 then
                self.facingDirection = 1   -- Face right
            end
        end
        
        -- Start walking animation when moving (only if not attacking)
        if not self.isAttacking then
            self.isWalking = true
        end
    else
        self:stopMovement()
        -- Stop walking animation when not moving
        self.isWalking = false
    end
end

-- === COMBAT & SKILLS ===

function Player:setAimDirection(dx, dy)
    if dx ~= 0 or dy ~= 0 then
        local len = math.sqrt(dx * dx + dy * dy)
        self.aimDirection.x = dx / len
        self.aimDirection.y = dy / len
        self.directionArrow = math.atan2(dy, dx)
        
        -- Update facing direction when aiming (like mob does)
        if dx < 0 then
            self.facingDirection = -1  -- Face left
        elseif dx > 0 then
            self.facingDirection = 1   -- Face right
        end
    else
        -- When not aiming, ensure we're not stuck in attack state
        if self.isAttacking and self.attackTimer >= self.attackDuration then
            self.isAttacking = false
            self.attackTimer = 0
        end
    end
end

function Player:setManualAimMode(enabled)
    self.manualAimMode = enabled
end

-- Check if skill can be cast
function Player:canCastSkill(skill)
    if not self:canAttack() then return false end
    if not skill.cooldownTimer then skill.cooldownTimer = 0 end
    return skill.cooldownTimer <= 0
end

-- Cast a specific skill (called by skills system)
function Player:castSkill(skill, targetX, targetY)
    if not self:canCastSkill(skill) then return false end

    -- Update facing direction before attacking (like mob does)
    if targetX and targetY then
        local dx = targetX - self.x
        if dx < 0 then
            self.facingDirection = -1  -- Face left
        elseif dx > 0 then
            self.facingDirection = 1   -- Face right
        end
    end

    -- Start attack animation when casting skill (only when projectile is actually fired)
    self:startAttackAnimation()

    -- Calculate effective cooldown (affected by cast speed)
    local effectiveCooldown = skill.cooldown / self.castSpeed
    skill.cooldownTimer = effectiveCooldown

    return true
end

-- === LEVELING ===

function Player:gainXP(amount)
    self.xp = self.xp + amount
    
    -- Check for level up
    while self.xp >= self.xpToNextLevel do
        self.xp = self.xp - self.xpToNextLevel
        self:levelUp()
    end
end

function Player:levelUp()
    self.level = self.level + 1
    
    -- Apply stat growth
    self.maxHp = self.maxHp + self.hpGrowth
    self.hp = self.maxHp  -- Full heal on level up
    self.armor = self.armor + self.armorGrowth
    self.speed = self.speed + self.speedGrowth
    self.castSpeed = self.castSpeed + self.castSpeedGrowth
    
    -- Update XP requirement for next level
    self.xpToNextLevel = Utils.xpForLevel(self.level + 1)
    
    Utils.log("Player leveled up to " .. self.level)
    
    -- Trigger skill choice (handled by game state)
    return true  -- Signal level up happened
end

function Player:addSkill(skillData)
    -- Check if we have room
    if #self.skills >= self.maxSkillSlots then
        Utils.logError("Cannot add skill: all slots full")
        return false
    end
    
    -- Check if skill already exists (for upgrades)
    for _, skill in ipairs(self.skills) do
        if skill.id == skillData.id then
            -- Upgrade existing skill
            skill.level = (skill.level or 1) + 1
            Utils.log("Upgraded skill: " .. skillData.name)
            return true
        end
    end
    
    -- Add new skill
    local newSkill = Utils.shallowCopy(skillData)
    newSkill.cooldownTimer = 0
    newSkill.level = 1
    
    -- Load skill sprites if assetFolder is specified
    if newSkill.assetFolder then
        local Assets = require("src.assets")
        newSkill.loadedSprites = Assets.loadFolderSprites("assets/" .. newSkill.assetFolder)
        Utils.log("Loaded sprites for skill: " .. newSkill.name)
    end
    
    table.insert(self.skills, newSkill)
    Utils.log("Added new skill: " .. skillData.name)
    
    return true
end

-- === PICKUP ===

function Player:canPickup(xpDrop)
    local dist = Utils.distance(self.x, self.y, xpDrop.x, xpDrop.y)
    return dist <= self.pickupRadius
end

-- === DRAW ===

function Player:draw()
    if not self.active then return end

    love.graphics.setColor(1, 1, 1, 1)  -- White for sprites (don't tint)

    -- Draw using spritesheet+quad if available, otherwise use direct sprite
    if self.spritesheet and self.quad then
        -- Spritesheet rendering with quad
        -- Use configured sprite size for origin calculation (assuming square sprites)
        local originSize = self.configSpriteSize or Constants.PLAYER_DEFAULT_SPRITE_SIZE
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

            -- Flip horizontally based on facing direction (like mob does)
            local flipX = self.facingDirection
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

    -- Draw aura effects
    self:drawAuraEffects()

    -- Draw direction arrow
    self:drawDirectionArrow()
end

function Player:drawAuraEffects()
    if not self.skills then return end
    
    -- Draw aura effects for active aura skills
    for _, skill in ipairs(self.skills) do
        if skill.type == "aura" and skill.active then
            local Aura = require("src.skills.aura")
            Aura.draw(self, skill)
        end
    end
end

function Player:drawDirectionArrow()
    if not Constants.DEBUG_DRAW_DIRECTION_ARROW then return end
    
    local arrowLength = self.radius + 8
    local arrowX = self.x + math.cos(self.directionArrow) * arrowLength
    local arrowY = self.y + math.sin(self.directionArrow) * arrowLength
    
    love.graphics.setColor(1, 1, 0, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.line(self.x, self.y, arrowX, arrowY)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 1)
end

-- === STATS ===

function Player:getStats()
    return {
        level = self.level,
        xp = self.xp,
        xpToNext = self.xpToNextLevel,
        hp = self.hp,
        maxHp = self.maxHp,
        armor = self.armor,
        speed = self.speed,
        castSpeed = self.castSpeed,
        -- Growth bonuses
        hpGrowth = self.hpGrowth,
        armorGrowth = self.armorGrowth,
        speedGrowth = self.speedGrowth,
        castSpeedGrowth = self.castSpeedGrowth,
    }
end

return Player

