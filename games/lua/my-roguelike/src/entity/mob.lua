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
    
    self.maxHp = mobData.baseHp + (level - 1) * mobData.hpGrowth
    self.hp = self.maxHp
    self.armor = mobData.baseArmor + (level - 1) * mobData.armorGrowth
    self.speed = mobData.baseMoveSpeed + (level - 1) * mobData.speedGrowth
    self.damage = mobData.baseDamage + (level - 1) * mobData.damageGrowth
    
    -- Combat
    self.attackSpeed = mobData.attackSpeed  -- Attacks per second
    self.attackTimer = 0
    self.attackCooldown = 1 / self.attackSpeed
    
    -- Ranged-specific
    if self.mobType == "ranged" then
        self.attackRange = mobData.attackRange
        self.projectileSpeed = mobData.projectileSpeed
    end
    
    -- AI state machine
    self.aiState = "idle"  -- idle, chase, attack
    self.aiTimer = 0
    self.aiUpdateInterval = Constants.MOB_AI_UPDATE_RATE
    self.target = nil  -- Usually player
    
    -- XP drop
    self.xpDrop = mobData.xpDrop + (level - 1) * mobData.xpDropGrowth
    
    -- Visual
    self.radius = Constants.MOB_HITBOX_RADIUS
    
    return self
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
    
    -- Update attack timer
    if self.attackTimer > 0 then
        self.attackTimer = self.attackTimer - dt
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
        
    elseif self.aiState == "chase" then
        if self.target then
            local dx, dy = Utils.directionTo(self.x, self.y, self.target.x, self.target.y)
            self:move(dx, dy, dt)
        end
        
    elseif self.aiState == "attack" then
        if self.mobType == "melee" then
            -- Stop moving and attack if in range
            self:stopMovement()
            if self.attackTimer <= 0 and self:collidesWith(self.target) then
                self:attackMelee()
            end
        elseif self.mobType == "ranged" then
            -- Stop moving and shoot
            self:stopMovement()
            if self.attackTimer <= 0 then
                self:attackRanged()
            end
        end
    end
end

-- === COMBAT ===

function Mob:attackMelee()
    if not self.target or not self.target.alive then return end
    if not self:canAttack() then return end
    
    self.target:takeDamage(self.damage, self)
    self.attackTimer = self.attackCooldown
end

function Mob:attackRanged()
    if not self.target or not self.target.alive then return end
    if not self:canAttack() then return end
    
    -- Signal to spawn projectile (handled by game/spawn manager)
    self.spawnProjectile = {
        x = self.x,
        y = self.y,
        targetX = self.target.x,
        targetY = self.target.y,
        damage = self.damage,
        speed = self.projectileSpeed
    }
    
    self.attackTimer = self.attackCooldown
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
    BaseEntity.draw(self)
    
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

