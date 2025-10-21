-- config/skills.lua
-- Skill configurations for level-up choices
-- Format:
-- {
--   id = "unique_id",
--   name = "Skill Name",
--   description = "What it does",
--   type = "projectile" | "aoe" | "buff",
--   cooldown = number (seconds),
--   damage = number (optional),
--   range = number (distance),
--   radius = number (for aoe),
--   projectileSpeed = number (for projectile),
--   spritesheet = "filename" (spritesheet file from assets/, without .png),
--   spriteIndex = number (index in spritesheet, 1-based),
--   effect = table (status effect: {type, duration, params})
-- }

local skills = {
    -- === BASELINE SKILL (REFERENCE FOR BALANCE) ===
    -- {
    --     id = "baseline_skill",
    --     name = "Baseline Skill",
    --     description = "Standard projectile attack",
    --     type = "projectile",
    --     cooldown = 2.0,        -- 2 second cooldown
    --     damage = 25,           -- Moderate damage
    --     range = 300,           -- Good range
    --     projectileSpeed = 250, -- Standard speed
    --     effect = nil           -- No special effects
    -- }
}

return skills

