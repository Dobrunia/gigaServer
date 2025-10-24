-- skills/aura.lua
-- Aura skill system - continuous area effects around caster
-- Public API: aura.cast(), aura.update(), aura.draw()
-- Dependencies: constants.lua, utils.lua

local Constants = require("src.constants")
local Utils = require("src.utils")

local Aura = {}

-- === CASTING ===

function Aura.cast(caster, skill, targets, spatialHash)
    if not caster or not skill then return false end
    
    -- Activate aura
    skill.active = true
    skill.startTime = love.timer.getTime()
    skill.lastTick = skill.startTime
    
    Utils.log("Aura activated: " .. skill.name)
    return true
end

-- === UPDATE ===

function Aura.update(caster, skill, targets, spatialHash, dt)
    if not skill.active then return end
    
    local currentTime = love.timer.getTime()
    local tickRate = skill.tickRate or Constants.SKILL_BASE_TICK_RATE
    local duration = skill.duration or Constants.SKILL_BASE_DURATION
    
    -- Check if aura should expire
    if currentTime - skill.startTime >= duration then
        skill.active = false
        Utils.log("Aura expired: " .. skill.name)
        return
    end
    
    -- Apply damage ticks
    if currentTime - skill.lastTick >= tickRate then
        Aura.applyDamage(caster, skill, targets, spatialHash)
        skill.lastTick = currentTime
    end
end

-- === DAMAGE APPLICATION ===

function Aura.applyDamage(caster, skill, targets, spatialHash)
    if not caster or not skill.active then return end
    
    local radius = skill.radius or Constants.SKILL_BASE_AOE_RADIUS
    local damage = skill.damage or (Constants.SKILL_BASE_DAMAGE * Constants.SKILL_AURA_DAMAGE_MULT)
    
    -- Find targets in range using spatial hash
    local nearby = spatialHash:queryNearby(caster.x, caster.y, radius)
    
    for _, target in ipairs(nearby) do
        if target.mobId and target.alive and target ~= caster then
            local dist = Utils.distance(caster.x, caster.y, target.x, target.y)
            if dist <= radius then
                -- Apply damage
                target:takeDamage(damage, caster)
                
                -- Apply status effects if any
                if skill.effect then
                    local Skills = require("src.skills.base")
                    Skills.applyEffect(target, skill.effect)
                end
            end
        end
    end
end

-- === RENDERING ===

function Aura.draw(caster, skill)
    if not skill.active or not caster then return end
    
    local radius = skill.radius or Constants.SKILL_BASE_AOE_RADIUS
    local duration = skill.duration or Constants.SKILL_BASE_DURATION
    local startTime = skill.startTime or love.timer.getTime()
    local currentTime = love.timer.getTime()
    
    -- Calculate fade effect (fade out in last 20% of duration)
    local elapsed = currentTime - startTime
    local fadeStart = duration * 0.8
    local alpha = 1.0
    
    if elapsed > fadeStart then
        local fadeProgress = (elapsed - fadeStart) / (duration - fadeStart)
        alpha = 1.0 - fadeProgress
    end
    
    -- Draw aura effect
    if skill.loadedSprites and skill.loadedSprites.aura then
        -- Use custom aura sprite if available
        local sprite = skill.loadedSprites.aura
        local spriteW, spriteH = sprite:getDimensions()
        
        -- Scale sprite to match aura radius (2x radius for visual effect)
        local targetSize = radius * 2
        local scale = targetSize / math.max(spriteW, spriteH)
        
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.draw(
            sprite,
            caster.x, caster.y,
            0,  -- No rotation
            scale, scale,
            spriteW / 2, spriteH / 2
        )
    else
        -- Fallback: draw colored circle
        love.graphics.setColor(1, 0.2, 0.2, alpha * 0.3)  -- Red aura
        love.graphics.circle("fill", caster.x, caster.y, radius)
        
        love.graphics.setColor(1, 0.5, 0.5, alpha * 0.6)  -- Red border
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", caster.x, caster.y, radius)
        love.graphics.setLineWidth(1)
    end
    
    love.graphics.setColor(1, 1, 1, 1)  -- Reset color
end

return Aura
