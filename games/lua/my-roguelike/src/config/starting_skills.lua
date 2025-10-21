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
--   hitboxRadius = number (pixels, collision radius for projectile, default 6),
--   assetFolder = "foldername" (folder in assets/ containing sprite files),
--   -- Sprite files in folder:
--   --   i.png - icon for UI/menu (any size, auto-scaled)
--   --   h.png - hit effect (optional, any size, auto-scaled)
--   --   1.png, 2.png, 3.png... - flight animation frames (any size, auto-scaled)
--   --   NOTE: All sprites should be oriented FACING RIGHT
--   animationSpeed = number (seconds per frame, default 0.1),
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
        hitboxRadius = 14,  -- Larger hitbox for bigger fireball sprite
        assetFolder = "fireballl",  -- assets/fireballl/ folder
        -- Contains: i.png (icon), h.png (hit), 1.png, 2.png (flight animation)
        -- All sprites face RIGHT and are auto-scaled to fit hitbox
        animationSpeed = 0.15,  -- 0.15 seconds per frame for smooth animation
        effect = {
            type = "poison",  -- Fire DOT (reusing poison mechanics)
            duration = 3,
            damage = 5,
            tickRate = 0.5
        }
    }
}

return startingSkills

