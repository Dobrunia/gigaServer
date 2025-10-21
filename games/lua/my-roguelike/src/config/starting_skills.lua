-- config/starting_skills.lua
-- Starting skill configurations (data-driven)
-- After character selection, player chooses ONE starting skill from this pool
-- These skills occupy the first active skill slot
-- Format:
-- {
--   id = "unique_id",
--   name = "Skill Name",
--   description = "What the skill does",
--   type = "projectile" | "aoe" | "buff" | "summon",
--   cooldown = number (seconds),
--   damage = number (base damage),
--   range = number (pixels),
--   projectileSpeed = number (pixels/sec, if type = projectile),
--   spritesheet = "filename" (spritesheet file from assets/, without .png),
--   spriteIndex = number (index in spritesheet, 1-based),
--   effect = table (optional status effect)
-- }

local startingSkills = {
    -- === BASELINE SKILL (REFERENCE FOR BALANCE) ===
    -- {
    --     id = "basic_attack",
    --     name = "Basic Attack",
    --     description = "Standard projectile attack",
    --     type = "projectile",
    --     cooldown = 2.0,
    --     damage = 25,
    --     range = 300,
    --     projectileSpeed = 250
    -- },

    -- === FIREBALL ===
    {
        id = "fireball",
        name = "Fireball",
        description = "Shoots a burning projectile that deals damage over time",
        type = "projectile",
        cooldown = 1.5,
        damage = 40,
        range = 400,
        projectileSpeed = 300,
        spritesheet = "items",  -- items.png from assets/
        spriteIndex = 371,  -- Bolt sprite from items.png
        effect = {
            type = "poison",  -- Fire DOT (reusing poison mechanics)
            duration = 3,
            damage = 5,
            tickRate = 0.5
        }
    }
}

return startingSkills

