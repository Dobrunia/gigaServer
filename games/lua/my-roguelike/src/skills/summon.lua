-- skills/summon.lua
-- Summon skill implementation
-- Public API: summon:cast(caster, skill, targets)

local Constants = require("src.constants")

local SummonSkill = {}
SummonSkill.__index = SummonSkill

function SummonSkill.new()
    local self = setmetatable({}, SummonSkill)
    return self
end

-- === CASTING ===

function SummonSkill:cast(caster, skill, targets)
    -- Create summon entity (simplified)
    local summon = {
        x = caster.x,
        y = caster.y,
        alive = true,
        hp = skill.summonHp or Constants.SUMMON_BASE_HP,
        maxHp = skill.summonHp or Constants.SUMMON_BASE_HP,
        damage = (skill.damage or Constants.SKILL_BASE_DAMAGE) * (caster.damageMultiplier),
        speed = skill.summonSpeed or Constants.SUMMON_BASE_SPEED,
        armor = skill.summonArmor or Constants.SUMMON_BASE_ARMOR,
        summonId = "summon_" .. skill.id,
        isSummon = true,
        owner = caster
    }
    
    -- Add to targets array (summons are friendly)
    table.insert(targets, summon)
end

return SummonSkill
