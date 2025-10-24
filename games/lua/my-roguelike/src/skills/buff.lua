-- skills/buff.lua
-- Buff skill implementation
-- Public API: buff:cast(caster, skill)

local BuffSkill = {}
BuffSkill.__index = BuffSkill

function BuffSkill.new()
    local self = setmetatable({}, BuffSkill)
    return self
end

-- === CASTING ===

function BuffSkill:cast(caster, skill)
    if skill.buffEffect then
        -- Apply buff effect
        local baseSkills = require("src.skills.base")
        baseSkills:applyEffect(caster, skill.buffEffect)
    end
end

return BuffSkill
