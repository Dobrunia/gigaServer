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
function Skills:update(dt, player, targets, projectilePool, spatialHash, projectiles)
    if not player or not player.alive then return end
    
    if #player.skills == 0 then
        -- print("[SKILLS] WARNING: Player has no skills!")
        return
    end
    
    -- DEBUG: Check player state
    -- print("[SKILLS] Player state - alive:", player.alive, "castSpeed:", player.castSpeed, "skills:", #player.skills)
    
    for _, skill in ipairs(player.skills) do
        -- Update cooldown
        if skill.cooldownTimer and skill.cooldownTimer > 0 then
            skill.cooldownTimer = skill.cooldownTimer - dt
        else
            skill.cooldownTimer = 0
        end
        
        -- Auto-cast if ready
        if skill.cooldownTimer <= 0 and player:canAttack() then
            -- print("[SKILLS] Skill ready:", skill.name, "cooldown:", skill.cooldownTimer, "canAttack:", player:canAttack())
            -- Check manual aim mode
            if player.manualAimMode then
                -- Use player's aim direction
                self:castSkill(player, skill, targets, projectilePool, spatialHash, projectiles, player.aimDirection.x, player.aimDirection.y)
            else
                -- Auto-target nearest enemy
                local nearest = self:findNearestTarget(player, targets, spatialHash, skill.range or 500)
                if nearest then
                    local dx, dy = Utils.directionTo(player.x, player.y, nearest.x, nearest.y)
                    -- Update arrow to show attack direction
                    player.directionArrow = math.atan2(dy, dx)
                    
                    -- Update facing direction for auto-attack (like mob does)
                    if dx < 0 then
                        player.facingDirection = -1  -- Face left
                    elseif dx > 0 then
                        player.facingDirection = 1   -- Face right
                    end
                    
                    -- print("[SKILLS] Casting", skill.name, "at target", nearest.x, nearest.y)
                    self:castSkill(player, skill, targets, projectilePool, spatialHash, projectiles, dx, dy)
                    -- print("[SKILLS] Auto-attacking nearest target at distance:", math.sqrt((nearest.x - player.x)^2 + (nearest.y - player.y)^2))
                else
                    -- print("[SKILLS] No targets in range for", skill.name)
                end
            end
        else
            if skill.cooldownTimer > 0 then
                -- print("[SKILLS] Skill on cooldown:", skill.name, "time:", skill.cooldownTimer)
            end
            if not player:canAttack() then
                -- print("[SKILLS] Player cannot attack (stunned?)")
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

function Skills:castSkill(caster, skill, targets, projectilePool, spatialHash, projectiles, dirX, dirY)
    -- print("[SKILLS] Attempting to cast:", skill.name, "type:", skill.type)
    -- Check if can cast
    if not caster:canCastSkill(skill) then 
        -- print("[SKILLS] Cannot cast skill:", skill.name)
        return false 
    end
    
    -- Set cooldown
    caster:castSkill(skill, nil, nil)
    -- print("[SKILLS] Set cooldown for:", skill.name, "to:", skill.cooldownTimer)
    
    -- Execute skill effect based on type
    if skill.type == "projectile" then
        -- print("[SKILLS] Casting projectile skill")
        self:castProjectile(caster, skill, dirX, dirY, projectilePool, projectiles)
    elseif skill.type == "aoe" then
        -- print("[SKILLS] Casting AOE skill")
        self:castAOE(caster, skill, targets, spatialHash)
    elseif skill.type == "buff" then
        -- print("[SKILLS] Casting buff skill")
        self:castBuff(caster, skill)
    elseif skill.type == "summon" then
        -- print("[SKILLS] Casting summon skill")
        self:castSummon(caster, skill, targets)
    elseif skill.type == "aura" then
        -- print("[SKILLS] Casting aura skill")
        self:castAura(caster, skill, targets, spatialHash)
    elseif skill.type == "laser" then
        -- print("[SKILLS] Casting laser skill")
        self:castLaser(caster, skill, targets, spatialHash, dirX, dirY)
    else
        -- print("[SKILLS] Unknown skill type:", skill.type)
    end
    
    return true
end

-- === SKILL TYPES ===

-- Projectile skill
function Skills:castProjectile(caster, skill, dirX, dirY, projectilePool, projectiles)
    if not projectilePool then 
        -- print("[SKILLS] ERROR: No projectile pool!")
        return 
    end
    
    -- print("[SKILLS] Creating projectile at", caster.x, caster.y, "direction", dirX, dirY)
    
    -- Load sprites from folder if needed
    if skill.assetFolder and not skill.loadedSprites then
        local Assets = require("src.assets")
        skill.loadedSprites = Assets.loadFolderSprites("assets/" .. skill.assetFolder)
    end
    
    local projectile = projectilePool:acquire()
    projectile:init(
        caster.x,
        caster.y,
        dirX,
        dirY,
        skill.projectileSpeed or Constants.SKILL_BASE_PROJECTILE_SPEED,
        skill.damage or Constants.SKILL_BASE_DAMAGE,
        skill.range or Constants.SKILL_BASE_RANGE,
        caster.heroId and "player" or "mob",
        skill.loadedSprites and skill.loadedSprites.flight or {},  -- Flight animation sprites
        skill.loadedSprites and skill.loadedSprites.hit or nil,  -- Hit sprite
        skill.animationSpeed or Constants.SKILL_BASE_ANIMATION_SPEED,  -- Animation speed
        skill.hitboxRadius or Constants.SKILL_BASE_HITBOX_RADIUS  -- Hitbox radius (uses default if nil)
    )
    
    -- Store effect data on projectile
    projectile.effectData = skill.effect
    
    -- Add to projectiles array for rendering/updating
    if projectiles then
        table.insert(projectiles, projectile)
        -- print("[SKILLS] Projectile added to array, total:", #projectiles)
    else
        -- print("[SKILLS] ERROR: No projectiles array provided!")
    end
    
    -- print("[SKILLS] Projectile created successfully")
end

-- AOE skill (damage/effect in radius)
function Skills:castAOE(caster, skill, targets, spatialHash)
    local radius = skill.radius or Constants.SKILL_BASE_AOE_RADIUS
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
    if skill.buffEffect then
        self:applyEffect(caster, skill.buffEffect)
    end
end

-- Summon skill (spawn allied creature)
function Skills:castSummon(caster, skill, targets)
    -- Create summon entity (simplified - would need proper entity creation)
    local summon = {
        x = caster.x,
        y = caster.y,
        alive = true,
        hp = skill.summonHp or Constants.SUMMON_BASE_HP,
        maxHp = skill.summonHp or Constants.SUMMON_BASE_HP,
        damage = skill.damage or Constants.SKILL_BASE_DAMAGE,
        speed = skill.summonSpeed or Constants.SUMMON_BASE_SPEED,
        armor = skill.summonArmor or Constants.SUMMON_BASE_ARMOR,
        summonId = "summon_" .. skill.id,
        isSummon = true,
        owner = caster
    }
    
    -- Add to targets array (summons are friendly)
    table.insert(targets, summon)
    -- print("[SKILLS] Summoned creature with", summon.hp, "HP")
end

-- Aura skill (continuous area effect)
function Skills:castAura(caster, skill, targets, spatialHash)
    local radius = skill.radius or Constants.SKILL_BASE_AOE_RADIUS
    local damage = skill.damage or (Constants.SKILL_BASE_DAMAGE * Constants.SKILL_AURA_DAMAGE_MULT)
    local tickRate = skill.tickRate or Constants.SKILL_BASE_TICK_RATE
    
    -- Find targets in aura radius
    local affected = {}
    if spatialHash then
        affected = spatialHash:queryNearby(caster.x, caster.y, radius)
    else
        for _, target in ipairs(targets) do
            if Utils.distance(caster.x, caster.y, target.x, target.y) <= radius then
                table.insert(affected, target)
            end
        end
    end
    
    -- Apply damage to enemies in aura
    for _, target in ipairs(affected) do
        if target.alive and target.mobId and not target.isSummon then  -- Only affect enemy mobs
            target:takeDamage(damage, caster)
            -- print("[SKILLS] Aura damage:", damage, "to target at distance:", Utils.distance(caster.x, caster.y, target.x, target.y))
        end
    end
end

-- Laser skill (continuous beam attack)
function Skills:castLaser(caster, skill, targets, spatialHash, dirX, dirY)
    local range = skill.range or Constants.SKILL_BASE_RANGE
    local damage = skill.damage or (Constants.SKILL_BASE_DAMAGE * Constants.SKILL_LASER_DAMAGE_MULT)
    local tickRate = skill.tickRate or Constants.SKILL_BASE_TICK_RATE
    
    -- Find target in laser direction
    local targetX = caster.x + dirX * range
    local targetY = caster.y + dirY * range
    
    -- Find nearest target in laser path
    local nearest = nil
    local nearestDist = range
    
    if spatialHash then
        local nearby = spatialHash:queryNearby(caster.x, caster.y, range)
        for _, target in ipairs(nearby) do
            if target.alive and target.mobId then
                -- Check if target is in laser direction
                local dist = Utils.distance(caster.x, caster.y, target.x, target.y)
                if dist <= range then
                    -- Simple direction check (could be improved with proper line intersection)
                    local targetDirX = (target.x - caster.x) / dist
                    local targetDirY = (target.y - caster.y) / dist
                    local dot = dirX * targetDirX + dirY * targetDirY
                    if dot > 0.7 then  -- Roughly in same direction
                        if dist < nearestDist then
                            nearest = target
                            nearestDist = dist
                        end
                    end
                end
            end
        end
    end
    
    -- Apply damage to target
    if nearest then
        nearest:takeDamage(damage, caster)
        -- print("[SKILLS] Laser damage:", damage, "to target at distance:", nearestDist)
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

