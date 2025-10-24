-- skills/laser.lua
-- Laser skill implementation
-- Public API: laser:cast(caster, skill, targets, spatialHash, dirX, dirY)

local Constants = require("src.constants")
local Utils = require("src.utils")

local LaserSkill = {}
LaserSkill.__index = LaserSkill

function LaserSkill.new()
    local self = setmetatable({}, LaserSkill)
    return self
end

-- === CASTING ===

function LaserSkill:cast(caster, skill, targets, spatialHash, dirX, dirY)
    local range = skill.range or Constants.SKILL_BASE_RANGE
    local damage = skill.damage or (Constants.SKILL_BASE_DAMAGE * Constants.SKILL_LASER_DAMAGE_MULT)
    
    -- Find target in laser direction
    local nearest = nil
    local nearestDist = range
    
    if spatialHash then
        local nearby = spatialHash:queryNearby(caster.x, caster.y, range)
        for _, target in ipairs(nearby) do
            if target.alive and target.mobId then
                local dist = Utils.distance(caster.x, caster.y, target.x, target.y)
                if dist <= range then
                    local targetDirX = (target.x - caster.x) / dist
                    local targetDirY = (target.y - caster.y) / dist
                    local dot = dirX * targetDirX + dirY * targetDirY
                    if dot > Constants.SKILL_DIRECTION_THRESHOLD then
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
    end
end

return LaserSkill
