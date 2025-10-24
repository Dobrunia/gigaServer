-- skills/orbital.lua
-- Orbital projectiles that rotate around caster
-- Public API: orbital:cast(), orbital:update(), orbital:draw()
-- Dependencies: constants.lua, utils.lua

local Constants = require("src.constants")
local Utils = require("src.utils")

local OrbitalSkill = {}
OrbitalSkill.__index = OrbitalSkill

-- === ORBITAL PROJECTILE ENTITY ===

local OrbitalProjectile = {}
OrbitalProjectile.__index = OrbitalProjectile

function OrbitalProjectile.new()
    local self = setmetatable({}, OrbitalProjectile)
    
    self.active = false
    self.radius = Constants.SKILL_BASE_HITBOX_RADIUS
    
    -- Orbital-specific properties
    self.angle = 0                    -- Current angle around caster
    self.orbitalRadius = Constants.ORBITAL_BASE_RADIUS          -- Distance from caster (default, overridden by skill)
    self.orbitalSpeed = Constants.ORBITAL_BASE_SPEED       -- Radians per second (default, overridden by skill)
    self.damage = Constants.ORBITAL_BASE_DAMAGE              -- Default damage (overridden by skill)
    self.owner = nil                  -- "player" or "mob"
    self.caster = nil                 -- Reference to caster
    
    -- Animation
    self.sprite = nil
    self.animationTimer = 0
    self.animationSpeed = Constants.ORBITAL_BASE_ANIMATION_SPEED     -- Default animation speed
    self.currentFrameIndex = 1
    self.flightSprites = {}
    
    -- Rotation for spinning effect
    self.spinAngle = 0                    -- Current spin angle
    self.spinSpeed = Constants.ORBITAL_SPIN_SPEED                  -- Radians per second (spins while orbiting)
    
    -- Collision tracking
    self.lastHitTarget = nil          -- Prevent hitting same target multiple times
    self.hitCooldown = Constants.ORBITAL_HIT_COOLDOWN            -- Minimum time between hits on same target
    
    return self
end

function OrbitalProjectile:init(caster, skill, orbitalIndex, totalOrbitals)
    self.caster = caster
    self.owner = caster.heroId and "player" or "mob"
    self.active = true
    
    -- Calculate initial angle (distribute evenly around caster)
    self.angle = (orbitalIndex / totalOrbitals) * (2 * math.pi)
    
    -- Set orbital properties from skill
    self.orbitalRadius = skill.orbitalRadius or Constants.ORBITAL_BASE_RADIUS
    self.orbitalSpeed = skill.orbitalSpeed or Constants.ORBITAL_BASE_SPEED
    self.damage = skill.damage or Constants.ORBITAL_BASE_DAMAGE
    self.radius = skill.hitboxRadius or Constants.ORBITAL_BASE_HITBOX_RADIUS
    self.animationSpeed = skill.animationSpeed
    self.spinSpeed = skill.spinSpeed or Constants.ORBITAL_SPIN_SPEED
    
    -- Load sprites if available
    if skill.loadedSprites and skill.loadedSprites.flight then
        self.flightSprites = skill.loadedSprites.flight
    end
    
    -- Set initial position
    self:updatePosition()
end

function OrbitalProjectile:update(dt)
    if not self.active or not self.caster or not self.caster.alive then
        self.active = false
        return
    end
    
    -- Update angle
    self.angle = self.angle + self.orbitalSpeed * dt
    
    -- Update spin angle for sprite rotation
    self.spinAngle = self.spinAngle + self.spinSpeed * dt
    
    -- Update position
    self:updatePosition()
    
    -- Update animation
    if #self.flightSprites > 1 then
        self.animationTimer = self.animationTimer + dt
        if self.animationTimer >= self.animationSpeed then
            self.animationTimer = 0
            self.currentFrameIndex = self.currentFrameIndex + 1
            if self.currentFrameIndex > #self.flightSprites then
                self.currentFrameIndex = 1
            end
        end
    end
end

function OrbitalProjectile:updatePosition()
    if not self.caster then return end
    
    self.x = self.caster.x + math.cos(self.angle) * self.orbitalRadius
    self.y = self.caster.y + math.sin(self.angle) * self.orbitalRadius
end

function OrbitalProjectile:checkHit(target)
    if not self.active or not target.alive then return false end
    if not self.caster or not self.caster.alive then return false end
    
    -- Don't hit owner type
    if self.owner == "player" and target.isPlayer then return false end
    if self.owner == "mob" and target.mobId then return false end
    
    -- Don't hit same target too frequently
    if self.lastHitTarget == target then return false end
    
    -- Check collision
    local dist = Utils.distance(self.x, self.y, target.x, target.y)
    if dist <= (self.radius + target.radius) then
        return true
    end
    
    return false
