-- skills.lua
-- Skill system: auto-casting, manual aim, status effects
-- Public API: Skills.new(), skills:update(dt, player, mobs, projectilePool), skills:applyEffect(target, effect)
-- Dependencies: constants.lua, utils.lua, entity/projectile.lua

local Constants = require("src.constants")
local Utils = require("src.utils")

local Skills = {}
Skills.__index = Skills

-- === CONSTRUCTOR ===

function Skills.new()
    local self = setmetatable({}, Skills)
    
    -- No internal state needed, skills are stored in player/entities
    
    return self
end

-- === UPDATE ===

-- Update and auto-cast player skills
function Skills:update(dt, player, targets, projectilePool, spatialHash)
    if not player or not player.alive then return end
    
    for _, skill in ipairs(player.skills) do
        -- Update cooldown
        if skill.cooldownTimer and skill.cooldownTimer > 0 then
            skill.cooldownTimer = skill.cooldownTimer - dt
        else
            skill.cooldownTimer = 0
        end
        
        -- Auto-cast if ready
        if skill.cooldownTimer <= 0 and player:canAttack() then
            -- Check manual aim mode
            if player.manualAimMode then
                -- Use player's aim direction
                self:castSkill(player, skill, targets, projectilePool, spatialHash, player.aimDirection.x, player.aimDirection.y)
            else
                -- Auto-target nearest enemy
                local nearest = self:findNearestTarget(player, targets, spatialHash, skill.range or 500)
                if nearest then
                    local dx, dy = Utils.directionTo(player.x, player.y, nearest.x, nearest.y)
                    self:castSkill(player, skill, targets, projectilePool, spatialHash, dx, dy)
                end
            end
        end
    end
end

-- === TARGETING ===

function Skills:findNearestTarget(player, targets, spatialHash, range)
    local nearest = nil
    local nearestDistSq = range * range
    
    -- Use spatial hash for efficient search
    if spatialHash then
        local nearby = spatialHash:queryNearby(player.x, player.y, range)
        for _, target in ipairs(nearby) do
            if target.mobId and target.alive then  -- Only target mobs
                local distSq = Utils.distanceSquared(player.x, player.y, target.x, target.y)
                if distSq < nearestDistSq then
                    nearest = target
                    nearestDistSq = distSq
                end
            end
        end
    else
        -- Fallback: linear search
        for _, target in ipairs(targets) do
            if target.alive then
                local distSq = Utils.distanceSquared(player.x, player.y, target.x, target.y)
                if distSq < nearestDistSq then
                    nearest = target
                    nearestDistSq = distSq
                end
            end
        end
    end
    
    return nearest
end

-- === CASTING ===

function Skills:castSkill(caster, skill, targets, projectilePool, spatialHash, dirX, dirY)
    -- Check if can cast
    if not caster:canCastSkill(skill) then return false end
    
    -- Set cooldown
    caster:castSkill(skill, nil, nil)
    
    -- Execute skill effect based on type
    if skill.type == "projectile" then
        self:castProjectile(caster, skill, dirX, dirY, projectilePool)
    elseif skill.type == "aoe" then
        self:castAOE(caster, skill, targets, spatialHash)
    elseif skill.type == "buff" then
        self:castBuff(caster, skill)
    end
    
    return true
end

-- === SKILL TYPES ===

-- Projectile skill
function Skills:castProjectile(caster, skill, dirX, dirY, projectilePool)
    if not projectilePool then return end
    
    local projectile = projectilePool:acquire()
    projectile:init(
        caster.x,
        caster.y,
        dirX,
        dirY,
        skill.projectileSpeed or 300,
        skill.damage or 10,
        skill.range or 500,
        caster.heroId and "player" or "mob"
    )
    
    -- Store effect data on projectile
    projectile.effectData = skill.effect
end

-- AOE skill (damage/effect in radius)
function Skills:castAOE(caster, skill, targets, spatialHash)
    local radius = skill.radius or 100
    local targetX = caster.x + (skill.range or 0) * (caster.aimDirection and caster.aimDirection.x or 1)
    local targetY = caster.y + (skill.range or 0) * (caster.aimDirection and caster.aimDirection.y or 0)
    
    -- Find targets in radius
    local affected = {}
    if spatialHash then
        affected = spatialHash:queryNearby(targetX, targetY, radius)
    else
        for _, target in ipairs(targets) do
            if Utils.distance(targetX, targetY, target.x, target.y) <= radius then
                table.insert(affected, target)
            end
        end
    end
    
    -- Apply damage and effects
    for _, target in ipairs(affected) do
        if target.alive and target.mobId then  -- Only affect mobs
            if skill.damage then
                target:takeDamage(skill.damage, caster)
            end
            if skill.effect then
                self:applyEffect(target, skill.effect)
            end
        end
    end
end

-- Buff skill (self-buff)
function Skills:castBuff(caster, skill)
    if skill.effect then
        self:applyEffect(caster, skill.effect)
    end
end

-- === EFFECTS ===

function Skills:applyEffect(target, effect)
    if not effect or not target then return end
    
    -- effect structure: { type, duration, params }
    if effect.type == "slow" then
        target:addStatusEffect("slow", effect.duration, {
            slowPercent = effect.slowPercent or 50
        })
    elseif effect.type == "poison" then
        target:addStatusEffect("poison", effect.duration, {
            damage = effect.damage or 5,
            tickRate = effect.tickRate or Constants.POISON_TICK_RATE
        })
    elseif effect.type == "root" then
        target:addStatusEffect("root", effect.duration, {})
    elseif effect.type == "stun" then
        target:addStatusEffect("stun", effect.duration, {})
    end
end

-- === PROJECTILE HIT ===

-- Called when projectile hits target
function Skills:onProjectileHit(projectile, target)
    -- Apply projectile damage (already done in projectile:hit)
    
    -- Apply additional effects
    if projectile.effectData then
        self:applyEffect(target, projectile.effectData)
    end
end

return Skills

