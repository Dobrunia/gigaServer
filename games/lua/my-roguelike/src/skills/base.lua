-- skills/base.lua
-- Base skill system with common logic
-- Public API: Skills.new(), skills:update(dt, player, mobs, projectilePool), skills:castSkill()
-- Dependencies: constants.lua, utils.lua

local Constants = require("src.constants")
local Utils = require("src.utils")

local Skills = {}
Skills.__index = Skills

-- === CONSTRUCTOR ===

function Skills.new()
    local self = setmetatable({}, Skills)
    
    -- Load skill type modules
    self.projectile = require("src.skills.projectile")
    self.aura = require("src.skills.aura")
    self.aoe = require("src.skills.aoe")
    self.buff = require("src.skills.buff")
    self.summon = require("src.skills.summon")
    self.laser = require("src.skills.laser")
    
    return self
end

-- === UPDATE ===

-- Update and auto-cast player skills
function Skills:update(dt, player, targets, projectilePool, spatialHash, projectiles)
    if not player or not player.alive then return end
    
    if #player.skills == 0 then
        return
    end
    
    for _, skill in ipairs(player.skills) do
        -- Update active auras
        if skill.type == "aura" and skill.active then
            self.aura.update(player, skill, targets, spatialHash, dt)
        end
        
        -- Update cooldown
        if skill.cooldownTimer and skill.cooldownTimer > 0 then
            skill.cooldownTimer = skill.cooldownTimer - dt
        else
            skill.cooldownTimer = 0
        end

        -- Auto-cast if ready
        if skill.cooldownTimer <= 0 and player:canAttack() then
            -- Special handling for aura skills - always cast on cooldown
            if skill.type == "aura" then
                self:castSkill(player, skill, targets, projectilePool, spatialHash, projectiles, 1, 0)
            elseif player.manualAimMode then
                self:castSkill(player, skill, targets, projectilePool, spatialHash, projectiles, player.aimDirection.x, player.aimDirection.y)
            else
                local nearest = self:findNearestTarget(player, targets, spatialHash, skill.range or Constants.SKILL_BASE_RANGE)
                if nearest then
                    local dx, dy = Utils.directionTo(player.x, player.y, nearest.x, nearest.y)
                    player.directionArrow = math.atan2(dy, dx)
                    if dx < 0 then
                        player.facingDirection = -1
                    elseif dx > 0 then
                        player.facingDirection = 1
                    end
                    self:castSkill(player, skill, targets, projectilePool, spatialHash, projectiles, dx, dy)
                end
            end
        end
    end
end

-- === TARGETING ===

function Skills:findNearestTarget(player, targets, spatialHash, range)
    local nearest = nil
    local nearestDistSq = range * range
    
    if spatialHash then
        local nearby = spatialHash:queryNearby(player.x, player.y, range)
        for _, target in ipairs(nearby) do
            if target.mobId and target.alive then
                local distSq = Utils.distanceSquared(player.x, player.y, target.x, target.y)
                if distSq < nearestDistSq then
                    nearest = target
                    nearestDistSq = distSq
                end
            end
        end
    else
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

function Skills:castSkill(caster, skill, targets, projectilePool, spatialHash, projectiles, dirX, dirY)
    if not caster:canCastSkill(skill) then 
        return false 
    end
    
    -- Set cooldown
    caster:castSkill(skill, nil, nil)
    
    -- Execute skill effect based on type
    if skill.type == "projectile" then
        -- Check if skill has direction field for multi-directional projectiles
        if skill.direction then
            self:castMultiDirectionalProjectile(caster, skill, projectilePool, projectiles)
        else
            self.projectile:cast(caster, skill, dirX, dirY, projectilePool, projectiles)
        end
    elseif skill.type == "aoe" then
        self.aoe:cast(caster, skill, targets, spatialHash)
    elseif skill.type == "buff" then
        self.buff:cast(caster, skill)
    elseif skill.type == "summon" then
        self.summon:cast(caster, skill, targets)
    elseif skill.type == "aura" then
        self.aura.cast(caster, skill, targets, spatialHash)
    elseif skill.type == "laser" then
        self.laser:cast(caster, skill, targets, spatialHash, dirX, dirY)
    end
    
    return true
end

-- === EFFECTS ===

function Skills:applyEffect(target, effect)
    if not effect or not target then return end
    
    if effect.type == "slow" then
        target:addStatusEffect("slow", effect.duration, {
            slowPercent = effect.slowPercent or Constants.SLOW_DEFAULT_PERCENT
        })
    elseif effect.type == "poison" then
        target:addStatusEffect("poison", effect.duration, {
            damage = effect.damage or Constants.POISON_DEFAULT_DAMAGE,
            tickRate = effect.tickRate or Constants.POISON_TICK_RATE
        })
    elseif effect.type == "root" then
        target:addStatusEffect("root", effect.duration, {})
    elseif effect.type == "stun" then
        target:addStatusEffect("stun", effect.duration, {})
    end
end

-- === MULTI-DIRECTIONAL PROJECTILE ===

function Skills:castMultiDirectionalProjectile(caster, skill, projectilePool, projectiles)
    local directions = {}
    
    if skill.direction == 4 then
        -- 4 directions: up, down, left, right
        directions = {
            {0, -1},   -- up
            {0, 1},    -- down
            {-1, 0},   -- left
            {1, 0}     -- right
        }
    elseif skill.direction == 8 then
        -- 8 directions: all cardinal + diagonal
        directions = {
            {0, -1},   -- up
            {0, 1},    -- down
            {-1, 0},   -- left
            {1, 0},    -- right
            {-1, -1},  -- up-left
            {1, -1},   -- up-right
            {-1, 1},   -- down-left
            {1, 1}     -- down-right
        }
    end
    
    -- Cast projectile in each direction
    for _, dir in ipairs(directions) do
        self.projectile:cast(caster, skill, dir[1], dir[2], projectilePool, projectiles)
    end
end

return Skills