end

function OrbitalProjectile:hit(target)
    if target and target.takeDamage then
        local damage = self.damage
        
        -- Apply damage multiplier from caster
        if self.caster and self.caster.damageMultiplier then
            damage = damage * self.caster.damageMultiplier
        end
        
        target:takeDamage(damage, self.owner)
        self.lastHitTarget = target
    end
end

function OrbitalProjectile:draw()
    if not self.active then return end
    
    love.graphics.setColor(1, 1, 1, 1)
    
    if #self.flightSprites > 0 then
        local sprite = self.flightSprites[self.currentFrameIndex] or self.flightSprites[1]
        if sprite then
            -- Scale sprite to match projectile size (like regular projectiles)
            local spriteW, spriteH = sprite:getDimensions()
            local targetSize = Constants.PROJECTILE_SPRITE_SIZE * 1.6  -- 20% smaller than regular projectiles
            local scale = targetSize / math.max(spriteW, spriteH)
            
            love.graphics.draw(
                sprite,
                self.x, self.y,
                self.spinAngle,  -- Rotate sprite for spinning effect
                scale, scale,
                spriteW / 2,
                spriteH / 2
            )
        end
    else
        -- Fallback: draw circle
        if self.owner == "player" then
            love.graphics.setColor(Constants.ORBITAL_PLAYER_COLOR_R, Constants.ORBITAL_PLAYER_COLOR_G, Constants.ORBITAL_PLAYER_COLOR_B, 1)  -- Orange for player
        else
            love.graphics.setColor(Constants.ORBITAL_MOB_COLOR_R, Constants.ORBITAL_MOB_COLOR_G, Constants.ORBITAL_MOB_COLOR_B, 1)  -- Red for mob
        end
        love.graphics.circle("fill", self.x, self.y, self.radius)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

-- === ORBITAL SKILL IMPLEMENTATION ===

function OrbitalSkill.new()
    local self = setmetatable({}, OrbitalSkill)
    self.orbitals = {}  -- Array of active orbital projectiles
    return self
end

function OrbitalSkill:cast(caster, skill, projectilePool, projectiles)
    if not caster or not skill then return false end
    
    -- Load sprites from folder if needed
    if skill.assetFolder and not skill.loadedSprites then
        local Assets = require("src.assets")
        skill.loadedSprites = Assets.loadFolderSprites("assets/" .. skill.assetFolder)
    end
    
    local orbitalCount = skill.orbitalCount or Constants.ORBITAL_BASE_COUNT
    local duration = skill.duration or Constants.ORBITAL_BASE_DURATION
    
    -- Create orbital projectiles
    for i = 1, orbitalCount do
        local orbital = OrbitalProjectile.new()
        orbital:init(caster, skill, i - 1, orbitalCount)
        
        -- Set expiration time
        orbital.expirationTime = love.timer.getTime() + duration
        
        table.insert(self.orbitals, orbital)
    end
    
    Utils.log("Orbital skill cast: " .. skill.name .. " with " .. orbitalCount .. " projectiles")
    return true
end

function OrbitalSkill:update(dt, caster, targets, spatialHash)
    if not caster or not caster.alive then
        -- Clear all orbitals if caster is dead
        self.orbitals = {}
        return
    end
    
    local currentTime = love.timer.getTime()
    
    -- Update and check collisions for each orbital
    for i = #self.orbitals, 1, -1 do
        local orbital = self.orbitals[i]
        
        -- Remove expired orbitals
        if currentTime >= orbital.expirationTime then
            table.remove(self.orbitals, i)
            goto continue
        end
        
        -- Update orbital
        orbital:update(dt)
        
        -- Check collisions with targets
        if spatialHash then
            local nearby = spatialHash:queryNearby(orbital.x, orbital.y, orbital.radius + Constants.ORBITAL_COLLISION_QUERY_RADIUS)
            for _, target in ipairs(nearby) do
                if orbital:checkHit(target) then
                    orbital:hit(target)
                    break  -- Only hit one target per frame
                end
            end
        else
            -- Fallback: check all targets
            for _, target in ipairs(targets) do
                if orbital:checkHit(target) then
                    orbital:hit(target)
                    break
                end
            end
        end
        
        ::continue::
    end
end

function OrbitalSkill:draw(caster)
    if not caster then return end
    
    -- Draw all active orbitals
    for _, orbital in ipairs(self.orbitals) do
        orbital:draw()
    end
end

-- Export OrbitalProjectile class for use in game.lua
OrbitalSkill.OrbitalProjectile = OrbitalProjectile

return OrbitalSkill
