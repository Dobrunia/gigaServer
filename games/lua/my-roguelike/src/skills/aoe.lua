-- skills/aoe.lua
-- AOE skill implementation
-- Public API: aoe:cast(caster, skill, targets, spatialHash)

local Constants = require("src.constants")
local Utils = require("src.utils")

local AOESkill = {}
AOESkill.__index = AOESkill

function AOESkill.new()
    local self = setmetatable({}, AOESkill)
    return self
end

-- === CASTING ===

function AOESkill:cast(caster, skill, targets, spatialHash)
    local radius = skill.radius or Constants.SKILL_BASE_AOE_RADIUS
    local targetX = caster.x + (skill.range or Constants.SKILL_BASE_RANGE) * (caster.aimDirection and caster.aimDirection.x or 1)
    local targetY = caster.y + (skill.range or Constants.SKILL_BASE_RANGE) * (caster.aimDirection and caster.aimDirection.y or 0)
    
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
        if target.alive and target.mobId then
            if skill.damage then
                target:takeDamage(skill.damage, caster)
            end
            if skill.effect then
                -- Apply effect - need to get access to base skills system
                local baseSkills = require("src.skills.base")
                baseSkills:applyEffect(target, skill.effect)
            end
        end
    end
end

return AOESkill
